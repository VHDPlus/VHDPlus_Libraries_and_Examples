  
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all; 
use work.Image_Data_Package.all;


ENTITY CSI_Camera IS
  GENERIC (
      CLK_Frequency : NATURAL := 12000000;
    Row_Buf       : BOOLEAN := false; 
    CLK_as_PCLK   : BOOLEAN := false 

  );
PORT (
  CLK : IN STD_LOGIC;
  Reset     : IN STD_LOGIC := '0';                
  CLK_Lane  : IN STD_LOGIC;                       
  Data_Lane : IN STD_LOGIC_VECTOR(1 downto 0);    
  SCL       : INOUT STD_LOGIC;
  SDA       : INOUT STD_LOGIC;
  oStream   : OUT rgb_stream

);
END CSI_Camera;

ARCHITECTURE BEHAVIORAL OF CSI_Camera IS

  SIGNAL address : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
  SIGNAL sreg    : STD_LOGIC_VECTOR(23 downto 0) := x"000000";
  SIGNAL I2C_Master_Interface_Enable        : STD_LOGIC := '0';
  SIGNAL I2C_Master_Interface_Address       : STD_LOGIC_VECTOR (6 DOWNTO 0) := (others => '0');
  SIGNAL I2C_Master_Interface_RW            : STD_LOGIC := '0';
  SIGNAL I2C_Master_Interface_Data_Wr       : STD_LOGIC_VECTOR (7 DOWNTO 0) := (others => '0');
  SIGNAL I2C_Master_Interface_Busy          : STD_LOGIC;
  SIGNAL I2C_Master_Interface_Data_RD       : STD_LOGIC_VECTOR (7 DOWNTO 0);
  SIGNAL I2C_Master_Interface_Ack_Error     : STD_LOGIC;
  SIGNAL Pixel_R_Reg   : STD_LOGIC_VECTOR (7 downto 0);
  SIGNAL Pixel_G_Reg   : STD_LOGIC_VECTOR (7 downto 0);
  SIGNAL Pixel_B_Reg   : STD_LOGIC_VECTOR (7 downto 0);
  SIGNAL New_Pixel_Reg : STD_LOGIC;
  SIGNAL Pixel_R_Reg_O   : STD_LOGIC_VECTOR (7 downto 0);
  SIGNAL Pixel_G_Reg_O   : STD_LOGIC_VECTOR (7 downto 0);
  SIGNAL Pixel_B_Reg_O   : STD_LOGIC_VECTOR (7 downto 0);
  SIGNAL New_Pixel_Reg_O : STD_LOGIC;
  SIGNAL New_Pixel : STD_LOGIC;
  SIGNAL Cur_Pixel_Reg_I : STD_LOGIC_VECTOR(23 downto 0);
  SIGNAL Cur_Pixel_Reg : STD_LOGIC_VECTOR(23 downto 0);
  SIGNAL RAM_Addr_A : STD_LOGIC_VECTOR(9 downto 0);
  SIGNAL RAM_Addr_B : STD_LOGIC_VECTOR(9 downto 0);
  SIGNAL Pixel_Clk_Enable : BOOLEAN := false;
  SIGNAL Pixel_Clk_Start : BOOLEAN := false;
  SIGNAL New_Pixel_Div : STD_LOGIC;
  CONSTANT pixel_clk_divider : NATURAL := CLK_Frequency/(Image_FPS*1200*Image_Width);
  SIGNAL Data_H          : STD_LOGIC_VECTOR(1 downto 0) := (others => '0');
  SIGNAL Data_L          : STD_LOGIC_VECTOR(1 downto 0) := (others => '0');
  SIGNAL RAM_Addr          : STD_LOGIC_VECTOR(15 downto 0) := (others => '0');
  SIGNAL RAM_Data          : STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
  SIGNAL RAM_Data_Out      : STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
  SIGNAL Received_Byte     : STD_LOGIC := '0';
  SIGNAL Combine_Bytes     : STD_LOGIC := '0';
  SIGNAL RAM_DATA_A        : STD_LOGIC_VECTOR(31 downto 0);
  SIGNAL RAM_WREN_A        : STD_LOGIC;
  TYPE Pixel_Value_type IS ARRAY (1 downto 0) OF UNSIGNED(7 downto 0);
  TYPE Pixel_RGB_type IS RECORD
  R : Pixel_Value_type;
  G : Pixel_Value_type;
  B : Pixel_Value_type;
  END RECORD Pixel_RGB_type;
  SIGNAL Pixel1 : Pixel_RGB_type := (others => (others => (others => '0')));
  SIGNAL Pixel2 : Pixel_RGB_type := (others => (others => (others => '0')));
  SIGNAL Column : NATURAL range 0 to Image_Width-1 := 0;
  SIGNAL Row    : NATURAL range 0 to Image_Height-1 := 0;
  Signal buf_col : NATURAL range 0 to Image_Width-1;
  SIGNAL start_buf : STD_LOGIC := '0';
  SIGNAL Byte_Start_Phase : BOOLEAN := false;
  SIGNAL First_Byte_Reg, Second_Byte_Reg : STD_LOGIC_VECTOR(11 downto 0) := (others => '0');
  SIGNAL Zero_Count          : NATURAL range 0 to 4 := 0;
  SIGNAL Bit_Count         : NATURAL range 0 to 2 := 0;
  SIGNAL Byte_Count        : NATURAL range 0 to 2 := 0;
  SIGNAL First_New_Pixel  : STD_LOGIC_VECTOR(1 downto 0) := (others => '0');
  SIGNAL Second_New_Pixel : STD_LOGIC := '0';
  SIGNAL Start_Reg   : UNSIGNED(1 downto 0) := (others => '0');
  SIGNAL Last_Bytes_Buf   : UNSIGNED(47 downto 0) := (others => '0');
  SIGNAL Convert_Type    : NATURAL range 0 to 1;
  COMPONENT I2C_Master_Interface IS
  GENERIC (
      CLK_Frequency : INTEGER := 12000000; 
    Bus_CLK       : INTEGER := 400000   

  );
  PORT (
    CLK : IN STD_LOGIC;
    Reset     : IN     STD_LOGIC := '0';                                
    Enable    : IN     STD_LOGIC := '0';                                
    Address   : IN     STD_LOGIC_VECTOR(6 DOWNTO 0) := (others => '0'); 
    RW        : IN     STD_LOGIC := '0';                                
    Data_WR   : IN     STD_LOGIC_VECTOR(7 DOWNTO 0) := (others => '0'); 
    Busy      : OUT    STD_LOGIC := '0';                                
    Data_RD   : OUT    STD_LOGIC_VECTOR(7 DOWNTO 0) := (others => '0'); 
    Ack_Error : BUFFER STD_LOGIC := '0';                                
    SDA       : INOUT  STD_LOGIC := 'Z';                                
    SCL       : INOUT  STD_LOGIC := 'Z'                                

  );
  END COMPONENT;
  COMPONENT ALTSYNCRAM IS
  GENERIC (
      address_aclr_a         : string := "UNUSED";
    address_aclr_b         : string := "NONE";
    address_reg_b          : string := "CLOCK1";
    byte_size              : natural := 8;
    byteena_aclr_a         : string := "UNUSED";
    byteena_aclr_b         : string := "NONE";
    byteena_reg_b          : string := "CLOCK1";
    clock_enable_core_a    : string := "USE_INPUT_CLKEN";
    clock_enable_core_b    : string := "USE_INPUT_CLKEN";
    clock_enable_input_a   : string := "NORMAL";
    clock_enable_input_b   : string := "NORMAL";
    clock_enable_output_a  : string := "NORMAL";
    clock_enable_output_b  : string := "NORMAL";
    intended_device_family : string := "MAX 10";
    enable_ecc             : string := "FALSE";
    implement_in_les       : string := "OFF";
    indata_aclr_a          : string := "UNUSED";
    indata_aclr_b          : string := "NONE";
    indata_reg_b           : string := "CLOCK1";
    init_file              : string := "UNUSED";
    init_file_layout       : string := "PORT_A";
    maximum_depth          : natural := 0;
    numwords_a             : natural := 0;
    numwords_b             : natural := 0;
    operation_mode         : string := "BIDIR_DUAL_PORT";
    outdata_aclr_a         : string := "NONE";
    outdata_aclr_b         : string := "NONE";
    outdata_reg_a          : string := "UNREGISTERED";
    outdata_reg_b          : string := "UNREGISTERED";
    power_up_uninitialized : string := "FALSE";
    ram_block_type         : string := "AUTO";
    rdcontrol_aclr_b       : string := "NONE";
    rdcontrol_reg_b        : string := "CLOCK1";
    read_during_write_mode_mixed_ports     : string := "DONT_CARE";
    read_during_write_mode_port_a          : string := "NEW_DATA_NO_NBE_READ";
    read_during_write_mode_port_b          : string := "NEW_DATA_NO_NBE_READ";
    width_a                : natural;
    width_b                : natural := 1;
    width_byteena_a        : natural := 1;
    width_byteena_b        : natural := 1;
    widthad_a              : natural;
    widthad_b              : natural := 1;
    wrcontrol_aclr_a       : string := "UNUSED";
    wrcontrol_aclr_b       : string := "NONE";
    wrcontrol_wraddress_reg_b              : string := "CLOCK1";
    lpm_hint               : string := "UNUSED";
    lpm_type               : string := "altsyncram"

  );
  PORT (
    aclr0          : in std_logic := '0';
    aclr1          : in std_logic := '0';
    address_a      : in std_logic_vector(widthad_a-1 downto 0);
    address_b      : in std_logic_vector(widthad_b-1 downto 0) := (others => '1');
    addressstall_a : in std_logic := '0';
    addressstall_b : in std_logic := '0';
    byteena_a      : in std_logic_vector(width_byteena_a-1 downto 0) := (others => '1');
    byteena_b      : in std_logic_vector(width_byteena_b-1 downto 0) := (others => '1');
    clock0         : in std_logic := '1';
    clock1         : in std_logic := '1';
    clocken0       : in std_logic := '1';
    clocken1       : in std_logic := '1';
    clocken2       : in std_logic := '1';
    clocken3       : in std_logic := '1';
    data_a         : in std_logic_vector(width_a-1 downto 0) := (others => '1');
    data_b         : in std_logic_vector(width_b-1 downto 0) := (others => '1');
    eccstatus      : out std_logic_vector(2 downto 0);
    q_a            : out std_logic_vector(width_a-1 downto 0);
    q_b            : out std_logic_vector(width_b-1 downto 0);
    rden_a         : in std_logic := '1';
    rden_b         : in std_logic := '1';
    wren_a         : in std_logic := '0';
    wren_b         : in std_logic := '0'

  );
  END COMPONENT;
  COMPONENT ALTDDIO_IN IS
  GENERIC (
      intended_device_family   : String := "MAX 10";
    implement_input_in_lcell : String := "ON";
    invert_input_clocks      : String := "OFF";
    lpm_hint                 : String := "UNUSED";
    lpm_type                 : String := "altddio_in";
    power_up_high            : String := "OFF";
    width                    : NATURAL

  );
  PORT (
    datain    : IN  STD_LOGIC_VECTOR (width-1 downto 0);
    inclock   : IN  STD_LOGIC;
    dataout_h : OUT STD_LOGIC_VECTOR (width-1 downto 0);
    dataout_l : OUT STD_LOGIC_VECTOR (width-1 downto 0);
    aclr      : IN STD_LOGIC := '0';
    aset      : IN STD_LOGIC := '0';
    inclocken : IN STD_LOGIC := '1';
    sclr      : IN STD_LOGIC := '0';
    sset      : IN STD_LOGIC := '0'

  );
  END COMPONENT;
  
BEGIN









  New_Pixel <= New_Pixel_Reg_O when Row_Buf OR CLK_as_PCLK else New_Pixel_Reg;
  oStream.R <= Pixel_R_Reg_O when Row_Buf OR CLK_as_PCLK else Pixel_R_Reg;
  oStream.G <= Pixel_G_Reg_O when Row_Buf OR CLK_as_PCLK else Pixel_G_Reg;
  oStream.B <= Pixel_B_Reg_O when Row_Buf OR CLK_as_PCLK else Pixel_B_Reg;
  oStream.New_Pixel <= New_Pixel;
  oStream.Column <= Column;
  oStream.Row <= Row;
  Pixel_R_Reg  <= STD_LOGIC_VECTOR(Pixel1.R(Convert_Type)) when First_New_Pixel(0) = '1' else STD_LOGIC_VECTOR(Pixel2.R(Convert_Type));
  Pixel_G_Reg  <= STD_LOGIC_VECTOR(Pixel1.G(Convert_Type)) when First_New_Pixel(0) = '1' else STD_LOGIC_VECTOR(Pixel2.G(Convert_Type));
  Pixel_B_Reg  <= STD_LOGIC_VECTOR(Pixel1.B(Convert_Type)) when First_New_Pixel(0) = '1' else STD_LOGIC_VECTOR(Pixel2.B(Convert_Type));
  New_Pixel_Reg <= '0' when Start_Reg(1) = '1' else First_New_Pixel(0) OR Second_New_Pixel;


  Pixel_R_Reg_O <= Cur_Pixel_Reg(23 downto 16);
  Pixel_G_Reg_O <= Cur_Pixel_Reg(15 downto 8);
  Pixel_B_Reg_O <= Cur_Pixel_Reg(7 downto 0);


  RAM_Addr_A <= STD_LOGIC_VECTOR(TO_UNSIGNED(buf_col,10));
  RAM_Addr_B <= STD_LOGIC_VECTOR(TO_UNSIGNED(Column,10));

  Pixel_Clk_Start <= true when buf_col = 1 else false when Column = 0 else Pixel_Clk_Start;

  New_Pixel_Reg_O <= New_Pixel_Div when Pixel_Clk_Enable else '0';






  RAM_DATA_A <= (RAM_Data(15 downto 0) & Second_Byte_Reg(7 downto 0) & First_Byte_Reg(7 downto 0));

  RAM_WREN_A <= (Received_Byte AND Combine_Bytes);
  RAM_Data <= (others => '0') when Start_Reg(1) = '1' else RAM_Data_Out;
  Cam_Init : PROCESS (CLK)  
    VARIABLE state  : NATURAL range 0 to 7 := 7;
    VARIABLE count  : NATURAL range 0 to CLK_Frequency/1000 := 0;

    
  BEGIN
  IF RISING_EDGE(CLK) THEN
    IF (Reset = '1') THEN
      address <= (others => '0');
      state := 7;
      count := 0;
      I2C_Master_Interface_Enable <= '0';
    ELSE
      IF (state = 0) THEN
        I2C_Master_Interface_Address <= "0110110";
        I2C_Master_Interface_RW      <= '0';
        I2C_Master_Interface_Data_Wr <= sreg(23 downto 16);
        I2C_Master_Interface_Enable  <= '1';
        state := 1;
      ELSIF (state = 1) THEN
        IF (I2C_Master_Interface_Busy = '1') THEN
          I2C_Master_Interface_Data_Wr <= sreg(15 downto 8);
          state := 2;
        
        END IF;
      ELSIF (state = 2) THEN
        IF (I2C_Master_Interface_Busy = '0') THEN
          state := 3;
        
        END IF;
      ELSIF (state = 3) THEN
        IF (I2C_Master_Interface_Busy = '1') THEN
          I2C_Master_Interface_Data_Wr <= sreg(7 downto 0);
          state := 4;
        
        END IF;
      ELSIF (state = 4) THEN
        IF (I2C_Master_Interface_Busy = '0') THEN
          I2C_Master_Interface_Enable  <= '0';
          state := 5;
        
        END IF;
      ELSIF (state = 5) THEN
        IF (I2C_Master_Interface_Busy = '1') THEN
          state := 6;
        
        END IF;
      ELSIF (state = 6) THEN
        IF (I2C_Master_Interface_Busy = '0') THEN
          IF (address /= x"61") THEN
            address <= STD_LOGIC_VECTOR(UNSIGNED(address)+1);
            state   := 7;
          
          END IF;
        
        END IF;
      ELSE
        IF (count < CLK_Frequency/1000) THEN
          count := count + 1;
        ELSE
          count := 0;
          state := 0;
        END IF;
      END IF;
    END IF;
  END IF;
  END PROCESS;
  Cam_Init_Register : PROCESS (CLK)  
    VARIABLE Image_Width_Reg : STD_LOGIC_VECTOR (11 downto 0);
    VARIABLE Image_Height_Reg : STD_LOGIC_VECTOR (11 downto 0);
    
  BEGIN
  IF RISING_EDGE(CLK) THEN
    CASE (address) IS
      WHEN x"00" =>
        sreg <=  x"010000";
      WHEN x"01" =>
        sreg <=  x"010301";
      WHEN x"02" =>
        sreg <=  x"303408";
      WHEN x"03" =>
        sreg <=  x"303541";
      WHEN x"04" =>
        sreg <=  x"303646";
      WHEN x"05" =>
        sreg <=  x"303c11";
      WHEN x"06" =>
        sreg <=  x"3106f5";
      WHEN x"07" =>
        sreg <=  x"382107";
      WHEN x"08" =>
        sreg <=  x"382041";
      WHEN x"09" =>
        sreg <=  x"3827ec";
      WHEN x"0A" =>
        sreg <=  x"370c0f";
      WHEN x"0B" =>
        sreg <=  x"361259";
      WHEN x"0C" =>
        sreg <=  x"361800";
      WHEN x"0D" =>
        sreg <=  x"500006";
      WHEN x"0E" =>
        sreg <=  x"500100";
      WHEN x"0F" =>
        sreg <=  x"500240";
      WHEN x"10" =>
        sreg <=  x"500308";
      WHEN x"11" =>
        sreg <=  x"5a0008";
      WHEN x"12" =>
        sreg <=  x"300000";
      WHEN x"13" =>
        sreg <=  x"300100";
      WHEN x"14" =>
        sreg <=  x"300200";
      WHEN x"15" =>
        sreg <=  x"301608";
      WHEN x"16" =>
        sreg <=  x"3017e0";
      WHEN x"17" =>
        sreg <=  x"301844";
      WHEN x"18" =>
        sreg <=  x"301cf8";
      WHEN x"19" =>
        sreg <=  x"301df0";
      WHEN x"1A" =>
        sreg <=  x"3a1800";
      WHEN x"1B" =>
        sreg <=  x"3a19f8";
      WHEN x"1C" =>
        sreg <=  x"3c0180";
      WHEN x"1D" =>
        sreg <=  x"3b070c";
      WHEN x"1E" =>
        sreg <=  x"380c07";
      WHEN x"1F" =>
        sreg <=  x"380d68";
      WHEN x"20" =>
        sreg <=  x"380e03";
      WHEN x"21" =>
        sreg <=  x"380fd8";
      WHEN x"22" =>
        sreg <=  x"381431";
      WHEN x"23" =>
        sreg <=  x"381531";
      WHEN x"24" =>
        sreg <=  x"370864";
      WHEN x"25" =>
        sreg <=  x"370952";
      WHEN x"26" =>
        Image_Width_Reg := STD_LOGIC_VECTOR(TO_UNSIGNED(Image_Width, 12));
        sreg <=  x"38080" & Image_Width_Reg(11 downto 8);
      WHEN x"27" =>
        sreg <=  x"3809" & Image_Width_Reg(7 downto 0);
      WHEN x"28" =>
        Image_Height_Reg := STD_LOGIC_VECTOR(TO_UNSIGNED(Image_Height, 12));
        sreg <=  x"380a0" & Image_Height_Reg(11 downto 8);
      WHEN x"29" =>
        sreg <=  x"380b" & Image_Height_Reg(7 downto 0);
      WHEN x"2A" =>
        sreg <=  x"380000";
      WHEN x"2B" =>
        sreg <=  x"380100";
      WHEN x"2C" =>
        sreg <=  x"380200";
      WHEN x"2D" =>
        sreg <=  x"380300";
      WHEN x"2E" =>
        sreg <=  x"38040a";
      WHEN x"2F" =>
        sreg <=  x"38053f";
      WHEN x"30" =>
        sreg <=  x"380607";
      WHEN x"31" =>
        sreg <=  x"3807a1";
      WHEN x"32" =>
        sreg <=  x"381108";
      WHEN x"33" =>
        sreg <=  x"381302";
      WHEN x"34" =>
        sreg <=  x"36302e";
      WHEN x"35" =>
        sreg <=  x"3632e2";
      WHEN x"36" =>
        sreg <=  x"363323";
      WHEN x"37" =>
        sreg <=  x"363444";
      WHEN x"38" =>
        sreg <=  x"363606";
      WHEN x"39" =>
        sreg <=  x"362064";
      WHEN x"3A" =>
        sreg <=  x"3621e0";
      WHEN x"3B" =>
        sreg <=  x"360037";
      WHEN x"3C" =>
        sreg <=  x"3704a0";
      WHEN x"3D" =>
        sreg <=  x"37035a";
      WHEN x"3E" =>
        sreg <=  x"371578";
      WHEN x"3F" =>
        sreg <=  x"371701";
      WHEN x"40" =>
        sreg <=  x"373102";
      WHEN x"41" =>
        sreg <=  x"370b60";
      WHEN x"42" =>
        sreg <=  x"37051a";
      WHEN x"43" =>
        sreg <=  x"3f0502";
      WHEN x"44" =>
        sreg <=  x"3f0610";
      WHEN x"45" =>
        sreg <=  x"3f010a";
      WHEN x"46" =>
        sreg <=  x"3a0801";
      WHEN x"47" =>
        sreg <=  x"3a0927";
      WHEN x"48" =>
        sreg <=  x"3a0a00";
      WHEN x"49" =>
        sreg <=  x"3a0bf6";
      WHEN x"4A" =>
        sreg <=  x"3a0d04";
      WHEN x"4B" =>
        sreg <=  x"3a0e03";
      WHEN x"4C" =>
        sreg <=  x"3a0f58";
      WHEN x"4D" =>
        sreg <=  x"3a1050";
      WHEN x"4E" =>
        sreg <=  x"3a1b58";
      WHEN x"4F" =>
        sreg <=  x"3a1e50";
      WHEN x"50" =>
        sreg <=  x"3a1160";
      WHEN x"51" =>
        sreg <=  x"3a1f28";
      WHEN x"52" =>
        sreg <=  x"400102";
      WHEN x"53" =>
        sreg <=  x"400402";
      WHEN x"54" =>
        sreg <=  x"400009";
      WHEN x"55" =>
        sreg <=  x"483724";
      WHEN x"56" =>
        sreg <=  x"40506e";
      WHEN x"57" =>
        sreg <=  x"40518f";
      WHEN x"58" =>
        sreg <=  x"503d00";
      WHEN x"59" =>
        sreg <=  x"303701";
      WHEN x"5A" =>
        sreg <=  x"3036" & STD_LOGIC_VECTOR(TO_UNSIGNED((32 * Image_FPS)/26, 8));
      WHEN x"5B" =>
        sreg <=  x"010001";
      WHEN x"5C" =>
        sreg <=  x"010001";
      WHEN x"5D" =>
        sreg <=  x"480004";
      WHEN x"5E" =>
        sreg <=  x"420200";
      WHEN x"5F" =>
        sreg <=  x"300D00";
      WHEN x"60" =>
        sreg <=  x"420200";
      WHEN x"61" =>
        sreg <=  x"300D00";
      WHEN others =>
        sreg <=  x"FFFFFF";
    END CASE;
  END IF;
  END PROCESS;
  I2C_Master_Interface1 : I2C_Master_Interface
  GENERIC MAP (
      CLK_Frequency => CLK_Frequency,
    Bus_CLK       => 400000

  ) PORT MAP (
    CLK => CLK,
    Reset         => Reset,
    Enable        => I2C_Master_Interface_Enable,
    Address       => I2C_Master_Interface_Address,  
    RW            => I2C_Master_Interface_RW,
    Data_Wr       => I2C_Master_Interface_Data_Wr,
    Busy          => I2C_Master_Interface_Busy,
    Data_RD       => I2C_Master_Interface_Data_RD,
    Ack_Error     => I2C_Master_Interface_Ack_Error,
    SDA           => SDA,
    SCL           => SCL

    
  );
  Cam_RX : PROCESS (New_Pixel)
    VARIABLE start_buf_reg : STD_LOGIC;
    
  BEGIN
    IF (rising_edge(New_Pixel)) THEN
      IF (start_buf /= start_buf_reg) THEN
        Column <= 0;
        Row    <= 0;
      ELSE
        IF (Column < Image_Width-1) THEN
          Column <= Column + 1;
        ELSE
          IF (Row < Image_Height-1) THEN
            Row    <= Row + 1;
            Column <= 0;
          
          END IF;
        END IF;
      END IF;
      start_buf_reg := start_buf;
    
    END IF;
  END PROCESS;
  ALTSYNCRAM1 : ALTSYNCRAM
  GENERIC MAP (
      address_reg_b => "CLOCK1",
    clock_enable_input_a => "BYPASS",
    clock_enable_input_b => "BYPASS",
    clock_enable_output_b => "BYPASS",
    intended_device_family => "unused",
    lpm_type => "altsyncram",
    numwords_a => 1024,
    numwords_b => 1024,
    operation_mode => "DUAL_PORT",
    outdata_reg_b => "CLOCK1",
    widthad_a => 10,
    widthad_b => 10,
    width_a => 24,
    width_b => 24

  ) PORT MAP (
    address_a => RAM_Addr_A,
    address_b => RAM_Addr_B,
    clock0 => New_Pixel_Reg,
    clock1 => New_Pixel_Reg_O,
    data_a => Cur_Pixel_Reg_I,
    wren_a => '1',
    q_b => Cur_Pixel_Reg

    
  );
  PROCESS (New_Pixel_Reg)
    
  BEGIN
    IF (rising_edge(New_Pixel_Reg)) THEN
      IF (Start_Reg(0) = '1') THEN
        buf_col <= 0;

        start_buf <= not start_buf;
      ELSE
        IF (buf_col < Image_Width-1) THEN
          buf_col <= buf_col + 1;
        ELSE
          buf_col <= 0;
        END IF;
      END IF;
      Cur_Pixel_Reg_I <= Pixel_R_Reg & Pixel_G_Reg & Pixel_B_Reg;
    
    END IF;
  END PROCESS;
  PROCESS (New_Pixel_Div)
    
  BEGIN
    IF (falling_edge(New_Pixel_Div)) THEN
      Pixel_Clk_Enable <= Column < Image_Width-1 OR Pixel_Clk_Start;
    
    END IF;
  END PROCESS;
  Generate1 : if pixel_clk_divider < 2 OR CLK_as_PCLK GENERATE
    New_Pixel_Div <= CLK;
  END GENERATE Generate1;
  Generate2 : if pixel_clk_divider > 1 AND NOT CLK_as_PCLK GENERATE
    PROCESS (CLK)  
      VARIABLE div_count  : NATURAL range 0 to pixel_clk_divider-1 := 0;

      
    BEGIN
    IF RISING_EDGE(CLK) THEN
      IF (div_count < pixel_clk_divider-1) THEN
        div_count := div_count + 1;
      ELSE
        div_count := 0;
      END IF;
      IF (div_count < pixel_clk_divider/2) THEN
        New_Pixel_Div <= '1';
      ELSE
        New_Pixel_Div <= '0';
      END IF;
    END IF;
    END PROCESS;
  END GENERATE Generate2;
  ALTDDIO_IN1 : ALTDDIO_IN
  GENERIC MAP (
      intended_device_family => "unused",
    width                  => 2

  ) PORT MAP (
    datain                 => Data_Lane,
    inclock                => CLK_Lane,
    dataout_h              => Data_H,
    dataout_l              => Data_L

    
  );
  ALTSYNCRAM2 : ALTSYNCRAM
  GENERIC MAP (
      address_reg_b                      => "CLOCK0",
    clock_enable_input_a               => "BYPASS",
    clock_enable_input_b               => "BYPASS",
    clock_enable_output_b              => "BYPASS",
    intended_device_family             => "unused",
    numwords_a                         => 1024,
    numwords_b                         => 1024,
    operation_mode                     => "DUAL_PORT",
    width_a                            => 32,
    width_b                            => 32,
    width_byteena_a                    => 1,
    widthad_a                          => 10,
    widthad_b                          => 10

  ) PORT MAP (
    address_a                          => RAM_Addr(9 downto 0),
    address_b                          => RAM_Addr(9 downto 0),
    clock0                             => CLK_Lane,
    data_a                             => RAM_DATA_A,
    q_b                                => RAM_Data_Out,
    wren_a                             => RAM_WREN_A
  );
  PROCESS (CLK_Lane)
    VARIABLE First_Byte_Data, Second_Byte_Data : STD_LOGIC_VECTOR(7 downto 0);
  BEGIN
    IF (rising_edge(CLK_Lane)) THEN
      IF (Byte_Start_Phase) THEN
        First_Byte_Reg <= "000" & Data_H(0) & Data_L(0) & First_Byte_Reg(8 downto 2);
        Second_Byte_Reg <= "000" & Data_H(1) & Data_L(1) & Second_Byte_Reg(8 downto 2);
      ELSE
        First_Byte_Reg <= "00" & Data_H(0) & Data_L(0) & First_Byte_Reg(9 downto 2);
        Second_Byte_Reg <= "00" & Data_H(1) & Data_L(1) & Second_Byte_Reg(9 downto 2);
      END IF;
      First_Byte_Data  := First_Byte_Reg(7 downto 0);
      Second_Byte_Data := Second_Byte_Reg(7 downto 0);
      IF (First_Byte_Reg(1 downto 0) = "00" AND Second_Byte_Reg(1 downto 0) = "00") THEN
        IF (Zero_Count < 4) THEN
          Zero_Count <= Zero_Count + 1;
        
        END IF;
      ELSE
        Zero_Count <= 0;
      END IF;

      Bit_Count <= Bit_Count + 1;

      Received_Byte    <= '0';
      IF (First_Byte_Data = "10111000" AND Second_Byte_Data = "10111000" AND Zero_Count = 4 AND Combine_Bytes = '0') THEN
        Bit_Count  <= 0;
        Byte_Count <= 1;
      ELSIF (First_Byte_Data = "10111000" AND Second_Byte_Data = "10111000" AND Zero_Count = 4 AND Combine_Bytes = '0') THEN
        Bit_Count  <= 0;
        Byte_Count <= 1;
        Byte_Start_Phase <= NOT Byte_Start_Phase;
        IF (Byte_Start_Phase) THEN
          First_Byte_Reg  <= "00" & Data_H(0) & Data_L(0) & First_Byte_Reg(8 downto 1);
          Second_Byte_Reg <= "00" & Data_H(1) & Data_L(1) & Second_Byte_Reg(8 downto 1);
        ELSE
          First_Byte_Reg  <= "000" & Data_H(0) & Data_L(0) & First_Byte_Reg(9 downto 3);
          Second_Byte_Reg <= "000" & Data_H(1) & Data_L(1) & Second_Byte_Reg(9 downto 3);
        END IF;
      ELSIF (Bit_Count = 2) THEN
        Received_Byte <= '1';
      
      END IF;


      Second_New_Pixel <= First_New_Pixel(1) AND NOT Start_Reg(0);
      First_New_Pixel  <= First_New_Pixel(0) & '0';
      IF (Received_Byte = '1') THEN
        IF (Byte_Count = 1) THEN
          Byte_Count <= 2;
          IF (First_Byte_Data = x"00") THEN
            Start_Reg          <= "01"; 
            First_New_Pixel(0) <= '1';
            Convert_Type       <= 0;
          ELSIF (First_Byte_Data = x"2A") THEN
            Combine_Bytes     <= '1';
            RAM_Addr(7 downto 0) <= Second_Byte_Data(7 downto 0);
          
          END IF;
        ELSIF (Byte_Count = 2) THEN
          Byte_Count   <= 0;
          Start_Reg    <= Start_Reg(0) & '0';
          IF (Combine_Bytes = '1') THEN
            RAM_Addr(15 downto 0) <= STD_LOGIC_VECTOR(UNSIGNED(First_Byte_Data & RAM_Addr(7 downto 0))-2);
          
          END IF;
          Last_Bytes_Buf  <= (others => '0');
        ELSIF (Combine_Bytes = '1') THEN
          Last_Bytes_Buf <= UNSIGNED(RAM_Data & Second_Byte_Data & First_Byte_Data);
          IF (Convert_Type = 1) THEN
            Pixel1.R(1) <= resize(shift_right(('0' & Last_Bytes_Buf(47 downto 40)) + ('0' & Last_Bytes_Buf(15 downto 8)), 1), 8);
            Pixel1.G(1) <= resize(shift_right(('0' & Last_Bytes_Buf(31 downto 24) & "00") + UNSIGNED("000" & First_Byte_Data) + ("000" & Last_Bytes_Buf(7 downto 0)) + ("000" & Last_Bytes_Buf(39 downto 32)) + UNSIGNED("000" & RAM_Data(23 downto 16)), 3), 8);
            Pixel1.B(1) <= resize(shift_right(('0' & Last_Bytes_Buf(23 downto 16)) + ('0' & Last_Bytes_Buf(7 downto 0)), 1), 8);
            Pixel2.R(1) <= resize(shift_right(("00" & Last_Bytes_Buf(47 downto 40)) + UNSIGNED("00" & RAM_Data(31 downto 24)) + ("00" & Last_Bytes_Buf(15 downto 8)) + UNSIGNED("00" & Second_Byte_Data), 2), 8);
            Pixel2.G(1) <= resize(shift_right(("00" & Last_Bytes_Buf(31 downto 24)) + UNSIGNED("00" & RAM_Data(15 downto 8)) + UNSIGNED("00" & RAM_Data(23 downto 16)) + UNSIGNED("00" & First_Byte_Data), 2), 8);
            Pixel2.B(1) <= UNSIGNED(RAM_Data(7 downto 0));
          ELSE
            Pixel1.R(0) <= Last_Bytes_Buf(31 downto 24);
            Pixel1.G(0) <= resize(shift_right(("00" & Last_Bytes_Buf(47 downto 40)) + UNSIGNED("00" & RAM_Data(7 downto 0)) + ("00" & Last_Bytes_Buf(15 downto 8)) + ("00" & Last_Bytes_Buf(23 downto 16)), 2), 8);
            Pixel1.B(0) <= resize(shift_right(("00" & Last_Bytes_Buf(39 downto 32)) + UNSIGNED("00" & RAM_Data(23 downto 16)) + ("00" & Last_Bytes_Buf(7 downto 0)) + UNSIGNED("00" & First_Byte_Data), 2), 8);
            Pixel2.R(0) <= resize(shift_right(('0' & Last_Bytes_Buf(31 downto 24)) + UNSIGNED('0' & RAM_Data(15 downto 8)), 1), 8);
            Pixel2.G(0) <= resize(shift_right(UNSIGNED('0' & RAM_Data(7 downto 0) & "00") + UNSIGNED("000" & Second_Byte_Data) + ("000" & Last_Bytes_Buf(15 downto 8)) + ("000" & Last_Bytes_Buf(47 downto 40)) + UNSIGNED("000" & RAM_Data(31 downto 24)), 3), 8);
            Pixel2.B(0) <= resize(shift_right(UNSIGNED('0' & RAM_Data(23 downto 16)) + UNSIGNED('0' & First_Byte_Data), 1), 8);
          END IF;
          First_New_Pixel(0) <= '1';
          IF (RAM_Addr = x"0000") THEN
            Combine_Bytes <= '0';
            Convert_Type  <= Convert_Type + 1;
          ELSE
            RAM_Addr <= STD_LOGIC_VECTOR(UNSIGNED(RAM_Addr)-2);
          END IF;
        END IF;
      END IF;
    END IF;
  END PROCESS;
  
END BEHAVIORAL;
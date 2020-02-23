  
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all; 
use work.Image_Data_Package.all;


ENTITY Blob_Detect IS
  GENERIC (
      Blob_Number     : NATURAL := 32;
    Blob_Buffer     : NATURAL := 8;
    Edge_Reg_Size   : NATURAL := 3;
    Min_Blob_Width  : NATURAL := 4;
    Min_Blob_Height : NATURAL := 2;
    Max_Blob_Width  : NATURAL := 20;
    Max_Blob_Height : NATURAL := 15;
    Upscale_Mult    : NATURAL := 4;
    Upscale_Start   : NATURAL := 100 

  );
PORT (
  CLK : IN STD_LOGIC;
  New_Pixel : IN STD_LOGIC;
  Pixel_In  : IN STD_LOGIC; 
  Column    : IN NATURAL range 0 to 639;
  Row       : IN NATURAL range 0 to 479;
  Blob_Busy : OUT STD_LOGIC := '0';
  Blobs     : OUT NATURAL range 0 to Blob_Number;
  Blob_Addr : IN  NATURAL range 0 to Blob_Number-1;
  Blob_X0   : OUT NATURAL range 0 to Image_Width-1;
  Blob_X1   : OUT NATURAL range 0 to Image_Width-1;
  Blob_Y0   : OUT NATURAL range 0 to Image_Height-1;
  Blob_Y1   : OUT NATURAL range 0 to Image_Height-1

);
END Blob_Detect;

ARCHITECTURE BEHAVIORAL OF Blob_Detect IS

  CONSTANT Compression : NATURAL := 2;
  TYPE blob_type IS RECORD
  x0 : NATURAL range 0 to Image_Width-1;
  x1 : NATURAL range 0 to Image_Width-1;
  y0 : NATURAL range 0 to Image_Height-1;
  y1 : NATURAL range 0 to Image_Height-1;
  END RECORD blob_type;
  TYPE blob_array IS ARRAY (natural range <>) OF blob_type;
  SIGNAL blob_reg : blob_array(0 to Blob_Buffer-1);
  SIGNAL blob_ram_data_in  : STD_LOGIC_VECTOR (35 downto 0);
  SIGNAL blob_ram_data_out : STD_LOGIC_VECTOR (35 downto 0);
  SIGNAL blob_ram_copy_in  : STD_LOGIC_VECTOR (35 downto 0);
  SIGNAL blob_ram_copy_out : STD_LOGIC_VECTOR (35 downto 0);
  SIGNAL blob_ram_copy_addr_in  : NATURAL range 0 to Blob_Number-1;
  SIGNAL blob_ram_copy_addr_out : NATURAL range 0 to Blob_Number-1;
  SIGNAL blob_in      : blob_type;
  SIGNAL in_blob_num  : NATURAL range 0 to Blob_Number-1;
  FUNCTION log2 ( x : positive) RETURN  natural IS
    variable i : natural;
  BEGIN
    i := 0;
    WHILE 2**i < x and i < 31 LOOP
      i := i + 1;
    END LOOP;
  
    return i;
  END FUNCTION;
  SIGNAL ram1_in_addr  : STD_LOGIC_VECTOR (log2(Blob_Number)-1 downto 0);
  SIGNAL ram1_out_addr : STD_LOGIC_VECTOR (log2(Blob_Number)-1 downto 0);
  SIGNAL ram2_in_addr  : STD_LOGIC_VECTOR (log2(Blob_Number)-1 downto 0);
  SIGNAL ram2_out_addr : STD_LOGIC_VECTOR (log2(Blob_Number)-1 downto 0);
  SIGNAL used_blobs : STD_LOGIC_VECTOR (0 to Blob_Buffer-1) := (others => '0');
  SIGNAL next_blob : NATURAL range 0 to Blob_Buffer := 0;
  TYPE edge_reg_type IS ARRAY (0 to Edge_Reg_Size-1) OF NATURAL range 0 to Image_Width-1;
  SIGNAL Blobs_Reg     : NATURAL range 0 to Blob_Number;
  SIGNAL Blobs_Buf     : NATURAL range 0 to Blob_Number+1;
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
  
BEGIN


  ram1_out_addr <= STD_LOGIC_VECTOR(TO_UNSIGNED(blob_ram_copy_addr_in,log2(Blob_Number)));
  ram1_in_addr <= STD_LOGIC_VECTOR(TO_UNSIGNED(Blob_Addr,log2(Blob_Number)));


  ram2_out_addr <= STD_LOGIC_VECTOR(TO_UNSIGNED(in_blob_num,log2(Blob_Number)));
  ram2_in_addr <= STD_LOGIC_VECTOR(TO_UNSIGNED(blob_ram_copy_addr_out,log2(Blob_Number)));
  blob_ram_data_in <= STD_LOGIC_VECTOR(TO_UNSIGNED(blob_in.y1, 9)) & STD_LOGIC_VECTOR(TO_UNSIGNED(blob_in.y0, 9)) &
  STD_LOGIC_VECTOR(TO_UNSIGNED(blob_in.x1/Compression, 9)) & STD_LOGIC_VECTOR(TO_UNSIGNED(blob_in.x0/Compression, 9));
  Blob_X0 <= TO_INTEGER(UNSIGNED(blob_ram_data_out(8 downto 0)))*Compression;
  Blob_X1 <= TO_INTEGER(UNSIGNED(blob_ram_data_out(17 downto 9)))*Compression;
  Blob_Y0 <= TO_INTEGER(UNSIGNED(blob_ram_data_out(26 downto 18)));
  Blob_Y1 <= TO_INTEGER(UNSIGNED(blob_ram_data_out(35 downto 27)));
  ALTSYNCRAM1 : ALTSYNCRAM
  GENERIC MAP (
      address_reg_b => "CLOCK0",
    clock_enable_input_a => "BYPASS",
    clock_enable_input_b => "BYPASS",
    clock_enable_output_b => "BYPASS",
    intended_device_family => "unused",
    numwords_a => Blob_Number,
    numwords_b => Blob_Number,
    operation_mode => "DUAL_PORT",
    outdata_reg_b => "CLOCK0",
    widthad_a => log2(Blob_Number),
    widthad_b => log2(Blob_Number),
    width_a => 36,
    width_b => 36,
    width_byteena_a => 1

  ) PORT MAP (
    address_a => ram1_out_addr,
    address_b => ram1_in_addr,
    clock0 => New_Pixel,
    data_a => blob_ram_copy_in,
    wren_a => '1',
    q_b => blob_ram_data_out

    
  );
  ALTSYNCRAM2 : ALTSYNCRAM
  GENERIC MAP (
      address_reg_b => "CLOCK0",
    clock_enable_input_a => "BYPASS",
    clock_enable_input_b => "BYPASS",
    clock_enable_output_b => "BYPASS",
    intended_device_family => "unused",
    numwords_a => Blob_Number,
    numwords_b => Blob_Number,
    operation_mode => "DUAL_PORT",
    outdata_reg_b => "CLOCK0",
    widthad_a => log2(Blob_Number),
    widthad_b => log2(Blob_Number),
    width_a => 36,
    width_b => 36,
    width_byteena_a => 1

  ) PORT MAP (
    address_a => ram2_out_addr,
    address_b => ram2_in_addr,
    clock0 => New_Pixel,
    data_a => blob_ram_data_in,
    wren_a => '1',
    q_b => blob_ram_copy_out
  );
  PROCESS (New_Pixel)
    VARIABLE Row_Reg      : NATURAL range 0 to Image_Height-1 := 0;
    VARIABLE reg_length : NATURAL range 0 to Edge_Reg_Size := 0;
    VARIABLE start_x : NATURAL range 0 to Image_Width-1 := 0;
    VARIABLE start_x_reg : edge_reg_type := (others => 0);
    VARIABLE end_x   : NATURAL range 0 to Image_Width-1 := 0;
    VARIABLE end_x_reg : edge_reg_type := (others => 0);
    VARIABLE cur_blob : NATURAL range 0 to Blob_Number-1;
    VARIABLE Pixel_In_Reg : STD_LOGIC;
    VARIABLE calc_max_h : NATURAL range 0 to Image_Height-1;
    VARIABLE calc_max_w : NATURAL range 0 to Image_Width-1;
    VARIABLE calc_min_h : NATURAL range 0 to Image_Height-1;
    VARIABLE calc_min_w : NATURAL range 0 to Image_Width-1;
    VARIABLE scale : NATURAL range 1 to Upscale_Mult+1 := 1;
    VARIABLE h_scale_div : NATURAL range 0 to Image_Height;
    VARIABLE w_scale_div : NATURAL range 0 to Image_Width;
    VARIABLE copy : BOOLEAN;
    VARIABLE found  : BOOLEAN;
    VARIABLE find_i : NATURAL range 0 to Blob_Buffer;
    VARIABLE x0 : NATURAL range 0 to Image_Width-1;
    VARIABLE x1 : NATURAL range 0 to Image_Width-1;
    VARIABLE x0_reg : NATURAL range 0 to Image_Width-1;
    VARIABLE x1_reg : NATURAL range 0 to Image_Width-1;
    VARIABLE y0_reg : NATURAL range 0 to Image_Height-1;
    VARIABLE y1_reg : NATURAL range 0 to Image_Height-1;
    VARIABLE this_find_i : NATURAL range 0 to Blob_Buffer;
    VARIABLE found_reg : BOOLEAN;
    VARIABLE find_i_reg : NATURAL range 0 to Blob_Buffer;
  BEGIN
    IF (falling_edge(New_Pixel)) THEN
      IF (Row < Row_Reg) THEN
        copy := true;
        Blobs_Buf <= 0;
        find_i := 0;
      
      END IF;
      Row_Reg := Row;
      IF (copy) THEN
        Blob_Busy <= '1';
      ELSE
        Blob_Busy <= '0';
      END IF;
      IF (Pixel_In = '1' AND Pixel_In_Reg = '0') THEN
        start_x_reg(0) := Column;
        start_x_reg(1 to Edge_Reg_Size-1) := start_x_reg(0 to Edge_Reg_Size-2);
      
      END IF;
      IF (Pixel_In = '0' AND Pixel_In_Reg = '1') THEN
        end_x_reg(0) := Column;
        end_x_reg(1 to Edge_Reg_Size-1) := end_x_reg(0 to Edge_Reg_Size-2);
        IF (reg_length < Edge_Reg_Size) THEN
          reg_length := reg_length + 1;
        
        END IF;
      
      END IF;
      Pixel_In_Reg := Pixel_In;
      IF (found AND reg_length > 0) THEN
        reg_length := reg_length - 1;
        end_x := end_x_reg(reg_length);
        start_x := start_x_reg(reg_length);


        found  := false;
        found_reg := false;
        find_i := 0;
      
      END IF;
      IF (Row > Upscale_Start) THEN
        scale := (((Row-Upscale_Start)*Upscale_Mult) / (Image_Height-Upscale_Start))+1;
      ELSE
        scale := 1;
      END IF;
      IF (scale > Upscale_Mult) THEN
        scale := Upscale_Mult;
      
      END IF;


      h_scale_div := Image_Height/scale;
      w_scale_div := Image_Width/scale;
      IF (Max_Blob_Height > h_scale_div) THEN
        calc_max_h := Image_Height-1;
      ELSE
        calc_max_h := Max_Blob_Height * scale;
      END IF;
      IF (Max_Blob_Width > w_scale_div) THEN
        calc_max_w := Image_Height-1;
      ELSE
        calc_max_w := Max_Blob_Width * scale;
      END IF;
      IF (Min_Blob_Height > h_scale_div) THEN
        calc_min_h := Image_Height-1;
      ELSE
        calc_min_h := Min_Blob_Height * scale;
      END IF;
      IF (Min_Blob_Width > w_scale_div) THEN
        calc_min_w := Image_Height-1;
      ELSE
        calc_min_w := Min_Blob_Width * scale;
      END IF;
      IF (not found or copy) THEN
        IF (find_i < Blob_Buffer) THEN
          IF (used_blobs(find_i) = '1') THEN
            IF (found_reg AND NOT copy) THEN
              this_find_i := find_i_reg;
            ELSE
              this_find_i := find_i;
            END IF;
            x0 := blob_reg(find_i).x0; 
            x1 := blob_reg(find_i).x1;
            x0_reg := blob_reg(this_find_i).x0; 
            x1_reg := blob_reg(this_find_i).x1;
            y0_reg := blob_reg(this_find_i).y0;
            y1_reg := blob_reg(this_find_i).y1;
            IF (NOT copy AND x0 <= end_x AND x1 >= start_x AND y1_reg >= Row-1) THEN
              IF (found_reg) THEN
                used_blobs(find_i) <= '0';
                IF (find_i < next_blob) THEN
                  next_blob <= find_i;
                
                END IF;
                IF (x0 > start_x) THEN
                  x0 := start_x;
                
                END IF;
                IF (x1 < end_x) THEN
                  x1 := end_x;
                
                END IF;
              ELSE
                found_reg := true;
                find_i_reg := find_i;
                x0 := start_x;
                x1 := end_x;
              END IF;
              blob_reg(this_find_i).y1 <= Row;
              IF (x0_reg > x0) THEN
                x0_reg := x0;
              
              END IF;
              IF (x1_reg < x1) THEN
                x1_reg := x1;
              
              END IF;
              blob_reg(this_find_i).x0 <= x0_reg;
              blob_reg(this_find_i).x1 <= x1_reg;
            ELSIF (y1_reg < Row-1 OR copy) THEN
              IF (y1_reg-y0_reg >= calc_min_h AND x1_reg-x0_reg >= calc_min_w) THEN
                blob_in <= blob_reg(find_i);
                in_blob_num <= cur_blob;
                cur_blob := cur_blob + 1;
              
              END IF;
              used_blobs(find_i) <= '0';
              IF (find_i < next_blob) THEN
                next_blob <= find_i;
              END IF;
            
            END IF;
          
          END IF;
          FOR i IN 0 to Blob_Buffer-1 LOOP
            IF (used_blobs(i) = '1' AND i > find_i) THEN
              find_i := i;
              exit;
            ELSIF (i = Blob_Buffer-1) THEN
              find_i := Blob_Buffer;
              exit;
            
            END IF;
          END LOOP;
          IF (copy AND find_i = Blob_Buffer) THEN
            Blobs_Reg <= cur_blob;
            blob_ram_copy_addr_out <= 0;
          
          END IF;
        ELSIF (copy) THEN
          IF (Blobs_Buf > 1) THEN
            blob_ram_copy_addr_in  <= Blobs_Buf-2;
            blob_ram_copy_in <= blob_ram_copy_out;
          
          END IF;
          IF (cur_blob > 0) THEN
            blob_ram_copy_addr_out <= Blobs_Buf;
            Blobs_Buf <= Blobs_Buf + 1;
            cur_blob := cur_blob - 1;
          ELSIF (Blobs_Buf < Blobs_Reg+1) THEN
            Blobs_Buf <= Blobs_Buf + 1;
          ELSE
            Blobs <= Blobs_Reg;
            copy       := false;
            next_blob  <= 0;
            used_blobs <= (others => '0');
          END IF;
        ELSE
          IF (not found_reg) THEN
            IF (next_blob < Blob_Buffer) THEN
              blob_reg(next_blob).x0 <= start_x;
              blob_reg(next_blob).x1 <= end_x;
              blob_reg(next_blob).y0 <= Row;
              blob_reg(next_blob).y1 <= Row;
              used_blobs(next_blob) <= '1';
              FOR i IN 0 to Blob_Buffer-1 LOOP
                IF (used_blobs(i) = '0' AND i /= next_blob) THEN
                  next_blob <= i;
                  exit;
                ELSIF (i = Blob_Buffer-1) THEN
                  next_blob <= Blob_Buffer;
                  exit;
                END IF;
              END LOOP;
            END IF;
          END IF;
          found := true;
        END IF;
      END IF;
    END IF;
  END PROCESS;
  
END BEHAVIORAL;
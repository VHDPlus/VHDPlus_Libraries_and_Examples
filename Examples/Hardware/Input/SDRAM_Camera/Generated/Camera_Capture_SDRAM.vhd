  
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all; 


ENTITY Camera_Capture_SDRAM IS
  GENERIC (
      Burst_Length : NATURAL := 8

  );
PORT (
  CLK : IN STD_LOGIC;
  New_Pixel   : IN    STD_LOGIC := '0';
  Column      : IN    NATURAL range 0 to 639 := 0;
  Row         : IN    NATURAL range 0 to 479 := 0;
  Pixel_R     : IN    STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
  Pixel_G     : IN    STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
  Pixel_B     : IN    STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
  SDRAM_ADDR  : OUT   STD_LOGIC_VECTOR(11 downto 0);
  SDRAM_BA    : OUT   STD_LOGIC_VECTOR(1 downto 0);
  SDRAM_DQ    : INOUT STD_LOGIC_VECTOR(15 downto 0);
  SDRAM_DQM   : OUT   STD_LOGIC_VECTOR(1 downto 0);
  SDRAM_CASn  : OUT   STD_LOGIC;
  SDRAM_CKE   : OUT   STD_LOGIC;
  SDRAM_CSn   : OUT   STD_LOGIC;
  SDRAM_RASn  : OUT   STD_LOGIC;
  SDRAM_WEn   : OUT   STD_LOGIC;
  SDRAM_CLK   : OUT   STD_LOGIC;
  Read_Column : IN     NATURAL range 0 to 639 := 0;
  Read_Row    : IN     NATURAL range 0 to 479 := 0;
  Read_Data   : BUFFER STD_LOGIC_VECTOR(23 downto 0) := (others => '0');
  Read_Ena    : IN     STD_LOGIC := '0'

);
END Camera_Capture_SDRAM;

ARCHITECTURE BEHAVIORAL OF Camera_Capture_SDRAM IS

  SIGNAL RAM_CLK : STD_LOGIC;
  SIGNAL CTL_CLK : STD_LOGIC;
  CONSTANT pixel_number : NATURAL := (Burst_Length*2)/3;
  TYPE burst_data_type IS ARRAY (0 to Burst_Length-1) OF STD_LOGIC_VECTOR(15 downto 0);
  SIGNAL save_buf      : burst_data_type := (others => (others => '0'));
  SIGNAL save_ram_buf  : burst_data_type := (others => (others => '0'));
  SIGNAL start_save    : BOOLEAN := false;
  SIGNAL Save_RAM_Addr : NATURAL range 0 to (640*480)/pixel_number := 0;
  SIGNAL save_pixel_reg   : NATURAL range 0 to pixel_number-1 := 0;
  SIGNAL save_buf_raddr : NATURAL range 0 to Burst_Length-1 := 0;
  SIGNAL save_buf_waddr : NATURAL range 0 to Burst_Length-1 := 0;
  SIGNAL save_buf_wr    : BOOLEAN := false;
  SIGNAL save_buf_rdata : STD_LOGIC_VECTOR(15 downto 0);
  SIGNAL save_buf_wdata : STD_LOGIC_VECTOR(15 downto 0);
  SIGNAL save_ram_buf_raddr : NATURAL range 0 to Burst_Length-1 := 0;
  SIGNAL save_ram_buf_waddr : NATURAL range 0 to Burst_Length-1 := 0;
  SIGNAL save_ram_buf_wr    : BOOLEAN := false;
  SIGNAL save_ram_buf_rdata : STD_LOGIC_VECTOR(15 downto 0);
  SIGNAL save_ram_buf_wdata : STD_LOGIC_VECTOR(15 downto 0);
  SIGNAL Read_Addr      : NATURAL range 0 to (640*480)/pixel_number := 0;
  SIGNAL Read_RAM_Addr  : NATURAL range 0 to (640*480)/pixel_number := 0;
  SIGNAL read_buf     : burst_data_type := (others => (others => '0'));
  SIGNAL read_ram_buf : burst_data_type := (others => (others => '0'));
  SIGNAL start_read   : BOOLEAN := false;
  SIGNAL read_buf_raddr : NATURAL range 0 to Burst_Length-1 := 0;
  SIGNAL read_buf_waddr : NATURAL range 0 to Burst_Length-1 := 0;
  SIGNAL read_buf_wr    : BOOLEAN := false;
  SIGNAL read_buf_rdata : STD_LOGIC_VECTOR(15 downto 0);
  SIGNAL read_buf_wdata : STD_LOGIC_VECTOR(15 downto 0);
  SIGNAL read_ram_buf_raddr : NATURAL range 0 to Burst_Length-1 := 0;
  SIGNAL read_ram_buf_waddr : NATURAL range 0 to Burst_Length-1 := 0;
  SIGNAL read_ram_buf_wr    : BOOLEAN := false;
  SIGNAL read_ram_buf_rdata : STD_LOGIC_VECTOR(15 downto 0);
  SIGNAL read_ram_buf_wdata : STD_LOGIC_VECTOR(15 downto 0);
  SIGNAL Read_Data_R : STD_LOGIC_VECTOR(7 downto 0);
  SIGNAL Read_Data_G : STD_LOGIC_VECTOR(7 downto 0);
  SIGNAL Read_Data_B : STD_LOGIC_VECTOR(7 downto 0);
  SIGNAL ISSP_source : std_logic_vector (7 downto 0) := (others => '0');
  SIGNAL ISSP_probe  : std_logic_vector (31 downto 0);
  SIGNAL RAM_Step : NATURAL range 0 to Burst_Length := 0;
  SIGNAL SDRAM_address        : std_logic_vector (21 downto 0) := (others => '0');
  SIGNAL SDRAM_writedata      : std_logic_vector (15 downto 0) := (others => '0');
  SIGNAL SDRAM_read_n         : std_logic := '1';
  SIGNAL SDRAM_write_n        : std_logic := '1';
  SIGNAL SDRAM_readdata       : std_logic_vector (15 downto 0) := (others => '0');
  SIGNAL SDRAM_readdatavalid  : std_logic;
  SIGNAL SDRAM_waitrequest    : std_logic;
  SIGNAL SDRAM_Reset          : STD_LOGIC := '0';
  SIGNAL copy_buffer_reg : BOOLEAN;
  SIGNAL read_pixel_reg : NATURAL;
  COMPONENT ISSP IS
  
  PORT (
    source : out std_logic_vector(7 downto 0);                      
    probe  : in  std_logic_vector(31 downto 0)  := (others => 'X') 

  );
  END COMPONENT;
  COMPONENT SDRAM IS
  
  PORT (
    clk_in_clk       : in    std_logic                     := '0';             
    reset_reset_n    : in    std_logic                     := '0';             
    s1_address       : in    std_logic_vector(21 downto 0) := (others => '0'); 
    s1_byteenable_n  : in    std_logic_vector(1 downto 0)  := (others => '0'); 
    s1_chipselect    : in    std_logic                     := '0';             
    s1_writedata     : in    std_logic_vector(15 downto 0) := (others => '0'); 
    s1_read_n        : in    std_logic                     := '0';             
    s1_write_n       : in    std_logic                     := '0';             
    s1_readdata      : out   std_logic_vector(15 downto 0);                    
    s1_readdatavalid : out   std_logic;                                        
    s1_waitrequest   : out   std_logic;                                        
    sdram_addr       : out   std_logic_vector(11 downto 0);                    
    sdram_ba         : out   std_logic_vector(1 downto 0);                     
    sdram_cas_n      : out   std_logic;                                        
    sdram_cke        : out   std_logic;                                        
    sdram_cs_n       : out   std_logic;                                        
    sdram_dq         : inout std_logic_vector(15 downto 0) := (others => '0'); 
    sdram_dqm        : out   std_logic_vector(1 downto 0);                     
    sdram_ras_n      : out   std_logic;                                        
    sdram_we_n       : out   std_logic                                         

  );
  END COMPONENT;
  
BEGIN

  SDRAM_CLK <= RAM_CLK;


  CTL_CLK <= CLK;
  RAM_CLK <= NOT CLK;
  save_buf_rdata <= save_buf(save_buf_raddr);
  save_ram_buf_rdata <= save_ram_buf(save_ram_buf_raddr);
  read_buf_rdata <= read_buf(read_buf_raddr);
  read_ram_buf_rdata <= read_ram_buf(read_ram_buf_raddr);
  PROCESS (CTL_CLK)
    
  BEGIN
    IF (rising_edge(CTL_CLK)) THEN
      IF (save_buf_wr) THEN
        save_buf(save_buf_waddr) <= save_buf_wdata;
      
      END IF;
    
    END IF;
  END PROCESS;
  PROCESS (CTL_CLK)
    
  BEGIN
    IF (rising_edge(CTL_CLK)) THEN
      IF (save_ram_buf_wr) THEN
        save_ram_buf(save_ram_buf_waddr) <= save_ram_buf_wdata;
      
      END IF;
    
    END IF;
  END PROCESS;
  Save_Process : PROCESS (CTL_CLK)
    VARIABLE New_Pixel_Reg : STD_LOGIC := '0';
    VARIABLE save_pixel   : NATURAL range 0 to pixel_number-1 := 0;
    VARIABLE Request_Addr : NATURAL range 0 to (640*480)/pixel_number;
    VARIABLE write_save_buf  : BOOLEAN := false;
    VARIABLE data_save_buf1  : STD_LOGIC_VECTOR(23 downto 0);
    VARIABLE data_save_buf   : STD_LOGIC_VECTOR(47 downto 0);
    VARIABLE copy_buffer : BOOLEAN := false;
    VARIABLE write_count : NATURAL range 0 to 2 := 0;
    
  BEGIN
    IF (falling_edge(CTL_CLK)) THEN
      IF (New_Pixel = '1' AND New_Pixel_Reg = '0') THEN
        Request_Addr := (Row*640+Column)/pixel_number;
        save_pixel   := (Row*640+Column)-Request_Addr*pixel_number;
        IF (save_pixel = 0) THEN
          copy_buffer     := true;
          start_save      <= true;
          save_buf_raddr  <= 0;
          IF (Request_Addr > 0) THEN
            Save_RAM_Addr <= Request_Addr-1;
          ELSE
            Save_RAM_Addr <= (640*480)/pixel_number-1;
          END IF;
        
        END IF;
        IF (TO_UNSIGNED(save_pixel, 10)(0) = '0') THEN
          save_buf_waddr  <= (save_pixel*3)/2;
          data_save_buf1  := Pixel_R & Pixel_G & Pixel_B;
        ELSE
          data_save_buf  := Pixel_R & Pixel_G & Pixel_B & data_save_buf1;

          write_count    := 0;
          write_save_buf := true;
        END IF;
      ELSE
        start_save    <= false;
      END IF;
      save_pixel_reg <= save_pixel;
      New_Pixel_Reg := New_Pixel;
      IF (write_save_buf) THEN
        save_buf_wr    <= true;
        save_buf_wdata <= data_save_buf(16*write_count+15 downto 16*write_count);
        IF (write_count > 0 AND save_buf_waddr < Burst_Length-1) THEN
          save_buf_waddr <= save_buf_waddr + 1;
        
        END IF;
        IF (write_count < 2) THEN
          write_count    := write_count + 1;
        ELSE
          write_save_buf := false;
        END IF;
      ELSE
        save_buf_wr    <= false;
      END IF;
      IF (copy_buffer) THEN
        save_ram_buf_wr <= true;
        save_ram_buf_waddr <= save_buf_raddr;
        save_ram_buf_wdata <= save_buf_rdata;
        IF (save_buf_raddr < Burst_Length-1) THEN
          save_buf_raddr <= save_buf_raddr + 1;
        ELSE
          copy_buffer := false;
        END IF;
      ELSE
        save_buf_raddr  <= 0;
        save_ram_buf_wr <= false;
      END IF;

      copy_buffer_reg <= copy_buffer;
    
    END IF;
  END PROCESS;
  PROCESS (CTL_CLK)
    
  BEGIN
    IF (rising_edge(CTL_CLK)) THEN
      IF (read_buf_wr) THEN
        read_buf(read_buf_waddr) <= read_buf_wdata;
      
      END IF;
    
    END IF;
  END PROCESS;
  PROCESS (CTL_CLK)
    
  BEGIN
    IF (rising_edge(CTL_CLK)) THEN
      IF (read_ram_buf_wr) THEN
        read_ram_buf(read_ram_buf_waddr) <= read_ram_buf_wdata;
      
      END IF;
    
    END IF;
  END PROCESS;
  Read_Process : PROCESS (CTL_CLK)
    VARIABLE Read_Ena_Reg : STD_LOGIC := '0';
    VARIABLE read_pixel : NATURAL range 0 to pixel_number-1;
    VARIABLE Request_Addr : NATURAL range 0 to (640*480)/pixel_number;
    VARIABLE read_read_buf : BOOLEAN := false;
    VARIABLE read_count : NATURAL range 0 to 2 := 0;
    VARIABLE copy_buffer : BOOLEAN := false;
    VARIABLE buf_reg : STD_LOGIC_VECTOR(15 downto 0);
    
  BEGIN
    IF (falling_edge(CTL_CLK)) THEN
      IF (Read_Ena = '1' AND Read_Ena_Reg = '0') THEN
        Request_Addr := (Read_Row*640+Read_Column)/pixel_number;
        IF (Request_Addr /= Read_Addr) THEN
          read_pixel := 0;
          Read_Addr    <= Request_Addr;
          IF (Request_Addr < (640*480)/pixel_number-1) THEN
            Read_RAM_Addr <= Request_Addr + 1;
          ELSE
            Read_RAM_Addr <= 0;
          END IF;

          read_ram_buf_raddr <= 0;
          copy_buffer        := true;
          start_read         <= true;
        ELSE
          read_pixel := Read_Row*640+Read_Column - Read_Addr*pixel_number;
        END IF;

        read_pixel_reg <= read_pixel;
        read_buf_raddr <= (read_pixel*3)/2;


        read_count    := 0;
        read_read_buf := true;
      ELSE
        start_read <= false;
      END IF;
      Read_Ena_Reg := Read_Ena;
      IF (read_read_buf) THEN
        buf_reg := read_buf_rdata;
        IF (read_count > 0) THEN
          IF (read_count = 1) THEN
            Read_Data(15 downto 0) <= buf_reg;
            read_buf_raddr  <= read_buf_raddr + 1;
          ELSE
            IF (TO_UNSIGNED(read_pixel, 10)(0) = '0') THEN
              Read_Data <= buf_reg(7 downto 0) & Read_Data(15 downto 0);
            ELSE
              Read_Data <= buf_reg & Read_Data(15 downto 8);
            END IF;
          END IF;
        
        END IF;
        IF (read_count < 2) THEN
          read_count      := read_count + 1;
        ELSE
          read_read_buf := false;
        END IF;
      ELSE
        Read_Data_R <= Read_Data(23 downto 16);
        Read_Data_G <= Read_Data(15 downto 8);
        Read_Data_B <= Read_Data(7 downto 0);
      END IF;
      IF (copy_buffer) THEN
        IF (read_ram_buf_raddr < Burst_Length-1) THEN
          read_buf_wr    <= true;
          read_buf_waddr <= read_ram_buf_raddr;
          read_buf_wdata <= read_ram_buf_rdata;
          read_ram_buf_raddr <= read_ram_buf_raddr + 1;
        ELSE
          read_buf_wr <= false;
          copy_buffer := false;
          read_ram_buf_raddr <= 0;
        END IF;
      
      END IF;
    
    END IF;
  END PROCESS;
  ISSP1 : ISSP  PORT MAP (
    source => ISSP_source,
    probe  => ISSP_probe

    
  );
  SDRAM_Controller_Interface : PROCESS (CTL_CLK)
    VARIABLE read_wait : BOOLEAN := false;
    VARIABLE start_read_reg : BOOLEAN := false;
    VARIABLE save_wait : BOOLEAN := false;
    VARIABLE start_save_reg : BOOLEAN := false;
    VARIABLE RAM_Busy : BOOLEAN := false;
    VARIABLE RAM_Wr   : BOOLEAN := false;
    VARIABLE ram_count : NATURAL := 0;
    VARIABLE data_reg : STD_LOGIC_VECTOR(15 downto 0);
    VARIABLE wait_delay : NATURAL range 0 to 3 := 0;
    VARIABLE Receive_Count : NATURAL range 0 to Burst_Length := 0;
  BEGIN
    IF (rising_edge(CTL_CLK)) THEN
      IF (SDRAM_Reset = '0') THEN
        SDRAM_Reset <= '1';
      
      END IF;
      IF (start_read AND NOT start_read_reg) THEN
        read_wait := true;
      
      END IF;
      start_read_reg := start_read;
      IF (start_save AND NOT start_save_reg) THEN
        save_wait := true;
      
      END IF;
      start_save_reg := start_save;
      IF (NOT RAM_Busy) THEN
        IF (save_wait AND ISSP_source(0) = '0') THEN
          save_wait      := false;
          RAM_Wr         := true;
          RAM_Busy       := true;
          save_ram_buf_raddr <= 0;
          RAM_Step       <= 0;
          ISSP_probe <= STD_LOGIC_VECTOR(TO_UNSIGNED(ram_count, 32));
          ram_count := 0;
        ELSIF (read_wait AND ISSP_source(1) = '0') THEN
          read_wait      := false;
          RAM_Wr         := false;
          RAM_Busy       := true;
          RAM_Step       <= 0;
          wait_delay := 2;
          ISSP_probe <= STD_LOGIC_VECTOR(TO_UNSIGNED(ram_count, 32));
          ram_count := 0;
        ELSE
          ram_count := ram_count + 1;
        END IF;
        read_ram_buf_wr <= false;
      ELSE
        IF (RAM_Wr) THEN
          IF (SDRAM_waitrequest /= '1' OR RAM_Step = 0) THEN
            IF (RAM_Step < Burst_Length) THEN
              SDRAM_write_n      <= '0';
              SDRAM_writedata    <= save_ram_buf_rdata;
              SDRAM_address      <= STD_LOGIC_VECTOR(TO_UNSIGNED(Save_RAM_Addr*Burst_Length+RAM_Step, SDRAM_address'LENGTH));
              IF (RAM_Step < Burst_Length-1) THEN
                save_ram_buf_raddr <= RAM_Step + 1;
              
              END IF;
              RAM_Step           <= RAM_Step + 1;
            ELSE
              SDRAM_write_n   <= '1';
              RAM_Busy        := false;
            END IF;
          
          END IF;
        ELSE
          IF (RAM_Step = 0) THEN
            SDRAM_read_n    <= '0';
            SDRAM_address   <= STD_LOGIC_VECTOR(TO_UNSIGNED(Read_RAM_Addr*Burst_Length+RAM_Step, SDRAM_address'LENGTH));
            RAM_Step        <= RAM_Step + 1;
            Receive_Count   := 0;
          ELSIF (SDRAM_waitrequest /= '1' OR wait_delay < 3 OR SDRAM_readdatavalid = '1') THEN
            IF (RAM_Step < Burst_Length AND SDRAM_waitrequest /= '1') THEN
              SDRAM_address   <= STD_LOGIC_VECTOR(TO_UNSIGNED(Read_RAM_Addr*Burst_Length+RAM_Step, SDRAM_address'LENGTH));
              RAM_Step        <= RAM_Step + 1;
            
            END IF;
            IF (SDRAM_readdatavalid = '1') THEN
              read_ram_buf_wr     <= true;
              read_ram_buf_waddr  <= Receive_Count;
              read_ram_buf_wdata  <= data_reg;
              Receive_Count       := Receive_Count + 1;
              IF (Receive_Count = Burst_Length) THEN
                SDRAM_read_n    <= '1';
                RAM_Busy        := false;
              END IF;
            
            END IF;
            IF (SDRAM_waitrequest = '1' AND wait_delay < 3) THEN
              wait_delay := wait_delay + 1;
            ELSE
              wait_delay := 0;
            END IF;
          END IF;

          data_reg := SDRAM_readdata;
        END IF;
      END IF;
    END IF;
  END PROCESS;
  SDRAM1 : SDRAM  PORT MAP (
    clk_in_clk       => CTL_CLK,
    reset_reset_n    => SDRAM_Reset,
    s1_address       => SDRAM_address,
    s1_byteenable_n  => "00",   
    s1_chipselect    => '1',    
    s1_writedata     => SDRAM_writedata,
    s1_read_n        => SDRAM_read_n,
    s1_write_n       => SDRAM_write_n,
    s1_readdata      => SDRAM_readdata,
    s1_readdatavalid => SDRAM_readdatavalid,
    s1_waitrequest   => SDRAM_waitrequest,
    sdram_addr       => SDRAM_ADDR,
    sdram_ba         => SDRAM_BA,
    sdram_cas_n      => SDRAM_CASn,
    sdram_cke        => SDRAM_CKE,
    sdram_cs_n       => SDRAM_CSn,
    sdram_dq         => SDRAM_DQ,
    sdram_dqm        => SDRAM_DQM,
    sdram_ras_n      => SDRAM_RASn,
    sdram_we_n       => SDRAM_WEn
  );
  
END BEHAVIORAL;
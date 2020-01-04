  
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all; 
use work.sdram_config.all;
use work.sdram_controller_interface.all;


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
  CONSTANT SDRAM_Config : sdram_config_type := GetSDRAMParameters(20 ns, 2);
  SIGNAL master_interface : SDRAM_controller_master_type;
  SIGNAL slave_interface : SDRAM_controller_slave_type;
  SIGNAL SDRAM_Reset          : STD_LOGIC := '1';
  SIGNAL copy_buffer_reg : BOOLEAN;
  SIGNAL read_pixel_reg : NATURAL;
  COMPONENT sdr_sdram IS
  GENERIC (
      SHORT_INITIALIZATION  : boolean := false;
            USE_AUTOMATIC_REFRESH : boolean;
            BURST_LENGTH          : natural; 
            SDRAM                 : sdram_config_type; 
        
            CS_WIDTH              : natural; 
            CS_LOW_BIT            : natural; 
            BA_LOW_BIT            : natural; 
            ROW_LOW_BIT           : natural; 
            COL_LOW_BIT           : natural 
    
  );
  PORT (
    rst         : in    std_logic;  
            clk         : in    std_logic;  
            pll_locked  : in    std_logic;  
        
            ocpSlave    : out   SDRAM_controller_slave_type;
            ocpMaster   : in    SDRAM_controller_master_type;
        
            sdram_CKE   : out   std_logic;  
            sdram_RAS_n : out   std_logic;  
            sdram_CAS_n : out   std_logic;  
            sdram_WE_n  : out   std_logic;  
            sdram_CS_n  : out   std_logic_vector(2 ** CS_WIDTH - 1 downto 0); 
            sdram_BA    : out   std_logic_vector(SDRAM.BA_WIDTH - 1 downto 0); 
            sdram_SA    : out   std_logic_vector(SDRAM.SA_WIDTH - 1 downto 0); 
            sdram_DQ    : inout std_logic_vector(SDRAM_DATA_WIDTH - 1 downto 0); 
            sdram_DQM   : out   std_logic_vector(SDRAM_DATA_WIDTH / 8 - 1 downto 0) 
    
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
          IF (save_pixel = pixel_number-1) THEN
            data_save_buf  := x"000000" & data_save_buf1;

            write_count    := 0;
            write_save_buf := true;
          
          END IF;
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
        IF (save_buf_waddr < Burst_Length-1) THEN
          IF (write_count > 0) THEN
            save_buf_waddr <= save_buf_waddr + 1;
          
          END IF;
          IF (write_count < 2) THEN
            write_count    := write_count + 1;
          ELSE
            write_save_buf := false;
          END IF;
        ELSE
          write_save_buf := false;
          save_buf_wr    <= false;
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
  SDRAM_Controller_Interface : PROCESS (CTL_CLK)
    VARIABLE start_up_cnt : NATURAL range 0 to 10000 := 0;
    VARIABLE read_wait : BOOLEAN := false;
    VARIABLE start_read_reg : BOOLEAN := false;
    VARIABLE save_wait : BOOLEAN := false;
    VARIABLE start_save_reg : BOOLEAN := false;
    VARIABLE RAM_Busy : BOOLEAN := false;
    VARIABLE RAM_Wr   : BOOLEAN := false;
    VARIABLE i : INTEGER range 0 to Burst_Length := 0;
    VARIABLE Thread69 : NATURAL range 0 to 3 := 0;
    VARIABLE Thread76 : NATURAL range 0 to 5 := 0;
  BEGIN
    IF (rising_edge(CTL_CLK)) THEN
      IF (start_up_cnt < 10000) THEN
        start_up_cnt := start_up_cnt + 1;
        master_interface.MCmd <= "000";
        master_interface.MDataByteEn <= "11";
        master_interface.MFlag_CmdRefresh <= '0';
        IF (start_up_cnt < 10) THEN
          SDRAM_Reset <= '1';
        ELSE
          SDRAM_Reset <= '0';
        END IF;
      ELSE
        IF (start_read AND NOT start_read_reg) THEN
          read_wait := true;
        
        END IF;
        start_read_reg := start_read;
        IF (start_save AND NOT start_save_reg) THEN
          save_wait := true;
        
        END IF;
        start_save_reg := start_save;
        IF (NOT RAM_Busy) THEN
          IF (save_wait) THEN
            save_wait      := false;
            RAM_Wr         := true;
            RAM_Busy       := true;
            save_ram_buf_raddr <= 0;
          ELSIF (read_wait) THEN
            read_wait      := false;
            RAM_Wr         := false;
            RAM_Busy       := true;
          
          END IF;
          read_ram_buf_wr <= false;
        ELSE
          IF (RAM_Wr) THEN
            CASE (Thread69) IS
              WHEN 0 =>
                master_interface.MAddr <= STD_LOGIC_VECTOR(TO_UNSIGNED(Save_RAM_Addr*Burst_Length, SDRAM_ADDR_WIDTH));
                master_interface.MData <= save_ram_buf_rdata;
                save_ram_buf_raddr <= 1;
                i := 1;
                master_interface.MDataValid <= '1';
                master_interface.MCmd  <= "001";
                Thread69 := 1;
              WHEN 1 =>
                IF (i < Burst_Length) THEN
                  IF (slave_interface.SDataAccept = '1') THEN
                    master_interface.MCmd <= "000";
                    master_interface.MData <= save_ram_buf_rdata;
                    i := i + 1;
                      IF (i < Burst_Length) THEN
                        save_ram_buf_raddr <= i;
                      END IF;
                  
                  END IF;
                ELSE
                  Thread69 := Thread69 + 1;
                END IF;
              WHEN 2 =>
                RAM_Busy        := false;
                Thread69 := 0;
              WHEN others => Thread69 := 0;
            END CASE;
          ELSE
            CASE (Thread76) IS
              WHEN 0 =>
                master_interface.MAddr <= STD_LOGIC_VECTOR(TO_UNSIGNED(Read_RAM_Addr*Burst_Length, SDRAM_ADDR_WIDTH));
                master_interface.MCmd  <= "010";
                Thread76 := 1;
              WHEN 1 =>
                IF (slave_interface.SCmdAccept = '0') THEN
                ELSE
                  Thread76 := Thread76 + 1;
                END IF;
              WHEN 2 =>
                master_interface.MCmd <= "000";
                i := 0;
                Thread76 := 3;
              WHEN 3 =>
                IF (i < Burst_Length) THEN
                  IF (slave_interface.SResp = '1') THEN
                    read_ram_buf_wr    <= true;
                    read_ram_buf_wdata <= slave_interface.SData;
                    read_ram_buf_waddr <= i;
                    i := i + 1;
                  END IF;
                ELSE
                  Thread76 := Thread76 + 1;
                END IF;
              WHEN 4 =>
                read_ram_buf_wr    <= false;
                RAM_Busy        := false;
                Thread76 := 0;
              WHEN others => Thread76 := 0;
            END CASE;
          END IF;
        END IF;
      END IF;
    END IF;
  END PROCESS;
  sdr_sdram1 : sdr_sdram
  GENERIC MAP (
      SHORT_INITIALIZATION  => false,
    USE_AUTOMATIC_REFRESH => true,
    BURST_LENGTH          => Burst_Length,
    SDRAM                 => SDRAM_Config,
    CS_WIDTH              => 0,
    CS_LOW_BIT            => SDRAM_Config.COL_WIDTH + SDRAM_Config.ROW_WIDTH + SDRAM_Config.BA_WIDTH,
    BA_LOW_BIT            => SDRAM_Config.COL_WIDTH + SDRAM_Config.ROW_WIDTH,
    ROW_LOW_BIT           => SDRAM_Config.COL_WIDTH,
    COL_LOW_BIT           => 0

  ) PORT MAP (
    rst                   => SDRAM_Reset,
    clk                   => CTL_CLK,
    pll_locked            => '1',
    ocpSlave              => slave_interface,
    ocpMaster             => master_interface,
    sdram_CKE             => SDRAM_CKE,
    sdram_RAS_n           => SDRAM_RASn,
    sdram_CAS_n           => SDRAM_CASn,
    sdram_WE_n            => SDRAM_WEn,
    sdram_CS_n(0)         => SDRAM_CSn,
    sdram_BA              => SDRAM_BA,
    sdram_SA              => SDRAM_ADDR,
    sdram_DQ              => SDRAM_DQ,
    sdram_DQM             => SDRAM_DQM
  );
  
END BEHAVIORAL;
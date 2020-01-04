  
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all; 
use work.sdram_config.all;
use work.sdram_controller_interface.all;


ENTITY CRT_Controller_RAM IS

PORT (
  CLK : IN STD_LOGIC;
  New_Pixel   : IN    STD_LOGIC := '0'; 
  Column      : IN    NATURAL range 0 to 639 := 0;
  Row         : IN    NATURAL range 0 to 479 := 0;
  Pixel_R     : IN    STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
  Pixel_G     : IN    STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
  Pixel_B     : IN    STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
  VS_PCLK    : OUT    STD_LOGIC;
  VS_SCLK    : OUT    STD_LOGIC;
  VS_R       : OUT    STD_LOGIC_VECTOR (7 downto 0);
  VS_G       : OUT    STD_LOGIC_VECTOR (7 downto 0);
  VS_B       : OUT    STD_LOGIC_VECTOR (7 downto 0);
  VS_HS      : OUT    STD_LOGIC;
  VS_VS      : OUT    STD_LOGIC;
  VS_DE      : OUT    STD_LOGIC

);
END CRT_Controller_RAM;

ARCHITECTURE BEHAVIORAL OF CRT_Controller_RAM IS

  SIGNAL ISSP_source : std_logic_vector (7 downto 0);
  SIGNAL ISSP_probe  : std_logic_vector (31 downto 0);
  SIGNAL PLL_c0     : STD_LOGIC;
  SIGNAL PLL_c1     : STD_LOGIC;
  CONSTANT porchHF : NATURAL := 640;
  CONSTANT syncH   : NATURAL := 656;
  CONSTANT porchHB : NATURAL := 752;
  CONSTANT maxH    : NATURAL := 799;
  CONSTANT porchVF : NATURAL := 480;
  CONSTANT syncV   : NATURAL := 490;
  CONSTANT porchVB : NATURAL := 492;
  CONSTANT maxV    : NATURAL := 525;
  SIGNAL xCountReg : INTEGER range 0 to maxH := 0;
  SIGNAL yCountReg : INTEGER range 0 to maxV := 0;
  TYPE Row_buf_type IS ARRAY (0 to 639) OF STD_LOGIC_VECTOR (23 downto 0);
  SIGNAL Row_buf : Row_buf_type;
  SIGNAL Save_Column : NATURAL range 0 to 639 := 0;
  SIGNAL Save_Data   : STD_LOGIC_VECTOR(23 downto 0) := (others => '0');
  SIGNAL Read_Column : NATURAL range 0 to 639 := 0;
  SIGNAL Read_Data   : STD_LOGIC_VECTOR(23 downto 0) := (others => '0');
  COMPONENT ISSP IS
  
  PORT (
    source : out std_logic_vector(7 downto 0);                      
    probe  : in  std_logic_vector(31 downto 0)  := (others => 'X') 

  );
  END COMPONENT;
  COMPONENT VS_PLL IS
  
  PORT (
    inclk0		: IN STD_LOGIC  := '0';
		    c0		: OUT STD_LOGIC ;
		    c1		: OUT STD_LOGIC 
	
  );
  END COMPONENT;
  
BEGIN
  VS_PCLK <= PLL_c0;
  VS_SCLK <= PLL_c1;
  ISSP1 : ISSP  PORT MAP (
    source => ISSP_source,
    probe  => ISSP_probe

    
  );
  VS_PLL1 : VS_PLL  PORT MAP (
    inclk0 => CLK,
    c0     => PLL_c0, 
    c1     => PLL_c1
  );
  ROW_Buf_Controller : PROCESS (CLK)  
    
  BEGIN
  IF RISING_EDGE(CLK) THEN
    Read_Data <= Row_buf(Read_Column);
    Row_buf(Save_Column) <= Save_Data;
  END IF;
  END PROCESS;
  PROCESS (New_Pixel)
    
  BEGIN
    IF (rising_edge(New_Pixel)) THEN
      Save_Column <= Column;
      Save_Data   <= Pixel_R & Pixel_G & Pixel_B;
    
    END IF;
  END PROCESS;
  PROCESS (PLL_c0)
    VARIABLE xCount : INTEGER range 0 to maxH := 0;
    VARIABLE yCount : INTEGER range 0 to maxV := 0;
    VARIABLE col_reg : INTEGER range 0 to 639 := 0;
    VARIABLE row_reg : INTEGER range 0 to 479 := 0;
  BEGIN
    IF (rising_edge(PLL_c0)) THEN
      IF (xCount < maxH AND (Column /= 0 OR Column = col_reg)) THEN
        xCount := xCount + 1;
      ELSIF (xCount > Column) THEN
        IF (ISSP_source(1 downto 0) = "00") THEN
          ISSP_probe <= STD_LOGIC_VECTOR(TO_UNSIGNED(xCount, 32));
        
        END IF;
        xCount := 0;
        IF (yCount < maxV AND (Row /= 0 OR Row = row_reg)) THEN
          yCount := yCount + 1;
        ELSIF (yCount > Row) THEN
          IF (ISSP_source(1 downto 0) = "01") THEN
            ISSP_probe <= STD_LOGIC_VECTOR(TO_UNSIGNED(yCount, 32));
          
          END IF;
          yCount := 0;
        ELSE
          IF (ISSP_source(1 downto 0) = "11") THEN
            ISSP_probe <= STD_LOGIC_VECTOR(TO_UNSIGNED(yCount, 32));
          END IF;
        END IF;
      ELSE
        IF (ISSP_source(1 downto 0) = "10") THEN
          ISSP_probe <= STD_LOGIC_VECTOR(TO_UNSIGNED(xCount, 32));
        
        END IF;
      END IF;
      col_reg := Column;
      row_reg := Row;
      IF (xCount < porchHF AND yCount < porchVF) THEN
        VS_DE <= '1';
        IF (xCount < 639) THEN
          Read_Column <= (xCount+1);
        ELSE
          Read_Column <= 0;
        END IF;
        VS_R <= Read_Data(23 downto 16);
        VS_G <= Read_Data(15 downto 8);
        VS_B <= Read_Data(7 downto 0);
      ELSE
        VS_DE <= '0';
        IF (xCount >= syncH AND xCount < porchHB) THEN
          VS_HS <= '0';
        ELSE
          VS_HS <= '1';
        END IF;
        IF (yCount >= syncV AND yCount < porchVB) THEN
          VS_VS <= '0';
        ELSE
          VS_VS <= '1';
        END IF;
      END IF;
      xCountReg <= xCount;
      yCountReg <= yCount;
    END IF;
  END PROCESS;
  
END BEHAVIORAL;
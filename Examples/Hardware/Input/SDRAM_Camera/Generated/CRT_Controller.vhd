  
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all; 
use work.sdram_config.all;
use work.sdram_controller_interface.all;


ENTITY CRT_Controller IS
  GENERIC (
      image_size_div : NATURAL := 1

  );
PORT (
  CLK : IN STD_LOGIC;
  Read_Column : OUT    NATURAL range 0 to 639 := 0;
  Read_Row    : OUT    NATURAL range 0 to 479 := 0;
  Read_Data   : IN     STD_LOGIC_VECTOR(23 downto 0) := (others => '0');
  Read_Ena    : OUT    STD_LOGIC := '0';
  VS_PCLK    : OUT    STD_LOGIC;
  VS_SCLK    : OUT    STD_LOGIC;
  VS_R       : OUT    STD_LOGIC_VECTOR (7 downto 0);
  VS_G       : OUT    STD_LOGIC_VECTOR (7 downto 0);
  VS_B       : OUT    STD_LOGIC_VECTOR (7 downto 0);
  VS_HS      : OUT    STD_LOGIC;
  VS_VS      : OUT    STD_LOGIC;
  VS_DE      : OUT    STD_LOGIC

);
END CRT_Controller;

ARCHITECTURE BEHAVIORAL OF CRT_Controller IS

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
 
 
 
 
 
 
 
 


  Read_Ena <= PLL_c0 when xCountReg < porchHF/image_size_div AND yCountReg < porchVF/image_size_div else '0';
  VS_PLL1 : VS_PLL  PORT MAP (
    inclk0 => CLK,
    c0     => PLL_c0, 
    c1     => PLL_c1
  );
  PROCESS (PLL_c0)
    VARIABLE xCount : INTEGER range 0 to maxH := 0;
    VARIABLE yCount : INTEGER range 0 to maxV := 0;
  BEGIN
    IF (rising_edge(PLL_c0)) THEN
      IF (xCount < maxH) THEN
        xCount := xCount + 1;
      ELSE
        xCount := 0;
        IF (yCount < maxV) THEN
          yCount := yCount + 1;
        ELSE
          yCount := 0;
        END IF;
      END IF;
      IF (xCount < porchHF AND yCount < porchVF) THEN
        VS_DE <= '1';
        IF (yCount < 479) THEN
          Read_Row <= (yCount+1);
        ELSE
          Read_Row <= 0;
        END IF;
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
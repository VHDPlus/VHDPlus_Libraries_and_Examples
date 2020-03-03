  
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all; 
use work.Image_Data_Package.all;


ENTITY Stream2VS IS

PORT (
  CLK : IN STD_LOGIC;
  iStream    : IN     rgb_stream; 
  VS_PCLK    : OUT    STD_LOGIC;
  VS_SCLK    : OUT    STD_LOGIC;
  VS_R       : OUT    STD_LOGIC_VECTOR (7 downto 0);
  VS_G       : OUT    STD_LOGIC_VECTOR (7 downto 0);
  VS_B       : OUT    STD_LOGIC_VECTOR (7 downto 0);
  VS_HS      : OUT    STD_LOGIC;
  VS_VS      : OUT    STD_LOGIC;
  VS_DE      : OUT    STD_LOGIC

);
END Stream2VS;

ARCHITECTURE BEHAVIORAL OF Stream2VS IS

  SIGNAL PLL_c0     : STD_LOGIC;
  COMPONENT Stream_PLL IS
  
  PORT (
    inclk0		: IN STD_LOGIC  := '0';
		    c0		: OUT STD_LOGIC 
	
  );
  END COMPONENT;
  
BEGIN

  VS_PCLK <= CLK;
  VS_SCLK <= PLL_c0;
  VS_R <= iStream.R;
  VS_G <= iStream.G;
  VS_B <= iStream.B;
  VS_HS <= '1' when iStream.Column = 639 else '0';
  VS_VS <= '1' when iStream.Row = 479 else '0';
  VS_DE <= '1' when iStream.Column < 639 AND iStream.Row < 479 else '0';
  Stream_PLL1 : Stream_PLL  PORT MAP (
    inclk0 => CLK,
    c0     => PLL_c0
  );
  
END BEHAVIORAL;
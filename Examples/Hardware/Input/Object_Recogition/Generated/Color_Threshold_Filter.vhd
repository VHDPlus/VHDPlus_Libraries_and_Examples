  
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all; 


ENTITY Color_Threshold_Filter IS
  GENERIC (
      R_Min : NATURAL := 0;
    R_Max : NATURAL := 255;
    G_Min : NATURAL := 0;
    G_Max : NATURAL := 255;
    B_Min : NATURAL := 0;
    B_Max : NATURAL := 255

  );
PORT (
  CLK : IN STD_LOGIC;
  iPixel_R   : IN STD_LOGIC_VECTOR (7 downto 0);
  iPixel_G   : IN STD_LOGIC_VECTOR (7 downto 0);
  iPixel_B   : IN STD_LOGIC_VECTOR (7 downto 0);
  oPixel_R   : OUT STD_LOGIC_VECTOR (7 downto 0);
  oPixel_G   : OUT STD_LOGIC_VECTOR (7 downto 0);
  oPixel_B   : OUT STD_LOGIC_VECTOR (7 downto 0)

);
END Color_Threshold_Filter;

ARCHITECTURE BEHAVIORAL OF Color_Threshold_Filter IS

  SIGNAL Pixel_Data : STD_LOGIC_VECTOR(23 downto 0);
  
BEGIN

  Pixel_Data <= iPixel_R & iPixel_G & iPixel_B when
  UNSIGNED(iPixel_R) >= R_Min AND UNSIGNED(iPixel_R) <= R_Max AND 
  UNSIGNED(iPixel_G) >= G_Min AND UNSIGNED(iPixel_G) <= G_Max AND 
  UNSIGNED(iPixel_B) >= B_Min AND UNSIGNED(iPixel_B) <= B_Max else (others => '0');
  oPixel_R <= Pixel_Data(23 downto 16);
  oPixel_G <= Pixel_Data(15 downto 8);
  oPixel_B <= Pixel_Data(7 downto 0);
  
END BEHAVIORAL;
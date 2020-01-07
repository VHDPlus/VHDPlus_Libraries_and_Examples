  
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all; 


ENTITY Color_Threshold_HSV_Filter IS
PORT (
  CLK : IN STD_LOGIC;
  H_Min : IN NATURAL := 0;   
  H_Max : IN NATURAL := 180; 
  S_Min : IN NATURAL := 0;   
  S_Max : IN NATURAL := 255; 
  V_Min : IN NATURAL := 0;   
  V_Max : IN NATURAL := 255; 
  Relace : IN STD_LOGIC_VECTOR(23 downto 0) := (others => '0');
  iPixel_R   : IN STD_LOGIC_VECTOR (7 downto 0);
  iPixel_G   : IN STD_LOGIC_VECTOR (7 downto 0);
  iPixel_B   : IN STD_LOGIC_VECTOR (7 downto 0);
  iHSV_H     : IN STD_LOGIC_VECTOR (7 downto 0);
  iHSV_S     : IN STD_LOGIC_VECTOR (7 downto 0);
  iHSV_V     : IN STD_LOGIC_VECTOR (7 downto 0);
  oPixel_R   : OUT STD_LOGIC_VECTOR (7 downto 0);
  oPixel_G   : OUT STD_LOGIC_VECTOR (7 downto 0);
  oPixel_B   : OUT STD_LOGIC_VECTOR (7 downto 0)

);
END Color_Threshold_HSV_Filter;

ARCHITECTURE BEHAVIORAL OF Color_Threshold_HSV_Filter IS

  SIGNAL Pixel_Data : STD_LOGIC_VECTOR(23 downto 0);
  
BEGIN

  Pixel_Data <= iPixel_R & iPixel_G & iPixel_B when
  UNSIGNED(iHSV_H) >= H_Min AND UNSIGNED(iHSV_H) <= H_Max AND
  UNSIGNED(iHSV_S) >= S_Min AND UNSIGNED(iHSV_S) <= S_Max AND
  UNSIGNED(iHSV_V) >= V_Min AND UNSIGNED(iHSV_V) <= V_Max else Relace;
  oPixel_R <= Pixel_Data(23 downto 16);
  oPixel_G <= Pixel_Data(15 downto 8);
  oPixel_B <= Pixel_Data(7 downto 0);
  
END BEHAVIORAL;
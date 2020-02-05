  
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all; 
use work.Image_Data_Package.all;


ENTITY Color_Threshold_2_Filter IS
  GENERIC (
      L_Min : NATURAL := 0;   
    L_Max : NATURAL := 255; 
    A_Min : NATURAL := 0;   
    A_Max : NATURAL := 255; 
    B_Min : NATURAL := 0;   
    B_Max : NATURAL := 255; 
    Relace : STD_LOGIC_VECTOR(23 downto 0) := (others => '0')

  );
PORT (
  CLK : IN STD_LOGIC;
  iPixel_R   : IN STD_LOGIC_VECTOR (7 downto 0);
  iPixel_G   : IN STD_LOGIC_VECTOR (7 downto 0);
  iPixel_B   : IN STD_LOGIC_VECTOR (7 downto 0);
  iLAB_L     : IN STD_LOGIC_VECTOR (7 downto 0);
  iLAB_A     : IN STD_LOGIC_VECTOR (7 downto 0);
  iLAB_B     : IN STD_LOGIC_VECTOR (7 downto 0);
  oPixel_R   : OUT STD_LOGIC_VECTOR (7 downto 0);
  oPixel_G   : OUT STD_LOGIC_VECTOR (7 downto 0);
  oPixel_B   : OUT STD_LOGIC_VECTOR (7 downto 0)

);
END Color_Threshold_2_Filter;

ARCHITECTURE BEHAVIORAL OF Color_Threshold_2_Filter IS

  SIGNAL Pixel_Data : STD_LOGIC_VECTOR(23 downto 0);
  
BEGIN

  Pixel_Data <= iPixel_R & iPixel_G & iPixel_B when
  UNSIGNED(iLAB_L) >= L_Min AND UNSIGNED(iLAB_L) <= L_Max AND
  UNSIGNED(iLAB_A) >= A_Min AND UNSIGNED(iLAB_A) <= A_Max AND
  UNSIGNED(iLAB_B) >= B_Min AND UNSIGNED(iLAB_B) <= B_Max else Relace;
  oPixel_R <= Pixel_Data(23 downto 16);
  oPixel_G <= Pixel_Data(15 downto 8);
  oPixel_B <= Pixel_Data(7 downto 0);
  
END BEHAVIORAL;
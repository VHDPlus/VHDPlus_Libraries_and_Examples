  
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all; 
use work.Image_Data_Package.all;


ENTITY Contrast_Filter IS
PORT (
  CLK : IN STD_LOGIC;
  Factor_Multiplier : IN NATURAL range 0 to 15 := 1;
  Factor_Divider    : IN NATURAL range 0 to 15 := 1;
  Average           : IN NATURAL range 0 to 255 := 1;
  iPixel_R   : IN STD_LOGIC_VECTOR (7 downto 0);
  iPixel_G   : IN STD_LOGIC_VECTOR (7 downto 0);
  iPixel_B   : IN STD_LOGIC_VECTOR (7 downto 0);
  oPixel_R   : OUT STD_LOGIC_VECTOR (7 downto 0);
  oPixel_G   : OUT STD_LOGIC_VECTOR (7 downto 0);
  oPixel_B   : OUT STD_LOGIC_VECTOR (7 downto 0)

);
END Contrast_Filter;

ARCHITECTURE BEHAVIORAL OF Contrast_Filter IS

  SIGNAL pixel_buf_r : INTEGER range -355 to 355;
  SIGNAL pixel_buf_g : INTEGER range -355 to 355;
  SIGNAL pixel_buf_b : INTEGER range -355 to 355;
  SIGNAL pixel_buf_r1 : INTEGER range -255 to 255;
  SIGNAL pixel_buf_g1 : INTEGER range -255 to 255;
  SIGNAL pixel_buf_b1 : INTEGER range -255 to 255;
  
BEGIN

  pixel_buf_r1 <= TO_INTEGER(UNSIGNED(iPixel_R))-Average;
  pixel_buf_g1 <= TO_INTEGER(UNSIGNED(iPixel_G))-Average;
  pixel_buf_b1 <= TO_INTEGER(UNSIGNED(iPixel_B))-Average;
  pixel_buf_r <= ((pixel_buf_r1*Factor_Multiplier)/Factor_Divider) + Average;
  pixel_buf_g <= ((pixel_buf_g1*Factor_Multiplier)/Factor_Divider) + Average;
  pixel_buf_b <= ((pixel_buf_b1*Factor_Multiplier)/Factor_Divider) + Average;
  oPixel_R <= STD_LOGIC_VECTOR(TO_UNSIGNED(pixel_buf_r,8)) when pixel_buf_r <= 255 AND pixel_buf_r >= 0 else
  (others => '1') when pixel_buf_r > 255 else (others => '0');
  oPixel_G <= STD_LOGIC_VECTOR(TO_UNSIGNED(pixel_buf_g,8)) when pixel_buf_g <= 255 AND pixel_buf_g >= 0 else
  (others => '1') when pixel_buf_g > 255 else (others => '0');
  oPixel_B <= STD_LOGIC_VECTOR(TO_UNSIGNED(pixel_buf_b,8)) when pixel_buf_b <= 255 AND pixel_buf_b >= 0 else
  (others => '1') when pixel_buf_b > 255 else (others => '0');
  
END BEHAVIORAL;
  
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all; 


ENTITY Color_Correction_Filter IS
PORT (
  CLK : IN STD_LOGIC;
  R_Multiplier : IN NATURAL range 0 to 15 := 1;
  R_Divider    : IN NATURAL range 0 to 15 := 1;
  R_Add        : IN INTEGER range -64 to 63 := 0;
  G_Multiplier : IN NATURAL range 0 to 15 := 1;
  G_Divider    : IN NATURAL range 0 to 15 := 1;
  G_Add        : IN INTEGER range -64 to 63 := 0;
  B_Multiplier : IN NATURAL range 0 to 15 := 1;
  B_Divider    : IN NATURAL range 0 to 15 := 1;
  B_Add        : IN INTEGER range -64 to 63 := 0;
  iPixel_R   : IN STD_LOGIC_VECTOR (7 downto 0);
  iPixel_G   : IN STD_LOGIC_VECTOR (7 downto 0);
  iPixel_B   : IN STD_LOGIC_VECTOR (7 downto 0);
  oPixel_R   : OUT STD_LOGIC_VECTOR (7 downto 0);
  oPixel_G   : OUT STD_LOGIC_VECTOR (7 downto 0);
  oPixel_B   : OUT STD_LOGIC_VECTOR (7 downto 0)

);
END Color_Correction_Filter;

ARCHITECTURE BEHAVIORAL OF Color_Correction_Filter IS

  SIGNAL pixel_buf_r : INTEGER range -100 to 355;
  SIGNAL pixel_buf_g : INTEGER range -100 to 355;
  SIGNAL pixel_buf_b : INTEGER range -100 to 355;
  
BEGIN

  pixel_buf_r <= (TO_INTEGER(UNSIGNED(iPixel_R))*R_Multiplier)/R_Divider + R_Add;
  pixel_buf_g <= (TO_INTEGER(UNSIGNED(iPixel_G))*G_Multiplier)/G_Divider + G_Add;
  pixel_buf_b <= (TO_INTEGER(UNSIGNED(iPixel_B))*B_Multiplier)/B_Divider + B_Add;
  oPixel_R <= STD_LOGIC_VECTOR(TO_UNSIGNED(pixel_buf_r,8)) when pixel_buf_r <= 255 AND pixel_buf_r >= 0 else
  (others => '1') when pixel_buf_r > 255 else (others => '0');
  oPixel_G <= STD_LOGIC_VECTOR(TO_UNSIGNED(pixel_buf_g,8)) when pixel_buf_g <= 255 AND pixel_buf_g >= 0 else
  (others => '1') when pixel_buf_g > 255 else (others => '0');
  oPixel_B <= STD_LOGIC_VECTOR(TO_UNSIGNED(pixel_buf_b,8)) when pixel_buf_b <= 255 AND pixel_buf_b >= 0 else
  (others => '1') when pixel_buf_b > 255 else (others => '0');
  
END BEHAVIORAL;
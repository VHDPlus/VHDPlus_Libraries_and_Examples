  
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all; 
use work.sdram_config.all;
use work.sdram_controller_interface.all;


ENTITY Test_Image_Generator2 IS
  GENERIC (
      image_size_div : NATURAL := 1

  );
PORT (
  CLK : IN STD_LOGIC;
  oPixel_R   : OUT STD_LOGIC_VECTOR (7 downto 0);
  oPixel_G   : OUT STD_LOGIC_VECTOR (7 downto 0);
  oPixel_B   : OUT STD_LOGIC_VECTOR (7 downto 0);
  iColumn    : IN  NATURAL range 0 to 639 := 0;
  iRow       : IN  NATURAL range 0 to 479 := 0;
  iNewPixel  : IN  STD_LOGIC

);
END Test_Image_Generator2;

ARCHITECTURE BEHAVIORAL OF Test_Image_Generator2 IS
  
BEGIN
  PROCESS (iNewPixel)
    VARIABLE grey_step : NATURAL range 0 to 255 := 0;
  BEGIN
    IF (rising_edge(iNewPixel)) THEN
      IF (iColumn < (639/image_size_div) AND iRow < (479/image_size_div)) THEN
        grey_step := (iColumn*255)/640;
        oPixel_R <= STD_LOGIC_VECTOR(TO_UNSIGNED(grey_step, 8));
        oPixel_G <= STD_LOGIC_VECTOR(TO_UNSIGNED(grey_step, 8));
        oPixel_B <= STD_LOGIC_VECTOR(TO_UNSIGNED(grey_step, 8));
      END IF;
    END IF;
  END PROCESS;
  
END BEHAVIORAL;
  
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all; 


ENTITY Draw_Square IS
  GENERIC (
      Width : NATURAL := 4;
    Color : STD_LOGIC_VECTOR(23 downto 0) := x"FF0000" 

  );
PORT (
  CLK : IN STD_LOGIC;
  Square_X0  : IN NATURAL range 0 to 639;
  Square_X1  : IN NATURAL range 0 to 639;
  Square_Y0  : IN NATURAL range 0 to 479;
  Square_Y1  : IN NATURAL range 0 to 479;
  iColumn    : IN NATURAL range 0 to 639;
  iRow       : IN NATURAL range 0 to 479;
  iPixel_R   : IN STD_LOGIC_VECTOR (7 downto 0);
  iPixel_G   : IN STD_LOGIC_VECTOR (7 downto 0);
  iPixel_B   : IN STD_LOGIC_VECTOR (7 downto 0);
  oPixel_R   : OUT STD_LOGIC_VECTOR (7 downto 0);
  oPixel_G   : OUT STD_LOGIC_VECTOR (7 downto 0);
  oPixel_B   : OUT STD_LOGIC_VECTOR (7 downto 0)

);
END Draw_Square;

ARCHITECTURE BEHAVIORAL OF Draw_Square IS
  
BEGIN

  oPixel_R <= Color(23 downto 16) when (((iColumn >= Square_X0 - Width/2 AND iColumn <= Square_X0 + Width/2) OR (iColumn >= Square_X1 - Width/2 AND iColumn <= Square_X1 + Width/2)) AND (iRow >= Square_Y0 AND iRow <= Square_Y1)) OR
  (((iRow >= Square_Y0 - Width/2 AND iRow <= Square_Y0 + Width/2) OR (iRow >= Square_Y1 - Width/2 AND iRow <= Square_Y1 + Width/2)) AND (iColumn >= Square_X0 AND iColumn <= Square_X1)) else iPixel_R;
  oPixel_G <= Color(15 downto 8) when (((iColumn >= Square_X0 - Width/2 AND iColumn <= Square_X0 + Width/2) OR (iColumn >= Square_X1 - Width/2 AND iColumn <= Square_X1 + Width/2)) AND (iRow >= Square_Y0 AND iRow <= Square_Y1)) OR
  (((iRow >= Square_Y0 - Width/2 AND iRow <= Square_Y0 + Width/2) OR (iRow >= Square_Y1 - Width/2 AND iRow <= Square_Y1 + Width/2)) AND (iColumn >= Square_X0 AND iColumn <= Square_X1)) else iPixel_G;
  oPixel_B <= Color(7 downto 0) when (((iColumn >= Square_X0 - Width/2 AND iColumn <= Square_X0 + Width/2) OR (iColumn >= Square_X1 - Width/2 AND iColumn <= Square_X1 + Width/2)) AND (iRow >= Square_Y0 AND iRow <= Square_Y1)) OR
  (((iRow >= Square_Y0 - Width/2 AND iRow <= Square_Y0 + Width/2) OR (iRow >= Square_Y1 - Width/2 AND iRow <= Square_Y1 + Width/2)) AND (iColumn >= Square_X0 AND iColumn <= Square_X1)) else iPixel_B;
  
END BEHAVIORAL;
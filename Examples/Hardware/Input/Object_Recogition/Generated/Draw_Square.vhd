  
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all; 
use work.Image_Data_Package.all;


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
  iStream    : in   rgb_stream;
  oStream    : out  rgb_stream

);
END Draw_Square;

ARCHITECTURE BEHAVIORAL OF Draw_Square IS
  
BEGIN

  oStream.New_Pixel <= iStream.New_Pixel;
  oStream.Row       <= iStream.Row;
  oStream.Column    <= iStream.Column;
  oStream.R <= Color(23 downto 16) when (((iStream.Column >= Square_X0 - Width/2 AND iStream.Column <= Square_X0 + Width/2) OR (iStream.Column >= Square_X1 - Width/2 AND iStream.Column <= Square_X1 + Width/2)) AND (iStream.Row >= Square_Y0 AND iStream.Row <= Square_Y1)) OR
  (((iStream.Row >= Square_Y0 - Width/2 AND iStream.Row <= Square_Y0 + Width/2) OR (iStream.Row >= Square_Y1 - Width/2 AND iStream.Row <= Square_Y1 + Width/2)) AND (iStream.Column >= Square_X0 AND iStream.Column <= Square_X1)) else iStream.R;
  oStream.G <= Color(15 downto 8) when (((iStream.Column >= Square_X0 - Width/2 AND iStream.Column <= Square_X0 + Width/2) OR (iStream.Column >= Square_X1 - Width/2 AND iStream.Column <= Square_X1 + Width/2)) AND (iStream.Row >= Square_Y0 AND iStream.Row <= Square_Y1)) OR
  (((iStream.Row >= Square_Y0 - Width/2 AND iStream.Row <= Square_Y0 + Width/2) OR (iStream.Row >= Square_Y1 - Width/2 AND iStream.Row <= Square_Y1 + Width/2)) AND (iStream.Column >= Square_X0 AND iStream.Column <= Square_X1)) else iStream.G;
  oStream.B <= Color(7 downto 0) when (((iStream.Column >= Square_X0 - Width/2 AND iStream.Column <= Square_X0 + Width/2) OR (iStream.Column >= Square_X1 - Width/2 AND iStream.Column <= Square_X1 + Width/2)) AND (iStream.Row >= Square_Y0 AND iStream.Row <= Square_Y1)) OR
  (((iStream.Row >= Square_Y0 - Width/2 AND iStream.Row <= Square_Y0 + Width/2) OR (iStream.Row >= Square_Y1 - Width/2 AND iStream.Row <= Square_Y1 + Width/2)) AND (iStream.Column >= Square_X0 AND iStream.Column <= Square_X1)) else iStream.B;
  
END BEHAVIORAL;
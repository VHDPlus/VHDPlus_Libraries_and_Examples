  
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all; 
use work.Image_Data_Package.all;


ENTITY Draw_Cross IS
  GENERIC (
      Width  : NATURAL := 4;
    Length : NATURAL := 8;
    Color  : STD_LOGIC_VECTOR(23 downto 0) := x"FF0000" 

  );
PORT (
  CLK : IN STD_LOGIC;
  Cross_X  : IN NATURAL range 0 to 639;
  Cross_Y   : IN NATURAL range 0 to 479;
  iStream    : in   rgb_stream;
  oStream    : out  rgb_stream

);
END Draw_Cross;

ARCHITECTURE BEHAVIORAL OF Draw_Cross IS
  
BEGIN

  oStream.New_Pixel <= iStream.New_Pixel;
  oStream.Row       <= iStream.Row;
  oStream.Column    <= iStream.Column;
  oStream.R <= Color(23 downto 16) when ((iStream.Column >= Cross_X - Width/2 AND iStream.Column <= Cross_X + Width/2) AND (iStream.Row >= Cross_Y - Length/2 AND iStream.Row <= Cross_Y - Length/2)) OR
  ((iStream.Column >= Cross_X - Length/2 AND iStream.Column <= Cross_X + Length/2) AND (iStream.Row >= Cross_Y - Width/2 AND iStream.Row <= Cross_Y - Width/2)) else iStream.R;
  oStream.G <= Color(15 downto 8) when ((iStream.Column >= Cross_X - Width/2 AND iStream.Column <= Cross_X + Width/2) AND (iStream.Row >= Cross_Y - Length/2 AND iStream.Row <= Cross_Y - Length/2)) OR
  ((iStream.Column >= Cross_X - Length/2 AND iStream.Column <= Cross_X + Length/2) AND (iStream.Row >= Cross_Y - Width/2 AND iStream.Row <= Cross_Y - Width/2)) else iStream.G;
  oStream.B <= Color(7 downto 0) when ((iStream.Column >= Cross_X - Width/2 AND iStream.Column <= Cross_X + Width/2) AND (iStream.Row >= Cross_Y - Length/2 AND iStream.Row <= Cross_Y - Length/2)) OR
  ((iStream.Column >= Cross_X - Length/2 AND iStream.Column <= Cross_X + Length/2) AND (iStream.Row >= Cross_Y - Width/2 AND iStream.Row <= Cross_Y - Width/2)) else iStream.B;
  
END BEHAVIORAL;
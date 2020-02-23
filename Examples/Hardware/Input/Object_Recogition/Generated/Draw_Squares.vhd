  
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all; 
use work.Image_Data_Package.all;


ENTITY Draw_Squares IS
  GENERIC (
      Max_Square_Number : NATURAL := 32;
    Width             : NATURAL := 4;
    Color             : STD_LOGIC_VECTOR(23 downto 0) := x"FF0000" 

  );
PORT (
  CLK : IN STD_LOGIC;
  Squares     : IN  NATURAL range 0 to Max_Square_Number;
  Square_Addr : BUFFER NATURAL range 0 to Max_Square_Number-1;
  Square_X0   : IN  NATURAL range 0 to Image_Width-1;
  Square_X1   : IN  NATURAL range 0 to Image_Width-1;
  Square_Y0   : IN  NATURAL range 0 to Image_Height-1;
  Square_Y1   : IN  NATURAL range 0 to Image_Height-1;
  iStream    : in   rgb_stream;
  oStream    : out  rgb_stream

);
END Draw_Squares;

ARCHITECTURE BEHAVIORAL OF Draw_Squares IS

  SIGNAL X0   : NATURAL range 0 to Image_Width-1;
  SIGNAL X1   : NATURAL range 0 to Image_Width-1;
  SIGNAL Y0   : NATURAL range 0 to Image_Height-1;
  SIGNAL Y1   : NATURAL range 0 to Image_Height-1;
  
BEGIN

  oStream.New_Pixel <= iStream.New_Pixel;
  PROCESS (iStream)
    VARIABLE r : NATURAL range 0 to Image_Height-1;
    VARIABLE c : NATURAL range 0 to Image_Width-1;
    VARIABLE r_s : NATURAL range 0 to Image_Height-1;
    VARIABLE r_e : NATURAL range 0 to Image_Height-1;
    VARIABLE c_s : NATURAL range 0 to Image_Width-1;
    VARIABLE c_e : NATURAL range 0 to Image_Width-1;
    VARIABLE save_square : BOOLEAN := false;
  BEGIN
    IF (rising_edge(iStream.New_Pixel)) THEN
      r := iStream.Row;
      c := iStream.Column;
      IF (Square_Y0 > Width/2) THEN
        r_s := Square_Y0-Width/2;
      ELSE
        r_s := 0;
      END IF;
      IF (Square_Y1 < Image_Height-1-Width/2) THEN
        r_e := Square_Y1+Width/2;
      ELSE
        r_s := Image_Height-1;
      END IF;
      IF (Square_X0 > Width/2+Squares*2) THEN
        c_s := Square_X0-Width/2-Squares*2;
      ELSE
        c_s := 0;
      END IF;
      IF (Square_X1 < Image_Width-1-Width/2) THEN
        c_e := Square_X1+Width/2;
      ELSE
        c_s := Image_Width-1;
      END IF;
      IF (r >= r_s AND r <= r_e AND c >= c_s AND c <= c_e) THEN
        IF (NOT save_square) THEN
          X0 <= Square_X0;
          X1 <= Square_X1;
          Y0 <= Square_Y0;
          Y1 <= Square_Y1;
          save_square := true;
        
        END IF;
      ELSE
        save_square := false;
        IF (Square_Addr < Squares) THEN
          Square_Addr <= Square_Addr + 1;
        ELSE
          Square_Addr <= 0;
        END IF;
      END IF;
      oStream.Column    <= iStream.Column;
      oStream.Row       <= iStream.Row;
      IF ((((iStream.Column >= X0 - Width/2 AND iStream.Column <= X0 + Width/2) OR (iStream.Column >= X1 - Width/2 AND iStream.Column <= X1 + Width/2)) AND (iStream.Row >= Y0 AND iStream.Row <= Y1)) OR
(((iStream.Row >= Y0 - Width/2 AND iStream.Row <= Y0 + Width/2) OR (iStream.Row >= Y1 - Width/2 AND iStream.Row <= Y1 + Width/2)) AND (iStream.Column >= X0 AND iStream.Column <= X1))) THEN
        oStream.R <= Color(23 downto 16);
        oStream.G <= Color(15 downto 8);
        oStream.B <= Color(7 downto 0);
      ELSE
        oStream.R <= iStream.R;
        oStream.G <= iStream.G;
        oStream.B <= iStream.B;
      END IF;
    END IF;
  END PROCESS;
  
END BEHAVIORAL;
  
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all; 
use work.Image_Data_Package.all;


ENTITY Draw_Crosses IS
  GENERIC (
      Max_Cross_Number  : NATURAL := 32;
    Width             : NATURAL := 4;
    Length            : NATURAL := 8;
    Color             : STD_LOGIC_VECTOR(23 downto 0) := x"FF0000" 

  );
PORT (
  CLK : IN STD_LOGIC;
  Crosses     : IN  NATURAL range 0 to Max_Cross_Number;
  Cross_Addr  : BUFFER NATURAL range 0 to Max_Cross_Number-1;
  Cross_X     : IN NATURAL range 0 to Image_Width-1;
  Cross_Y     : IN NATURAL range 0 to Image_Height-1;
  iStream    : in   rgb_stream;
  oStream    : out  rgb_stream

);
END Draw_Crosses;

ARCHITECTURE BEHAVIORAL OF Draw_Crosses IS
  
BEGIN

  oStream.New_Pixel <= iStream.New_Pixel;
  PROCESS (iStream)
    VARIABLE X   : NATURAL range 0 to Image_Width-1;
    VARIABLE Y   : NATURAL range 0 to Image_Height-1;
    VARIABLE r : NATURAL range 0 to Image_Height-1;
    VARIABLE c : NATURAL range 0 to Image_Width-1;
    VARIABLE r_s : NATURAL range 0 to Image_Height-1;
    VARIABLE r_e : NATURAL range 0 to Image_Height-1;
    VARIABLE c_s : NATURAL range 0 to Image_Width-1;
    VARIABLE c_e : NATURAL range 0 to Image_Width-1;
    VARIABLE save_cross : BOOLEAN := false;
  BEGIN
    IF (rising_edge(iStream.New_Pixel)) THEN
      r := iStream.Row;
      c := iStream.Column;
      IF (Cross_Y > Length/2) THEN
        r_s := Cross_Y-Length/2;
      ELSE
        r_s := 0;
      END IF;
      IF (Cross_Y < Image_Height-1-Length/2) THEN
        r_e := Cross_Y+Length/2;
      ELSE
        r_e := Image_Height-1;
      END IF;
      IF (Cross_X > Length/2+Crosses*2) THEN
        c_s := Cross_X-Length/2-Crosses*2;
      ELSE
        c_s := 0;
      END IF;
      IF (Cross_X < Image_Width-1-Length/2) THEN
        c_e := Cross_X+Length/2;
      ELSE
        c_e := Image_Width-1;
      END IF;
      IF (r >= r_s AND r <= r_e AND c >= c_s AND c <= c_e) THEN
        IF (NOT save_cross) THEN
          X := Cross_X;
          Y := Cross_Y;
          save_cross := true;
        
        END IF;
      ELSE
        save_cross := false;
        IF (Cross_Addr < Crosses) THEN
          Cross_Addr <= Cross_Addr + 1;
        ELSE
          Cross_Addr <= 0;
        END IF;
      END IF;
      oStream.Column    <= iStream.Column;
      oStream.Row       <= iStream.Row;
      IF (((iStream.Column >= X - Width/2 AND iStream.Column <= X + Width/2) AND (iStream.Row >= Y - Length/2 AND iStream.Row <= Y + Length/2)) OR
((iStream.Column >= X - Length/2 AND iStream.Column <= X + Length/2) AND (iStream.Row >= Y - Width/2 AND iStream.Row <= Y + Width/2))) THEN
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
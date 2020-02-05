  
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all; 
use work.Image_Data_Package.all;


ENTITY RGB2HSV_Filter IS
  GENERIC (
      CLK_Edge    : BOOLEAN := true 

  );
PORT (
  CLK : IN STD_LOGIC;
  iStream    : in   rgb_stream;
  oStream    : out  rgb_stream

);
END RGB2HSV_Filter;

ARCHITECTURE BEHAVIORAL OF RGB2HSV_Filter IS

  SIGNAL oStream_buf : rgb_stream;
  SIGNAL iStream_buf : rgb_stream;
  SIGNAL New_Pixel_Buf : STD_LOGIC;
  
BEGIN

  oStream.New_Pixel <= iStream.New_Pixel;

  New_Pixel_Buf <= iStream.New_Pixel when CLK_Edge else NOT iStream.New_Pixel;
  PROCESS (New_Pixel_Buf)
    variable r_int, g_int, b_int : integer range 0 to 255;
    variable max_value, min_value, delta : integer range 0 to 255;
    variable h_value : integer range 0 to 255;
    variable s_value : integer range 0 to 255;
    VARIABLE degree_offset : NATURAL range 0 to 180 := 0;
    VARIABLE remainder_diff : INTEGER range -255 to 255 := 0;
  BEGIN
    IF (rising_edge(New_Pixel_Buf)) THEN
      iStream_buf <= iStream;
      oStream.R <= oStream_buf.R;
      oStream.G <= oStream_buf.G;
      oStream.B <= oStream_buf.B;
      oStream.Column <= oStream_buf.Column;
      oStream.Row <= oStream_buf.Row;
      oStream_buf.Column <= iStream_buf.Column;
      oStream_buf.Row    <= iStream_buf.Row;




      r_int := to_integer(unsigned(iStream_buf.R));
      g_int := to_integer(unsigned(iStream_buf.G));
      b_int := to_integer(unsigned(iStream_buf.B));
      IF (r_int > g_int and r_int > b_int) THEN
        max_value := r_int;
      ELSIF (g_int > r_int and g_int > b_int) THEN
        max_value := g_int;
      ELSE
        max_value := b_int;
      END IF;
      IF (r_int < g_int and r_int < b_int) THEN
        min_value := r_int;
      ELSIF (g_int < r_int and g_int < b_int) THEN
        min_value := g_int;
      ELSE
        min_value := b_int;
      END IF;
      delta := max_value-min_value;
      IF (delta = 0) THEN
        h_value := 0;
      ELSE
        IF (max_value = r_int AND g_int >= b_int) THEN
          degree_offset := 0;
        ELSIF (max_value = r_int AND g_int < b_int) THEN
          degree_offset := 180;
        ELSIF (max_value = g_int) THEN
          degree_offset := 60;
        ELSE
          degree_offset := 120;
        END IF;
        IF (max_value = r_int) THEN
          remainder_diff := g_int - b_int;
        ELSIF (max_value = g_int) THEN
          remainder_diff := b_int - r_int;
        ELSE
          remainder_diff := r_int - g_int;
        END IF;
        h_value := ((30 * remainder_diff)/delta) + degree_offset;
      END IF;
      IF (max_value = 0) THEN
        s_value := 0;
      ELSE
        s_value := (delta*255)/max_value;
      END IF;
      IF (h_value <= 180) THEN
        oStream_buf.R <= std_logic_vector(TO_UNSIGNED(h_value,8));
      ELSE
        oStream_buf.R <= std_logic_vector(to_unsigned(180, 8));
      END IF;
      IF (s_value <= 255) THEN
        oStream_buf.G <= std_logic_vector(TO_UNSIGNED(s_value,8));
      ELSE
        oStream_buf.G <= std_logic_vector(to_unsigned(255, 8));
      END IF;
      IF (max_value <= 255) THEN
        oStream_buf.B <= std_logic_vector(TO_UNSIGNED(max_value,8));
      ELSE
        oStream_buf.B <= std_logic_vector(to_unsigned(255, 8));
      END IF;
    END IF;
  END PROCESS;
  
END BEHAVIORAL;
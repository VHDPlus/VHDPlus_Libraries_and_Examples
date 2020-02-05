  
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all; 
use work.Image_Data_Package.all;


ENTITY Gaussian_Filter2 IS
  GENERIC (
      Image_Width : NATURAL := 640;
    Filter_Area : NATURAL := 3; 
    Color_Depth : NATURAL := 8; 
    Compression : NATURAL := 1; 
    Gaussian    : BOOLEAN := true; 
    HSV_Mode    : BOOLEAN := false; 
    CLK_Edge    : BOOLEAN := true 

  );
PORT (
  CLK : IN STD_LOGIC;
  iStream    : in   rgb_stream;
  oStream    : out  rgb_stream

);
END Gaussian_Filter2;

ARCHITECTURE BEHAVIORAL OF Gaussian_Filter2 IS

  SIGNAL iStream_buf    : rgb_stream;
  SIGNAL oStream_buf    : rgb_stream;
  type ram_type is array (Filter_Area-2 downto 0, Image_Width-1 downto 0) of std_logic_vector (Color_Depth-1 downto 0);
  signal RAM_r : ram_type;
  signal RAM_g : ram_type;
  signal RAM_b : ram_type;
  type ram_type_h is array (Filter_Area-2 downto 0, Image_Width-1 downto 0) of std_logic_vector (7 downto 0);
  signal RAM_h : ram_type_h;
  TYPE last_pixel_type IS ARRAY (Filter_Area-1 downto 0) OF std_logic_vector (Color_Depth-1 downto 0);
  TYPE last_pixel_arr_type IS ARRAY (Filter_Area downto 0) OF last_pixel_type;
  TYPE last_pixel_type_h IS ARRAY (Filter_Area-1 downto 0) OF std_logic_vector (7 downto 0);
  TYPE last_pixel_arr_type_h IS ARRAY (Filter_Area downto 0) OF last_pixel_type_h;
  SIGNAL New_Pixel_Buf : STD_LOGIC;
  
BEGIN

  oStream.New_Pixel <= iStream.New_Pixel;











  New_Pixel_Buf <= iStream.New_Pixel when CLK_Edge else NOT iStream.New_Pixel;
  PROCESS (New_Pixel_Buf)
    VARIABLE row_count : NATURAL range 0 to Filter_Area-2 := 0;
    VARIABLE last_col  : NATURAL range 0 to 639 := 0;
    VARIABLE Buf_r : last_pixel_arr_type;
    VARIABLE Buf_g : last_pixel_arr_type;
    VARIABLE Buf_b : last_pixel_arr_type;
    VARIABLE Buf_h : last_pixel_arr_type_h;
    VARIABLE r_add : NATURAL;
    VARIABLE g_add : NATURAL;
    VARIABLE b_add : NATURAL;
    VARIABLE divider : NATURAL range 0 to 1024;
    VARIABLE read_row : NATURAL range 0 to Filter_Area-2 := 0;
  BEGIN
    IF (rising_edge(New_Pixel_Buf)) THEN
      iStream_buf <= iStream;
      oStream.R <= oStream_buf.R;
      oStream.G <= oStream_buf.G;
      oStream.B <= oStream_buf.B;
      oStream.Column <= oStream_buf.Column;
      oStream.Row <= oStream_buf.Row;
      IF (last_col > iStream_buf.Column) THEN
        IF (row_count < Filter_Area-2) THEN
          row_count := row_count + 1;
        ELSE
          row_count := 0;
        END IF;
      
      END IF;
      last_col := iStream_buf.Column;
      IF (iStream_buf.Row > 2 AND iStream_buf.Column > 3) THEN
        oStream_buf.Column <= iStream_buf.Column-2;
        oStream_buf.Row    <= iStream_buf.Row-1;
        IF (iStream_buf.Column mod Compression = 0) THEN
          r_add := 0;
          g_add := 0;
          b_add := 0;
          IF (Gaussian) THEN
            FOR i IN 0 to Filter_Area-1 LOOP
              FOR j IN 1 to Filter_Area LOOP
                IF (HSV_Mode) THEN
                  r_add := r_add + TO_INTEGER(UNSIGNED(Buf_h(j)(i)))*(((Filter_Area-1)-(abs(i-Filter_Area/2)+abs(j-(Filter_Area/2+1))))*2);
                ELSE
                  r_add := r_add + TO_INTEGER(UNSIGNED(Buf_r(j)(i)))*(((Filter_Area-1)-(abs(i-Filter_Area/2)+abs(j-(Filter_Area/2+1))))*2);
                END IF;
                g_add := g_add + TO_INTEGER(UNSIGNED(Buf_g(j)(i)))*(((Filter_Area-1)-(abs(i-Filter_Area/2)+abs(j-(Filter_Area/2+1))))*2);
                b_add := b_add + TO_INTEGER(UNSIGNED(Buf_b(j)(i)))*(((Filter_Area-1)-(abs(i-Filter_Area/2)+abs(j-(Filter_Area/2+1))))*2);
              END LOOP;
            END LOOP;
            CASE (Filter_Area) IS
              WHEN 1 =>
                divider := 1;
              WHEN 3 =>
                divider := 16;
              WHEN 5 =>
                divider := 84;
              WHEN 7 =>
                divider := 256;
              WHEN others =>
                divider := 1;
            END CASE;
            IF (HSV_Mode) THEN
              oStream_buf.R <= STD_LOGIC_VECTOR(TO_UNSIGNED(r_add/divider, 8));
            ELSE
              oStream_buf.R(7 downto 8-Color_Depth) <= STD_LOGIC_VECTOR(TO_UNSIGNED(r_add/divider, Color_Depth));
            END IF;
            oStream_buf.G(7 downto 8-Color_Depth) <= STD_LOGIC_VECTOR(TO_UNSIGNED(g_add/divider, Color_Depth));
            oStream_buf.B(7 downto 8-Color_Depth) <= STD_LOGIC_VECTOR(TO_UNSIGNED(b_add/divider, Color_Depth));
          ELSE
            FOR i IN 0 to Filter_Area-1 LOOP
              FOR j IN 1 to Filter_Area LOOP
                IF (HSV_Mode) THEN
                  r_add := r_add + TO_INTEGER(UNSIGNED(Buf_h(j)(i)));
                ELSE
                  r_add := r_add + TO_INTEGER(UNSIGNED(Buf_r(j)(i)));
                END IF;
                g_add := g_add + TO_INTEGER(UNSIGNED(Buf_g(j)(i)));
                b_add := b_add + TO_INTEGER(UNSIGNED(Buf_b(j)(i)));
              END LOOP;
            END LOOP;
            IF (HSV_Mode) THEN
              oStream_buf.R <= STD_LOGIC_VECTOR(TO_UNSIGNED(r_add/Filter_Area**2, 8));
            ELSE
              oStream_buf.R(7 downto 8-Color_Depth) <= STD_LOGIC_VECTOR(TO_UNSIGNED(r_add/Filter_Area**2, Color_Depth));
            END IF;
            oStream_buf.G(7 downto 8-Color_Depth) <= STD_LOGIC_VECTOR(TO_UNSIGNED(g_add/Filter_Area**2, Color_Depth));
            oStream_buf.B(7 downto 8-Color_Depth) <= STD_LOGIC_VECTOR(TO_UNSIGNED(b_add/Filter_Area**2, Color_Depth));
          END IF;
        
        END IF;
      END IF;




      Buf_r(Filter_Area downto 1) := Buf_r(Filter_Area-1 downto 0);
      Buf_g(Filter_Area downto 1) := Buf_g(Filter_Area-1 downto 0);
      Buf_b(Filter_Area downto 1) := Buf_b(Filter_Area-1 downto 0);
      Buf_h(Filter_Area downto 1) := Buf_h(Filter_Area-1 downto 0);
      FOR i IN 0 to Filter_Area-2 LOOP
        IF (row_count >= i) THEN
          read_row := row_count-i;
        ELSE
          read_row := (Filter_Area-1)+row_count-i;
        END IF;
        Buf_r(0)(i) := RAM_r(read_row, iStream_buf.Column);
        Buf_g(0)(i) := RAM_g(read_row, iStream_buf.Column);
        Buf_b(0)(i) := RAM_b(read_row, iStream_buf.Column);
        Buf_h(0)(i) := RAM_h(read_row, iStream_buf.Column);
      END LOOP;
  
      Buf_r(0)(Filter_Area-1) := iStream_buf.R(7 downto 8-Color_Depth);
      Buf_g(0)(Filter_Area-1) := iStream_buf.G(7 downto 8-Color_Depth);
      Buf_b(0)(Filter_Area-1) := iStream_buf.B(7 downto 8-Color_Depth);
      Buf_h(0)(Filter_Area-1) := iStream_buf.R;
      RAM_r(row_count, iStream_buf.Column)   <= iStream_buf.R(7 downto 8-Color_Depth);
      RAM_g(row_count, iStream_buf.Column)   <= iStream_buf.G(7 downto 8-Color_Depth);
      RAM_b(row_count, iStream_buf.Column)   <= iStream_buf.B(7 downto 8-Color_Depth);
      RAM_h(row_count, iStream_buf.Column)   <= iStream_buf.R;
    END IF;
  END PROCESS;
  
END BEHAVIORAL;
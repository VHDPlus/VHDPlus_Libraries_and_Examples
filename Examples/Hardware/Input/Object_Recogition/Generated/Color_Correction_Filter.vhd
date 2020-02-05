  
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all; 
use work.Image_Data_Package.all;


ENTITY Color_Correction_Filter IS
  GENERIC (
      CLK_Edge    : BOOLEAN := true 

  );
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
  iStream      : in   rgb_stream;
  oStream      : out  rgb_stream

);
END Color_Correction_Filter;

ARCHITECTURE BEHAVIORAL OF Color_Correction_Filter IS

  SIGNAL iStream_buf    : rgb_stream;
  SIGNAL oStream_buf    : rgb_stream;
  SIGNAL New_Pixel_Buf : STD_LOGIC;
  
BEGIN

  oStream.New_Pixel <= iStream.New_Pixel;



  New_Pixel_Buf <= iStream.New_Pixel when CLK_Edge else NOT iStream.New_Pixel;
  PROCESS (New_Pixel_Buf)
    VARIABLE pixel_buf_r : INTEGER range -100 to 355;
    VARIABLE pixel_buf_g : INTEGER range -100 to 355;
    VARIABLE pixel_buf_b : INTEGER range -100 to 355;
  BEGIN
    IF (rising_edge(New_Pixel_Buf)) THEN
      iStream_buf <= iStream;
      oStream.R <= oStream_buf.R;
      oStream.G <= oStream_buf.G;
      oStream.B <= oStream_buf.B;
      oStream.Column <= oStream_buf.Column;
      oStream.Row <= oStream_buf.Row;



      pixel_buf_r := (TO_INTEGER(UNSIGNED(iStream_buf.R))*R_Multiplier)/R_Divider + R_Add;
      pixel_buf_g := (TO_INTEGER(UNSIGNED(iStream_buf.G))*G_Multiplier)/G_Divider + G_Add;
      pixel_buf_b := (TO_INTEGER(UNSIGNED(iStream_buf.B))*B_Multiplier)/B_Divider + B_Add;
      oStream_buf.Column <= iStream_buf.Column;
      oStream_buf.Row    <= iStream_buf.Row;
      IF (pixel_buf_r <= 255 AND pixel_buf_r >= 0) THEN
        oStream_buf.R <= STD_LOGIC_VECTOR(TO_UNSIGNED(pixel_buf_r,8));
      ELSIF (pixel_buf_r > 255) THEN
        oStream_buf.R <= (others => '1');
      ELSE
        oStream_buf.R <= (others => '0');
      END IF;
      IF (pixel_buf_g <= 255 AND pixel_buf_g >= 0) THEN
        oStream_buf.G <= STD_LOGIC_VECTOR(TO_UNSIGNED(pixel_buf_g,8));
      ELSIF (pixel_buf_g > 255) THEN
        oStream_buf.G <= (others => '1');
      ELSE
        oStream_buf.G <= (others => '0');
      END IF;
      IF (pixel_buf_b <= 255 AND pixel_buf_b >= 0) THEN
        oStream_buf.B <= STD_LOGIC_VECTOR(TO_UNSIGNED(pixel_buf_b,8));
      ELSIF (pixel_buf_b > 255) THEN
        oStream_buf.B <= (others => '1');
      ELSE
        oStream_buf.B <= (others => '0');
      END IF;
    END IF;
  END PROCESS;
  
END BEHAVIORAL;
  
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all; 
use work.Image_Data_Package.all;


ENTITY Row_Compression IS
  GENERIC (
      compression : NATURAL := 4;
    Color_Depth : NATURAL := 8;
    CLK_Edge    : BOOLEAN := true 

  );
PORT (
  CLK : IN STD_LOGIC;
  iStream    : in   rgb_stream;
  oStream    : out  rgb_stream

);
END Row_Compression;

ARCHITECTURE BEHAVIORAL OF Row_Compression IS

  SIGNAL New_Pixel_Buf : STD_LOGIC;
  SIGNAL compress_count : NATURAL range 0 to compression-1 := 0;
  
BEGIN

  oStream.New_Pixel <= iStream.New_Pixel;
  oStream.Column    <= ((iStream.Column-3)/compression);
  oStream.Row       <= iStream.Row;

  New_Pixel_Buf <= iStream.New_Pixel when CLK_Edge else NOT iStream.New_Pixel;
  PROCESS (New_Pixel_Buf)
    VARIABLE sum_r : NATURAL range 0 to ((Color_Depth**2)*compression) := 0;
    VARIABLE sum_g : NATURAL range 0 to ((Color_Depth**2)*compression) := 0;
    VARIABLE sum_b : NATURAL range 0 to ((Color_Depth**2)*compression) := 0;
  BEGIN
    IF (rising_edge(New_Pixel_Buf)) THEN
      sum_r := sum_r + TO_INTEGER(UNSIGNED(iStream.R));
      sum_g := sum_g + TO_INTEGER(UNSIGNED(iStream.G));
      sum_b := sum_b + TO_INTEGER(UNSIGNED(iStream.B));
      IF (compress_count < compression-1) THEN
        compress_count <= compress_count + 1;
      ELSE
        oStream.R <= STD_LOGIC_VECTOR(TO_UNSIGNED(sum_r/compression, oStream.R'LENGTH));
        oStream.G <= STD_LOGIC_VECTOR(TO_UNSIGNED(sum_g/compression, oStream.G'LENGTH));
        oStream.B <= STD_LOGIC_VECTOR(TO_UNSIGNED(sum_b/compression, oStream.B'LENGTH));
        sum_r := 0;
        sum_g := 0;
        sum_b := 0;
        compress_count <= 0;
      END IF;
    END IF;
  END PROCESS;
  
END BEHAVIORAL;
  
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all; 
use work.Image_Data_Package.all;


ENTITY Color_Threshold_HSV_Filter IS
  GENERIC (
      CLK_Edge    : BOOLEAN := true 

  );
PORT (
  CLK : IN STD_LOGIC;
  H_Min : IN NATURAL := 0;   
  H_Max : IN NATURAL := 255; 
  S_Min : IN NATURAL := 0;   
  S_Max : IN NATURAL := 255; 
  V_Min : IN NATURAL := 0;   
  V_Max : IN NATURAL := 255; 
  iStream    : in   rgb_stream;
  oStream    : out  rgb_stream

);
END Color_Threshold_HSV_Filter;

ARCHITECTURE BEHAVIORAL OF Color_Threshold_HSV_Filter IS

  SIGNAL iStream_buf    : rgb_stream;
  SIGNAL oStream_buf    : rgb_stream;
  SIGNAL New_Pixel_Buf : STD_LOGIC;
  
BEGIN

  oStream.New_Pixel <= iStream.New_Pixel;

  New_Pixel_Buf <= iStream.New_Pixel when CLK_Edge else NOT iStream.New_Pixel;
  PROCESS (New_Pixel_Buf)
    VARIABLE in_range : BOOLEAN;
  BEGIN
    IF (rising_edge(New_Pixel_Buf)) THEN
      iStream_buf <= iStream;
      oStream_buf.Column <= iStream_buf.Column;
      oStream_buf.Row    <= iStream_buf.Row;
      oStream.R <= oStream_buf.R;
      oStream.G <= oStream_buf.G;
      oStream.B <= oStream_buf.B;
      oStream.Column <= oStream_buf.Column;
      oStream.Row <= oStream_buf.Row;

      in_range := (((UNSIGNED(iStream_buf.R) >= H_Min AND UNSIGNED(iStream_buf.R) <= H_Max) AND H_Min <= H_Max) OR ((UNSIGNED(iStream_buf.R) >= H_Min OR UNSIGNED(iStream_buf.R) <= H_Max) AND H_Min > H_Max)) AND
      UNSIGNED(iStream_buf.G) >= S_Min AND UNSIGNED(iStream_buf.G) <= S_Max AND UNSIGNED(iStream_buf.B) >= V_Min AND UNSIGNED(iStream_buf.B) <= V_Max;
      IF (in_range) THEN
        oStream_buf.R <= (others => '1');
        oStream_buf.G <= (others => '1');
        oStream_buf.B <= (others => '1');
      ELSE
        oStream_buf.R <= (others => '0');
        oStream_buf.G <= (others => '0');
        oStream_buf.B <= (others => '0');
      END IF;
    END IF;
  END PROCESS;
  
END BEHAVIORAL;
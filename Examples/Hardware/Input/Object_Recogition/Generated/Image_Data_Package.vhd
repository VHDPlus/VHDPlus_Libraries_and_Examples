
library IEEE;  
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all; 


PACKAGE Image_Data_Package is
  CONSTANT Image_Width  : NATURAL := 640;
  CONSTANT Image_Height : NATURAL := 480;
  CONSTANT Image_FPS    : NATURAL := 50;
  TYPE rgb_data IS RECORD
  R : STD_LOGIC_VECTOR(7 downto 0);
  G : STD_LOGIC_VECTOR(7 downto 0);
  B : STD_LOGIC_VECTOR(7 downto 0);
  END RECORD rgb_data;
  TYPE rgb_stream IS RECORD
  R         : STD_LOGIC_VECTOR(7 downto 0);
  G         : STD_LOGIC_VECTOR(7 downto 0);
  B         : STD_LOGIC_VECTOR(7 downto 0);
  Column    : NATURAL range 0 to Image_Width-1;
  Row       : NATURAL range 0 to Image_Height-1;
  New_Pixel : STD_LOGIC;
  END RECORD rgb_stream;
END PACKAGE Image_Data_Package;


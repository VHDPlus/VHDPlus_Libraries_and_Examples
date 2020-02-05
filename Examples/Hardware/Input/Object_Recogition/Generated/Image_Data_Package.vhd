
library IEEE;  
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all; 


PACKAGE Image_Data_Package is
  TYPE rgb_data IS RECORD
  R : STD_LOGIC_VECTOR(7 downto 0);
  G : STD_LOGIC_VECTOR(7 downto 0);
  B : STD_LOGIC_VECTOR(7 downto 0);
  END RECORD rgb_data;
  TYPE rgb_stream IS RECORD
  R         : STD_LOGIC_VECTOR(7 downto 0);
  G         : STD_LOGIC_VECTOR(7 downto 0);
  B         : STD_LOGIC_VECTOR(7 downto 0);
  Column    : NATURAL range 0 to 639;
  Row       : NATURAL range 0 to 479;
  New_Pixel : STD_LOGIC;
  END RECORD rgb_stream;
END PACKAGE Image_Data_Package;


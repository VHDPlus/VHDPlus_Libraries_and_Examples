  
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all; 


ENTITY Camera_Capture IS
  GENERIC (
      Compression : NATURAL := 3;  
    Width       : NATURAL := 4  

  );
PORT (
  CLK : IN STD_LOGIC;
  New_Pixel   : IN     STD_LOGIC := '0';
  Column      : IN     NATURAL range 0 to 639 := 0;
  Row         : IN     NATURAL range 0 to 479 := 0;
  Pixel_R     : IN     STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
  Pixel_G     : IN     STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
  Pixel_B     : IN     STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
  Read_Column : IN     NATURAL range 0 to 639 := 0;
  Read_Row    : IN     NATURAL range 0 to 479 := 0;
  Read_Data   : OUT    STD_LOGIC_VECTOR(23 downto 0) := (others => '0')

);
END Camera_Capture;

ARCHITECTURE BEHAVIORAL OF Camera_Capture IS

  CONSTANT xWidth : NATURAL := 640/Compression;
  CONSTANT yWidth : NATURAL := 480/Compression;
  TYPE column_type IS ARRAY (xWidth-1 downto 0) OF STD_LOGIC_VECTOR((Width*3)-1 downto 0);
  TYPE frame_type IS ARRAY (yWidth-1 downto 0) OF column_type;
  SIGNAL image : frame_type := (others => (others => (others => '0')));
  SIGNAL RAM_Write    : STD_LOGIC := '0';
  SIGNAL RAM_Addr_Col : NATURAL range 0 to xWidth-1 := 0;
  SIGNAL RAM_Addr_Row : NATURAL range 0 to yWidth-1 := 0;
  SIGNAL RAM_Out_Col  : NATURAL range 0 to xWidth-1 := 0;
  SIGNAL RAM_Out_Row  : NATURAL range 0 to yWidth-1 := 0;
  SIGNAL RAM_Data_In  : STD_LOGIC_VECTOR((Width*3)-1 downto 0) := (others => '0');
  SIGNAL RAM_Data_Out : STD_LOGIC_VECTOR((Width*3)-1 downto 0) := (others => '0');
  
BEGIN
  RAM_Out_Col <= Read_Column/Compression;
  RAM_Out_Row <= Read_Row/Compression;
  RAM_Data_Out <= image(RAM_Out_Row)(RAM_Out_Col);
  Read_Data(23 downto 24-Width) <= RAM_Data_Out((Width*3)-1 downto Width*2);
  Read_Data(15 downto 16-Width) <= RAM_Data_Out((Width*2)-1 downto Width);
  Read_Data(7  downto 8-Width)  <= RAM_Data_Out((Width)-1   downto 0);
  RAM_Controller : PROCESS (CLK)  
    
  BEGIN
  IF RISING_EDGE(CLK) THEN
    IF (RAM_Write = '1') THEN
      image(RAM_Addr_Row)(RAM_Addr_Col) <= RAM_Data_In;
    
    END IF;
  END IF;
  END PROCESS;
  Pixel_Capture : PROCESS (New_Pixel)
    VARIABLE skip_row  : NATURAL range 0 to Compression-1 := 0;
    VARIABLE skip_col  : NATURAL range 0 to Compression-1 := 0;
    VARIABLE Col_prev  : NATURAL range 0 to 639 := 0;
    VARIABLE Row_prev  : NATURAL range 0 to 479 := 0;
  BEGIN
    IF (falling_edge(New_Pixel)) THEN
      IF (RAM_Write = '1') THEN
        RAM_Write <= '0';
      
      END IF;
      IF (Row_prev /= Row) THEN
        Row_prev := Row;
        IF (skip_row < Compression-1 AND Row > 0) THEN
          skip_row := skip_row + 1;
        ELSE
          skip_row := 0;
        END IF;
      
      END IF;
      IF (Col_prev /= Column) THEN
        Col_prev := Column;
        IF (skip_col < Compression-1 AND Column > 0) THEN
          skip_col := skip_col + 1;
        ELSE
          skip_col := 0;
        END IF;
      
      END IF;
      IF (skip_row = Compression/2 AND skip_col = Compression/2) THEN
        RAM_Data_In <= Pixel_R(7 downto 8-Width) & Pixel_G(7 downto 8-Width) & Pixel_B(7 downto 8-Width);
        RAM_Addr_Row <= Row/Compression;
        RAM_Addr_Col <= Column/Compression;
        RAM_Write <= '1';
      END IF;
    END IF;
  END PROCESS;
  
END BEHAVIORAL;
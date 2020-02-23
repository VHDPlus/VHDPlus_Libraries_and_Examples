  
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all; 
use work.Image_Data_Package.all;


ENTITY Camera_Capture IS
  GENERIC (
      Compression : NATURAL := 3;  
    Width       : NATURAL := 4;  
    Full_Image  : BOOLEAN := true; 
    RGB         : BOOLEAN := true;
    CLK_Edge    : BOOLEAN := true 

  );
PORT (
  CLK : IN STD_LOGIC;
  New_Pixel   : IN     STD_LOGIC := '0';
  Column      : IN     NATURAL range 0 to Image_Width-1 := 0;
  Row         : IN     NATURAL range 0 to Image_Height-1 := 0;
  Pixel_R     : IN     STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
  Pixel_G     : IN     STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
  Pixel_B     : IN     STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
  Read_Column : IN     NATURAL range 0 to 639 := 0;
  Read_Row    : IN     NATURAL range 0 to 479 := 0;
  Read_Data   : OUT    STD_LOGIC_VECTOR(23 downto 0) := (others => '0')

);
END Camera_Capture;

ARCHITECTURE BEHAVIORAL OF Camera_Capture IS

  CONSTANT xWidth : NATURAL := 639/Compression;
  CONSTANT yWidth : NATURAL := 479/Compression;
  TYPE column_type IS ARRAY (xWidth-1 downto 0) OF STD_LOGIC_VECTOR((Width)-1 downto 0);
  TYPE frame_type IS ARRAY (yWidth-1 downto 0) OF column_type;
  SIGNAL image_r : frame_type := (others => (others => (others => '0')));
  SIGNAL image_g : frame_type := (others => (others => (others => '0')));
  SIGNAL image_b : frame_type := (others => (others => (others => '0')));
  SIGNAL RAM_Out_Col  : NATURAL range 0 to xWidth-1 := 0;
  SIGNAL RAM_Out_Row  : NATURAL range 0 to yWidth-1 := 0;
  SIGNAL RAM_Data_Out : STD_LOGIC_VECTOR((Width*3)-1 downto 0) := (others => '0');
  SIGNAL Column_buf      : NATURAL range 0 to 639 := 0;
  SIGNAL Row_buf         : NATURAL range 0 to 479 := 0;
  SIGNAL Pixel_R_buf     : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
  SIGNAL Pixel_G_buf     : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
  SIGNAL Pixel_B_buf     : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
  SIGNAL New_Pixel_Buf : STD_LOGIC;
  
BEGIN

  RAM_Out_Col <= Read_Column/Compression;
  RAM_Out_Row <= Read_Row/Compression;
  RAM_Data_Out <= image_r(RAM_Out_Row)(RAM_Out_Col) & image_g(RAM_Out_Row)(RAM_Out_Col) & image_b(RAM_Out_Row)(RAM_Out_Col);
  Read_Data(23 downto 24-Width) <= RAM_Data_Out((Width*3)-1 downto Width*2);
  Read_Data(15 downto 16-Width) <= RAM_Data_Out((Width*2)-1 downto Width) when RGB else RAM_Data_Out((Width*3)-1 downto Width*2);
  Read_Data(7  downto 8-Width)  <= RAM_Data_Out((Width)-1   downto 0) when RGB else RAM_Data_Out((Width*3)-1 downto Width*2);

  New_Pixel_Buf <= New_Pixel when CLK_Edge else NOT New_Pixel;
  Pixel_Capture : PROCESS (New_Pixel_Buf)
    VARIABLE skip_row  : NATURAL range 0 to Compression-1 := 0;
    VARIABLE skip_col  : NATURAL range 0 to Compression-1 := 0;
    VARIABLE Col_prev  : NATURAL range 0 to Image_Width-1 := 0;
    VARIABLE Row_prev  : NATURAL range 0 to Image_Height-1 := 0;

    VARIABLE RAM_Data_In_R  : STD_LOGIC_VECTOR((Width)-1 downto 0) := (others => '0');
    VARIABLE RAM_Data_In_G  : STD_LOGIC_VECTOR((Width)-1 downto 0) := (others => '0');
    VARIABLE RAM_Data_In_B  : STD_LOGIC_VECTOR((Width)-1 downto 0) := (others => '0');
    VARIABLE RAM_Addr_Col : NATURAL range 0 to xWidth-1 := 0;
    VARIABLE RAM_Addr_Row : NATURAL range 0 to yWidth-1 := 0;
  BEGIN
    IF (rising_edge(New_Pixel_Buf)) THEN
      Column_buf <= Column * (640/Image_Width);
      Row_buf    <= Row * (480/Image_Height);
      Pixel_R_buf <= Pixel_R;
      Pixel_G_buf <= Pixel_G;
      Pixel_B_buf <= Pixel_B;
      IF (Row_prev /= Row_buf) THEN
        Row_prev := Row_buf;
        IF (skip_row < Compression-1 AND Row_buf > 0) THEN
          skip_row := skip_row + 1;
        ELSE
          skip_row := 0;
        END IF;
      
      END IF;
      IF (Col_prev /= Column_buf) THEN
        Col_prev := Column_buf;
        IF (skip_col < Compression-1 AND Column_buf > 0) THEN
          skip_col := skip_col + 1;
        ELSE
          skip_col := 0;
        END IF;
      
      END IF;
      IF (Full_Image) THEN
        IF (skip_row = Compression/2 AND skip_col = Compression/2) THEN
          RAM_Data_In_R := Pixel_R_buf(7 downto 8-Width);
          RAM_Data_In_G := Pixel_G_buf(7 downto 8-Width);
          RAM_Data_In_B := Pixel_B_buf(7 downto 8-Width);
          RAM_Addr_Row := Row_buf/Compression;
          RAM_Addr_Col := Column_buf/Compression;
        
        END IF;
      ELSE
        IF (Row_buf < 480/Compression AND Column_buf < 640/Compression) THEN
          RAM_Data_In_R := Pixel_R_buf(7 downto 8-Width);
          RAM_Data_In_G := Pixel_G_buf(7 downto 8-Width);
          RAM_Data_In_B := Pixel_B_buf(7 downto 8-Width);
          RAM_Addr_Row := Row_buf;
          RAM_Addr_Col := Column_buf;
        END IF;
      END IF;
      image_r(RAM_Addr_Row)(RAM_Addr_Col) <= RAM_Data_In_R;
      IF (RGB) THEN
        image_g(RAM_Addr_Row)(RAM_Addr_Col) <= RAM_Data_In_G;
        image_b(RAM_Addr_Row)(RAM_Addr_Col) <= RAM_Data_In_B;
      END IF;
    END IF;
  END PROCESS;
  
END BEHAVIORAL;
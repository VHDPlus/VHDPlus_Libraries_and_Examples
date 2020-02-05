  
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all; 
use work.Image_Data_Package.all;


ENTITY AreaLimitedCompression IS
  GENERIC (
      Image_Width : NATURAL := 640;
    Image_Height: NATURAL := 480;
    MAX_Area_O  : NATURAL := 4;  
    MAX_Area    : NATURAL range 1 to 24 := 10; 
    MIN_Area    : NATURAL range 1 to 24 := 1;
    Colors      : NATURAL := 1;
    Start_Row   : NATURAL := 0;
    CLK_Edge    : BOOLEAN := true 

  );
PORT (
  CLK : IN STD_LOGIC;
  iPixel     : IN STD_LOGIC_VECTOR(Colors-1 downto 0);
  iColumn    : IN NATURAL range 0 to Image_Width-1;
  iRow       : IN NATURAL range 0 to Image_Height-1;
  iNew_Pixel : IN STD_LOGIC;
  oPixel     : OUT STD_LOGIC_VECTOR(Colors-1 downto 0);
  oColumn    : OUT NATURAL range 0 to Image_Width-1;
  oRow       : OUT NATURAL range 0 to Image_Height-1;
  oNew_Pixel : OUT STD_LOGIC

);
END AreaLimitedCompression;

ARCHITECTURE BEHAVIORAL OF AreaLimitedCompression IS

  SIGNAL iPixel_buf    : STD_LOGIC_VECTOR(Colors-1 downto 0);
  SIGNAL oPixel_buf    : STD_LOGIC_VECTOR(Colors-1 downto 0);
  TYPE last_pixel_sub_row_type IS ARRAY (NATURAL range <>) OF STD_LOGIC_VECTOR(Colors-1 downto 0);
  TYPE last_pixel_row_type IS ARRAY (NATURAL range <>) OF last_pixel_sub_row_type(MAX_Area-1 downto 0);
  SIGNAL New_Pixel_Buf : STD_LOGIC;
  TYPE col_add IS ARRAY (Colors-1 downto 0) OF NATURAL range 0 to MAX_Area*2;
  TYPE matrix_add IS ARRAY (Colors-1 downto 0) OF NATURAL range 0 to MAX_Area**2;
  TYPE sum_matrix_type IS ARRAY (NATURAL range <>) OF col_add;
  SIGNAL sum_matrix : sum_matrix_type(Image_Width-1 downto 0);
  
BEGIN

  oNew_Pixel <= iNew_Pixel;



  New_Pixel_Buf <= iNew_Pixel when CLK_Edge else NOT iNew_Pixel;
  PROCESS (New_Pixel_Buf)
    VARIABLE area_width    : NATURAL range 1 to 24;
    CONSTANT row_divider   : NATURAL := (Image_Height-Start_Row)/(MAX_Area-MIN_Area+1);
    VARIABLE r_add : matrix_add;
    VARIABLE sum_buf_i : col_add;
    VARIABLE sum_buf_o : col_add;
    VARIABLE add_c : NATURAL range 0 to MAX_Area-1 := 0;
    VARIABLE row_reg : NATURAL range 0 to Image_Height-1 := 0;
    VARIABLE add_r   : NATURAL range 0 to MAX_Area-1 := 0;
  BEGIN
    IF (rising_edge(New_Pixel_Buf)) THEN
      iPixel_buf <= iPixel;
      oPixel <= oPixel_buf;
      oColumn <= iColumn-2-(area_width/2);
      oRow    <= iRow-1-(area_width/2);
      IF (iRow < Start_Row) THEN
        area_width := MAX_Area;
      ELSE
        area_width := (iRow-Start_Row)/row_divider+MIN_Area;
      END IF;
      IF (iRow <= area_width OR iColumn <= area_width+1) THEN
        oPixel <= (others => '0');
      
      END IF;



      sum_buf_i := sum_matrix(iColumn);
      FOR i IN 0 to Colors-1 LOOP
        sum_buf_o(i) := sum_buf_i(i) + TO_INTEGER("0" & iPixel(i));
      END LOOP;
      IF (add_r = area_width-1) THEN
        FOR k IN 0 to Colors-1 LOOP
          r_add(k) := r_add(k) + sum_buf_o(k);
        END LOOP;
        IF (add_c = area_width-1) THEN
          FOR k IN 0 to Colors-1 LOOP
            IF (r_add(k) > (MAX_Area_O*area_width**2)/(MAX_Area**2)) THEN
              oPixel(k) <= '1';
            ELSE
              oPixel(k) <= '0';
            END IF;
          END LOOP;
  
          r_add := (others => 0);
        
        END IF;
        sum_buf_o := (others => 0);
      
      END IF;
      IF (add_c < area_width-1) THEN
        add_c := add_c + 1;
      ELSE
        add_c := 0;
      END IF;
      IF (row_reg /= iRow) THEN
        IF (add_r < area_width-1) THEN
          add_r := add_r + 1;
        ELSE
          add_r := 0;
        END IF;
      END IF;
      row_reg := iRow;
      sum_matrix(iColumn) <= sum_buf_o;
    END IF;
  END PROCESS;
  
END BEHAVIORAL;
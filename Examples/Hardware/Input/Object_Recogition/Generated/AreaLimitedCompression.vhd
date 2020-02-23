  
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all; 
use work.Image_Data_Package.all;


ENTITY AreaLimitedCompression IS
  GENERIC (
      Min_Pixel_Num  : NATURAL := 4;  
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
  TYPE last_row_type IS ARRAY (Image_Width/MIN_Area-1 downto 0) OF STD_LOGIC_VECTOR (Colors-1 downto 0);
  SIGNAL last_Row : last_row_type;
  TYPE area_shift_type IS ARRAY (MAX_Area-1 downto 0) OF NATURAL range 1 to 24;
  SIGNAL area_shift : area_shift_type;
  SIGNAL add_c     : NATURAL range 0 to MAX_Area-1 := 0;
  SIGNAL last_row_addr : NATURAL range 0 to Image_Width/MIN_Area;
  SIGNAL add_r   : NATURAL range 0 to MAX_Area-1 := 0;
  SIGNAL area_width       : NATURAL range 1 to 24 := MIN_Area;
  
BEGIN

  oNew_Pixel <= iNew_Pixel;



  New_Pixel_Buf <= iNew_Pixel when CLK_Edge else NOT iNew_Pixel;
  PROCESS (New_Pixel_Buf)
    VARIABLE oColumn_buf   : NATURAL range 0 to Image_Width-1;
    VARIABLE oRow_buf      : NATURAL range 0 to Image_Height-1;
    VARIABLE r_add : matrix_add;
    VARIABLE sum_buf_o : col_add;
    VARIABLE area_width_reg    : NATURAL range 1 to 24 := MIN_Area;
    VARIABLE last_row_addr_reg : NATURAL range 0 to Image_Width/MIN_Area;
    VARIABLE last_row_out  : STD_LOGIC_VECTOR (Colors-1 downto 0);
    VARIABLE last_row_in   : STD_LOGIC_VECTOR (Colors-1 downto 0);
    VARIABLE column_reg : NATURAL range 0 to Image_Width-1 := 0;
    VARIABLE row_reg : NATURAL range 0 to Image_Height-1 := 0;
    CONSTANT row_divider    : NATURAL := (Image_Height-Start_Row)/(MAX_Area-MIN_Area+1);
  BEGIN
    IF (rising_edge(New_Pixel_Buf)) THEN
      iPixel_buf <= iPixel;
      oPixel     <= oPixel_buf;
      oColumn    <= oColumn_buf;
      oRow       <= oRow_buf;



      area_width_reg := area_shift(area_width-1);

      last_row_addr_reg := (last_row_addr * area_width) / area_width_reg;
      sum_buf_o := sum_matrix(iColumn);
      FOR k IN 0 to Colors-1 LOOP
        IF (iPixel(k) = '1') THEN
          sum_buf_o(k) := sum_buf_o(k) + 1;
        
        END IF;
      END LOOP;
      IF (iColumn > area_width+1) THEN
        oColumn_buf := iColumn-area_width-1;
      ELSE
        oColumn_buf := Image_Width-area_width+iColumn-1;
      END IF;
      IF (iRow > 0) THEN
        oRow_buf    := iRow-1;
      ELSE
        oRow_buf    := Image_Height-1;
      END IF;


      last_row_out  := last_Row(last_row_addr);
      last_row_in   := last_Row(last_row_addr_reg);
      IF (oRow_buf > area_width AND oColumn_buf > 0) THEN
        oPixel_buf <= last_row_in;
      ELSE
        oPixel_buf <= (others => '0');
      END IF;
      IF (add_r = area_width-1) THEN
        FOR k IN 0 to Colors-1 LOOP
          r_add(k) := r_add(k) + sum_buf_o(k);
        END LOOP;
        IF (add_c = area_width-1) THEN
          FOR k IN 0 to Colors-1 LOOP
            IF (r_add(k) > (Min_Pixel_Num*area_width**2)/(MAX_Area**2)) THEN
              last_row_out(k) := '1';
            ELSE
              last_row_out(k) := '0';
            END IF;
          END LOOP;
  
          last_Row(last_row_addr) <= last_row_out;
          r_add := (others => 0);
        
        END IF;
        sum_buf_o := (others => 0);
      
      END IF;
      sum_matrix(iColumn) <= sum_buf_o;
      IF (add_c < area_width-1 AND iColumn > column_reg) THEN
        add_c <= add_c + 1;
      ELSE
        add_c <= 0;
        last_row_addr <= last_row_addr + 1;
      END IF;
      column_reg := iColumn;
      IF (row_reg /= iRow) THEN
        area_shift(MAX_Area-1 downto 1) <= area_shift(MAX_Area-2 downto 0);
        area_shift(0) <= area_width;
        last_row_addr <= 0;
        IF (add_r < area_width-1 AND iRow > row_reg) THEN
          add_r <= add_r + 1;
        ELSE
          add_r <= 0;
          add_c <= 0;
          IF (iRow < Start_Row) THEN
            area_width <= MIN_Area;
          ELSE
            area_width <= (iRow-Start_Row)/row_divider+MIN_Area;
          END IF;
        END IF;
      END IF;
      row_reg := iRow;
    END IF;
  END PROCESS;
  
END BEHAVIORAL;
  
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all; 
use work.sdram_config.all;
use work.sdram_controller_interface.all;


ENTITY Color_Correction_Filter IS
  GENERIC (
      R_Multiplier : NATURAL := 1;
    R_Divider    : NATURAL := 1;
    R_Add        : INTEGER := 0;
    G_Multiplier : NATURAL := 1;
    G_Divider    : NATURAL := 1;
    G_Add        : INTEGER := 0;
    B_Multiplier : NATURAL := 1;
    B_Divider    : NATURAL := 1;
    B_Add        : INTEGER := 0

  );
PORT (
  CLK : IN STD_LOGIC;
  iPixel_R   : IN STD_LOGIC_VECTOR (7 downto 0);
  iPixel_G   : IN STD_LOGIC_VECTOR (7 downto 0);
  iPixel_B   : IN STD_LOGIC_VECTOR (7 downto 0);
  iColumn    : IN NATURAL range 0 to 639 := 0;
  iRow       : IN NATURAL range 0 to 479 := 0;
  iNew_Pixel : IN STD_LOGIC;
  oPixel_R   : OUT STD_LOGIC_VECTOR (7 downto 0);
  oPixel_G   : OUT STD_LOGIC_VECTOR (7 downto 0);
  oPixel_B   : OUT STD_LOGIC_VECTOR (7 downto 0);
  oColumn    : BUFFER NATURAL range 0 to 639 := 0;
  oRow       : BUFFER NATURAL range 0 to 479 := 0;
  oNew_Pixel : BUFFER STD_LOGIC

);
END Color_Correction_Filter;

ARCHITECTURE BEHAVIORAL OF Color_Correction_Filter IS
  
BEGIN
  R_Calc : PROCESS (iNew_Pixel)
    
  BEGIN
    IF (rising_edge(iNew_Pixel)) THEN
      oPixel_R <= STD_LOGIC_VECTOR(TO_UNSIGNED((TO_INTEGER(UNSIGNED(iPixel_R))*R_Multiplier)/R_Divider + R_Add, oPixel_R'LENGTH));
    
    END IF;
  END PROCESS;
  G_Calc : PROCESS (iNew_Pixel)
    
  BEGIN
    IF (rising_edge(iNew_Pixel)) THEN
      oPixel_G <= STD_LOGIC_VECTOR(TO_UNSIGNED((TO_INTEGER(UNSIGNED(iPixel_G))*G_Multiplier)/G_Divider + G_Add, oPixel_G'LENGTH));
    
    END IF;
  END PROCESS;
  B_Calc : PROCESS (iNew_Pixel)
    
  BEGIN
    IF (rising_edge(iNew_Pixel)) THEN
      oPixel_B <= STD_LOGIC_VECTOR(TO_UNSIGNED((TO_INTEGER(UNSIGNED(iPixel_B))*B_Multiplier)/B_Divider + B_Add, oPixel_B'LENGTH));
    
    END IF;
  END PROCESS;
  Col_Row_Shift : PROCESS (iNew_Pixel)
  BEGIN
    IF (rising_edge(iNew_Pixel)) THEN
      oColumn    <= iColumn;
      oRow       <= iRow;
      oNew_Pixel <= iNew_Pixel;
    END IF;
  END PROCESS;
  
END BEHAVIORAL;
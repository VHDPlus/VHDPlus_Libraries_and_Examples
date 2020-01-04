  
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all; 
use work.sdram_config.all;
use work.sdram_controller_interface.all;


ENTITY Test_Image_Generator IS
  GENERIC (
      image_size_div : NATURAL := 1;
    pixel_clk_div  : NATURAL := 1 

  );
PORT (
  CLK : IN STD_LOGIC;
  oPixel_R   : OUT STD_LOGIC_VECTOR (7 downto 0);
  oPixel_G   : OUT STD_LOGIC_VECTOR (7 downto 0);
  oPixel_B   : OUT STD_LOGIC_VECTOR (7 downto 0);
  oColumn    : OUT NATURAL range 0 to 639 := 0;
  oRow       : OUT NATURAL range 0 to 479 := 0;
  oNew_Pixel : OUT STD_LOGIC

);
END Test_Image_Generator;

ARCHITECTURE BEHAVIORAL OF Test_Image_Generator IS

  SIGNAL pixel_clk : STD_LOGIC;
  SIGNAL colum_count : NATURAL range 0 to 640/image_size_div-1 := 0;
  SIGNAL row_count   : NATURAL range 0 to 480/image_size_div-1 := 0;
  SIGNAL out_pixel_buf : STD_LOGIC_VECTOR(23 downto 0);
  
BEGIN
  oColumn    <= colum_count;
  oRow       <= row_count;
  oNew_Pixel <= pixel_clk;
  oPixel_R   <= out_pixel_buf(23 downto 16);
  oPixel_G   <= out_pixel_buf(15 downto 8);
  oPixel_B   <= out_pixel_buf(7 downto 0);
  PROCESS (CLK)  
    VARIABLE pixel_clk_count : NATURAL range 0 to pixel_clk_div-1 := 0;
    
  BEGIN
  IF RISING_EDGE(CLK) THEN
    IF (pixel_clk_count < pixel_clk_div-1) THEN
      pixel_clk_count := pixel_clk_count + 1;
    ELSE
      pixel_clk <= NOT pixel_clk;
      pixel_clk_count := 0;
    END IF;
  END IF;
  END PROCESS;
  PROCESS (pixel_clk)
    VARIABLE Thread8 : NATURAL range 0 to 2 := 0;
    VARIABLE Thread11 : NATURAL range 0 to 3 := 0;
  BEGIN
    IF (rising_edge(pixel_clk)) THEN
      CASE (Thread8) IS
        WHEN 0 =>
          row_count <= 0;
          Thread8 := 1;
        WHEN 1 =>
          IF ( row_count < 480/image_size_div-1) THEN 
            Thread8 := Thread8 + 1;
          ELSE
            Thread8 := 0;
          END IF;
        WHEN (1+1) =>
          CASE (Thread11) IS
            WHEN 0 =>
              colum_count <= 0;
              out_pixel_buf <= (others => '0');
              Thread11 := 1;
            WHEN 1 =>
              IF ( colum_count < 640/image_size_div-1) THEN 
                out_pixel_buf <= STD_LOGIC_VECTOR(UNSIGNED(out_pixel_buf)+((2**24)/(639/image_size_div)));

               colum_count <= colum_count + 1;
              ELSE
                Thread11 := Thread11 + 1;
              END IF;
            WHEN 2 =>
              row_count <= row_count + 1;
              Thread8 := 1;
              Thread11 := 0;
            WHEN others => Thread11 := 0;
          END CASE;
        WHEN others => Thread8 := 0;
      END CASE;
    END IF;
  END PROCESS;
  
END BEHAVIORAL;
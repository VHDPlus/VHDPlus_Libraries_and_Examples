  
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all; 
use work.Image_Data_Package.all;


ENTITY Gaussian_RGB_Filter IS

PORT (
  CLK : IN STD_LOGIC;
  iStream    : in   rgb_stream;
  oStream    : out  rgb_stream

);
END Gaussian_RGB_Filter;

ARCHITECTURE BEHAVIORAL OF Gaussian_RGB_Filter IS
  COMPONENT Gaussian_Filter IS
  GENERIC (
      depth : integer:=650

  );
  PORT (
    CLK : IN STD_LOGIC;
    New_Pixel  : in   STD_LOGIC;
    iColumn    : IN   NATURAL range 0 to 639 := 0;
    iRow       : IN   NATURAL range 0 to 479 := 0;
    iPixel     : in   STD_LOGIC_VECTOR (7 downto 0);
    oColumn    : OUT  NATURAL range 0 to 639 := 0;
    oRow       : OUT  NATURAL range 0 to 479 := 0;
    oPixel     : out  STD_LOGIC_VECTOR (7 downto 0)

  );
  END COMPONENT;
  
BEGIN
  oStream.New_Pixel <= iStream.New_Pixel;
  Gaussian_Filter1 : Gaussian_Filter
  GENERIC MAP (
      depth     => 650

  ) PORT MAP (
    CLK => CLK,
    New_Pixel => iStream.New_Pixel,
    iColumn   => iStream.Column,
    iRow      => iStream.Row,
    iPixel    => iStream.R,
    oPixel    => oStream.R,
    oColumn   => oStream.Column,
    oRow      => oStream.Row

    
  );
  Gaussian_Filter2 : Gaussian_Filter
  GENERIC MAP (
      depth     => 650

  ) PORT MAP (
    CLK => CLK,
    New_Pixel => iStream.New_Pixel,
    iColumn   => iStream.Column,
    iRow      => iStream.Row,
    iPixel    => iStream.G,
    oPixel    => oStream.G

    
  );
  Gaussian_Filter3 : Gaussian_Filter
  GENERIC MAP (
      depth     => 650

  ) PORT MAP (
    CLK => CLK,
    New_Pixel => iStream.New_Pixel,
    iColumn   => iStream.Column,
    iRow      => iStream.Row,
    iPixel    => iStream.B,
    oPixel    => oStream.B
  );
  
END BEHAVIORAL;
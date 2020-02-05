  
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all; 
use work.Image_Data_Package.all;


ENTITY Gaussian_Filter IS
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
END Gaussian_Filter;

ARCHITECTURE BEHAVIORAL OF Gaussian_Filter IS

  signal GR11 : std_logic_vector (12 downto 0):=(others=>'0');
  signal GR12 : std_logic_vector (12 downto 0):=(others=>'0');
  signal GR13 : std_logic_vector (12 downto 0):=(others=>'0');
  signal GR21 : std_logic_vector (12 downto 0):=(others=>'0');
  signal GR22 : std_logic_vector (12 downto 0):=(others=>'0');
  signal GR23 : std_logic_vector (12 downto 0):=(others=>'0');
  signal GR31 : std_logic_vector (12 downto 0):=(others=>'0');
  signal GR32 : std_logic_vector (12 downto 0):=(others=>'0');
  signal GR33 : std_logic_vector (12 downto 0):=(others=>'0');
  signal data : unsigned (12 downto 0):=(others=>'0');
  SIGNAL reset : STD_LOGIC;
  COMPONENT LineBuffer IS
  GENERIC (
      depth : integer:=256;
    width : integer:=8

  );
  PORT (
    CLK : IN STD_LOGIC;
    Reset     : in  STD_LOGIC;
    new_pixel : in  STD_LOGIC;
    pixel_in  : in  STD_LOGIC_VECTOR (width-1 downto 0);
    GR11 : out  STD_LOGIC_VECTOR (width-1 downto 0);
    GR12 : out  STD_LOGIC_VECTOR (width-1 downto 0);
    GR13 : out  STD_LOGIC_VECTOR (width-1 downto 0);
    GR21 : out  STD_LOGIC_VECTOR (width-1 downto 0);
    GR22 : out  STD_LOGIC_VECTOR (width-1 downto 0);
    GR23 : out  STD_LOGIC_VECTOR (width-1 downto 0);
    GR31 : out  STD_LOGIC_VECTOR (width-1 downto 0);
    GR32 : out  STD_LOGIC_VECTOR (width-1 downto 0);
    GR33 : out  STD_LOGIC_VECTOR (width-1 downto 0)

  );
  END COMPONENT;
  
BEGIN

  oColumn <= iColumn - 1 when iColumn > 0 else 649-iColumn;
  oRow    <= iRow - 1 when iRow > 0 else 479-iRow;











  reset <= '1' when iColumn = 649-11 else '0';
  data <= UNSIGNED(GR11) + UNSIGNED(GR11) + UNSIGNED(GR12) + UNSIGNED(GR13) +
  UNSIGNED(GR21) + UNSIGNED(GR22) + UNSIGNED(GR23) + UNSIGNED(GR31) +
  UNSIGNED(GR32) + UNSIGNED(GR33);
  oPixel <= STD_LOGIC_VECTOR(data(11 downto 4)) when data(12) = '0' else (others => '1');
  LineBuffer1 : LineBuffer
  GENERIC MAP (
      depth     => depth,
    width     => 8

  ) PORT MAP (
    CLK => CLK,
    Reset     => reset,
    new_pixel => new_pixel,
    pixel_in  => iPixel,
    GR11      => GR11(7 downto 0),
    GR12      => GR12(8 downto 1),
    GR13      => GR13(7 downto 0),
    GR21      => GR21(8 downto 1),
    GR22      => GR22(9 downto 2),
    GR23      => GR23(8 downto 1),
    GR31      => GR31(7 downto 0),
    GR32      => GR32(8 downto 1),
    GR33      => GR33(7 downto 0)
  );
  
END BEHAVIORAL;
  
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all; 
use work.Image_Data_Package.all;


ENTITY LineBuffer IS
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
END LineBuffer;

ARCHITECTURE BEHAVIORAL OF LineBuffer IS

  type reg_array is array(0 to 1) of std_logic_vector(width-1 downto 0);
  signal reg1:reg_array:=(others=>(others=>'0'));
  signal reg2:reg_array:=(others=>(others=>'0'));
  signal reg3:reg_array:=(others=>(others=>'0'));
  signal out1,out2: std_logic_vector(width-1 downto 0):=(others=>'0');
  COMPONENT RamShiftRegister IS
  GENERIC (
      depth : integer:=256;
    width : integer:=8

  );
  PORT (
    CLK : IN STD_LOGIC;
    rst       : in  STD_LOGIC;
    new_pixel : in  STD_LOGIC;
    pixel_in  : in  STD_LOGIC_VECTOR (width-1 downto 0);
    pixel_out : out  STD_LOGIC_VECTOR (width-1 downto 0)

  );
  END COMPONENT;
  
BEGIN
  GR11<=reg1(1);
  GR12<=reg1(0);
  GR13<=pixel_in;
  GR21<=reg2(1);
  GR22<=reg2(0);
  GR23<=out1;
  GR31<=reg3(1);
  GR32<=reg3(0);
  GR33<=out2;
  PROCESS (new_pixel)
  BEGIN
    IF (falling_edge(new_pixel)) THEN
      reg1(1)<=reg1(0);
      reg1(0)<=pixel_in;
      reg2(1)<=reg2(0);
      reg2(0)<=out1;
      reg3(1)<=reg3(0);
      reg3(0)<=out2;
    END IF;
  END PROCESS;
  RamShiftRegister1 : RamShiftRegister
  GENERIC MAP (
      depth     => depth,
    width     => width

  ) PORT MAP (
    CLK => CLK,
    rst       => Reset,
    new_pixel => new_pixel,
    pixel_in  => pixel_in,
    pixel_out => out1

    
  );
  RamShiftRegister2 : RamShiftRegister
  GENERIC MAP (
      depth     => depth,
    width     => width

  ) PORT MAP (
    CLK => CLK,
    rst       => Reset,
    new_pixel => new_pixel,
    pixel_in  => out1,
    pixel_out => out2
  );
  
END BEHAVIORAL;
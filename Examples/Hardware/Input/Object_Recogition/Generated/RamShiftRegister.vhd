  
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all; 
use work.Image_Data_Package.all;


ENTITY RamShiftRegister IS
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
END RamShiftRegister;

ARCHITECTURE BEHAVIORAL OF RamShiftRegister IS

  type memory is array (0 to depth-1) of std_logic_vector(width-1 downto 0);
  signal ram:memory:=(others=>(others=>'0'));
  signal data:std_logic_vector(width-1 downto 0):=(others=>'0');
  signal addr_p,addr_n:integer range 0 to depth-2:=0;
  
BEGIN
  addr_n<=0 when addr_p=depth-2 else
  addr_p+1;
  pixel_out<=data;
  PROCESS (new_pixel)
  BEGIN
    IF (rising_edge(new_pixel)) THEN
      ram(addr_p)<=pixel_in;
      data<=ram(addr_p);
      IF (rst = '1') THEN
        addr_p <= depth-2;
      ELSE
        addr_p<=addr_n;
      END IF;
    END IF;
  END PROCESS;
  
END BEHAVIORAL;
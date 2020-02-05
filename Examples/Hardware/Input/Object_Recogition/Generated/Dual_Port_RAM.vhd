  
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all; 
use work.Image_Data_Package.all;


ENTITY Dual_Port_RAM IS
  GENERIC (
      bits    : NATURAL := 8;     
    width   : NATURAL := 256   

  );
PORT (
  CLK : IN STD_LOGIC;
  write_a   : in  std_logic := '1';               
  write_b   : in  std_logic := '1';
  address_a : in  natural range 0 to width-1;
  address_b : in  natural range 0 to width-1;
  dataIn_a  : in  std_logic_vector(bits-1 downto 0); 
  dataIn_b  : in  std_logic_vector(bits-1 downto 0);
  dataOut_a : out std_logic_vector(bits-1 downto 0);  
  dataOut_b : out std_logic_vector(bits-1 downto 0)

);
END Dual_Port_RAM;

ARCHITECTURE BEHAVIORAL OF Dual_Port_RAM IS

  type ram_type is array (width-1 downto 0) of std_logic_vector (bits-1 downto 0);   
  signal RAM : ram_type;
  
BEGIN
  dataOut_a <= RAM(address_a);
  dataOut_b <= RAM(address_b);
  PROCESS (CLK)  
    
  BEGIN
  IF RISING_EDGE(CLK) THEN
    IF (write_a = '1') THEN
      RAM(address_a) <= dataIn_a;
    
    END IF;
  END IF;
  END PROCESS;
  PROCESS (CLK)
  BEGIN
  IF RISING_EDGE(CLK) THEN
    IF (write_b = '1') THEN
      RAM(address_b) <= dataIn_b;
    END IF;
  END IF;
  END PROCESS;
  
END BEHAVIORAL;
  
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all; 


ENTITY CSI_Data_Deserializer IS
PORT (
  CLK : IN STD_LOGIC;
  d_lane  : IN STD_LOGIC_VECTOR (1 downto 0); 
  bit_clk : IN STD_LOGIC;
  data_o  : OUT STD_LOGIC_VECTOR (7 downto 0);
  state   : OUT INTEGER range 0 to 7 

);
END CSI_Data_Deserializer;

ARCHITECTURE BEHAVIORAL OF CSI_Data_Deserializer IS

  SIGNAL dataIsZero : BOOLEAN := false;
  SIGNAL startTrans : BOOLEAN := false;
  SIGNAL dataIsOne : BOOLEAN := false;
  SIGNAL receivedData : STD_LOGIC_VECTOR := (others => '0');
  SIGNAL receiveState : INTEGER range 0 to 7 := 0;
  
BEGIN
  PROCESS (d_lane)
    
  BEGIN
    IF (rising_edge(d_lane(0))) THEN
      dataIsZero  <= NOT dataIsZero;
    
    END IF;
  END PROCESS;
  PROCESS (d_lane)
    
  BEGIN
    IF (rising_edge(d_lane(1))) THEN
      dataIsOne  <= NOT dataIsOne;
    
    END IF;
  END PROCESS;
  PROCESS (bit_clk)
    VARIABLE zeroReg : BOOLEAN := false;
    VARIABLE oneReg : BOOLEAN := false;
    
  BEGIN
    IF (rising_edge(bit_clk)) THEN
      IF (zeroReg /= dataIsZero) THEN
        receivedData <= '0' & receivedData(7 downto 1);
      ELSIF (oneReg /= dataIsOne) THEN
        receivedData <= '1' & receivedData(7 downto 1);
      ELSE
        receivedData <= d_lane(1) & receivedData(7 downto 1);
      END IF;
      zeroReg := dataIsZero;
      oneReg  := dataIsOne;
    
    END IF;
  END PROCESS;
  PROCESS (bit_clk)
  BEGIN
    IF (startTrans AND receiveState = 7) THEN
      receiveState <= 0;
    ELSIF (rising_edge(bit_clk)) THEN
      IF (d_lane = "11") THEN
      END IF;
    END IF;
  END PROCESS;
  
END BEHAVIORAL;
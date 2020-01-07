  
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all; 


ENTITY RGB2FakeLAB_Filter IS
PORT (
  CLK : IN STD_LOGIC;
  iPixel_R   : IN STD_LOGIC_VECTOR (7 downto 0);
  iPixel_G   : IN STD_LOGIC_VECTOR (7 downto 0);
  iPixel_B   : IN STD_LOGIC_VECTOR (7 downto 0);
  oLAB_L     : OUT STD_LOGIC_VECTOR (7 downto 0);
  oLAB_A     : OUT STD_LOGIC_VECTOR (7 downto 0);
  oLAB_B     : OUT STD_LOGIC_VECTOR (7 downto 0)

);
END RGB2FakeLAB_Filter;

ARCHITECTURE BEHAVIORAL OF RGB2FakeLAB_Filter IS

  CONSTANT l_weight_r : NATURAL := 3;
  CONSTANT l_weight_g : NATURAL := 5;
  CONSTANT l_weight_b : NATURAL := 2;
  CONSTANT a_weight_r : INTEGER := 3;
  CONSTANT a_weight_g : INTEGER := -5;
  CONSTANT a_weight_b : INTEGER := 2;
  CONSTANT b_weight_r : INTEGER := 2;
  CONSTANT b_weight_g : INTEGER := 3;
  CONSTANT b_weight_b : INTEGER := -5;
  SIGNAL l_val : UNSIGNED (11 downto 0);
  SIGNAL a_val : SIGNED (11 downto 0);
  SIGNAL b_val : SIGNED (11 downto 0);
  SIGNAL l_val2 : UNSIGNED (8 downto 0);
  SIGNAL a_val2 : SIGNED (9 downto 0);
  SIGNAL b_val2 : SIGNED (9 downto 0);
  
BEGIN

  l_val <= TO_UNSIGNED(TO_INTEGER(UNSIGNED(iPixel_R))*l_weight_r + TO_INTEGER(UNSIGNED(iPixel_G))*l_weight_g + TO_INTEGER(UNSIGNED(iPixel_B))*l_weight_b, 12);
  a_val <= TO_SIGNED(TO_INTEGER(UNSIGNED(iPixel_R))*a_weight_r + TO_INTEGER(UNSIGNED(iPixel_G))*a_weight_g + TO_INTEGER(UNSIGNED(iPixel_B))*a_weight_b, 12);
  b_val <= TO_SIGNED(TO_INTEGER(UNSIGNED(iPixel_R))*b_weight_r + TO_INTEGER(UNSIGNED(iPixel_G))*b_weight_g + TO_INTEGER(UNSIGNED(iPixel_B))*b_weight_b, 12);

  l_val2 <= resize(shift_right(l_val,3),9);
  oLAB_L <= STD_LOGIC_VECTOR(l_val2(7 downto 0)) when l_val2(8) = '0' else (others => '1');


  a_val2 <= resize(shift_right(a_val,3) + 127,10); 
  b_val2 <= resize(shift_right(b_val,3) + 127,10);
  oLAB_A <= STD_LOGIC_VECTOR(UNSIGNED(abs(a_val2))(7 downto 0)) when a_val2 <= 255 AND a_val2 >= 0 else
  (others => '0') when a_val2 < 0 else
  (others => '1');
  oLAB_B <= STD_LOGIC_VECTOR(UNSIGNED(abs(b_val2))(7 downto 0)) when b_val2 <= 255 AND b_val2 >= 0 else
  (others => '0') when b_val2 < 0 else
  (others => '1');
  
END BEHAVIORAL;
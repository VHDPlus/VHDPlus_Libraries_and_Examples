  
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all; 


ENTITY RGB2HSV_Filter IS
PORT (
  CLK : IN STD_LOGIC;
  iPixel_R   : IN STD_LOGIC_VECTOR (7 downto 0);
  iPixel_G   : IN STD_LOGIC_VECTOR (7 downto 0);
  iPixel_B   : IN STD_LOGIC_VECTOR (7 downto 0);
  oPixel_H     : OUT STD_LOGIC_VECTOR (7 downto 0);
  oPixel_S     : OUT STD_LOGIC_VECTOR (7 downto 0);
  oPixel_V     : OUT STD_LOGIC_VECTOR (7 downto 0)

);
END RGB2HSV_Filter;

ARCHITECTURE BEHAVIORAL OF RGB2HSV_Filter IS

  signal r_int, g_int, b_int : integer range 0 to 255;
  signal max_value, min_value, delta : integer range 0 to 255;
  signal h_value : integer range 0 to 255;
  signal s_value : integer range 0 to 255;
  SIGNAL degree_offset : NATURAL range 0 to 180 := 0;
  SIGNAL remainder_diff : INTEGER range -255 to 255 := 0;
  
BEGIN

  r_int <= to_integer(unsigned(iPixel_R));
  g_int <= to_integer(unsigned(iPixel_G));
  b_int <= to_integer(unsigned(iPixel_B));
  max_value <= r_int when (r_int > g_int and r_int > b_int) else
  g_int when (g_int > r_int and g_int > b_int) else
  b_int;
  min_value <= r_int when (r_int < g_int and r_int < b_int) else
  g_int when (g_int < r_int and g_int < b_int) else
  b_int;
  delta <= max_value-min_value;

  degree_offset <= 0 when delta = 0 else
  0   when (max_value = r_int AND g_int >= b_int) else
  180 when (max_value = r_int AND g_int < b_int)  else
  60  when (max_value = g_int) else
  120 when (max_value = b_int);

  remainder_diff <= 0 when delta = 0 else
  g_int - b_int when (max_value = r_int) else
  b_int - r_int when (max_value = g_int) else
  r_int - g_int when (max_value = b_int);
  h_value <= 0 when delta = 0 else
  ((30 * remainder_diff)/delta) + degree_offset;
  s_value <= 0 when max_value = 0 else
  (delta*255)/max_value;
  oPixel_H <= std_logic_vector(TO_UNSIGNED(h_value,8)) when h_value <= 180 else std_logic_vector(to_unsigned(180, 8));
  oPixel_S <= std_logic_vector(TO_UNSIGNED(s_value,8)) when s_value <= 255 else std_logic_vector(to_unsigned(255, 8));
  oPixel_V <= std_logic_vector(TO_UNSIGNED(max_value,8)) when max_value <= 255 else std_logic_vector(to_unsigned(255, 8));
  
END BEHAVIORAL;
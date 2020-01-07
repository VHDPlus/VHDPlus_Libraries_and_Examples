  
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all; 


ENTITY HDMI_Out IS
PORT (
  CLK : IN STD_LOGIC;
  VS_PCLK    : IN  STD_LOGIC;
  VS_SCLK    : IN  STD_LOGIC;
  VS_R       : IN  STD_LOGIC_VECTOR (7 downto 0);
  VS_G       : IN  STD_LOGIC_VECTOR (7 downto 0);
  VS_B       : IN  STD_LOGIC_VECTOR (7 downto 0);
  VS_HS      : IN  STD_LOGIC;
  VS_VS      : IN  STD_LOGIC;
  VS_DE      : IN  STD_LOGIC;
  oHDMI_DATA : OUT STD_LOGIC_VECTOR(2 downto 0);
  oHDMI_CLK  : OUT STD_LOGIC;
  iHDMI_HPD  : IN  STD_LOGIC

);
END HDMI_Out;

ARCHITECTURE BEHAVIORAL OF HDMI_Out IS

  component DVI_OUT
  port (
  iPCLK  : IN STD_LOGIC;
  iSCLK  : IN STD_LOGIC;
  iRED   : IN STD_LOGIC_VECTOR(7 downto 0);
  iGRN   : IN STD_LOGIC_VECTOR(7 downto 0);
  iBLU   : IN STD_LOGIC_VECTOR(7 downto 0);
  iHS    : IN STD_LOGIC;
  iVS    : IN STD_LOGIC;
  iDE    : IN STD_LOGIC;
  oDVI_DATA : OUT STD_LOGIC_VECTOR(2 downto 0);
  oDVI_CLK  : OUT STD_LOGIC;
  iDVI_HPD  : IN  STD_LOGIC
  );
  end component;
  
BEGIN

  u1: DVI_OUT port map
  (
  iPCLK     => VS_PCLK,
  iSCLK     => VS_SCLK,
  iRED      => VS_R,
  iGRN      => VS_G,
  iBLU      => VS_B,
  iHS       => VS_HS,
  iVS       => VS_VS,
  iDE       => VS_DE,
  oDVI_DATA => oHDMI_DATA,
  oDVI_CLK  => oHDMI_CLK,
  iDVI_HPD  => iHDMI_HPD
  );
  
END BEHAVIORAL;
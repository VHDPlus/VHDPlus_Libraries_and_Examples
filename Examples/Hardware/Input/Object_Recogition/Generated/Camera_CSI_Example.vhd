  
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all; 

      
ENTITY Camera_CSI_Example IS

PORT (
  CLK : IN STD_LOGIC;
  Camera_CLK_Lane      : IN     STD_LOGIC;
  Camera_Data_Lane     : IN     STD_LOGIC_VECTOR (1 downto 0);
  Camera_Enable        : OUT    STD_LOGIC;
  Camera_SCL           : INOUT  STD_LOGIC;
  Camera_SDA           : INOUT  STD_LOGIC;
  oHDMI_TX             : OUT    STD_LOGIC_VECTOR(2 downto 0);
  oHDMI_CLK            : OUT    STD_LOGIC;
  iHDMI_HPD            : IN     STD_LOGIC

);
END Camera_CSI_Example;

ARCHITECTURE BEHAVIORAL OF Camera_CSI_Example IS

  SIGNAL Camera_Pixel_R       : STD_LOGIC_VECTOR (7 downto 0);
  SIGNAL Camera_Pixel_G       : STD_LOGIC_VECTOR (7 downto 0);
  SIGNAL Camera_Pixel_B       : STD_LOGIC_VECTOR (7 downto 0);
  SIGNAL Camera_Column        : NATURAL          range 0 to 639;
  SIGNAL Camera_Row           : NATURAL          range 0 to 479;
  SIGNAL Camera_New_Pixel     : STD_LOGIC;
  SIGNAL Color_Correction_Filter_oPixel_R     : STD_LOGIC_VECTOR (7 downto 0);
  SIGNAL Color_Correction_Filter_oPixel_G     : STD_LOGIC_VECTOR (7 downto 0);
  SIGNAL Color_Correction_Filter_oPixel_B     : STD_LOGIC_VECTOR (7 downto 0);
  SIGNAL ISSP1_source : std_logic_vector (7 downto 0) := "01001000";
  SIGNAL ISSP2_source : std_logic_vector (7 downto 0) := "00010001";
  SIGNAL ISSP1_probe  : std_logic_vector (31 downto 0);
  SIGNAL ISSP2_probe  : std_logic_vector (31 downto 0);
  SIGNAL Color_Threshold_Filter_iHSV_H       : STD_LOGIC_VECTOR (7 downto 0);
  SIGNAL Color_Threshold_Filter_iHSV_S       : STD_LOGIC_VECTOR (7 downto 0);
  SIGNAL Color_Threshold_Filter_iHSV_V       : STD_LOGIC_VECTOR (7 downto 0);
  SIGNAL Color_Threshold_Filter_iPixel_X     : STD_LOGIC_VECTOR (7 downto 0);
  SIGNAL Color_Threshold_Filter_iPixel_Y     : STD_LOGIC_VECTOR (7 downto 0);
  SIGNAL Color_Threshold_Filter_iPixel_Z     : STD_LOGIC_VECTOR (7 downto 0);
  SIGNAL Yellow_Filter_oPixel_R     : STD_LOGIC_VECTOR (7 downto 0);
  SIGNAL Yellow_Filter_oPixel_G     : STD_LOGIC_VECTOR (7 downto 0);
  SIGNAL Yellow_Filter_oPixel_B     : STD_LOGIC_VECTOR (7 downto 0);
  SIGNAL Black_Filter_oPixel_R     : STD_LOGIC_VECTOR (7 downto 0);
  SIGNAL Black_Filter_oPixel_G     : STD_LOGIC_VECTOR (7 downto 0);
  SIGNAL Black_Filter_oPixel_B     : STD_LOGIC_VECTOR (7 downto 0);
  SIGNAL Blue_Filter_oPixel_R     : STD_LOGIC_VECTOR (7 downto 0);
  SIGNAL Blue_Filter_oPixel_G     : STD_LOGIC_VECTOR (7 downto 0);
  SIGNAL Blue_Filter_oPixel_B     : STD_LOGIC_VECTOR (7 downto 0);
  SIGNAL White_Filter_oPixel_R     : STD_LOGIC_VECTOR (7 downto 0);
  SIGNAL White_Filter_oPixel_G     : STD_LOGIC_VECTOR (7 downto 0);
  SIGNAL White_Filter_oPixel_B     : STD_LOGIC_VECTOR (7 downto 0);
  SIGNAL Camera_Capture_iPixel_R     : STD_LOGIC_VECTOR (7 downto 0);
  SIGNAL Camera_Capture_iPixel_G     : STD_LOGIC_VECTOR (7 downto 0);
  SIGNAL Camera_Capture_iPixel_B     : STD_LOGIC_VECTOR (7 downto 0);
  SIGNAL ISSP_source : std_logic_vector (7 downto 0) := "00000000";
  SIGNAL ISSP_probe  : std_logic_vector (31 downto 0);
  SIGNAL hsync : STD_LOGIC;
  SIGNAL vsync : STD_LOGIC;
  SIGNAL CLK_150MHz : STD_LOGIC;
  SIGNAL blob_in : NATURAL range 0 to 255;
  TYPE blob_pos IS RECORD
  x0 : NATURAL range 0 to 1024;
  y0 : NATURAL range 0 to 1024;
  x1 : NATURAL range 0 to 1024;
  y1 : NATURAL range 0 to 1024;
  END RECORD blob_pos;
  SIGNAL blob_detection_blob_data      : std_logic_vector (7 downto 0);
  SIGNAL blob_detection_mem_addr       : std_logic_vector (15 downto 0);
  SIGNAL blob_detection_mem_data       : std_logic_vector (15 downto 0);
  SIGNAL blob_detection_mem_wr         : std_logic;
  CONSTANT blob_buf_width : NATURAL := 32;
  TYPE blob_buf_type IS ARRAY (0 to blob_buf_width-1) OF blob_pos;
  SIGNAL blob_buf : blob_buf_type;
  SIGNAL blobs_in_buf : NATURAL range 0 to blob_buf_width-1 := 0;
  TYPE Square_oPixel_type IS ARRAY (0 to 32) OF STD_LOGIC_VECTOR (7 downto 0);
  SIGNAL Square_oPixel_R : Square_oPixel_type;
  SIGNAL Square_oPixel_G : Square_oPixel_type;
  SIGNAL Square_oPixel_B : Square_oPixel_type;
  SIGNAL Camera_Capture_Read_Column : NATURAL          range 0 to 639;
  SIGNAL Camera_Capture_Read_Row    : NATURAL          range 0 to 479;
  SIGNAL Camera_Capture_Read_Data   : STD_LOGIC_VECTOR (23 downto 0);
  SIGNAL Camera_Capture_SDRAM_Read_Ena      : STD_LOGIC;
  SIGNAL HDMI_Out_VS_PCLK   : STD_LOGIC;
  SIGNAL HDMI_Out_VS_SCLK   : STD_LOGIC;
  SIGNAL HDMI_Out_VS_R      : STD_LOGIC_VECTOR (7 downto 0);
  SIGNAL HDMI_Out_VS_G      : STD_LOGIC_VECTOR (7 downto 0);
  SIGNAL HDMI_Out_VS_B      : STD_LOGIC_VECTOR (7 downto 0);
  SIGNAL HDMI_Out_VS_HS     : STD_LOGIC;
  SIGNAL HDMI_Out_VS_VS     : STD_LOGIC;
  SIGNAL HDMI_Out_VS_DE     : STD_LOGIC;
  COMPONENT CSI_Camera IS
  GENERIC (
      CLK_Frequency : NATURAL := 12000000

  );
  PORT (
    CLK : IN STD_LOGIC;
    Reset     : IN STD_LOGIC := '0';                
    CLK_Lane  : IN STD_LOGIC;                       
    Data_Lane : IN STD_LOGIC_VECTOR(1 downto 0);    
    SCL       : INOUT STD_LOGIC;
    SDA       : INOUT STD_LOGIC;
    Pixel_R   : OUT STD_LOGIC_VECTOR (7 downto 0);
    Pixel_G   : OUT STD_LOGIC_VECTOR (7 downto 0);
    Pixel_B   : OUT STD_LOGIC_VECTOR (7 downto 0);
    Column    : BUFFER NATURAL range 0 to 639 := 0;
    Row       : BUFFER NATURAL range 0 to 479 := 0;
    New_Pixel : BUFFER STD_LOGIC

  );
  END COMPONENT;
  COMPONENT ISSP IS
  
  PORT (
    source : out std_logic_vector(7 downto 0);                      
    probe  : in  std_logic_vector(31 downto 0)  := (others => 'X') 

  );
  END COMPONENT;
  COMPONENT RGB2HSV_Filter IS
  
  PORT (
    CLK : IN STD_LOGIC;
    iPixel_R   : IN STD_LOGIC_VECTOR (7 downto 0);
    iPixel_G   : IN STD_LOGIC_VECTOR (7 downto 0);
    iPixel_B   : IN STD_LOGIC_VECTOR (7 downto 0);
    oPixel_H     : OUT STD_LOGIC_VECTOR (7 downto 0);
    oPixel_S     : OUT STD_LOGIC_VECTOR (7 downto 0);
    oPixel_V     : OUT STD_LOGIC_VECTOR (7 downto 0)

  );
  END COMPONENT;
  COMPONENT Color_Threshold_HSV_Filter IS
  
  PORT (
    CLK : IN STD_LOGIC;
    H_Min : IN NATURAL := 0;   
    H_Max : IN NATURAL := 180; 
    S_Min : IN NATURAL := 0;   
    S_Max : IN NATURAL := 255; 
    V_Min : IN NATURAL := 0;   
    V_Max : IN NATURAL := 255; 
    Relace : IN STD_LOGIC_VECTOR(23 downto 0) := (others => '0');
    iPixel_R   : IN STD_LOGIC_VECTOR (7 downto 0);
    iPixel_G   : IN STD_LOGIC_VECTOR (7 downto 0);
    iPixel_B   : IN STD_LOGIC_VECTOR (7 downto 0);
    iHSV_H     : IN STD_LOGIC_VECTOR (7 downto 0);
    iHSV_S     : IN STD_LOGIC_VECTOR (7 downto 0);
    iHSV_V     : IN STD_LOGIC_VECTOR (7 downto 0);
    oPixel_R   : OUT STD_LOGIC_VECTOR (7 downto 0);
    oPixel_G   : OUT STD_LOGIC_VECTOR (7 downto 0);
    oPixel_B   : OUT STD_LOGIC_VECTOR (7 downto 0)

  );
  END COMPONENT;
  COMPONENT PLL IS
  
  PORT (
    inclk0		: IN STD_LOGIC  := '0';
		    c0		: OUT STD_LOGIC 
	
  );
  END COMPONENT;
  COMPONENT blob_detection IS
  GENERIC (
      LINE_SIZE : natural := 640
  );
  PORT (
    clk : in std_logic; 
            resetn: in std_logic; 
            pixel_in_clk,pixel_in_hsync,pixel_in_vsync : in std_logic;
            pixel_in_data : in std_logic_vector(7 downto 0 );
            blob_data : out std_logic_vector(7 downto 0);
        
        
            mem_addr : out std_logic_vector(15 downto 0);
            mem_data : inout std_logic_vector(15 downto 0);
            mem_wr : out std_logic
        
  );
  END COMPONENT;
  COMPONENT Draw_Square IS
  GENERIC (
      Width : NATURAL := 4;
    Color : STD_LOGIC_VECTOR(23 downto 0) := x"FF0000" 

  );
  PORT (
    CLK : IN STD_LOGIC;
    Square_X0  : IN NATURAL range 0 to 639;
    Square_X1  : IN NATURAL range 0 to 639;
    Square_Y0  : IN NATURAL range 0 to 479;
    Square_Y1  : IN NATURAL range 0 to 479;
    iColumn    : IN NATURAL range 0 to 639;
    iRow       : IN NATURAL range 0 to 479;
    iPixel_R   : IN STD_LOGIC_VECTOR (7 downto 0);
    iPixel_G   : IN STD_LOGIC_VECTOR (7 downto 0);
    iPixel_B   : IN STD_LOGIC_VECTOR (7 downto 0);
    oPixel_R   : OUT STD_LOGIC_VECTOR (7 downto 0);
    oPixel_G   : OUT STD_LOGIC_VECTOR (7 downto 0);
    oPixel_B   : OUT STD_LOGIC_VECTOR (7 downto 0)

  );
  END COMPONENT;
  COMPONENT Camera_Capture IS
  GENERIC (
      Compression : NATURAL := 3;  
    Width       : NATURAL := 4  

  );
  PORT (
    CLK : IN STD_LOGIC;
    New_Pixel   : IN     STD_LOGIC := '0';
    Column      : IN     NATURAL range 0 to 639 := 0;
    Row         : IN     NATURAL range 0 to 479 := 0;
    Pixel_R     : IN     STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
    Pixel_G     : IN     STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
    Pixel_B     : IN     STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
    Read_Column : IN     NATURAL range 0 to 639 := 0;
    Read_Row    : IN     NATURAL range 0 to 479 := 0;
    Read_Data   : OUT    STD_LOGIC_VECTOR(23 downto 0) := (others => '0')

  );
  END COMPONENT;
  COMPONENT CRT_Controller IS
  GENERIC (
      image_size_div : NATURAL := 1

  );
  PORT (
    CLK : IN STD_LOGIC;
    Read_Column : OUT    NATURAL range 0 to 639 := 0;
    Read_Row    : OUT    NATURAL range 0 to 479 := 0;
    Read_Data   : IN     STD_LOGIC_VECTOR(23 downto 0) := (others => '0');
    Read_Ena    : OUT    STD_LOGIC := '0';
    VS_PCLK    : OUT    STD_LOGIC;
    VS_SCLK    : OUT    STD_LOGIC;
    VS_R       : OUT    STD_LOGIC_VECTOR (7 downto 0);
    VS_G       : OUT    STD_LOGIC_VECTOR (7 downto 0);
    VS_B       : OUT    STD_LOGIC_VECTOR (7 downto 0);
    VS_HS      : OUT    STD_LOGIC;
    VS_VS      : OUT    STD_LOGIC;
    VS_DE      : OUT    STD_LOGIC

  );
  END COMPONENT;
  COMPONENT HDMI_Out IS
  
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
  END COMPONENT;
  
BEGIN

  Camera_Enable <= '1';
  Color_Correction_Filter_oPixel_R <= Camera_Pixel_R;
  Color_Correction_Filter_oPixel_G <= Camera_Pixel_G;
  Color_Correction_Filter_oPixel_B <= Camera_Pixel_B;
  Camera_Capture_iPixel_R <= Camera_Pixel_R when ISSP_source = x"00" else
  Color_Correction_Filter_oPixel_R          when ISSP_source = x"01" else
  Square_oPixel_R(16)                        when ISSP_source = x"02" else
  Color_Threshold_Filter_iHSV_H             when ISSP_source = x"03" else
  Yellow_Filter_oPixel_R                    when ISSP_source = x"04" else
  Yellow_Filter_oPixel_R                    when ISSP_source = x"05" else
  Black_Filter_oPixel_R                     when ISSP_source = x"06" else
  Black_Filter_oPixel_R                     when ISSP_source = x"07" else
  Blue_Filter_oPixel_R                      when ISSP_source = x"08" else
  Blue_Filter_oPixel_R                      when ISSP_source = x"09" else
  White_Filter_oPixel_R                     when ISSP_source = x"0A" else
  White_Filter_oPixel_R;
  Camera_Capture_iPixel_G <= Camera_Pixel_G when ISSP_source = x"00" else
  Color_Correction_Filter_oPixel_G          when ISSP_source = x"01" else
  Square_oPixel_G(16)                        when ISSP_source = x"02" else
  Color_Threshold_Filter_iHSV_H             when ISSP_source = x"03" else
  Yellow_Filter_oPixel_G                    when ISSP_source = x"04" else
  Yellow_Filter_oPixel_G                    when ISSP_source = x"05" else
  Black_Filter_oPixel_G                     when ISSP_source = x"06" else
  Black_Filter_oPixel_G                     when ISSP_source = x"07" else
  Blue_Filter_oPixel_G                      when ISSP_source = x"08" else
  Blue_Filter_oPixel_G                      when ISSP_source = x"09" else
  White_Filter_oPixel_G                     when ISSP_source = x"0A" else
  White_Filter_oPixel_G;
  Camera_Capture_iPixel_B <= Camera_Pixel_B when ISSP_source = x"00" else
  Color_Correction_Filter_oPixel_B          when ISSP_source = x"01" else
  Square_oPixel_B(16)                        when ISSP_source = x"02" else
  Color_Threshold_Filter_iHSV_H             when ISSP_source = x"03" else
  Yellow_Filter_oPixel_B                    when ISSP_source = x"04" else
  Yellow_Filter_oPixel_B                    when ISSP_source = x"05" else
  Black_Filter_oPixel_B                     when ISSP_source = x"06" else
  Black_Filter_oPixel_B                     when ISSP_source = x"07" else
  Blue_Filter_oPixel_B                      when ISSP_source = x"08" else
  Blue_Filter_oPixel_B                      when ISSP_source = x"09" else
  White_Filter_oPixel_B                     when ISSP_source = x"0A" else
  White_Filter_oPixel_B;
  Color_Threshold_Filter_iPixel_X <= Color_Threshold_Filter_iHSV_H when (ISSP_source = x"04" OR ISSP_source = x"06" OR ISSP_source = x"08" OR ISSP_source = x"0A") AND
  (TO_INTEGER(UNSIGNED(Color_Threshold_Filter_iHSV_H)) < 30 OR TO_INTEGER(UNSIGNED(Color_Threshold_Filter_iHSV_H)) > 150)
  else (others => '0') when (ISSP_source = x"04" OR ISSP_source = x"06" OR ISSP_source = x"08" OR ISSP_source = x"0A")
  else Color_Correction_Filter_oPixel_R;
  Color_Threshold_Filter_iPixel_Y <= Color_Threshold_Filter_iHSV_H when (ISSP_source = x"04" OR ISSP_source = x"06" OR ISSP_source = x"08" OR ISSP_source = x"0A") AND
  (TO_INTEGER(UNSIGNED(Color_Threshold_Filter_iHSV_H)) >= 30 OR TO_INTEGER(UNSIGNED(Color_Threshold_Filter_iHSV_H)) < 90)
  else (others => '0') when (ISSP_source = x"04" OR ISSP_source = x"06" OR ISSP_source = x"08" OR ISSP_source = x"0A")
  else Color_Correction_Filter_oPixel_G;
  Color_Threshold_Filter_iPixel_Z <= Color_Threshold_Filter_iHSV_H when (ISSP_source = x"04" OR ISSP_source = x"06" OR ISSP_source = x"08" OR ISSP_source = x"0A") AND
  (TO_INTEGER(UNSIGNED(Color_Threshold_Filter_iHSV_H)) >= 90 OR TO_INTEGER(UNSIGNED(Color_Threshold_Filter_iHSV_H)) <= 150)
  else (others => '0') when (ISSP_source = x"04" OR ISSP_source = x"06" OR ISSP_source = x"08" OR ISSP_source = x"0A")
  else Color_Correction_Filter_oPixel_B;


  hsync <= '1' when Camera_Column = 0 else '0';
  vsync <= '1' when Camera_Row = 0 else '0';

  blob_in <= (TO_INTEGER(UNSIGNED(Yellow_Filter_oPixel_R)) + TO_INTEGER(UNSIGNED(Yellow_Filter_oPixel_G)) + TO_INTEGER(UNSIGNED(Yellow_Filter_oPixel_B)))/3 when ISSP2_source = x"00" else
  (TO_INTEGER(UNSIGNED(Black_Filter_oPixel_R)) + TO_INTEGER(UNSIGNED(Black_Filter_oPixel_G)) + TO_INTEGER(UNSIGNED(Black_Filter_oPixel_B)))/3 when ISSP2_source = x"01" else
  (TO_INTEGER(UNSIGNED(Blue_Filter_oPixel_R)) + TO_INTEGER(UNSIGNED(Blue_Filter_oPixel_G)) + TO_INTEGER(UNSIGNED(Blue_Filter_oPixel_B)))/3 when ISSP2_source = x"02" else
  (TO_INTEGER(UNSIGNED(White_Filter_oPixel_R)) + TO_INTEGER(UNSIGNED(White_Filter_oPixel_G)) + TO_INTEGER(UNSIGNED(White_Filter_oPixel_B)))/3;
  Square_oPixel_R(0) <= Color_Correction_Filter_oPixel_R;
  Square_oPixel_G(0) <= Color_Correction_Filter_oPixel_G;
  Square_oPixel_B(0) <= Color_Correction_Filter_oPixel_B;
  CSI_Camera1 : CSI_Camera
  GENERIC MAP (
      CLK_Frequency => 48000000

  ) PORT MAP (
    CLK => CLK,
    Reset         => '0',
    CLK_Lane      => Camera_CLK_Lane,
    Data_Lane     => Camera_Data_Lane,
    SCL           => Camera_SCL,
    SDA           => Camera_SDA,
    Pixel_R       => Camera_Pixel_R,
    Pixel_G       => Camera_Pixel_G,
    Pixel_B       => Camera_Pixel_B,
    Column        => Camera_Column,
    Row           => Camera_Row,
    New_Pixel     => Camera_New_Pixel

    
  );
  ISSP1 : ISSP  PORT MAP (
    source => ISSP1_source,
    probe  => ISSP1_probe

    
  );
  ISSP2 : ISSP  PORT MAP (
    source => ISSP2_source,
    probe  => ISSP2_probe

    
  );
  RGB2HSV_Filter1 : RGB2HSV_Filter  PORT MAP (
    CLK => CLK,
    iPixel_R => Color_Correction_Filter_oPixel_R,
    iPixel_G => Color_Correction_Filter_oPixel_G,
    iPixel_B => Color_Correction_Filter_oPixel_B,
    oPixel_H => Color_Threshold_Filter_iHSV_H,
    oPixel_S => Color_Threshold_Filter_iHSV_S,
    oPixel_V => Color_Threshold_Filter_iHSV_V

    
  );
  Color_Threshold_HSV_Filter1 : Color_Threshold_HSV_Filter  PORT MAP (
    CLK => CLK,
    H_Min      => 0,
    H_Max      => 255,
    S_Min      => 220, 
    S_Max      => 255, 
    V_Min      => 30, 
    V_Max      => 255, 
    iPixel_R   => Color_Threshold_Filter_iPixel_X,
    iPixel_G   => Color_Threshold_Filter_iPixel_Y,
    iPixel_B   => Color_Threshold_Filter_iPixel_Z,
    iHSV_H     => Color_Threshold_Filter_iHSV_H,
    iHSV_S     => Color_Threshold_Filter_iHSV_S,
    iHSV_V     => Color_Threshold_Filter_iHSV_V,
    oPixel_R   => Yellow_Filter_oPixel_R,
    oPixel_G   => Yellow_Filter_oPixel_G,
    oPixel_B   => Yellow_Filter_oPixel_B

    
  );
  Color_Threshold_HSV_Filter2 : Color_Threshold_HSV_Filter  PORT MAP (
    CLK => CLK,
    H_Min      => 0,
    H_Max      => 255,
    S_Min      => 0,
    S_Max      => 255,
    V_Min      => 0,
    V_Max      => 30,
    Relace     => (others => '1'),
    iPixel_R   => Color_Threshold_Filter_iPixel_X,
    iPixel_G   => Color_Threshold_Filter_iPixel_Y,
    iPixel_B   => Color_Threshold_Filter_iPixel_Z,
    iHSV_H     => Color_Threshold_Filter_iHSV_H,
    iHSV_S     => Color_Threshold_Filter_iHSV_S,
    iHSV_V     => Color_Threshold_Filter_iHSV_V,
    oPixel_R   => Black_Filter_oPixel_R,
    oPixel_G   => Black_Filter_oPixel_G,
    oPixel_B   => Black_Filter_oPixel_B

    
  );
  Color_Threshold_HSV_Filter3 : Color_Threshold_HSV_Filter  PORT MAP (
    CLK => CLK,
    H_Min      => 70, 
    H_Max      => 100, 
    S_Min      => 50, 
    S_Max      => 255,
    V_Min      => 10,
    V_Max      => 255,
    Relace     => (others => '1'),
    iPixel_R   => Color_Threshold_Filter_iPixel_X,
    iPixel_G   => Color_Threshold_Filter_iPixel_Y,
    iPixel_B   => Color_Threshold_Filter_iPixel_Z,
    iHSV_H     => Color_Threshold_Filter_iHSV_H,
    iHSV_S     => Color_Threshold_Filter_iHSV_S,
    iHSV_V     => Color_Threshold_Filter_iHSV_V,
    oPixel_R   => Blue_Filter_oPixel_R,
    oPixel_G   => Blue_Filter_oPixel_G,
    oPixel_B   => Blue_Filter_oPixel_B

    
  );
  Color_Threshold_HSV_Filter4 : Color_Threshold_HSV_Filter  PORT MAP (
    CLK => CLK,
    H_Min      => 0,
    H_Max      => 255,
    S_Min      => 0,
    S_Max      => 130,
    V_Min      => 150,
    V_Max      => 255,
    iPixel_R   => Color_Threshold_Filter_iPixel_X,
    iPixel_G   => Color_Threshold_Filter_iPixel_Y,
    iPixel_B   => Color_Threshold_Filter_iPixel_Z,
    iHSV_H     => Color_Threshold_Filter_iHSV_H,
    iHSV_S     => Color_Threshold_Filter_iHSV_S,
    iHSV_V     => Color_Threshold_Filter_iHSV_V,
    oPixel_R   => White_Filter_oPixel_R,
    oPixel_G   => White_Filter_oPixel_G,
    oPixel_B   => White_Filter_oPixel_B

    
  );
  ISSP3 : ISSP  PORT MAP (
    source => ISSP_source,
    probe  => ISSP_probe

    
  );
  PLL1 : PLL  PORT MAP (
    inclk0 => CLK,
    c0     => CLK_150MHz

    
  );
  blob_detection1 : blob_detection
  GENERIC MAP (
      LINE_SIZE      => 640

  ) PORT MAP (
    clk            => CLK_150MHz,
    resetn         => '1',
    pixel_in_clk   => Camera_New_Pixel,
    pixel_in_hsync => hsync,
    pixel_in_vsync => vsync,
    pixel_in_data  => STD_LOGIC_VECTOR(TO_UNSIGNED(blob_in,8)),
    blob_data      => blob_detection_blob_data,
    mem_addr       => blob_detection_mem_addr,
    mem_data       => blob_detection_mem_data,
    mem_wr         => blob_detection_mem_wr

    
  );
  PROCESS (CLK_150MHz)
    VARIABLE wr_reg : STD_LOGIC;
    VARIABLE receive_cnt : NATURAL range 0 to 2 := 0;
    VARIABLE data_reg : STD_LOGIC_VECTOR(47 downto 0);
    VARIABLE blob_reg : blob_pos;
  BEGIN
    IF (rising_edge(CLK_150MHz)) THEN
      IF ((wr_reg = '0' AND blob_detection_mem_wr = '1') OR receive_cnt > 0) THEN
        data_reg(16*receive_cnt + 15 downto 16*receive_cnt) := blob_detection_mem_data;
        IF (receive_cnt < 2) THEN
          receive_cnt := receive_cnt + 1;
        ELSE
          ISSP_probe <= data_reg(31 downto 0);
          ISSP1_probe(15 downto 0) <= data_reg(47 downto 32);

          blob_reg.y0 := TO_INTEGER(UNSIGNED(data_reg(9 downto 0)));
          blob_reg.x0 := TO_INTEGER(UNSIGNED(data_reg(19 downto 10)));
          blob_reg.y1 := TO_INTEGER(UNSIGNED(data_reg(29 downto 20)));
          blob_reg.x1 := TO_INTEGER(UNSIGNED(data_reg(39 downto 30)));
          blob_buf(blobs_in_buf) <= blob_reg;
          blobs_in_buf <= blobs_in_buf + 1;
          receive_cnt := 0;
        END IF;
      END IF;
      wr_reg := blob_detection_mem_wr;
    END IF;
  END PROCESS;
  Generate1 : for i in 0 to 15 GENERATE
    Draw_Square1 : Draw_Square
  GENERIC MAP (
      Width     => 4,
      Color     => x"FF0000"

  ) PORT MAP (
      CLK => CLK,
      Square_X0 => blob_buf(i).X0,
      Square_X1 => blob_buf(i).X1,
      Square_Y0 => blob_buf(i).Y0,
      Square_Y1 => blob_buf(i).Y1,
      iColumn   => Camera_Row,
      iRow      => Camera_Column,
      iPixel_R  => Square_oPixel_R(i),
      iPixel_G  => Square_oPixel_G(i),
      iPixel_B  => Square_oPixel_B(i),
      oPixel_R  => Square_oPixel_R(i+1),
      oPixel_G  => Square_oPixel_G(i+1),
      oPixel_B  => Square_oPixel_B(i+1)

      
    );
  END GENERATE Generate1;
  Camera_Capture1 : Camera_Capture
  GENERIC MAP (
      Compression => 4,
    Width       => 4

  ) PORT MAP (
    CLK => CLK,
    New_Pixel   => Camera_New_Pixel,
    Column      => Camera_Column,
    Row         => Camera_Row,
    Pixel_R     => Camera_Capture_iPixel_R,
    Pixel_G     => Camera_Capture_iPixel_G,
    Pixel_B     => Camera_Capture_iPixel_B,
    Read_Column => Camera_Capture_Read_Column,
    Read_Row    => Camera_Capture_Read_Row,
    Read_Data   => Camera_Capture_Read_Data

    
  );
  CRT_Controller1 : CRT_Controller
  GENERIC MAP (
      image_size_div => 1

  ) PORT MAP (
    CLK => CLK,
    Read_Column => Camera_Capture_Read_Column,
    Read_Row    => Camera_Capture_Read_Row,
    Read_Data   => Camera_Capture_Read_Data,
    Read_Ena    => Camera_Capture_SDRAM_Read_Ena,
    VS_PCLK     => HDMI_Out_VS_PCLK,
    VS_SCLK     => HDMI_Out_VS_SCLK,
    VS_R        => HDMI_Out_VS_R,
    VS_G        => HDMI_Out_VS_G,
    VS_B        => HDMI_Out_VS_B,
    VS_HS       => HDMI_Out_VS_HS,
    VS_VS       => HDMI_Out_VS_VS,
    VS_DE       => HDMI_Out_VS_DE

    
  );
  HDMI_Out1 : HDMI_Out  PORT MAP (
    CLK => CLK,
    VS_PCLK    => HDMI_Out_VS_PCLK,
    VS_SCLK    => HDMI_Out_VS_SCLK,
    VS_R       => HDMI_Out_VS_R,
    VS_G       => HDMI_Out_VS_G,
    VS_B       => HDMI_Out_VS_B,
    VS_HS      => HDMI_Out_VS_HS,
    VS_VS      => HDMI_Out_VS_VS,
    VS_DE      => HDMI_Out_VS_DE,
    oHDMI_DATA => oHDMI_TX,
    oHDMI_CLK  => oHDMI_CLK,
    iHDMI_HPD  => iHDMI_HPD
  );
  
END BEHAVIORAL;
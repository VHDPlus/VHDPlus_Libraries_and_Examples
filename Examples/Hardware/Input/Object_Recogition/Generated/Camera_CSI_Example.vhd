  
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all; 
use work.Image_Data_Package.all;

      
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

  CONSTANT MAX_Area    : NATURAL := 6;
  CONSTANT MIN_Area    : NATURAL := 2;
  CONSTANT MAX_Area_O  : NATURAL := ((MAX_Area**2)/2)*1;
  CONSTANT Start_Row   : NATURAL := 100;
  CONSTANT blob_number : NATURAL := 32;
  CONSTANT capture_compression : NATURAL :=  1;
  CONSTANT Blob_Min_H  : NATURAL := 2;
  CONSTANT Blob_Min_W  : NATURAL := 2;
  CONSTANT Blob_Max_H  : NATURAL := 40;
  CONSTANT Blob_Max_W  : NATURAL := 80;
  CONSTANT RGB        : BOOLEAN := false;
  CONSTANT Full_Image : BOOLEAN := true;
  SIGNAL color_select : NATURAL range 0 to 3 := 2;
  SIGNAL cone_select : NATURAL range 0 to 1 := 1;
  SIGNAL Camera_Stream         : rgb_stream;
  SIGNAL Color_Correction_Filter_Stream     : rgb_stream;
  SIGNAL Compression_Filter_oStream    : rgb_stream;
  SIGNAL RGB2HSV_oHSV       : rgb_stream;
  SIGNAL RGB2HSV_iRGB       : rgb_stream;
  SIGNAL Color_Threshold_Filter_iHSV       : rgb_stream;
  SIGNAL Yellow_Filter_oStream             : rgb_stream;
  SIGNAL Black_Filter_oStream     : rgb_stream;
  SIGNAL Blue_Filter_oStream     : rgb_stream;
  SIGNAL White_Filter_oStream     : rgb_stream;
  SIGNAL Area_Compression_Pixel     : STD_LOGIC_VECTOR(3 downto 0);
  SIGNAL Area_Compression_New_Pixel : STD_LOGIC;
  SIGNAL Area_Compression_Column    : NATURAL range 0 to 639;
  SIGNAL Area_Compression_Row       : NATURAL range 0 to 479;
  SIGNAL Blob_Detect_Busy_Yellow            : STD_LOGIC;
  SIGNAL Blob_Detect_Blobs_Yellow           : NATURAL   range 0 to 64-1;
  SIGNAL Blob_Detect_Blob_Addr_Yellow       : NATURAL   range 0 to 64-1;
  SIGNAL Blob_Detect_Blob_X0_Yellow         : NATURAL   range 0 to 640-1;
  SIGNAL Blob_Detect_Blob_X1_Yellow         : NATURAL   range 0 to 640-1;
  SIGNAL Blob_Detect_Blob_Y0_Yellow         : NATURAL   range 0 to 480-1;
  SIGNAL Blob_Detect_Blob_Y1_Yellow         : NATURAL   range 0 to 480-1;
  SIGNAL Blob_Detect_Busy_Black            : STD_LOGIC;
  SIGNAL Blob_Detect_Blobs_Black           : NATURAL   range 0 to 64-1;
  SIGNAL Blob_Detect_Blob_Addr_Black       : NATURAL   range 0 to 64-1;
  SIGNAL Blob_Detect_Blob_X0_Black         : NATURAL   range 0 to 640-1;
  SIGNAL Blob_Detect_Blob_X1_Black         : NATURAL   range 0 to 640-1;
  SIGNAL Blob_Detect_Blob_Y0_Black         : NATURAL   range 0 to 480-1;
  SIGNAL Blob_Detect_Blob_Y1_Black         : NATURAL   range 0 to 480-1;
  SIGNAL Blob_Detect_Busy_Blue            : STD_LOGIC;
  SIGNAL Blob_Detect_Blobs_Blue           : NATURAL   range 0 to 64-1;
  SIGNAL Blob_Detect_Blob_Addr_Blue       : NATURAL   range 0 to 64-1;
  SIGNAL Blob_Detect_Blob_X0_Blue         : NATURAL   range 0 to 640-1;
  SIGNAL Blob_Detect_Blob_X1_Blue         : NATURAL   range 0 to 640-1;
  SIGNAL Blob_Detect_Blob_Y0_Blue         : NATURAL   range 0 to 480-1;
  SIGNAL Blob_Detect_Blob_Y1_Blue         : NATURAL   range 0 to 480-1;
  SIGNAL Blob_Detect_Busy_White            : STD_LOGIC;
  SIGNAL Blob_Detect_Blobs_White           : NATURAL   range 0 to 64-1;
  SIGNAL Blob_Detect_Blob_Addr_White       : NATURAL   range 0 to 64-1;
  SIGNAL Blob_Detect_Blob_X0_White         : NATURAL   range 0 to 640-1;
  SIGNAL Blob_Detect_Blob_X1_White         : NATURAL   range 0 to 640-1;
  SIGNAL Blob_Detect_Blob_Y0_White         : NATURAL   range 0 to 480-1;
  SIGNAL Blob_Detect_Blob_Y1_White         : NATURAL   range 0 to 480-1;
  SIGNAL Cone_Detection_oCones_Blue          : NATURAL   range 0 to 16;
  SIGNAL Cone_Detection_oCones_Addr_Blue     : NATURAL   range 0 to 16-1;
  SIGNAL Cone_Detection_oCones_X_Blue        : NATURAL   range 0 to 640-1;
  SIGNAL Cone_Detection_oCones_Y_Blue        : NATURAL   range 0 to 480-1;
  SIGNAL Cone_Detection_oCones_Yellow          : NATURAL   range 0 to 16;
  SIGNAL Cone_Detection_oCones_Addr_Yellow     : NATURAL   range 0 to 16-1;
  SIGNAL Cone_Detection_oCones_X_Yellow        : NATURAL   range 0 to 640-1;
  SIGNAL Cone_Detection_oCones_Y_Yellow        : NATURAL   range 0 to 480-1;
  SIGNAL Camera_Capture_iStream     : rgb_stream;
  SIGNAL ISSP_source  : std_logic_vector (7 downto 0) := "00000000";
  SIGNAL ISSP1_source : std_logic_vector (7 downto 0) := "01001000";
  SIGNAL ISSP2_source : std_logic_vector (7 downto 0) := "00010001";
  SIGNAL ISSP3_source : std_logic_vector (7 downto 0) := "01001000";
  SIGNAL ISSP4_source : std_logic_vector (7 downto 0) := "00010001";
  SIGNAL ISSP_probe   : std_logic_vector (31 downto 0);
  SIGNAL ISSP1_probe  : std_logic_vector (31 downto 0);
  SIGNAL ISSP2_probe  : std_logic_vector (31 downto 0);
  SIGNAL ISSP3_probe  : std_logic_vector (31 downto 0);
  SIGNAL ISSP4_probe  : std_logic_vector (31 downto 0);
  SIGNAL Cone_Detection_oCones_Out          : NATURAL   range 0 to 16;
  SIGNAL Cone_Detection_oCones_Addr_Out     : NATURAL   range 0 to 16-1;
  SIGNAL Cone_Detection_oCones_X_Out        : NATURAL   range 0 to 640-1;
  SIGNAL Cone_Detection_oCones_Y_Out        : NATURAL   range 0 to 480-1;
  SIGNAL Blob_Detect_Blobs_Out           : NATURAL   range 0 to 64-1;
  SIGNAL Blob_Detect_Blob_X0_Out         : NATURAL   range 0 to 640-1;
  SIGNAL Blob_Detect_Blob_X1_Out         : NATURAL   range 0 to 640-1;
  SIGNAL Blob_Detect_Blob_Y0_Out         : NATURAL   range 0 to 480-1;
  SIGNAL Blob_Detect_Blob_Y1_Out         : NATURAL   range 0 to 480-1;
  SIGNAL Square_iStream : rgb_stream;
  SIGNAL Square_oStream : rgb_stream;
  SIGNAL Camera_Capture_Read_Column    : NATURAL          range 0 to 639;
  SIGNAL Camera_Capture_Read_Row       : NATURAL          range 0 to 479;
  SIGNAL Camera_Capture_Read_Data      : STD_LOGIC_VECTOR (23 downto 0);
  SIGNAL Camera_Capture_SDRAM_Read_Ena : STD_LOGIC;
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
  COMPONENT Color_Correction_Filter IS
  GENERIC (
      CLK_Edge    : BOOLEAN := true 

  );
  PORT (
    CLK : IN STD_LOGIC;
    R_Multiplier : IN NATURAL range 0 to 15 := 1;
    R_Divider    : IN NATURAL range 0 to 15 := 1;
    R_Add        : IN INTEGER range -64 to 63 := 0;
    G_Multiplier : IN NATURAL range 0 to 15 := 1;
    G_Divider    : IN NATURAL range 0 to 15 := 1;
    G_Add        : IN INTEGER range -64 to 63 := 0;
    B_Multiplier : IN NATURAL range 0 to 15 := 1;
    B_Divider    : IN NATURAL range 0 to 15 := 1;
    B_Add        : IN INTEGER range -64 to 63 := 0;
    iStream      : in   rgb_stream;
    oStream      : out  rgb_stream

  );
  END COMPONENT;
  COMPONENT RGB2HSV_Filter IS
  GENERIC (
      CLK_Edge    : BOOLEAN := true 

  );
  PORT (
    CLK : IN STD_LOGIC;
    iStream    : in   rgb_stream;
    oStream    : out  rgb_stream

  );
  END COMPONENT;
  COMPONENT Color_Threshold_HSV_Filter IS
  GENERIC (
      CLK_Edge    : BOOLEAN := true 

  );
  PORT (
    CLK : IN STD_LOGIC;
    H_Min : IN NATURAL := 0;   
    H_Max : IN NATURAL := 180; 
    S_Min : IN NATURAL := 0;   
    S_Max : IN NATURAL := 255; 
    V_Min : IN NATURAL := 0;   
    V_Max : IN NATURAL := 255; 
    iStream    : in   rgb_stream;
    oStream    : out  rgb_stream

  );
  END COMPONENT;
  COMPONENT AreaLimitedCompression IS
  GENERIC (
      Image_Width : NATURAL := 640;
    Image_Height: NATURAL := 480;
    MAX_Area_O  : NATURAL := 4;  
    MAX_Area    : NATURAL range 1 to 24 := 10; 
    MIN_Area    : NATURAL range 1 to 24 := 1;
    Colors      : NATURAL := 1;
    Start_Row   : NATURAL := 0;
    CLK_Edge    : BOOLEAN := true 

  );
  PORT (
    CLK : IN STD_LOGIC;
    iPixel     : IN STD_LOGIC_VECTOR(Colors-1 downto 0);
    iColumn    : IN NATURAL range 0 to Image_Width-1;
    iRow       : IN NATURAL range 0 to Image_Height-1;
    iNew_Pixel : IN STD_LOGIC;
    oPixel     : OUT STD_LOGIC_VECTOR(Colors-1 downto 0);
    oColumn    : OUT NATURAL range 0 to Image_Width-1;
    oRow       : OUT NATURAL range 0 to Image_Height-1;
    oNew_Pixel : OUT STD_LOGIC

  );
  END COMPONENT;
  COMPONENT Blob_Detect IS
  GENERIC (
      Blob_Number     : NATURAL := 32;
    Blob_Buffer     : NATURAL := 8;
    Width           : NATURAL := 640;
    Height          : NATURAL := 480;
    Min_Blob_Width  : NATURAL := 4;
    Min_Blob_Height : NATURAL := 2;
    Max_Blob_Width  : NATURAL := 20;
    Max_Blob_Height : NATURAL := 15;
    Upscale_Mult    : NATURAL := 4;
    Upscale_Start   : NATURAL := 100 

  );
  PORT (
    CLK : IN STD_LOGIC;
    New_Pixel : IN STD_LOGIC;
    Pixel_In  : IN STD_LOGIC; 
    Column    : IN NATURAL range 0 to 639;
    Row       : IN NATURAL range 0 to 479;
    Blob_Busy : OUT STD_LOGIC := '0';
    Blobs     : BUFFER NATURAL range 0 to Blob_Number-1;
    Blob_Addr : IN  NATURAL range 0 to Blob_Number-1;
    Blob_X0   : OUT NATURAL range 0 to Width-1;
    Blob_X1   : OUT NATURAL range 0 to Width-1;
    Blob_Y0   : OUT NATURAL range 0 to Height-1;
    Blob_Y1   : OUT NATURAL range 0 to Height-1

  );
  END COMPONENT;
  COMPONENT Cone_Detection IS
  GENERIC (
      Blob_Number     : NATURAL := 32;
    Cone_Number     : NATURAL := 16;
    Width           : NATURAL := 640;
    Height          : NATURAL := 480;
    Max_11Dist_Mult : NATURAL := 2;  
    Max_11Dist_Div  : NATURAL := 1;
    Max_12Dist_Mult : NATURAL := 1;  
    Max_12Dist_Div  : NATURAL := 1

  );
  PORT (
    CLK : IN STD_LOGIC;
    Blob_Busy_1  : IN STD_LOGIC;
    iBlobs_1     : IN NATURAL range 0 to Blob_Number-1;
    iBlob_Addr_1 : OUT  NATURAL range 0 to Blob_Number-1;
    iBlob_X0_1   : IN NATURAL range 0 to Width-1;
    iBlob_X1_1   : IN NATURAL range 0 to Width-1;
    iBlob_Y0_1   : IN NATURAL range 0 to Height-1;
    iBlob_Y1_1   : IN NATURAL range 0 to Height-1;
    Blob_Busy_2  : IN STD_LOGIC;
    iBlobs_2     : IN NATURAL range 0 to Blob_Number-1;
    iBlob_Addr_2 : OUT  NATURAL range 0 to Blob_Number-1;
    iBlob_X0_2   : IN NATURAL range 0 to Width-1;
    iBlob_X1_2   : IN NATURAL range 0 to Width-1;
    iBlob_Y0_2   : IN NATURAL range 0 to Height-1;
    iBlob_Y1_2   : IN NATURAL range 0 to Height-1;
    oCones       : OUT NATURAL range 0 to Cone_Number;
    oCones_Addr  : IN  NATURAL range 0 to Cone_Number-1;
    oCones_X     : OUT NATURAL range 0 to Width-1;
    oCones_Y     : OUT NATURAL range 0 to Height-1

  );
  END COMPONENT;
  COMPONENT ISSP IS
  
  PORT (
    source : out std_logic_vector(7 downto 0);                      
    probe  : in  std_logic_vector(31 downto 0)  := (others => 'X') 

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
    iStream    : in   rgb_stream;
    oStream    : out  rgb_stream

  );
  END COMPONENT;
  COMPONENT Camera_Capture IS
  GENERIC (
      Compression : NATURAL := 3;  
    Width       : NATURAL := 4;  
    Full_Image  : BOOLEAN := true; 
    RGB         : BOOLEAN := true;
    CLK_Edge    : BOOLEAN := true 

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

  Compression_Filter_oStream <= Color_Correction_Filter_Stream;


  RGB2HSV_iRGB <= Compression_Filter_oStream;

  Color_Threshold_Filter_iHSV  <= RGB2HSV_oHSV;
  Camera_Capture_iStream <= Square_iStream;




  Cone_Detection_oCones_Out <= Cone_Detection_oCones_Yellow when cone_select = 0 else Cone_Detection_oCones_Blue;
  Cone_Detection_oCones_Addr_Out <= Cone_Detection_oCones_Addr_Yellow when cone_select = 0 else Cone_Detection_oCones_Addr_Blue;
  Cone_Detection_oCones_X_Out <= Cone_Detection_oCones_X_Yellow when cone_select = 0 else Cone_Detection_oCones_X_Blue;
  Cone_Detection_oCones_Y_Out <= Cone_Detection_oCones_Y_Yellow when cone_select = 0 else Cone_Detection_oCones_Y_Blue;





  Square_iStream.R         <= (others => Area_Compression_Pixel(color_select));
  Square_iStream.G         <= (others => Area_Compression_Pixel(color_select));
  Square_iStream.B         <= (others => Area_Compression_Pixel(color_select));
  Square_iStream.Column    <= Area_Compression_Column;
  Square_iStream.Row       <= Area_Compression_Row;
  Square_iStream.New_Pixel <= Area_Compression_New_Pixel;
  Blob_Detect_Blobs_Out <= Blob_Detect_Blobs_Yellow when color_select = 0
  else Blob_Detect_Blobs_Black when color_select = 1
  else Blob_Detect_Blobs_Blue  when color_select = 2
  else Blob_Detect_Blobs_White;
  Blob_Detect_Blob_X0_Out <= Blob_Detect_Blob_X0_Yellow when color_select = 0
  else Blob_Detect_Blob_X0_Black when color_select = 1
  else Blob_Detect_Blob_X0_Blue  when color_select = 2
  else Blob_Detect_Blob_X0_White;
  Blob_Detect_Blob_X1_Out <= Blob_Detect_Blob_X1_Yellow when color_select = 0
  else Blob_Detect_Blob_X1_Black when color_select = 1
  else Blob_Detect_Blob_X1_Blue  when color_select = 2
  else Blob_Detect_Blob_X1_White;
  Blob_Detect_Blob_Y0_Out <= Blob_Detect_Blob_Y0_Yellow when color_select = 0
  else Blob_Detect_Blob_Y0_Black when color_select = 1
  else Blob_Detect_Blob_Y0_Blue  when color_select = 2
  else Blob_Detect_Blob_Y0_White;
  Blob_Detect_Blob_Y1_Out <= Blob_Detect_Blob_Y1_Yellow when color_select = 0
  else Blob_Detect_Blob_Y1_Black when color_select = 1
  else Blob_Detect_Blob_Y1_Blue  when color_select = 2
  else Blob_Detect_Blob_Y1_White;
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
    Pixel_R       => Camera_Stream.R,
    Pixel_G       => Camera_Stream.G,
    Pixel_B       => Camera_Stream.B,
    Column        => Camera_Stream.Column,
    Row           => Camera_Stream.Row,
    New_Pixel     => Camera_Stream.New_Pixel

    
  );
  Color_Correction_Filter1 : Color_Correction_Filter
  GENERIC MAP (
      CLK_Edge     => false

  ) PORT MAP (
    CLK => CLK,
    R_Multiplier => 1,
    R_Divider    => 1,
    R_Add        => 0,
    G_Multiplier => 3,
    G_Divider    => 5,
    G_Add        => 0,
    B_Multiplier => 1,
    B_Divider    => 1,
    B_Add        => 0,
    iStream      => Camera_Stream,
    oStream      => Color_Correction_Filter_Stream

    
  );
  RGB2HSV_Filter1 : RGB2HSV_Filter
  GENERIC MAP (
      CLK_Edge => true

  ) PORT MAP (
    CLK => CLK,
    iStream  => RGB2HSV_iRGB,
    oStream  => RGB2HSV_oHSV

    
  );
  Color_Threshold_HSV_Filter1 : Color_Threshold_HSV_Filter
  GENERIC MAP (
      CLK_Edge   => false

  ) PORT MAP (
    CLK => CLK,
    H_Min      => 170, 
    H_Max      => 40,  
    S_Min      => 100, 
    S_Max      => 255, 
    V_Min      => 60,  
    V_Max      => 255, 
    iStream    => Color_Threshold_Filter_iHSV,
    oStream    => Yellow_Filter_oStream

    
  );
  Color_Threshold_HSV_Filter2 : Color_Threshold_HSV_Filter
  GENERIC MAP (
      CLK_Edge   => false

  ) PORT MAP (
    CLK => CLK,
    H_Min      => 0,
    H_Max      => 255,
    S_Min      => 0,
    S_Max      => 255,
    V_Min      => 0,
    V_Max      => 40,
    iStream    => Color_Threshold_Filter_iHSV,
    oStream    => Black_Filter_oStream

    
  );
  Color_Threshold_HSV_Filter3 : Color_Threshold_HSV_Filter
  GENERIC MAP (
      CLK_Edge   => false

  ) PORT MAP (
    CLK => CLK,
    H_Min      => 105,
    H_Max      => 150,
    S_Min      => 120,
    S_Max      => 255,
    V_Min      => 60,
    V_Max      => 255,
    iStream    => Color_Threshold_Filter_iHSV,
    oStream    => Blue_Filter_oStream

    
  );
  Color_Threshold_HSV_Filter4 : Color_Threshold_HSV_Filter
  GENERIC MAP (
      CLK_Edge   => false

  ) PORT MAP (
    CLK => CLK,
    H_Min      => 0,
    H_Max      => 255,
    S_Min      => 0,
    S_Max      => 120,
    V_Min      => 150,
    V_Max      => 255,
    iStream    => Color_Threshold_Filter_iHSV,
    oStream    => White_Filter_oStream

    
  );
  AreaLimitedCompression1 : AreaLimitedCompression
  GENERIC MAP (
      Image_Width => 640,
    MAX_Area_O  => MAX_Area_O,  
    MAX_Area    => MAX_Area,
    MIN_Area    => MIN_Area,
    Start_Row   => Start_Row,
    Colors      => 4,
    CLK_Edge    => true

  ) PORT MAP (
    CLK => CLK,
    iNew_Pixel  => Yellow_Filter_oStream.New_Pixel,
    iColumn     => Yellow_Filter_oStream.Column,
    iRow        => Yellow_Filter_oStream.Row,
    iPixel(0)   => Yellow_Filter_oStream.R(0),
    iPixel(1)   => Black_Filter_oStream.R(0),
    iPixel(2)   => Blue_Filter_oStream.R(0),
    iPixel(3)   => White_Filter_oStream.R(0),
    oNew_Pixel  => Area_Compression_New_Pixel,
    oColumn     => Area_Compression_Column,
    oRow        => Area_Compression_Row,
    oPixel      => Area_Compression_Pixel

    
  );
  Blob_Detect1 : Blob_Detect
  GENERIC MAP (
      Blob_Number     => blob_number,
    Blob_Buffer     => 8,
    Width           => 640,
    Height          => 480,
    Min_Blob_Width  => Blob_Min_W,
    Min_Blob_Height => Blob_Min_H,
    Max_Blob_Width  => Blob_Max_W,
    Max_Blob_Height => Blob_Max_H,
    Upscale_Mult    => MAX_Area/MIN_Area,
    Upscale_Start   => Start_Row

  ) PORT MAP (
    CLK => CLK,
    New_Pixel       => Area_Compression_New_Pixel,
    Pixel_In        => Area_Compression_Pixel(0),
    Column          => Area_Compression_Column,
    Row             => Area_Compression_Row,
    Blob_Busy       => Blob_Detect_Busy_Yellow,
    Blobs           => Blob_Detect_Blobs_Yellow,
    Blob_Addr       => Blob_Detect_Blob_Addr_Yellow,
    Blob_X0         => Blob_Detect_Blob_X0_Yellow,
    Blob_X1         => Blob_Detect_Blob_X1_Yellow,
    Blob_Y0         => Blob_Detect_Blob_Y0_Yellow,
    Blob_Y1         => Blob_Detect_Blob_Y1_Yellow

    
  );
  Blob_Detect2 : Blob_Detect
  GENERIC MAP (
      Blob_Number     => blob_number,
    Blob_Buffer     => 8,
    Width           => 640,
    Height          => 480,
    Min_Blob_Width  => Blob_Min_W,
    Min_Blob_Height => Blob_Min_H,
    Max_Blob_Width  => Blob_Max_W,
    Max_Blob_Height => Blob_Max_H,
    Upscale_Mult    => MAX_Area/MIN_Area,
    Upscale_Start   => Start_Row

  ) PORT MAP (
    CLK => CLK,
    New_Pixel       => Area_Compression_New_Pixel,
    Pixel_In        => Area_Compression_Pixel(1),
    Column          => Area_Compression_Column,
    Row             => Area_Compression_Row,
    Blob_Busy       => Blob_Detect_Busy_Black,
    Blobs           => Blob_Detect_Blobs_Black,
    Blob_Addr       => Blob_Detect_Blob_Addr_Black,
    Blob_X0         => Blob_Detect_Blob_X0_Black,
    Blob_X1         => Blob_Detect_Blob_X1_Black,
    Blob_Y0         => Blob_Detect_Blob_Y0_Black,
    Blob_Y1         => Blob_Detect_Blob_Y1_Black

    
  );
  Blob_Detect3 : Blob_Detect
  GENERIC MAP (
      Blob_Number     => blob_number,
    Blob_Buffer     => 8,
    Width           => 640,
    Height          => 480,
    Min_Blob_Width  => Blob_Min_W,
    Min_Blob_Height => Blob_Min_H,
    Max_Blob_Width  => Blob_Max_W,
    Max_Blob_Height => Blob_Max_H,
    Upscale_Mult    => MAX_Area/MIN_Area,
    Upscale_Start   => Start_Row

  ) PORT MAP (
    CLK => CLK,
    New_Pixel       => Area_Compression_New_Pixel,
    Pixel_In        => Area_Compression_Pixel(2),
    Column          => Area_Compression_Column,
    Row             => Area_Compression_Row,
    Blob_Busy       => Blob_Detect_Busy_Blue,
    Blobs           => Blob_Detect_Blobs_Blue,
    Blob_Addr       => Blob_Detect_Blob_Addr_Blue,
    Blob_X0         => Blob_Detect_Blob_X0_Blue,
    Blob_X1         => Blob_Detect_Blob_X1_Blue,
    Blob_Y0         => Blob_Detect_Blob_Y0_Blue,
    Blob_Y1         => Blob_Detect_Blob_Y1_Blue

    
  );
  Blob_Detect4 : Blob_Detect
  GENERIC MAP (
      Blob_Number     => blob_number,
    Blob_Buffer     => 8,
    Width           => 640,
    Height          => 480,
    Min_Blob_Width  => Blob_Min_W,
    Min_Blob_Height => Blob_Min_H,
    Max_Blob_Width  => Blob_Max_W,
    Max_Blob_Height => Blob_Max_H,
    Upscale_Mult    => MAX_Area/MIN_Area,
    Upscale_Start   => Start_Row

  ) PORT MAP (
    CLK => CLK,
    New_Pixel       => Area_Compression_New_Pixel,
    Pixel_In        => Area_Compression_Pixel(3),
    Column          => Area_Compression_Column,
    Row             => Area_Compression_Row,
    Blob_Busy       => Blob_Detect_Busy_White,
    Blobs           => Blob_Detect_Blobs_White,
    Blob_Addr       => Blob_Detect_Blob_Addr_White,
    Blob_X0         => Blob_Detect_Blob_X0_White,
    Blob_X1         => Blob_Detect_Blob_X1_White,
    Blob_Y0         => Blob_Detect_Blob_Y0_White,
    Blob_Y1         => Blob_Detect_Blob_Y1_White

    
  );
  Cone_Detection1 : Cone_Detection
  GENERIC MAP (
      Blob_Number     => 32,
    Cone_Number     => 16,
    Width           => 640,
    Height          => 480,
    Max_11Dist_Mult => 2,
    Max_11Dist_Div  => 1,
    Max_12Dist_Mult => 1,
    Max_12Dist_Div  => 1

  ) PORT MAP (
    CLK => CLK,
    Blob_Busy_1     => Blob_Detect_Busy_Blue,
    iBlobs_1        => Blob_Detect_Blobs_Blue,
    iBlob_Addr_1    => Blob_Detect_Blob_Addr_Blue,
    iBlob_X0_1      => Blob_Detect_Blob_X0_Blue,
    iBlob_X1_1      => Blob_Detect_Blob_X1_Blue,
    iBlob_Y0_1      => Blob_Detect_Blob_Y0_Blue,
    iBlob_Y1_1      => Blob_Detect_Blob_Y1_Blue,
    Blob_Busy_2     => Blob_Detect_Busy_White,
    iBlobs_2        => Blob_Detect_Blobs_White,
    iBlob_Addr_2    => Blob_Detect_Blob_Addr_White,
    iBlob_X0_2      => Blob_Detect_Blob_X0_White,
    iBlob_X1_2      => Blob_Detect_Blob_X1_White,
    iBlob_Y0_2      => Blob_Detect_Blob_Y0_White,
    iBlob_Y1_2      => Blob_Detect_Blob_Y1_White,
    oCones          => Cone_Detection_oCones_Blue,
    oCones_Addr     => Cone_Detection_oCones_Addr_Blue,
    oCones_X        => Cone_Detection_oCones_X_Blue,
    oCones_Y        => Cone_Detection_oCones_Y_Blue

    
  );
  Cone_Detection2 : Cone_Detection
  GENERIC MAP (
      Blob_Number     => 32,
    Cone_Number     => 16,
    Width           => 640,
    Height          => 480,
    Max_11Dist_Mult => 2,
    Max_11Dist_Div  => 1,
    Max_12Dist_Mult => 1,
    Max_12Dist_Div  => 1

  ) PORT MAP (
    CLK => CLK,
    Blob_Busy_1     => Blob_Detect_Busy_Yellow,
    iBlobs_1        => Blob_Detect_Blobs_Yellow,
    iBlob_Addr_1    => Blob_Detect_Blob_Addr_Yellow,
    iBlob_X0_1      => Blob_Detect_Blob_X0_Yellow,
    iBlob_X1_1      => Blob_Detect_Blob_X1_Yellow,
    iBlob_Y0_1      => Blob_Detect_Blob_Y0_Yellow,
    iBlob_Y1_1      => Blob_Detect_Blob_Y1_Yellow,
    Blob_Busy_2     => Blob_Detect_Busy_Black,
    iBlobs_2        => Blob_Detect_Blobs_Black,
    iBlob_Addr_2    => Blob_Detect_Blob_Addr_Black,
    iBlob_X0_2      => Blob_Detect_Blob_X0_Black,
    iBlob_X1_2      => Blob_Detect_Blob_X1_Black,
    iBlob_Y0_2      => Blob_Detect_Blob_Y0_Black,
    iBlob_Y1_2      => Blob_Detect_Blob_Y1_Black,
    oCones          => Cone_Detection_oCones_Yellow,
    oCones_Addr     => Cone_Detection_oCones_Addr_Yellow,
    oCones_X        => Cone_Detection_oCones_X_Yellow,
    oCones_Y        => Cone_Detection_oCones_Y_Yellow

    
  );
  ISSP1 : ISSP  PORT MAP (
    source => ISSP_source,
    probe  => ISSP_probe

    
  );
  ISSP2 : ISSP  PORT MAP (
    source => ISSP1_source,
    probe  => ISSP1_probe

    
  );
  ISSP3 : ISSP  PORT MAP (
    source => ISSP2_source,
    probe  => ISSP2_probe

    
  );
  ISSP4 : ISSP  PORT MAP (
    source => ISSP3_source,
    probe  => ISSP3_probe

    
  );
  ISSP5 : ISSP  PORT MAP (
    source => ISSP4_source,
    probe  => ISSP4_probe

    
  );
  Draw_Square1 : Draw_Square
  GENERIC MAP (
      Width     => 8,
    Color     => x"FF0000"

  ) PORT MAP (
    CLK => CLK,
    Square_X0 => Blob_Detect_Blob_X0_Out,
    Square_X1 => Blob_Detect_Blob_X1_Out,
    Square_Y0 => Blob_Detect_Blob_Y0_Out,
    Square_Y1 => Blob_Detect_Blob_Y1_Out,
    iStream   => Square_iStream,
    oStream   => Square_oStream

    
  );
  Camera_Capture1 : Camera_Capture
  GENERIC MAP (
      Compression => capture_compression,
    Width       => 1,
    Full_Image  => Full_Image,
    RGB         => RGB,
    CLK_Edge    => false

  ) PORT MAP (
    CLK => CLK,
    New_Pixel   => Camera_Capture_iStream.New_Pixel,
    Column      => Camera_Capture_iStream.Column,
    Row         => Camera_Capture_iStream.Row,
    Pixel_R     => Camera_Capture_iStream.R,
    Pixel_G     => Camera_Capture_iStream.G,
    Pixel_B     => Camera_Capture_iStream.B,
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
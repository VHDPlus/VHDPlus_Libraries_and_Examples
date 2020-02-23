  
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all; 
use work.Image_Data_Package.all;


ENTITY Cone_Detection IS
  GENERIC (
      Blob_Number     : NATURAL := 32;
    Cone_Number     : NATURAL := 16;
    Max_11Dist_Mult : NATURAL := 2;  
    Max_11Dist_Div  : NATURAL := 1;
    Max_12Dist_Mult : NATURAL := 1;  
    Max_12Dist_Div  : NATURAL := 1

  );
PORT (
  CLK : IN STD_LOGIC;
  New_Pixel    : IN STD_LOGIC;
  Blob_Busy_1  : IN STD_LOGIC;
  iBlobs_1     : IN NATURAL range 0 to Blob_Number-1;
  iBlob_Addr_1 : OUT  NATURAL range 0 to Blob_Number-1;
  iBlob_X0_1   : IN NATURAL range 0 to Image_Width-1;
  iBlob_X1_1   : IN NATURAL range 0 to Image_Width-1;
  iBlob_Y0_1   : IN NATURAL range 0 to Image_Height-1;
  iBlob_Y1_1   : IN NATURAL range 0 to Image_Height-1;
  Blob_Busy_2  : IN STD_LOGIC;
  iBlobs_2     : IN NATURAL range 0 to Blob_Number-1;
  iBlob_Addr_2 : OUT  NATURAL range 0 to Blob_Number-1;
  iBlob_X0_2   : IN NATURAL range 0 to Image_Width-1;
  iBlob_X1_2   : IN NATURAL range 0 to Image_Width-1;
  iBlob_Y0_2   : IN NATURAL range 0 to Image_Height-1;
  iBlob_Y1_2   : IN NATURAL range 0 to Image_Height-1;
  oBusy        : OUT STD_LOGIC;
  oCones       : OUT NATURAL range 0 to Cone_Number;
  oCones_Addr  : IN  NATURAL range 0 to Cone_Number-1;
  oCones_X     : OUT NATURAL range 0 to Image_Width-1;
  oCones_Y     : OUT NATURAL range 0 to Image_Height-1

);
END Cone_Detection;

ARCHITECTURE BEHAVIORAL OF Cone_Detection IS

  CONSTANT Detect_Steps : NATURAL := 4;
  TYPE cone_type IS RECORD
  x : NATURAL range 0 to Image_Width-1;  
  y : NATURAL range 0 to Image_Height-1; 
  END RECORD cone_type;
  TYPE cones_type IS ARRAY (0 to Cone_Number-1) OF cone_type;
  SIGNAL cones_c : NATURAL range 0 to Cone_Number;
  FUNCTION log2 ( x : positive) RETURN  natural IS
    variable i : natural;
  BEGIN
    i := 0;
    WHILE 2**i < x and i < 31 LOOP
      i := i + 1;
    END LOOP;
  
    return i;
  END FUNCTION;
  SIGNAL blob_ram_data_in  : STD_LOGIC_VECTOR (17 downto 0);
  SIGNAL blob_ram_data_out : STD_LOGIC_VECTOR (17 downto 0);
  SIGNAL blob_ram_addr_in  : NATURAL range 0 to Cone_Number-1;
  SIGNAL ISSP1_probe  : std_logic_vector (31 downto 0);
  SIGNAL ISSP2_probe  : std_logic_vector (31 downto 0);
  SIGNAL ISSP3_probe  : std_logic_vector (31 downto 0);
  SIGNAL ISSP4_probe  : std_logic_vector (31 downto 0);
  COMPONENT ALTSYNCRAM IS
  GENERIC (
      address_aclr_a         : string := "UNUSED";
    address_aclr_b         : string := "NONE";
    address_reg_b          : string := "CLOCK1";
    byte_size              : natural := 8;
    byteena_aclr_a         : string := "UNUSED";
    byteena_aclr_b         : string := "NONE";
    byteena_reg_b          : string := "CLOCK1";
    clock_enable_core_a    : string := "USE_INPUT_CLKEN";
    clock_enable_core_b    : string := "USE_INPUT_CLKEN";
    clock_enable_input_a   : string := "NORMAL";
    clock_enable_input_b   : string := "NORMAL";
    clock_enable_output_a  : string := "NORMAL";
    clock_enable_output_b  : string := "NORMAL";
    intended_device_family : string := "MAX 10";
    enable_ecc             : string := "FALSE";
    implement_in_les       : string := "OFF";
    indata_aclr_a          : string := "UNUSED";
    indata_aclr_b          : string := "NONE";
    indata_reg_b           : string := "CLOCK1";
    init_file              : string := "UNUSED";
    init_file_layout       : string := "PORT_A";
    maximum_depth          : natural := 0;
    numwords_a             : natural := 0;
    numwords_b             : natural := 0;
    operation_mode         : string := "BIDIR_DUAL_PORT";
    outdata_aclr_a         : string := "NONE";
    outdata_aclr_b         : string := "NONE";
    outdata_reg_a          : string := "UNREGISTERED";
    outdata_reg_b          : string := "UNREGISTERED";
    power_up_uninitialized : string := "FALSE";
    ram_block_type         : string := "AUTO";
    rdcontrol_aclr_b       : string := "NONE";
    rdcontrol_reg_b        : string := "CLOCK1";
    read_during_write_mode_mixed_ports     : string := "DONT_CARE";
    read_during_write_mode_port_a          : string := "NEW_DATA_NO_NBE_READ";
    read_during_write_mode_port_b          : string := "NEW_DATA_NO_NBE_READ";
    width_a                : natural;
    width_b                : natural := 1;
    width_byteena_a        : natural := 1;
    width_byteena_b        : natural := 1;
    widthad_a              : natural;
    widthad_b              : natural := 1;
    wrcontrol_aclr_a       : string := "UNUSED";
    wrcontrol_aclr_b       : string := "NONE";
    wrcontrol_wraddress_reg_b              : string := "CLOCK1";
    lpm_hint               : string := "UNUSED";
    lpm_type               : string := "altsyncram"

  );
  PORT (
    aclr0          : in std_logic := '0';
    aclr1          : in std_logic := '0';
    address_a      : in std_logic_vector(widthad_a-1 downto 0);
    address_b      : in std_logic_vector(widthad_b-1 downto 0) := (others => '1');
    addressstall_a : in std_logic := '0';
    addressstall_b : in std_logic := '0';
    byteena_a      : in std_logic_vector(width_byteena_a-1 downto 0) := (others => '1');
    byteena_b      : in std_logic_vector(width_byteena_b-1 downto 0) := (others => '1');
    clock0         : in std_logic := '1';
    clock1         : in std_logic := '1';
    clocken0       : in std_logic := '1';
    clocken1       : in std_logic := '1';
    clocken2       : in std_logic := '1';
    clocken3       : in std_logic := '1';
    data_a         : in std_logic_vector(width_a-1 downto 0) := (others => '1');
    data_b         : in std_logic_vector(width_b-1 downto 0) := (others => '1');
    eccstatus      : out std_logic_vector(2 downto 0);
    q_a            : out std_logic_vector(width_a-1 downto 0);
    q_b            : out std_logic_vector(width_b-1 downto 0);
    rden_a         : in std_logic := '1';
    rden_b         : in std_logic := '1';
    wren_a         : in std_logic := '0';
    wren_b         : in std_logic := '0'

  );
  END COMPONENT;
  
BEGIN

  oCones <= cones_c;
  oCones_X <= TO_INTEGER(UNSIGNED(blob_ram_data_out(8 downto 0)))*2;
  oCones_Y <= TO_INTEGER(UNSIGNED(blob_ram_data_out(17 downto 9)));
  ALTSYNCRAM1 : ALTSYNCRAM
  GENERIC MAP (
      address_reg_b => "CLOCK0",
    clock_enable_input_a => "BYPASS",
    clock_enable_input_b => "BYPASS",
    clock_enable_output_b => "BYPASS",
    intended_device_family => "unused",
    numwords_a => Cone_Number,
    numwords_b => Cone_Number,
    operation_mode => "DUAL_PORT",
    outdata_reg_b => "CLOCK0",
    widthad_a => log2(Cone_Number),
    widthad_b => log2(Cone_Number),
    width_a => 18,
    width_b => 18,
    width_byteena_a => 1

  ) PORT MAP (
    address_a => STD_LOGIC_VECTOR(TO_UNSIGNED(blob_ram_addr_in,log2(Cone_Number))),
    address_b => STD_LOGIC_VECTOR(TO_UNSIGNED(oCones_Addr,log2(Cone_Number))),
    clock0 => New_Pixel,
    data_a => blob_ram_data_in,
    wren_a => '1',
    q_b => blob_ram_data_out
  );
  PROCESS (New_Pixel)
    VARIABLE run_combine : BOOLEAN := false;
    VARIABLE New_Image_Reg : STD_LOGIC;
    VARIABLE new_cone : cone_type;
    VARIABLE Cur_Blob_Addr1 : NATURAL range 0 to Blob_Number-1;
    VARIABLE Cur_Blob_Addr2 : NATURAL range 0 to Blob_Number-1;
    VARIABLE Cur_Blob1_Addr : NATURAL range 0 to Blob_Number-1;
    VARIABLE main_blob : BOOLEAN := false;
    VARIABLE Blob1_X0  : NATURAL range 0 to Image_Width-1;
    VARIABLE Blob1_X1  : NATURAL range 0 to Image_Width-1;
    VARIABLE Blob1_Y0  : NATURAL range 0 to Image_Height-1;
    VARIABLE Blob1_Y1  : NATURAL range 0 to Image_Height-1;
    VARIABLE Blob1_XC  : NATURAL range 0 to Image_Width-1;
    VARIABLE Blob1_Flp : BOOLEAN;
    VARIABLE Blob1_H   : NATURAL range 0 to Image_Height-1;
    VARIABLE Blob1_W   : NATURAL range 0 to Image_Width-1;
    VARIABLE Max_Dist2 : NATURAL range 0 to Image_Height-1;
    VARIABLE Max_Dist3 : NATURAL range 0 to Image_Height-1;
    VARIABLE match21 : NATURAL range 0 to Blob_Number**2;
    VARIABLE match22 : NATURAL range 0 to Blob_Number**2;
    VARIABLE match23 : NATURAL range 0 to Blob_Number**2;
    VARIABLE match24 : NATURAL range 0 to Blob_Number**2;
    VARIABLE match31 : NATURAL range 0 to Blob_Number**2;
    VARIABLE match32 : NATURAL range 0 to Blob_Number**2;
    VARIABLE match33 : NATURAL range 0 to Blob_Number**2;
    VARIABLE match34 : NATURAL range 0 to Blob_Number**2;
    VARIABLE found : BOOLEAN := false;
    VARIABLE Blob3_XC  : NATURAL range 0 to Image_Width-1;
    VARIABLE Dist3 : NATURAL range 0 to Image_Height+Image_Width;
    VARIABLE Blob3_W   : NATURAL range 0 to Image_Width-1;
    VARIABLE Blob3_Flp : BOOLEAN;
    VARIABLE Blob2_XC  : NATURAL range 0 to Image_Width-1;
    VARIABLE Dist2 : NATURAL range 0 to Image_Height-1;
    VARIABLE Blob2_W   : NATURAL range 0 to Image_Width-1;
    VARIABLE Blob2_Flp : BOOLEAN;
    VARIABLE Thread15 : NATURAL range 0 to 4 := 0;
    VARIABLE Thread18 : NATURAL range 0 to 12 := 0;
  BEGIN
    IF (rising_edge(New_Pixel)) THEN
      IF ((Blob_Busy_1 OR Blob_Busy_2) = '0' AND New_Image_Reg = '1') THEN
        run_combine := true;
        cones_c     <= 0;
        match21 := 0;
        match22 := 0;
        match23 := 0;
        match24 := 0;
        match31 := 0;
        match32 := 0;
        match33 := 0;
        match34 := 0;
      
      END IF;
      New_Image_Reg := (Blob_Busy_1 OR Blob_Busy_2);
      IF (run_combine) THEN
        oBusy <= '1';
      ELSE
        oBusy <= '0';
      END IF;
      ISSP1_probe <= STD_LOGIC_VECTOR(TO_UNSIGNED(match31, 32));
      ISSP2_probe <= STD_LOGIC_VECTOR(TO_UNSIGNED(match32, 32));
      ISSP3_probe <= STD_LOGIC_VECTOR(TO_UNSIGNED(match33, 32));
      ISSP4_probe <= STD_LOGIC_VECTOR(TO_UNSIGNED(match34, 32));
      IF (run_combine) THEN
        iBlob_Addr_2 <= Cur_Blob_Addr2;
        IF (main_blob) THEN
          iBlob_Addr_1 <= Cur_Blob1_Addr;
        ELSE
          iBlob_Addr_1 <= Cur_Blob_Addr1;
        END IF;
        CASE (Thread15) IS
          WHEN 0 =>
            Cur_Blob1_Addr := 0;
            Thread15 := 1;
          WHEN 1 =>
            IF ( Cur_Blob1_Addr < iBlobs_1) THEN 
              Thread15 := Thread15 + 1;
            ELSE
              Thread15 := Thread15 + 2;
            END IF;
          WHEN (1+1) =>
            CASE (Thread18) IS
              WHEN 0 =>
                main_blob := true;
                iBlob_Addr_1 <= Cur_Blob1_Addr;
                Thread18 := 1;
              WHEN 1 to 2 =>
                Thread18 := Thread18 + 1;
              WHEN 3 =>
                main_blob := false;
                Blob1_X0 := iBlob_X0_1;
                Blob1_X1 := iBlob_X1_1;
                Blob1_Y0 := iBlob_Y0_1;
                Blob1_Y1 := iBlob_Y1_1;
                Blob1_XC := (Blob1_X1+Blob1_X0)/2;
                Thread18 := 4;
              WHEN 4 =>
                IF (Blob1_Y1 - Blob1_Y0 < Blob1_X1 - Blob1_X0) THEN 
                  Blob1_Flp := false;
                Blob1_H := Blob1_Y1 - Blob1_Y0;
                Blob1_W := Blob1_X1 - Blob1_X0;
                ELSE
                  Blob1_Flp := true;
                Blob1_H := Blob1_X1 - Blob1_X0;
                Blob1_W := Blob1_Y1 - Blob1_Y0;
                END IF;
                Thread18 := 5;

              Thread18 := 5;
              WHEN 5 =>
                Max_Dist2 := (Blob1_H * Max_12Dist_Mult) / Max_12Dist_Div;
                Max_Dist3 := (Blob1_H * Max_11Dist_Mult) / Max_11Dist_Div;

                found := false;
                Thread18 := 6;
              WHEN 6 =>
                IF ( Cur_Blob_Addr1 < iBlobs_1 AND NOT found) THEN
                  IF (Blob1_Y1 > iBlob_Y1_1 OR Detect_Steps < 1) THEN
                    match31 := match31 + 1;

                    Blob3_XC := (iBlob_X1_1+iBlob_X0_1)/2;

                    Dist3 := abs(Blob3_XC-Blob1_XC)+abs(iBlob_Y1_1-Blob1_Y1);
                      IF (Dist3 < Max_Dist3 OR Detect_Steps < 2) THEN
                        match32 := match32 + 1;
                          IF (iBlob_Y1_1 - iBlob_Y0_1 < iBlob_X1_1 - iBlob_X0_1) THEN
                            Blob3_Flp := false;
                            Blob3_W := iBlob_X1_1 - iBlob_X0_1;
                          ELSE
                            Blob3_Flp := true;
                            Blob3_W := iBlob_Y1_1 - iBlob_Y0_1;
                          END IF;
                          IF (Blob3_W < Blob1_W OR Detect_Steps < 3) THEN
                            match33 := match33 + 1;
                              IF ((abs(Blob3_XC-Blob1_XC) < abs(iBlob_Y1_1-Blob1_Y1) XOR Blob1_Flp) OR Detect_Steps < 4) THEN
                                match34 := match34 + 1;
                                new_cone.x := Blob1_XC;
                                new_cone.y := Blob1_Y1;
                                cones_c <= cones_c + 1;
                                found := true;
                              
                              END IF;
                          
                          END IF;
                      
                      END IF;
                  
                  END IF;

                 Cur_Blob_Addr1 := Cur_Blob_Addr1 + 1;
                ELSE
                  Thread18 := Thread18 + 1;
                END IF;
              WHEN 7 =>
                Cur_Blob_Addr1 := 0;
                Thread18 := 8;
              WHEN 8 =>
                IF ( Cur_Blob_Addr2 < iBlobs_2 AND NOT found) THEN
                  IF (Blob1_Y1 > iBlob_Y1_2 OR Detect_Steps < 1) THEN
                    match21 := match21 + 1;

                    Blob2_XC := (iBlob_X1_2+iBlob_X0_2)/2;

                    Dist2 := abs(Blob2_XC-Blob1_XC)+abs(iBlob_Y1_2-Blob1_Y1);
                      IF (Dist2 < Max_Dist2 OR Detect_Steps < 2) THEN
                        match22 := match22 + 1;
                          IF (iBlob_Y1_2 - iBlob_Y0_2 < iBlob_X1_2 - iBlob_X0_2) THEN
                            Blob2_Flp := false;
                            Blob2_W := iBlob_X1_2 - iBlob_X0_2;
                          ELSE
                            Blob2_Flp := true;
                            Blob2_W := iBlob_Y1_2 - iBlob_Y0_2;
                          END IF;
                          IF (Blob2_W < Blob1_W OR Detect_Steps < 3) THEN
                            match23 := match23 + 1;
                              IF ((abs(Blob2_XC-Blob1_XC) < abs(iBlob_Y1_2-Blob1_Y1) XOR Blob2_Flp) OR Detect_Steps < 4) THEN
                                match24 := match24 + 1;
                                new_cone.x := Blob1_XC;
                                new_cone.y := Blob1_Y1;
                                cones_c <= cones_c + 1;
                                found := true;
                              END IF;
                          END IF;
                      END IF;
                  END IF;

                 Cur_Blob_Addr2 := Cur_Blob_Addr2 + 1;
                ELSE
                  Thread18 := Thread18 + 1;
                END IF;
              WHEN 9 =>
                Cur_Blob_Addr2 := 0;
                Thread18 := 10;
              WHEN 10 =>
                IF (found) THEN 
                  blob_ram_addr_in <= cones_c;
                blob_ram_data_in <= STD_LOGIC_VECTOR(TO_UNSIGNED(new_cone.y, 9)) & STD_LOGIC_VECTOR(TO_UNSIGNED(new_cone.x/2, 9));
                END IF;
                Thread18 := 11;
              WHEN 11 =>
                Cur_Blob1_Addr := Cur_Blob1_Addr + 1;
                Thread18 := 0;
                Thread15 := 1;
              WHEN others => Thread18 := 0;
            END CASE;
          WHEN 3 =>
            run_combine := false;
            Thread15 := 0;
          WHEN others => Thread15 := 0;
        END CASE;
      END IF;
    END IF;
  END PROCESS;
  
END BEHAVIORAL;
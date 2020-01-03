  
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all; 


ENTITY I2C_Master_Interface IS
  GENERIC (
      CLK_Frequency : INTEGER := 12000000; 
    Bus_CLK       : INTEGER := 400000   

  );
PORT (
  CLK : IN STD_LOGIC;
  Reset     : IN     STD_LOGIC := '0';                                
  Enable    : IN     STD_LOGIC := '0';                                
  Address   : IN     STD_LOGIC_VECTOR(6 DOWNTO 0) := (others => '0'); 
  RW        : IN     STD_LOGIC := '0';                                
  Data_WR   : IN     STD_LOGIC_VECTOR(7 DOWNTO 0) := (others => '0'); 
  Busy      : OUT    STD_LOGIC := '0';                                
  Data_RD   : OUT    STD_LOGIC_VECTOR(7 DOWNTO 0) := (others => '0'); 
  Ack_Error : BUFFER STD_LOGIC := '0';                                
  SDA       : INOUT  STD_LOGIC := 'Z';                                
  SCL       : INOUT  STD_LOGIC := 'Z'                                

);
END I2C_Master_Interface;

ARCHITECTURE BEHAVIORAL OF I2C_Master_Interface IS

  CONSTANT divider     :  INTEGER := (CLK_Frequency/Bus_CLK)/4; 
  TYPE machine IS(ready, start, command, slv_ack1, wr, rd, slv_ack2, mstr_ack, stop); 
  SIGNAL state         : machine;                        
  SIGNAL data_clk      : STD_LOGIC;                      
  SIGNAL data_clk_prev : STD_LOGIC;                      
  SIGNAL scl_clk       : STD_LOGIC;                      
  SIGNAL scl_ena       : STD_LOGIC := '0';               
  SIGNAL sda_int       : STD_LOGIC := '1';               
  SIGNAL sda_ena_n     : STD_LOGIC;                      
  SIGNAL addr_rw       : STD_LOGIC_VECTOR(7 DOWNTO 0);   
  SIGNAL data_tx       : STD_LOGIC_VECTOR(7 DOWNTO 0);   
  SIGNAL data_rx       : STD_LOGIC_VECTOR(7 DOWNTO 0);   
  SIGNAL bit_cnt       : INTEGER RANGE 0 TO 7 := 7;      
  SIGNAL stretch       : STD_LOGIC := '0';
  
BEGIN
  I2C_Timing_Generator : PROCESS (CLK)  
    VARIABLE count  :  INTEGER RANGE 0 TO divider*4;    

    
  BEGIN
  IF RISING_EDGE(CLK) THEN
    IF (Reset = '1') THEN
      stretch <= '0';
      count := 0;
    ELSE
      data_clk_prev <= data_clk;
      IF (count = divider*4-1) THEN
        count := 0;
      ELSIF (stretch = '0') THEN
        count := count + 1;
      
      END IF;
      IF (count < divider) THEN
        scl_clk <= '0';
        data_clk <= '0';
      ELSIF (count < divider*2) THEN
        scl_clk <= '0';
        data_clk <= '1';
      ELSIF (count < divider*3) THEN
        scl_clk <= '1';
        IF (SCL = '0') THEN
          stretch <= '1';
        ELSE
          stretch <= '0';
        END IF;
        data_clk <= '1';
      ELSE
        scl_clk <= '1';
        data_clk <= '0';
      END IF;
    END IF;
  END IF;
  END PROCESS;
  I2C_State_Machine : PROCESS (CLK)
  BEGIN
  IF RISING_EDGE(CLK) THEN
    IF (Reset = '1') THEN
      state <= ready;                      
      Busy <= '1';                         
      scl_ena <= '0';                      
      sda_int <= '1';                      
      Ack_Error <= '0';                    
      bit_cnt <= 7;                        
      Data_RD <= "00000000";
    ELSE
      IF (data_clk = '1' AND data_clk_prev = '0') THEN
        CASE (state) IS
          WHEN ready =>
            IF (Enable = '1') THEN
              Busy <= '1';                    
              addr_rw <= Address & RW;        
              data_tx <= Data_WR;             
              state <= start;
            ELSE
              Busy <= '0';                    
              state <= ready;
            END IF;
          WHEN start =>
            Busy <= '1';                        
            sda_int <= addr_rw(bit_cnt);        
            state <= command;
          WHEN command =>
            IF (bit_cnt = 0) THEN
              sda_int <= '1';                 
              bit_cnt <= 7;                   
              state <= slv_ack1;
            ELSE
              bit_cnt <= bit_cnt - 1;         
              sda_int <= addr_rw(bit_cnt-1);  
              state <= command;
            END IF;
          WHEN slv_ack1 =>
            IF (addr_rw(0) = '0') THEN
              sda_int <= data_tx(bit_cnt);    
              state <= wr;
            ELSE
              sda_int <= '1';                 
              state <= rd;
            END IF;
          WHEN wr =>
            Busy <= '1';
            IF (bit_cnt = 0) THEN
              sda_int <= '1';                 
              bit_cnt <= 7;                   
              state <= slv_ack2;
            ELSE
              bit_cnt <= bit_cnt - 1;         
              sda_int <= data_tx(bit_cnt-1);  
              state <= wr;
            END IF;
          WHEN rd =>
            Busy <= '1';
            IF (bit_cnt = 0) THEN
              IF (Enable = '1' AND addr_rw = Address & RW) THEN
                sda_int <= '0';
              ELSE
                sda_int <= '1';
              END IF;
              bit_cnt <= 7;                   
              Data_RD <= data_rx;             
              state <= mstr_ack;
            ELSE
              bit_cnt <= bit_cnt - 1;         
              state <= rd;
            END IF;
          WHEN slv_ack2 =>
            IF (Enable = '1') THEN
              Busy <= '0';                    
              addr_rw <= Address & RW;        
              data_tx <= Data_WR;
              IF (addr_rw = Address & RW) THEN
                sda_int <= Data_WR(bit_cnt);
                state <= wr;
              ELSE
                state <= start;
              END IF;
            ELSE
              state <= stop;
            END IF;
          WHEN mstr_ack =>
            IF (Enable = '1') THEN
              Busy <= '0';                    
              addr_rw <= Address & RW;        
              data_tx <= Data_WR;
              IF (addr_rw = Address & RW) THEN
                sda_int <= '1';             
                state <= rd;
              ELSE
                state <= start;
              END IF;
            ELSE
              state <= stop;
            END IF;
          WHEN stop =>
            Busy <= '0';                        
            state <= ready;
          
        END CASE;
      ELSIF (data_clk = '0' AND data_clk_prev = '1') THEN
        CASE (state) IS
          WHEN start =>
            IF (scl_ena = '0') THEN
              scl_ena <= '1';                 
              Ack_Error <= '0';
            
            END IF;
          WHEN slv_ack1 =>
            IF (SDA /= '0' OR Ack_Error = '1') THEN
              Ack_Error <= '1';
            
            END IF;
          WHEN rd =>
            data_rx(bit_cnt) <= SDA;
          WHEN slv_ack2 =>
            IF (SDA /= '0' OR Ack_Error = '1') THEN
              Ack_Error <= '1';
            END IF;
          WHEN stop =>
            scl_ena <= '0';
          WHEN others =>
            NULL;
        END CASE;
      END IF;
    END IF;
  END IF;
  END PROCESS;

  WITH state SELECT
  sda_ena_n <= data_clk_prev WHEN start,      
  NOT data_clk_prev WHEN stop,   
  sda_int WHEN OTHERS;           
  SCL <= '0' WHEN (scl_ena = '1' AND scl_clk = '0') ELSE 'Z';
  SDA <= '0' WHEN sda_ena_n = '0' ELSE 'Z';
  
END BEHAVIORAL;
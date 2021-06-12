--------------------------------------------------------------------------------
-- The SDRAM controller interface declarations
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

package sdram_controller_interface is
    -- 16M (addr) x 4 (bytes) == 64MB 
    constant SDRAM_DATA_WIDTH : natural := 16; -- These should go to separate package to allow different configurations
    constant SDRAM_ADDR_WIDTH : natural := 22;

    --! This enables the automatic periodic refresh that would have higher priority than other requests.
    --! The value of false: enables the SFlag_CmdRefresh on slave port that would trigger the SDRAM refresh once the SDRAM becomes ready
    --! In such case, the refresh is acknowledged with MFlag_RefreshAccept of master port
    constant SDRAM_USE_AUTOMATIC_REFRESH : boolean := true;
    constant SDRAM_USE_MANUAL_REFRESH : boolean := false;

    -- Simple OCP like protocol, master driven signals
    type SDRAM_controller_master_type is record
        MCmd             : std_logic_vector(2 downto 0); -- Request (0:Idle, 1:Read, 2:Write)
        MAddr            : std_logic_vector(SDRAM_ADDR_WIDTH - 1 downto 0); -- Request Address
        MData            : std_logic_vector(SDRAM_DATA_WIDTH - 1 downto 0); -- Write Data  
        MDataByteEn      : std_logic_vector(SDRAM_DATA_WIDTH / 8 - 1 downto 0); -- Write Data mask
        -- The write handshaking is not used. The controller expects data to be always valid during request, and uses fixed transactions
        MDataValid       : std_logic ; -- Write Data valid (handshaking during write)
        -- MDataLast        : std_logic ; -- Write Data Last (handshaking during write)
        MFlag_CmdRefresh : std_logic;   -- OCP sideband signal to trigger refresh (@see SDRAM_USE_AUTOMATIC_REFRESH constant)
    end record SDRAM_controller_master_type;

    -- Simple OCP like protocol, slave driven signals
    type SDRAM_controller_slave_type is record
        -- Acknowledges the validity of the next word. For Read Request this denotes the transmission of
        -- valid word. For Write Request this acknowledges that the current word is accepted and next word
        -- should be provided during next cycle.
        SCmdAccept          : std_logic; -- Acknowledges the request and the Data 
        SDataAccept         : std_logic; -- Write Data accept (handshaking during write)
        SData               : std_logic_vector(SDRAM_DATA_WIDTH - 1 downto 0); -- Read Data
        SResp               : std_logic; -- The Read Data is Valid
        SRespLast           : std_logic; -- Last data in burst
        SFlag_RefreshAccept : std_logic; -- OCP sideband signal to acknowledge refresh (@see SDRAM_USE_AUTOMATIC_REFRESH constant)
    end record SDRAM_controller_slave_type;
end sdram_controller_interface;

package body sdram_controller_interface is
end sdram_controller_interface;
--------------------------------------------------------------------------------
-- The package for SDR SDRAM chip parameters
--------------------------------------------------------------------------------

package sdram_config is

    -- Configuration of the SDRAM (Structure and timing)
    type sdram_config_type is record
        SA_WIDTH           : natural;   -- SDRAM interface address width
        BA_WIDTH           : natural;   -- bits of bank address
        ROW_WIDTH          : natural;   -- bits of row address (log2 of rows available)
        COL_WIDTH          : natural;   -- bits of column address (log2 of columns available)
        -- Timing parameters
        INIT_IDLE          : natural;   -- Inactivity perdiod required during initialization 
        INIT_REFRESH_COUNT : natural;   -- Number of Refresh commands required during initialization
        CAC                : natural;   -- CAS Latency (READ-data)
        RRD                : natural;   -- Row to Row Delay (ACT[0]-ACT[1])
        RCD                : natural;   -- Row to Column Delay (ACT-READ/WRITE)
        RAS                : natural;   -- Row Access Strobe (ACT-PRE)
        RC                 : natural;   -- Row Cycle (REF-REF,ACT-ACT)
        RP                 : natural;   -- Row Precharge (PRE-ACT)
        CCD                : natural;   -- Column Command Delay Time
        DPL                : natural;   -- Input Data to Precharge (DQ_WR-PRE)
        DAL                : natural;   -- Input Data to Activate (DQ_WR-ACT/PRE)
        RBD                : natural;   -- Burst Stop to High Impedance (Read)
        WBD                : natural;   -- Burst Stop to Input in Invalid (Write)
        PQL                : natural;   -- Last Output to Auto-Precharge Start (READ)
        QMD                : natural;   -- DQM to Output (Read)
        DMD                : natural;   -- DQM to Input (Write)
        MRD                : natural;   -- Mode Register Delay (program time)
        REFI               : natural;   -- Refresh interval (cycles between two refresh operations are required)
        RFC                : natural;   -- Refresh Cycle (time needed for Auto-Refresh operation; might be equal to RC)
    end record;

    -- Use a function here, because the timing params are dependent on Clock period and CAS latency
    function GetSDRAMParameters(clkPeriod : time; CACCycles : natural) return sdram_config_type;

end sdram_config;

--------------------------------------------------------------------------------
-- The IS42S16160B-7TLI chip parameters
-- SDR SDRAM on DE2-70 board
--------------------------------------------------------------------------------

library ieee;
use ieee.math_real.ceil;
package body sdram_config is

    -- Rounds the constant in time units to cycles
    function RoundTimeConstantToCycles(
        constant clkPeriod  : time;     -- Clock Period
        constant timePeriod : time)     -- Time period to be rounded to cycles
        return natural is
        constant resolution : time := 100 ps;
        variable r          : real := real(real(timePeriod / resolution) / real(clkPeriod / resolution));
    begin                               -- RoundTimeConstantToCycles
        return natural(ceil(r));
    end RoundTimeConstantToCycles;

    function GetSDRAMParameters(clkPeriod : time; CACCycles : natural) return sdram_config_type is
        variable res : sdram_config_type;

        constant SA_WIDTH  : integer := 12;
        constant BA_WIDTH  : integer := 2;
        constant ROW_WIDTH : integer := 12;
        constant COL_WIDTH : integer := 8;

        constant tINIT_IDLE         : time    := 200 us; -- Inactivity perdiod required during initialization 
        constant INIT_REFRESH_COUNT : natural := 8; -- Number of Refresh commands required during initialization
        constant tRRD               : time    := 14 ns; -- Row to Row Delay (ACT[0]-ACT[1])
        constant tRCD               : time    := 20 ns; -- Row to Column Delay (ACT-READ/WRITE)
        constant tRAS               : time    := 45 ns; -- Row Access Strobe (ACT-PRE)
        constant tRC                : time    := 67.5 ns; -- Row Cycle (REF-REF,ACT-ACT)
        constant tRP                : time    := 20 ns; -- Row Precharge (PRE-ACT)
        constant tCCD               : time    := clkPeriod * 1; -- Column Command Delay Time
        constant tDPL               : time    := 14 ns; -- Input Data to Precharge (DQ_WR-PRE)
        constant tDAL               : time    := 35 ns; -- Input Data to Activate (DQ_WR-ACT/PRE)
        constant tRBD               : time    := clkPeriod * CACCycles; -- Burst Stop to High Impedance (Read)
        constant tWBD               : time    := 0 ns; -- Burst Stop to Input in Invalid (Write)
        constant tPQL               : time    := clkPeriod * (CACCycles - 1); -- Last Output to Auto-Precharge Start (READ)
        constant tQMD               : time    := clkPeriod * 2; -- DQM to Output (Read)
        constant tDMD               : time    := 0 ns; -- DQM to Input (Write)
        -- Even though the MRD time is given in the specs, it seams that the frequency independent value (in clock cycles) should be used
        constant tMRD               : time    := clkPeriod * 2; -- Mode Register Delay (program time)
        constant tREF               : time    := 64 ms; -- Refresh Cycle (for each row)
        constant tREFI              : time    := tREF / (2 ** ROW_WIDTH); -- Minimal refresh interval


        constant INIT_IDLE : natural := RoundTimeConstantToCycles(clkPeriod, tINIT_IDLE);
        constant RRD       : natural := RoundTimeConstantToCycles(clkPeriod, tRRD); --! Row to Row Delay (ACT[0]-ACT[1])
        constant RCD       : natural := RoundTimeConstantToCycles(clkPeriod, tRCD); --! Row to Column Delay (ACT-READ/WRITE)
        constant RAS       : natural := RoundTimeConstantToCycles(clkPeriod, tRAS); --! Row Access Strobe (ACT-PRE)
        constant RC        : natural := RoundTimeConstantToCycles(clkPeriod, tRC); --! Row Cycle (REF-REF,ACT-ACT)
        constant RP        : natural := RoundTimeConstantToCycles(clkPeriod, tRP); --! Row Precharge (PRE-ACT)
        constant CCD       : natural := RoundTimeConstantToCycles(clkPeriod, tCCD); --! Column Command Delay Time
        constant DPL       : natural := RoundTimeConstantToCycles(clkPeriod, tDPL); --! Input Data to Precharge (DQ_WR-PRE)
        constant DAL       : natural := RoundTimeConstantToCycles(clkPeriod, tDAL); --! Input Data to Activate (DQ_WR-ACT/PRE)
        constant RBD       : natural := RoundTimeConstantToCycles(clkPeriod, tRBD); --! Burst Stop to High Impedance (Read)
        constant WBD       : natural := RoundTimeConstantToCycles(clkPeriod, tWBD); --! Burst Stop to Input in Invalid (Write)
        constant PQL       : natural := RoundTimeConstantToCycles(clkPeriod, tPQL); --! Last Output to Auto-Precharge Start (READ)
        constant QMD       : natural := RoundTimeConstantToCycles(clkPeriod, tQMD); --! DQM to Output (Read)
        constant DMD       : natural := RoundTimeConstantToCycles(clkPeriod, tDMD); --! DQM to Input (Write)
        constant MRD       : natural := RoundTimeConstantToCycles(clkPeriod, tMRD); --! Mode Register Delay (program time)
        constant REFI      : natural := RoundTimeConstantToCycles(clkPeriod, tREFI); --! Minimal refresh interval
        constant RFC       : natural := RC; --! Equal to RowCycle for this SDRAМ
    begin
        assert CACCycles = 2 or CACCycles = 3 report "CAS Latency of 2 or 3 must be used" severity error;
        assert CACCycles > 2 or clkPeriod >= 10 ns report "CAS Latency 2 is only supported for clk freq < 100 MHz" severity error;

        res := (SA_WIDTH           => SA_WIDTH,
                BA_WIDTH           => BA_WIDTH,
                ROW_WIDTH          => ROW_WIDTH,
                COL_WIDTH          => COL_WIDTH,
                INIT_IDLE          => INIT_IDLE,
                INIT_REFRESH_COUNT => INIT_REFRESH_COUNT,
                CAC                => CACCycles,
                RRD                => RRD,
                RCD                => RCD,
                RAS                => RAS,
                RC                 => RC,
                RP                 => RP,
                CCD                => CCD,
                DPL                => DPL,
                DAL                => DAL,
                RBD                => RBD,
                WBD                => WBD,
                PQL                => PQL,
                QMD                => QMD,
                DMD                => DMD,
                MRD                => MRD,
                REFI               => REFI,
                RFC                => RFC);
        return res;
    end function GetSDRAMParameters;
end sdram_config;


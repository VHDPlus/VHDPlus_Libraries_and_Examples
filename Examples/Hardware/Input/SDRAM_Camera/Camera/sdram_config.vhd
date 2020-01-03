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

	component LogicAnalyzer is
		port (
			acq_clk        : in std_logic                     := 'X';             -- clk
			acq_data_in    : in std_logic_vector(31 downto 0) := (others => 'X'); -- acq_data_in
			acq_trigger_in : in std_logic_vector(0 downto 0)  := (others => 'X')  -- acq_trigger_in
		);
	end component LogicAnalyzer;

	u0 : component LogicAnalyzer
		port map (
			acq_clk        => CONNECTED_TO_acq_clk,        -- acq_clk.clk
			acq_data_in    => CONNECTED_TO_acq_data_in,    --     tap.acq_data_in
			acq_trigger_in => CONNECTED_TO_acq_trigger_in  --        .acq_trigger_in
		);


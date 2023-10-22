	component NIOSDuino_Core is
		port (
			clk_in_clk    : in    std_logic                     := 'X';             -- clk
			pi_export     : in    std_logic_vector(31 downto 0) := (others => 'X'); -- export
			po_export     : out   std_logic_vector(31 downto 0);                    -- export
			reset_reset_n : in    std_logic                     := 'X';             -- reset_n
			sdram_addr    : out   std_logic_vector(11 downto 0);                    -- addr
			sdram_ba      : out   std_logic_vector(1 downto 0);                     -- ba
			sdram_cas_n   : out   std_logic;                                        -- cas_n
			sdram_cke     : out   std_logic;                                        -- cke
			sdram_cs_n    : out   std_logic;                                        -- cs_n
			sdram_dq      : inout std_logic_vector(15 downto 0) := (others => 'X'); -- dq
			sdram_dqm     : out   std_logic_vector(1 downto 0);                     -- dqm
			sdram_ras_n   : out   std_logic;                                        -- ras_n
			sdram_we_n    : out   std_logic;                                        -- we_n
			sdram_clk_clk : out   std_logic;                                        -- clk
			spi_MISO      : in    std_logic                     := 'X';             -- MISO
			spi_MOSI      : out   std_logic;                                        -- MOSI
			spi_SCLK      : out   std_logic;                                        -- SCLK
			spi_SS_n      : out   std_logic;                                        -- SS_n
			uart_rxd      : in    std_logic                     := 'X';             -- rxd
			uart_txd      : out   std_logic                                         -- txd
		);
	end component NIOSDuino_Core;

	u0 : component NIOSDuino_Core
		port map (
			clk_in_clk    => CONNECTED_TO_clk_in_clk,    --    clk_in.clk
			pi_export     => CONNECTED_TO_pi_export,     --        pi.export
			po_export     => CONNECTED_TO_po_export,     --        po.export
			reset_reset_n => CONNECTED_TO_reset_reset_n, --     reset.reset_n
			sdram_addr    => CONNECTED_TO_sdram_addr,    --     sdram.addr
			sdram_ba      => CONNECTED_TO_sdram_ba,      --          .ba
			sdram_cas_n   => CONNECTED_TO_sdram_cas_n,   --          .cas_n
			sdram_cke     => CONNECTED_TO_sdram_cke,     --          .cke
			sdram_cs_n    => CONNECTED_TO_sdram_cs_n,    --          .cs_n
			sdram_dq      => CONNECTED_TO_sdram_dq,      --          .dq
			sdram_dqm     => CONNECTED_TO_sdram_dqm,     --          .dqm
			sdram_ras_n   => CONNECTED_TO_sdram_ras_n,   --          .ras_n
			sdram_we_n    => CONNECTED_TO_sdram_we_n,    --          .we_n
			sdram_clk_clk => CONNECTED_TO_sdram_clk_clk, -- sdram_clk.clk
			spi_MISO      => CONNECTED_TO_spi_MISO,      --       spi.MISO
			spi_MOSI      => CONNECTED_TO_spi_MOSI,      --          .MOSI
			spi_SCLK      => CONNECTED_TO_spi_SCLK,      --          .SCLK
			spi_SS_n      => CONNECTED_TO_spi_SS_n,      --          .SS_n
			uart_rxd      => CONNECTED_TO_uart_rxd,      --      uart.rxd
			uart_txd      => CONNECTED_TO_uart_txd       --          .txd
		);


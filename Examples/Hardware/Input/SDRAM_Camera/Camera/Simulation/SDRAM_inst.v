	SDRAM u0 (
		.clk_in_clk       (<connected-to-clk_in_clk>),       // clk_in.clk
		.reset_reset_n    (<connected-to-reset_reset_n>),    //  reset.reset_n
		.s1_address       (<connected-to-s1_address>),       //     s1.address
		.s1_byteenable_n  (<connected-to-s1_byteenable_n>),  //       .byteenable_n
		.s1_chipselect    (<connected-to-s1_chipselect>),    //       .chipselect
		.s1_writedata     (<connected-to-s1_writedata>),     //       .writedata
		.s1_read_n        (<connected-to-s1_read_n>),        //       .read_n
		.s1_write_n       (<connected-to-s1_write_n>),       //       .write_n
		.s1_readdata      (<connected-to-s1_readdata>),      //       .readdata
		.s1_readdatavalid (<connected-to-s1_readdatavalid>), //       .readdatavalid
		.s1_waitrequest   (<connected-to-s1_waitrequest>),   //       .waitrequest
		.sdram_addr       (<connected-to-sdram_addr>),       //  sdram.addr
		.sdram_ba         (<connected-to-sdram_ba>),         //       .ba
		.sdram_cas_n      (<connected-to-sdram_cas_n>),      //       .cas_n
		.sdram_cke        (<connected-to-sdram_cke>),        //       .cke
		.sdram_cs_n       (<connected-to-sdram_cs_n>),       //       .cs_n
		.sdram_dq         (<connected-to-sdram_dq>),         //       .dq
		.sdram_dqm        (<connected-to-sdram_dqm>),        //       .dqm
		.sdram_ras_n      (<connected-to-sdram_ras_n>),      //       .ras_n
		.sdram_we_n       (<connected-to-sdram_we_n>)        //       .we_n
	);


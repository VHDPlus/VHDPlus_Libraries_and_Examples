	SDRAM u0 (
		.clk_in_clk              (<connected-to-clk_in_clk>),              //    clk_in.clk
		.reset_reset_n           (<connected-to-reset_reset_n>),           //     reset.reset_n
		.sdram_addr              (<connected-to-sdram_addr>),              //     sdram.addr
		.sdram_ba                (<connected-to-sdram_ba>),                //          .ba
		.sdram_cas_n             (<connected-to-sdram_cas_n>),             //          .cas_n
		.sdram_cke               (<connected-to-sdram_cke>),               //          .cke
		.sdram_cs_n              (<connected-to-sdram_cs_n>),              //          .cs_n
		.sdram_dq                (<connected-to-sdram_dq>),                //          .dq
		.sdram_dqm               (<connected-to-sdram_dqm>),               //          .dqm
		.sdram_ras_n             (<connected-to-sdram_ras_n>),             //          .ras_n
		.sdram_we_n              (<connected-to-sdram_we_n>),              //          .we_n
		.sdram_clk_clk           (<connected-to-sdram_clk_clk>),           // sdram_clk.clk
		.interface_address       (<connected-to-interface_address>),       // interface.address
		.interface_byteenable_n  (<connected-to-interface_byteenable_n>),  //          .byteenable_n
		.interface_chipselect    (<connected-to-interface_chipselect>),    //          .chipselect
		.interface_writedata     (<connected-to-interface_writedata>),     //          .writedata
		.interface_read_n        (<connected-to-interface_read_n>),        //          .read_n
		.interface_write_n       (<connected-to-interface_write_n>),       //          .write_n
		.interface_readdata      (<connected-to-interface_readdata>),      //          .readdata
		.interface_readdatavalid (<connected-to-interface_readdatavalid>), //          .readdatavalid
		.interface_waitrequest   (<connected-to-interface_waitrequest>)    //          .waitrequest
	);


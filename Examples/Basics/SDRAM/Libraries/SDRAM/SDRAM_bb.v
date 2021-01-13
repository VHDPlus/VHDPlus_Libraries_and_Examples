
module SDRAM (
	clk_in_clk,
	reset_reset_n,
	sdram_addr,
	sdram_ba,
	sdram_cas_n,
	sdram_cke,
	sdram_cs_n,
	sdram_dq,
	sdram_dqm,
	sdram_ras_n,
	sdram_we_n,
	sdram_clk_clk,
	interface_address,
	interface_byteenable_n,
	interface_chipselect,
	interface_writedata,
	interface_read_n,
	interface_write_n,
	interface_readdata,
	interface_readdatavalid,
	interface_waitrequest);	

	input		clk_in_clk;
	input		reset_reset_n;
	output	[11:0]	sdram_addr;
	output	[1:0]	sdram_ba;
	output		sdram_cas_n;
	output		sdram_cke;
	output		sdram_cs_n;
	inout	[15:0]	sdram_dq;
	output	[1:0]	sdram_dqm;
	output		sdram_ras_n;
	output		sdram_we_n;
	output		sdram_clk_clk;
	input	[21:0]	interface_address;
	input	[1:0]	interface_byteenable_n;
	input		interface_chipselect;
	input	[15:0]	interface_writedata;
	input		interface_read_n;
	input		interface_write_n;
	output	[15:0]	interface_readdata;
	output		interface_readdatavalid;
	output		interface_waitrequest;
endmodule

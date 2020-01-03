
module SDRAM (
	clk_in_clk,
	reset_reset_n,
	s1_address,
	s1_byteenable_n,
	s1_chipselect,
	s1_writedata,
	s1_read_n,
	s1_write_n,
	s1_readdata,
	s1_readdatavalid,
	s1_waitrequest,
	sdram_addr,
	sdram_ba,
	sdram_cas_n,
	sdram_cke,
	sdram_cs_n,
	sdram_dq,
	sdram_dqm,
	sdram_ras_n,
	sdram_we_n);	

	input		clk_in_clk;
	input		reset_reset_n;
	input	[21:0]	s1_address;
	input	[1:0]	s1_byteenable_n;
	input		s1_chipselect;
	input	[15:0]	s1_writedata;
	input		s1_read_n;
	input		s1_write_n;
	output	[15:0]	s1_readdata;
	output		s1_readdatavalid;
	output		s1_waitrequest;
	output	[11:0]	sdram_addr;
	output	[1:0]	sdram_ba;
	output		sdram_cas_n;
	output		sdram_cke;
	output		sdram_cs_n;
	inout	[15:0]	sdram_dq;
	output	[1:0]	sdram_dqm;
	output		sdram_ras_n;
	output		sdram_we_n;
endmodule

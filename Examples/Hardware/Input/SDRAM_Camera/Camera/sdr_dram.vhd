--------------------------------------------------------------------------------
-- SDRAM controller (Single Data Rate)
--
-- @version 0.1.1
-- Simple, non-pipelined, non-optimized controller
--
-- @author Edgar Lakis <edgar.lakis@gmail.com>
-- @section LICENSE
-- Copyright Technical University of Denmark. All rights reserved.
-- This file is part of the time-predictable VLIW Patmos.
-- 
-- Redistribution and use in source and binary forms, with or without
-- modification, are permitted provided that the following conditions are met:
-- 
--    1. Redistributions of source code must retain the above copyright notice,
--       this list of conditions and the following disclaimer.
-- 
--    2. Redistributions in binary form must reproduce the above copyright
--       notice, this list of conditions and the following disclaimer in the
--       documentation and/or other materials provided with the distribution.
-- 
-- THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDER ``AS IS'' AND ANY EXPRESS
-- OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
-- OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN
-- NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY
-- DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
-- (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
-- LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
-- ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
-- (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
-- THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
-- 
-- The views and conclusions contained in the software and documentation are
-- those of the authors and should not be interpreted as representing official
-- policies, either expressed or implied, of the copyright holder.
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.sdram_config.all;
use work.sdram_controller_interface.all;

-- SDRAM controller (Single Data Rate)

-- Simple controller with predictable timing.
-- Uses closed page policy.
entity sdr_sdram is
	generic(
		SHORT_INITIALIZATION  : boolean := false;
		USE_AUTOMATIC_REFRESH : boolean;
		BURST_LENGTH          : natural; -- The number of words transfered per request
		SDRAM                 : sdram_config_type; -- Parameters of the SDRAM chip
		-- Address mapping
		CS_WIDTH              : natural; -- width of rank address (0 for single rank)
		CS_LOW_BIT            : natural; -- last position of rank address in logical address
		BA_LOW_BIT            : natural; -- last position of bank address in logical address
		ROW_LOW_BIT           : natural; -- last position of row address in logical address
		COL_LOW_BIT           : natural -- last position of column address in logical address
	);
	port(
		rst         : in    std_logic;  -- Reset
		clk         : in    std_logic;  -- Clock
		pll_locked  : in    std_logic;  -- '1' when PLL has locked the clocks 
		-- User interface
		ocpSlave    : out   SDRAM_controller_slave_type;
		ocpMaster   : in    SDRAM_controller_master_type;
		-- SDRAM interface 
		sdram_CKE   : out   std_logic;  -- Clock Enable
		sdram_RAS_n : out   std_logic;  -- Row Address Strobe
		sdram_CAS_n : out   std_logic;  -- Column Address Strobe
		sdram_WE_n  : out   std_logic;  -- Write Enable
		sdram_CS_n  : out   std_logic_vector(2 ** CS_WIDTH - 1 downto 0); -- Chip Selects
		sdram_BA    : out   std_logic_vector(SDRAM.BA_WIDTH - 1 downto 0); -- Bank Address
		sdram_SA    : out   std_logic_vector(SDRAM.SA_WIDTH - 1 downto 0); -- SDRAM Address
		sdram_DQ    : inout std_logic_vector(SDRAM_DATA_WIDTH - 1 downto 0); -- Data
		sdram_DQM   : out   std_logic_vector(SDRAM_DATA_WIDTH / 8 - 1 downto 0) -- Data mask
	);
end entity sdr_sdram;

library ieee;
use ieee.math_real.ceil;

architecture RTL of sdr_sdram is

	-- @brief Variable size binary decoder (active low)
	function BinDecode_n(num : std_logic_vector) return std_logic_vector is
		variable result : std_logic_vector(2 ** num'length - 1 downto 0);
	begin
		result                            := (others => '1');
		result(to_integer(unsigned(num))) := '0';
		return result;
	end function BinDecode_n;

	-- @brief Maximum of two values
	function max(constant a, b : integer) return integer is
	begin
		if (a > b) then
			return a;
		else
			return b;
		end if;
	end function max;

	-- @brief Convert boolean to std_logic
	function bool2sl(bit : boolean) return std_logic is
	begin
		if bit then
			return '1';
		else
			return '0';
		end if;
	end function bool2sl;

	-- @brief Convert std_logic to natural
	function sl2int(bit : std_logic) return natural is
	begin
		if bit = '1' then
			return 1;
		else
			return 0;
		end if;
	end function sl2int;

	constant OCP_CMD_READ  : std_logic_vector(2 downto 0) := "010";
	constant OCP_CMD_WRITE : std_logic_vector(2 downto 0) := "001";

	function DefineModeRegister return std_logic_vector is
		variable result : std_logic_vector(SDRAM.BA_WIDTH + SDRAM.SA_WIDTH - 1 downto 0);

	begin
		-- Set reserved bits to '0'
		result             := (others => '0');
		-- Write Burst Mode: '0'- use same burst length as read; '1'- write single word 
		result(9)          := '0';
		-- Operating Mode: "00"- Normal Operation (other reserved for testing etc.)  
		result(8 downto 7) := "00";
		-- CAS Latency: usual binary encoding
		result(6 downto 4) := std_logic_vector(to_unsigned(SDRAM.CAC, 3));
		-- Burst Type: '0'- Sequential; '1'- interleaved (addr ^ offset)
		result(3)          := '0';
		-- Burst Length: "000".."011": 1,2,4,8; "111": Full Page
		case BURST_LENGTH is
			when 1 => result(2 downto 0) := "000";
			when 2 => result(2 downto 0) := "001";
			when 4 => result(2 downto 0) := "010";
			when 8 => result(2 downto 0) := "011";
			when 0 => result(2 downto 0) := "111";
				assert result(3) = '0' report "Full Page Burst not possible in interleaved mode" severity error;
				report "Full Page Bursts not supported by controller" severity error;
			when others =>
				report "Burst Length not supported by SDRAM" severity error;
		end case;
		return result;
	end function DefineModeRegister;

	-- We use autoprecharge, ensure that it will be invoked after tRAS 
	function CalculateAct2ReadCycles return natural is
		constant BL     : natural := BURST_LENGTH;
		variable result : natural;
	begin
		result := SDRAM.RCD;
		-- We are using the AutoPrecharge, so deffer the Read command,
		-- if the burst length is to short to satisfy the tRAS
		if (SDRAM.RCD + SDRAM.CAC + BL - 1 - SDRAM.PQL < SDRAM.RAS) then
			result := SDRAM.RAS + SDRAM.PQL - (BL - 1) - SDRAM.CAC;
		end if;
		return result;
	end function CalculateAct2ReadCycles;

	-- We use autoprecharge, ensure that it will be invoked after tRAS 
	function CalculateAct2WriteCycles return natural is
		constant BL     : natural := BURST_LENGTH;
		variable result : natural;
	begin
		result := SDRAM.RCD;
		-- We are using the AutoPrecharge, so deffer the Write command,
		-- if the burst length is to short to satisfy the tRAS
		if (SDRAM.RCD + BL - 1 + SDRAM.DPL < SDRAM.RAS) then
			result := SDRAM.RAS - SDRAM.DPL - (BL - 1);
		end if;
		return result;
	end function CalculateAct2WriteCycles;

	constant c_INIT_IDLE_CYCLES : natural := SDRAM.INIT_IDLE * sl2int(bool2sl(not SHORT_INITIALIZATION));
	constant c_ACT2READ_CYCLES  : natural := CalculateAct2ReadCycles;
	constant c_ACT2WRITE_CYCLES : natural := CalculateAct2WriteCycles;

	type t_state is (initWaitLock, initWaitIdle, initPrecharge, initPrechargeComplete, initRefresh, initRefreshComplete, initProgramModeReg, initProgramModeRegComplete, ready, readCmd, readDataWait, readData, writeCmd, writeDataRest, writePrechargeComplete, refreshComplete);

	signal state_r, state_nxt : t_state;
	signal sdram_RAS_n_nxt    : std_logic;
	signal sdram_CAS_n_nxt    : std_logic;
	signal sdram_WE_n_nxt     : std_logic;
	signal sdram_CS_n_nxt     : std_logic_vector(2 ** CS_WIDTH - 1 downto 0);
	signal sdram_BA_nxt       : std_logic_vector(SDRAM.BA_WIDTH - 1 downto 0);
	signal sdram_SA_nxt       : std_logic_vector(SDRAM.SA_WIDTH - 1 downto 0);
	signal sdram_DQM_nxt      : std_logic_vector(SDRAM_DATA_WIDTH / 8 - 1 downto 0);
	-- registered Data input
	signal sdram_DQ_r         : std_logic_vector(SDRAM_DATA_WIDTH - 1 downto 0);
	-- registered Data output, before the tri-state
	signal sdram_DQout_r      : std_logic_vector(SDRAM_DATA_WIDTH - 1 downto 0);
	-- registered Data output tri-state controll
	signal sdram_DQoe_r       : std_logic;
	signal sdram_DQoe_nxt     : std_logic;

	alias a_cs      : std_logic_vector(CS_WIDTH - 1 downto 0) is ocpMaster.MAddr(CS_WIDTH + CS_LOW_BIT - 1 downto CS_LOW_BIT);
	alias a_row     : std_logic_vector(SDRAM.ROW_WIDTH - 1 downto 0) is ocpMaster.MAddr(SDRAM.ROW_WIDTH + ROW_LOW_BIT - 1 downto ROW_LOW_BIT);
	alias a_bank    : std_logic_vector(SDRAM.BA_WIDTH - 1 downto 0) is ocpMaster.MAddr(SDRAM.BA_WIDTH + BA_LOW_BIT - 1 downto BA_LOW_BIT);
	-- SDRAM activate is issued at the same cycle as command is accepted. The row address is latched to conform to OCP
	signal cs_r     : std_logic_vector(CS_WIDTH - 1 downto 0);
	signal bank_r   : std_logic_vector(SDRAM.BA_WIDTH - 1 downto 0);
	signal column_r : std_logic_vector(SDRAM.COL_WIDTH - 1 downto 0);

	-- Counters
	-- A big counter for keeping the refresh/initialisation interval
	constant REFI_CNT_MAX                               : natural := max(c_INIT_IDLE_CYCLES, SDRAM.REFI * sl2int(bool2sl(USE_AUTOMATIC_REFRESH)));
	signal refi_cnt_nxt, refi_cnt_r                     : integer range 0 to REFI_CNT_MAX;
	-- Keeps track of number of refreshes perfomed during init
	signal refresh_repeat_cnt_nxt, refresh_repeat_cnt_r : integer range 0 to SDRAM.INIT_REFRESH_COUNT - 1;
	-- Small counter for various delays
	constant DELAY_CNT_MAX                              : natural := max(SDRAM.RP, max(SDRAM.RFC, max(SDRAM.MRD, max(c_ACT2WRITE_CYCLES, max(c_ACT2READ_CYCLES, SDRAM.DAL)))));
	signal delay_cnt_nxt, delay_cnt_r                   : integer range 0 to DELAY_CNT_MAX;
	-- Counts the word of the burst
	signal burst_cnt_nxt, burst_cnt_r                   : integer range 0 to 7;
	-- The DQ is saved in register during read, so need to delay the acknowledgment
	signal SResp_nxt, SResp_r                           : std_logic;
	signal SRespLast_nxt, SRespLast_r                   : std_logic;
begin
	sdram_CKE      <= '1';
	sdram_DQ       <= sdram_DQout_r when sdram_DQoe_r = '1' else (others => 'Z');
	ocpSlave.SData <= sdram_DQ_r;

	-- Registers
	reg : process(clk, rst) is
	begin
		if rst = '1' then
			--if SHORT_INITIALIZATION then
			--    state_r <= ready;
			--else
			state_r <= initWaitLock;
		--end if;
		elsif rising_edge(clk) then
			state_r              <= state_nxt;
			-- SDRAM i-face registers
			sdram_RAS_n          <= sdram_RAS_n_nxt;
			sdram_CAS_n          <= sdram_CAS_n_nxt;
			sdram_WE_n           <= sdram_WE_n_nxt;
			sdram_CS_n           <= sdram_CS_n_nxt;
			sdram_BA             <= sdram_BA_nxt;
			sdram_SA             <= sdram_SA_nxt;
			sdram_DQM            <= sdram_DQM_nxt;
			sdram_DQ_r           <= sdram_DQ;
			sdram_DQout_r        <= ocpMaster.MData;
			sdram_DQoe_r         <= sdram_DQoe_nxt;
			-- Delay the read data acknowledge for two cycles corresponding to 2 additional latency cycles introduced by controller.
			-- This is needed to accept the next command (be in the ready state) before the data transfer is finished.
			-- This is a quick fix. A proper solution would probably be moving the data acknowledge into the separate FSM.
			SResp_r              <= SResp_nxt;
			SRespLast_r          <= SRespLast_nxt;
			ocpSlave.SResp       <= SResp_r;
			ocpSlave.SRespLast   <= SRespLast_r;
			-- Counters
			delay_cnt_r          <= delay_cnt_nxt;
			refi_cnt_r           <= refi_cnt_nxt;
			refresh_repeat_cnt_r <= refresh_repeat_cnt_nxt;
			burst_cnt_r          <= burst_cnt_nxt;
			if state_r = ready and ocpMaster.MCmd /= "000" then
				-- latch the column address on command issue to conform to OCP
				cs_r     <= ocpMaster.MAddr(CS_WIDTH + CS_LOW_BIT - 1 downto CS_LOW_BIT);
				bank_r   <= ocpMaster.MAddr(SDRAM.BA_WIDTH + BA_LOW_BIT - 1 downto BA_LOW_BIT);
				column_r <= ocpMaster.MAddr(SDRAM.COL_WIDTH + COL_LOW_BIT - 1 downto COL_LOW_BIT);
			end if;

		end if;
	end process reg;

	assert false report "Controller timing information: " & lf & "Refresh cycles: " & natural'image(SDRAM.RFC) & lf &
		-- (c_ACT2WRITE-1) is used because it includes the first cycle of the data burst
		"Write cycles: " & natural'image((c_ACT2WRITE_CYCLES - 1) + BURST_LENGTH + SDRAM.DAL) & lf &
		-- (CAS latency-1) is used because CAC incudes the first cycle of the data burst.
		-- +1 at the end, to include the cycle at which the Activate is issued
		"Read cycles: " & natural'image(c_ACT2READ_CYCLES + (SDRAM.CAC - 1) + BURST_LENGTH + 1) & lf &
		-- 2 extra cycles in read latency are introduced by the registers in the SDRAM interface. One for command and one for incomming data. 
		"Read accept to first data word latency: " & natural'image(c_ACT2READ_CYCLES + SDRAM.CAC + 2) & lf
		severity note;

	-- State machine
	controller : process(a_bank, bank_r, column_r, a_cs, cs_r, a_row, burst_cnt_r, delay_cnt_r, ocpMaster.MCmd, ocpMaster.MDataByteEn, pll_locked, refresh_repeat_cnt_r, state_r, refi_cnt_r, ocpMaster.MDataValid)
		variable do_refresh              : std_logic;
		-- These are created as variables, to get rid of simulation range mismatch, where counters are out of range in transient time.
		variable refi_cnt_done           : std_logic;
		variable delay_cnt_done          : std_logic;
		variable refresh_repeat_cnt_done : std_logic;
		variable burst_cnt_done          : std_logic;

	begin
		-- NOP
		sdram_RAS_n_nxt                                     <= '1';
		sdram_CAS_n_nxt                                     <= '1';
		sdram_WE_n_nxt                                      <= '1';
		-- all chips
		sdram_CS_n_nxt                                      <= (others => '0');
		-- row of the bank
		sdram_BA_nxt                                        <= a_bank;
		sdram_SA_nxt(sdram_SA_nxt'high downto a_row'length) <= (others => '0');
		sdram_SA_nxt(a_row'range)                           <= a_row;
		-- Don't mask reads
		sdram_DQM_nxt                                       <= (others => '0');
		-- Data Disabled/High-Z
		sdram_DQoe_nxt                                      <= '0';
		-- OCP acknowledge
		ocpSlave.SCmdAccept                                 <= '0';
		SResp_nxt                                           <= '0';
		SRespLast_nxt                                       <= '0';
		ocpSlave.SDataAccept                                <= '0';
		state_nxt                                           <= state_r;
		ocpSlave.SFlag_RefreshAccept 			    <= '0';

		-- Counters
		refresh_repeat_cnt_done := bool2sl(refresh_repeat_cnt_r = 0);
		refi_cnt_done           := bool2sl(refi_cnt_r = 0);
		burst_cnt_done          := bool2sl(burst_cnt_r = 0);
		delay_cnt_done          := bool2sl(delay_cnt_r = 0);

		-- Default next values (decrement if non zero)
		delay_cnt_nxt          <= delay_cnt_r - sl2int(not delay_cnt_done);
		refi_cnt_nxt           <= refi_cnt_r - sl2int(not refi_cnt_done);
		burst_cnt_nxt          <= burst_cnt_r - sl2int(not burst_cnt_done);
		-- Count only in special state (keep the value by default)
		refresh_repeat_cnt_nxt <= refresh_repeat_cnt_r;

		case state_r is
			when initWaitLock =>
				if pll_locked = '1' then
					refi_cnt_nxt <= max(0, c_INIT_IDLE_CYCLES - 1);
					state_nxt    <= initWaitIdle;
				end if;
			when initWaitIdle =>
				if refi_cnt_done = '1' then
					state_nxt <= initPrecharge;
				end if;
			when initPrecharge =>
				sdram_RAS_n_nxt  <= '0';
				sdram_CAS_n_nxt  <= '1';
				sdram_WE_n_nxt   <= '0';
				sdram_SA_nxt(10) <= '1'; -- Precharge all banks
				sdram_CS_n_nxt   <= (others => '0'); -- All chips
				-- TODO: Add check for cnt constant beeing 0 and bypass the idle state
				-- TODO: Check if doing waiting in single state would improve the design
				-- TODO: The separate state machines will be used in pipelined version, so it might be better to do it differently
				delay_cnt_nxt    <= max(0, SDRAM.RP - 2); -- (-1) because of counter implementation; extra (-1) because we stay idle during whole counting
				state_nxt        <= initPrechargeComplete;
			when initPrechargeComplete =>
				if delay_cnt_done = '1' then
					refresh_repeat_cnt_nxt <= max(0, SDRAM.INIT_REFRESH_COUNT - 1);
					if SHORT_INITIALIZATION then
						state_nxt <= initProgramModeReg;
					else
						state_nxt <= initRefresh;
					end if;
				end if;
			when initRefresh =>
				sdram_RAS_n_nxt        <= '0';
				sdram_CAS_n_nxt        <= '0';
				sdram_WE_n_nxt         <= '1';
				sdram_CS_n_nxt         <= (others => '0'); -- All chips
				refresh_repeat_cnt_nxt <= refresh_repeat_cnt_r - 1;
				delay_cnt_nxt          <= max(0, SDRAM.RFC - 2); -- (-1) because of counter implementation; extra (-1) because we stay idle during whole counting
				state_nxt              <= initRefreshComplete;
			when initRefreshComplete =>
				if delay_cnt_done = '1' then
					if refresh_repeat_cnt_done = '1' then
						state_nxt <= initProgramModeReg;
					else
						state_nxt <= initRefresh;
					end if;
				end if;
			when initProgramModeReg =>
				sdram_RAS_n_nxt <= '0';
				sdram_CAS_n_nxt <= '0';
				sdram_WE_n_nxt  <= '0';
				sdram_BA_nxt    <= DefineModeRegister(SDRAM.BA_WIDTH + SDRAM.SA_WIDTH - 1 downto SDRAM.SA_WIDTH);
				sdram_SA_nxt    <= DefineModeRegister(SDRAM.SA_WIDTH - 1 downto 0);
				sdram_CS_n_nxt  <= (others => '0'); -- All chips
				delay_cnt_nxt   <= max(0, SDRAM.MRD - 2); -- (-1) because of counter implementation; extra (-1) because we stay idle during whole counting
				state_nxt       <= initProgramModeRegComplete;
			when initProgramModeRegComplete =>
				if delay_cnt_done = '1' then
					state_nxt <= ready;
					if USE_AUTOMATIC_REFRESH then
						refi_cnt_nxt <= SDRAM.REFI - 1;
					end if;
				end if;
			when ready =>
				if USE_AUTOMATIC_REFRESH then
					do_refresh := refi_cnt_done;
				else
					do_refresh := ocpMaster.MFlag_CmdRefresh;
				end if;
				-- Read/Write/Refresh
				if ocpMaster.MCmd = OCP_CMD_READ or ocpMaster.MCmd = OCP_CMD_WRITE or do_refresh = '1' then
					-- ocpSlave.SCmdAccept       <= '1'; -- luca
					-- Activate / Refresh
					sdram_RAS_n_nxt           <= '0';
					sdram_CAS_n_nxt           <= not do_refresh; -- '0': Refresh; '1': Activate
					sdram_WE_n_nxt            <= '1';
					sdram_BA_nxt              <= a_bank;
					sdram_SA_nxt(a_row'range) <= a_row;
					sdram_CS_n_nxt            <= BinDecode_n(a_cs) and (sdram_CS_n_nxt'range => not do_refresh); -- Refresh => All chips (Active LOW)

					if do_refresh = '1' then
						-- No cmd acknowledge for Refresh.
						ocpSlave.SCmdAccept <= '0';
						-- Uses separate acknowledge for manual refreshs trigger
						if not USE_AUTOMATIC_REFRESH then
							ocpSlave.SFlag_RefreshAccept <= '1';
						end if;
						delay_cnt_nxt <= max(0, SDRAM.RFC - 2); -- (-1) because of counter implementation; extra (-1) because we stay idle during whole counting
						state_nxt     <= refreshComplete;
					elsif ocpMaster.MCmd = OCP_CMD_READ then
						ocpSlave.SCmdAccept       <= '1';
						delay_cnt_nxt <= max(0, c_ACT2READ_CYCLES - 1); -- (-1) because of the counter implementation
						state_nxt     <= readCmd;
					else
						ocpSlave.SCmdAccept       <= '0';
						delay_cnt_nxt <= max(0, c_ACT2WRITE_CYCLES - 1); -- (-1) because of the counter implementation
						state_nxt     <= writeCmd;
					end if;
				end if;
			when readCmd =>
				if delay_cnt_done = '1' then
					-- Read with AutoPrecharge
					sdram_RAS_n_nxt              <= '1';
					sdram_CAS_n_nxt              <= '0';
					sdram_WE_n_nxt               <= '1';
					sdram_BA_nxt                 <= bank_r;
					sdram_CS_n_nxt               <= BinDecode_n(cs_r);
					sdram_SA_nxt(column_r'range) <= column_r;
					sdram_SA_nxt(10)             <= '1'; -- auto precharge
					if column_r'high >= 10 then
						sdram_SA_nxt(column_r'high + 1 downto 11) <= column_r(column_r'high downto 10);
					end if;

					-- Schedule Read Data
					if SDRAM.CAC >= 2 then
						delay_cnt_nxt <= SDRAM.CAC - 2; -- (-1) because of counter implementation; extra (-1) because CAC includes the first data transfer cycle
						state_nxt     <= readDataWait;
					elsif SDRAM.CAC = 1 then -- CAC of 1 means that there is no wait cycles (the data available in next cycle)
						state_nxt <= readData;
					end if;
				end if;
			when readDataWait =>
				if delay_cnt_done = '1' then
					burst_cnt_nxt <= BURST_LENGTH - 1; -- (-1) because of the counter implementation
					state_nxt     <= readData;
				end if;
			when readData =>
				-- The data seen by the user has 2 cycles of extra latency (1 reg to issue a command on SDRAМ interface and 1 reg to sample the data) 
				-- The extra delay of the acknowledgement is implemented as a shift register, to allow accepting the next command early
				SResp_nxt <= '1';
				if burst_cnt_done = '1' then
					SRespLast_nxt <= '1';
					state_nxt     <= ready;
				end if;
			when writeCmd =>
				if delay_cnt_done = '1' then
					ocpSlave.SCmdAccept       <= '1';
					if ocpMaster.MDataValid = '1' then
				
						-- Write with AutoPrecharge
						sdram_RAS_n_nxt              <= '1';
						sdram_CAS_n_nxt              <= '0';
						sdram_WE_n_nxt               <= '0';
						sdram_BA_nxt                 <= bank_r;
						sdram_CS_n_nxt               <= BinDecode_n(cs_r);
						sdram_SA_nxt(column_r'range) <= column_r;
						sdram_SA_nxt(10)             <= '1'; -- auto precharge
						if column_r'high >= 10 then
							sdram_SA_nxt(column_r'high + 1 downto 11) <= column_r(column_r'high downto 10);
						end if;

						-- First word of data and schedule the rest
						
						ocpSlave.SDataAccept <= '1';
						sdram_DQM_nxt        <= not ocpMaster.MDataByteEn;
						sdram_DQoe_nxt       <= '1';
						if BURST_LENGTH >= 2 then
							burst_cnt_nxt <= BURST_LENGTH - 2; -- (-1) because of counter implementation; extra (-1) because current state sends first word
							state_nxt     <= writeDataRest;
						else
							delay_cnt_nxt <= max(0, SDRAM.DAL - 2); -- (-1) because of counter implementation; extra (-1) because we stay idle during whole counting
							state_nxt     <= writePrechargeComplete;
						end if;
					
					end if;
					
				end if;
			when writeDataRest =>
				ocpSlave.SDataAccept <= '1';
				sdram_DQM_nxt        <= not ocpMaster.MDataByteEn;
				sdram_DQoe_nxt       <= '1';
				if burst_cnt_done = '1' then
					delay_cnt_nxt <= max(0, SDRAM.DAL - 2); -- (-1) because of counter implementation; extra (-1) because we stay idle during whole counting
					state_nxt     <= writePrechargeComplete;
				end if;
			when writePrechargeComplete =>
				if delay_cnt_done = '1' then
					state_nxt <= ready;
					SResp_nxt <= '1';
				end if;
			when refreshComplete =>
				if delay_cnt_done = '1' then
					state_nxt <= ready;
					if USE_AUTOMATIC_REFRESH then
						refi_cnt_nxt <= SDRAM.REFI - 1;
					end if;
				end if;
		end case;
	end process controller;

end architecture RTL;

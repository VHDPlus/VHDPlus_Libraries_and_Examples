--
--  Pseudo Random Number Generator "xoshiro128++ 1.0".
--
--  Author: Joris van Rantwijk <joris@jorisvr.nl>
--
--  This is a 32-bit random number generator in synthesizable VHDL.
--  The generator can produce 32 new random bits on every clock cycle.
--
--  The algorithm "xoshiro128++" is by David Blackman and Sebastiano Vigna.
--  See also http://prng.di.unimi.it/
--
--  The generator requires a 128-bit seed value, not equal to all zeros.
--  A default seed must be supplied at compile time and will be used
--  to initialize the generator at reset. The generator also supports
--  re-seeding at run time.
--
--  After reset and after re-seeding, one or two clock cycles are needed
--  before valid random data appears on the output. The exact delay
--  depends on the setting of the "pipeline" parameter.
--
--  NOTE: This is not a cryptographic random number generator.
--

--
--  Copyright (C) 2020 Joris van Rantwijk
--
--  This code is free software; you can redistribute it and/or
--  modify it under the terms of the GNU Lesser General Public
--  License as published by the Free Software Foundation; either
--  version 2.1 of the License, or (at your option) any later version.
--
--  See <https://www.gnu.org/licenses/old-licenses/lgpl-2.1.html>
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity Random_Number is

    generic (
        -- Default seed value.
        init_seed:  std_logic_vector(127 downto 0) := x"0123456789abcdef0123456789abcdef";

        -- Enable optional pipeline stage in output calculation.
        -- This uses an extra 32-bit register but tends to improve
        -- the timing performance of the circuit.
        -- If the pipeline stage is enabled, two clock cycles are needed
        -- before valid output appears after reset and after re-seeding.
        -- If the pipeline stage is disabled, just one clock cycle is needed.
        pipeline:   boolean := true );

    port (

        -- Clock, rising edge active.
        clk:        in  std_logic;

        -- Synchronous reset, active high.
        rst:        in  std_logic := '0';

        -- High to request re-seeding of the generator.
        reseed:     in  std_logic := '0';

        -- New seed value (must be valid when reseed = '1').
        newseed:    in  std_logic_vector(127 downto 0) := (others => '0');

        -- High when the user accepts the current random data word
        -- and requests new random data for the next clock cycle.
        out_ready:  in  std_logic := '1';

        -- High when valid random data is available on the output.
        -- This signal is low for 1 or 2 clock cycles after reset and
        -- after re-seeding, and high in all other cases.
        out_valid:  out std_logic;

        -- Random output data (valid when out_valid = '1').
        -- A new random word appears after every rising clock edge
        -- where out_ready = '1'.
        out_data:   out std_logic_vector(31 downto 0) );

end entity;


architecture xoshiro128plusplus_arch of Random_Number is

    -- Internal state of RNG.
    signal reg_state_s0:    std_logic_vector(31 downto 0) := init_seed(31 downto 0);
    signal reg_state_s1:    std_logic_vector(31 downto 0) := init_seed(63 downto 32);
    signal reg_state_s2:    std_logic_vector(31 downto 0) := init_seed(95 downto 64);
    signal reg_state_s3:    std_logic_vector(31 downto 0) := init_seed(127 downto 96);

    -- Optional pipeline register.
    signal reg_sum_s0s3:    std_logic_vector(31 downto 0) := (others => '0');

    -- Output register.
    signal reg_valid:       std_logic := '0';
    signal reg_nvalid:      std_logic := '0';
    signal reg_output:      std_logic_vector(31 downto 0) := (others => '0');

begin

    -- Drive output signal.
    out_valid   <= reg_valid;
    out_data    <= reg_output;

    -- Synchronous process.
    process (clk) is
        variable v_prev_s0: std_logic_vector(31 downto 0) := (others => '0');
    begin
        if rising_edge(clk) then

            if out_ready = '1' or reg_valid = '0' then

                -- Prepare output word.
                if pipeline then

                    -- Use a pipelined output stage.
                    reg_valid       <= reg_nvalid;
                    reg_nvalid      <= '1';

                    -- Calculate the previous value of s0.
                    v_prev_s0       := reg_state_s0 xor
                    std_logic_vector(
                        rotate_right(unsigned(reg_state_s3),
                            11));

                    -- Derive output from prev_s0 and intermediate result
                    -- (prev_s0 + prev_s3) calculated in the previous cycle.
                    reg_output      <= std_logic_vector(
                        unsigned(v_prev_s0) +
                        rotate_left(unsigned(reg_sum_s0s3),
                            7));

                    -- Update the intermediate register (s0 + s3).
                    reg_sum_s0s3    <= std_logic_vector(
                        unsigned(reg_state_s0) +
                        unsigned(reg_state_s3));

                else

                    -- Derive output directly from s0 and s3.
                    -- This requires two cascaded 32-bit adders and
                    -- may limit the timing performance of the circuit.
                    reg_valid       <= '1';
                    reg_output      <= std_logic_vector(
                        rotate_left(
                            unsigned(reg_state_s0) +
                            unsigned(reg_state_s3), 7) +
                        unsigned(reg_state_s0));

                end if;

                -- Update internal state.
                reg_state_s0    <= reg_state_s0 xor
                reg_state_s1 xor
                reg_state_s3;

                reg_state_s1    <= reg_state_s0 xor
                reg_state_s1 xor
                reg_state_s2;

                reg_state_s2    <= reg_state_s0 xor
                reg_state_s2 xor
                std_logic_vector(
                    shift_left(unsigned(reg_state_s1), 9));

                reg_state_s3    <= std_logic_vector(
                    rotate_left(
                        unsigned(reg_state_s1 xor
                            reg_state_s3), 11));

            end if;

            -- Re-seed function.
            if reseed = '1' then
                reg_state_s0    <= newseed(31 downto 0);
                reg_state_s1    <= newseed(63 downto 32);
                reg_state_s2    <= newseed(95 downto 64);
                reg_state_s3    <= newseed(127 downto 96);
                reg_valid       <= '0';
                reg_nvalid      <= '0';
            end if;

            -- Synchronous reset.
            if rst = '1' then
                reg_state_s0    <= init_seed(31 downto 0);
                reg_state_s1    <= init_seed(63 downto 32);
                reg_state_s2    <= init_seed(95 downto 64);
                reg_state_s3    <= init_seed(127 downto 96);
                reg_valid       <= '0';
                reg_nvalid      <= '0';
                reg_output      <= (others => '0');
            end if;

        end if;
    end process;

end architecture;


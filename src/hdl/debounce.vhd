--------------------------------------------------------------------------------
--
--  Counter based switch debounce module
--
--  Output changes only when the input is stable for G_NUM_CLK_CYCLES clock
--  cycles. Input is first passed through a synchronization double FF.Total
--  latency is G_NUM_CLK_CYCLES + 5.
--
--
--------------------------------------------------------------------------------
--  This work is licensed under the MIT License (see the LICENSE file for terms)
--  Copyright 2016 Lymperis Voudouris 
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity debounce is
    generic(
    G_NUM_CLK_CYCLES : natural := 2**16
    );
    port(
    clk     : in  std_logic;
    sig_in  : in  std_logic;
    sig_out : out std_logic
    );
end entity debounce;

architecture rtl of debounce is
    signal cnt_debounce_r : natural := 0;
    -- shift register serves as a sync double flip-flop plus an edge detector
    signal syncedge_sr    : std_logic_vector(2 downto 0) := (others=>'0');
    signal rst_cnt_c      : std_logic := '0';
begin
    
    rst_cnt_c <= syncedge_sr(1) xor syncedge_sr(0);

    proc_debounce:
    process(clk)
    begin
        if rising_edge(clk) then
            
            syncedge_sr <= sig_in & syncedge_sr(2 downto 1);

            -- Counter keeps counting as long as the input signal remains stable. When it
            -- reaches the max number of clk cycles, the output register is set to the stable 
            -- input value. Any change in the input signal resets the counter.
            if (rst_cnt_c = '1') then
                cnt_debounce_r <= 0;
            elsif (cnt_debounce_r = G_NUM_CLK_CYCLES-1) then
                sig_out <= syncedge_sr(0);
            else
                cnt_debounce_r <= cnt_debounce_r + 1;
            end if;

        end if;
    end process;


end architecture;
--------------------------------------------------------------------------------
--
--  Shift register based deglitch filter
--
--  Output changes only when the input is stable for G_NUM_CLK_CYCLES clock
--  cycles. Input is first passed through a synchronization double FF.Total
--  latency is G_NUM_CLK_CYCLES + 3.
--
--
--------------------------------------------------------------------------------
--  This work is licensed under the MIT License (see the LICENSE file for terms)
--  Copyright 2016 Lymperis Voudouris 
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity deglitch is
    generic(
    G_NUM_CLK_CYCLES : natural := 4
    );
    port(
    clk     : in  std_logic;
    sig_in  : in  std_logic;
    sig_out : out std_logic
    );
end entity deglitch;

architecture rtl of deglitch is
    constant FILTER_ALL_ONES  : std_logic_vector(G_NUM_CLK_CYCLES-1 downto 0) := (others=>'1');
    constant FILTER_ALL_ZEROS : std_logic_vector(G_NUM_CLK_CYCLES-1 downto 0) := (others=>'0');
    
    signal filter_sr : std_logic_vector(G_NUM_CLK_CYCLES+1 downto 0) := (others=>'0');  

begin
    
    proc_deglitch:
    process(clk)
    begin
        if rising_edge(clk) then
            filter_sr <= sig_in & filter_sr(G_NUM_CLK_CYCLES+1 downto 1);

            if (filter_sr(G_NUM_CLK_CYCLES-1 downto 0) = FILTER_ALL_ONES) then
                sig_out <= '1';
            elsif (filter_sr(G_NUM_CLK_CYCLES-1 downto 0) = FILTER_ALL_ZEROS) then
                sig_out <= '0';
            end if;
        end if;
    end process;


end architecture;
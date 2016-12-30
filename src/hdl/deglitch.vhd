--------------------------------------------------------------------------------
--
--  Shift register based deglitch filter
--
--  Output changes only when the input is stable for G_NUM_CLK_CYCLES clock
--  cycles. Input is first passed through a synchronization double FF.Total
--  latency is G_NUM_CLK_CYCLES + 3.
--
--  Author(s): Lymperis Voudouris
--
--------------------------------------------------------------------------------
-- MIT License
--
-- Copyright (c) 2016 Lymperis Voudouris
-- 
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
-- 
-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.
-- 
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
-- THE SOFTWARE.
--
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
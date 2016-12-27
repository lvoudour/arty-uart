--------------------------------------------------------------------------------
--
--  UART Tx module
--
--  8 bit data, 1 stop bit, no parity. Baud rate = Fclk / G_CLK_DIVISOR.
--
--  Assuming clk is the Arty 100 MHz XTAL, the default baud rate will be 1Mbaud
--  Not optimal for high clk rates/low baud rates, as the dividing counter can
--  become unnecessarily large.
--
--  The FT2232H chip does not support baud rates of 7 Mbaud 9 Mbaud, 10 Mbaud
--  and 11 Mbaud.
--  http://www.ftdichip.com/Support/Documents/DataSheets/ICs/DS_FT2232H.pdf
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

entity uart_tx is
    generic(
    G_CLK_DIVISOR : positive := 100
    );
    port(
    clk          : in  std_logic;
    rst          : in  std_logic;
    tx_data_in   : in  std_logic_vector(7 downto 0);
    tx_en_in     : in  std_logic;
    tx_ready_out : out std_logic;
    tx_out       : out std_logic
    );
end entity uart_tx;

architecture rtl of uart_tx is
    
    type fsm_tx_type is (
    FSM_TX_IDLE,
    FSM_TX_SHIFT_WORD
    );

    signal fsm_tx_state : fsm_tx_type := FSM_TX_IDLE;
    signal cnt_div_r    : integer range 0 to G_CLK_DIVISOR-1 := 0;
    signal cnt_shift_r  : integer range 0 to 9 := 0;
    signal tx_word_sr   : std_logic_vector(9 downto 0) := (others=>'0');
    signal tx_ready_r   : std_logic := '0';
    signal tx_r         : std_logic := '1';

begin
    
    PROC_FSM_TX:
    process(clk)
    begin
        if rising_edge(clk) then
            if (rst = '1') then
                tx_r         <= '1';
                tx_ready_r   <= '0';
                cnt_div_r    <= 0;
                cnt_shift_r  <= 0;
                fsm_tx_state <= FSM_TX_IDLE;
            else
                case fsm_tx_state is

                when FSM_TX_IDLE =>
                   tx_r       <= '1';
                   tx_ready_r <= '1';
                   if (tx_en_in = '1') then
                       tx_ready_r   <= '0';
                       tx_word_sr   <= '1' & tx_data_in & '0';
                       fsm_tx_state <= FSM_TX_SHIFT_WORD;
                    end if;
                

                when FSM_TX_SHIFT_WORD =>
                    tx_r <= tx_word_sr(0);
                    if (cnt_div_r = G_CLK_DIVISOR-1) then
                        cnt_div_r  <= 0;
                        tx_word_sr <= '1' & tx_word_sr(9 downto 1);
                        if (cnt_shift_r = 9) then
                            cnt_shift_r  <= 0;
                            fsm_tx_state <= FSM_TX_IDLE;
                        else
                            cnt_shift_r <= cnt_shift_r + 1;
                        end if;
                    else
                        cnt_div_r <= cnt_div_r + 1;
                    end if;

                end case;

            end if;
        end if;
    end process;


---------------------------------
-- Outputs
---------------------------------

    tx_ready_out <= tx_ready_r;
    tx_out       <= tx_r;

end architecture;
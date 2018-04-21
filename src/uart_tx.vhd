--------------------------------------------------------------------------------
--  UART Tx module
--
--  8 bit data, 1 stop bit, no parity. Intended for the Digilent Arty Artix-7
--  FPGA board, but can be easily used in other projects without modification.
--
--  Signals:
--    clk          : clock of frequency G_CLOCK_FREQ
--    rst          : active high synchronous reset
--    tx_out       : Tx data line. Should be routed the Rx pin of the external
--                   UART device.
--    tx_en_in     : Set high for at least 1 clk cycle to initate data transfer.
--                   Will be ignored if the module is busy (tx_ready_out low)
--    tx_data_in   : 8 bit data to send
--    tx_ready_out : high = module is ready to transfer new data
--                   low  = module is currently busy and cannot accept new data
--
--  Parameters:
--    G_BAUD_RATE  : UART baud rate
--    G_CLOCK_FREQ : clk frequency. Can be fractional
--    
--  Not optimal for high clk rates/low baud rates, as the dividing counter can
--  become unnecessarily large.
--
--  Arty FPGA board specific notes:
--    The FT2232H chip does not support baud rates of 7 Mbaud 9 Mbaud, 10 Mbaud
--    and 11 Mbaud.
--    http://www.ftdichip.com/Support/Documents/DataSheets/ICs/DS_FT2232H.pdf
--
--
--------------------------------------------------------------------------------
--  This work is licensed under the MIT License (see the LICENSE file for terms)
--  Copyright 2016 Lymperis Voudouris 
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity uart_tx is
  generic(
    G_BAUD_RATE  : positive := 1250000;
    G_CLOCK_FREQ : real     := 100.0e6
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
    
  constant C_CLK_DIVISOR : positive := positive(round(G_CLOCK_FREQ / real(G_BAUD_RATE)));
  constant C_DIV_WIDTH   : positive := positive(ceil(log2(real(C_CLK_DIVISOR))));
  
  type fsm_tx_type is (
  TX_IDLE,
  TX_SHIFT_WORD
  );

  signal fsm_tx_state : fsm_tx_type := TX_IDLE;
  signal cnt_div_r    : unsigned(C_DIV_WIDTH-1 downto 0) := (others=>'0');
  signal cnt_shift_r  : unsigned(9 downto 0) := (others=>'0');
  signal tx_data_sr   : std_logic_vector(9 downto 0) := (others=>'0');
  signal tx_ready_r   : std_logic := '0';
  signal tx_r         : std_logic := '1';

begin
    
  proc_fsm_tx:
  process(clk)
  begin
    if rising_edge(clk) then
      if (rst = '1') then
        tx_r         <= '1';
        tx_ready_r   <= '0';
        fsm_tx_state <= TX_IDLE;
      else
        case fsm_tx_state is

        when TX_IDLE =>
         tx_r       <= '1';
         tx_ready_r <= '1';
         cnt_shift_r  <= (others=>'0');
         cnt_div_r    <= (others=>'0');
         if (tx_en_in = '1') then
           tx_ready_r   <= '0';
           tx_data_sr   <= '1' & tx_data_in & '0';
           fsm_tx_state <= TX_SHIFT_WORD;
         end if;

        when TX_SHIFT_WORD =>
          tx_r <= tx_data_sr(0);
          if (cnt_div_r = C_CLK_DIVISOR-1) then
            cnt_div_r   <= (others=>'0');
            tx_data_sr  <= '1' & tx_data_sr(9 downto 1);
            if (cnt_shift_r = 9) then
              fsm_tx_state <= TX_IDLE;
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

  tx_ready_out <= tx_ready_r;
  tx_out       <= tx_r;

end architecture;
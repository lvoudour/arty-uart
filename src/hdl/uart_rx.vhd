--------------------------------------------------------------------------------
--
--  UART Rx module
--
--  8 bit data, 1 stop bit, no parity. Intended for the Digilent Arty Artix-7
--  FPGA board, but can be easily used in other projects without modification.
--
--  Signals:
--    clk          : clock of frequency G_CLOCK_FREQ
--    rst          : active high synchronous reset
--    rx_in        : Rx data line. Should be routed to the Tx pin of the external
--                   UART device.
--    rx_data_out  : 8 bit data received
--    rx_valid_out : 1 clk cycle pulse that indicates rx_data_out is valid.
--
--  Parameters:
--    G_BAUD_RATE  : UART baud rate
--    G_CLOCK_FREQ : clk frequency. Can be fractional
--  
--  Optimally, the baud rate must be an integer multiple of the clock
--  frequency. If not, it's rouded to the closest integer. In such cases
--  care must be taken to ensure sampling does not deviate significantly from
--  the center of the "eye"(ie. the middle of the received bit).
--
--  It is recommended to use sync flip-flops and a glitch filter before 
--  connecting the rx input to the external UART device.
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

entity uart_rx is
  generic(
    G_BAUD_RATE  : positive := 1250000;
    G_CLOCK_FREQ : real     := 100.0e6
  );
  port(
    clk          : in  std_logic;
    rst          : in  std_logic;
    rx_in        : in  std_logic;
    rx_data_out  : out std_logic_vector(7 downto 0);
    rx_valid_out : out std_logic
  );
end entity uart_rx;

architecture rtl of uart_rx is
    
  constant C_CLK_DIVISOR : positive := positive(round(G_CLOCK_FREQ / real(G_BAUD_RATE)));
  constant C_DIV_WIDTH   : positive := positive(ceil(log2(real(C_CLK_DIVISOR))));
  
  type fsm_rx_type is (
  RX_IDLE,
  RX_DATA,
  RX_STOP
  );

  signal fsm_rx_state      : fsm_rx_type := RX_IDLE;
  signal cnt_div_r         : unsigned(C_DIV_WIDTH-1 downto 0) := (others=>'0');
  signal cnt_data_r        : unsigned(7 downto 0) := (others=>'0');
  signal rx_data_sr        : std_logic_vector(7 downto 0) := (others=>'0');
  signal rx_r              : std_logic := '0';
  signal rx_falling_edge_c : std_logic := '0';
  signal rx_valid_r        : std_logic := '0';

begin
    
    
  rx_falling_edge_c <= (not rx_in) and rx_r;

  -- A counter is used to synchronize the clock to the baud rate. The counter
  -- is reset at the falling edge of the start bit. Sampling should be done
  -- exactly halfway (ie. after C_CLK_DIVISOR/2 cycles)
  proc_div_counter:
  process(clk)
  begin
    if rising_edge(clk) then
      rx_r <= rx_in;

      -- reset counter
      if (rx_falling_edge_c = '1') and (fsm_rx_state = RX_IDLE) then
        cnt_div_r <= (others=>'0');
      else
        if (cnt_div_r = C_CLK_DIVISOR - 1) then
          cnt_div_r <= (others=>'0');
        else
          cnt_div_r <= cnt_div_r + 1;
        end if;
      end if;
    end if;
  end process;

  proc_fsm_rx:
  process(clk)
  begin
    if rising_edge(clk) then
      if (rst = '1') then
        rx_valid_r <= '0';
        fsm_rx_state <= RX_IDLE;
      else
        rx_valid_r <= '0';

        case fsm_rx_state is

        -- Wait for the start bit
        when RX_IDLE =>
          -- We're checking rx_r and not rx_in
          -- just in case the counter happens to be halway at the falling edge,
          -- causing a false trigger
          cnt_data_r <= (others=>'0');
          if (rx_r = '0') and (cnt_div_r = C_CLK_DIVISOR/2 - 1) then
            fsm_rx_state <= RX_DATA;
          end if;

        -- Sample the data bits and shift them into a register
        when RX_DATA =>
          if (cnt_div_r = C_CLK_DIVISOR/2 - 1) then
            rx_data_sr <= rx_r & rx_data_sr(7 downto 1);
            if (cnt_data_r = 7) then
              fsm_rx_state <= RX_STOP;
            else
              cnt_data_r <= cnt_data_r + 1;
            end if;
          end if;

        -- Check for the stop bit
        when RX_STOP =>
          if (cnt_div_r = C_CLK_DIVISOR/2 - 1) then
            -- raise the valid flag only if the stop bit is 1
            if (rx_r = '1') then
              rx_valid_r <= '1';
            end if;
            fsm_rx_state <= RX_IDLE;
          end if;

        when others =>
          fsm_rx_state <= RX_IDLE;

        end case;

      end if;
    end if;
  end process;

  rx_data_out  <= rx_data_sr;
  rx_valid_out <= rx_valid_r;

end architecture;
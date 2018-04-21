--------------------------------------------------------------------------------
--
--  UART loopback demo for the Arty FPGA board
--
--  Ports:
--    clk_100mhz_ipad   : Arty 100MHz clock
--    ck_rst_n_ipad     : Arty CK_RST active low reset pin
--    uart_rx_ipad      : UART Rx line connected to the FT2232HQ chip Tx line
--    uart_tx_opad      : UART Tx line connected to the FT2232HQ chip Rx line
--    tx_fifo_full_out  : Tx FIFO full
--
--  On reset, the module tranmits a "welcome" message and then switches to
--  loopback mode. In loopback mode any data received by the FPGA UART is
--  transmitted back (echo).
--
--  To test set the JP2 jumper, connect the Arty board through micro-USB to a
--  PC and open a serial terminal (eg. Putty). You should see the message at
--  the top. Any characters entered with the keyboard are echoed back to the
--  terminal. Each time you reconnect, the FT2232HQ chip on the board resets the
--  FPGA so the message is displayed with every new terminal connection.
--
--------------------------------------------------------------------------------
--  This work is licensed under the MIT License (see the LICENSE file for terms)
--  Copyright 2016 Lymperis Voudouris 
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_loopback is
  port(
    clk_100mhz_ipad : in  std_logic;
    ck_rst_n_ipad   : in  std_logic;
    uart_rx_ipad    : in  std_logic;
    uart_tx_opad    : out std_logic
  );
end entity uart_loopback;

architecture rtl of uart_loopback is
    
  ------------------------------------------
  -- to_slv
  ------------------------------------------
  -- Converts a character to std_logic_vector
  --    c      : Input character
  --    width  : width of output std_logic_vector
  function to_slv(c : character; width : positive) return std_logic_vector is
  begin
    return std_logic_vector(to_unsigned(character'pos(c), width));
  end to_slv;

  type fsm_uart_type is (
  UART_RST,
  UART_LOOPBACK
  );
  signal fsm_uart : fsm_uart_type := UART_RST;

  signal ck_rst_n_i      : std_logic := '1';
  signal rst             : std_logic := '0';
  signal uart_rx_r0      : std_logic := '1';
  signal uart_rx_r1      : std_logic := '1';

  signal rx_data_rd_sr   : std_logic_vector(1 downto 0) := (others=>'0');
  signal tx_data_wr_r    : std_logic := '0';
  signal tx_fifo_full_i  : std_logic := '0';
  signal rx_fifo_empty_i : std_logic := '0';
  signal rx_data_i       : std_logic_vector(7 downto 0) := (others=>'0');
  signal tx_data_r       : std_logic_vector(7 downto 0) := (others=>'0');

  constant MSG : string(1 to 32) := "Arty UART v1.0" & CR & LF & "--------------" & CR & LF;
  signal cnt_msg_r : integer range 0 to MSG'length-1 := 0;
begin
    
  -- External reset is active low. No sync flip-flop needed
  -- since the reset duration is ~1ms
  rst <= not ck_rst_n_ipad;

  -- Use a double flip-flop to synchronize the rx input
  -- to the FPGA clock
  proc_rx_dff:
  process(clk_100mhz_ipad)
  begin
    if rising_edge(clk_100mhz_ipad) then
      uart_rx_r0 <= uart_rx_ipad;
      uart_rx_r1 <= uart_rx_r0;
    end if;
  end process;


  proc_loopback:
  process(clk_100mhz_ipad)
  begin        
    if rising_edge(clk_100mhz_ipad) then
      
      -- default assignments
      rx_data_rd_sr <= rx_data_rd_sr(0) & '0';
      tx_data_wr_r <= '0';
  
      if (rst = '1') then
        cnt_msg_r <= 0;
        fsm_uart  <= UART_RST;
      else

        case fsm_uart is

        -- On reset transmit a "welcome" message before switching
        -- to loopback mode.
        when UART_RST =>
          if (tx_fifo_full_i='0') and (tx_data_wr_r='0') then
            tx_data_r    <= to_slv(MSG(cnt_msg_r+1), 8);
            tx_data_wr_r <= '1';
            if (cnt_msg_r = MSG'length-1) then
              cnt_msg_r <= 0;
              fsm_uart  <= UART_LOOPBACK;
            else
              cnt_msg_r <= cnt_msg_r + 1;
            end if;
          end if;

        -- Read a word from the Rx FIFO and pass it to the Tx FIFO.
        -- Transaction takes 2 clk cycles.
        when UART_LOOPBACK =>
          tx_data_wr_r <= rx_data_rd_sr(1);
          tx_data_r    <= rx_data_i;
          if (rx_fifo_empty_i = '0') and (rx_data_rd_sr(0) = '0') then
            rx_data_rd_sr <= rx_data_rd_sr(0) & '1';
          end if;

        end case;

      end if;
    end if;
  end process;

---------------------------------------------
-- UART
---------------------------------------------

  uart_inst : entity work.uart(rtl)
    generic map(
      G_BAUD_RATE  => 115200,
      G_CLOCK_FREQ => 100.0e6
    )
    port map(
      clk               => clk_100mhz_ipad,
      rst               => rst,
      tx_data_in        => tx_data_r,
      tx_data_wr_in     => tx_data_wr_r,
      tx_fifo_full_out  => tx_fifo_full_i,
      tx_out            => uart_tx_opad,
      rx_in             => uart_rx_r1,
      rx_data_rd_in     => rx_data_rd_sr(0),
      rx_data_out       => rx_data_i,
      rx_fifo_empty_out => rx_fifo_empty_i
    );


end architecture rtl;
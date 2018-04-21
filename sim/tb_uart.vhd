--------------------------------------------------------------------------------
--
--  UART Loopback Testbench
--
--  Self checking testbench that wires the UART in loopback configuration (Rx 
--  data is echoed back to Tx). An ASCII text is transmitted from the external
--  device and the testbench checks that the same text is received by the
--  external device.
--
--------------------------------------------------------------------------------
--  This work is licensed under the MIT License (see the LICENSE file for terms)
--  Copyright 2016 Lymperis Voudouris 
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;
use std.textio.all;

entity tb_uart is
end entity tb_uart;

architecture behv of tb_uart is  
    
  ------------------------------------------
  -- uart_tx
  ------------------------------------------
  -- Emulates an external UART device Tx
  --    txdata : Data to transmit
  --    tx     : Tx data line
  --    T_UART : UART period (bit duration)
  procedure uart_tx ( 
    variable txdata : in    std_logic_vector(7 downto 0); 
    signal   tx     : inout std_logic;
    constant T_UART : in    time) is 
  begin 
    tx <= '0'; -- start bit
    wait for T_UART;
    for i in 0 to 7 loop 
      tx <= txdata(i);
      wait for T_UART;
    end loop; 
    tx <= '1'; -- stop bit
    wait for T_UART;
  end uart_tx;

  ------------------------------------------
  -- uart_rx
  ------------------------------------------
  -- Emulates an external UART device Rx
  --    rx     : Rx data line
  --    rxdata : Data received
  --    T_UART : UART period (bit duration)
  procedure uart_rx ( 
    signal   rx     : in  std_logic;
    variable rxdata : out std_logic_vector(7 downto 0); 
    constant T_UART : in  time) is 
  begin
    wait until falling_edge(rx);
    wait for T_UART/2;
    
    for n in 0 to 7 loop
      wait for T_UART;
      rxdata(n) := rx;
    end loop;

    wait for T_UART;
    assert (rx = '1') report "Incorrect UART stop bit" severity error;
  end uart_rx;


  constant C_CLK_PERIOD  : time := 10 ns;  -- 100 MHz
  constant C_UART_PERIOD : time := 800 ns; -- 1.25 Mbaud

  signal clk             : std_logic := '0';
  signal rst             : std_logic := '0';
  signal tx_i            : std_logic := '1';
  signal tx_data_i       : std_logic_vector(7 downto 0) := (others=>'0');
  signal tx_data_wr_i    : std_logic := '0';
  signal tx_fifo_full_i  : std_logic := '0';
  signal rx_i            : std_logic := '1';
  signal rx_data_i       : std_logic_vector(7 downto 0) := (others=>'0');
  signal rx_data_rd_i    : std_logic := '0';
  signal rx_fifo_empty_i : std_logic := '0';

  signal transmitted_text : string(1 to 9) := "TEST_1234";

begin

  clk <= not clk after C_CLK_PERIOD/2;
  rst <= '1', '0' after 1000 ns;
  
  -- Loopback. Connect rx fifo output to tx fifo input
  tx_data_i <= rx_data_i;

  -- External device UART transmitter
  proc_external_uart_tx:
  process
    variable txdata : std_logic_vector(7 downto 0) := (others=>'0');
  begin
    wait until falling_edge(rst);
    
    -- transmit each character of the string (least significant char first)
    for n in transmitted_text'range loop
      wait for 133 ns; -- wait some arbitrary amount of time
      txdata := std_logic_vector(to_unsigned(character'pos(transmitted_text(n)), 8));
      uart_tx(txdata, rx_i, C_UART_PERIOD);
    end loop;
    wait;
  end process;

  -- Read/Write UART Rx/Tx FIFOs
  proc_loopback:
  process
  begin
    wait until falling_edge(rst);
    
    -- Repeat for every character
    for n in transmitted_text'range loop

      -- wait until rx fifo has some data
      if (rx_fifo_empty_i='1') then
        wait until rx_fifo_empty_i = '0';
      end if;
      
      -- Read pulse
      wait until rising_edge(clk);        
      rx_data_rd_i <= '1';
      wait until rising_edge(clk);
      rx_data_rd_i <= '0';
      
      -- check if tx fifo is full before writing
      -- any data (not really necessary in loopback
      -- configuration)
      if (tx_fifo_full_i = '1') then
        wait until tx_fifo_full_i = '0';
      end if;

      -- Write pulse
      wait until rising_edge(clk);
      tx_data_wr_i <= '1';
      wait until rising_edge(clk);
      tx_data_wr_i <= '0';

    end loop;
    
    wait;
  end process;

  -- External device UART receiver
  proc_external_uart_rx:
  process
    variable rxdata : std_logic_vector(7 downto 0) := (others=>'0');
    variable received_text : string(transmitted_text'range);
  begin
    -- Receive characters and store them in a string
    for n in transmitted_text'range loop
      uart_rx(tx_i, rxdata, C_UART_PERIOD);
      received_text(n) := character'val(to_integer(unsigned(rxdata)));
    end loop;

    -- Fail simulation if received text is not equal to the transmitted text
    assert (received_text = transmitted_text) 
      report "Received text: " & received_text & " is not equal to trasmitted text: " & transmitted_text
      severity failure;

    -- All is well. Report success
    assert false
      report "Successfuly received transmitted text: " & received_text
      severity note;

    wait;
  end process;


------------------------------------------------
-- UART
------------------------------------------------
  uart_inst : entity work.uart(rtl)
    generic map(
      G_BAUD_RATE  => 1250000,
      G_CLOCK_FREQ => 100.0e6
    )
    port map(
      clk               => clk,
      rst               => rst,
      tx_data_in        => tx_data_i,
      tx_data_wr_in     => tx_data_wr_i,
      tx_fifo_full_out  => tx_fifo_full_i,
      tx_out            => tx_i,
      rx_in             => rx_i,
      rx_data_rd_in     => rx_data_rd_i,
      rx_data_out       => rx_data_i,
      rx_fifo_empty_out => rx_fifo_empty_i
    );

end architecture behv;
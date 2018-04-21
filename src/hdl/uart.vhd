--------------------------------------------------------------------------------
--
--  UART top module
--
--  8 bit data, 1 stop bit, no parity. Intended for the Digilent Arty Artix-7
--  FPGA board, but can be easily used in other projects without modification.
--
--  Signals:
--    clk               : Clock of frequency G_CLOCK_FREQ
--    rst               : Active high synchronous reset
--    tx_data_in        : Tx data
--    tx_data_wr_in     : Tx data FIFO write enable
--    tx_fifo_full_out  : Tx FIFO full
--    tx_out            : Tx data line. Should be routed to the Rx pin
--                        of the external UART device.
--    rx_in             : Rx data line. Should be routed to the Tx pin
--                        of the external UART device.
--    rx_data_rd_in     : Rx FIFO read enable
--    rx_data_out       : Rx data
--    rx_fifo_empty_out : Rx FIFO empty
--
--  Parameters:
--    G_BAUD_RATE  : UART baud rate
--    G_CLOCK_FREQ : clk frequency. Can be fractional
--  
--  Data tranasction is done through small (16 deep) FIFOs. rx_data_out
--  is valid 1 clk cycle after rx_data_rd_in is asserted. Any attempt 
--  to read data when the Rx FIFO is empty is ignored (rx_data_out is
--  invalid). Any attempt to send more data while the Tx FIFO is full
--  is also ignored (data on tx_data_in is dropped).
--  
--  Optimally, the baud rate must be an integer multiple of the clock
--  frequency. If not, it's rounded to the closest integer. In such cases
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

entity uart is
  generic(
    G_BAUD_RATE  : positive := 1250000;
    G_CLOCK_FREQ : real     := 100.0e6
  );
  port(
    clk               : in  std_logic;
    rst               : in  std_logic;
    tx_data_in        : in  std_logic_vector(7 downto 0);
    tx_data_wr_in     : in  std_logic;
    tx_fifo_full_out  : out std_logic;
    tx_out            : out std_logic;
    rx_in             : in  std_logic;
    rx_data_rd_in     : in  std_logic;
    rx_data_out       : out std_logic_vector(7 downto 0);
    rx_fifo_empty_out : out std_logic
  );
end entity uart;

architecture rtl of uart is

  signal fifo_tx_dout_i  : std_logic_vector(7 downto 0) := (others=>'0');
  signal fifo_tx_full_i  : std_logic := '0';
  signal fifo_tx_rd_en_r : std_logic := '0';
  signal fifo_tx_empty_i : std_logic := '0';
  signal tx_en_r         : std_logic := '0';
  signal tx_ready_i      : std_logic := '0';

  signal fifo_rx_din_r   : std_logic_vector(7 downto 0) := (others=>'0');
  signal fifo_rx_wr_en_r : std_logic := '0';
  signal fifo_rx_full_i  : std_logic := '0';
  signal fifo_rx_empty_i : std_logic := '0';
  signal rx_data_i       : std_logic_vector(7 downto 0) := (others=>'0');
  signal rx_valid_i      : std_logic := '0';

begin

---------------------------------------------
-- Tx
---------------------------------------------

  tx_fifo_full_out <= fifo_tx_full_i;

  fifo_tx_inst : entity work.fifo_srl(rtl)
    generic map(
      G_DATA_WIDTH => 8,
      G_DEPTH      => 16
    )
    port map(
      clk    => clk,
      rst    => rst,
      din    => tx_data_in,
      wr_en  => tx_data_wr_in,
      full   => fifo_tx_full_i,
      dout   => fifo_tx_dout_i,
      rd_en  => fifo_tx_rd_en_r,
      empty  => fifo_tx_empty_i
    );

  proc_fifo_tx:
  process(clk)
  begin
    if rising_edge(clk) then
        
      tx_en_r <= fifo_tx_rd_en_r;

      if (rst = '1') then
        fifo_tx_rd_en_r <= '0';
      else
          
        -- Fetch new data from the FIFO only when the FIFO is not empty and
        -- the Tx is not busy. Allow one clk cycle for the data to be fetched and
        -- one more for tx_ready to update.
        fifo_tx_rd_en_r <= '0';
        if (tx_ready_i = '1') and (fifo_tx_empty_i = '0') and (fifo_tx_rd_en_r='0') and (tx_en_r='0') then
          fifo_tx_rd_en_r <= '1';
        end if;

      end if;
    end if;
  end process;

  uart_tx_inst : entity work.uart_tx(rtl)
    generic map(
      G_BAUD_RATE  => G_BAUD_RATE,
      G_CLOCK_FREQ => G_CLOCK_FREQ
    )
    port map(
      clk          => clk,
      rst          => rst,
      tx_data_in   => fifo_tx_dout_i,
      tx_en_in     => tx_en_r,
      tx_ready_out => tx_ready_i,
      tx_out       => tx_out
    );


---------------------------------------------
-- Rx
---------------------------------------------

  rx_fifo_empty_out <= fifo_rx_empty_i;

  fifo_rx_inst : entity work.fifo_srl(rtl)
    generic map(
      G_DATA_WIDTH => 8,
      G_DEPTH      => 16
    )
    port map(
      clk    => clk,
      rst    => rst,
      din    => fifo_rx_din_r,
      wr_en  => fifo_rx_wr_en_r,
      full   => fifo_rx_full_i,
      dout   => rx_data_out,
      rd_en  => rx_data_rd_in,
      empty  => fifo_rx_empty_i
    );

  proc_fifo_rx:
  process(clk)
  begin
    if rising_edge(clk) then
      if (rst = '1') then
        fifo_rx_wr_en_r <= '0';
      else
        fifo_rx_din_r <= rx_data_i;
        
        -- Write data to the FIFO only when the FIFO is not full and
        -- the Rx has valid data.
        fifo_rx_wr_en_r <= '0';
        if (rx_valid_i = '1') and (fifo_rx_full_i = '0') then
          fifo_rx_wr_en_r <= '1';
        end if;

      end if;
    end if;
  end process;

  uart_rx_inst: entity work.uart_rx(rtl)
    generic map(
      G_BAUD_RATE  => G_BAUD_RATE,
      G_CLOCK_FREQ => G_CLOCK_FREQ
    )
    port map(
      clk          => clk,
      rst          => rst,
      rx_in        => rx_in,
      rx_data_out  => rx_data_i,
      rx_valid_out => rx_valid_i
    );

end architecture rtl;
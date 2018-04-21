--------------------------------------------------------------------------------
--
--  Shift register (SRL) based synchronous FIFO
--
--  Signals:
--    clk   : clock
--    rst   : synchronous reset (active high)
--    din   : data input
--    wr_en : write enable
--    full  : FIFO full flag
--    dout  : data output
--    rd_en : read enable
--    empty : FIFO empty flag
--
--  Parameters:
--    G_DATA_WIDTH : Bit width of the data input/output
--    G_DEPTH      : FIFO depth
--  
--  This design takes advantage of the SRL blocks in Xilinx FPGAs. Optimal
--  G_DEPTH is 16 (SRL16) or 32 (SRL32). 
--
--  Read/Write:
--  dout is valid 1 clk cycle after rd_en goes high. din is written into the
--  FIFO 1 clk cycle after wr_en goes high.
--  Simultaneous rd/wr operations do not change the state of the FIFO (ie. FIFO
--  will not go empty or full)
--
--  Empty/Full flags
--  At reset empty flag is set high and full low. Empty flag goes low 1 clk cycle
--  after the first wr_en and high after the last valid rd_en. Full goes high 1
--  clk cycle after the last valid wr_en and low after the first rd_en.
--  Any subsequent rd_en/wr_en when empty/full respecively is ignored and FIFO
--  state doesn't change (ie. it stays empty or full)
--
--  Arty FPGA board specific notes:
--  Vivado infers SRL blocks (SRL16 when using the default G_DEPTH=16). Should
--  work for other Xilinx FPGAs as well. Should be slightly faster than an 
--  equivalent distributed RAM impelementation for depths up to 32 words. Same
--  type of FIFO can be generated using the Xilinx FIFO generator (if you don't
--  mind the device specific netlist).
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

entity fifo_srl is
  generic(
    G_DATA_WIDTH : positive := 8;
    G_DEPTH      : positive := 16
  );
  port(
    clk    : in  std_logic;
    rst    : in  std_logic;
    din    : in  std_logic_vector(G_DATA_WIDTH-1 downto 0);
    wr_en  : in  std_logic;
    full   : out std_logic;
    dout   : out std_logic_vector(G_DATA_WIDTH-1 downto 0);
    rd_en  : in  std_logic;
    empty  : out std_logic
  );
end entity fifo_srl;

architecture rtl of fifo_srl is
  constant C_ADDR_WIDTH : natural := natural(ceil(log2(real(G_DEPTH))));

  type srl16_array is array (G_DEPTH-1 downto 0) of std_logic_vector (G_DATA_WIDTH-1 downto 0);
  signal fifo : srl16_array := (others=>(others=>'0'));

  signal ptr     : unsigned(C_ADDR_WIDTH-1 downto 0) := (others=>'0');
  signal inc_ptr : unsigned(C_ADDR_WIDTH-1 downto 0) := (others=>'0');
  signal dec_ptr : unsigned(C_ADDR_WIDTH-1 downto 0) := (others=>'0');
  signal empty_r : std_logic := '1';
  signal full_r  : std_logic := '0';
  signal wr_rd   : std_logic_vector(1 downto 0) := "00";
begin
    
  wr_rd   <= wr_en & rd_en;
  inc_ptr <= ptr + 1;
  dec_ptr <= ptr - 1;

  proc_data:
  process(clk)
  begin
    if rising_edge(clk) then
      if (rst = '1') then
        ptr     <= (others=>'0');
        full_r  <= '0';
        empty_r <= '1';
      else
        case wr_rd is
        
        -- Read operation
        -- Read the data and decrement the pointer if not empty.
        -- FIFO is empty if the next pointer decrement reaches zero.
        when "01" =>
          if (empty_r = '0') then
            dout <= fifo(to_integer(dec_ptr));
            ptr  <= dec_ptr;
          end if;

          full_r <= '0';
          if (dec_ptr = 0) then
            empty_r <= '1';
          end if;

        -- Write operation
        -- Write the data and increment the pointer if not full.
        -- FIFO is full if the next pointer increment reaches zero.
        when "10" =>
          if (full_r = '0') then
            fifo <= fifo(G_DEPTH-2 downto 0) & din;
            ptr  <= inc_ptr;
          end if;

          empty_r <= '0';                   
          if (inc_ptr = 0) then
            full_r <= '1';
          end if;

        -- Simultaneous read/write
        -- Read and write data without moving the pointer
        when "11" =>
          fifo <= fifo(G_DEPTH-2 downto 0) & din;
          dout <= fifo(to_integer(dec_ptr));

        -- No operation
        when others =>
          null;

        end case;

      end if;
    end if;
  end process;

  full  <= full_r;
  empty <= empty_r;

end architecture rtl;
--------------------------------------------------------------------------------
--
--  RAM based synchronous FIFO
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
--  Vivado infers a distributed (LUT based) RAM or a BRAM depending on the depth
--  and bit width. Using the default parameters (G_DEPTH=16 anf G_DATA_WIDTH=8)
--  will always infer distributed RAM. Should work with most Xilinx FPGAs.
--
--------------------------------------------------------------------------------
--  This work is licensed under the MIT License (see the LICENSE file for terms)
--  Copyright 2016 Lymperis Voudouris 
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity fifo_ram is
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
end entity fifo_ram;

architecture rtl of fifo_ram is
  constant C_ADDR_WIDTH : natural := natural(ceil(log2(real(G_DEPTH))));

  type ram_array is array (G_DEPTH-1 downto 0) of std_logic_vector (G_DATA_WIDTH-1 downto 0);
  signal fifo : ram_array := (others=>(others=>'0'));

  signal wr_ptr      : unsigned(C_ADDR_WIDTH-1 downto 0) := (others=>'0');
  signal rd_ptr      : unsigned(C_ADDR_WIDTH-1 downto 0) := (others=>'0');
  signal next_wr_ptr : unsigned(C_ADDR_WIDTH-1 downto 0) := (others=>'0');
  signal next_rd_ptr : unsigned(C_ADDR_WIDTH-1 downto 0) := (others=>'0');
  signal empty_r     : std_logic := '1';
  signal full_r      : std_logic := '0';
begin
    
  next_wr_ptr <= wr_ptr + 1;
  next_rd_ptr <= rd_ptr + 1;

  proc_wr_data:
  process(clk)
  begin
    if rising_edge(clk) then
      if (rst = '1') then
        wr_ptr <= (others=>'0');
      else
        -- Write operation is valid when the FIFO is not full or
        -- when there's a simultaneous read operation 
        if (wr_en = '1') and ((full_r = '0') or (rd_en='1')) then
         fifo(to_integer(wr_ptr)) <= din;
         wr_ptr <= next_wr_ptr;
        end if;
      end if;
    end if;
  end process;


  proc_rd_data:
  process(clk)
  begin
    if rising_edge(clk) then
      if (rst = '1') then
        rd_ptr <= (others=>'0');
      else
        -- Read operation is valid when the FIFO is not empty or
        -- when there's a simultaneous write operation 
        if (rd_en = '1') and ((empty_r = '0') or (wr_en='1'))  then
         dout   <= fifo(to_integer(rd_ptr));
         rd_ptr <= next_rd_ptr;
        end if;
      end if;
    end if;
  end process;


  proc_flags:
  process(clk)
  begin
    if rising_edge(clk) then
      if (rst = '1') then
        full_r  <= '0';
        empty_r <= '1';
      else
        if (wr_en = '1') and (rd_en = '0') then
          empty_r <= '0';
          if (next_wr_ptr = rd_ptr) then
            full_r <= '1';
          end if;

        elsif (wr_en = '0') and (rd_en = '1') then
          full_r <= '0';
          if (next_rd_ptr = wr_ptr) then
            empty_r <= '1';
          end if;

        end if;
      end if;
    end if;
  end process;


  full  <= full_r;
  empty <= empty_r;

end architecture rtl;
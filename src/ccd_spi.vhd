-------------------------------------------------------------------------
-- Company     : Yansar
-- Engineer    : Golovachenko Victor
--
-- Create Date : 19.06.2014 11:14:45
-- Module Name : ccd_spi
--
-- Назначение/Описание :
--
--
-- Revision:
-- Revision 0.01 - File Created
--
-------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.spi_pkg.all;
use work.vicg_common_pkg.all;

entity ccd_spi is
generic(
G_SIM : string := "OFF"
);
port(
p_out_physpi    : out  TSPI_pinout;
p_in_physpi     : in   TSPI_pinin;

p_in_fifo_dout  : in   std_logic_vector(15 downto 0);
p_out_fifo_rd   : out  std_logic;
p_in_fifo_empty : in   std_logic;

p_out_init_done : out  std_logic;

p_out_tst       : out  std_logic_vector(31 downto 0);
p_in_tst        : in   std_logic_vector(31 downto 0);

p_in_clk        : in   std_logic;
p_in_rst        : in   std_logic
);
end;

architecture behavior of ccd_spi is

type TCCD_RegINIT is array (0 to 19) of std_logic_vector(24 downto 0);

constant CI_CCD_REGINIT : TCCD_RegINIT := (
std_logic_vector(TO_UNSIGNED(10#002#, 9)) & std_logic_vector(TO_UNSIGNED(16#0001#, 16)),
std_logic_vector(TO_UNSIGNED(10#032#, 9)) & std_logic_vector(TO_UNSIGNED(16#2002#, 16)),
std_logic_vector(TO_UNSIGNED(10#034#, 9)) & std_logic_vector(TO_UNSIGNED(16#0001#, 16)),
std_logic_vector(TO_UNSIGNED(10#065#, 9)) & std_logic_vector(TO_UNSIGNED(16#008B#, 16)),
std_logic_vector(TO_UNSIGNED(10#066#, 9)) & std_logic_vector(TO_UNSIGNED(16#53C6#, 16)),
std_logic_vector(TO_UNSIGNED(10#067#, 9)) & std_logic_vector(TO_UNSIGNED(16#0844#, 16)),
std_logic_vector(TO_UNSIGNED(10#068#, 9)) & std_logic_vector(TO_UNSIGNED(16#0086#, 16)),
std_logic_vector(TO_UNSIGNED(10#128#, 9)) & std_logic_vector(TO_UNSIGNED(16#4520#, 16)),
std_logic_vector(TO_UNSIGNED(10#204#, 9)) & std_logic_vector(TO_UNSIGNED(16#09E5#, 16)),
std_logic_vector(TO_UNSIGNED(10#224#, 9)) & std_logic_vector(TO_UNSIGNED(16#3E04#, 16)),
std_logic_vector(TO_UNSIGNED(10#225#, 9)) & std_logic_vector(TO_UNSIGNED(16#6733#, 16)),
std_logic_vector(TO_UNSIGNED(10#129#, 9)) & std_logic_vector(TO_UNSIGNED(16#C001#, 16)),
std_logic_vector(TO_UNSIGNED(10#447#, 9)) & std_logic_vector(TO_UNSIGNED(16#0BF1#, 16)),
std_logic_vector(TO_UNSIGNED(10#448#, 9)) & std_logic_vector(TO_UNSIGNED(16#0BC3#, 16)),
std_logic_vector(TO_UNSIGNED(10#032#, 9)) & std_logic_vector(TO_UNSIGNED(16#2003#, 16)),
std_logic_vector(TO_UNSIGNED(10#064#, 9)) & std_logic_vector(TO_UNSIGNED(16#0001#, 16)),
std_logic_vector(TO_UNSIGNED(10#040#, 9)) & std_logic_vector(TO_UNSIGNED(16#0003#, 16)),
std_logic_vector(TO_UNSIGNED(10#048#, 9)) & std_logic_vector(TO_UNSIGNED(16#0001#, 16)),
std_logic_vector(TO_UNSIGNED(10#112#, 9)) & std_logic_vector(TO_UNSIGNED(16#0007#, 16)),
std_logic_vector(TO_UNSIGNED(10#192#, 9)) & std_logic_vector(TO_UNSIGNED(16#0000#, 16))  --Reg 192[0]=1 - Start Image Capture CCD
);

component spi_core is
generic(
G_AWIDTH : integer := 16;
G_DWIDTH : integer := 16
);
port(
p_in_adr    : in   std_logic_vector(G_AWIDTH - 1 downto 0);
p_in_data   : in   std_logic_vector(G_DWIDTH - 1 downto 0); --FPGA -> DEV
p_out_data  : out  std_logic_vector(G_DWIDTH - 1 downto 0); --FPGA <- DEV
p_in_dir    : in   std_logic;
p_in_start  : in   std_logic;

p_out_busy  : out  std_logic;

p_out_physpi : out TSPI_pinout;
p_in_physpi  : in  TSPI_pinin;

p_out_tst    : out std_logic_vector(31 downto 0);
p_in_tst     : in  std_logic_vector(31 downto 0);

p_in_clk_en : in   std_logic;
p_in_clk    : in   std_logic;
p_in_rst    : in   std_logic
);
end component;

type TFsm_spireg is (
S_IDLE,
S_REG_INIT_SET,
S_REG_INIT_START,
S_REG_INIT_DONE,
S_REG_USR
);

signal i_fsm_spi_cs : TFsm_spireg;

signal i_clkcnt     : unsigned(4 downto 0) := (others => '0');
signal i_clk_en     : std_logic := '0';

signal i_busy       : std_logic := '0';
signal i_dir        : std_logic := '0';
signal i_start      : std_logic := '0';
signal i_adr        : std_logic_vector(8 downto 0) := (others => '0');
signal i_txd        : std_logic_vector(15 downto 0) := (others => '0');
signal i_rxd        : std_logic_vector(15 downto 0) := (others => '0');

signal i_cnt        : unsigned(4 downto 0) := (others => '0');

signal i_init_done  : std_logic := '0';


--MAIN
begin

p_out_tst <= (others => '0');

p_out_init_done <= i_init_done;

process(p_in_clk)
begin
  if rising_edge(p_in_clk) then
    i_clkcnt <= i_clkcnt + 1;

    if i_clkcnt = (i_clkcnt'range => '1') then
      i_clk_en <= '1';
    else
      i_clk_en <= '0';
    end if;
  end if;
end process;


process(p_in_clk)
begin
  if rising_edge(p_in_clk) then
    if p_in_rst = '1' then
      i_cnt <= (others => '0');
      i_adr <= (others => '0');
      i_txd <= (others => '0');
      i_dir <= '0';
      i_start <= '0';
      i_init_done <= '0';
      i_fsm_spi_cs <= S_IDLE;

    else
      if i_clk_en = '1' then

        case i_fsm_spi_cs is

          when S_IDLE =>

            if i_cnt = (i_cnt'range => '1') then
              i_cnt <= (others => '0');
              i_fsm_spi_cs <= S_REG_INIT_SET;

            else
              i_cnt <= i_cnt + 1;

            end if;

          --------------------------------
          --CCD (Power UP)
          --------------------------------
          when S_REG_INIT_SET =>

            for i in 0 to CI_CCD_REGINIT'length - 1 loop
              if i_cnt = i then
                i_adr <= CI_CCD_REGINIT(i)(24 downto 16);
                i_txd <= CI_CCD_REGINIT(i)(15 downto 0);
              end if;
            end loop;

            i_cnt <= i_cnt + 1;

            i_dir <= C_SPI_WRITE;
            i_start <= '1';
            i_fsm_spi_cs <= S_REG_INIT_START;

          when S_REG_INIT_START =>

            i_start <= '0';
            i_fsm_spi_cs <= S_REG_INIT_DONE;

          when S_REG_INIT_DONE =>

            if i_busy = '0' then
              if i_cnt = TO_UNSIGNED(CI_CCD_REGINIT'length - 1, i_cnt'length) then
                i_init_done <= '1';
                i_fsm_spi_cs <= S_REG_USR;
              else
                i_fsm_spi_cs <= S_REG_INIT_SET;
              end if;
            end if;


          --------------------------------
          --CCD User Reg Control
          --------------------------------
          when S_REG_USR =>
            i_dir <= C_SPI_WRITE;
            i_start <= '0';

        end case;

      end if; --if i_clk_en = '1' then
    end if;
  end if;
end process;


m_spi_core : spi_core
generic map(
G_AWIDTH => 9 ,
G_DWIDTH => 16
)
port map(
p_in_adr    => i_adr,
p_in_data   => i_txd,
p_out_data  => i_rxd,
p_in_dir    => i_dir,
p_in_start  => i_start,

p_out_busy  => i_busy,

p_out_physpi => p_out_physpi,
p_in_physpi  => p_in_physpi,

p_out_tst    => open,
p_in_tst     => (others => '0'),

p_in_clk_en => i_clk_en,
p_in_clk    => p_in_clk,
p_in_rst    => p_in_rst
);


--END MAIN
end architecture;

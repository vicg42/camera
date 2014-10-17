-------------------------------------------------------------------------
-- Company     : Yansar
-- Engineer    : Golovachenko Victor
--
-- Create Date : 13.06.2014 15:08:42
-- Module Name : ccd_vita25K
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
use work.ccd_pkg.all;
use work.prj_cfg.all;
use work.spi_pkg.all;
use work.vicg_common_pkg.all;
use work.reduce_pack.all;

entity ccd_vita25K is
generic(
G_SIM : string := "OFF"
);
port(
p_in_ccd       : in   TCCD_pinin;
p_out_ccd      : out  TCCD_pinout;

p_out_vfr_data : out  std_logic_vector(((C_PCFG_CCD_LVDS_COUNT - C_PCFG_CCD_SYNC_LINE_COUNT)
                                          * selval(16, 32, C_PCFG_VD_BIT_PER_PIXEL = 8)) - 1 downto 0);
p_out_vfr_den  : out  std_logic;
p_out_vfr_vs   : out  std_logic;
p_out_vfr_hs   : out  std_logic;
p_out_vfr_clk  : out  std_logic;

p_out_status   : out  std_logic_vector(C_CCD_STATUS_LAST_BIT downto 0);

p_out_tst      : out  std_logic_vector(31 downto 0);
p_in_tst       : in   std_logic_vector(31 downto 0);

p_in_refclk    : in   std_logic;
p_in_ccdclk    : in   std_logic;
p_in_rst       : in   std_logic
);
end;

architecture behavior of ccd_vita25K is

component ccd_spi
generic(
G_SPI_WRITE : std_logic := '1';
G_SIM : string := "OFF"
);
port(
p_out_physpi    : out  TSPI_pinout;
p_in_physpi     : in   TSPI_pinin;
--p_out_ccdrst_n  : out  std_logic;

--p_in_fifo_dout  : in   std_logic_vector(15 downto 0);
--p_out_fifo_rd   : out  std_logic;
--p_in_fifo_empty : in   std_logic;

p_in_deser_rdy  : in   std_logic;
p_in_align      : in   std_logic;
p_out_init_done : out  std_logic;
p_out_err       : out  std_logic;

p_out_tst       : out   std_logic_vector(31 downto 0);
p_in_tst        : in    std_logic_vector(31 downto 0);

p_in_clk        : in   std_logic;
p_in_rst        : in   std_logic
);
end component;

component ccd_fg
generic(
G_SYNC_LINE_COUNT : integer := 1;
G_LVDS_CH_COUNT : integer := 16;
G_CCD_BIT_COUNT : integer := 10;
G_VD_BIT_COUNT : integer := 10
);
port(
p_in_ccd        : in    TCCD_pinin;
p_out_ccd       : out   TCCD_pinout;

p_out_vfr_data  : out  std_logic_vector(((G_LVDS_CH_COUNT - G_SYNC_LINE_COUNT)
                                          * selval(16, 32, G_VD_BIT_COUNT = 8)) - 1 downto 0);
p_out_vfr_den   : out   std_logic;
p_out_vfr_vs    : out   std_logic;
p_out_vfr_hs    : out   std_logic;
p_out_vfr_clk   : out   std_logic;

p_out_status    : out   std_logic_vector(C_CCD_FG_STATUS_LAST_BIT downto 0);

p_out_tst       : out   std_logic_vector(31 downto 0);
p_in_tst        : in    std_logic_vector(31 downto 0);

p_in_ccdinit    : in    std_logic;
p_in_ccdclk     : in    std_logic;
p_in_refclk     : in    std_logic;
p_in_rst        : in    std_logic
);
end component;

signal i_ccd_out        : TCCD_pinout;
signal i_spi_out        : TSPI_pinout;
signal i_spi_in         : TSPI_pinin;

signal i_rstcnt         : unsigned(20 downto 0) := (others => '0');
signal i_ccd_rst_n      : std_logic;
signal i_ccd_rst        : std_logic;
signal i_ccd_init_done  : std_logic;
signal i_ccd_spi_err    : std_logic;

signal i_ccd_fg_status  : std_logic_vector(C_CCD_FG_STATUS_LAST_BIT downto 0);

signal i_tst_spi_out    : std_logic_vector(31 downto 0);
signal i_tst_fg_out     : std_logic_vector(31 downto 0);




--MAIN
begin

p_out_tst(3 downto 0) <= i_tst_fg_out(3 downto 0);
p_out_tst(7 downto 4) <= (others => '0');
p_out_tst(8) <= '0';
p_out_tst(9) <= '0';
p_out_tst(31 downto 16) <= i_tst_spi_out(15 downto 0);

p_out_status(C_CCD_STATUS_INIT_OK_BIT) <= i_ccd_init_done;
p_out_status(C_CCD_STATUS_ALIGN_OK_BIT) <= i_ccd_fg_status(C_CCD_FG_STATUS_ALIGN_OK_BIT);


p_out_ccd.clk_p <= i_ccd_out.clk_p;
p_out_ccd.clk_n <= i_ccd_out.clk_n;

--deasert reset ccd after input clock ccd enable > 10us
p_out_ccd.rst_n <= i_ccd_rst_n;
p_out_ccd.trig <= '0';

p_out_ccd.sck  <= i_spi_out.sck;
p_out_ccd.ss_n <= i_spi_out.ss_n;
p_out_ccd.mosi <= i_spi_out.mosi;

i_spi_in.miso <= p_in_ccd.miso;


--process(p_in_rst, p_in_ccdclk)
--begin
--  if rising_edge(p_in_ccdclk) then
--    if p_in_rst = '1' then
--      i_rstcnt <= (others => '0');
--    else
--      if i_rstcnt(selval(19, 8, strcmp(G_SIM, "OFF"))) /= '1' then
--        i_rstcnt <= i_rstcnt + 1;
--      end if;
--    end if;
--  end if;
--end process;

i_ccd_rst_n <= '1';--i_rstcnt( selval(19, 8, strcmp(G_SIM, "OFF")) );
--i_ccd_rst <= not i_rstcnt( selval(19, 8, strcmp(G_SIM, "OFF")) );


--####################################
--Program internal register of CCD
--####################################
m_spi : ccd_spi
generic map(
G_SPI_WRITE => '1',
G_SIM => G_SIM
)
port map(
p_out_physpi    => i_spi_out,
p_in_physpi     => i_spi_in ,
--p_out_ccdrst_n  => open,--i_ccd_rst_n,

--p_in_fifo_dout  => (others => '0'),
--p_out_fifo_rd   => open,
--p_in_fifo_empty => '0',

p_in_deser_rdy  => i_ccd_fg_status(C_CCD_FG_STATUS_DRY_BIT),
p_in_align      => i_ccd_fg_status(C_CCD_FG_STATUS_ALIGN_OK_BIT),
p_out_init_done => i_ccd_init_done,
p_out_err       => i_ccd_spi_err,

p_out_tst       => i_tst_spi_out,
p_in_tst        => p_in_tst(31 downto 0),

p_in_clk        => p_in_ccdclk,
p_in_rst        => p_in_rst
);


--####################################
--Recieve video data from CCD
--####################################
m_fg : ccd_fg
generic map(
G_SYNC_LINE_COUNT => C_PCFG_CCD_SYNC_LINE_COUNT,
G_LVDS_CH_COUNT => C_PCFG_CCD_LVDS_COUNT,
G_CCD_BIT_COUNT => C_PCFG_CCD_BIT_PER_PIXEL,
G_VD_BIT_COUNT => C_PCFG_VD_BIT_PER_PIXEL
)
port map(
p_in_ccd        => p_in_ccd,
p_out_ccd       => i_ccd_out,

p_out_vfr_data  => p_out_vfr_data,
p_out_vfr_den   => p_out_vfr_den ,
p_out_vfr_vs    => p_out_vfr_vs  ,
p_out_vfr_hs    => p_out_vfr_hs  ,
p_out_vfr_clk   => p_out_vfr_clk ,

p_out_status    => i_ccd_fg_status,

p_out_tst       => i_tst_fg_out,
p_in_tst        => i_tst_spi_out,--p_in_tst(31 downto 0),

p_in_ccdinit    => i_ccd_init_done,
p_in_ccdclk     => p_in_ccdclk,
p_in_refclk     => p_in_refclk,
p_in_rst        => p_in_rst
);

--END MAIN
end architecture;

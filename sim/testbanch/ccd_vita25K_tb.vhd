library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.reduce_pack.all;
use work.vicg_common_pkg.all;
use work.prj_cfg.all;
use work.ccd_vita25K_pkg.all;
use work.clocks_pkg.all;

entity ccd_vita25K_tb is
port(
pin_out_syn    : out std_logic;
pin_out_tp     : out std_logic_vector((C_PCFG_CCD_DATA_LINE_COUNT
                                                * C_PCFG_CCD_BIT_PER_PIXEL) - 1 downto 0)
);
end ccd_vita25K_tb;

architecture test of ccd_vita25K_tb is

component ccd_vita25K is
generic(
G_SIM : string := "OFF"
);
port(
p_in_ccd   : in   TCCD_pinin;
p_out_ccd  : out  TCCD_pinout;

p_out_video_vs  : out std_logic;
p_out_video_hs  : out std_logic;
p_out_video_den : out std_logic;
p_out_video_d   : out std_logic_vector((C_PCFG_CCD_LVDS_COUNT
                                          * C_PCFG_CCD_BIT_PER_PIXEL) - 1 downto 0);
p_out_video_clk : out std_logic;

p_out_tst       : out   std_logic_vector(31 downto 0);
p_in_tst        : in    std_logic_vector(31 downto 0);

p_in_refclk : in   std_logic;
p_in_ccdclk : in   std_logic;
p_in_rst    : in   std_logic
);
end component;

component clocks is
port(
p_out_rst  : out   std_logic;
p_out_gclk : out   std_logic_vector(7 downto 0);

p_in_clk   : in    TRefclk_pinin
);
end component;

constant CI_CLK_PERIOD         : time := 10 ns; -- 100 MHz clk


signal i_clk    : std_logic := '0';
signal i_rst    : std_logic := '0';

signal pin_in_ccd         : TCCD_pinin;
signal pin_out_ccd        : TCCD_pinout;

signal pin_in_refclk      : TRefclk_pinin;

signal g_usrclk           : std_logic_vector(7 downto 0);
signal i_video_d          : std_logic_vector((C_PCFG_CCD_LVDS_COUNT
                                               * C_PCFG_CCD_BIT_PER_PIXEL) - 1 downto 0);
signal i_video_d_clk      : std_logic;
signal i_video_vs         : std_logic;
signal i_video_hs         : std_logic;
signal i_video_den        : std_logic;



begin


process begin
  wait for (CI_CLK_PERIOD/2);
  i_clk <= not i_clk;
end process;

pin_in_refclk.clk(0) <= i_clk;
pin_in_refclk.clk(1) <= i_clk;
pin_in_refclk.clk(2) <= i_clk;

gen_ccd_data : for i in 0 to pin_in_ccd.data_p'length - 1 generate begin
pin_in_ccd.data_p(i) <= '1';
pin_in_ccd.data_n(i) <= '1';
end generate;

pin_in_ccd.clk_p <= pin_out_ccd.clk_p;
pin_in_ccd.clk_n <= pin_out_ccd.clk_n;

pin_in_ccd.miso <= pin_out_ccd.mosi;


--***********************************************************
--Установка частот проекта:
--***********************************************************
m_clocks : clocks
port map(
p_out_rst  => i_rst,
p_out_gclk => g_usrclk,

p_in_clk   => pin_in_refclk
);


--***********************************************************
--Установка частот проекта:
--***********************************************************
m_ccd : ccd_vita25K
generic map(
G_SIM => "ON"
)
port map(
p_in_ccd  => pin_in_ccd,
p_out_ccd => pin_out_ccd,

p_out_video_vs  => i_video_vs,
p_out_video_hs  => i_video_hs,
p_out_video_den => i_video_den,
p_out_video_d   => i_video_d,
p_out_video_clk => i_video_d_clk,

p_out_tst       => open,
p_in_tst        => (others => '0'),

p_in_refclk => g_usrclk(0),
p_in_ccdclk => g_usrclk(1),
p_in_rst    => i_rst
);


gen_tp : for i in 1 to (C_PCFG_CCD_LVDS_COUNT - 1) generate
pin_out_tp(i - 1) <= OR_reduce(i_video_d((C_PCFG_CCD_BIT_PER_PIXEL * (i + 1)) - 1 downto (C_PCFG_CCD_BIT_PER_PIXEL * i)));
end generate;

pin_out_syn <= i_video_den or i_video_hs or i_video_vs;



end test;


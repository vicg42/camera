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
use work.ccd_vita25K_pkg.all;
use work.prj_cfg.all;

entity ccd_vita25K is
port(
p_in_ccd   : in   TCCD_PortIN;
p_out_ccd  : out  TCCD_PortOUT;

p_out_video_vs  : out std_logic;
p_out_video_hs  : out std_logic;
p_out_video_den : out std_logic;
p_out_video_d   : out std_logic_vector((C_PCFG_CCD_LVDS_COUNT
                                          * C_PCFG_CCD_BIT_PER_PIXEL) - 1 downto 0);
p_out_video_clk : out std_logic;

p_in_refclk : in   std_logic;
p_in_ccdclk : in   std_logic;
p_in_rst    : in   std_logic
);
end;

architecture behavior of ccd_vita25K is

component ccd_deser
generic(
G_LVDS_CH_COUNT : integer := 16;
G_BIT_COUNT     : integer := 10
);
port(
p_in_ccd        : in    TCCD_PortIN;
p_out_ccd       : out   TCCD_PortOUT;

p_out_video_vs  : out   std_logic;
p_out_video_hs  : out   std_logic;
p_out_video_den : out   std_logic;
p_out_video_d   : out   std_logic_vector((G_LVDS_CH_COUNT * G_BIT_COUNT) - 1 downto 0);
p_out_video_clk : out   std_logic;

p_in_ccdclk     : in    std_logic;
p_in_refclk     : in    std_logic;
p_in_rst        : in    std_logic
);
end component;

signal i_video_vs       : std_logic;
signal i_video_hs       : std_logic;
signal i_video_den      : std_logic;
signal i_video_d        : std_logic_vector((C_PCFG_CCD_LVDS_COUNT
                                                * C_PCFG_CCD_BIT_PER_PIXEL) - 1 downto 0);
signal i_video_clk      : std_logic;

signal i_out_ccd        : TCCD_PortOUT;

--MAIN
begin


p_out_ccd.clk_p <= i_out_ccd.clk_p;
p_out_ccd.clk_n <= i_out_ccd.clk_n;
p_out_ccd.rst_n <= '1';
p_out_ccd.trig <= '1';

m_deser : ccd_deser
generic map(
G_LVDS_CH_COUNT => C_PCFG_CCD_LVDS_COUNT,
G_BIT_COUNT     => C_PCFG_CCD_BIT_PER_PIXEL
)
port map(
p_in_ccd        => p_in_ccd,
p_out_ccd       => i_out_ccd,

p_out_video_vs  => i_video_vs,
p_out_video_hs  => i_video_hs,
p_out_video_den => i_video_den,
p_out_video_d   => i_video_d,
p_out_video_clk => i_video_clk,

p_in_ccdclk     => p_in_ccdclk,
p_in_refclk     => p_in_refclk,
p_in_rst        => p_in_rst
);

p_out_video_vs  <= i_video_vs;
p_out_video_hs  <= i_video_hs;
p_out_video_den <= i_video_den;
p_out_video_d <= i_video_d;
p_out_video_clk <= i_video_clk;


--END MAIN
end architecture;

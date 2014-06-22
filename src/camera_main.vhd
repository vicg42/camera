-------------------------------------------------------------------------
-- Company     : Yansar
-- Engineer    : Golovachenko Victor
--
-- Create Date : 13.06.2014 12:31:35
-- Module Name : caamera_main
--
-- Назначение/Описание :
--
-- Revision:
-- Revision 0.01 - File Created
--
-------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.reduce_Pack.all;
use work.vicg_common_pkg.all;
use work.clocks_pkg.all;
use work.ccd_vita25K_pkg.all;
use work.prj_cfg.all;
use work.vout_pkg.all;

entity camera_main is
port(
--------------------------------------------------
--Технологический порт
--------------------------------------------------
pin_out_TP          : out   std_logic_vector((C_PCFG_CCD_DATA_LINE_COUNT
                                                * C_PCFG_CCD_BIT_PER_PIXEL) - 1 downto 0);
pin_out_syn         : out   std_logic;

--------------------------------------------------
--CCD
--------------------------------------------------
pin_in_ccd          : in   TCCD_pinin;
pin_out_ccd         : out  TCCD_pinout;

--------------------------------------------------
--Video Output
--------------------------------------------------
pin_out_video       : out  TVout_pinout;

--------------------------------------------------
--Reference clock
--------------------------------------------------
pin_in_refclk       : in    TRefclk_pinin
);
end entity;

architecture struct of camera_main is

component clocks is
port(
p_out_rst  : out   std_logic;
p_out_gclk : out   std_logic_vector(7 downto 0);

p_in_clk   : in    TRefclk_pinin
);
end component;

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

component vout is
port(
--PHY
p_out_video   : out  TVout_pinout;

p_in_fifo_do  : in   std_logic_vector(31 downto 0);
p_out_fifo_rd : out  std_logic;

--System
p_in_clk      : in   std_logic;
p_in_rst      : in   std_logic
);
end component;

signal i_rst              : std_logic;
signal g_usrclk           : std_logic_vector(7 downto 0);
signal i_video_d          : std_logic_vector((C_PCFG_CCD_LVDS_COUNT
                                               * C_PCFG_CCD_BIT_PER_PIXEL) - 1 downto 0);
signal i_video_d_clk      : std_logic;
signal i_video_vs         : std_logic;
signal i_video_hs         : std_logic;
signal i_video_den        : std_logic;

signal i_vfifo_do         : std_logic_vector(31 downto 0) := (others => '0');
signal i_vfifo_rd         : std_logic;

signal tst_cnt : std_logic_vector(2 downto 0);
signal i_tst_out : std_logic_vector(31 downto 0);


--MAIN
begin

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
G_SIM => C_PCFG_SIM
)
port map(
p_in_ccd  => pin_in_ccd,
p_out_ccd => pin_out_ccd,

p_out_video_vs  => i_video_vs,
p_out_video_hs  => i_video_hs,
p_out_video_den => i_video_den,
p_out_video_d   => i_video_d,
p_out_video_clk => i_video_d_clk,

p_out_tst       => i_tst_out,
p_in_tst        => (others => '0'),

p_in_refclk => g_usrclk(0),
p_in_ccdclk => g_usrclk(1),
p_in_rst    => i_rst
);


--***********************************************************
--
--***********************************************************
m_video_out : vout
port map(
--PHY
p_out_video   => pin_out_video,

p_in_fifo_do  => i_vfifo_do,
p_out_fifo_rd => i_vfifo_rd,

--System
p_in_clk      => g_usrclk(2),
p_in_rst      => i_rst
);



--***********************************************************
--Технологический порт
--***********************************************************
--pin_out_TP <= tst_cnt;--(others => '0');
--
--process(i_rst, g_usrclk(0))
--begin
--  if i_rst = '1' then
--    tst_cnt <= (others => '0');
--  elsif rising_edge(g_usrclk(0)) then
--    tst_cnt <= tst_cnt;
--  end if;
--end process;

gen_tp : for i in 1 to (C_PCFG_CCD_LVDS_COUNT - 1) generate
pin_out_TP(i - 1) <= OR_reduce(i_video_d((C_PCFG_CCD_BIT_PER_PIXEL * (i + 1)) - 1 downto (C_PCFG_CCD_BIT_PER_PIXEL * i)));
end generate;

pin_out_syn <= i_video_den or i_video_hs or i_video_vs or OR_reduce(i_tst_out);

--END MAIN
end architecture;

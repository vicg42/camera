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

entity camera_main is
port(
--------------------------------------------------
--Технологический порт
--------------------------------------------------
pin_out_TP          : out   std_logic_vector(C_PCFG_CCD_LVDS_COUNT - 1 downto 0);

--------------------------------------------------
--CCD
--------------------------------------------------
pin_in_ccd          : in   TCCD_PortIN;
pin_out_ccd         : out  TCCD_PortOUT;

--------------------------------------------------
--Reference clock
--------------------------------------------------
pin_in_refclk       : in    TRefClkPinIN
);
end entity;

architecture struct of camera_main is

component clocks is
port(
p_out_rst  : out   std_logic;
p_out_gclk : out   std_logic_vector(7 downto 0);

p_in_clk   : in    TRefClkPinIN
);
end component;

component ccd_vita25K is
port(
p_in_ccd   : in   TCCD_PortIN;
p_out_ccd  : out  TCCD_PortOUT;

p_out_vd     : out std_logic_vector((C_PCFG_CCD_LVDS_COUNT * 10) - 1 downto 0);
p_out_vd_clk : out std_logic;

p_in_refclk : in   std_logic;
p_in_ccdclk : in   std_logic;
p_in_rst    : in   std_logic
);
end component;

signal i_rst                            : std_logic;
signal g_usrclk                         : std_logic_vector(7 downto 0);
signal i_vd                             : std_logic_vector((C_PCFG_CCD_LVDS_COUNT * 10) - 1 downto 0);
signal i_vd_clk                         : std_logic;

signal tst_cnt : std_logic_vector(2 downto 0);

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
port map(
p_in_ccd  => pin_in_ccd,
p_out_ccd => pin_out_ccd,

p_out_vd     => i_vd,
p_out_vd_clk => i_vd_clk,

p_in_refclk => g_usrclk(0),
p_in_ccdclk => g_usrclk(1),
p_in_rst    => i_rst
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

gen_tp : for i in 0 to (C_PCFG_CCD_LVDS_COUNT - 1) generate
pin_out_TP(i) <= OR_reduce(i_vd((10 * (i + 1)) - 1 downto (10 * i)));
end generate;

--END MAIN
end architecture;

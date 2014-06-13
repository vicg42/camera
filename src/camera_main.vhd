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
use work.vicg_common_pkg.all;
use work.clocks_pkg.all;

entity camera_main is
port(
--------------------------------------------------
--Технологический порт
--------------------------------------------------
pin_out_TP          : out   std_logic_vector(2 downto 0);

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


signal i_rst                            : std_logic;
signal g_usrclk                         : std_logic_vector(7 downto 0);


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
--Технологический порт
--***********************************************************
pin_out_TP <= tst_cnt;--(others => '0');

process(i_rst, g_usrclk(0))
begin
  if i_rst = '1' then
    tst_cnt <= (others => '0');
  elsif rising_edge(g_usrclk(0)) then
    tst_cnt <= tst_cnt;
  end if;
end process;

--END MAIN
end architecture;

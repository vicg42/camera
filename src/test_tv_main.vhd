-------------------------------------------------------------------------
-- Company     : Yansar
-- Engineer    : Golovachenko Victor
--
-- Create Date : 13.06.2014 12:31:35
-- Module Name : test_tv_main
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
use work.prj_cfg.all;
use work.reduce_pack.all;
use work.vicg_common_pkg.all;
use work.clocks_pkg.all;
use work.vout_pkg.all;

entity test_tv_main is
port(
--------------------------------------------------
--Технологический порт
--------------------------------------------------
pin_out_led         : out   std_logic_vector(1 downto 0);
pin_in_btn          : in    std_logic;

pin_out_video       : out  TVout_pinout;

--------------------------------------------------
--Reference clock
--------------------------------------------------
pin_in_refclk       : in    TRefclk_pinin
);
end entity test_tv_main;

architecture struct of test_tv_main is

component clocks is
generic(
G_VOUT_TYPE : string := "VGA"
);
port(
p_out_rst  : out   std_logic;
p_out_gclk : out   std_logic_vector(7 downto 0);

p_in_clk   : in    TRefclk_pinin
);
end component clocks;

component fpga_test_01
generic(
G_BLINK_T05   : integer:=10#125#; -- 1/2 периода мигания светодиода.(время в ms)
G_CLK_T05us   : integer:=10#1000# -- кол-во периодов частоты порта p_in_clk
                                  -- укладывающиес_ в 1/2 периода 1us
);
port(
p_out_test_led : out   std_logic;--мигание сведодиода
p_out_test_done: out   std_logic;--сигнал переходи в '1' через 3 сек.

p_out_1us      : out   std_logic;
p_out_1ms      : out   std_logic;
-------------------------------
--System
-------------------------------
p_in_clk       : in    std_logic;
p_in_rst       : in    std_logic
);
end component fpga_test_01;

component vout is
generic(
G_VDWIDTH : integer := 32;
G_VOUT_TYPE : string := "VGA";
G_TEST_PATTERN : string := "ON"
);
port(
--PHY
p_out_video   : out  TVout_pinout;

p_in_fifo_do  : in   std_logic_vector(G_VDWIDTH - 1 downto 0);
p_out_fifo_rd : out  std_logic;
p_in_fifo_empty : in  std_logic;

p_out_tst     : out std_logic_vector(31 downto 0);
p_in_tst      : in  std_logic_vector(31 downto 0);

--System
p_in_rdy      : in   std_logic;
p_in_clk      : in   std_logic;
p_in_rst      : in   std_logic
);
end component vout;

signal i_rst              : std_logic;
signal g_usrclk           : std_logic_vector(7 downto 0);
signal i_test_led         : std_logic_vector(1 downto 0);
signal i_1ms              : std_logic;

signal i_cntdiv_memclkin  : unsigned(10 downto 0);

attribute keep : string;
attribute keep of g_usrclk : signal is "true";


begin --architecture struct

--***********************************************************
--Установка частот проекта:
--***********************************************************
m_clocks : clocks
generic map(
G_VOUT_TYPE => C_PCGF_VOUT_TYPE
)
port map(
p_out_rst  => i_rst,
p_out_gclk => g_usrclk,

p_in_clk   => pin_in_refclk
);


--***********************************************************
--Технологический порт
--***********************************************************
pin_out_led(0) <= i_test_led(0);
pin_out_led(1) <= i_cntdiv_memclkin(8);


m_led1_tst: fpga_test_01
generic map(
G_BLINK_T05   =>10#250#,
G_CLK_T05us   =>10#10#
)
port map(
p_out_test_led => i_test_led(0),
p_out_test_done=> open,

p_out_1us      => open,
p_out_1ms      => i_1ms,
-------------------------------
--System
-------------------------------
p_in_clk       => g_usrclk(5),
p_in_rst       => i_rst
);


--***********************************************************
--
--***********************************************************
m_video_out : vout
generic map(
G_VDWIDTH => C_CGF_VBUFO_DWIDTH,
G_VOUT_TYPE => C_PCGF_VOUT_TYPE,
G_TEST_PATTERN => C_PCGF_VOUT_TEST
)
port map(
--PHY
p_out_video   => pin_out_video,

p_in_fifo_do  => (others => '0'),
p_out_fifo_rd => open,
p_in_fifo_empty => '0',

p_out_tst     => open,
p_in_tst      => (others => '0'),

--System
p_in_rdy      => '1',
p_in_clk      => g_usrclk(2),
p_in_rst      => i_rst
);


process(g_usrclk(4))
begin
  if rising_edge(g_usrclk(4)) then
    i_cntdiv_memclkin <= i_cntdiv_memclkin + 1;
  end if;
end process;


end architecture struct;

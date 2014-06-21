library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.reduce_pack.all;
use work.vicg_common_pkg.all;
use work.clocks_pkg.all;

entity vga_gen_tb is
port(
pin_out_syn    : out std_logic;
pin_out_tp     : out std_logic_vector(1 downto 0)
);
end vga_gen_tb;

architecture test of vga_gen_tb is

component vga_gen is
generic(
G_SEL : integer := 0 --Resolution select
);
port(
--SYNC
p_out_vsync   : out  std_logic; --Vertical Sync
p_out_hsync   : out  std_logic; --Horizontal Sync
p_out_den     : out  std_logic; --Pixels

--System
p_in_clk      : in   std_logic;
p_in_rst      : in   std_logic
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

signal pin_in_refclk      : TRefclk_pinin;

signal g_usrclk           : std_logic_vector(7 downto 0);
signal i_video_d          : std_logic_vector(7 downto 0);
signal i_video_d_clk      : std_logic;
signal i_video_vs         : std_logic;
signal i_video_hs         : std_logic;
signal i_video_den        : std_logic;

signal i_cfg      : std_logic_vector(1 downto 0);
signal i_vpix     : std_logic_vector(15 downto 0);
signal i_vrow     : std_logic_vector(15 downto 0);
signal i_syn_h    : std_logic_vector(15 downto 0);
signal i_syn_v    : std_logic_vector(15 downto 0);

signal i_pixcnt   : unsigned(10 downto 0) := (others => '0');

begin


process begin
  wait for (CI_CLK_PERIOD/2);
  i_clk <= not i_clk;
end process;

pin_in_refclk.clk(0) <= i_clk;
pin_in_refclk.clk(1) <= i_clk;
pin_in_refclk.clk(2) <= i_clk;


--***********************************************************
--Установка частот проекта:
--***********************************************************
m_clocks : clocks
port map(
p_out_rst  => i_rst,
p_out_gclk => g_usrclk,

p_in_clk   => pin_in_refclk
);


m_vga : vga_gen
generic map(
G_SEL => 2
)
port map(
--SYNC
p_out_vsync   => i_video_vs,
p_out_hsync   => i_video_hs,
p_out_den     => i_video_den,

--System
p_in_clk      => g_usrclk(1),
p_in_rst      => i_rst
);

pin_out_syn <= OR_reduce(i_video_d) or i_video_hs or i_video_vs or i_video_den or i_pixcnt(9);

process(g_usrclk(1))
begin
  if rising_edge(g_usrclk(1)) then
    if i_video_den = '1' then
    i_pixcnt <= i_pixcnt + 1;
    else
    i_pixcnt <= (others => '0');
    end if;
  end if;
end process;



end test;


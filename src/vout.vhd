-------------------------------------------------------------------------
-- Company     : Yansar
-- Engineer    : Golovachenko Victor
--
-- Create Date : 21.06.2014 12:31:25
-- Module Name : vout
--
-- Назначение/Описание :
--
--------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.vicg_common_pkg.all;
use work.vout_pkg.all;

entity vout is
port(
--PHY
p_out_video   : out  TVout_pinout;

p_in_fifo_do  : in   std_logic_vector(31 downto 0);
p_out_fifo_rd : out  std_logic;
p_out_fifo_empty : in  std_logic;

--System
p_in_clk      : in   std_logic;
p_in_rst      : in   std_logic
);
end vout;

architecture behavioral of vout is

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

signal i_video_vs           : std_logic;
signal i_video_hs           : std_logic;
signal i_video_den          : std_logic;


--MAIN
begin


m_time_gen : vga_gen
generic map(
G_SEL => 2
)
port map(
--SYNC
p_out_vsync => i_video_vs,
p_out_hsync => i_video_hs,
p_out_den   => i_video_den,

--System
p_in_clk    => p_in_clk,
p_in_rst    => p_in_rst
);


p_out_video.vga_dr <= p_in_fifo_do(10 - 1 downto 0);
p_out_video.vga_dg <= p_in_fifo_do(10 - 1 downto 0);
p_out_video.vga_db <= p_in_fifo_do(10 - 1 downto 0);
p_out_video.vga_hs <= i_video_hs;
p_out_video.vga_vs <= i_video_vs;

p_out_video.dac_blank_n <= i_video_den;
p_out_video.dac_sync_n  <= i_video_hs;
p_out_video.dac_psave_n <= '1'; --Power Down OFF
p_out_video.dac_clk     <= p_in_clk;

p_out_fifo_rd <= i_video_den;


--END MAIN
end behavioral;

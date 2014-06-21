-------------------------------------------------------------------------
-- Company     : Yansar
-- Engineer    : Golovachenko Victor
--
-- Create Date : 21.06.2014 12:31:25
-- Module Name : vga
--
-- Назначение/Описание :
--
--------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.vicg_common_pkg.all;

entity vga is
generic(
G_SEL : integer := 0 --Resolution select
);
port(
--PHY
p_out_video_dr : out  std_logic_vector(10 - 1 downto 0);
p_out_video_dg : out  std_logic_vector(10 - 1 downto 0);
p_out_video_db : out  std_logic_vector(10 - 1 downto 0);
p_out_video_vs : out  std_logic; --Vertical Sync
p_out_video_hs : out  std_logic; --Horizontal Sync

p_in_fifo_do   : in   std_logic_vector(31 downto 0);
p_out_fifo_rd  : out  std_logic;

--System
p_in_clk      : in   std_logic;
p_in_rst      : in   std_logic
);
end vga;

architecture behavioral of vga is

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
G_SEL => G_SEL
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


p_out_video_vs <= i_video_vs;
p_out_video_hs <= i_video_hs;
p_out_video_dr <= p_in_fifo_do(10 - 1 downto 0) when i_video_den = '1' else (others => '0');
p_out_video_dg <= p_in_fifo_do(10 - 1 downto 0) when i_video_den = '1' else (others => '0');
p_out_video_db <= p_in_fifo_do(10 - 1 downto 0) when i_video_den = '1' else (others => '0');

p_out_fifo_rd <= i_video_den;


--END MAIN
end behavioral;

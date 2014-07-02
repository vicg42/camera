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
p_in_fifo_empty : in  std_logic;

--System
p_in_clk      : in   std_logic_vector(1 downto 0);
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

component TVS is
port(
p_out_tv_kci   : out std_logic;
p_out_tv_ssi   : out std_logic;--Синхросмесь. Стандартный TV сигнал
p_out_tv_field : out std_logic;--Поле TV сигнала (Четные/Нечетные строки)
p_out_den      : out std_logic;--Активная часть строки.(Разрешение вывода пиксел)

p_in_clk_en: in std_logic;
p_in_clk   : in std_logic;
p_in_rst   : in std_logic
);
end component;

signal i_tvss             : std_logic;
signal i_tv_den           : std_logic;
signal i_vga_vs           : std_logic;
signal i_vga_hs           : std_logic;
signal i_vga_den          : std_logic;
signal i_cnt              : unsigned(9 downto 0) := (others => '0');


--MAIN
begin


m_vga_timegen : vga_gen
generic map(
G_SEL => 2
)
port map(
--SYNC
p_out_vsync => i_vga_vs,
p_out_hsync => i_vga_hs,
p_out_den   => i_vga_den,

--System
p_in_clk    => p_in_clk(0),
p_in_rst    => p_in_rst
);

p_out_video.vga_db <= p_in_fifo_do(10 - 1 downto 0);
p_out_video.vga_dg <= p_in_fifo_do(10 - 1 downto 0);
p_out_video.vga_dr <= p_in_fifo_do(10 - 1 downto 0);
p_out_video.vga_hs <= i_vga_hs;
p_out_video.vga_vs <= i_vga_vs;

--Control DAC (ADV7123)
p_out_video.dac_blank_n <= i_vga_den;--not i_tv_den;--
p_out_video.dac_sync_n  <= '0';
p_out_video.dac_psave_n <= '1';--Power Down OFF
p_out_video.dac_clk     <= not p_in_clk(1);--p_in_clk(0);

p_out_fifo_rd <= i_vga_den;

--m_tv_timegen : TVS
--port map(
--p_out_tv_kci   => open,
--p_out_tv_ssi   => i_tvss,
--p_out_tv_field => open,
--p_out_den      => i_tv_den,
--
--p_in_clk_en => '1',
--p_in_clk    => p_in_clk(1),
--p_in_rst    => p_in_rst
--);
--
--p_out_video.hsync <= i_tvss;
--p_out_video.vsync <= '1';
--p_out_video.ce    <= '1';
--p_out_video.sa    <= '0';
--p_out_video.stnd  <= '0';
--p_out_video.fcs4  <= p_in_clk(1);

--gen : for i in 0 to p_out_video.vga_db'length - 1 generate
--p_out_video.vga_db(i) <= '1' when i_cnt(7) = '1' else '0';
--p_out_video.vga_dg(i) <= '1' when i_cnt(8) = '1' else '0';
--p_out_video.vga_dr(i) <= '1' when i_cnt(9) = '1' else '0';
--end generate;
--
--process(p_in_clk)
--begin
--  if rising_edge(p_in_clk) then
--    if i_tv_den = '1' then --if i_vga_hs = '0' then
--      i_cnt <= (others => '0');
--    else
--      i_cnt <= i_cnt + 1;
--    end if;
--  end if;
--end process;


--END MAIN
end behavioral;

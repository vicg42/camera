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
generic(
G_VOUT_TYPE : string := "VGA";
G_TEST_PATTERN : string := "ON"
);
port(
--PHY
p_out_video   : out  TVout_pinout;

p_in_fifo_do  : in   std_logic_vector(31 downto 0);
p_out_fifo_rd : out  std_logic;
p_in_fifo_empty : in  std_logic;

p_out_tst     : out std_logic_vector(31 downto 0);
p_in_tst      : in  std_logic_vector(31 downto 0);

--System
p_in_clk      : in   std_logic_vector(1 downto 0);
p_in_rst      : in   std_logic
);
end entity;

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

component tv_gen is
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

signal i_tv_ss            : std_logic;
signal i_tv_field         : std_logic;
signal i_tv_den           : std_logic;
signal i_tv_pix_clk       : std_logic;
signal i_tv_color_clk     : std_logic;
signal i_vga_vs           : std_logic;
signal i_vga_hs           : std_logic;
signal i_vga_den          : std_logic;
signal i_vga_pix_clk      : std_logic;
signal i_cnt              : unsigned(9 downto 0) := (others => '0');



--MAIN
begin

--################################
--VGA
--################################
gen_vga : if strcmp(G_VOUT_TYPE, "VGA") generate
begin

p_out_tst <= (others => '0');

i_vga_pix_clk <= p_in_clk(0);

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
p_in_clk    => i_vga_pix_clk,
p_in_rst    => p_in_rst
);

p_out_video.adv7123_blank_n <= i_vga_den;
p_out_video.adv7123_sync_n  <= '0';
p_out_video.adv7123_psave_n <= '1';--Power Down OFF
p_out_video.adv7123_clk     <= not i_vga_pix_clk;

p_out_fifo_rd <= i_vga_den;

p_out_video.vga_hs <= i_vga_hs;
p_out_video.vga_vs <= i_vga_vs;

gen_tst_off : if strcmp(G_TEST_PATTERN, "OFF") generate
begin
p_out_video.adv7123_db <= p_in_fifo_do(10 - 1 downto 0);
p_out_video.adv7123_dg <= p_in_fifo_do(10 - 1 downto 0);
p_out_video.adv7123_dr <= p_in_fifo_do(10 - 1 downto 0);
end generate gen_tst_off;

gen_tst_on : if strcmp(G_TEST_PATTERN, "ON") generate
begin
gen : for i in 0 to p_out_video.adv7123_db'length - 1 generate
p_out_video.adv7123_db(i) <= i_cnt(7);
p_out_video.adv7123_dg(i) <= i_cnt(8);
p_out_video.adv7123_dr(i) <= i_cnt(9);
end generate;

process(i_vga_pix_clk)
begin
  if rising_edge(i_vga_pix_clk) then
    if i_vga_hs = '0' then
      i_cnt <= (others => '0');
    else
      i_cnt <= i_cnt + 1;
    end if;
  end if;
end process;

end generate gen_tst_on;
end generate gen_vga;



--################################
--TV
--################################
gen_tv : if strcmp(G_VOUT_TYPE, "TV") generate
begin

p_out_tst(0) <= i_tv_field;
i_tv_pix_clk <= p_in_clk(1);--p_in_clk(0);--12.5MHz
i_tv_color_clk <= p_in_clk(1);--PAL =17,734472MHz / NTSC=13,845984MHz

m_tv_timegen : tv_gen
port map(
p_out_tv_kci   => open,
p_out_tv_ssi   => i_tv_ss,
p_out_tv_field => i_tv_field,
p_out_den      => i_tv_den,

p_in_clk_en => '1',
p_in_clk    => i_tv_pix_clk,
p_in_rst    => p_in_rst
);

p_out_video.ad723_hsrca <= i_tv_ss;
p_out_video.ad723_vsrca <= '1';
p_out_video.ad723_ce    <= '1';
p_out_video.ad723_sa    <= '0';
p_out_video.ad723_stnd  <= '0';
p_out_video.ad723_fcs4  <= i_tv_color_clk;
p_out_video.ad723_term  <= '1';

p_out_video.adv7123_blank_n <= i_tv_den;
p_out_video.adv7123_sync_n  <= '0';
p_out_video.adv7123_psave_n <= '1';--Power Down OFF
p_out_video.adv7123_clk     <= i_tv_pix_clk;

p_out_fifo_rd <= i_tv_den;

p_out_video.vga_hs <= '0';
p_out_video.vga_vs <= '0';

gen_tst_off : if strcmp(G_TEST_PATTERN, "OFF") generate
begin
p_out_video.adv7123_db <= p_in_fifo_do(10 - 1 downto 0);
p_out_video.adv7123_dg <= p_in_fifo_do(10 - 1 downto 0);
p_out_video.adv7123_dr <= p_in_fifo_do(10 - 1 downto 0);
end generate gen_tst_off;

gen_tst_on : if strcmp(G_TEST_PATTERN, "ON") generate
begin
gen : for i in 0 to p_out_video.adv7123_db'length - 1 generate
p_out_video.adv7123_db(i) <= i_cnt(6);
p_out_video.adv7123_dg(i) <= i_cnt(7);
p_out_video.adv7123_dr(i) <= i_cnt(8);
end generate;

process(i_tv_pix_clk)
begin
  if rising_edge(i_tv_pix_clk) then
    if i_tv_den = '0' then
      i_cnt <= (others => '0');
    else
      i_cnt <= i_cnt + 1;
    end if;
  end if;
end process;
end generate gen_tst_on;

end generate gen_tv;


--END MAIN
end architecture;


--component monvctv is
--port(
--clk13m,clk17m : in std_logic;
--monvc_en : in std_logic;
--clk17_out,clk13_out : out std_logic;
--csync_out,ce_out,term_out,sa_out,stnd_out,sync_out,psave_out,blank_out : out std_logic;
--tvdet_in : in std_logic;
--r_out,g_out,b_out : out std_logic_vector(9 downto 0)
--);
--end component;

----// Видеоконтроллер TV 886H x 625V x 50Hz x 13.846MHz
--i_ad723_ce <= not p_in_rst;
--
--m_tv_timegen : monvctv
--port map(
--clk17m    => p_in_clk(0),--(clk17m),
--clk13m    => p_in_clk(1),--(clk13m),
--monvc_en  => i_ad723_ce,--(monvc_en),
--clk17_out => p_out_video.ad723_fcs4,--(TV4FSC),
--csync_out => p_out_video.ad723_hsrca,--(csync_out),
--ce_out    => p_out_video.ad723_ce,--(CE),
--term_out  => p_out_video.ad723_term,--(TERM),
--sa_out    => p_out_video.ad723_sa,--(SA),
--stnd_out  => p_out_video.ad723_stnd,--(STND),
--tvdet_in  => '0',--(TVDET),
--blank_out => p_out_video.adv7123_blank_n,--(DACBBL),
--sync_out  => p_out_video.adv7123_sync_n,--(DACBSY),
--clk13_out => p_out_video.adv7123_clk,--(DACBCL),
--psave_out => p_out_video.adv7123_psave_n,--(DACBPS),
--r_out     => p_out_video.adv7123_dr,--(DACBR),
--g_out     => p_out_video.adv7123_dg,--(DACBG),
--b_out     => p_out_video.adv7123_db --(DACBB)
--);
--
--p_out_video.ad723_vsrca <= '1';
--
--p_out_video.vga_hs <= '0';
--p_out_video.vga_vs <= '0';
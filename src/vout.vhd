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
use work.reduce_pack.all;

entity vout is
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
p_in_clk      : in   std_logic;
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
generic(
N_ROW  : integer:=625;--Кол-во строк в кадре. (312.5 строк в одном поле)
N_H2   : integer:=400;--т.е. 64us/2=32us (удвоеная частота строк)
W2_32us: integer:=29 ;--т.е. 2.32 us
W4_7us : integer:=59 ;--т.е. 4.7 us
W1_53us: integer:=19 ;--т.е. 1.53 us
W5_8us : integer:=73 ;--т.е. 5.8 us
var1   : integer:=4  ;--продстройка
var2   : integer:=5   --продстройка
);
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
signal sr_vga_vs          : unsigned(0 to 1) := (others => '0');
signal sr_vga_den          : unsigned(0 to 1) := (others => '0');
signal i_vga_work         : std_logic;
signal i_cnt              : unsigned(8 downto 0) := (others => '0');
signal i_fifo_rd          : std_logic;
signal i_fifo_do          : std_logic_vector(G_VDWIDTH - 1 downto 0);
signal sr_fifo_rd         : std_logic_vector(0 to 1);
signal sr_fifo_rd_start   : std_logic;
signal tst_linecnt        : unsigned(10 downto 0) := (others => '0');



--MAIN
begin

--################################
--VGA
--################################
gen_vga : if strcmp(G_VOUT_TYPE, "VGA") generate
begin

p_out_tst(0) <= sr_fifo_rd_start;
p_out_tst(1) <= OR_reduce(i_fifo_do) or OR_reduce(tst_linecnt);

i_vga_pix_clk <= p_in_clk;

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
p_out_video.ad723_ce <= '0';

p_out_fifo_rd <= i_fifo_rd; i_fifo_rd <= i_vga_den and i_vga_work;

p_out_video.vga_hs <= i_vga_hs;
p_out_video.vga_vs <= i_vga_vs;

gen_tst_off : if strcmp(G_TEST_PATTERN, "OFF") generate
begin
gen : for i in 0 to p_out_video.adv7123_db'length - 1 generate
p_out_video.adv7123_db(i) <= p_in_fifo_do(5);
p_out_video.adv7123_dg(i) <= p_in_fifo_do(6);
p_out_video.adv7123_dr(i) <= p_in_fifo_do(7);
end generate;
--p_out_video.adv7123_db <= i_fifo_do(8 - 1 downto 0) & "00";
--p_out_video.adv7123_dg <= i_fifo_do(8 - 1 downto 0) & "00";
--p_out_video.adv7123_dr <= i_fifo_do(8 - 1 downto 0) & "00";


process(i_vga_pix_clk)
begin
if rising_edge(i_vga_pix_clk) then
  if p_in_rst = '1' then
    sr_vga_vs <= (others => '0');
    sr_vga_den <= (others => '0');
    i_vga_work <= '0';
    sr_fifo_rd <= (others => '0');
    sr_fifo_rd_start <= '0';
    tst_linecnt <= (others => '0');
  else
    sr_vga_vs <= i_vga_vs & sr_vga_vs(0 to 0);
    sr_vga_den <= i_vga_den & sr_vga_den(0 to 0);

    if p_in_fifo_empty = '0' then
      if sr_vga_vs(0) = '0' and sr_vga_vs(1) = '1' then
        i_vga_work <= '1';
      end if;
    end if;

    if i_fifo_rd = '1' then
      i_fifo_do <= p_in_fifo_do;
    end if;

    sr_fifo_rd <= i_fifo_rd & sr_fifo_rd(0 to 0);
    sr_fifo_rd_start <= sr_fifo_rd(0) and not sr_fifo_rd(1);

    if i_vga_vs = '0' then
      tst_linecnt <= (others => '0');
    elsif sr_vga_den(0) = '1' and sr_vga_den(1) = '0' then
      tst_linecnt <= tst_linecnt + 1;
    end if;
  end if;
end if;
end process;

end generate gen_tst_off;

gen_tst_on : if strcmp(G_TEST_PATTERN, "ON") generate
begin
gen : for i in 0 to p_out_video.adv7123_db'length - 1 generate
p_out_video.adv7123_db(i) <= i_cnt(6);
p_out_video.adv7123_dg(i) <= i_cnt(7);
p_out_video.adv7123_dr(i) <= i_cnt(8);
end generate;
--p_out_video.adv7123_db <= i_cnt(6) & i_cnt(3) & i_cnt(0) & "0000000";
--p_out_video.adv7123_dg <= i_cnt(7) & i_cnt(4) & i_cnt(1) & "0000000";
--p_out_video.adv7123_dr <= i_cnt(8) & i_cnt(5) & i_cnt(2) & "0000000";

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
--TV (896pix x 625line) pixclk 17,734472MHz
--################################
gen_tv : if strcmp(G_VOUT_TYPE, "TV") generate
begin

p_out_tst(0) <= i_tv_field;
i_tv_pix_clk <= p_in_clk;--17,734472MHz
i_tv_color_clk <= p_in_clk;--PAL =17,734472MHz / NTSC=13,845984MHz

m_tv_timegen : tv_gen
generic map(
--Все значения относительно p_in_clk=17,734472MHz (Активных строк/пиксел - 574/xxx)
N_ROW   => 625, --Кол-во строк в кадре. (312.5 строк в одном поле)
N_H2    => 567, --т.е. 64us/2=32us (удвоеная частота строк)
W2_32us => 41 , --т.е. 2.32 us
W4_7us  => 83 , --т.е. 4.7 us
W1_53us => 27 , --т.е. 1.53 us
W5_8us  => 102, --т.е. 5.8 us
var1    => 13  , --продстройка
var2    => 14    --продстройка
)
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
p_out_video.ad723_stnd  <= '0';--0/1 - PAL/NTSC
p_out_video.ad723_fcs4  <= i_tv_color_clk;
p_out_video.ad723_term  <= '1';

p_out_video.adv7123_blank_n <= i_tv_den;
p_out_video.adv7123_sync_n  <= '0';
p_out_video.adv7123_psave_n <= '1';--Power Down OFF
p_out_video.adv7123_clk     <= not i_tv_pix_clk;

p_out_fifo_rd <= i_tv_den and i_vga_work;

process(i_tv_pix_clk)
begin
if rising_edge(i_tv_pix_clk) then
  if p_in_rst = '1' then
    sr_vga_vs <= (others => '0');
    i_vga_work <= '0';
  else
    sr_vga_vs <= i_tv_field & sr_vga_vs(0 to 0);

    if p_in_fifo_empty = '0' then
      if sr_vga_vs(0) = '0' and sr_vga_vs(1) = '1' then
        i_vga_work <= '1';
      end if;
    end if;
  end if;
end if;
end process;

p_out_video.vga_hs <= '0';
p_out_video.vga_vs <= '0';

gen_tst_off : if strcmp(G_TEST_PATTERN, "OFF") generate
begin
p_out_video.adv7123_db <= p_in_fifo_do(8 - 1 downto 0) & "00";
p_out_video.adv7123_dg <= p_in_fifo_do(8 - 1 downto 0) & "00";
p_out_video.adv7123_dr <= p_in_fifo_do(8 - 1 downto 0) & "00";
end generate gen_tst_off;

gen_tst_on : if strcmp(G_TEST_PATTERN, "ON") generate
begin
--gen : for i in 0 to p_out_video.adv7123_db'length - 1 generate
--p_out_video.adv7123_db(i) <= i_cnt(6);
--p_out_video.adv7123_dg(i) <= i_cnt(7);
--p_out_video.adv7123_dr(i) <= i_cnt(8);
--end generate;
----p_out_video.adv7123_db <= i_cnt(6) & i_cnt(3) & i_cnt(0) & "0000000";
----p_out_video.adv7123_dg <= i_cnt(7) & i_cnt(4) & i_cnt(1) & "0000000";
----p_out_video.adv7123_dr <= i_cnt(8) & i_cnt(5) & i_cnt(2) & "0000000";
p_out_video.adv7123_db <= std_logic_vector(i_cnt(7 downto 0)) & "00";
p_out_video.adv7123_dg <= std_logic_vector(i_cnt(7 downto 0)) & "00";
p_out_video.adv7123_dr <= std_logic_vector(i_cnt(7 downto 0)) & "00";

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

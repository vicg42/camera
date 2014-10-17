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
p_in_rdy      : in   std_logic;
p_in_clk      : in   std_logic;
p_in_rst      : in   std_logic
);
end entity;

architecture behavioral of vout is

component char_screen is
generic(
G_VDWIDTH    : integer := 32;
G_COLDWIDTH  : integer := 10;
G_FONT_SIZEX : integer := 8;
G_FONT_SIZEY : integer := 10;
G_SCR_STARTX : integer := 8; --(index pixel)
G_SCR_STARTY : integer := 8; --(index pixel)
G_SCR_SIZEX  : integer := 8; --(char count)
G_SCR_SIZEY  : integer := 8  --(char count)
);
port(
p_in_ram_adr  : in  std_logic_vector(11 downto 0);
p_in_ram_din  : in  std_logic_vector(31 downto 0);

--SYNC
p_out_vd      : out  std_logic_vector(G_VDWIDTH - 1 downto 0);
p_in_vd       : in   std_logic_vector(G_VDWIDTH - 1 downto 0);
p_in_vsync    : in   std_logic; --Vertical Sync
p_in_hsync    : in   std_logic; --Horizontal Sync
p_in_pixen    : in   std_logic;
p_in_pixcnt   : in   std_logic_vector(15 downto 0);
p_in_linecnt  : in   std_logic_vector(15 downto 0);

p_out_tst     : out  std_logic_vector(31 downto 0);

--System
p_in_clk      : in   std_logic;
p_in_rst      : in   std_logic
);
end component char_screen;

component vga_gen is
generic(
G_SEL : integer := 0 --Resolution select
);
port(
--SYNC
p_out_vsync   : out  std_logic; --Vertical Sync
p_out_hsync   : out  std_logic; --Horizontal Sync
p_out_pixen   : out  std_logic; --Pixels
p_out_pixcnt  : out  std_logic_vector(15 downto 0);
p_out_linecnt : out  std_logic_vector(15 downto 0);

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
signal i_tv_pix_clk       : std_logic;
signal i_tv_color_clk     : std_logic;
signal i_vga_vs           : std_logic;
signal i_vga_hs           : std_logic;
signal i_vga_pix_clk      : std_logic;
signal i_pix_den          : std_logic;
signal i_rdy              : std_logic;
signal sr_vfr_start       : unsigned(0 to 1) := (others => '0');
signal i_vout_work        : std_logic := '1';
signal i_cnt              : unsigned(8 downto 0) := (others => '0');

signal i_vdin             : std_logic_vector(p_in_fifo_do'range);
signal i_vdtxt            : std_logic_vector(p_in_fifo_do'range);
signal i_pixcnt           : std_logic_vector(15 downto 0);
signal i_linecnt          : std_logic_vector(15 downto 0);
--signal tst_char_screen_out: std_logic_vector(31 downto 0);
--signal tst_vdtxt          : std_logic_vector(p_in_fifo_do'range);
signal tst_vdout          : std_logic_vector(G_VDWIDTH - 1 downto 0);

--MAIN
begin

--################################
--VGA
--################################
gen_vga : if strcmp(G_VOUT_TYPE, "VGA") generate
begin

p_out_tst(0) <= i_vga_vs;
p_out_tst(1) <= OR_reduce(tst_vdout);
p_out_tst(2) <= '0';--OR_reduce(tst_vdtxt);

process(i_vga_pix_clk)
begin
if rising_edge(i_vga_pix_clk) then
tst_vdout <= p_in_fifo_do((G_VDWIDTH * 1) - 1 downto (G_VDWIDTH * 0));
end if;
end process;

i_vga_pix_clk <= p_in_clk;

m_vga_timegen : vga_gen
generic map(
G_SEL => 1
)
port map(
--SYNC
p_out_vsync => i_vga_vs,
p_out_hsync => i_vga_hs,
p_out_pixen => i_pix_den,
p_out_pixcnt  => i_pixcnt,
p_out_linecnt => i_linecnt,

--System
p_in_clk    => i_vga_pix_clk,
p_in_rst    => p_in_rst
);

p_out_video.ad723_hsrca <= '0';
p_out_video.ad723_vsrca <= '0';
p_out_video.ad723_ce    <= '1';
p_out_video.ad723_sa    <= '0';
p_out_video.ad723_stnd  <= '0';--0/1 - PAL/NTSC
p_out_video.ad723_fcs4  <= '0';
p_out_video.ad723_term  <= '1';

p_out_video.adv7123_blank_n <= i_pix_den;
p_out_video.adv7123_sync_n  <= '0';
p_out_video.adv7123_psave_n <= '1';--Power Down OFF
p_out_video.adv7123_clk     <= not i_vga_pix_clk;

p_out_fifo_rd <= i_pix_den and i_vout_work;

p_out_video.vga_hs <= i_vga_hs;
p_out_video.vga_vs <= i_vga_vs;

--gen_vga
process(i_vga_pix_clk)
begin
if rising_edge(i_vga_pix_clk) then
  if p_in_rst = '1' then
    i_rdy <= '0';
    sr_vfr_start <= (others => '0');
    i_vout_work <= '0';

  else
    i_rdy <= p_in_rdy;
    sr_vfr_start <= i_vga_vs & sr_vfr_start(0 to 0);

    if i_rdy = '1' then
      if sr_vfr_start(0) = '0' and sr_vfr_start(1) = '1' and p_in_fifo_empty = '0' then
        i_vout_work <= '1';
      end if;
    else
      i_vout_work <= '0';
    end if;

  end if;
end if;
end process;

--gen_vga
gen_tst_off : if strcmp(G_TEST_PATTERN, "OFF") generate
begin
--gen : for i in 0 to p_out_video.adv7123_db'length - 1 generate
--p_out_video.adv7123_db(i) <= p_in_fifo_do(5);
--p_out_video.adv7123_dg(i) <= p_in_fifo_do(6);
--p_out_video.adv7123_dr(i) <= p_in_fifo_do(7);
--end generate;
--p_out_video.adv7123_dr <= p_in_fifo_do((10 * 3) - 1 downto (10 * 2));
--p_out_video.adv7123_db <= p_in_fifo_do((10 * 2) - 1 downto (10 * 1));
--p_out_video.adv7123_dg <= p_in_fifo_do((10 * 1) - 1 downto (10 * 0));

p_out_video.adv7123_dr <= std_logic_vector(RESIZE(UNSIGNED(p_in_fifo_do((G_VDWIDTH * 1) - 1 downto (G_VDWIDTH * 0))), p_out_video.adv7123_dr'length));
p_out_video.adv7123_db <= std_logic_vector(RESIZE(UNSIGNED(p_in_fifo_do((G_VDWIDTH * 1) - 1 downto (G_VDWIDTH * 0))), p_out_video.adv7123_db'length));
p_out_video.adv7123_dg <= std_logic_vector(RESIZE(UNSIGNED(p_in_fifo_do((G_VDWIDTH * 1) - 1 downto (G_VDWIDTH * 0))), p_out_video.adv7123_dg'length));
--i_vdin <= p_in_fifo_do;

end generate gen_tst_off;

--gen_vga
gen_tst_on : if strcmp(G_TEST_PATTERN, "ON") generate
begin
gen : for i in 0 to p_out_video.adv7123_db'length - 1 generate
p_out_video.adv7123_db(i) <= i_cnt(6);
p_out_video.adv7123_dg(i) <= i_cnt(7);
p_out_video.adv7123_dr(i) <= i_cnt(8);
--i_vdin(i + (0 * 0)) <= i_cnt(6);
--i_vdin(i + (10 * 1)) <= i_cnt(7);
--i_vdin(i + (10 * 2)) <= i_cnt(8);
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

----gen_vga
--m_screen_txt : char_screen
--generic map(
--G_VDWIDTH    => G_VDWIDTH,
--G_COLDWIDTH  => 10,
--G_FONT_SIZEX => 8,
--G_FONT_SIZEY => 12,
--G_SCR_STARTX => 128,
--G_SCR_STARTY => 128,
--G_SCR_SIZEX  => 32,
--G_SCR_SIZEY  => 1
--)
--port map(
--p_in_ram_adr  => (others => '0'),--std_logic_vector(i_ram_adr(11 downto 0)),
--p_in_ram_din  => (others => '0'),--std_logic_vector(i_ram_din(31 downto 0)),
--
----SYNC
--p_out_vd      => i_vdtxt,
--p_in_vd       => i_vdin,
--p_in_vsync    => i_vga_vs,
--p_in_hsync    => i_vga_hs,
--p_in_pixen    => i_pix_den,
--p_in_pixcnt   => i_pixcnt,
--p_in_linecnt  => i_linecnt,
--
--p_out_tst     => open,--tst_char_screen_out,
--
----System
--p_in_clk      => i_vga_pix_clk,
--p_in_rst      => p_in_rst
--);

----Gray Scale
--p_out_video.adv7123_dg <= (others => '0');
--p_out_video.adv7123_db <= (others => '0');
--p_out_video.adv7123_dr <= i_vdtxt((10 * 1) - 1 downto (10 * 0));
------Color
----p_out_video.adv7123_dg <= i_vdtxt((10 * 1) - 1 downto (10 * 0));
----p_out_video.adv7123_db <= i_vdtxt((10 * 2) - 1 downto (10 * 1));
----p_out_video.adv7123_dr <= i_vdtxt((10 * 3) - 1 downto (10 * 2));

--process(i_vga_pix_clk)
--begin
--  if rising_edge(i_vga_pix_clk) then
--    tst_vdtxt <= i_vdtxt;
--  end if;
--end process;

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
p_out_den      => i_pix_den,

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

p_out_video.adv7123_blank_n <= i_pix_den;
p_out_video.adv7123_sync_n  <= '0';
p_out_video.adv7123_psave_n <= '1';--Power Down OFF
p_out_video.adv7123_clk     <= not i_tv_pix_clk;

p_out_fifo_rd <= i_pix_den and i_vout_work;

p_out_video.vga_hs <= '0';
p_out_video.vga_vs <= '0';

--gen_tv
process(i_tv_pix_clk)
begin
if rising_edge(i_tv_pix_clk) then
  if p_in_rst = '1' then
    i_rdy <= '0';
    sr_vfr_start <= (others => '0');
    i_vout_work <= '0';

  else
    i_rdy <= p_in_rdy;
    sr_vfr_start <= i_tv_field & sr_vfr_start(0 to 0);

    if i_rdy = '1' then
      if sr_vfr_start(0) = '0' and sr_vfr_start(1) = '1' and p_in_fifo_empty = '0' then
        i_vout_work <= '1';
      end if;
    else
      i_vout_work <= '0';
    end if;

  end if;
end if;
end process;

--gen_tv
gen_tst_off : if strcmp(G_TEST_PATTERN, "OFF") generate
begin
--gen : for i in 0 to p_out_video.adv7123_db'length - 1 generate
--p_out_video.adv7123_db(i) <= p_in_fifo_do(5);
--p_out_video.adv7123_dg(i) <= p_in_fifo_do(6);
--p_out_video.adv7123_dr(i) <= p_in_fifo_do(7);
--end generate;
p_out_video.adv7123_dr <= std_logic_vector(RESIZE(UNSIGNED(p_in_fifo_do((G_VDWIDTH * 1) - 1 downto (G_VDWIDTH * 0))), p_out_video.adv7123_dr'length));
p_out_video.adv7123_db <= std_logic_vector(RESIZE(UNSIGNED(p_in_fifo_do((G_VDWIDTH * 1) - 1 downto (G_VDWIDTH * 0))), p_out_video.adv7123_db'length));
p_out_video.adv7123_dg <= std_logic_vector(RESIZE(UNSIGNED(p_in_fifo_do((G_VDWIDTH * 1) - 1 downto (G_VDWIDTH * 0))), p_out_video.adv7123_dg'length));

end generate gen_tst_off;

--gen_tv
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
    if i_pix_den = '0' then
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

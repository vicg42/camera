-------------------------------------------------------------------------
-- Company     : Yansar
-- Engineer    : Golovachenko Victor
--
-- Create Date : 13.06.2014 12:31:35
-- Module Name : caamera_main
--
-- ����������/�������� :
--
-- Revision:
-- Revision 0.01 - File Created
--
-------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.reduce_pack.all;
use work.vicg_common_pkg.all;
use work.clocks_pkg.all;
use work.ccd_vita25K_pkg.all;
use work.prj_cfg.all;

entity test_ccd_main is
port(
pin_out_TP2         : out   std_logic_vector(2 downto 0);
pin_out_led         : out   std_logic_vector(0 downto 0);
pin_in_btn          : in    std_logic;

--------------------------------------------------
--CCD
--------------------------------------------------
pin_in_ccd          : in   TCCD_pinin;
pin_out_ccd         : out  TCCD_pinout;

--------------------------------------------------
--Reference clock
--------------------------------------------------
pin_in_refclk       : in   TRefclk_pinin
);
end entity;

architecture struct of test_ccd_main is


component debounce is
generic(
G_PUSH_LEVEL : std_logic := '0'; --���. ������� ����� ������ ������
G_DEBVAL : integer := 4
);
port(
p_in_btn  : in    std_logic;
p_out_btn : out   std_logic;

p_in_clk_en : in    std_logic;
p_in_clk    : in    std_logic
);
end component;

component fpga_test_01
generic(
G_BLINK_T05   : integer:=10#125#; -- 1/2 ������� ������� ����������.(����� � ms)
G_CLK_T05us   : integer:=10#1000# -- ���-�� �������� ������� ����� p_in_clk
                                  -- �������������_ � 1/2 ������� 1us
);
port(
p_out_test_led : out   std_logic;--������� ����������
p_out_test_done: out   std_logic;--������ �������� � '1' ����� 3 ���.

p_out_1us      : out   std_logic;
p_out_1ms      : out   std_logic;
-------------------------------
--System
-------------------------------
p_in_clk       : in    std_logic;
p_in_rst       : in    std_logic
);
end component;

component clocks is
generic(
G_VOUT_TYPE : string := "VGA"
);
port(
p_out_rst  : out   std_logic;
p_out_gclk : out   std_logic_vector(7 downto 0);

p_in_clk   : in    TRefclk_pinin
);
end component;

component ccd_vita25K is
generic(
G_SIM : string := "OFF"
);
port(
p_in_ccd   : in   TCCD_pinin;
p_out_ccd  : out  TCCD_pinout;

p_out_video_vs  : out std_logic;
p_out_video_hs  : out std_logic;
p_out_video_den : out std_logic;
p_out_video_d   : out std_logic_vector((C_PCFG_CCD_LVDS_COUNT
                                          * C_PCFG_CCD_BIT_PER_PIXEL) - 1 downto 0);
p_out_video_clk : out std_logic;

p_out_init_done : out  std_logic;
p_out_detect_tr : out  std_logic;

p_out_tst       : out   std_logic_vector(31 downto 0);
p_in_tst        : in    std_logic_vector(31 downto 0);

p_in_refclk : in   std_logic;
p_in_ccdclk : in   std_logic;
p_in_ccdclk2 : in   std_logic;
p_in_rst    : in   std_logic
);
end component;


signal i_rst              : std_logic;
signal g_usrclk           : std_logic_vector(7 downto 0);
signal g_usr_highclk      : std_logic;
signal i_video_d          : std_logic_vector((C_PCFG_CCD_LVDS_COUNT
                                               * C_PCFG_CCD_BIT_PER_PIXEL) - 1 downto 0);
--signal i_video_d          : std_logic_vector(256 - 1 downto 0);
signal i_video_d_clk      : std_logic;
signal i_video_vs         : std_logic;
signal i_video_hs         : std_logic;
signal i_video_den        : std_logic;

signal i_test_led         : std_logic_vector(1 downto 0);
signal i_1ms              : std_logic;
signal i_btn_push         : std_logic;
signal i_btn              : std_logic;
signal sr_btn_push        : unsigned(0 to 1);
signal sr_video_vs        : unsigned(0 to 1) := (others => '1');

signal i_ccd_init_done    : std_logic;
signal i_ccd_tst_in       : std_logic_vector(31 downto 0);
signal i_ccd_tst_out      : std_logic_vector(31 downto 0);
signal i_ccd_out          : TCCD_pinout;
signal i_ccd_detect_tr    : std_logic;

signal tst_ccd_syn       : std_logic;
signal sr_tst_ccd_syn    : std_logic;
signal tst_1ms           : std_logic;

signal tst_vfr_pixcount  : unsigned(15 downto 0);
signal tst_vfr_rowcount  : unsigned(15 downto 0);
signal tst_vfr_cfg       : unsigned(15 downto 0);
signal tst_vfr_synwidth  : unsigned(15 downto 0);
signal tst_vtest_en      : std_logic := '0';
signal tst_mem_ctrl_rdy  : std_logic := '0';
signal tst_vctrl_in      : std_logic_vector(31 downto 0);
signal tst_vctrl_out     : std_logic_vector(31 downto 0);
signal tst_vbufo_do      : std_logic_vector(31 downto 0);
signal tst_video_d       : std_logic_vector(i_video_d'range);
signal tst_video_vs      : std_logic;
signal tst_video_hs      : std_logic;
signal tst_video_den     : std_logic;

signal i_ccd_clkref      : std_logic;
signal i_ccd_clk         : std_logic;
signal i_ccd_clk2        : std_logic;

attribute keep : string;
attribute keep of g_usrclk : signal is "true";


--MAIN
begin


--***********************************************************
--��������� ������ �������:
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

i_ccd_clkref <= g_usrclk(0);
i_ccd_clk    <= g_usrclk(1);
i_ccd_clk2   <= g_usrclk(7);



--***********************************************************
--
--***********************************************************
pin_out_ccd <= i_ccd_out;

m_ccd : ccd_vita25K
generic map(
G_SIM => C_PCFG_SIM
)
port map(
p_in_ccd   => pin_in_ccd ,
p_out_ccd  => i_ccd_out,--pin_out_ccd,

p_out_video_vs  => i_video_vs,
p_out_video_hs  => i_video_hs,
p_out_video_den => i_video_den,
p_out_video_d   => i_video_d,
p_out_video_clk => i_video_d_clk,

p_out_init_done => i_ccd_init_done,
p_out_detect_tr => i_ccd_detect_tr,

p_out_tst   => i_ccd_tst_out,
p_in_tst    => i_ccd_tst_in,

p_in_refclk => i_ccd_clkref,--g_usrclk(0),
p_in_ccdclk => i_ccd_clk   ,--g_usrclk(1),
p_in_ccdclk2 => i_ccd_clk2   ,--g_usrclk(1),
p_in_rst    => i_rst
);



--***********************************************************
--��������������� ����
--***********************************************************
--gen_tp : for i in 1 to (C_PCFG_CCD_LVDS_COUNT - 1) generate
--pin_out_TP(i - 1) <= OR_reduce(i_video_d((C_PCFG_CCD_BIT_PER_PIXEL * (i + 1)) - 1 downto (C_PCFG_CCD_BIT_PER_PIXEL * i)));
--end generate;
--pin_out_TP2(0) <= i_ccd_tst_out(16);--spi --OR_reduce(i_mem_ctrl_status.rdy);--
--pin_out_TP2(1) <= i_ccd_tst_out(3);--clk:fpga -> ccd --i_video_vs;--
--pin_out_TP2(2) <= i_ccd_tst_out(7);--clk:fpga <- ccd --i_btn_push;--

pin_out_led(0) <= OR_reduce(tst_video_d);
--pin_out_led(1) <= i_test_led(0);

pin_out_TP2(0) <= '0';--tst_video_vs  and tst_video_hs  and tst_video_den;
pin_out_TP2(1) <= i_ccd_init_done and i_ccd_detect_tr;
pin_out_TP2(2) <= OR_reduce(i_ccd_tst_out);


m_led1_tst: fpga_test_01
generic map(
G_BLINK_T05   =>10#250#,
G_CLK_T05us   =>10#155#
)
port map(
p_out_test_led => i_test_led(0),
p_out_test_done=> open,

p_out_1us      => open,
p_out_1ms      => i_1ms,
-------------------------------
--System
-------------------------------
p_in_clk       => g_usrclk(1),
p_in_rst       => i_rst
);


m_button : debounce
generic map(
G_PUSH_LEVEL => '0',
G_DEBVAL => 4
)
port map(
p_in_btn  => pin_in_btn,
p_out_btn => i_btn_push,

p_in_clk_en => i_1ms,
p_in_clk    => g_usrclk(1)
);

i_ccd_tst_in(0) <= i_btn_push;
i_ccd_tst_in(i_ccd_tst_in'length - 1 downto 1) <= (others => '0');



--tst_vtest_en <= '1';
process(g_usrclk(6))
begin
  if rising_edge(g_usrclk(6)) then
    sr_btn_push <= i_btn_push & sr_btn_push(0 to 0);
    sr_video_vs <= i_video_vs & sr_video_vs(0 to 0);

    if sr_btn_push(0) = '1' and sr_btn_push(1) = '0' then
      i_btn <= not i_btn;
    end if;

    if i_btn = '1' then --or i_dbg_ctrl_out.glob.start_vout = '1'
      if sr_video_vs(0) = '0' and sr_video_vs(1) = '1' then
        tst_vtest_en <= '1';
      end if;
    else
      tst_vtest_en <= '0';
    end if;

  end if;
end process;


process(i_video_d_clk)
begin
  if rising_edge(i_video_d_clk) then

--    if i_ccd_init_done = '1' and i_ccd_detect_tr = '1' then
--      if i_video_vs = '1' and i_video_hs = '1' and i_video_den = '1' then
        tst_video_d <= i_video_d;
--        tst_video_vs  <= i_video_vs ;
--        tst_video_hs  <= i_video_hs ;
--        tst_video_den <= i_video_den;
--      end if;
--    end if;

  end if;
end process;

--END MAIN
end architecture;

-------------------------------------------------------------------------
-- Company     : Yansar
-- Engineer    : Golovachenko Victor
--
-- Create Date : 13.06.2014 12:31:35
-- Module Name : camera_main
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
use work.reduce_pack.all;
use work.vicg_common_pkg.all;
use work.clocks_pkg.all;
use work.ccd_vita25K_pkg.all;
use work.prj_cfg.all;
use work.vout_pkg.all;
--use work.mem_ctrl_pkg.all;
--use work.mem_wr_pkg.all;
--use work.video_ctrl_pkg.all;

library unisim;
use unisim.vcomponents.all;

entity camera_main is
port(
--------------------------------------------------
--Технологический порт
--------------------------------------------------
--pin_out_TP          : out std_logic_vector(((C_PCFG_CCD_LVDS_COUNT - 1)
--                                          * C_PCFG_CCD_BIT_PER_PIXEL) - 1 downto 0);
--pin_out_TP2          : out   std_logic_vector(2 downto 0);
pin_out_led         : out   std_logic_vector(0 downto 0);
pin_in_btn          : in    std_logic;

--------------------------------------------------
--CCD
--------------------------------------------------
pin_in_ccd          : in   TCCD_pinin;
pin_out_ccd         : out  TCCD_pinout;

----------------------------------------------------
----Video Output
----------------------------------------------------
--pin_out_video       : out  TVout_pinout;

----------------------------------------------------
----Memory banks
----------------------------------------------------
--pin_out_phymem      : out   TMEMCTRL_pinouts;
--pin_inout_phymem    : inout TMEMCTRL_pininouts;

--------------------------------------------------
--Reference clock
--------------------------------------------------
pin_in_refclk       : in    TRefclk_pinin
);
end entity;

architecture struct of camera_main is

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
end component;

component clocks is
generic(
G_VOUT_TYPE : string := "VGA"
);
port(
p_out_rst  : out   std_logic;
p_out_gclk : out   std_logic_vector(6 downto 0);

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
p_in_rst    : in   std_logic
);
end component;

component vout is
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
p_in_clk      : in   std_logic;
p_in_rst      : in   std_logic
);
end component;

--component video_ctrl is
--generic(
--G_USR_OPT : std_logic_vector(7 downto 0) := (others=>'0');
--G_DBGCS  : string:="OFF";
--G_CCD_DWIDTH : integer := 256;
--G_MEM_AWIDTH : integer:=32;
--G_MEMWR_DWIDTH : integer:=32;
--G_MEMRD_DWIDTH : integer:=32
--);
--port(
---------------------------------
----CFG
---------------------------------
--p_in_vwrite_en        : in   std_logic;
--p_in_memtrn_lenwr     : in   std_logic_vector(7 downto 0);
--p_in_memtrn_lenrd     : in   std_logic_vector(7 downto 0);
--p_in_vwrite_prm       : in   TWriterVCHParams;
--p_in_vread_prm        : in   TReaderVCHParams;
--
---------------------------------
----CCD
---------------------------------
--p_in_ccd_d            : in    std_logic_vector(G_CCD_DWIDTH - 1 downto 0);
--p_in_ccd_den          : in    std_logic;
--p_in_ccd_hs           : in    std_logic;
--p_in_ccd_vs           : in    std_logic;
--p_in_ccd_dclk         : in    std_logic;
--
---------------------------------
----VBUFO
---------------------------------
--p_in_vbufo_rdclk      : in    std_logic;
--p_out_vbufo_do        : out   std_logic_vector(G_MEMRD_DWIDTH - 1 downto 0);
--p_in_vbufo_rd         : in    std_logic;
--p_out_vbufo_empty     : out   std_logic;
--
-----------------------------------
----MEM
-----------------------------------
----CH WRITE
--p_out_memwr           : out   TMemIN;
--p_in_memwr            : in    TMemOUT;
----CH READ
--p_out_memrd           : out   TMemIN;
--p_in_memrd            : in    TMemOUT;
--
---------------------------------
----Технологический
---------------------------------
--p_in_tst              : in    std_logic_vector(31 downto 0);
--p_out_tst             : out   std_logic_vector(31 downto 0);
--
---------------------------------
----System
---------------------------------
--p_in_clk              : in    std_logic;
--p_in_rst              : in    std_logic
--);
--end component;

signal i_rst              : std_logic;
signal g_usrclk           : std_logic_vector(6 downto 0);
signal g_usr_highclk      : std_logic;
signal i_video_d          : std_logic_vector((C_PCFG_CCD_LVDS_COUNT
                                               * C_PCFG_CCD_BIT_PER_PIXEL) - 1 downto 0);
signal i_video_d_clk      : std_logic;
signal i_video_vs         : std_logic;
signal i_video_hs         : std_logic;
signal i_video_den        : std_logic;

--signal i_vbufo_do         : std_logic_vector(C_AXIS_DWIDTH(1) - 1 downto 0) := (others => '0');
signal i_vbufo_do         : std_logic_vector(31 downto 0) := (others => '0');
signal i_vbufo_rd         : std_logic;
signal i_vbufo_empty      : std_logic;

--signal i_vctrl_vwrite_en    : std_logic;
--signal i_vctrl_memtrn_lenwr : std_logic_vector(7 downto 0);
--signal i_vctrl_memtrn_lenrd : std_logic_vector(7 downto 0);
--signal i_vctrl_vwrite_prm   : TWriterVCHParams;
--signal i_vctrl_vread_prm    : TReaderVCHParams;
--
--signal i_memin_ch         : TMemINCh;
--signal i_memout_ch        : TMemOUTCh;
--signal i_memin_bank       : TMemINBank;
--signal i_memout_bank      : TMemOUTBank;
--
--signal i_arb_mem_rst      : std_logic;
--signal i_arb_memin        : TMemIN;
--signal i_arb_memout       : TMemOUT;
--signal i_arb_mem_tst_out  : std_logic_vector(31 downto 0);
--
--signal i_mem_ctrl_status  : TMEMCTRL_status;
--signal i_mem_ctrl_sysin   : TMEMCTRL_sysin;
--signal i_mem_ctrl_sysout  : TMEMCTRL_sysout;

signal i_vout_clkin       : std_logic;

signal i_test_led         : std_logic_vector(1 downto 0);
signal i_1ms              : std_logic;
signal i_debcnt           : unsigned(8 downto 0) := (others => '0');
signal i_btn_push         : std_logic;
signal sr_btn_push        : std_logic_vector(0 to 1) := (others =>'0');
signal i_btn_push_edge    : std_logic := '0';

signal i_ccd_init_done    : std_logic;
signal i_ccd_tst_in       : std_logic_vector(31 downto 0);
signal i_ccd_tst_out      : std_logic_vector(31 downto 0);
signal i_ccd_out          : TCCD_pinout;

signal i_video_out        : TVout_pinout;
signal tst_vout_out       : std_logic_vector(31 downto 0);

signal tst_ccd_syn       : std_logic;
signal sr_tst_ccd_syn    : std_logic;

attribute keep : string;
attribute keep of g_usrclk : signal is "true";
attribute keep of g_usr_highclk : signal is "true";


--MAIN
begin


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

--g_usr_highclk <= i_mem_ctrl_sysout.clk;
--i_mem_ctrl_sysin.ref_clk <= g_usrclk(3);
--i_mem_ctrl_sysin.clk <= g_usrclk(4);
--
--i_mem_ctrl_sysin.rst <= i_rst;
--i_arb_mem_rst <= not OR_reduce(i_mem_ctrl_status.rdy);

i_vout_clkin <= g_usrclk(2);

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
p_out_detect_tr => open,

p_out_tst   => i_ccd_tst_out,
p_in_tst    => i_ccd_tst_in,

p_in_refclk => g_usrclk(0),
p_in_ccdclk => g_usrclk(1),
p_in_rst    => i_rst
);


----***********************************************************
----
----***********************************************************
--m_video_out : vout
--generic map(
--G_VOUT_TYPE => C_PCGF_VOUT_TYPE,
--G_TEST_PATTERN => C_PCGF_VOUT_TEST
--)
--port map(
----PHY
--p_out_video   => i_video_out,--pin_out_video,
--
--p_in_fifo_do  => i_vbufo_do,
--p_out_fifo_rd => i_vbufo_rd,
--p_in_fifo_empty => i_vbufo_empty,
--
--p_out_tst     => tst_vout_out,
--p_in_tst      => (others => '0'),
--
----System
--p_in_clk      => i_vout_clkin,
--p_in_rst      => i_rst
--);
--
--pin_out_video <= i_video_out;


----***********************************************************
----
----***********************************************************
--i_vctrl_vwrite_en    <= i_video_vs;
--i_vctrl_memtrn_lenwr <= std_logic_vector(TO_UNSIGNED(16#80#,i_vctrl_memtrn_lenwr'length));
--i_vctrl_memtrn_lenrd <= std_logic_vector(TO_UNSIGNED(16#80#,i_vctrl_memtrn_lenrd'length));
--
--i_vctrl_vwrite_prm(0).fr_size.skip.pix  <= std_logic_vector(TO_UNSIGNED(10#00#, 16));
--i_vctrl_vwrite_prm(0).fr_size.skip.row  <= std_logic_vector(TO_UNSIGNED(10#00#, 16));
--i_vctrl_vwrite_prm(0).fr_size.activ.pix <= std_logic_vector(TO_UNSIGNED(10#5120#, 16));
--i_vctrl_vwrite_prm(0).fr_size.activ.row <= std_logic_vector(TO_UNSIGNED(10#5120#, 16));
--
--i_vctrl_vread_prm(0).fr_size.skip.pix  <= std_logic_vector(TO_UNSIGNED(10#00#, 16));
--i_vctrl_vread_prm(0).fr_size.skip.row  <= std_logic_vector(TO_UNSIGNED(10#00#, 16));
--i_vctrl_vread_prm(0).fr_size.activ.pix <= std_logic_vector(TO_UNSIGNED(10#5120#, 16));
--i_vctrl_vread_prm(0).fr_size.activ.row <= std_logic_vector(TO_UNSIGNED(10#5120#, 16));
--
--m_vctrl : video_ctrl
--generic map(
--G_USR_OPT => (others=>'0'),
--G_DBGCS  => "OFF",
--G_CCD_DWIDTH => 256,
--G_MEM_AWIDTH => C_AXI_AWIDTH,
--G_MEMWR_DWIDTH => C_AXIS_DWIDTH(0),
--G_MEMRD_DWIDTH => C_AXIS_DWIDTH(1)
--)
--port map(
---------------------------------
----CFG
---------------------------------
--p_in_vwrite_en        => i_vctrl_vwrite_en   ,
--p_in_memtrn_lenwr     => i_vctrl_memtrn_lenwr,
--p_in_memtrn_lenrd     => i_vctrl_memtrn_lenrd,
--p_in_vwrite_prm       => i_vctrl_vwrite_prm  ,
--p_in_vread_prm        => i_vctrl_vread_prm   ,
--
---------------------------------
----CCD
---------------------------------
--p_in_ccd_d            => i_video_d(256 - 1 downto 0),
--p_in_ccd_den          => i_video_den,
--p_in_ccd_hs           => i_video_hs,
--p_in_ccd_vs           => i_video_vs,
--p_in_ccd_dclk         => i_video_d_clk,
--
---------------------------------
----VBUFO
---------------------------------
--p_in_vbufo_rdclk      => g_usrclk(2),
--p_out_vbufo_do        => i_vbufo_do,
--p_in_vbufo_rd         => i_vbufo_rd,
--p_out_vbufo_empty     => i_vbufo_empty,
--
-----------------------------------
----MEM
-----------------------------------
----CH WRITE
--p_out_memwr           => i_memin_ch(0),
--p_in_memwr            => i_memout_ch(0),
----CH READ
--p_out_memrd           => i_memin_ch(1),
--p_in_memrd            => i_memout_ch(1),
--
---------------------------------
----Технологический
---------------------------------
--p_in_tst              => (others => '0'),
--p_out_tst             => open,
--
---------------------------------
----System
---------------------------------
--p_in_clk              => g_usrclk(2),
--p_in_rst              => i_rst
--);
--
----***********************************************************
----
----***********************************************************
----Арбитр контроллера памяти
--m_mem_arb : mem_arb
--generic map(
--G_CH_COUNT   => C_MEM_ARB_CH_COUNT,
--G_MEM_AWIDTH => C_AXI_AWIDTH,
--G_MEM_DWIDTH => C_AXIM_DWIDTH
--)
--port map(
---------------------------------
----Связь с пользователями ОЗУ
---------------------------------
--p_in_memch  => i_memin_ch,
--p_out_memch => i_memout_ch,
--
---------------------------------
----Связь с mem_ctrl.vhd
---------------------------------
--p_out_mem   => i_arb_memin,
--p_in_mem    => i_arb_memout,
--
---------------------------------
----Технологический
---------------------------------
--p_in_tst    => (others=>'0'),
--p_out_tst   => i_arb_mem_tst_out,
--
---------------------------------
----System
---------------------------------
--p_in_clk    => g_usr_highclk,
--p_in_rst    => i_arb_mem_rst
--);
--
----Подключаем арбитра ОЗУ к соотв банку
--i_memin_bank(0) <= i_arb_memin;
--i_arb_memout    <= i_memout_bank(0);
--
----Core Memory controller
--m_mem_ctrl : mem_ctrl
--generic map(
--G_SIM => C_PCFG_SIM
--)
--port map(
--------------------------------------
----User Post
--------------------------------------
--p_in_mem   => i_memin_bank,
--p_out_mem  => i_memout_bank,
--
--------------------------------------
----Memory physical interface
--------------------------------------
--p_out_phymem    => pin_out_phymem,
--p_inout_phymem  => pin_inout_phymem,
--
--------------------------------------
----Memory status
--------------------------------------
--p_out_status    => i_mem_ctrl_status,
--
--------------------------------------
----System
--------------------------------------
--p_out_sys       => i_mem_ctrl_sysout,
--p_in_sys        => i_mem_ctrl_sysin
--);


--***********************************************************
--Технологический порт
--***********************************************************
--gen_tp : for i in 1 to (C_PCFG_CCD_LVDS_COUNT - 1) generate
--pin_out_TP(i - 1) <= OR_reduce(i_video_d((C_PCFG_CCD_BIT_PER_PIXEL * (i + 1)) - 1 downto (C_PCFG_CCD_BIT_PER_PIXEL * i)));
--end generate;
--pin_out_TP2(0) <= tst_vout_out(0);--OR_reduce(i_ccd_tst_out);
--pin_out_TP2(1) <= i_ccd_out.sck;
--pin_out_TP2(2) <= i_vbufo_rd;
--
--pin_out_led(1) <= i_test_led(0);
pin_out_led(0) <= i_video_vs or i_video_hs or i_video_den or OR_reduce(i_ccd_tst_out) or i_ccd_init_done;-- or sr_tst_ccd_syn;--OR_reduce(i_mem_ctrl_status.rdy);


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


process(i_rst, g_usrclk(5))
begin
  if i_rst = '1' then
    i_debcnt <= (others => '0');
    i_btn_push <= '0';

  elsif rising_edge(g_usrclk(5)) then

    if pin_in_btn = '1' then
      i_debcnt <= (others => '0');
      i_btn_push <= '0';
    else
      if i_1ms = '1' then
        if i_debcnt = TO_UNSIGNED(80 ,i_debcnt'length) then
          i_btn_push <= '1';
        else
          i_debcnt <= i_debcnt + 1;
        end if;
      end if;
    end if;

  end if;
end process;


process(g_usrclk(1))
begin
  if rising_edge(g_usrclk(1)) then
    sr_btn_push <= i_btn_push & sr_btn_push(0 to 0);
    i_btn_push_edge <= sr_btn_push(0) and not sr_btn_push(1);
  end if;
end process;

i_ccd_tst_in(0) <= i_btn_push_edge;
i_ccd_tst_in(i_ccd_tst_in'length - 1 downto 1) <= (others => '0');


--m_ibufds_sync : IBUFDS
--generic map (
--DIFF_TERM  => TRUE
--)
--port map (
--I   => pin_in_ccd_syn_p,
--IB  => pin_in_ccd_syn_n,
--O   => tst_ccd_syn
--);
--
--process(g_usrclk(1))
--begin
--  if rising_edge(g_usrclk(1)) then
--    sr_tst_ccd_syn <= i_ccd_tst_out(1);
--  end if;
--end process;


--END MAIN
end architecture;

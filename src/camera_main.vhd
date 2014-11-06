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
use work.ccd_pkg.all;
use work.prj_cfg.all;
use work.vout_pkg.all;
use work.mem_ctrl_pkg.all;
use work.mem_wr_pkg.all;
use work.video_ctrl_pkg.all;
use work.dbg_pkg.all;

library unisim;
use unisim.vcomponents.all;

entity camera_main is
port(
--------------------------------------------------
--Технологический порт
--------------------------------------------------
--pin_out_TP          : out std_logic_vector(((C_PCFG_CCD_LVDS_COUNT - 1)
--                                          * C_PCFG_CCD_PIXBIT) - 1 downto 0);
pin_out_TP2         : out   std_logic_vector(2 downto 0);
pin_out_led         : out   std_logic_vector(0 downto 0);
pin_in_btn          : in    std_logic;

--------------------------------------------------
--CCD
--------------------------------------------------
pin_in_ccd          : in   TCCD_pinin;
pin_out_ccd         : out  TCCD_pinout;

--------------------------------------------------
--Video Output
--------------------------------------------------
pin_out_video       : out  TVout_pinout;
pin_in_tv_det       : in   std_logic;

--------------------------------------------------
--Memory banks
--------------------------------------------------
pin_out_phymem      : out   TMEMCTRL_pinouts;
pin_inout_phymem    : inout TMEMCTRL_pininouts;

--------------------------------------------------
--Reference clock
--------------------------------------------------
pin_in_refclk       : in    TRefclk_pinin
);
end entity camera_main;

architecture struct of camera_main is

--component data2axistream is
--generic(
--G_VFR_PIX_COUNT : integer := 8;
--G_VFR_ROW_COUNT : integer := 8;
--G_BUFI_DWIDTH   : integer := 8;
--G_AXI_DWIDTH    : integer := 8
--);
--port(
-----------------------------------
------
-----------------------------------
----p_in_vfr_pix     : in    std_logic_vector(15 downto 0);
----p_in_vfr_row     : in    std_logic_vector(15 downto 0);
--p_in_work       : in    std_logic;
--
---------------------------------
----
---------------------------------
--p_in_bufi_dout  : in    std_logic_vector(G_BUFI_DWIDTH - 1 downto 0);
--p_out_bufi_rd   : out   std_logic;
--p_in_bufi_empty : in    std_logic;
--
--p_out_axi_stream_tdata  : out   std_logic_vector(G_AXI_DWIDTH - 1 downto 0);
--p_out_axi_stream_tvalid : out   std_logic;
--p_out_axi_stream_tuser  : out   std_logic; --SOF (start of frame)
--p_out_axi_stream_tlast  : out   std_logic; --EOL (End of line)
--p_in_axi_stream_tready  : in    std_logic;
--
---------------------------------
----Технологические сигналы
---------------------------------
--p_in_tst             : in    std_logic_vector(31 downto 0);
--p_out_tst            : out   std_logic_vector(31 downto 0);
--
---------------------------------
----System
---------------------------------
--p_in_clk             : in    std_logic;
--p_in_rst             : in    std_logic
--);
--end component data2axistream;
--
--component system is
--port (
--p_in_irq : in std_logic;
--p_in_rst : in std_logic;
--p_out_gpio0 : out std_logic_vector(7 downto 0);
--p_in_clk : in std_logic;
--p_in_osdvin_s_axis_tvalid : in std_logic;
--p_in_osdvin_s_axis_tlast : in std_logic;
--p_in_osdvin_s_axis_tuser : in std_logic;
--p_in_osdvin_s_axis_tdata : in std_logic_vector(31 downto 0);
--p_out_osdvin_s_axis_tready : out std_logic;
--p_in_osd_aclk : in std_logic;
--p_in_osd_aresetn : in std_logic;
--p_out_osdvout_m_axis_tvalid : out std_logic;
--p_out_osdvout_m_axis_tlast : out std_logic;
--p_out_osdvout_m_axis_tuser : out std_logic;
--p_out_osdvout_m_axis_tdata : out std_logic_vector(31 downto 0);
--p_in_osdvout_m_axis_tready : in std_logic
--);
--end component system;

component dbg_ctrl is
port(
p_out_usr     : out  TDGB_ctrl_out;
p_in_usr      : in   TDGB_ctrl_in;

p_in_clk      : in   std_logic
);
end component dbg_ctrl;

component vtest_gen is
generic(
G_DBG : string := "OFF";
G_VD_WIDTH : integer := 80;
G_VSYN_ACTIVE : std_logic := '1'
);
port(
--CFG
p_in_cfg      : in   std_logic_vector(15 downto 0);
p_in_vpix     : in   std_logic_vector(15 downto 0);
p_in_vrow     : in   std_logic_vector(15 downto 0);
p_in_syn_h    : in   std_logic_vector(15 downto 0);
p_in_syn_v    : in   std_logic_vector(15 downto 0);

--Test Video
p_out_vd      : out  std_logic_vector(G_VD_WIDTH - 1 downto 0);
p_out_vs      : out  std_logic;
p_out_hs      : out  std_logic;

--Технологический
p_in_tst      : in   std_logic_vector(31 downto 0);
p_out_tst     : out  std_logic_vector(31 downto 0);

--System
p_in_clk_en   : in   std_logic;
p_in_clk      : in   std_logic;
p_in_rst      : in   std_logic
);
end component vtest_gen;

component debounce is
generic(
G_PUSH_LEVEL : std_logic := '0'; --Лог. уровень когда кнопка нажата
G_DEBVAL : integer := 4
);
port(
p_in_btn  : in    std_logic;
p_out_btn : out   std_logic;

p_in_clk_en : in    std_logic;
p_in_clk    : in    std_logic
);
end component debounce;

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

component clocks is
generic(
G_VOUT_TYPE : string := "VGA";
G_CCD_PIXBIT : integer := 10
);
port(
p_out_rst  : out   std_logic;
p_out_gclk : out   std_logic_vector(7 downto 0);

p_in_clk   : in    TRefclk_pinin
);
end component clocks;

component ccd_vita25K is
generic(
G_SIM : string := "OFF"
);
port(
p_in_ccd       : in   TCCD_pinin;
p_out_ccd      : out  TCCD_pinout;

p_out_vfr_data : out  std_logic_vector(((C_PCFG_CCD_LVDS_COUNT - C_PCFG_CCD_SYNC_LINE_COUNT)
                                    * selval(16, 32, C_PCFG_VDATA_PIXBIT = 8)) - 1 downto 0);
p_out_vfr_den  : out  std_logic;
p_out_vfr_vs   : out  std_logic;
p_out_vfr_hs   : out  std_logic;
p_out_vfr_clk  : out  std_logic;

p_out_status   : out  std_logic_vector(C_CCD_STATUS_LAST_BIT downto 0);

p_out_tst      : out  std_logic_vector(31 downto 0);
p_in_tst       : in   std_logic_vector(31 downto 0);

p_in_refclk    : in   std_logic;
p_in_ccdclk    : in   std_logic;
p_in_rst       : in   std_logic
);
end component ccd_vita25K;

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

component video_ctrl is
generic(
G_USR_OPT      : std_logic_vector(7 downto 0) := (others=>'0');
G_DBGCS        : string := "OFF";
G_VBUFI_DWIDTH : integer := 32;
G_VBUFO_DWIDTH : integer := 32;
G_MEM_AWIDTH   : integer := 32;
G_MEMWR_DWIDTH : integer := 32;
G_MEMRD_DWIDTH : integer := 32
);
port(
-------------------------------
--CFG
-------------------------------
p_in_vwrite_en        : in   std_logic;
p_in_memtrn_lenwr     : in   std_logic_vector(7 downto 0);
p_in_memtrn_lenrd     : in   std_logic_vector(7 downto 0);
p_in_vwrite_prm       : in   TWriterVCHParams;
p_in_vread_prm        : in   TReaderVCHParams;
p_in_vread_sync       : in   std_logic;

-------------------------------
--CCD
-------------------------------
p_in_ccd_d            : in    std_logic_vector(G_VBUFI_DWIDTH - 1 downto 0);
p_in_ccd_den          : in    std_logic;
p_in_ccd_hs           : in    std_logic;
p_in_ccd_vs           : in    std_logic;
p_in_ccd_dclk         : in    std_logic;

-------------------------------
--VBUFO
-------------------------------
p_in_vbufo_rdclk      : in    std_logic;
p_out_vbufo_do        : out   std_logic_vector(G_VBUFO_DWIDTH - 1 downto 0);
p_in_vbufo_rd         : in    std_logic;
p_out_vbufo_empty     : out   std_logic;

---------------------------------
--MEM
---------------------------------
--CH WRITE
p_out_memwr           : out   TMemIN;
p_in_memwr            : in    TMemOUT;
--CH READ
p_out_memrd           : out   TMemIN;
p_in_memrd            : in    TMemOUT;

-------------------------------
--Технологический
-------------------------------
p_in_tst              : in    std_logic_vector(31 downto 0);
p_out_tst             : out   std_logic_vector(31 downto 0);

-------------------------------
--System
-------------------------------
p_in_clk              : in    std_logic;
p_in_rst              : in    std_logic
);
end component video_ctrl;

signal i_rst              : std_logic;
signal g_usrclk           : std_logic_vector(7 downto 0);
signal g_usr_highclk      : std_logic;

signal i_video_d          : std_logic_vector(((C_PCFG_CCD_LVDS_COUNT - C_PCFG_CCD_SYNC_LINE_COUNT)
                                          * selval(16, 32, C_PCFG_VDATA_PIXBIT = 8)) - 1 downto 0);
signal i_video_d_clk      : std_logic;
signal i_video_vs         : std_logic;
signal i_video_hs         : std_logic;
signal i_video_den        : std_logic;

signal i_vbufo_do         : std_logic_vector(C_CGF_VBUFO_DWIDTH - 1 downto 0) := (others => '0');
signal i_vbufo_rd         : std_logic;
signal i_vbufo_empty      : std_logic;

signal i_vctrl_vwrite_en    : std_logic;
signal i_vctrl_memtrn_lenwr : std_logic_vector(7 downto 0);
signal i_vctrl_memtrn_lenrd : std_logic_vector(7 downto 0);
signal i_vctrl_vwrite_prm   : TWriterVCHParams;
signal i_vctrl_vread_prm    : TReaderVCHParams;
signal i_vctrl_sync         : std_logic;

signal i_memin_ch         : TMemINCh;
signal i_memout_ch        : TMemOUTCh;
signal i_memin_bank       : TMemINBank;
signal i_memout_bank      : TMemOUTBank;

signal i_arb_mem_rst_n    : std_logic;
signal i_arb_mem_rst      : std_logic;
signal i_arb_memin        : TMemIN;
signal i_arb_memout       : TMemOUT;
signal i_arb_mem_tst_out  : std_logic_vector(31 downto 0);

signal i_mem_ctrl_status  : TMEMCTRL_status;
signal i_mem_ctrl_sysin   : TMEMCTRL_sysin;
signal i_mem_ctrl_sysout  : TMEMCTRL_sysout;

signal i_vout_clkin       : std_logic;

signal i_test_led         : std_logic_vector(1 downto 0);
signal i_1ms              : std_logic;
signal i_btn_push         : std_logic;
signal i_btn              : std_logic;
signal sr_btn_push        : unsigned(0 to 1);
signal sr_video_vs        : unsigned(0 to 1) := (others => '1');

signal i_ccd_status       : std_logic_vector(C_CCD_STATUS_LAST_BIT downto 0);
signal i_ccd_tst_in       : std_logic_vector(31 downto 0);
signal i_ccd_tst_out      : std_logic_vector(31 downto 0);
signal i_ccd_out          : TCCD_pinout;

signal i_video_out        : TVout_pinout;
signal tst_vout_out       : std_logic_vector(31 downto 0);

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

signal i_ccd_clkref      : std_logic;
signal i_ccd_clk         : std_logic;

signal i_dbg_ctrl_out    : TDGB_ctrl_out;
signal i_dbg_ctrl_in     : TDGB_ctrl_in;

signal i_cntdiv_memclkin : unsigned(10 downto 0);
signal i_cntdiv_memclkout : unsigned(10 downto 0);

signal tst_mem_rdy : std_logic;

--signal i_xps_led          : std_logic_vector(7 downto 0);
--
--signal i_xps_osdin_axi_tvalid : std_logic;
--signal i_xps_osdin_axi_tlast  : std_logic;
--signal i_xps_osdin_axi_tuser  : std_logic;
--signal i_xps_osdin_axi_tdata  : std_logic_vector(C_CGF_VBUFO_DWIDTH - 1 downto 0);
--signal i_xps_osdin_axi_tready : std_logic;
--
--signal i_xps_osdout_axi_tvalid: std_logic;
--signal i_xps_osdout_axi_tlast : std_logic;
--signal i_xps_osdout_axi_tuser : std_logic;
--signal i_xps_osdout_axi_tdata : std_logic_vector(C_CGF_VBUFO_DWIDTH - 1 downto 0);
--signal i_xps_osdout_axi_tready: std_logic;
--
--signal tst_xps_osdin_axi_tlast   : std_logic;
--signal tst_xps_osdin_axi_tuser   : std_logic;
--signal tst_xps_osdin_axi_tvalid  : std_logic;
--signal tst_xps_osdin_axi_tready  : std_logic;
--signal tst_xps_osdout_axi_tlast  : std_logic;
--signal tst_xps_osdout_axi_tuser  : std_logic;
--signal tst_xps_osdout_axi_tvalid : std_logic;
--signal tst_xps_osdout_axi_tready : std_logic;
--
--signal tmp_vbufo_do    : std_logic_vector(C_CGF_VBUFO_DWIDTH - 1 downto 0);
--signal tmp_vbufo_rd    : std_logic;
--signal tmp_vbufo_empty : std_logic;

attribute keep : string;
attribute keep of g_usrclk : signal is "true";
attribute keep of g_usr_highclk : signal is "true";
attribute keep of i_video_d_clk : signal is "true";



begin --architecture struct


--***********************************************************
--Установка частот проекта:
--***********************************************************
m_clocks : clocks
generic map(
G_VOUT_TYPE => C_PCGF_VOUT_TYPE,
G_CCD_PIXBIT => C_PCFG_CCD_PIXBIT
)
port map(
p_out_rst  => i_rst,
p_out_gclk => g_usrclk,

p_in_clk   => pin_in_refclk
);

i_ccd_clkref <= g_usrclk(0);
i_ccd_clk    <= g_usrclk(1);--g_usrclk(6);

g_usr_highclk <= i_mem_ctrl_sysout.clk;
i_mem_ctrl_sysin.ref_clk <= g_usrclk(3);
i_mem_ctrl_sysin.clk <= g_usrclk(4);

i_mem_ctrl_sysin.rst <= i_rst;
i_arb_mem_rst <= not OR_reduce(i_mem_ctrl_status.rdy);
i_arb_mem_rst_n <= OR_reduce(i_mem_ctrl_status.rdy);


--***********************************************************
--
--***********************************************************
pin_out_ccd <= i_ccd_out;

m_ccd : ccd_vita25K
generic map(
G_SIM => C_PCFG_SIM
)
port map(
p_in_ccd       => pin_in_ccd ,
p_out_ccd      => i_ccd_out,--pin_out_ccd,

p_out_vfr_data => i_video_d,
p_out_vfr_den  => i_video_den,
p_out_vfr_vs   => i_video_vs,
p_out_vfr_hs   => i_video_hs,
p_out_vfr_clk  => i_video_d_clk,

p_out_status   => i_ccd_status,

p_out_tst      => i_ccd_tst_out,
p_in_tst       => i_ccd_tst_in,

p_in_refclk    => i_ccd_clkref,
p_in_ccdclk    => i_ccd_clk   ,
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
p_out_video   => i_video_out,--pin_out_video,

p_in_fifo_do    => i_vbufo_do   , --i_xps_osdout_axi_tdata   ,--
p_out_fifo_rd   => i_vbufo_rd   , --i_xps_osdout_axi_tready  ,--
p_in_fifo_empty => i_vbufo_empty, --tmp_vbufo_empty          ,--

p_out_tst     => tst_vout_out,
p_in_tst      => (others => '0'),

--System
p_in_rdy      => tst_vctrl_out(9),--tst_vtest_en,
p_in_clk      => g_usrclk(2),
p_in_rst      => i_rst
);

pin_out_video <= i_video_out;

--tmp_vbufo_empty <= not i_xps_osdout_axi_tvalid;

--***********************************************************
--
--***********************************************************
i_vctrl_sync <= i_video_out.vga_vs;

i_vctrl_vwrite_en    <= tst_vtest_en;
i_vctrl_memtrn_lenwr <= std_logic_vector(TO_UNSIGNED(16#E0#, 8));
i_vctrl_memtrn_lenrd <= std_logic_vector(TO_UNSIGNED(16#10#, 8));
--i_vctrl_memtrn_lenwr <= i_dbg_ctrl_out.vout_memtrn_lenwr;
--i_vctrl_memtrn_lenrd <= i_dbg_ctrl_out.vout_memtrn_lenrd;

i_vctrl_vwrite_prm(0).fr_size.skip.pix  <= std_logic_vector(TO_UNSIGNED(10#00#, 16));
i_vctrl_vwrite_prm(0).fr_size.skip.row  <= std_logic_vector(TO_UNSIGNED(10#00#, 16));
i_vctrl_vwrite_prm(0).fr_size.activ.pix <= std_logic_vector(TO_UNSIGNED(C_PCFG_CCD_WIN_X, 16));
i_vctrl_vwrite_prm(0).fr_size.activ.row <= std_logic_vector(TO_UNSIGNED(C_PCFG_CCD_WIN_Y, 16));

i_vctrl_vread_prm(0).debayer_off <= '0';--i_dbg_ctrl_out.debayer_off;
i_vctrl_vread_prm(0).debayer_colorfst <= (others => '0');--i_dbg_ctrl_out.debayer_colorfst;
i_vctrl_vread_prm(0).frw_size <= i_vctrl_vwrite_prm(0).fr_size;
i_vctrl_vread_prm(0).fr_size.skip.pix  <= std_logic_vector(TO_UNSIGNED(C_PCFG_VOUT_START_X, 16));
i_vctrl_vread_prm(0).fr_size.skip.row  <= std_logic_vector(TO_UNSIGNED(C_PCFG_VOUT_START_Y, 16));
i_vctrl_vread_prm(0).fr_mirror.x <= '1';
i_vctrl_vread_prm(0).fr_mirror.y <= '1';
gen_tv1 : if strcmp(C_PCGF_VOUT_TYPE, "TV") generate begin
i_vctrl_vread_prm(0).fr_size.activ.pix <= std_logic_vector(TO_UNSIGNED(10#896#, 16));
i_vctrl_vread_prm(0).fr_size.activ.row <= std_logic_vector(TO_UNSIGNED(10#576#, 16));
end generate gen_tv1;
gen_vga : if strcmp(C_PCGF_VOUT_TYPE, "VGA") generate begin
--i_vctrl_vread_prm(0).fr_size.skip.pix  <= i_dbg_ctrl_out.vout_start_x;
--i_vctrl_vread_prm(0).fr_size.skip.row  <= i_dbg_ctrl_out.vout_start_y;
i_vctrl_vread_prm(0).fr_size.activ.pix <= std_logic_vector(TO_UNSIGNED(10#800#, 16));
i_vctrl_vread_prm(0).fr_size.activ.row <= std_logic_vector(TO_UNSIGNED(10#600#, 16));
end generate gen_vga;

m_vctrl : video_ctrl
generic map(
G_USR_OPT => (others=>'0'),
G_DBGCS  => "ON",
G_VBUFI_DWIDTH => i_video_d'length,
G_VBUFO_DWIDTH => C_CGF_VBUFO_DWIDTH,
G_MEM_AWIDTH => C_AXI_AWIDTH,
G_MEMWR_DWIDTH => C_AXIS_DWIDTH(0),
G_MEMRD_DWIDTH => C_AXIS_DWIDTH(1)
)
port map(
-------------------------------
--CFG
-------------------------------
p_in_vwrite_en        => i_vctrl_vwrite_en   ,
p_in_memtrn_lenwr     => i_vctrl_memtrn_lenwr,
p_in_memtrn_lenrd     => i_vctrl_memtrn_lenrd,
p_in_vwrite_prm       => i_vctrl_vwrite_prm  ,
p_in_vread_prm        => i_vctrl_vread_prm   ,
p_in_vread_sync       => i_vctrl_sync,

-------------------------------
--CCD
-------------------------------
p_in_ccd_d            => i_video_d,
p_in_ccd_den          => i_video_den,
p_in_ccd_hs           => i_video_hs,
p_in_ccd_vs           => i_video_vs,
p_in_ccd_dclk         => i_video_d_clk,

-------------------------------
--VBUFO
-------------------------------
p_in_vbufo_rdclk      => g_usrclk(2),
p_out_vbufo_do        => i_vbufo_do,
p_in_vbufo_rd         => i_vbufo_rd,
p_out_vbufo_empty     => i_vbufo_empty,

---------------------------------
--MEM
---------------------------------
--CH WRITE
p_out_memwr           => i_memin_ch(0),
p_in_memwr            => i_memout_ch(0),
--CH READ
p_out_memrd           => i_memin_ch(1),
p_in_memrd            => i_memout_ch(1),

-------------------------------
--Технологический
-------------------------------
p_in_tst              => tst_vctrl_in,
p_out_tst             => tst_vctrl_out,

-------------------------------
--System
-------------------------------
p_in_clk              => g_usr_highclk,
p_in_rst              => i_arb_mem_rst
);

--***********************************************************
--
--***********************************************************
--Арбитр контроллера памяти
m_mem_arb : mem_arb
generic map(
G_CH_COUNT   => C_MEM_ARB_CH_COUNT,
G_MEM_AWIDTH => C_AXI_AWIDTH,
G_MEM_DWIDTH => C_AXIM_DWIDTH
)
port map(
-------------------------------
--Связь с пользователями ОЗУ
-------------------------------
p_in_memch  => i_memin_ch,
p_out_memch => i_memout_ch,

-------------------------------
--Связь с mem_ctrl.vhd
-------------------------------
p_out_mem   => i_arb_memin,
p_in_mem    => i_arb_memout,

-------------------------------
--Технологический
-------------------------------
p_in_tst    => (others=>'0'),
p_out_tst   => i_arb_mem_tst_out,

-------------------------------
--System
-------------------------------
p_in_clk    => g_usr_highclk,
p_in_rst    => i_arb_mem_rst
);

--Подключаем арбитра ОЗУ к соотв банку
i_memin_bank(0) <= i_arb_memin;
i_arb_memout    <= i_memout_bank(0);

--Core Memory controller
m_mem_ctrl : mem_ctrl
generic map(
G_SIM => C_PCFG_SIM
)
port map(
------------------------------------
--User Post
------------------------------------
p_in_mem   => i_memin_bank,
p_out_mem  => i_memout_bank,

------------------------------------
--Memory physical interface
------------------------------------
p_out_phymem    => pin_out_phymem,
p_inout_phymem  => pin_inout_phymem,

------------------------------------
--Memory status
------------------------------------
p_out_status    => i_mem_ctrl_status,

------------------------------------
--System
------------------------------------
p_out_sys       => i_mem_ctrl_sysout,
p_in_sys        => i_mem_ctrl_sysin
);


--***********************************************************
--Технологический порт
--***********************************************************
--gen_tp : for i in 1 to (C_PCFG_CCD_LVDS_COUNT - 1) generate
--pin_out_TP(i - 1) <= OR_reduce(i_video_d((C_PCFG_CCD_PIXBIT * (i + 1)) - 1 downto (C_PCFG_CCD_PIXBIT * i)));
--end generate;
--pin_out_TP2(0) <= i_ccd_tst_out(16);--spi --OR_reduce(i_mem_ctrl_status.rdy);--
--pin_out_TP2(1) <= i_ccd_tst_out(3);--clk:fpga -> ccd --i_video_vs;--
--pin_out_TP2(2) <= i_ccd_tst_out(7);--clk:fpga <- ccd --i_btn_push;--

--pin_out_led(1) <= i_test_led(0);
--pin_out_led(0) <= OR_reduce(i_video_d) or OR_reduce(i_ccd_tst_out) or i_ccd_init_done;-- or -- or i_video_vs or i_video_hs or i_video_den;-- or sr_tst_ccd_syn;--OR_reduce(i_mem_ctrl_status.rdy);
pin_out_led(0) <= i_test_led(0);-- or OR_reduce(i_video_d);--OR_reduce(tst_vbufo_do) or

pin_out_TP2(0) <= i_cntdiv_memclkin(8);
pin_out_TP2(1) <= i_cntdiv_memclkout(8);
pin_out_TP2(2) <= OR_reduce(i_ccd_tst_out) or OR_reduce(tst_vout_out) or OR_reduce(tst_vctrl_out) or i_ccd_status(C_CCD_STATUS_ALIGN_OK_BIT) or tst_mem_rdy;
--tst_xps_osdin_axi_tlast
--or tst_xps_osdin_axi_tuser
--or tst_xps_osdin_axi_tvalid
--or tst_xps_osdin_axi_tready
--or tst_xps_osdout_axi_tlast
--or tst_xps_osdout_axi_tuser
--or tst_xps_osdout_axi_tvalid
--or tst_xps_osdout_axi_tready;

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


--
--tst_vfr_pixcount <= TO_UNSIGNED(C_PCFG_CCD_WIN_X / (i_video_d'length / 8), tst_vfr_pixcount'length);
--tst_vfr_rowcount <= TO_UNSIGNED(C_PCFG_CCD_WIN_Y, tst_vfr_rowcount'length);
--
----3..0 --0/1/2/3/4 - 30fps/60fps/120fps/240fps/480fps/
----7..4 --0/1/2/    - Test picture: V+H Counter/ V Counter/ H Counter/
--tst_vfr_cfg <= TO_UNSIGNED(16#00#, tst_vfr_cfg'length);
--
--tst_vfr_synwidth <= TO_UNSIGNED(372, tst_vfr_synwidth'length);-- for 30fps (for dwidth=256bit, frame:4096x4096)
----tst_vfr_synwidth <= TO_UNSIGNED(240, tst_vfr_synwidth'length);-- for 30fps (for dwidth=256bit, frame:5120x5120)
----tst_vfr_synwidth <= TO_UNSIGNED(1278, tst_vfr_synwidth'length);-- for 30fps (for dwidth=32bit, frame:1280x1024)
--
--m_vtest_gen : vtest_gen
--generic map(
--G_DBG => "OFF",
--G_VD_WIDTH => i_video_d'length,
--G_VSYN_ACTIVE => '0'
--)
--port map(
----CFG
--p_in_cfg      => std_logic_vector(tst_vfr_cfg),
--p_in_vpix     => std_logic_vector(tst_vfr_pixcount),
--p_in_vrow     => std_logic_vector(tst_vfr_rowcount),
--p_in_syn_h    => std_logic_vector(tst_vfr_synwidth),
--p_in_syn_v    => std_logic_vector(tst_vfr_synwidth),
--
----Test Video
--p_out_vd      => i_video_d,
--p_out_vs      => i_video_vs,
--p_out_hs      => i_video_hs,
--
----Технологический
--p_in_tst      => (others => '0'),
--p_out_tst     => open,
--
----System
--p_in_clk_en   => '1',
--p_in_clk      => g_usrclk(6),
--p_in_rst      => i_rst
--);
--
--i_video_den <= i_video_hs and i_video_vs and tst_vtest_en;
--i_video_d_clk <= g_usrclk(6);

----tst_vtest_en <= '1';
--process(g_usrclk(6))
--begin
--  if rising_edge(g_usrclk(6)) then
----    sr_btn_push <= i_btn_push & sr_btn_push(0 to 0);
--    sr_video_vs <= i_video_vs & sr_video_vs(0 to 0);
----
----    if sr_btn_push(0) = '1' and sr_btn_push(1) = '0' then
----      i_btn <= not i_btn;
----    end if;
--
----    if i_btn = '1' then --or i_dbg_ctrl_out.glob.start_vout = '1'
--      if sr_video_vs(0) = '0' and sr_video_vs(1) = '1' then
--        tst_vtest_en <= '1';
--      end if;
----    else
----      tst_vtest_en <= '0';
----    end if;
--
--  end if;
--end process;


--m_dbg_ctrl : dbg_ctrl
--port map(
--p_out_usr => i_dbg_ctrl_out,
--p_in_usr  => i_dbg_ctrl_in,
--
--p_in_clk => g_usrclk(6)
--);
--
--i_dbg_ctrl_in.tv_detect <= '0';


--m_d2axistream : data2axistream
--generic map(
--G_VFR_PIX_COUNT => 640,
--G_VFR_ROW_COUNT => 480,
--G_BUFI_DWIDTH => C_CGF_VBUFO_DWIDTH,
--G_AXI_DWIDTH  => C_CGF_VBUFO_DWIDTH
--)
--port map (
-----------------------------------
------
-----------------------------------
----p_in_vfr_pix  =>
----p_in_vfr_row  =>
--p_in_work       => tst_vctrl_out(9),--vctrl/i_vread_en
--
---------------------------------
----
---------------------------------
--p_in_bufi_dout  => i_vbufo_do,
--p_out_bufi_rd   => i_vbufo_rd,
--p_in_bufi_empty => i_vbufo_empty,
--
----Data for XPS_OSD (s_axis_* - video input)
--p_out_axi_stream_tdata  => i_xps_osdin_axi_tdata ,
--p_out_axi_stream_tvalid => i_xps_osdin_axi_tvalid,
--p_out_axi_stream_tuser  => i_xps_osdin_axi_tuser ,
--p_out_axi_stream_tlast  => i_xps_osdin_axi_tlast ,
--p_in_axi_stream_tready  => i_xps_osdin_axi_tready,
--
---------------------------------
----Технологические сигналы
---------------------------------
--p_in_tst   => (others => '0'),
--p_out_tst  => open,
--
---------------------------------
----System
---------------------------------
--p_in_clk   => g_usrclk(2),
--p_in_rst   => i_arb_mem_rst
--);
--

--m_xps : system
--port map (
--p_in_osdvin_s_axis_tvalid   => i_xps_osdin_axi_tvalid,  --'0',             --
--p_in_osdvin_s_axis_tlast    => i_xps_osdin_axi_tlast ,  --'0',             --
--p_in_osdvin_s_axis_tuser    => i_xps_osdin_axi_tuser ,  --'0',             --
--p_in_osdvin_s_axis_tdata    => i_xps_osdin_axi_tdata ,  --(others => '0'), --
--p_out_osdvin_s_axis_tready  => i_xps_osdin_axi_tready,  --open,            --
--                                                        --
--p_out_osdvout_m_axis_tvalid => i_xps_osdout_axi_tvalid, --open,            --
--p_out_osdvout_m_axis_tlast  => i_xps_osdout_axi_tlast , --open,            --
--p_out_osdvout_m_axis_tuser  => i_xps_osdout_axi_tuser , --open,            --
--p_out_osdvout_m_axis_tdata  => i_xps_osdout_axi_tdata , --open,            --
--p_in_osdvout_m_axis_tready  => i_xps_osdout_axi_tready, --'1',             --
--
--p_in_osd_aclk    => g_usrclk(2),
--p_in_osd_aresetn => i_arb_mem_rst_n,
--
--p_out_gpio0 => i_xps_led,
--
--p_in_irq => '0',
--
--p_in_clk => g_usrclk(5),
--p_in_rst => i_arb_mem_rst
--);
--
--process(g_usrclk(2))
--begin
--  if rising_edge(g_usrclk(2)) then
--    tst_xps_osdin_axi_tlast  <= i_xps_osdin_axi_tlast ;
--    tst_xps_osdin_axi_tuser  <= i_xps_osdin_axi_tuser ;
--    tst_xps_osdin_axi_tvalid <= i_xps_osdin_axi_tvalid;
--    tst_xps_osdin_axi_tready <= i_xps_osdin_axi_tready;
--
--    tst_xps_osdout_axi_tlast  <= i_xps_osdout_axi_tlast ;
--    tst_xps_osdout_axi_tuser  <= i_xps_osdout_axi_tuser ;
--    tst_xps_osdout_axi_tvalid <= i_xps_osdout_axi_tvalid;
--    tst_xps_osdout_axi_tready <= i_xps_osdout_axi_tready;
--
--  end if;
--end process;

process(g_usrclk(4))
begin
  if rising_edge(g_usrclk(4)) then
    i_cntdiv_memclkin <= i_cntdiv_memclkin + 1;
  end if;
end process;

process(g_usr_highclk)
begin
  if rising_edge(g_usr_highclk) then
    i_cntdiv_memclkout <= i_cntdiv_memclkout + 1;
    tst_mem_rdy <= OR_reduce(i_mem_ctrl_status.rdy);
  end if;
end process;


end architecture struct;

-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 29.03.2012 13:12:29
-- Module Name : mem_ctrl_pkg
--
-- Description :
--
-- Revision:
-- Revision 0.01 - File Created
--
-------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.vicg_common_pkg.all;
use work.prj_cfg.all;
use work.mem_wr_pkg.all;
use work.mem_glob_pkg.all;

package mem_ctrl_pkg is

constant C_AXIS_IDWIDTH    : integer:=4;
constant C_AXIM_IDWIDTH    : integer:=8;

constant C_AXI_AWIDTH      : integer:=32;
constant C_AXIM_DWIDTH     : integer:=C_PCGF_MEMCTRL_DWIDTH;

type TAXIS_DWIDTH is array (0 to C_MEMCH_COUNT_MAX - 1) of integer;
------------------------------------------------------------------------------------------------------------
--                              slave num   | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10| 11| 12| 13| 14| 15|
------------------------------------------------------------------------------------------------------------
constant C_AXIS_DWIDTH     : TAXIS_DWIDTH := (
256,
64,
C_PCGF_MEMCTRL_DWIDTH,
C_PCGF_MEMCTRL_DWIDTH,
C_PCGF_MEMCTRL_DWIDTH,
C_PCGF_MEMCTRL_DWIDTH,
C_PCGF_MEMCTRL_DWIDTH,
C_PCGF_MEMCTRL_DWIDTH);

constant C_MEM_ARB_CH_COUNT  : integer := C_PCFG_MEMARB_CH_COUNT;

constant C_MEM_BANK_COUNT    : integer := C_PCFG_MEMCTRL_BANK_COUNT;
constant C_MEM_BANK_COUNT_MAX: integer := C_MEM_BANK_COUNT;

constant CI_nCS_PER_RANK  : integer:=1 ;-- # of unique CS outputs per Rank for phy.
constant CI_BANK_WIDTH    : integer:=3 ;-- # of memory Bank Address bits.
constant CI_CK_WIDTH      : integer:=1 ;-- # of CK/CK# outputs to memory.
constant CI_CKE_WIDTH     : integer:=1 ;-- # of CKE outputs to memory.
constant CI_CS_WIDTH      : integer:=1 ;-- # of unique CS outputs to memory.
constant CI_DM_WIDTH      : integer:=2 ;-- # of Data Mask bits.
constant CI_DQ_WIDTH      : integer:=16;-- # of Data (DQ) bits.
constant CI_DQS_WIDTH     : integer:=2 ;-- # of DQS/DQS# bits.
constant CI_ROW_WIDTH     : integer:=13;-- # of memory Row Address bits.
constant CI_ODT_WIDTH     : integer:=1 ;

--Memory interface types
type TMEMCTRL_pinout is record
addr  : std_logic_vector(CI_ROW_WIDTH - 1 downto 0);
ba    : std_logic_vector(CI_BANK_WIDTH - 1 downto 0);
ras_n : std_logic;
cas_n : std_logic;
we_n  : std_logic;
reset_n : std_logic;
cs_n  : std_logic_vector((CI_CS_WIDTH * CI_nCS_PER_RANK) - 1 downto 0);--SODIMM - pin Sx#
odt   : std_logic_vector(CI_ODT_WIDTH - 1 downto 0);
cke   : std_logic_vector(CI_CKE_WIDTH - 1 downto 0);
dm    : std_logic_vector(CI_DM_WIDTH - 1 downto 0);
ck_p  : std_logic_vector(CI_CK_WIDTH - 1 downto 0);
ck_n  : std_logic_vector(CI_CK_WIDTH - 1 downto 0);
end record;

type TMEMCTRL_pininout is record
dq    : std_logic_vector(CI_DQ_WIDTH - 1 downto 0);
dqs_p : std_logic_vector(CI_DQS_WIDTH - 1 downto 0);
dqs_n : std_logic_vector(CI_DQS_WIDTH - 1 downto 0);
--sda   : std_logic;
--event_n : std_logic;--SODIMM - pin EVENT# is asserted by the temperature sensor when crit-ical temperature thresholds have been exceeded.
end record;

type TMEMCTRL_status is record
rdy   : std_logic_vector(C_MEM_BANK_COUNT - 1 downto 0);
end record;

type TMEMCTRL_sysin is record
clk   : std_logic;
rst   : std_logic;
ref_clk: std_logic;
end record;

type TMEMCTRL_sysout is record
gusrclk_locked: std_logic;
clk   : std_logic;
end record;

-- Types for memory interface
type TMEMCTRL_pinouts   is array(0 to C_MEM_BANK_COUNT_MAX - 1) of TMEMCTRL_pinout  ;
type TMEMCTRL_pininouts is array(0 to C_MEM_BANK_COUNT_MAX - 1) of TMEMCTRL_pininout;

Type TMemINCh is array (0 to C_MEM_ARB_CH_COUNT - 1) of TMemIN;
Type TMemOUTCh is array (0 to C_MEM_ARB_CH_COUNT - 1) of TMemOUT;

Type TMemINBank  is array (0 to C_MEM_BANK_COUNT - 1) of TMemIN; --TMemINCh;
Type TMemOUTBank is array (0 to C_MEM_BANK_COUNT - 1) of TMemOUT;--TMemOUTCh;


component mem_ctrl
generic(
G_SIM : string:="OFF"
);
port(
------------------------------------
--User Post
------------------------------------
p_in_mem       : in    TMemINBank;
p_out_mem      : out   TMemOUTBank;

------------------------------------
--Memory physical interface
------------------------------------
p_out_phymem   : out   TMEMCTRL_pinouts;
p_inout_phymem : inout TMEMCTRL_pininouts;

------------------------------------
--Memory status
------------------------------------
p_out_status   : out   TMEMCTRL_status;

------------------------------------
--System
------------------------------------
p_out_sys      : out   TMEMCTRL_sysout;
p_in_sys       : in    TMEMCTRL_sysin
);
end component;

component mem_arb
generic(
G_CH_COUNT   : integer:=4;
G_MEM_AWIDTH : integer:=32;
G_MEM_DWIDTH : integer:=32
);
port(
-------------------------------
--Связь с пользователями ОЗУ
-------------------------------
p_in_memch  : in   TMemINCh;
p_out_memch : out  TMemOUTCh;

-------------------------------
--Связь с mem_ctrl.vhd
-------------------------------
p_out_mem   : out   TMemIN;
p_in_mem    : in    TMemOUT;

-------------------------------
--Технологический
-------------------------------
p_in_tst    : in    std_logic_vector(31 downto 0);
p_out_tst   : out   std_logic_vector(31 downto 0);

-------------------------------
--System
-------------------------------
p_in_clk    : in    std_logic;
p_in_rst    : in    std_logic
);
end component;

component mem_ctrl_core_axi
generic(
C_S_AXI_ID_WIDTH   : integer := 8;
C_S_AXI_ADDR_WIDTH : integer := 32;
C_S_AXI_DATA_WIDTH : integer := 32
);
port(
ddr3_dq             : inout  std_logic_vector(CI_DQ_WIDTH - 1 downto 0);
ddr3_addr           : out    std_logic_vector(CI_ROW_WIDTH - 1 downto 0);
ddr3_ba             : out    std_logic_vector(CI_BANK_WIDTH - 1 downto 0);
ddr3_ras_n          : out    std_logic;
ddr3_cas_n          : out    std_logic;
ddr3_we_n           : out    std_logic;
ddr3_reset_n        : out    std_logic;
ddr3_cs_n           : out    std_logic_vector((CI_CS_WIDTH * CI_nCS_PER_RANK) - 1 downto 0);
ddr3_odt            : out    std_logic_vector((CI_CS_WIDTH * CI_nCS_PER_RANK) - 1 downto 0);
ddr3_cke            : out    std_logic_vector(CI_CKE_WIDTH - 1 downto 0);
ddr3_dm             : out    std_logic_vector(CI_DM_WIDTH - 1 downto 0);
ddr3_dqs_p          : inout  std_logic_vector(CI_DQS_WIDTH - 1 downto 0);
ddr3_dqs_n          : inout  std_logic_vector(CI_DQS_WIDTH - 1 downto 0);
ddr3_ck_p           : out    std_logic_vector(CI_CK_WIDTH - 1 downto 0);
ddr3_ck_n           : out    std_logic_vector(CI_CK_WIDTH - 1 downto 0);

s_axi_awid          : in     std_logic_vector(C_AXIM_IDWIDTH - 1 downto 0);
s_axi_awaddr        : in     std_logic_vector(C_AXI_AWIDTH - 1 downto 0);
s_axi_awlen         : in     std_logic_vector(7 downto 0);
s_axi_awsize        : in     std_logic_vector(2 downto 0);
s_axi_awburst       : in     std_logic_vector(1 downto 0);
s_axi_awlock        : in     std_logic_vector(0 downto 0);
s_axi_awcache       : in     std_logic_vector(3 downto 0);
s_axi_awprot        : in     std_logic_vector(2 downto 0);
s_axi_awqos         : in     std_logic_vector(3 downto 0);
s_axi_awvalid       : in     std_logic;
s_axi_awready       : out    std_logic;
-- Slave Interface Write Data Ports
s_axi_wdata         : in     std_logic_vector(C_AXIM_DWIDTH - 1 downto 0);
s_axi_wstrb         : in     std_logic_vector(C_AXIM_DWIDTH/8 - 1 downto 0);
s_axi_wlast         : in     std_logic;
s_axi_wvalid        : in     std_logic;
s_axi_wready        : out    std_logic;
-- Slave Interface Write Response Ports
s_axi_bid           : out    std_logic_vector(C_AXIM_IDWIDTH - 1 downto 0);
s_axi_bresp         : out    std_logic_vector(1 downto 0);
s_axi_bvalid        : out    std_logic;
s_axi_bready        : in     std_logic;
-- Slave Interface Read Address Ports
s_axi_arid          : in     std_logic_vector(C_AXIM_IDWIDTH - 1 downto 0);
s_axi_araddr        : in     std_logic_vector(C_AXI_AWIDTH - 1 downto 0);
s_axi_arlen         : in     std_logic_vector(7 downto 0);
s_axi_arsize        : in     std_logic_vector(2 downto 0);
s_axi_arburst       : in     std_logic_vector(1 downto 0);
s_axi_arlock        : in     std_logic_vector(0 downto 0);
s_axi_arcache       : in     std_logic_vector(3 downto 0);
s_axi_arprot        : in     std_logic_vector(2 downto 0);
s_axi_arqos         : in     std_logic_vector(3 downto 0);
s_axi_arvalid       : in     std_logic;
s_axi_arready       : out    std_logic;
-- Slave Interface Read Data Ports
s_axi_rid           : out    std_logic_vector(C_AXIM_IDWIDTH - 1 downto 0);
s_axi_rdata         : out    std_logic_vector(C_AXIM_DWIDTH - 1 downto 0);
s_axi_rresp         : out    std_logic_vector(1 downto 0);
s_axi_rlast         : out    std_logic;
s_axi_rvalid        : out    std_logic;
s_axi_rready        : in     std_logic;

--Status
init_calib_complete : out    std_logic;
mmcm_locked         : out    std_logic;

aresetn             : in     std_logic;
ui_clk_sync_rst     : out    std_logic;
ui_clk              : out    std_logic;

--System
clk_ref_i           : in     std_logic;
sys_clk_i           : in     std_logic;
sys_rst             : in     std_logic;

device_temp_i       : in     std_logic_vector(11 downto 0);

app_sr_req          : in     std_logic;
app_sr_active       : out    std_logic;
app_ref_req         : in     std_logic;
app_ref_ack         : out    std_logic;
app_zq_req          : in     std_logic;
app_zq_ack          : out    std_logic
);
end component;


COMPONENT mem_achcount2
  PORT (
    INTERCONNECT_ACLK : IN STD_LOGIC;
    INTERCONNECT_ARESETN : IN STD_LOGIC;

    S00_AXI_ARESET_OUT_N : OUT STD_LOGIC;
    S00_AXI_ACLK : IN STD_LOGIC;
    S00_AXI_AWID : IN STD_LOGIC_VECTOR(C_AXIS_IDWIDTH - 1 DOWNTO 0);
    S00_AXI_AWADDR : IN STD_LOGIC_VECTOR(C_AXI_AWIDTH - 1 DOWNTO 0);
    S00_AXI_AWLEN : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    S00_AXI_AWSIZE : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
    S00_AXI_AWBURST : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    S00_AXI_AWLOCK : IN STD_LOGIC;
    S00_AXI_AWCACHE : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
    S00_AXI_AWPROT : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
    S00_AXI_AWQOS : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
    S00_AXI_AWVALID : IN STD_LOGIC;
    S00_AXI_AWREADY : OUT STD_LOGIC;
    S00_AXI_WDATA : IN STD_LOGIC_VECTOR(C_AXIS_DWIDTH(0) - 1 DOWNTO 0);
    S00_AXI_WSTRB : IN STD_LOGIC_VECTOR(C_AXIS_DWIDTH(0)/8 - 1 DOWNTO 0);
    S00_AXI_WLAST : IN STD_LOGIC;
    S00_AXI_WVALID : IN STD_LOGIC;
    S00_AXI_WREADY : OUT STD_LOGIC;
    S00_AXI_BID : OUT STD_LOGIC_VECTOR(C_AXIS_IDWIDTH - 1 DOWNTO 0);
    S00_AXI_BRESP : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    S00_AXI_BVALID : OUT STD_LOGIC;
    S00_AXI_BREADY : IN STD_LOGIC;
    S00_AXI_ARID : IN STD_LOGIC_VECTOR(C_AXIS_IDWIDTH - 1 DOWNTO 0);
    S00_AXI_ARADDR : IN STD_LOGIC_VECTOR(C_AXI_AWIDTH - 1 DOWNTO 0);
    S00_AXI_ARLEN : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    S00_AXI_ARSIZE : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
    S00_AXI_ARBURST : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    S00_AXI_ARLOCK : IN STD_LOGIC;
    S00_AXI_ARCACHE : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
    S00_AXI_ARPROT : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
    S00_AXI_ARQOS : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
    S00_AXI_ARVALID : IN STD_LOGIC;
    S00_AXI_ARREADY : OUT STD_LOGIC;
    S00_AXI_RID : OUT STD_LOGIC_VECTOR(C_AXIS_IDWIDTH - 1 DOWNTO 0);
    S00_AXI_RDATA : OUT STD_LOGIC_VECTOR(C_AXIS_DWIDTH(0) - 1 DOWNTO 0);
    S00_AXI_RRESP : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    S00_AXI_RLAST : OUT STD_LOGIC;
    S00_AXI_RVALID : OUT STD_LOGIC;
    S00_AXI_RREADY : IN STD_LOGIC;

    S01_AXI_ARESET_OUT_N : OUT STD_LOGIC;
    S01_AXI_ACLK : IN STD_LOGIC;
    S01_AXI_AWID : IN STD_LOGIC_VECTOR(C_AXIS_IDWIDTH - 1 DOWNTO 0);
    S01_AXI_AWADDR : IN STD_LOGIC_VECTOR(C_AXI_AWIDTH - 1 DOWNTO 0);
    S01_AXI_AWLEN : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    S01_AXI_AWSIZE : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
    S01_AXI_AWBURST : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    S01_AXI_AWLOCK : IN STD_LOGIC;
    S01_AXI_AWCACHE : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
    S01_AXI_AWPROT : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
    S01_AXI_AWQOS : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
    S01_AXI_AWVALID : IN STD_LOGIC;
    S01_AXI_AWREADY : OUT STD_LOGIC;
    S01_AXI_WDATA : IN STD_LOGIC_VECTOR(C_AXIS_DWIDTH(1) - 1 DOWNTO 0);
    S01_AXI_WSTRB : IN STD_LOGIC_VECTOR(C_AXIS_DWIDTH(1)/8 - 1 DOWNTO 0);
    S01_AXI_WLAST : IN STD_LOGIC;
    S01_AXI_WVALID : IN STD_LOGIC;
    S01_AXI_WREADY : OUT STD_LOGIC;
    S01_AXI_BID : OUT STD_LOGIC_VECTOR(C_AXIS_IDWIDTH - 1 DOWNTO 0);
    S01_AXI_BRESP : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    S01_AXI_BVALID : OUT STD_LOGIC;
    S01_AXI_BREADY : IN STD_LOGIC;
    S01_AXI_ARID : IN STD_LOGIC_VECTOR(C_AXIS_IDWIDTH - 1 DOWNTO 0);
    S01_AXI_ARADDR : IN STD_LOGIC_VECTOR(C_AXI_AWIDTH - 1 DOWNTO 0);
    S01_AXI_ARLEN : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    S01_AXI_ARSIZE : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
    S01_AXI_ARBURST : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    S01_AXI_ARLOCK : IN STD_LOGIC;
    S01_AXI_ARCACHE : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
    S01_AXI_ARPROT : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
    S01_AXI_ARQOS : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
    S01_AXI_ARVALID : IN STD_LOGIC;
    S01_AXI_ARREADY : OUT STD_LOGIC;
    S01_AXI_RID : OUT STD_LOGIC_VECTOR(C_AXIS_IDWIDTH - 1 DOWNTO 0);
    S01_AXI_RDATA : OUT STD_LOGIC_VECTOR(C_AXIS_DWIDTH(1) - 1 DOWNTO 0);
    S01_AXI_RRESP : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    S01_AXI_RLAST : OUT STD_LOGIC;
    S01_AXI_RVALID : OUT STD_LOGIC;
    S01_AXI_RREADY : IN STD_LOGIC;

    M00_AXI_ARESET_OUT_N : OUT STD_LOGIC;
    M00_AXI_ACLK : IN STD_LOGIC;
    M00_AXI_AWID : OUT STD_LOGIC_VECTOR(C_AXIM_IDWIDTH - 1 DOWNTO 0);
    M00_AXI_AWADDR : OUT STD_LOGIC_VECTOR(C_AXI_AWIDTH - 1 DOWNTO 0);
    M00_AXI_AWLEN : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    M00_AXI_AWSIZE : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
    M00_AXI_AWBURST : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    M00_AXI_AWLOCK : OUT STD_LOGIC;
    M00_AXI_AWCACHE : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    M00_AXI_AWPROT : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
    M00_AXI_AWQOS : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    M00_AXI_AWVALID : OUT STD_LOGIC;
    M00_AXI_AWREADY : IN STD_LOGIC;
    M00_AXI_WDATA : OUT STD_LOGIC_VECTOR(C_AXIM_DWIDTH - 1 DOWNTO 0);
    M00_AXI_WSTRB : OUT STD_LOGIC_VECTOR(C_AXIM_DWIDTH/8 - 1 DOWNTO 0);
    M00_AXI_WLAST : OUT STD_LOGIC;
    M00_AXI_WVALID : OUT STD_LOGIC;
    M00_AXI_WREADY : IN STD_LOGIC;
    M00_AXI_BID : IN STD_LOGIC_VECTOR(C_AXIM_IDWIDTH - 1 DOWNTO 0);
    M00_AXI_BRESP : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    M00_AXI_BVALID : IN STD_LOGIC;
    M00_AXI_BREADY : OUT STD_LOGIC;
    M00_AXI_ARID : OUT STD_LOGIC_VECTOR(C_AXIM_IDWIDTH - 1 DOWNTO 0);
    M00_AXI_ARADDR : OUT STD_LOGIC_VECTOR(C_AXI_AWIDTH - 1 DOWNTO 0);
    M00_AXI_ARLEN : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    M00_AXI_ARSIZE : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
    M00_AXI_ARBURST : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    M00_AXI_ARLOCK : OUT STD_LOGIC;
    M00_AXI_ARCACHE : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    M00_AXI_ARPROT : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
    M00_AXI_ARQOS : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    M00_AXI_ARVALID : OUT STD_LOGIC;
    M00_AXI_ARREADY : IN STD_LOGIC;
    M00_AXI_RID : IN STD_LOGIC_VECTOR(C_AXIM_IDWIDTH - 1 DOWNTO 0);
    M00_AXI_RDATA : IN STD_LOGIC_VECTOR(C_AXIM_DWIDTH - 1 DOWNTO 0);
    M00_AXI_RRESP : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    M00_AXI_RLAST : IN STD_LOGIC;
    M00_AXI_RVALID : IN STD_LOGIC;
    M00_AXI_RREADY : OUT STD_LOGIC
  );
END COMPONENT;


end; --package mem_ctrl_pkg is


package body mem_ctrl_pkg is


end;
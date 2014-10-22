-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 29.03.2012 13:12:10
-- Module Name : mem_ctrl
--
-- Назначение/Описание :
--
--
-- Revision:
-- Revision 0.01 - File Created
--
-------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_arith.ext;

library work;
use work.mem_ctrl_pkg.all;
use work.mem_wr_pkg.all;

entity mem_ctrl is
generic(
G_SIM : string:= "OFF"
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
end entity mem_ctrl;

architecture synth of mem_ctrl is

type TSAXI_ID_t is array (0 to C_MEM_BANK_COUNT - 1)
                            of std_logic_vector(C_AXIM_IDWIDTH - 1 downto 0);
signal i_saxi_bid : TSAXI_ID_t;
signal i_saxi_rid : TSAXI_ID_t;
signal i_clk      : std_logic_vector(C_MEM_BANK_COUNT - 1 downto 0);
signal i_rst      : std_logic_vector(C_MEM_BANK_COUNT - 1 downto 0);
signal i_aresetn  : std_logic_vector(C_MEM_BANK_COUNT - 1 downto 0) := (others => '1');
type Tclk_opt is array (0 to C_MEM_BANK_COUNT - 1)
                            of std_logic_vector(4 downto 0);

signal i_mmcm_locked : std_logic_vector(C_MEM_BANK_COUNT - 1 downto 0);


begin --architecture synth

p_out_sys.clk <= i_clk(0);
p_out_sys.gusrclk_locked <= i_mmcm_locked(0);

gen_bank : for i in 0 to C_MEM_BANK_COUNT - 1 generate

p_out_mem(i).axiw.rid <= EXT(i_saxi_bid(i), p_out_mem(i).axiw.rid'length);
p_out_mem(i).axir.rid <= EXT(i_saxi_rid(i), p_out_mem(i).axir.rid'length);
p_out_mem(i).clk <= i_clk(i);
p_out_mem(i).rstn <= i_aresetn(i);

m_mem_core : mem_ctrl_core_axi
generic map (
C_S_AXI_ID_WIDTH => C_AXIM_IDWIDTH,
C_S_AXI_ADDR_WIDTH => C_AXI_AWIDTH,
C_S_AXI_DATA_WIDTH => C_AXIM_DWIDTH
)
port map(
-- AXI Slave Interface:
-- Write Address Ports
s_axi_awid     => p_in_mem (i).axiw.aid(C_AXIM_IDWIDTH - 1 downto 0),
s_axi_awaddr   => p_in_mem (i).axiw.adr(C_AXI_AWIDTH - 1 downto 0)  ,
s_axi_awlen    => p_in_mem (i).axiw.trnlen                        ,
s_axi_awsize   => p_in_mem (i).axiw.dbus                          ,
s_axi_awburst  => p_in_mem (i).axiw.burst                         ,
s_axi_awlock   => p_in_mem (i).axiw.lock                          ,
s_axi_awcache  => p_in_mem (i).axiw.cache                         ,
s_axi_awprot   => p_in_mem (i).axiw.prot                          ,
s_axi_awqos    => p_in_mem (i).axiw.qos                           ,
s_axi_awvalid  => p_in_mem (i).axiw.avalid                        ,
s_axi_awready  => p_out_mem(i).axiw.aready                        ,
-- Write Data Ports
s_axi_wdata    => p_in_mem (i).axiw.data(C_AXIM_DWIDTH - 1 downto 0) ,
s_axi_wstrb    => p_in_mem (i).axiw.dbe(C_AXIM_DWIDTH/8 - 1 downto 0),
s_axi_wlast    => p_in_mem (i).axiw.dlast                         ,
s_axi_wvalid   => p_in_mem (i).axiw.dvalid                        ,
s_axi_wready   => p_out_mem(i).axiw.wready                        ,
-- Write Response Ports
s_axi_bid      => i_saxi_bid(i)(C_AXIM_IDWIDTH - 1 downto 0)        ,
s_axi_bresp    => p_out_mem(i).axiw.resp                          ,
s_axi_bvalid   => p_out_mem(i).axiw.rvalid                        ,
s_axi_bready   => p_in_mem (i).axiw.rready                        ,
-- Read Address Ports
s_axi_arid     => p_in_mem (i).axir.aid(C_AXIM_IDWIDTH - 1 downto 0),
s_axi_araddr   => p_in_mem (i).axir.adr(C_AXI_AWIDTH - 1 downto 0)  ,
s_axi_arlen    => p_in_mem (i).axir.trnlen                        ,
s_axi_arsize   => p_in_mem (i).axir.dbus                          ,
s_axi_arburst  => p_in_mem (i).axir.burst                         ,
s_axi_arlock   => p_in_mem (i).axir.lock                          ,
s_axi_arcache  => p_in_mem (i).axir.cache                         ,
s_axi_arprot   => p_in_mem (i).axir.prot                          ,
s_axi_arqos    => p_in_mem (i).axir.qos                           ,
s_axi_arvalid  => p_in_mem (i).axir.avalid                        ,
s_axi_arready  => p_out_mem(i).axir.aready                        ,
-- Read Data Ports
s_axi_rid      => i_saxi_rid(i)(C_AXIM_IDWIDTH - 1 downto 0)        ,
s_axi_rdata    => p_out_mem(i).axir.data(C_AXIM_DWIDTH - 1 downto 0) ,
s_axi_rresp    => p_out_mem(i).axir.resp                          ,
s_axi_rlast    => p_out_mem(i).axir.dlast                         ,
s_axi_rvalid   => p_out_mem(i).axir.dvalid                        ,
s_axi_rready   => p_in_mem (i).axir.rready                        ,

-- DDR3 Physical Interface
ddr3_dq         => p_inout_phymem(i).dq     ,
ddr3_addr       => p_out_phymem  (i).addr   ,
ddr3_ba         => p_out_phymem  (i).ba     ,
ddr3_ras_n      => p_out_phymem  (i).ras_n  ,
ddr3_cas_n      => p_out_phymem  (i).cas_n  ,
ddr3_we_n       => p_out_phymem  (i).we_n   ,
ddr3_reset_n    => p_out_phymem  (i).reset_n,
ddr3_cs_n       => p_out_phymem  (i).cs_n   ,
ddr3_odt        => p_out_phymem  (i).odt    ,
ddr3_cke        => p_out_phymem  (i).cke    ,
ddr3_dm         => p_out_phymem  (i).dm     ,
ddr3_dqs_p      => p_inout_phymem(i).dqs_p  ,
ddr3_dqs_n      => p_inout_phymem(i).dqs_n  ,
ddr3_ck_p       => p_out_phymem  (i).ck_p   ,
ddr3_ck_n       => p_out_phymem  (i).ck_n   ,

--Status
init_calib_complete => p_out_status.rdy(i),
mmcm_locked     => i_mmcm_locked(i),

aresetn         => i_aresetn(i)           ,--input
ui_clk_sync_rst => i_rst(i)               ,--output
ui_clk          => i_clk(i)               ,--output

--System
sys_clk_i       => p_in_sys.clk    ,
clk_ref_i       => p_in_sys.ref_clk,
sys_rst         => p_in_sys.rst,

device_temp_i   => (others=>'0'),

app_sr_req      => '0',
app_sr_active   => open,
app_ref_req     => '0',
app_ref_ack     => open,
app_zq_req      => '0',
app_zq_ack      => open
);

process(i_clk(i))
begin
  if rising_edge(i_clk(i)) then
    i_aresetn(i) <= not i_rst(i);
  end if;
end process;

end generate gen_bank;


end architecture synth;

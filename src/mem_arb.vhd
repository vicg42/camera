-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 2010.09
-- Module Name : mem_arb
--
-- Назначение/Описание :
--  Арбитр достпупа к ОЗУ
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
use work.mem_glob_pkg.all;
use work.mem_wr_pkg.all;
use work.mem_ctrl_pkg.all;

entity mem_arb is
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
end entity mem_arb;

architecture behavioral of mem_arb is

type TMemIDWR_Set is record
axiw_id : std_logic_vector(C_MEMWR_IDWIDTH_MAX - 1 downto 0);
axir_id : std_logic_vector(C_MEMWR_IDWIDTH_MAX - 1 downto 0);
end record;
Type TMemChIDWR_Set is array (0 to C_MEMCH_COUNT_MAX - 1) of TMemIDWR_Set;
signal i_set_memch : TMemChIDWR_Set;

type TMemIDWR_Get is record
axiw_rid : std_logic_vector(C_AXIS_IDWIDTH - 1 downto 0);
axir_rid : std_logic_vector(C_AXIS_IDWIDTH - 1 downto 0);
end record;
Type TMemChIDWR_Get is array (0 to C_MEMCH_COUNT_MAX - 1) of TMemIDWR_Get;
signal i_get_memch : TMemChIDWR_Get;

signal i_in_memch           : TMemINCh;
signal i_out_memch          : TMemOUTCh;


begin --architecture behavioral

------------------------------------
--Технологические сигналы
------------------------------------
p_out_tst(31 downto 0) <= (others=>'0');


----------------------------------------------------
--Связь с контроллером памяти mem_ctrl.vhd
----------------------------------------------------
gen_chcount_1 : if G_CH_COUNT = 1 generate

p_out_mem <= p_in_memch(0);
p_out_memch(0) <= p_in_mem;

end generate gen_chcount_1;

gen_chcount_2 : if G_CH_COUNT = 2 generate

gen_idch : for i in 0 to G_CH_COUNT - 1 generate
i_set_memch(i).axiw_id <= std_logic_vector(TO_UNSIGNED((2 * i) + 0, i_set_memch(i).axiw_id'length));
i_set_memch(i).axir_id <= std_logic_vector(TO_UNSIGNED((2 * i) + 0, i_set_memch(i).axir_id'length));

--Response ID
p_out_memch(i).axiw.rid <= std_logic_vector(RESIZE(UNSIGNED(i_get_memch(i).axiw_rid), p_out_memch(i).axiw.rid'length));
p_out_memch(i).axir.rid <= std_logic_vector(RESIZE(UNSIGNED(i_get_memch(i).axir_rid), p_out_memch(i).axir.rid'length));
end generate gen_idch;

m_arb: mem_achcount2
port map(
INTERCONNECT_ACLK    => p_in_clk,                                           --: IN STD_LOGIC;
INTERCONNECT_ARESETN => p_in_mem.rstn,                                      --: IN STD_LOGIC;

S00_AXI_ARESET_OUT_N => p_out_memch(0).rstn,                                --: OUT STD_LOGIC;
S00_AXI_ACLK         => p_in_memch (0).clk,                                 --: IN STD_LOGIC;
S00_AXI_AWID         => i_set_memch(0).axiw_id(C_AXIS_IDWIDTH - 1 downto 0),  --: IN STD_LOGIC_VECTOR(3 DOWNTO 0);
S00_AXI_AWADDR       => p_in_memch (0).axiw.adr(G_MEM_AWIDTH - 1 downto 0),   --: IN STD_LOGIC_VECTOR(31 DOWNTO 0);
S00_AXI_AWLEN        => p_in_memch (0).axiw.trnlen(7 downto 0),             --: IN STD_LOGIC_VECTOR(7 DOWNTO 0);
S00_AXI_AWSIZE       => p_in_memch (0).axiw.dbus(2 downto 0),               --: IN STD_LOGIC_VECTOR(2 DOWNTO 0);
S00_AXI_AWBURST      => p_in_memch (0).axiw.burst(1 downto 0),              --: IN STD_LOGIC_VECTOR(1 DOWNTO 0);
S00_AXI_AWLOCK       => p_in_memch (0).axiw.lock(0),                        --: IN STD_LOGIC;
S00_AXI_AWCACHE      => p_in_memch (0).axiw.cache(3 downto 0),              --: IN STD_LOGIC_VECTOR(3 DOWNTO 0);
S00_AXI_AWPROT       => p_in_memch (0).axiw.prot(2 downto 0),               --: IN STD_LOGIC_VECTOR(2 DOWNTO 0);
S00_AXI_AWQOS        => p_in_memch (0).axiw.qos(3 downto 0),                --: IN STD_LOGIC_VECTOR(3 DOWNTO 0);
S00_AXI_AWVALID      => p_in_memch (0).axiw.avalid,                         --: IN STD_LOGIC;
S00_AXI_AWREADY      => p_out_memch(0).axiw.aready,                         --: OUT STD_LOGIC;
S00_AXI_WDATA        => p_in_memch (0).axiw.data(C_AXIS_DWIDTH(0) - 1 downto 0),  --: IN STD_LOGIC_VECTOR(31 DOWNTO 0);
S00_AXI_WSTRB        => p_in_memch (0).axiw.dbe(C_AXIS_DWIDTH(0)/8 - 1 downto 0), --: IN STD_LOGIC_VECTOR(3 DOWNTO 0);
S00_AXI_WLAST        => p_in_memch (0).axiw.dlast,                          --: IN STD_LOGIC;
S00_AXI_WVALID       => p_in_memch (0).axiw.dvalid,                         --: IN STD_LOGIC;
S00_AXI_WREADY       => p_out_memch(0).axiw.wready,                         --: OUT STD_LOGIC;
S00_AXI_BID          => i_get_memch(0).axiw_rid(C_AXIS_IDWIDTH - 1 downto 0), --: OUT STD_LOGIC_VECTOR(3 DOWNTO 0)
S00_AXI_BRESP        => p_out_memch(0).axiw.resp(1 downto 0),               --: OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
S00_AXI_BVALID       => p_out_memch(0).axiw.rvalid,                         --: OUT STD_LOGIC;
S00_AXI_BREADY       => p_in_memch (0).axiw.rready,                         --: IN STD_LOGIC;
S00_AXI_ARID         => i_set_memch(0).axir_id(C_AXIS_IDWIDTH - 1 downto 0),  --: IN STD_LOGIC_VECTOR(3 DOWNTO 0);
S00_AXI_ARADDR       => p_in_memch (0).axir.adr(G_MEM_AWIDTH - 1 downto 0),   --: IN STD_LOGIC_VECTOR(31 DOWNTO 0);
S00_AXI_ARLEN        => p_in_memch (0).axir.trnlen(7 downto 0),             --: IN STD_LOGIC_VECTOR(7 DOWNTO 0);
S00_AXI_ARSIZE       => p_in_memch (0).axir.dbus(2 downto 0),               --: IN STD_LOGIC_VECTOR(2 DOWNTO 0);
S00_AXI_ARBURST      => p_in_memch (0).axir.burst(1 downto 0),              --: IN STD_LOGIC_VECTOR(1 DOWNTO 0);
S00_AXI_ARLOCK       => p_in_memch (0).axir.lock(0),                        --: IN STD_LOGIC;
S00_AXI_ARCACHE      => p_in_memch (0).axir.cache(3 downto 0),              --: IN STD_LOGIC_VECTOR(3 DOWNTO 0);
S00_AXI_ARPROT       => p_in_memch (0).axir.prot(2 downto 0),               --: IN STD_LOGIC_VECTOR(2 DOWNTO 0);
S00_AXI_ARQOS        => p_in_memch (0).axir.qos(3 downto 0),                --: IN STD_LOGIC_VECTOR(3 DOWNTO 0);
S00_AXI_ARVALID      => p_in_memch (0).axir.avalid,                         --: IN STD_LOGIC;
S00_AXI_ARREADY      => p_out_memch(0).axir.aready,                         --: OUT STD_LOGIC;
S00_AXI_RID          => i_get_memch(0).axir_rid(C_AXIS_IDWIDTH - 1 downto 0), --: OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
S00_AXI_RDATA        => p_out_memch(0).axir.data(C_AXIS_DWIDTH(0) - 1 downto 0),  --: OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
S00_AXI_RRESP        => p_out_memch(0).axir.resp(1 downto 0),               --: OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
S00_AXI_RLAST        => p_out_memch(0).axir.dlast,                          --: OUT STD_LOGIC;
S00_AXI_RVALID       => p_out_memch(0).axir.dvalid,                         --: OUT STD_LOGIC;
S00_AXI_RREADY       => p_in_memch (0).axir.rready,                         --: IN STD_LOGIC;

S01_AXI_ARESET_OUT_N => p_out_memch(1).rstn,                                --: OUT STD_LOGIC;
S01_AXI_ACLK         => p_in_memch (1).clk,                                 --: IN STD_LOGIC;
S01_AXI_AWID         => i_set_memch(1).axiw_id(C_AXIS_IDWIDTH - 1 downto 0),  --: IN STD_LOGIC_VECTOR(3 DOWNTO 0);
S01_AXI_AWADDR       => p_in_memch (1).axiw.adr(G_MEM_AWIDTH - 1 downto 0),   --: IN STD_LOGIC_VECTOR(31 DOWNTO 0);
S01_AXI_AWLEN        => p_in_memch (1).axiw.trnlen(7 downto 0),             --: IN STD_LOGIC_VECTOR(7 DOWNTO 0);
S01_AXI_AWSIZE       => p_in_memch (1).axiw.dbus(2 downto 0),               --: IN STD_LOGIC_VECTOR(2 DOWNTO 0);
S01_AXI_AWBURST      => p_in_memch (1).axiw.burst(1 downto 0),              --: IN STD_LOGIC_VECTOR(1 DOWNTO 0);
S01_AXI_AWLOCK       => p_in_memch (1).axiw.lock(0),                        --: IN STD_LOGIC;
S01_AXI_AWCACHE      => p_in_memch (1).axiw.cache(3 downto 0),              --: IN STD_LOGIC_VECTOR(3 DOWNTO 0);
S01_AXI_AWPROT       => p_in_memch (1).axiw.prot(2 downto 0),               --: IN STD_LOGIC_VECTOR(2 DOWNTO 0);
S01_AXI_AWQOS        => p_in_memch (1).axiw.qos(3 downto 0),                --: IN STD_LOGIC_VECTOR(3 DOWNTO 0);
S01_AXI_AWVALID      => p_in_memch (1).axiw.avalid,                         --: IN STD_LOGIC;
S01_AXI_AWREADY      => p_out_memch(1).axiw.aready,                         --: OUT STD_LOGIC;
S01_AXI_WDATA        => p_in_memch (1).axiw.data(C_AXIS_DWIDTH(1) - 1 downto 0),  --: IN STD_LOGIC_VECTOR(31 DOWNTO 0);
S01_AXI_WSTRB        => p_in_memch (1).axiw.dbe(C_AXIS_DWIDTH(1)/8 - 1 downto 0), --: IN STD_LOGIC_VECTOR(3 DOWNTO 0);
S01_AXI_WLAST        => p_in_memch (1).axiw.dlast,                          --: IN STD_LOGIC;
S01_AXI_WVALID       => p_in_memch (1).axiw.dvalid,                         --: IN STD_LOGIC;
S01_AXI_WREADY       => p_out_memch(1).axiw.wready,                         --: OUT STD_LOGIC;
S01_AXI_BID          => i_get_memch(1).axiw_rid(C_AXIS_IDWIDTH - 1 downto 0), --: OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
S01_AXI_BRESP        => p_out_memch(1).axiw.resp(1 downto 0),               --: OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
S01_AXI_BVALID       => p_out_memch(1).axiw.rvalid,                         --: OUT STD_LOGIC;
S01_AXI_BREADY       => p_in_memch (1).axiw.rready,                         --: IN STD_LOGIC;
S01_AXI_ARID         => i_set_memch(1).axir_id(C_AXIS_IDWIDTH - 1 downto 0),  --: IN STD_LOGIC_VECTOR(3 DOWNTO 0);
S01_AXI_ARADDR       => p_in_memch (1).axir.adr(G_MEM_AWIDTH - 1 downto 0),   --: IN STD_LOGIC_VECTOR(31 DOWNTO 0);
S01_AXI_ARLEN        => p_in_memch (1).axir.trnlen(7 downto 0),             --: IN STD_LOGIC_VECTOR(7 DOWNTO 0);
S01_AXI_ARSIZE       => p_in_memch (1).axir.dbus(2 downto 0),               --: IN STD_LOGIC_VECTOR(2 DOWNTO 0);
S01_AXI_ARBURST      => p_in_memch (1).axir.burst(1 downto 0),              --: IN STD_LOGIC_VECTOR(1 DOWNTO 0);
S01_AXI_ARLOCK       => p_in_memch (1).axir.lock(0),                        --: IN STD_LOGIC;
S01_AXI_ARCACHE      => p_in_memch (1).axir.cache(3 downto 0),              --: IN STD_LOGIC_VECTOR(3 DOWNTO 0);
S01_AXI_ARPROT       => p_in_memch (1).axir.prot(2 downto 0),               --: IN STD_LOGIC_VECTOR(2 DOWNTO 0);
S01_AXI_ARQOS        => p_in_memch (1).axir.qos(3 downto 0),                --: IN STD_LOGIC_VECTOR(3 DOWNTO 0);
S01_AXI_ARVALID      => p_in_memch (1).axir.avalid,                         --: IN STD_LOGIC;
S01_AXI_ARREADY      => p_out_memch(1).axir.aready,                         --: OUT STD_LOGIC;
S01_AXI_RID          => i_get_memch(1).axir_rid(C_AXIS_IDWIDTH - 1 downto 0), --: OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
S01_AXI_RDATA        => p_out_memch(1).axir.data(C_AXIS_DWIDTH(1) - 1 downto 0),  --: OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
S01_AXI_RRESP        => p_out_memch(1).axir.resp(1 downto 0),               --: OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
S01_AXI_RLAST        => p_out_memch(1).axir.dlast,                          --: OUT STD_LOGIC;
S01_AXI_RVALID       => p_out_memch(1).axir.dvalid,                         --: OUT STD_LOGIC;
S01_AXI_RREADY       => p_in_memch (1).axir.rready,                         --: IN STD_LOGIC;


M00_AXI_ARESET_OUT_N => open, --p_out_mem.rstn,                             --: OUT STD_LOGIC;
M00_AXI_ACLK         => p_in_mem.clk,                                       --: IN STD_LOGIC;
M00_AXI_AWID         => p_out_mem.axiw.aid(C_AXIM_IDWIDTH - 1 downto 0),      --: OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
M00_AXI_AWADDR       => p_out_mem.axiw.adr(G_MEM_AWIDTH - 1 downto 0),        --: OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
M00_AXI_AWLEN        => p_out_mem.axiw.trnlen(7 downto 0),                  --: OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
M00_AXI_AWSIZE       => p_out_mem.axiw.dbus(2 downto 0),                    --: OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
M00_AXI_AWBURST      => p_out_mem.axiw.burst(1 downto 0),                   --: OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
M00_AXI_AWLOCK       => p_out_mem.axiw.lock(0),                             --: OUT STD_LOGIC;
M00_AXI_AWCACHE      => p_out_mem.axiw.cache(3 downto 0),                   --: OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
M00_AXI_AWPROT       => p_out_mem.axiw.prot(2 downto 0),                    --: OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
M00_AXI_AWQOS        => p_out_mem.axiw.qos(3 downto 0),                     --: OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
M00_AXI_AWVALID      => p_out_mem.axiw.avalid,                              --: OUT STD_LOGIC;
M00_AXI_AWREADY      => p_in_mem.axiw.aready,                               --: IN STD_LOGIC;
M00_AXI_WDATA        => p_out_mem.axiw.data(G_MEM_DWIDTH - 1 downto 0),       --: OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
M00_AXI_WSTRB        => p_out_mem.axiw.dbe(G_MEM_DWIDTH/8 - 1 downto 0),      --: OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
M00_AXI_WLAST        => p_out_mem.axiw.dlast,                               --: OUT STD_LOGIC;
M00_AXI_WVALID       => p_out_mem.axiw.dvalid,                              --: OUT STD_LOGIC;
M00_AXI_WREADY       => p_in_mem.axiw.wready,                               --: IN STD_LOGIC;
M00_AXI_BID          => p_in_mem.axiw.rid(C_AXIM_IDWIDTH - 1 downto 0),       --: IN STD_LOGIC_VECTOR(7 DOWNTO 0);
M00_AXI_BRESP        => p_in_mem.axiw.resp(1 downto 0),                     --: IN STD_LOGIC_VECTOR(1 DOWNTO 0);
M00_AXI_BVALID       => p_in_mem.axiw.rvalid,                               --: IN STD_LOGIC;
M00_AXI_BREADY       => p_out_mem.axiw.rready,                              --: OUT STD_LOGIC;
M00_AXI_ARID         => p_out_mem.axir.aid(C_AXIM_IDWIDTH - 1 downto 0),      --: OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
M00_AXI_ARADDR       => p_out_mem.axir.adr(G_MEM_AWIDTH - 1 downto 0),        --: OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
M00_AXI_ARLEN        => p_out_mem.axir.trnlen(7 downto 0),                  --: OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
M00_AXI_ARSIZE       => p_out_mem.axir.dbus(2 downto 0),                    --: OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
M00_AXI_ARBURST      => p_out_mem.axir.burst(1 downto 0),                   --: OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
M00_AXI_ARLOCK       => p_out_mem.axir.lock(0),                             --: OUT STD_LOGIC;
M00_AXI_ARCACHE      => p_out_mem.axir.cache(3 downto 0),                   --: OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
M00_AXI_ARPROT       => p_out_mem.axir.prot(2 downto 0),                    --: OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
M00_AXI_ARQOS        => p_out_mem.axir.qos(3 downto 0),                     --: OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
M00_AXI_ARVALID      => p_out_mem.axir.avalid,                              --: OUT STD_LOGIC;
M00_AXI_ARREADY      => p_in_mem.axir.aready,                               --: IN STD_LOGIC;
M00_AXI_RID          => p_in_mem.axir.rid(C_AXIM_IDWIDTH - 1 downto 0),       --: IN STD_LOGIC_VECTOR(7 DOWNTO 0);
M00_AXI_RDATA        => p_in_mem.axir.data(G_MEM_DWIDTH - 1 downto 0),        --: IN STD_LOGIC_VECTOR(31 DOWNTO 0);
M00_AXI_RRESP        => p_in_mem.axir.resp(1 downto 0),                     --: IN STD_LOGIC_VECTOR(1 DOWNTO 0);
M00_AXI_RLAST        => p_in_mem.axir.dlast,                                --: IN STD_LOGIC;
M00_AXI_RVALID       => p_in_mem.axir.dvalid,                               --: IN STD_LOGIC;
M00_AXI_RREADY       => p_out_mem.axir.rready                               --: OUT STD_LOGIC
);

end generate gen_chcount_2;


end architecture behavioral;

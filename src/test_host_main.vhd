-------------------------------------------------------------------------
-- Company     : Yansar
-- Engineer    : Golovachenko Victor
--
-- Create Date : 30.12.2014 18:59:52
-- Module Name : test_host_main
--
-------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.prj_cfg.all;
use work.reduce_pack.all;
use work.vicg_common_pkg.all;
use work.clocks_pkg.all;
use work.host_pkg.all;

entity test_host_main is
port(
pin_in_hostphy   : in     THostPhyIN;
pin_out_hostphy  : out    THostPhyOUT;

--------------------------------------------------
--DBG
--------------------------------------------------
pin_out_TP2         : out   std_logic_vector(2 downto 2);
pin_out_led         : out   std_logic_vector(1 downto 0);
--pin_in_btn          : in    std_logic;

--------------------------------------------------
--Reference clock
--------------------------------------------------
pin_in_refclk       : in    TRefclk_pinin
);
end entity test_host_main;

architecture struct of test_host_main is

component clocks is
generic(
G_VOUT_TYPE : string := "VGA"
);
port(
p_out_rst  : out   std_logic;
p_out_gclk : out   std_logic_vector(7 downto 0);

p_in_clk   : in    TRefclk_pinin
);
end component clocks;

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

component host is
generic(
G_DBG : string := "OFF";
G_BAUDCNT_VAL : integer := 64
);
port(
-------------------------------
--
-------------------------------
p_in_phy    : in     THostPhyIN;
p_out_phy   : out    THostPhyOUT;

-------------------------------
--dev
-------------------------------
p_out_host  : out    THostOUT;
p_in_host   : in     THostINs;

-------------------------------
--DBG
-------------------------------
p_in_tst    : in     std_logic_vector(31 downto 0);
p_out_tst   : out    std_logic_vector(31 downto 0);

-------------------------------
--System
-------------------------------
p_in_sys    : in     TSysIN
);
end component host;

signal i_rst              : std_logic;
signal g_usrclk           : std_logic_vector(7 downto 0);
signal i_test_led         : std_logic_vector(1 downto 0);
signal i_1ms              : std_logic;

signal i_sys              : TSysIN;
signal i_host_out         : THostOUT;
signal i_host_in          : THostINs;
signal i_out_hostphy      : THostPhyOUT;

type TUsrRegs is array (0 to C_PCFG_TSTREG_COUNT_MAX - 1) of unsigned(i_host_out.txdata'range);

signal i_reg0_acnt        : unsigned(i_host_out.radr'range);
signal i_reg0             : TUsrRegs;
signal i_reg0_cs          : std_logic;

signal i_reg1_acnt        : unsigned(i_host_out.radr'range);
signal i_reg1             : TUsrRegs;
signal i_reg1_cs          : std_logic;

attribute keep : string;
attribute keep of i_sys : signal is "true";

signal tst_host_out       : std_logic_vector(31 downto 0);
signal tst_uart_rx, tst_uart_tx : std_logic;


begin --architecture struct

--***********************************************************
--
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

i_sys.uart_refclk <= g_usrclk(7);
i_sys.cfg_clk <= g_usrclk(7);
i_sys.rst <= i_rst;

--***********************************************************
--DBG
--***********************************************************
pin_out_led(0) <= i_test_led(0);
pin_out_led(1) <= tst_host_out(0);

pin_out_TP2(2) <= tst_uart_rx and tst_uart_tx;

process(i_sys.uart_refclk)
begin
if rising_edge(i_sys.uart_refclk) then
  tst_uart_rx <= pin_in_hostphy.uart_rx;
  tst_uart_tx <= i_out_hostphy.uart_tx;
end if;
end process;

pin_out_hostphy <= i_out_hostphy;

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
p_in_clk       => i_sys.uart_refclk,
p_in_rst       => i_rst
);


--***********************************************************
--
--***********************************************************
m_host : host
generic map(
G_BAUDCNT_VAL => 34 --for baudrate 115200; uart_refclk = 62MHz
--G_BAUDCNT_VAL => 650 --for baudrate 19200; uart_refclk = 200MHz
)
port map(
-------------------------------
--
-------------------------------
p_in_phy   => pin_in_hostphy ,
p_out_phy  => i_out_hostphy,--pin_out_hostphy,

-------------------------------
--host <-> dev
-------------------------------
p_out_host   => i_host_out, -- to(->) fpga dev
p_in_host    => i_host_in , -- from(<-) fpga dev

-------------------------------
--DBG
-------------------------------
p_in_tst    => (others => '0'),
p_out_tst   => tst_host_out,

-------------------------------
--System
-------------------------------
p_in_sys    => i_sys
);


--#############################
--FDEV - TSTREG0
--#############################
i_reg0_cs <= '1' when UNSIGNED(i_host_out.dadr)
                        = TO_UNSIGNED(C_PCFG_FDEV_TSTREG0_NUM, i_host_out.dadr'length) else '0';

--Register adress
process(i_sys)
begin
if i_sys.rst = '1' then
  i_reg0_acnt <= (others => '0');
elsif rising_edge(i_sys.cfg_clk) then
if i_reg0_cs = '1' then
  if i_host_out.radr_ld = '1' then
    i_reg0_acnt <= UNSIGNED(i_host_out.radr);
  else
    if i_host_out.fifo = '0' and (i_host_out.wr = '1' or i_host_out.rd = '1') then
      i_reg0_acnt <= i_reg0_acnt + 1;
    end if;
  end if;
end if;
end if;
end process;

--write to reg
process(i_sys)
begin
if i_sys.rst = '1' then
  for i in 0 to i_reg0'length - 1 loop
    i_reg0(i) <= (others => '0');
  end loop;
elsif rising_edge(i_sys.cfg_clk) then
if i_reg0_cs = '1' then
  if i_host_out.wr = '1' and i_host_out.fifo = '0' then
    for i in 0 to i_reg0'length - 1 loop
      if i_reg0_acnt = i then
        i_reg0(i) <= UNSIGNED(i_host_out.txdata);
      end if;
    end loop;
  end if;
end if;
end if;
end process;

process(i_reg0_acnt, i_reg0, i_host_in)
begin
for i in 0 to i_reg0'length - 1 loop
  if i_reg0_acnt = i then
    i_host_in(C_PCFG_FDEV_TSTREG0_NUM).rxdata <= std_logic_vector(i_reg0(i));
  end if;
end loop;
end process;
i_host_in(C_PCFG_FDEV_TSTREG0_NUM).rxbuf_full  <= '0';
i_host_in(C_PCFG_FDEV_TSTREG0_NUM).rxbuf_empty <= '0';
i_host_in(C_PCFG_FDEV_TSTREG0_NUM).txbuf_full  <= '0';
i_host_in(C_PCFG_FDEV_TSTREG0_NUM).txbuf_empty <= '0';


--#############################
--FDEV - TSTREG1
--#############################
i_reg1_cs <= '1' when UNSIGNED(i_host_out.dadr)
                        = TO_UNSIGNED(C_PCFG_FDEV_TSTREG1_NUM, i_host_out.dadr'length) else '0';

--Register adress
process(i_sys)
begin
if i_sys.rst = '1' then
  i_reg1_acnt <= (others => '0');
elsif rising_edge(i_sys.cfg_clk) then
if i_reg1_cs = '1' then
  if i_host_out.radr_ld = '1' then
    i_reg1_acnt <= UNSIGNED(i_host_out.radr);
  else
    if i_host_out.fifo = '0' and (i_host_out.wr = '1' or i_host_out.rd = '1') then
      i_reg1_acnt <= i_reg1_acnt + 1;
    end if;
  end if;
end if;
end if;
end process;

--write to reg
process(i_sys)
begin
if i_sys.rst = '1' then
  for i in 0 to i_reg1'length - 1 loop
    i_reg1(i) <= (others => '0');
  end loop;
elsif rising_edge(i_sys.cfg_clk) then
if i_reg1_cs = '1' then
  if i_host_out.wr = '1' and i_host_out.fifo = '0' then
    for i in 0 to i_reg1'length - 1 loop
      if i_reg1_acnt = i then
        i_reg1(i) <= UNSIGNED(i_host_out.txdata);
      end if;
    end loop;
  end if;
end if;
end if;
end process;

process(i_reg1_acnt, i_reg1, i_host_in)
begin
for i in 0 to i_reg1'length - 1 loop
  if i_reg1_acnt = i then
    i_host_in(C_PCFG_FDEV_TSTREG1_NUM).rxdata <= std_logic_vector(i_reg1(i));
  end if;
end loop;
end process;
i_host_in(C_PCFG_FDEV_TSTREG1_NUM).rxbuf_full  <= '0';
i_host_in(C_PCFG_FDEV_TSTREG1_NUM).rxbuf_empty <= '0';
i_host_in(C_PCFG_FDEV_TSTREG1_NUM).txbuf_full  <= '0';
i_host_in(C_PCFG_FDEV_TSTREG1_NUM).txbuf_empty <= '0';


end architecture struct;

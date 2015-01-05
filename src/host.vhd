-------------------------------------------------------------------------
-- Company     : Yansar
-- Engineer    : Golovachenko Victor
--
-- Create Date : 30.12.2014 15:34:14
-- Module Name : host
--
-------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.vicg_common_pkg.all;
use work.cfgdev_pkg.all;
use work.host_pkg.all;
use work.prj_cfg.all;

entity host is
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
end entity host;

architecture behavioral of host is

component uart is
generic(
G_BAUDCNT_VAL: integer:=64
);
port(
-------------------------------
--UART
-------------------------------
p_out_uart_tx    : out   std_logic;
p_in_uart_rx     : in    std_logic;

-------------------------------
--USR IF
-------------------------------
p_out_usr_rxd    : out   std_logic_vector(7 downto 0);
p_out_usr_rxrdy  : out   std_logic;
p_in_usr_rd      : in    std_logic;

p_in_usr_txd     : in    std_logic_vector(7 downto 0);
p_out_usr_txrdy  : out   std_logic;
p_in_usr_wr      : in    std_logic;

-------------------------------
--DBG
-------------------------------
p_in_tst         : in    std_logic_vector(31 downto 0);
p_out_tst        : out   std_logic_vector(31 downto 0);

-------------------------------
--System
-------------------------------
p_in_clk         : in    std_logic;
p_in_rst         : in    std_logic
);
end component uart;

signal i_zero           : std_logic_vector(31 downto 0);

signal i_uart_txd       : std_logic_vector(7 downto 0);
signal i_uart_txdrdy    : std_logic;
signal i_uart_wr        : std_logic;
signal i_uart_rxd       : std_logic_vector(7 downto 0);
signal i_uart_rxdrdy    : std_logic;
signal i_uart_rd        : std_logic;

signal i_host_out       : THostOUT;
signal i_host_in        : THostIN;
signal i_hrxbuf_empty   : std_logic;
signal i_htxbuf_full    : std_logic;

signal tst_core_out     : std_logic_vector(31 downto 0);
signal tst_uart_out     : std_logic_vector(31 downto 0);


begin --architecture behavioral

i_zero <= (others => '0');

--############################
--DBG
--############################
p_out_tst(31 downto 0) <= (others=>'0');


--############################
--
--############################
m_uart: uart
generic map(
G_BAUDCNT_VAL => G_BAUDCNT_VAL
)
port map(
-------------------------------
--UART
-------------------------------
p_out_uart_tx    => p_out_phy.uart_tx,
p_in_uart_rx     => p_in_phy.uart_rx,

-------------------------------
--USR IF
-------------------------------
p_out_usr_rxd    => i_uart_rxd,
p_out_usr_rxrdy  => i_uart_rxdrdy,
p_in_usr_rd      => i_uart_rd,

p_in_usr_txd     => i_uart_txd,
p_out_usr_txrdy  => i_uart_txdrdy,
p_in_usr_wr      => i_uart_wr,

-------------------------------
--DBG
-------------------------------
p_in_tst         => i_zero,
p_out_tst        => tst_uart_out,

-------------------------------
--System
-------------------------------
p_in_clk         => p_in_sys.uart_refclk,
p_in_rst         => p_in_sys.rst
);

process(p_in_sys.uart_refclk)
begin
if rising_edge(p_in_sys.uart_refclk) then
  i_uart_wr <= not i_hrxbuf_empty and i_uart_txdrdy;
  i_uart_rd <= not i_htxbuf_full and i_uart_rxdrdy;
end if;
end process;

p_out_host <= i_host_out;

process(i_host_out, i_host_in, p_in_host)
begin
for i in 0 to C_PCFG_FDEV_COUNT - 1 loop
  if UNSIGNED(i_host_out.dadr) = i then
    i_host_in <= p_in_host(i);
  end if;
end loop;
end process;

--i_host_in.radata <= p_in_host(C_PCFG_FDEV_TSTREG0_NUM).rxdata when UNSIGNED(i_host_out.dadr) = TO_UNSIGNED(C_PCFG_FDEV_TSTREG1_NUM, i_host_in.radata'length) else
--                    p_in_host(C_PCFG_FDEV_TSTREG1_NUM).rxdata;
--
--i_host_in.txbuf_full <= p_in_host(C_PCFG_FDEV_TSTREG0_NUM).txbuf_full when UNSIGNED(i_host_out.dadr) = TO_UNSIGNED(C_PCFG_FDEV_TSTREG1_NUM, i_host_in.radata'length) else
--                        p_in_host(C_PCFG_FDEV_TSTREG1_NUM).txbuf_full;
--
--i_host_in.txbuf_empty <= p_in_host(C_PCFG_FDEV_TSTREG0_NUM).txbuf_empty when UNSIGNED(i_host_out.dadr) = TO_UNSIGNED(C_PCFG_FDEV_TSTREG1_NUM, i_host_in.radata'length) else
--                         p_in_host(C_PCFG_FDEV_TSTREG1_NUM).txbuf_empty;
--
--i_host_in.rxbuf_full <= p_in_host(C_PCFG_FDEV_TSTREG0_NUM).rxbuf_full when UNSIGNED(i_host_out.dadr) = TO_UNSIGNED(C_PCFG_FDEV_TSTREG1_NUM, i_host_in.radata'length) else
--                        p_in_host(C_PCFG_FDEV_TSTREG1_NUM).rxbuf_full;
--
--i_host_in.rxbuf_empty <= p_in_host(C_PCFG_FDEV_TSTREG0_NUM).rxbuf_empty when UNSIGNED(i_host_out.dadr) = TO_UNSIGNED(C_PCFG_FDEV_TSTREG1_NUM, i_host_in.radata'length) else
--                         p_in_host(C_PCFG_FDEV_TSTREG1_NUM).rxbuf_empty;

m_devcfg : cfgdev_host
generic map(
G_DBG => "OFF",
G_HOST_DWIDTH => i_uart_txd'length,
G_CFG_DWIDTH => C_HOST_DWIDTH
)
port map (
-------------------------------
--HOST
-------------------------------
p_out_hrxbuf_do      => i_uart_txd,
p_in_hrxbuf_rd       => i_uart_wr,
p_out_hrxbuf_full    => open,
p_out_hrxbuf_empty   => i_hrxbuf_empty,

p_in_htxbuf_di       => i_uart_rxd,
p_in_htxbuf_wr       => i_uart_rd,
p_out_htxbuf_full    => i_htxbuf_full,
p_out_htxbuf_empty   => open,

p_out_hirq           => open,
p_in_hclk            => p_in_sys.uart_refclk,

-------------------------------
--CFG
-------------------------------
p_out_cfg_dadr       => i_host_out.dadr      ,
p_out_cfg_radr       => i_host_out.radr      ,
p_out_cfg_radr_ld    => i_host_out.radr_ld   ,
p_out_cfg_radr_fifo  => i_host_out.fifo      ,
p_out_cfg_wr         => i_host_out.wr        ,
p_out_cfg_rd         => i_host_out.rd        ,
p_out_cfg_txdata     => i_host_out.txdata    ,
p_in_cfg_txbuf_full  => i_host_in.txbuf_full ,
p_in_cfg_txbuf_empty => i_host_in.txbuf_empty,
p_in_cfg_rxdata      => i_host_in.rxdata     ,
p_in_cfg_rxbuf_full  => i_host_in.rxbuf_full ,
p_in_cfg_rxbuf_empty => i_host_in.rxbuf_empty,
p_out_cfg_done       => i_host_out.done      ,
p_in_cfg_clk         => p_in_sys.cfg_clk     ,

-------------------------------
--DBG
-------------------------------
p_in_tst             => i_zero,
p_out_tst            => tst_core_out,

-------------------------------
--System
-------------------------------
p_in_rst             => p_in_sys.rst
);


end architecture behavioral;

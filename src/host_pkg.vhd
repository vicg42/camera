-------------------------------------------------------------------------
-- Company     : Yansar
-- Engineer    : Golovachenko Victor
--
-- Create Date : 24.12.2014 15:07:49
-- Module Name : host_pkg
--
-------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

use work.prj_cfg.all;
use work.cfgdev_pkg.all;

package host_pkg is

type TSysIN is record
uart_refclk : std_logic;
cfg_clk : std_logic;
rst : std_logic;
end record;

--PC -> HostPhy
type THostPhyIN is record
uart_rx     : std_logic;
end record;
--PC <- HostPhy
type THostPhyOUT is record
uart_tx     : std_logic;
end record;

--Host -> Dev
type THostOUT is record
dadr       : std_logic_vector(C_CFGPKT_DADR_M_BIT - C_CFGPKT_DADR_L_BIT downto 0); --dev number
radr       : std_logic_vector(C_HOST_DWIDTH - 1 downto 0); --adr register
radr_ld    : std_logic;
fifo       : std_logic;
wr         : std_logic;
rd         : std_logic;
txdata     : std_logic_vector(C_HOST_DWIDTH - 1 downto 0);
done       : std_logic;
end record;

--Host <- Dev
type THostIN is record
txbuf_full  : std_logic;
txbuf_empty : std_logic;
rxdata      : std_logic_vector(C_HOST_DWIDTH - 1 downto 0);
rxbuf_full  : std_logic;
rxbuf_empty : std_logic;
end record;

type THostINs is array (0 to C_PCFG_FDEV_COUNT - 1) of THostIN;

end package host_pkg;

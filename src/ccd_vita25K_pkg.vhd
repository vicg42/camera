-------------------------------------------------------------------------
-- Company     : Yansar
-- Engineer    : Golovachenko Victor
--
-- Create Date : 13.06.2014 15:09:01
-- Module Name : ccd_vita25K_pkg
--
-- Description :
--
-- Revision:
-- Revision 0.01 - File Created
--
-------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use work.prj_cfg.all;

package ccd_vita25K_pkg is

type TCCD_PortIN is record
data_p : std_logic_vector(C_PCFG_CCD_LVDS_COUNT - 1 downto 0);
data_n : std_logic_vector(C_PCFG_CCD_LVDS_COUNT - 1 downto 0);

clk_p : std_logic;
clk_n : std_logic;
end record;

type TCCD_PortOUT is record
clk_p : std_logic;
clk_n : std_logic;

rst_n : std_logic;
trig  : std_logic;
end record;

end ccd_vita25K_pkg;


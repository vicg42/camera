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

package ccd_vita25K_pkg is

type TCCD_PortIN is record
vd_p : std_logic_vector(16 - 1 downto 0);
vd_n : std_logic_vector(16 - 1 downto 0);

sync_p : std_logic;
sync_n : std_logic;

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


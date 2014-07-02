-------------------------------------------------------------------------
-- Company     : Yansar
-- Engineer    : Golovachenko Victor
--
-- Create Date : 22.06.2014 10:23:57
-- Module Name : vout_pkg
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
--use work.prj_cfg.all;

package vout_pkg is

type TVout_pinout is record
vga_dr      : std_logic_vector(10 - 1 downto 0);
vga_dg      : std_logic_vector(10 - 1 downto 0);
vga_db      : std_logic_vector(10 - 1 downto 0);
vga_hs      : std_logic;
vga_vs      : std_logic;

--ADV7123
dac_blank_n : std_logic;
dac_sync_n  : std_logic;
dac_psave_n : std_logic;
dac_clk     : std_logic;

----AD723
--hsync        : std_logic;
--vsync        : std_logic;
--ce           : std_logic;
--sa           : std_logic;
--stnd         : std_logic;
--fcs4         : std_logic;
end record;

end vout_pkg;


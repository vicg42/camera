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

package vout_pkg is

type TVout_pinout is record
vga_hs      : std_logic;
vga_vs      : std_logic;

--DAC
adv7123_dr      : std_logic_vector(10 - 1 downto 0);
adv7123_dg      : std_logic_vector(10 - 1 downto 0);
adv7123_db      : std_logic_vector(10 - 1 downto 0);
adv7123_blank_n : std_logic;
adv7123_sync_n  : std_logic;
adv7123_psave_n : std_logic;
adv7123_clk     : std_logic;

--TV PAL
ad723_hsrca     : std_logic;
ad723_vsrca     : std_logic;
ad723_ce        : std_logic;
ad723_sa        : std_logic;
ad723_stnd      : std_logic;
ad723_fcs4      : std_logic;
ad723_term      : std_logic;
end record;

end vout_pkg;


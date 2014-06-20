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

--10Bit per pix
constant C_CCD_CHSYNC_TRAINING : integer := 16#3A6#;
constant C_CCD_CHSYNC_BLACKPIX : integer := 16#015#;
constant C_CCD_CHSYNC_CRC      : integer := 16#059#;
constant C_CCD_CHSYNC_IMAGE    : integer := 16#035#;
constant C_CCD_CHSYNC_FS       : integer := 16#2AA#;-- 10_1|010_1010
constant C_CCD_CHSYNC_FE       : integer := 16#32A#;-- 11_0|010_1010
constant C_CCD_CHSYNC_LS       : integer := 16#3AA#;-- 00_1|010_1010
constant C_CCD_CHSYNC_LE       : integer := 16#22A#;-- 01_0|010_1010


type TCCD_pinin is record
data_p : std_logic_vector(C_PCFG_CCD_LVDS_COUNT - 1 downto 0);
data_n : std_logic_vector(C_PCFG_CCD_LVDS_COUNT - 1 downto 0);

clk_p : std_logic;
clk_n : std_logic;

miso  : std_logic;
end record;

type TCCD_pinout is record
clk_p : std_logic;
clk_n : std_logic;

rst_n : std_logic;
trig  : std_logic;

sck  : std_logic;
ss_n : std_logic;
mosi : std_logic;--Master OUT, Slave IN
end record;

end ccd_vita25K_pkg;


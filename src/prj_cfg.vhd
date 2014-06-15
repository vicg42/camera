-------------------------------------------------------------------------
-- Company     : Yansar
-- Engineer    : Golovachenko Victor
--
-- Create Date : 13.06.2014 18:36:41
-- Module Name : prj_cfg
--
-- Description :
--
-- Revision:
-- Revision 0.01 - File Created
--
-------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

package prj_cfg is

constant C_PCFG_CCD_BIT_PER_PIXEL : integer := 10;
constant C_PCFG_CCD_DATA_LINE_COUNT : integer := 32;
constant C_PCFG_CCD_SYNC_LINE_COUNT : integer := 1;

constant C_PCFG_CCD_LVDS_COUNT : integer := C_PCFG_CCD_DATA_LINE_COUNT
                                            + C_PCFG_CCD_SYNC_LINE_COUNT;

end prj_cfg;


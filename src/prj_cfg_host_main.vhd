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

constant C_PCFG_SIM : string := "OFF";

--cfg CCD
constant C_PCFG_CCD_PIXBIT          : integer := 10;
constant C_PCFG_CCD_DATA_LINE_COUNT : integer := 32;
constant C_PCFG_CCD_SYNC_LINE_COUNT : integer := 1;
constant C_PCFG_CCD_WIN_X           : integer := 1024;--must be multiples 64!!!
constant C_PCFG_CCD_WIN_Y           : integer := 1024;--must be multiples 64!!!

constant C_PCFG_CCD_LVDS_COUNT : integer := C_PCFG_CCD_DATA_LINE_COUNT
                                            + C_PCFG_CCD_SYNC_LINE_COUNT;

constant C_PCFG_VDATA_PIXBIT  : integer := 8; --Pix range for write to memory

--cfg Memory Controller
constant C_PCGF_MEMCTRL_DWIDTH      : integer := 128;
constant C_PCFG_MEMCTRL_BANK_COUNT  : integer := 1;
constant C_PCFG_MEMARB_CH_COUNT     : integer := 2;

--cfg VIDEO OUT
constant C_PCGF_VOUT_TYPE  : string := "VGA";--"VGA"/"TV"
constant C_PCGF_VOUT_TEST  : string := "OFF";--"ON"/"OFF"

constant C_CGF_VBUFO_DWIDTH   : integer := 32;
constant C_PCFG_VOUT_START_X  : integer := 0;
constant C_PCFG_VOUT_START_Y  : integer := 0;

constant C_PCFG_TSTREG_COUNT_MAX   : integer := 8;

constant C_PCFG_FDEV_TSTREG0_NUM : integer := 0;
constant C_PCFG_FDEV_TSTREG1_NUM : integer := 1;
constant C_PCFG_FDEV_COUNT   : integer := 2;

end package prj_cfg;


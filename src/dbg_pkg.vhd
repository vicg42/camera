-------------------------------------------------------------------------
-- Company     : Yansar
-- Engineer    : Golovachenko Victor
--
-- Create Date : 13.06.2014 18:36:41
-- Module Name : dbg_pkg
--
-- Description :
--
-- Revision:
-- Revision 0.01 - File Created
--
-------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

package dbg_pkg is

type TDGB_ctrl_glob is record
start_vout : std_logic;
end record;

type TDGB_ctrl_out is record
glob : TDGB_ctrl_glob;
vout_start_x : std_logic_vector(15 downto 0);
vout_start_y : std_logic_vector(15 downto 0);
vout_memtrn_lenwr: std_logic_vector(7 downto 0);
vout_memtrn_lenrd: std_logic_vector(7 downto 0);
end record;

end dbg_pkg;


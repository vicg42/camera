-------------------------------------------------------------------------
-- Company     : Yansar
-- Engineer    : Golovachenko Victor
--
-- Create Date : 24.10.2014 18:16:41
-- Module Name : vfilter_core_pkg
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

package vfilter_core_pkg is

constant C_VFILTER_RANG : integer := 3;
constant C_VFILTER_RANG_MAX : integer := 3;

type TMatrix_X is array (0 to C_VFILTER_RANG_MAX - 1) of unsigned(7 downto 0);
type TMatrix is array (0 to C_VFILTER_RANG_MAX - 1) of TMatrix_X;

end package vfilter_core_pkg;

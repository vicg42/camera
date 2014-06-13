-------------------------------------------------------------------------
-- Company     : Yansar
-- Engineer    : Golovachenko Victor
--
-- Create Date : 13.06.2014 15:09:01
-- Module Name : clocks_pkg
--
-- Description :
--
-- Revision:
-- Revision 0.01 - File Created
--
-------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

package clocks_pkg is

type TRefClkPinIN is record
clk : std_logic_vector(2 downto 0);
end record;

--type TRefClkPinOUT is record
--oe : std_logic_vector(0 downto 0);
--end record;

end clocks_pkg;


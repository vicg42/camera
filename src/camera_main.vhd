-------------------------------------------------------------------------
-- Company     : Yansar
-- Engineer    : Golovachenko Victor
--
-- Create Date : 13.06.2014 12:31:35
-- Module Name : caamera_main
--
-- ����������/�������� :
--
-- Revision:
-- Revision 0.01 - File Created
--
-------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric std.all;

library work;
use work.vicg_common_pkg.all;

entity camera_main is
port(
--------------------------------------------------
--��������������� ����
--------------------------------------------------
pin_out_TP          : out   std_logic_vector(2 downto 0);

--------------------------------------------------
--Reference clock
--------------------------------------------------
pin_out_refclk      : out   TRefClkPinOUT;
pin_in_refclk       : in    TRefClkPinIN
);
end entity;

architecture struct of camera_main is



--MAIN
begin




end architecture;

-------------------------------------------------------------------------
-- Company     : Yansar
-- Engineer    : Golovachenko Victor
--
-- Create Date : 31.07.2014 10:19:11
-- Module Name : dbg_ctrl
--
-- Назначение/Описание :
--
--------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.dbg_pkg.all;

entity dbg_ctrl is
port(
p_out_usr     : out  TDGB_ctrl_out;
p_in_usr      : in   TDGB_ctrl_in;

--System
p_in_clk      : in   std_logic
);
end entity;

architecture behavioral of dbg_ctrl is

component dbg_icon
port (
CONTROL0 : inout std_logic_vector(35 downto 0);
CONTROL1 : inout std_logic_vector(35 downto 0)
);
end component;

component dbg_vio_usrctrl
port (
CONTROL : inout std_logic_vector(35 downto 0);
CLK : in  std_logic ;
SYNC_OUT  : out std_logic_vector(7 downto 0);
ASYNC_IN: in std_logic_vector(7 downto 0)
);
end component;

component dbg_vio_vout
port (
CONTROL : inout std_logic_vector(35 downto 0);
CLK : in  std_logic ;
SYNC_OUT  : out std_logic_vector(47 downto 0)
);
end component;

signal i_control_0 : std_logic_vector(35 downto 0);
signal i_control_1 : std_logic_vector(35 downto 0);

signal i_usrctrl_in  : std_logic_vector(7 downto 0);
signal i_usrctrl_out : std_logic_vector(7 downto 0);
signal i_vout        : std_logic_vector(47 downto 0);

--MAIN
begin


p_out_usr.glob.start_vout <= i_usrctrl_out(0);
p_out_usr.vout_memtrn_lenwr <= i_vout(7 downto 0);
p_out_usr.vout_memtrn_lenrd <= i_vout(15 downto 8);
p_out_usr.vout_start_x <= i_vout(31 downto 16);
p_out_usr.vout_start_y <= i_vout(47 downto 32);

i_usrctrl_in(0) <= p_in_usr.tv_detect;
i_usrctrl_in(7 downto 1) <= (others => '0');


m_icon : dbg_icon
port map (
CONTROL0 => i_control_0,
CONTROL1 => i_control_1
);

m_usrctrl : dbg_vio_usrctrl
port map (
CONTROL => i_control_0,
CLK => p_in_clk,
SYNC_OUT  => i_usrctrl_out,
ASYNC_IN => i_usrctrl_in
);

m_vout : dbg_vio_vout
port map (
CONTROL => i_control_1,
CLK => p_in_clk,
SYNC_OUT  => i_vout
);


--END MAIN
end architecture;

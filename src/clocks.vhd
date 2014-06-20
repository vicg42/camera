-------------------------------------------------------------------------
-- Company     : Yansar
-- Engineer    : Golovachenko Victor
--
-- Create Date : 13.06.2014 15:08:42
-- Module Name : clocks
--
-- Назначение/Описание :
--
--
-- Revision:
-- Revision 0.01 - File Created
--
-------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

library work;
use work.reduce_Pack.all;
use work.clocks_pkg.all;

entity clocks is
port(
p_out_rst  : out   std_logic;
p_out_gclk : out   std_logic_vector(7 downto 0);

--p_out_clk  : out   TRefClkPinOUT;
p_in_clk   : in    TRefclk_pinin
);
end;

architecture behavior of clocks is

signal g_clkin       : std_logic_vector(2 downto 0);

signal i_clk_fb      : std_logic_vector(2 downto 0);
signal g_clk_fb      : std_logic_vector(2 downto 0);
signal i_pll_locked  : std_logic_vector(2 downto 0);
signal i_clk0_out    : std_logic_vector(0 downto 0);
signal i_clk1_out    : std_logic_vector(0 downto 0);
signal i_clk2_out    : std_logic_vector(0 downto 0);

begin


p_out_rst <= not (AND_reduce(i_pll_locked));

bufg_clk0: BUFG port map(I => i_clk0_out(0), O => p_out_gclk(0)); --200MHz
bufg_clk1: BUFG port map(I => i_clk2_out(0), O => p_out_gclk(1)); --3100MHz


gen_clkin : for i in 0 to p_in_clk.clk'length - 1 generate
m_ibufg : IBUFG port map(I  => p_in_clk.clk(i), O => g_clkin(i));
end generate;--gen_clkin


--#######################################
--20Mhz
--#######################################
-- Reference clock MMCM (CLKFBOUT range 600.00 MHz to 1440.00 MHz)
-- CLKvco   = (CLKIN1/DIVCLK_DIVIDE) * CLKFBOUT_MULT_F
-- CLKFBOUT = (CLKIN1/DIVCLK_DIVIDE) * CLKFBOUT_MULT_F
-- CLKOUTn  = (CLKIN1/DIVCLK_DIVIDE) * CLKFBOUT_MULT_F/CLKOUTn_DIVIDE
-- CLKFvco =  (20 MHz/1) * 50.000      = 1000 MHz
-- CLKOUT0  = (20 MHz/1) * 50.000/5    = 200 MHz
-- CLKOUT1  = (20 MHz/1) * 50.000/5    = 200 MHz
-- CLKOUT2  = (20 MHz/1) * 50.000/5    = 200 MHz
-- CLKOUT3  = (20 MHz/1) * 50.000/5    = 200 MHz

m_mmcm_ref_clk0 : MMCME2_BASE
generic map(
BANDWIDTH          => "OPTIMIZED", -- string := "OPTIMIZED"
CLKIN1_PERIOD      => 50.000,      -- real := 0.0
DIVCLK_DIVIDE      => 1,           -- integer := 1 (1 to 128)
CLKFBOUT_MULT_F    => 50.000,      -- real := 1.0  (5.0 to 64.0)
CLKOUT0_DIVIDE_F   => 5.000,       -- real := 1.0  (1.0 to 128.0)
CLKOUT1_DIVIDE     => 5,           -- integer := 1
CLKOUT2_DIVIDE     => 5,           -- integer := 1
CLKOUT3_DIVIDE     => 5,           -- integer := 1
CLKOUT4_DIVIDE     => 1,           -- integer := 1
CLKOUT5_DIVIDE     => 1,           -- integer := 1
CLKOUT6_DIVIDE     => 1,           -- integer := 1
CLKFBOUT_PHASE     => 0.000,       -- real := 0.0
CLKOUT0_PHASE      => 0.000,       -- real := 0.0
CLKOUT1_PHASE      => 0.000,       -- real := 0.0
CLKOUT2_PHASE      => 0.000,       -- real := 0.0
CLKOUT3_PHASE      => 0.000,       -- real := 0.0
CLKOUT4_PHASE      => 0.000,       -- real := 0.0
CLKOUT5_PHASE      => 0.000,       -- real := 0.0
CLKOUT6_PHASE      => 0.000,       -- real := 0.0
CLKOUT0_DUTY_CYCLE => 0.500,       -- real := 0.5
CLKOUT1_DUTY_CYCLE => 0.500,       -- real := 0.5
CLKOUT2_DUTY_CYCLE => 0.500,       -- real := 0.5
CLKOUT3_DUTY_CYCLE => 0.500,       -- real := 0.5
CLKOUT4_DUTY_CYCLE => 0.500,       -- real := 0.5
CLKOUT5_DUTY_CYCLE => 0.500,       -- real := 0.5
CLKOUT6_DUTY_CYCLE => 0.500,       -- real := 0.5
CLKOUT4_CASCADE    => FALSE,       -- boolean := FALSE
REF_JITTER1        => 0.0,         -- real := 0.0
STARTUP_WAIT       => FALSE)       -- boolean := FALSE
port map(
RST       => '0',
PWRDWN    => '0',
CLKIN1    => g_clkin(0),
CLKFBIN   => g_clk_fb(0),
CLKFBOUT  => i_clk_fb(0),
CLKFBOUTB => open,
CLKOUT0   => i_clk0_out(0),
CLKOUT0B  => open,
CLKOUT1   => open,--i_clk0_out(1),
CLKOUT1B  => open,
CLKOUT2   => open,--i_clk0_out(2),
CLKOUT2B  => open,
CLKOUT3   => open,--i_clk0_out(3),
CLKOUT3B  => open,
CLKOUT4   => open,--i_clk0_out(5),
CLKOUT5   => open,
CLKOUT6   => open,
LOCKED    => i_pll_locked(0)
);
-- MMCM feedback (not using BUFG, because we don't care about phase compensation)
g_clk_fb(0) <= i_clk_fb(0);


--#######################################
--54Mhz
--#######################################
-- Reference clock MMCM (CLKFBOUT range 600.00 MHz to 1440.00 MHz)
-- CLKvco   = (CLKIN1/DIVCLK_DIVIDE) * CLKFBOUT_MULT_F
-- CLKFBOUT = (CLKIN1/DIVCLK_DIVIDE) * CLKFBOUT_MULT_F
-- CLKOUTn  = (CLKIN1/DIVCLK_DIVIDE) * CLKFBOUT_MULT_F/CLKOUTn_DIVIDE
-- CLKFvco =  (54 MHz/1) * 14.000      = 756 MHz
-- CLKOUT0  = (54 MHz/1) * 14.000/1    = 756 MHz
-- CLKOUT1  = (54 MHz/1) * 14.000/1    = 756 MHz
-- CLKOUT2  = (54 MHz/1) * 14.000/1    = 756 MHz
-- CLKOUT3  = (54 MHz/1) * 14.000/1    = 756 MHz

m_mmcm_ref_clk1 : MMCME2_BASE
generic map(
BANDWIDTH          => "OPTIMIZED", -- string := "OPTIMIZED"
CLKIN1_PERIOD      => 18.518,      -- real := 0.0
DIVCLK_DIVIDE      => 1,           -- integer := 1 (1 to 128)
CLKFBOUT_MULT_F    => 14.000,      -- real := 1.0  (5.0 to 64.0)
CLKOUT0_DIVIDE_F   => 1.000,       -- real := 1.0  (1.0 to 128.0)
CLKOUT1_DIVIDE     => 1,           -- integer := 1
CLKOUT2_DIVIDE     => 1,           -- integer := 1
CLKOUT3_DIVIDE     => 1,           -- integer := 1
CLKOUT4_DIVIDE     => 1,           -- integer := 1
CLKOUT5_DIVIDE     => 1,           -- integer := 1
CLKOUT6_DIVIDE     => 1,           -- integer := 1
CLKFBOUT_PHASE     => 0.000,       -- real := 0.0
CLKOUT0_PHASE      => 0.000,       -- real := 0.0
CLKOUT1_PHASE      => 0.000,       -- real := 0.0
CLKOUT2_PHASE      => 0.000,       -- real := 0.0
CLKOUT3_PHASE      => 0.000,       -- real := 0.0
CLKOUT4_PHASE      => 0.000,       -- real := 0.0
CLKOUT5_PHASE      => 0.000,       -- real := 0.0
CLKOUT6_PHASE      => 0.000,       -- real := 0.0
CLKOUT0_DUTY_CYCLE => 0.500,       -- real := 0.5
CLKOUT1_DUTY_CYCLE => 0.500,       -- real := 0.5
CLKOUT2_DUTY_CYCLE => 0.500,       -- real := 0.5
CLKOUT3_DUTY_CYCLE => 0.500,       -- real := 0.5
CLKOUT4_DUTY_CYCLE => 0.500,       -- real := 0.5
CLKOUT5_DUTY_CYCLE => 0.500,       -- real := 0.5
CLKOUT6_DUTY_CYCLE => 0.500,       -- real := 0.5
CLKOUT4_CASCADE    => FALSE,       -- boolean := FALSE
REF_JITTER1        => 0.0,         -- real := 0.0
STARTUP_WAIT       => FALSE)       -- boolean := FALSE
port map(
RST       => '0',
PWRDWN    => '0',
CLKIN1    => g_clkin(1),
CLKFBIN   => g_clk_fb(1),
CLKFBOUT  => i_clk_fb(1),
CLKFBOUTB => open,
CLKOUT0   => i_clk1_out(0),
CLKOUT0B  => open,
CLKOUT1   => open,--i_clk1_out(1),
CLKOUT1B  => open,
CLKOUT2   => open,--i_clk1_out(2),
CLKOUT2B  => open,
CLKOUT3   => open,--i_clk1_out(3),
CLKOUT3B  => open,
CLKOUT4   => open,--i_clk1_out(5),
CLKOUT5   => open,
CLKOUT6   => open,
LOCKED    => i_pll_locked(1)
);
-- MMCM feedback (not using BUFG, because we don't care about phase compensation)
g_clk_fb(1) <= i_clk_fb(1);


--#######################################
--62Mhz
--#######################################
-- Reference clock MMCM (CLKFBOUT range 600.00 MHz to 1440.00 MHz)
-- CLKvco   = (CLKIN1/DIVCLK_DIVIDE) * CLKFBOUT_MULT_F
-- CLKFBOUT = (CLKIN1/DIVCLK_DIVIDE) * CLKFBOUT_MULT_F
-- CLKOUTn  = (CLKIN1/DIVCLK_DIVIDE) * CLKFBOUT_MULT_F/CLKOUTn_DIVIDE
-- CLKFvco =  (62 MHz/1) * 10.000      = 620 MHz
-- CLKOUT0  = (62 MHz/1) * 10.000/2    = 310 MHz
-- CLKOUT1  = (62 MHz/1) * 10.000/2    = 310 MHz
-- CLKOUT2  = (62 MHz/1) * 10.000/2    = 310 MHz
-- CLKOUT3  = (62 MHz/1) * 10.000/2    = 310 MHz

m_mmcm_ref_clk2 : MMCME2_BASE
generic map(
BANDWIDTH          => "OPTIMIZED", -- string := "OPTIMIZED"
CLKIN1_PERIOD      => 16.129,      -- real := 0.0
DIVCLK_DIVIDE      => 1,           -- integer := 1 (1 to 128)
CLKFBOUT_MULT_F    => 10.000,      -- real := 1.0  (5.0 to 64.0)
CLKOUT0_DIVIDE_F   => 2.000,       -- real := 1.0  (1.0 to 128.0)
CLKOUT1_DIVIDE     => 2,           -- integer := 1
CLKOUT2_DIVIDE     => 2,           -- integer := 1
CLKOUT3_DIVIDE     => 2,           -- integer := 1
CLKOUT4_DIVIDE     => 1,           -- integer := 1
CLKOUT5_DIVIDE     => 1,           -- integer := 1
CLKOUT6_DIVIDE     => 1,           -- integer := 1
CLKFBOUT_PHASE     => 0.000,       -- real := 0.0
CLKOUT0_PHASE      => 0.000,       -- real := 0.0
CLKOUT1_PHASE      => 0.000,       -- real := 0.0
CLKOUT2_PHASE      => 0.000,       -- real := 0.0
CLKOUT3_PHASE      => 0.000,       -- real := 0.0
CLKOUT4_PHASE      => 0.000,       -- real := 0.0
CLKOUT5_PHASE      => 0.000,       -- real := 0.0
CLKOUT6_PHASE      => 0.000,       -- real := 0.0
CLKOUT0_DUTY_CYCLE => 0.500,       -- real := 0.5
CLKOUT1_DUTY_CYCLE => 0.500,       -- real := 0.5
CLKOUT2_DUTY_CYCLE => 0.500,       -- real := 0.5
CLKOUT3_DUTY_CYCLE => 0.500,       -- real := 0.5
CLKOUT4_DUTY_CYCLE => 0.500,       -- real := 0.5
CLKOUT5_DUTY_CYCLE => 0.500,       -- real := 0.5
CLKOUT6_DUTY_CYCLE => 0.500,       -- real := 0.5
CLKOUT4_CASCADE    => FALSE,       -- boolean := FALSE
REF_JITTER1        => 0.0,         -- real := 0.0
STARTUP_WAIT       => FALSE)       -- boolean := FALSE
port map(
RST       => '0',
PWRDWN    => '0',
CLKIN1    => g_clkin(2),
CLKFBIN   => g_clk_fb(2),
CLKFBOUT  => i_clk_fb(2),
CLKFBOUTB => open,
CLKOUT0   => i_clk2_out(0),
CLKOUT0B  => open,
CLKOUT1   => open,--i_clk2_out(1),
CLKOUT1B  => open,
CLKOUT2   => open,--i_clk2_out(2),
CLKOUT2B  => open,
CLKOUT3   => open,--i_clk2_out(3),
CLKOUT3B  => open,
CLKOUT4   => open,--i_clk2_out(5),
CLKOUT5   => open,
CLKOUT6   => open,
LOCKED    => i_pll_locked(2)
);
-- MMCM feedback (not using BUFG, because we don't care about phase compensation)
g_clk_fb(2) <= i_clk_fb(2);

end;

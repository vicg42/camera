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
use work.reduce_pack.all;
use work.clocks_pkg.all;
use work.vicg_common_pkg.all;

entity clocks is
generic(
G_VOUT_TYPE : string := "VGA"
);
port(
p_out_rst  : out   std_logic;
p_out_gclk : out   std_logic_vector(7 downto 0);

--p_out_clk  : out   TRefClkPinOUT;
p_in_clk   : in    TRefclk_pinin
);
end entity clocks;

architecture xilinx of clocks is

signal g_clkin       : std_logic_vector(2 downto 0);

signal i_clk_fb      : std_logic_vector(2 downto 0);
signal g_clk_fb      : std_logic_vector(2 downto 0);
signal i_pll_locked  : std_logic_vector(2 downto 0);
signal i_clk0_out    : std_logic_vector(2 downto 0);
signal i_clk1_out    : std_logic_vector(1 downto 0);
signal i_clk2_out    : std_logic_vector(0 downto 0);


begin --architecture xilinx


p_out_rst <= not (AND_reduce(i_pll_locked));

bufg_clk0: BUFG port map(I => i_clk0_out(1), O => p_out_gclk(0)); --200MHz
bufg_clk1: BUFG port map(I => i_clk1_out(0), O => p_out_gclk(1)); --310MHz (CCD inputclk)
bufg_clk7: BUFG port map(I => i_clk1_out(1), O => p_out_gclk(7)); --62MHz

gen_vga1 : if strcmp(G_VOUT_TYPE, "VGA") generate begin
bufg_clk2: BUFG port map(I => i_clk2_out(0), O => p_out_gclk(2)); --135MHz (VGA Pixclk)
end generate gen_vga1;

bufg_clk3: BUFG port map(I => i_clk0_out(2), O => p_out_gclk(3)); --200MHz
bufg_clk4: BUFG port map(I => i_clk0_out(0), O => p_out_gclk(4)); --400MHz
bufg_clk5: BUFG port map(I => g_clkin(0), O => p_out_gclk(5)); --20MHz

gen_tv1 : if strcmp(G_VOUT_TYPE, "TV") generate begin
bufg_clk2: BUFG port map(I => i_clk2_out(0), O => p_out_gclk(2)); --17,734472MHz
end generate gen_tv1;

p_out_gclk(6) <= g_clkin(2); --62MHz

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
-- CLKOUT0  = (20 MHz/1) * 50.000/2.5  = 400 MHz
-- CLKOUT1  = (20 MHz/1) * 50.000/5    = 200 MHz
-- CLKOUT2  = (20 MHz/1) * 50.000/5    = 200 MHz
-- CLKOUT3  = (20 MHz/1) * 50.000/80   = 12.5 MHz

m_mmcm_clk_20MHz : MMCME2_BASE
generic map(
BANDWIDTH          => "OPTIMIZED", -- string := "OPTIMIZED"
CLKIN1_PERIOD      => 50.000,      -- real := 0.0
DIVCLK_DIVIDE      => 1,           -- integer := 1 (1 to 128)
CLKFBOUT_MULT_F    => 50.000,      -- real := 1.0  (5.0 to 64.0)
CLKOUT0_DIVIDE_F   => 2.500,       -- real := 1.0  (1.0 to 128.0)
CLKOUT1_DIVIDE     => 5,           -- integer := 1
CLKOUT2_DIVIDE     => 5,           -- integer := 1
CLKOUT3_DIVIDE     => 80,          -- integer := 1
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
CLKOUT1   => i_clk0_out(1),
CLKOUT1B  => open,
CLKOUT2   => i_clk0_out(2),
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
--62Mhz
--#######################################
-- Reference clock MMCM (CLKFBOUT range 600.00 MHz to 1440.00 MHz)
-- CLKvco   = (CLKIN1/DIVCLK_DIVIDE) * CLKFBOUT_MULT_F
-- CLKFBOUT = (CLKIN1/DIVCLK_DIVIDE) * CLKFBOUT_MULT_F
-- CLKOUTn  = (CLKIN1/DIVCLK_DIVIDE) * CLKFBOUT_MULT_F/CLKOUTn_DIVIDE
-- CLKFvco =  (62 MHz/1) * 10.000      = 620 MHz
-- CLKOUT0  = (62 MHz/1) * 10.000/2    = 310 MHz
-- CLKOUT1  = (62 MHz/1) * 10.000/10   = 62 MHz

m_mmcm_clk_62MHz : MMCME2_BASE
generic map(
BANDWIDTH          => "OPTIMIZED", -- string := "OPTIMIZED"
CLKIN1_PERIOD      => 16.129,      -- real := 0.0
DIVCLK_DIVIDE      => 1,           -- integer := 1 (1 to 128)
CLKFBOUT_MULT_F    => 10.000,      -- real := 1.0  (5.0 to 64.0)
CLKOUT0_DIVIDE_F   => 2.000,       -- real := 1.0  (1.0 to 128.0)
CLKOUT1_DIVIDE     => 10,           -- integer := 1
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
CLKIN1    => g_clkin(2),
CLKFBIN   => g_clk_fb(1),
CLKFBOUT  => i_clk_fb(1),
CLKFBOUTB => open,
CLKOUT0   => i_clk1_out(0),
CLKOUT0B  => open,
CLKOUT1   => i_clk1_out(1),--i_clk2_out(1),
CLKOUT1B  => open,
CLKOUT2   => open,--i_clk2_out(2),
CLKOUT2B  => open,
CLKOUT3   => open,--i_clk2_out(3),
CLKOUT3B  => open,
CLKOUT4   => open,--i_clk2_out(5),
CLKOUT5   => open,
CLKOUT6   => open,
LOCKED    => i_pll_locked(1)
);
-- MMCM feedback (not using BUFG, because we don't care about phase compensation)
g_clk_fb(1) <= i_clk_fb(1);

gen_vga2 : if strcmp(G_VOUT_TYPE, "VGA") generate
begin
--#######################################
--54Mhz
--#######################################
-- Reference clock MMCM (CLKFBOUT range 600.00 MHz to 1440.00 MHz)
-- CLKvco   = (CLKIN1/DIVCLK_DIVIDE) * CLKFBOUT_MULT_F
-- CLKFBOUT = (CLKIN1/DIVCLK_DIVIDE) * CLKFBOUT_MULT_F
-- CLKOUTn  = (CLKIN1/DIVCLK_DIVIDE) * CLKFBOUT_MULT_F/CLKOUTn_DIVIDE
-- CLKFvco =  (54 MHz/1) * 18.500       = 999 MHz
-- CLKOUT0  = (54 MHz/1) * 18.375/31.500 = 31.5 MHz
-- CLKOUT0  = (54 MHz/1) * 18.750/20.250 = 50 MHz
-- CLKOUT1  = (54 MHz/1) * 18.500/1     = 999 MHz
-- CLKOUT2  = (54 MHz/1) * 18.500/1     = 999 MHz
-- CLKOUT3  = (54 MHz/1) * 18.500/1     = 999 MHz

m_mmcm_clk_54HHz : MMCME2_BASE
generic map(
BANDWIDTH          => "OPTIMIZED", -- string := "OPTIMIZED"

----VGA(600x480)
--CLKIN1_PERIOD      => 18.518,      -- real := 0.0 --54MHz
--DIVCLK_DIVIDE      => 1,           -- integer := 1 (1 to 128)
--CLKFBOUT_MULT_F    => 18.375,      -- real := 1.0  (5.0 to 64.0)
--CLKOUT0_DIVIDE_F   => 31.500,      -- real := 1.0  (1.0 to 128.0)

--VGA(800x600)
CLKIN1_PERIOD      => 18.518,      -- real := 0.0 --54MHz
DIVCLK_DIVIDE      => 1,           -- integer := 1 (1 to 128)
CLKFBOUT_MULT_F    => 18.750,      -- real := 1.0  (5.0 to 64.0)
CLKOUT0_DIVIDE_F   => 20.250,      -- real := 1.0  (1.0 to 128.0)

----VGA(1024x768)
--CLKIN1_PERIOD      => 16.129,      -- real := 0.0 --62MHz
--DIVCLK_DIVIDE      => 1,           -- integer := 1 (1 to 128)
--CLKFBOUT_MULT_F    => 16.875,      -- real := 1.0  (5.0 to 64.0)
--CLKOUT0_DIVIDE_F   => 7.750,       -- real := 1.0  (1.0 to 128.0)

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
CLKIN1    => g_clkin(1),--54MHz
--CLKIN1    => g_clkin(2),--62Mhz
CLKFBIN   => g_clk_fb(2),
CLKFBOUT  => i_clk_fb(2),
CLKFBOUTB => open,
CLKOUT0   => i_clk2_out(0),
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
LOCKED    => i_pll_locked(2)
);
-- MMCM feedback (not using BUFG, because we don't care about phase compensation)
g_clk_fb(2) <= i_clk_fb(2);
end generate gen_vga2;


gen_tv2 : if strcmp(G_VOUT_TYPE, "TV") generate
begin
--#######################################
--54Mhz
--#######################################
-- Reference clock MMCM (CLKFBOUT range 600.00 MHz to 1440.00 MHz)
-- CLKvco   = (CLKIN1/DIVCLK_DIVIDE) * CLKFBOUT_MULT_F
-- CLKFBOUT = (CLKIN1/DIVCLK_DIVIDE) * CLKFBOUT_MULT_F
-- CLKOUTn  = (CLKIN1/DIVCLK_DIVIDE) * CLKFBOUT_MULT_F/CLKOUTn_DIVIDE
-- CLKFvco =  (54 MHz/3) * 50.000       = 900 MHz
-- CLKOUT0  = (54 MHz/3) * 50.000/50.750 = 17,733990147783251231527093596059 MHz
-- CLKOUT1  = (54 MHz/3) * 50.000/1     = 900 MHz
-- CLKOUT2  = (54 MHz/3) * 50.000/1     = 900 MHz
-- CLKOUT3  = (54 MHz/3) * 50.000/1     = 900 MHz

m_mmcm_tv_pal : MMCME2_BASE
generic map(
BANDWIDTH          => "OPTIMIZED", -- string := "OPTIMIZED"
CLKIN1_PERIOD      => 18.518,      -- real := 0.0
DIVCLK_DIVIDE      => 3,           -- integer := 1 (1 to 128)
CLKFBOUT_MULT_F    => 50.000,      -- real := 1.0  (5.0 to 64.0)
CLKOUT0_DIVIDE_F   => 50.750,      -- real := 1.0  (1.0 to 128.0)
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
CLKFBIN   => g_clk_fb(2),
CLKFBOUT  => i_clk_fb(2),
CLKFBOUTB => open,
CLKOUT0   => i_clk2_out(0),
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
LOCKED    => i_pll_locked(2)
);
-- MMCM feedback (not using BUFG, because we don't care about phase compensation)
g_clk_fb(2) <= i_clk_fb(2);

end generate gen_tv2;

end architecture xilinx;

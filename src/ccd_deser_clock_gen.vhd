------------------------------------------------------------------------------
--   ____  ____
--  /   /\/   /
-- /___/  \  /   Vendor: Xilinx
-- \   \   \/    Version: 1.0
--  \   \        Filename: clock_generator_pll_7_to_1_diff_ddr.vhd
--  /   /        Date Last Modified:  May 30th 2012
-- /___/   /\    Date Created: August 1 2009
-- \   \  /  \
--  \___\/\___\
--
--Device: Virtex 6
--Purpose: MMCM Based clock generator. Takes in a differential clock and multiplies it
--    by the amount specified.
--
--Reference:  XAPP585.pdf
--
--Revision History:
--    Rev 1.0 - First created (nicks)
------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all ;

library unisim ;
use unisim.vcomponents.all ;

library work;
use work.reduce_pack.all;

entity ccd_deser_clock_gen is
generic (
CLKIN_PERIOD    : real := 6.000 ;     -- clock period (ns) of input clock on clkin_p
MMCM_MODE       : integer := 1 ;      -- Parameter to set multiplier for MMCM either 1 or 2 to get VCO in correct operating range. 1 multiplies clock by 7, 2 multiplies clock by 14
MMCM_MODE_REAL  : real := 1.000 ;     -- Parameter to set multiplier for MMCM either 1 or 2 to get VCO in correct operating range. 1 multiplies clock by 7, 2 multiplies clock by 14
TX_CLOCK        : string := "BUFIO" ; -- Parameter to set transmission clock buffer type, BUFIO, BUF_H, BUF_G
INTER_CLOCK     : string := "BUF_R" ; -- Parameter to set intermediate clock buffer type, BUFR, BUF_H, BUF_G
PIXEL_CLOCK     : string := "BUF_G" ; -- Parameter to set final clock buffer type, BUF_R, BUF_H, BUF_G
USE_PLL         : boolean := FALSE ;  -- Parameter to enable PLL use rather than MMCM use, note, PLL does not support BUFIO and BUFR
DIFF_TERM       : boolean := TRUE     -- Enable or disable internal differential termination
);
port  (
reset     :  in std_logic ;     -- reset (active high)
clkin_p   :  in std_logic ;     -- differential clock input
clkin_n   :  in std_logic ;     -- differential clock input
txclk     : out std_logic ;     -- CLK for serdes
pixel_clk : out std_logic ;     -- Pixel clock output
txclk_div : out std_logic ;     -- CLKDIV for serdes, and gearbox output = pixel clock / 2
mmcm_lckd : out std_logic ;     -- Locked output from MMCM
status    : out std_logic_vector(6 downto 0);   -- Status bus
p_out_tst : out std_logic_vector(31 downto 0)
);
end ccd_deser_clock_gen ;

architecture xilinx of ccd_deser_clock_gen is

signal clkint        : std_logic ;
signal mmcmout_xn    : std_logic ;
signal mmcmout_x1    : std_logic ;
signal mmcmout_d2    : std_logic ;
signal pixel_clk_int : std_logic ;
signal clkint_tmp    : std_logic ;
signal tst_ccdclkin_cnt: std_logic_vector(3 downto 0) ;


begin

process(clkint)
begin
if rising_edge(clkint) then
tst_ccdclkin_cnt <= tst_ccdclkin_cnt + 1;
end if;
end process;

p_out_tst(3 downto 0) <= tst_ccdclkin_cnt;

pixel_clk <= pixel_clk_int ;

m_ibufds : IBUFDS
port map (
I  => clkin_p,
IB => clkin_n,
O  => clkint_tmp
);
m_bufg : BUFG port map(I => clkint_tmp, O => clkint) ;


--################################
-- use an MMCM
--################################
loop8 : if USE_PLL = FALSE generate

status(6) <= '1' ;

-- CLKFBOUT = (CLKIN1/DIVCLK_DIVIDE)
-- CLKOUTn  = (CLKIN1/DIVCLK_DIVIDE) * CLKFBOUT_MULT_F/CLKOUTn_DIVIDE

tx_mmcm_adv_inst : MMCME2_ADV
generic map(
--COMPENSATION    => "ZHOLD",      -- "SYSTEM_SYNCHRONOUS", "SOURCE_SYNCHRONOUS", "INTERNAL", "EXTERNAL", "DCM2MMCM", "MMCM2DCM"
BANDWIDTH       => "OPTIMIZED",  -- "high", "low" or "optimized"

CLKIN1_PERIOD   => CLKIN_PERIOD, -- clock period (ns) of input clock on clkin1
CLKIN2_PERIOD   => CLKIN_PERIOD, -- clock period (ns) of input clock on clkin2

CLKFBOUT_MULT_F => (2.000 * MMCM_MODE_REAL), -- multiplication factor for all output clocks
DIVCLK_DIVIDE   => 1,                        -- division factor for all clocks (1 to 52)
CLKFBOUT_PHASE  => 0.0,                      -- phase shift (degrees) of all output clocks

CLKOUT0_DIVIDE_F   => (2.000 * MMCM_MODE_REAL), -- division factor for clkout0 (1 to 128)
CLKOUT0_DUTY_CYCLE => 0.5,              -- duty cycle for clkout0 (0.01 to 0.99)
CLKOUT0_PHASE      => 0.0,              -- phase shift (degrees) for clkout0 (0.0 to 360.0)
CLKOUT1_DIVIDE     => (10 * MMCM_MODE), -- division factor for clkout1 (1 to 128)
CLKOUT1_DUTY_CYCLE => 0.5,              -- duty cycle for clkout1 (0.01 to 0.99)
CLKOUT1_PHASE      => 0.0,              -- phase shift (degrees) for clkout1 (0.0 to 360.0)
CLKOUT2_DIVIDE     => 8,                -- division factor for clkout2 (1 to 128)
CLKOUT2_DUTY_CYCLE => 0.5,              -- duty cycle for clkout2 (0.01 to 0.99)
CLKOUT2_PHASE      => 0.0,              -- phase shift (degrees) for clkout2 (0.0 to 360.0)
CLKOUT3_DIVIDE     => 8,                -- division factor for clkout3 (1 to 128)
CLKOUT3_DUTY_CYCLE => 0.5,              -- duty cycle for clkout3 (0.01 to 0.99)
CLKOUT3_PHASE      => 0.0,              -- phase shift (degrees) for clkout3 (0.0 to 360.0)
CLKOUT4_DIVIDE     => 8,                -- division factor for clkout4 (1 to 128)
CLKOUT4_DUTY_CYCLE => 0.5,              -- duty cycle for clkout4 (0.01 to 0.99)
CLKOUT4_PHASE      => 0.0,              -- phase shift (degrees) for clkout4 (0.0 to 360.0)
CLKOUT5_DIVIDE     => 8,                -- division factor for clkout5 (1 to 128)
CLKOUT5_DUTY_CYCLE => 0.5,              -- duty cycle for clkout5 (0.01 to 0.99)
CLKOUT5_PHASE      => 0.0               -- phase shift (degrees) for clkout5 (0.0 to 360.0)
)
port map (
CLKFBOUT     => mmcmout_x1,         -- general output feedback signal   (= pixel_clk = pixel_clk_int)
CLKFBOUTB    => open,
CLKFBSTOPPED => open,
CLKINSTOPPED => open,
CLKOUT0      => mmcmout_xn,         -- x7 clock for transmitter (= txclk)
CLKOUT0B     => open,
CLKOUT1      => mmcmout_d2,                                   --(= txclk_div)
CLKOUT1B     => open,
CLKOUT2      => open,
CLKOUT2B     => open,
CLKOUT3      => open,               -- x2 clock for BUFG
CLKOUT3B     => open,
CLKOUT4      => open,               -- one of six general clock output signals
CLKOUT5      => open,               -- one of six general clock output signals
DO           => open,               -- dynamic reconfig data output (16-bits)
DRDY         => open,               -- dynamic reconfig ready output
PSDONE       => open,
PSCLK        => '0',
PSEN         => '0',
PSINCDEC     => '0',
PWRDWN       => '0',
LOCKED       => mmcm_lckd,          -- active high mmcm lock signal
CLKFBIN      => pixel_clk_int,      -- clock feedback input
CLKIN1       => clkint,             -- primary clock input
CLKIN2       => '0',                -- secondary clock input
CLKINSEL     => '1',                -- selects '1' = clkin1, '0' = clkin2
DADDR        => "0000000",          -- dynamic reconfig address input (7-bits)
DCLK         => '0',                -- dynamic reconfig clock input
DEN          => '0',                -- dynamic reconfig enable input
DI           => "0000000000000000", -- dynamic reconfig data input (16-bits)
DWE          => '0',                -- dynamic reconfig write enable input
RST          => reset               -- asynchronous mmcm reset
);

loop6 : if PIXEL_CLOCK = "BUF_G" generate
   bufg_mmcm_x1 : BUFG
   port map (I => mmcmout_x1, O => pixel_clk_int) ;
   status(1 downto 0) <= "00" ;
end generate ;

loop6a : if PIXEL_CLOCK = "BUF_R" generate
   bufr_mmcm_x1 : BUFR
   generic map(BUFR_DIVIDE => "1", SIM_DEVICE => "7SERIES")
   port map (I => mmcmout_x1, CE => '1', O => pixel_clk_int, CLR => '0') ;
   status(1 downto 0) <= "01" ;
end generate ;

loop6b : if PIXEL_CLOCK = "BUF_H" generate
   bufh_mmcm_x1 : BUFH
   port map (I => mmcmout_x1, O => pixel_clk_int) ;
   status(1 downto 0) <= "10" ;
end generate ;

loop7 : if INTER_CLOCK = "BUF_G" generate
   bufg_mmcm_d4 : BUFG
   port map(I => mmcmout_d2, O => txclk_div) ;
   status(3 downto 2) <= "00" ;
end generate ;

loop7a : if INTER_CLOCK = "BUF_R" generate
   bufr_mmcm_d4 :  BUFR
   generic map(BUFR_DIVIDE => "1", SIM_DEVICE => "7SERIES")
   port map (I => mmcmout_d2, CE => '1', O => txclk_div, CLR => '0') ;
   status(3 downto 2) <= "01" ;
end generate ;

loop7b : if INTER_CLOCK = "BUF_H" generate
   bufh_mmcm_x1 : BUFH
   port map (I => mmcmout_d2, O => txclk_div) ;
   status(3 downto 2) <= "10" ;
end generate ;

loop9 : if TX_CLOCK = "BUF_G" generate
   bufg_mmcm_xn : BUFG
   port map(I => mmcmout_xn, O => txclk) ;
   status(5 downto 4) <= "00" ;
end generate ;

loop9a : if TX_CLOCK = "BUFIO" generate
   bufio_mmcm_xn : BUFIO
   port map (I => mmcmout_xn, O => txclk) ;
   status(5 downto 4) <= "11" ;
end generate ;

loop9b : if TX_CLOCK = "BUF_H" generate
   bufh_mmcm_xn : BUFH
   port map(I => mmcmout_xn, O => txclk) ;
   status(5 downto 4) <= "10" ;
end generate ;
end generate ; --loop8 : if USE_PLL = FALSE generate  -- use an MMCM


--################################
-- use an MMCM
--################################
loop2 : if USE_PLL = TRUE generate

status(6) <= '0' ;

rx_mmcm_adv_inst : PLLE2_ADV
generic map(
BANDWIDTH       => "OPTIMIZED",
COMPENSATION    => "ZHOLD",
REF_JITTER1     => 0.100,

CLKIN1_PERIOD   => CLKIN_PERIOD,
CLKIN2_PERIOD   => CLKIN_PERIOD,
DIVCLK_DIVIDE   => 1,
CLKFBOUT_MULT   => (7 * MMCM_MODE),
CLKFBOUT_PHASE  => 0.0,

CLKOUT0_DIVIDE     => (2 * MMCM_MODE),
CLKOUT0_DUTY_CYCLE => 0.5,
CLKOUT0_PHASE      => 0.0,
CLKOUT1_DIVIDE     => (14 * MMCM_MODE),
CLKOUT1_DUTY_CYCLE => 0.5,
CLKOUT1_PHASE      => 0.0,
CLKOUT2_DIVIDE     => 7,
CLKOUT2_DUTY_CYCLE => 0.5,
CLKOUT2_PHASE      => 0.0,
CLKOUT3_DIVIDE     => 7,
CLKOUT3_DUTY_CYCLE => 0.5,
CLKOUT3_PHASE      => 0.0,
CLKOUT4_DIVIDE     => 7,
CLKOUT4_DUTY_CYCLE => 0.5,
CLKOUT4_PHASE      => 0.0,
CLKOUT5_DIVIDE     => 7,
CLKOUT5_DUTY_CYCLE => 0.5,
CLKOUT5_PHASE      => 0.0
)
port map (
CLKFBOUT    => mmcmout_x1,
CLKOUT0     => mmcmout_xn,
CLKOUT1     => mmcmout_d2,
CLKOUT2     => open,
CLKOUT3     => open,
CLKOUT4     => open,
CLKOUT5     => open,
DO          => open,
DRDY        => open,
PWRDWN      => '0',
LOCKED      => mmcm_lckd,
CLKFBIN     => pixel_clk_int,
CLKIN1      => clkint,
CLKIN2      => '0',
CLKINSEL    => '1',
DADDR       => "0000000",
DCLK        => '0',
DEN         => '0',
DI          => X"0000",
DWE         => '0',
RST         => reset
);

loop4 : if PIXEL_CLOCK = "BUF_G" generate
   bufg_pll_x1 : BUFG
   port map (I => mmcmout_x1, O => pixel_clk_int) ;
   status(1 downto 0) <= "00" ;
end generate ;

loop4a : if PIXEL_CLOCK = "BUF_R" generate
   bufr_pll_x1 : BUFR
   generic map(BUFR_DIVIDE => "1", SIM_DEVICE => "7SERIES")
   port map (I => mmcmout_x1, CE => '1', O => pixel_clk_int, CLR => '0') ;
   status(1 downto 0) <= "01" ;
end generate ;

loop4b : if PIXEL_CLOCK = "BUF_H" generate
   bufh_pll_x1 : BUFH
   port map (I => mmcmout_x1, O => pixel_clk_int) ;
   status(1 downto 0) <= "10" ;
end generate ;

loop5 : if INTER_CLOCK = "BUF_G" generate
   bufg_pll_d4 : BUFG
   port map(I => mmcmout_d2, O => txclk_div) ;
   status(3 downto 2) <= "00" ;
end generate ;

loop5a : if INTER_CLOCK = "BUF_R" generate
   bufr_pll_d4 :  BUFR
   generic map(BUFR_DIVIDE => "1", SIM_DEVICE => "7SERIES")
   port map (I => mmcmout_d2, CE => '1', O => txclk_div, CLR => '0') ;
   status(3 downto 2) <= "01" ;
end generate ;

loop5b : if INTER_CLOCK = "BUF_H" generate
   bufh_pll_x1 : BUFH
   port map (I => mmcmout_d2, O => txclk_div) ;
   status(3 downto 2) <= "10" ;
end generate ;

loop10 : if TX_CLOCK = "BUF_G" generate
   bufg_pll_xn : BUFG
   port map(I => mmcmout_xn, O => txclk) ;
   status(5 downto 4) <= "00" ;
end generate ;

loop10a : if TX_CLOCK = "BUFIO" generate
   bufio_pll_xn : BUFIO
   port map (I => mmcmout_xn, O => txclk) ;
   status(5 downto 4) <= "11" ;
end generate ;

loop10b : if TX_CLOCK = "BUF_H" generate
   bufh_pll_xn : BUFH
   port map(I => mmcmout_xn, O => txclk) ;
   status(5 downto 4) <= "10" ;
end generate ;
end generate ;--loop2 : if USE_PLL = TRUE generate

end xilinx ;


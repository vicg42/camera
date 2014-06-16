-------------------------------------------------------------------------
-- Company     : Yansar
-- Engineer    : Golovachenko Victor
--
-- Create Date : 13.06.2014 15:08:42
-- Module Name : ccd_vita25K
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
use work.ccd_vita25K_pkg.all;
use work.prj_cfg.all;

entity ccd_vita25K is
port(
p_in_ccd   : in   TCCD_PortIN;
p_out_ccd  : out  TCCD_PortOUT;

p_out_video_vs  : out std_logic;
p_out_video_hs  : out std_logic;
p_out_video_den : out std_logic;
p_out_video_d   : out std_logic_vector((C_PCFG_CCD_DATA_LINE_COUNT
                                          * C_PCFG_CCD_BIT_PER_PIXEL) - 1 downto 0);
p_out_video_clk : out std_logic;

p_in_refclk : in   std_logic;
p_in_ccdclk : in   std_logic;
p_in_rst    : in   std_logic
);
end;

architecture behavior of ccd_vita25K is

component deser_lvds_ccd is
generic(
sys_w       : integer := 16; -- width of the data for the system
dev_w       : integer := 160 -- width of the data for the device
);
port
(
-- From the system into the device
DATA_IN_FROM_PINS_P : in    std_logic_vector(sys_w - 1 downto 0);
DATA_IN_FROM_PINS_N : in    std_logic_vector(sys_w - 1 downto 0);
DATA_IN_TO_DEVICE   : out   std_logic_vector(dev_w - 1 downto 0);

-- Input, Output delay control signals
IN_DELAY_RESET      : in    std_logic;                            -- Active high synchronous reset for input delay
IN_DELAY_DATA_CE    : in    std_logic_vector(sys_w - 1 downto 0); -- Enable signal for delay
IN_DELAY_DATA_INC   : in    std_logic_vector(sys_w - 1 downto 0); -- Delay increment (high), decrement (low) signal
IN_DELAY_TAP_IN     : in    std_logic_vector((5 * sys_w) -1 downto 0); -- Dynamically loadable delay tap value for input delay
IN_DELAY_TAP_OUT    : out   std_logic_vector((5 * sys_w) -1 downto 0); -- Delay tap value for monitoring input delay
DELAY_LOCKED        : out   std_logic; -- Locked signal from IDELAYCTRL
REF_CLOCK           : in    std_logic; -- Reference Clock for IDELAYCTRL. Has to come from BUFG.
BITSLIP             : in    std_logic; -- Bitslip module is enabled in NETWORKING mode
                                       -- User should tie it to '0' if not needed

-- Clock and reset signals
CLK_IN_P            : in    std_logic;   -- Differential fast clock from IOB
CLK_IN_N            : in    std_logic;
CLK_DIV_OUT         : out   std_logic;   -- Slow clock output
CLK_RESET           : in    std_logic;   -- Reset signal for Clock circuit
IO_RESET            : in    std_logic    -- Reset signal for IO circuit
);
end component;

signal i_delay_tap_in   : std_logic_vector((5 * C_PCFG_CCD_LVDS_COUNT) - 1 downto 0);
signal i_delay_tap_out  : std_logic_vector((5 * C_PCFG_CCD_LVDS_COUNT) - 1 downto 0);
signal i_delay_data_ce  : std_logic_vector(C_PCFG_CCD_LVDS_COUNT - 1 downto 0);
signal i_delay_data_inc : std_logic_vector(C_PCFG_CCD_LVDS_COUNT - 1 downto 0);
signal i_idelayctrl_rdy : std_logic;

signal i_bitslip        : std_logic;
signal i_deser_d_clk    : std_logic;
signal i_deser_d        : std_logic_vector((C_PCFG_CCD_LVDS_COUNT
                                              * C_PCFG_CCD_BIT_PER_PIXEL) - 1 downto 0);

signal i_video_d        : std_logic_vector((C_PCFG_CCD_DATA_LINE_COUNT
                                              * C_PCFG_CCD_BIT_PER_PIXEL) - 1 downto 0);

signal i_video_sync     : std_logic_vector((C_PCFG_CCD_SYNC_LINE_COUNT
                                              * C_PCFG_CCD_BIT_PER_PIXEL) - 1 downto 0);



--MAIN
begin


p_out_ccd.rst_n <= '1';
p_out_ccd.trig <= '1';

m_ccd_clkout : OBUFDS
generic map (IOSTANDARD => "LVDS_25")
port map (
O  => p_out_ccd.clk_p,
OB => p_out_ccd.clk_n,
I  => p_in_ccdclk
);


m_lvds_in : deser_lvds_ccd
generic map (
sys_w  => C_PCFG_CCD_LVDS_COUNT,
dev_w  => (C_PCFG_CCD_LVDS_COUNT * C_PCFG_CCD_BIT_PER_PIXEL)
)
port map (
-- From the system into the device
DATA_IN_FROM_PINS_P => p_in_ccd.data_p,
DATA_IN_FROM_PINS_N => p_in_ccd.data_n,
DATA_IN_TO_DEVICE   => i_deser_d,

-- Input, Output delay control signals
IN_DELAY_RESET      => p_in_rst,
IN_DELAY_DATA_CE    => i_delay_data_ce,
IN_DELAY_DATA_INC   => i_delay_data_inc,
IN_DELAY_TAP_IN     => i_delay_tap_in,
IN_DELAY_TAP_OUT    => i_delay_tap_out,
DELAY_LOCKED        => i_idelayctrl_rdy,
REF_CLOCK           => p_in_refclk,
BITSLIP             => i_bitslip,

-- Clock and reset signals
CLK_IN_P            => p_in_ccd.clk_p,
CLK_IN_N            => p_in_ccd.clk_n,
CLK_DIV_OUT         => i_deser_d_clk,
CLK_RESET           => p_in_rst,
IO_RESET            => p_in_rst
);

process(i_deser_d_clk)
begin
  if rising_edge(i_deser_d_clk) then
    i_video_d <= i_deser_d((C_PCFG_CCD_LVDS_COUNT * C_PCFG_CCD_BIT_PER_PIXEL) - 1
                              downto (C_PCFG_CCD_SYNC_LINE_COUNT * C_PCFG_CCD_BIT_PER_PIXEL));

    i_video_sync <= i_deser_d((C_PCFG_CCD_SYNC_LINE_COUNT
                                * C_PCFG_CCD_BIT_PER_PIXEL) - 1 downto 0);
  end if;
end process;


p_out_video_vs  <= '1' when i_video_sync = std_logic_vector(to_unsigned(16#11#, i_video_sync'length)) else '0';
p_out_video_hs  <= '1' when i_video_sync = std_logic_vector(to_unsigned(16#12#, i_video_sync'length))else '0';
p_out_video_den <= '1' when i_video_sync = std_logic_vector(to_unsigned(16#13#, i_video_sync'length))else '0';
p_out_video_d <= i_video_d;
p_out_video_clk <= '0';


--END MAIN
end architecture;

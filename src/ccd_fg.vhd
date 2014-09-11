-------------------------------------------------------------------------
-- Company     : Yansar
-- Engineer    : Golovachenko Victor
--
-- Create Date : 13.06.2014 15:08:42
-- Module Name : ccd_fg (frame grabber)
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
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

library work;
use work.ccd_vita25K_pkg.all;
use work.prj_cfg.all;

entity ccd_fg is
generic(
G_LVDS_CH_COUNT : integer := 16;
G_BIT_COUNT     : integer := 10
);
port(
p_in_ccd        : in    TCCD_pinin;
p_out_ccd       : out   TCCD_pinout;

p_out_video_vs  : out   std_logic;
p_out_video_hs  : out   std_logic;
p_out_video_den : out   std_logic;
p_out_video_d   : out   std_logic_vector((G_LVDS_CH_COUNT * G_BIT_COUNT) - 1 downto 0);
p_out_video_clk : out   std_logic;

p_out_detect_tr : out   std_logic;

p_out_tst       : out   std_logic_vector(31 downto 0);
p_in_tst        : in    std_logic_vector(31 downto 0);

p_in_ccdinit    : in    std_logic;
p_in_ccdclk2    : in    std_logic;
p_in_ccdclk     : in    std_logic;
p_in_refclk     : in    std_logic;
p_in_rst        : in    std_logic;
p_in_rst2       : in    std_logic
);
end ccd_fg;

architecture xilinx of ccd_fg is

component ccd_deser is
generic(
G_BIT_COUNT     : integer := 10
);
port(
p_in_data_p     : in    std_logic;
p_in_data_n     : in    std_logic;

p_out_rxd       : out   std_logic_vector(G_BIT_COUNT - 1 downto 0);
p_out_align_done: out   std_logic;

p_in_clken      : in    std_logic;
p_in_clkdiv     : in    std_logic;
p_in_clk        : in    std_logic;
p_in_clkinv     : in    std_logic;

p_out_tst       : out   std_logic_vector(31 downto 0);
p_in_tst        : in    std_logic_vector(31 downto 0);

p_in_deser_rst  : in    std_logic
);
end component ccd_deser;

component ccd_deser_clock_gen is
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
p_in_tst  : in  std_logic_vector(31 downto 0);
p_out_tst : out std_logic_vector(31 downto 0)
);
end component;

signal i_clk_en                  : std_logic;
signal clk_in_int                : std_logic;
signal clk_in_int_inv            : std_logic;
signal clk_div                   : std_logic;

signal i_serial_din              : std_logic_vector(G_LVDS_CH_COUNT - 1 downto 0);
signal i_idelaye2_dout           : std_logic_vector(G_LVDS_CH_COUNT - 1 downto 0);
signal in_delay_ce               : std_logic_vector(G_LVDS_CH_COUNT - 1 downto 0);
signal in_delay_inc_dec          : std_logic_vector(G_LVDS_CH_COUNT - 1 downto 0);
type loadarr is array (0 to G_LVDS_CH_COUNT - 1) of std_logic_vector(4 downto 0);
signal in_delay_tap_in_int       : loadarr := (( others => (others => '0')));
signal in_delay_tap_out_int      : loadarr := (( others => (others => '0')));
signal i_in_delay_reset          : std_logic;
type TDeserData is array (0 to G_LVDS_CH_COUNT - 1) of std_logic_vector(13 downto 0);
signal i_deser_d                 : TDeserData := (( others => (others => '0')));
signal icascade1                 : std_logic_vector(G_LVDS_CH_COUNT - 1 downto 0);
signal icascade2                 : std_logic_vector(G_LVDS_CH_COUNT - 1 downto 0);
signal i_io_reset                : std_logic;
signal i_mmcm_lckd               : std_logic;

--attribute IODELAY_GROUP : string;
--attribute IODELAY_GROUP of delayctrl : label is "deser_lvds_ccd_group";

signal i_deser_dout     : std_logic_vector((G_LVDS_CH_COUNT * G_BIT_COUNT) - 1 downto 0);

signal i_video_d        : std_logic_vector((G_LVDS_CH_COUNT * G_BIT_COUNT) - 1 downto 0);
signal i_video_sync     : std_logic_vector(G_BIT_COUNT - 1 downto 0);

signal i_pattern_det_en : std_logic;
type TCHcount_bus4bit is array (0 to G_LVDS_CH_COUNT - 1) of std_logic_vector(3 downto 0);
type TCHcount_bus3bit is array (0 to G_LVDS_CH_COUNT - 1) of std_logic_vector(2 downto 0);
signal i_bitslip_en     : std_logic_vector(G_LVDS_CH_COUNT  - 1 downto 0);
signal i_align_done    : std_logic_vector(G_LVDS_CH_COUNT  - 1 downto 0);
signal i_align_done_cnt: TCHcount_bus4bit;--std_logic_vector(3 downto 0);
signal i_bitslip        : std_logic_vector(G_LVDS_CH_COUNT  - 1 downto 0);
signal i_bitcnt         : TCHcount_bus3bit;--std_logic_vector(2 downto 0);

signal i_video_vs       : std_logic;
signal i_video_hs       : std_logic;
signal i_video_den      : std_logic;

signal sr_sync_rst      : std_logic_vector(6 downto 0);
signal i_idelayctrl_rdy : std_logic;
signal i_deser_rdy      : std_logic;

signal tst_mmcm_lckd,tst_ibufds_dout : std_logic;
signal tst_gen_out      : std_logic_vector(31 downto 0);
signal tst_clk_div      : std_logic_vector(3 downto 0);

signal sr_clk_en        : std_logic_vector(0 to 7);


begin

i_in_delay_reset <= '0';
in_delay_ce <= (others => '0');
in_delay_inc_dec <= (others => '0');
gen : for i in 0 to G_LVDS_CH_COUNT - 1 generate
begin
in_delay_tap_in_int(i) <= (others => '0');
end generate;

-- IDELAYCTRL is needed for calibration
delayctrl : IDELAYCTRL
port map (
RDY    => i_idelayctrl_rdy,
REFCLK => p_in_refclk,
RST    => p_in_rst2
);


m_clk_fpga2ccd : OBUFDS
port map (
O  => p_out_ccd.clk_p,
OB => p_out_ccd.clk_n,
I  => p_in_ccdclk
);

m_clk_gen : ccd_deser_clock_gen
generic map(
CLKIN_PERIOD    => 3.225  , -- clock period (ns) of input clock on clkin_p
MMCM_MODE       => 1      ,
MMCM_MODE_REAL  => 1.000  ,
TX_CLOCK        => "BUF_G", -- Parameter to set transmission clock buffer type, BUFIO, BUF_H, BUF_G
INTER_CLOCK     => "BUF_G", -- Parameter to set intermediate clock buffer type, BUFR, BUF_H, BUF_G
PIXEL_CLOCK     => "BUF_G", -- Parameter to set final clock buffer type, BUF_R, BUF_H, BUF_G
USE_PLL         => FALSE  ,
DIFF_TERM       => TRUE     -- differential termination on p_in_lvds_clk_p/p_in_lvds_clk_n
)
port map(
reset     => p_in_rst,
clkin_p   => p_in_ccd.clk_p,
clkin_n   => p_in_ccd.clk_n,
txclk     => open,
pixel_clk => clk_in_int,
txclk_div => clk_div,
mmcm_lckd => i_mmcm_lckd,
status    => open,
p_in_tst  => p_in_tst,
p_out_tst => tst_gen_out
);

clk_in_int_inv <= not (clk_in_int);

i_deser_rdy <= i_mmcm_lckd and i_idelayctrl_rdy;

i_clk_en <= sr_clk_en(sr_clk_en'length - 1);
i_io_reset <= not i_mmcm_lckd;

process(clk_div, i_io_reset)
begin
  if (i_io_reset = '1') then
    sr_clk_en <= (others => '0');
  elsif rising_edge(clk_div) then
    sr_clk_en <= '1' & sr_clk_en(0 to sr_clk_en'length - 2);
  end if;
end process;


--###########################################
--Recieve data from lvds channel
--###########################################
gen_lvds_ch: for lvds_ch in 0 to G_LVDS_CH_COUNT - 1 generate
begin

m_deser : ccd_deser
generic map(
G_BIT_COUNT => G_BIT_COUNT
)
port map(
p_in_data_p     => p_in_ccd.data_p(lvds_ch),
p_in_data_n     => p_in_ccd.data_n(lvds_ch),

p_out_rxd       => i_deser_d(lvds_ch)(G_BIT_COUNT - 1 downto 0),
p_out_align_done => i_align_done(lvds_ch),

p_in_clken      => i_clk_en,
p_in_clkdiv     => clk_div,
p_in_clk        => clk_in_int,
p_in_clkinv     => clk_in_int_inv,

p_out_tst       => open,
p_in_tst        => p_in_tst,

p_in_deser_rst  => i_io_reset
);


gen_dout : for bitnum in 0 to G_BIT_COUNT - 1 generate
begin

--i_deser_dout((lvds_ch * G_BIT_COUNT) + bitnum) <= i_deser_d(lvds_ch)(G_BIT_COUNT - bitnum - 1);
i_deser_dout((lvds_ch * G_BIT_COUNT) + bitnum) <= i_deser_d(lvds_ch)(bitnum);

end generate gen_dout;

end generate gen_lvds_ch;




process(clk_div)
begin
  if rising_edge(clk_div) then
    i_video_d <= i_deser_dout((G_LVDS_CH_COUNT * G_BIT_COUNT) - 1 downto 0);
  end if;
end process;

i_video_sync <= i_video_d(G_BIT_COUNT - 1 downto 0);


process(clk_div)
begin
if rising_edge(clk_div) then
  if i_deser_rdy = '0' then
    i_video_vs <= '0';
    i_video_hs <= '0';
    i_video_den <= '0';

  else

        if (i_video_sync = CONV_STD_LOGIC_VECTOR(C_CCD_CHSYNC_FS, i_video_sync'length)) then
          i_video_vs <= '1';
          i_video_hs <= '0';
          i_video_den <= '0';

        elsif (i_video_sync = CONV_STD_LOGIC_VECTOR(C_CCD_CHSYNC_FE, i_video_sync'length)) then
          i_video_vs <= '0';
          i_video_hs <= '0';
          i_video_den <= '0';

        elsif (i_video_sync = CONV_STD_LOGIC_VECTOR(C_CCD_CHSYNC_LS, i_video_sync'length)) then
          i_video_vs <= '0';
          i_video_hs <= '1';
          i_video_den <= '0';

        elsif (i_video_sync = CONV_STD_LOGIC_VECTOR(C_CCD_CHSYNC_LE, i_video_sync'length)) then
          i_video_vs <= '0';
          i_video_hs <= '0';
          i_video_den <= '0';

        elsif (i_video_sync = CONV_STD_LOGIC_VECTOR(C_CCD_CHSYNC_IMAGE, i_video_sync'length)) then
          i_video_vs <= '0';
          i_video_den <= '1';

        else
          i_video_vs <= '0';
          i_video_hs <= '0';
          i_video_den <= '0';

        end if;

  end if;
end if;
end process;


p_out_video_vs  <= i_video_vs;
p_out_video_hs  <= i_video_hs;
p_out_video_den <= i_video_den;
p_out_video_d <= i_video_d;
p_out_video_clk <= clk_div;

p_out_detect_tr <= OR_reduce(i_align_done);



p_out_tst(3 downto 0) <= tst_gen_out(3 downto 0);
p_out_tst(4) <= OR_reduce(tst_clk_div);
p_out_tst(5) <= '0';

process(clk_div)
begin
  if rising_edge(clk_div) then
    tst_clk_div <= tst_clk_div + 1;
  end if;
end process;

--process(p_in_ccdclk)
--begin
--if rising_edge(p_in_ccdclk) then
--  tst_mmcm_lckd <= i_mmcm_lckd;
--  tst_ibufds_dout <= i_serial_din(0);
--
--end if;
--end process;
--
--process(clk_div)
--begin
--  if rising_edge(clk_div) then
----    if i_bitslip = '1' then
--    i_deser_dout <= tst_ibufds_dout & i_deser_dout((G_LVDS_CH_COUNT * G_BIT_COUNT) - 1 downto 1);
----    end if;
--  end if;
--end process;
--
--p_out_video_vs  <= '0';
--p_out_video_hs  <= '0';
--p_out_video_den <= '0';
--p_out_video_d <= i_deser_dout;
--p_out_video_clk <= '0';
--
--p_out_detect_tr <= '0';



end xilinx;




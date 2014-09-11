-------------------------------------------------------------------------
-- Company     : Yansar
-- Engineer    : Golovachenko Victor
--
-- Create Date : 11.09.2014 10:34:22
-- Module Name : ccd_fg (frame grabber)
--
-- ����������/�������� :
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
use work.ccd_pkg.all;

entity ccd_fg is
generic(
G_LVDS_CH_COUNT : integer := 16;
G_BIT_COUNT     : integer := 10
);
port(
p_in_ccd        : in    TCCD_pinin;
p_out_ccd       : out   TCCD_pinout;

p_out_vfr_data  : out   std_logic_vector((G_LVDS_CH_COUNT * G_BIT_COUNT) - 1 downto 0);
p_out_vfr_den   : out   std_logic;
p_out_vfr_vs    : out   std_logic;
p_out_vfr_hs    : out   std_logic;
p_out_vfr_clk   : out   std_logic;

p_out_status    : out   std_logic_vector(C_CCD_FG_STATUS_LAST_BIT downto 0);

p_out_tst       : out   std_logic_vector(31 downto 0);
p_in_tst        : in    std_logic_vector(31 downto 0);

p_in_ccdinit    : in    std_logic;
p_in_ccdclk     : in    std_logic;
p_in_refclk     : in    std_logic;
p_in_rst        : in    std_logic
);
end ccd_fg;

architecture xilinx of ccd_fg is

component ccd_deser is
generic(
G_BIT_COUNT : integer := 10
);
port(
p_in_data_p    : in    std_logic;
p_in_data_n    : in    std_logic;

p_out_data     : out   std_logic_vector(G_BIT_COUNT - 1 downto 0);
p_out_align_ok : out   std_logic;

p_out_tst      : out   std_logic_vector(31 downto 0);
p_in_tst       : in    std_logic_vector(31 downto 0);

p_in_clken     : in    std_logic;
p_in_clkdiv    : in    std_logic;
p_in_clk       : in    std_logic;
p_in_clkinv    : in    std_logic;
p_in_rst       : in    std_logic
);
end component ccd_deser;

component ccd_deser_clk is
generic (
CLKIN_PERIOD    : real := 6.000 ;
MMCM_MODE       : integer := 1 ;
MMCM_MODE_REAL  : real := 1.000 ;
TX_CLOCK        : string := "BUFIO" ;
INTER_CLOCK     : string := "BUF_R" ;
PIXEL_CLOCK     : string := "BUF_G" ;
USE_PLL         : boolean := FALSE ;
DIFF_TERM       : boolean := TRUE
);
port  (
reset     :  in std_logic ;
clkin_p   :  in std_logic ;
clkin_n   :  in std_logic ;
txclk     : out std_logic ;
pixel_clk : out std_logic ;
txclk_div : out std_logic ;
mmcm_lckd : out std_logic ;
status    : out std_logic_vector(6 downto 0);
p_in_tst  : in  std_logic_vector(31 downto 0);
p_out_tst : out std_logic_vector(31 downto 0)
);
end component;

signal i_mmcm_lckd      : std_logic;
signal i_mmcm_rst       : std_logic;

signal i_idelayctrl_rdy : std_logic;
signal sr_sync_rst      : std_logic_vector(6 downto 0);

--signal i_clk_en         : std_logic;
signal i_clk            : std_logic;
signal i_clk_inv        : std_logic;
signal i_clk_div        : std_logic;

signal i_deser_rst      : std_logic;
type TDeserData is array (0 to G_LVDS_CH_COUNT - 1) of std_logic_vector(G_BIT_COUNT - 1 downto 0);
signal i_deser_d        : TDeserData := (( others => (others => '0')));
signal i_align_ok       : std_logic_vector(G_LVDS_CH_COUNT - 1 downto 0);

signal i_rxd            : std_logic_vector((G_LVDS_CH_COUNT * G_BIT_COUNT) - 1 downto 0);
signal i_rxdout         : std_logic_vector((G_LVDS_CH_COUNT * G_BIT_COUNT) - 1 downto 0);

signal i_sync_d         : unsigned(G_BIT_COUNT - 1 downto 0);

signal i_vfr_vs         : std_logic;
signal i_vfr_hs         : std_logic;
signal i_vfr_den        : std_logic;
signal i_vfr_bl         : std_logic;


begin

-- IDELAYCTRL is needed for calibration
delayctrl : IDELAYCTRL
port map (
RDY    => i_idelayctrl_rdy,
REFCLK => p_in_refclk,
RST    => p_in_rst
);


m_clk_fpga2ccd : OBUFDS
port map (
O  => p_out_ccd.clk_p,
OB => p_out_ccd.clk_n,
I  => p_in_ccdclk
);

m_clk_gen : ccd_deser_clk
generic map(
CLKIN_PERIOD    => 3.225  , -- clock period (ns) of input clock on clkin_p
MMCM_MODE       => 1      ,
MMCM_MODE_REAL  => 1.000  ,
TX_CLOCK        => "BUF_G",
INTER_CLOCK     => "BUF_G",
PIXEL_CLOCK     => "BUF_G",
USE_PLL         => FALSE  ,
DIFF_TERM       => TRUE
)
port map(
clkin_p   => p_in_ccd.clk_p,
clkin_n   => p_in_ccd.clk_n,
txclk     => open,
pixel_clk => i_clk,
txclk_div => i_clk_div,
mmcm_lckd => i_mmcm_lckd,
status    => open,

p_in_tst  => p_in_tst,
p_out_tst => open,

reset     => i_mmcm_rst
);

i_mmcm_rst <= not p_in_ccdinit;
i_clk_inv <= not (i_clk);

i_deser_rst <= not (i_mmcm_lckd and i_idelayctrl_rdy);


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
p_in_data_p    => p_in_ccd.data_p(lvds_ch),
p_in_data_n    => p_in_ccd.data_n(lvds_ch),

p_out_data     => i_deser_d(lvds_ch)(G_BIT_COUNT - 1 downto 0),
p_out_align_ok => i_align_ok(lvds_ch),

p_out_tst      => open,
p_in_tst       => (others => '0'),

p_in_clken     => '1', --i_clk_en
p_in_clkdiv    => i_clk_div,
p_in_clk       => i_clk,
p_in_clkinv    => i_clk_inv,
p_in_rst       => i_deser_rst
);


gen_dout : for bitnum in 0 to G_BIT_COUNT - 1 generate
begin
--i_rxd((lvds_ch * G_BIT_COUNT) + bitnum) <= i_deser_d(lvds_ch)(G_BIT_COUNT - bitnum - 1);
i_rxd((lvds_ch * G_BIT_COUNT) + bitnum) <= i_deser_d(lvds_ch)(bitnum);
end generate gen_dout;

end generate gen_lvds_ch;



--###########################################
--SYNC detect
--###########################################
process(i_clk_div)
begin
  if rising_edge(i_clk_div) then
    i_rxdout <= i_rxd((G_LVDS_CH_COUNT * G_BIT_COUNT) - 1 downto 0);
  end if;
end process;

i_sync_d <= UNSIGNED(i_rxdout(G_BIT_COUNT - 1 downto 0));


process(i_clk_div)
begin
if rising_edge(i_clk_div) then
  if i_deser_rst = '1' then
    i_vfr_vs <= '0';
    i_vfr_hs <= '0';
    i_vfr_den <= '0';
    i_vfr_bl <= '0';

  else

        if (i_sync_d = TO_UNSIGNED(C_CCD_CHSYNC_FS, i_sync_d'length)) then
          i_vfr_vs <= '1';
          i_vfr_hs <= '0';
          i_vfr_den <= '0';
          i_vfr_bl <= '0';

        elsif (i_sync_d = TO_UNSIGNED(C_CCD_CHSYNC_FE, i_sync_d'length)) then
          i_vfr_vs <= '0';
          i_vfr_hs <= '0';
          i_vfr_den <= '0';
          i_vfr_bl <= '0';

        elsif (i_sync_d = TO_UNSIGNED(C_CCD_CHSYNC_LS, i_sync_d'length)) then
          i_vfr_vs <= '0';
          i_vfr_hs <= '1';
          i_vfr_den <= '0';
          i_vfr_bl <= '0';

        elsif (i_sync_d = TO_UNSIGNED(C_CCD_CHSYNC_LE, i_sync_d'length)) then
          i_vfr_vs <= '0';
          i_vfr_hs <= '0';
          i_vfr_den <= '0';
          i_vfr_bl <= '0';

        elsif (i_sync_d = TO_UNSIGNED(C_CCD_CHSYNC_IMAGE, i_sync_d'length)) then
          i_vfr_vs <= '0';
          i_vfr_den <= '1';
          i_vfr_bl <= '0';

        elsif (i_sync_d = TO_UNSIGNED(C_CCD_CHSYNC_BLACKPIX, i_sync_d'length)) then
          i_vfr_bl <= '1';

        else
          i_vfr_vs <= '0';
          i_vfr_hs <= '0';
          i_vfr_den <= '0';
          i_vfr_bl <= '0';

        end if;

  end if;
end if;
end process;


p_out_vfr_data <= i_rxdout  ;
p_out_vfr_den  <= i_vfr_den;
p_out_vfr_vs   <= i_vfr_vs ;
p_out_vfr_hs   <= i_vfr_hs ;
p_out_vfr_clk  <= i_clk_div;

p_out_status(C_CCD_FG_STATUS_ALIGN_OK_BIT) <= OR_reduce(i_align_ok);

p_out_tst(0) <= i_vfr_bl;
p_out_tst(31 downto 1) <= (others => '0');


end xilinx;




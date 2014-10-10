library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

entity test_lvds_rcv is
generic(
G_BIT_COUNT : integer := 10
);
port(
p_in_align_start : in   std_logic;
p_out_data       : out  std_logic_vector(G_BIT_COUNT - 1 downto 0);
p_out_align      : out  std_logic;

p_in_lvds_data_p : in std_logic_vector(0 downto 0);
p_in_lvds_data_n : in std_logic_vector(0 downto 0);
p_in_lvds_clk_p  : in std_logic;
p_in_lvds_clk_n  : in std_logic;

p_out_tst        : out std_logic_vector(31 downto 0);
p_in_sys_clk     : in  std_logic;
p_in_sys_rst     : in  std_logic
);
end test_lvds_rcv;

architecture behavioral of test_lvds_rcv is

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

signal i_idelayctrl_rdy : std_logic_vector(0 downto 0);

--signal i_clk_en         : std_logic;
signal i_clk            : std_logic;
signal i_clk_inv        : std_logic;
signal i_clk_div        : std_logic;

signal i_deser_rst      : std_logic;
signal i_deser_d        : std_logic_vector(G_BIT_COUNT - 1 downto 0);
signal i_deser_dout     : std_logic_vector(G_BIT_COUNT - 1 downto 0);
signal i_align_ok       : std_logic;

signal tst_ccd_deser_in : std_logic_vector(31 downto 0);


begin

---- IDELAYCTRL is needed for calibration
--gen_delayctrl: for i in 0 to 0 generate begin
--m_delayctrl : IDELAYCTRL
--port map (
--RDY    => i_idelayctrl_rdy(i),
--REFCLK => p_in_refclk,
--RST    => p_in_rst
--);
--end generate gen_delayctrl;


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
clkin_p   => p_in_lvds_clk_p,
clkin_n   => p_in_lvds_clk_n,
txclk     => open,
pixel_clk => i_clk,
txclk_div => i_clk_div,
mmcm_lckd => i_mmcm_lckd,
status    => open,

p_in_tst  => (others => '0'),
p_out_tst => open,

reset     => i_mmcm_rst
);

i_mmcm_rst <= p_in_sys_rst;
i_clk_inv <= not (i_clk);

i_deser_rst <= not (i_mmcm_lckd);-- and AND_Reduce(i_idelayctrl_rdy));


--###########################################
--Recieve data from lvds channel
--###########################################
--gen_lvds_ch: for lvds_ch in 0 to G_LVDS_CH_COUNT - 1 generate
--begin

m_deser : ccd_deser
generic map(
G_BIT_COUNT => G_BIT_COUNT
)
port map(
p_in_data_p    => p_in_lvds_data_p(0),
p_in_data_n    => p_in_lvds_data_n(0),

p_out_data     => i_deser_d(G_BIT_COUNT - 1 downto 0),
p_out_align_ok => i_align_ok,

p_out_tst      => p_out_tst,
p_in_tst       => tst_ccd_deser_in,

p_in_clken     => '1', --i_clk_en
p_in_clkdiv    => i_clk_div,
p_in_clk       => i_clk,
p_in_clkinv    => i_clk_inv,
p_in_rst       => i_deser_rst
);


gen_dout : for bitnum in 0 to G_BIT_COUNT - 1 generate
begin
--i_deser_dout(bitnum) <= i_deser_d(G_BIT_COUNT - bitnum - 1);
i_deser_dout(bitnum) <= i_deser_d(bitnum);
end generate gen_dout;

--end generate gen_lvds_ch;

p_out_align <= i_align_ok;



tst_ccd_deser_in(0) <= p_in_align_start;
tst_ccd_deser_in(31 downto 1) <= (others => '0');

end behavioral;


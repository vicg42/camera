library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

entity test_lvds_snd is
generic(
G_BIT_COUNT : integer := 10
);
port(
p_in_data         : in  std_logic_vector(G_BIT_COUNT - 1 downto 0);
p_out_dclk        : out  std_logic;
p_out_dclken      : out  std_logic;

p_out_lvds_data_p : out std_logic_vector(0 downto 0);
p_out_lvds_data_n : out std_logic_vector(0 downto 0);
p_out_lvds_clk_p  : out std_logic;
p_out_lvds_clk_n  : out std_logic;

p_in_sys_clk      : in  std_logic;
p_in_sys_rst      : in  std_logic
);
end test_lvds_snd;

architecture behavioral of test_lvds_snd is

component ccd_deser_clk is
generic (
CLKIN_DIFF      : boolean := TRUE ;
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
end component ccd_deser_clk ;

signal i_clk_div         : std_logic;
signal i_mmcm_lckd       : std_logic;

signal i_oserdes_clken   : std_logic;
signal i_oserdes_din     : unsigned(13 downto 0);
signal i_oserdes_dout    : std_logic;
signal i_ocascade        : unsigned(1 downto 0);

signal sr_oserdes_clken  : std_logic := '0';
signal i_rst             : std_logic := '0';

begin

p_out_dclk <= i_clk_div;
p_out_dclken <= i_oserdes_clken;

m_clk : ccd_deser_clk
generic map(
CLKIN_DIFF      => FALSE  ,
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
reset     => p_in_sys_rst,
clkin_p   => p_in_sys_clk,
clkin_n   => '0',
txclk     => open,
pixel_clk => open,
txclk_div => i_clk_div,
mmcm_lckd => i_mmcm_lckd,
status    => open,
p_in_tst  => (others => '0'),
p_out_tst => open
);

m_clk_fpga2ccd : OBUFDS
generic map (
IOSTANDARD => "DEFAULT", -- Specify the output I/O standard
SLEW => "SLOW")
port map (
O          => p_out_lvds_clk_p,
OB         => p_out_lvds_clk_n,
I          => p_in_sys_clk
);

i_oserdes_clken <= i_mmcm_lckd;

--gen_oserdes_din : for i in 0 to G_BIT_COUNT - 1 generate
--begin
--i_oserdes_din(13 - i) <= p_in_data(i);
--end generate gen_oserdes_din;
--
--gen_oserdes_din2 : for i in G_BIT_COUNT to 13 generate
--begin
--i_oserdes_din(13 - i) <= '0';
--end generate gen_oserdes_din2;

i_oserdes_din(13) <= p_in_data(9);
i_oserdes_din(12) <= p_in_data(8);
i_oserdes_din(11) <= p_in_data(7);
i_oserdes_din(10) <= p_in_data(6);
i_oserdes_din(9) <= p_in_data(5);
i_oserdes_din(8) <= p_in_data(4);
i_oserdes_din(7) <= p_in_data(3);
i_oserdes_din(6) <= p_in_data(2);
i_oserdes_din(5) <= p_in_data(1);
i_oserdes_din(4) <= p_in_data(0);
i_oserdes_din(3) <= '0';
i_oserdes_din(2) <= '0';
i_oserdes_din(1) <= '0';
i_oserdes_din(0) <= '0';


m_oserdese2_master : OSERDESE2
generic map (
DATA_RATE_OQ   => "DDR",       -- DDR, SDR
DATA_RATE_TQ   => "SDR",       -- DDR, BUF, SDR
DATA_WIDTH     => G_BIT_COUNT, -- Parallel data width (2-8,10,14)
INIT_OQ        => '0',         -- Initial value of OQ output (1'b0,1'b1)
INIT_TQ        => '0',         -- Initial value of TQ output (1'b0,1'b1)
SERDES_MODE    => "MASTER",    -- MASTER, SLAVE
SRVAL_OQ       => '0'     ,    -- OQ output value when SR is used (1'b0,1'b1)
SRVAL_TQ       => '0'     ,    -- TQ output value when SR is used (1'b0,1'b1)
TBYTE_CTL      => "FALSE" ,    -- Enable tristate byte operation (FALSE, TRUE)
TBYTE_SRC      => "FALSE" ,    -- Tristate byte source (FALSE, TRUE)
TRISTATE_WIDTH => 1            -- 3-state converter width (1,4)
)
port map (
D1         => i_oserdes_din(13),
D2         => i_oserdes_din(12),
D3         => i_oserdes_din(11),
D4         => i_oserdes_din(10),
D5         => i_oserdes_din(9) ,
D6         => i_oserdes_din(8) ,
D7         => i_oserdes_din(7) ,
D8         => i_oserdes_din(6) ,
T1         => '0',
T2         => '0',
T3         => '0',
T4         => '0',
SHIFTIN1   => i_ocascade(0),
SHIFTIN2   => i_ocascade(1),
SHIFTOUT1  => open,
SHIFTOUT2  => open,
OCE        => i_oserdes_clken,
CLK        => p_in_sys_clk,
CLKDIV     => i_clk_div,
OQ         => i_oserdes_dout,
TQ         => open,
OFB        => open,
TBYTEIN    => '0',
TBYTEOUT   => open,
TFB        => open,
TCE        => '0',
RST        => i_rst --p_in_sys_rst
);

m_oserdese2_slave : OSERDESE2
generic map (
DATA_RATE_OQ   => "DDR",       -- DDR, SDR
DATA_RATE_TQ   => "SDR",       -- DDR, BUF, SDR
DATA_WIDTH     => G_BIT_COUNT, -- Parallel data width (2-8,10,14)
INIT_OQ        => '0',         -- Initial value of OQ output (1'b0,1'b1)
INIT_TQ        => '0',         -- Initial value of TQ output (1'b0,1'b1)
SERDES_MODE    => "SLAVE" ,    -- MASTER, SLAVE
SRVAL_OQ       => '0'     ,    -- OQ output value when SR is used (1'b0,1'b1)
SRVAL_TQ       => '0'     ,    -- TQ output value when SR is used (1'b0,1'b1)
TBYTE_CTL      => "FALSE" ,    -- Enable tristate byte operation (FALSE, TRUE)
TBYTE_SRC      => "FALSE" ,    -- Tristate byte source (FALSE, TRUE)
TRISTATE_WIDTH => 1            -- 3-state converter width (1,4)
)
port map (
D1         => '0',
D2         => '0',
D3         => i_oserdes_din(5),
D4         => i_oserdes_din(4),
D5         => i_oserdes_din(3),
D6         => i_oserdes_din(2),
D7         => i_oserdes_din(1),
D8         => i_oserdes_din(0),
T1         => '0',
T2         => '0',
T3         => '0',
T4         => '0',
SHIFTOUT1  => i_ocascade(0),
SHIFTOUT2  => i_ocascade(1),
SHIFTIN1   => '0',
SHIFTIN2   => '0',
OCE        => i_oserdes_clken,
CLK        => p_in_sys_clk,
CLKDIV     => i_clk_div,
OQ         => open,
TQ         => open,
OFB        => open,
TFB        => open,
TBYTEIN    => '0',
TBYTEOUT   => open,
TCE        => '0',
RST        => i_rst --p_in_sys_rst
);


m_lvds_bufout : OBUFDS
--generic map (
--IOSTANDARD => "LVDS_25")
port map (
O          => p_out_lvds_data_p(0),
OB         => p_out_lvds_data_n(0),
I          => i_oserdes_dout
);


process(i_clk_div)
begin
  sr_oserdes_clken <= i_oserdes_clken;
  i_rst <= i_oserdes_clken and not sr_oserdes_clken;
end process;

end behavioral;


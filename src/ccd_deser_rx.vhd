library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

library work;
use work.ccd_vita25K_pkg.all;
use work.prj_cfg.all;

entity ccd_deser_rx is
generic(
G_BIT_COUNT     : integer := 10
);
port(
p_in_data_p     : in    std_logic;
p_in_data_n     : in    std_logic;

p_out_rxd       : out   std_logic_vector(G_BIT_COUNT - 1 downto 0);
p_out_aligen_done: out   std_logic;

p_in_clken      : in    std_logic;
p_in_clkdiv     : in    std_logic;
p_in_clk        : in    std_logic;
p_in_clkinv     : in    std_logic;

p_out_tst       : out   std_logic_vector(31 downto 0);
p_in_tst        : in    std_logic_vector(31 downto 0);

p_in_deser_rst  : in    std_logic
);
end ccd_deser_rx;

architecture xilinx of ccd_deser_rx is

type TFsm_aligen is (
S_IDLE          ,
S_BITSLIP_ANLZ  ,
S_BITSLIP_WAIT0 ,
S_BITSLIP_WAIT1 ,
S_BITSLIP_WAIT2 ,
S_ALIGEN_DONE   ,
S_BITSLIP_ANLZ2
);

signal i_fsm_aligen_cs       : TFsm_aligen;

signal i_serial_din          : std_logic;
signal i_idelaye2_dout       : std_logic;
signal in_delay_ce           : std_logic;
signal in_delay_inc_dec      : std_logic;
signal in_delay_tap_in_int   : std_logic_vector(4 downto 0);
signal in_delay_tap_out_int  : std_logic_vector(4 downto 0);
signal i_in_delay_reset      : std_logic;
signal i_deser_d             : unsigned(13 downto 0);
signal icascade1             : std_logic;
signal icascade2             : std_logic;

signal i_aligen_done         : std_logic;
signal i_bitslip             : std_logic;
signal i_cntok               : unsigned(1 downto 0);




begin


p_out_tst <= (others => '0');


--i_in_delay_reset <= '0';
--in_delay_ce <= '0';
--in_delay_inc_dec <= (others => '0');
--in_delay_tap_in_int <= (others => '0');


m_ibufds : IBUFDS
--generic map (
--DIFF_TERM  => TRUE -- Differential termination
--)
port map (
I   => p_in_data_p,
IB  => p_in_data_n,
O   => i_serial_din
);


m_idelaye2 : IDELAYE2
generic map (
CINVCTRL_SEL          => "FALSE", -- Dynamic clock inversion
DELAY_SRC             => "IDATAIN",
                      -- Specify which input port to be used
                      -- "I"=IDATAIN, "O"=ODATAIN, "DATAIN"=DATAIN, "IO"=Bi-directional
HIGH_PERFORMANCE_MODE => "TRUE",
                      -- TRUE specifies lower jitter
                      -- at expense of more power
IDELAY_TYPE           => "VARIABLE",
                      -- "DEFAULT", "FIXED" or "VARIABLE", or VAR_LOADABLE
IDELAY_VALUE          => 0,
                      -- 0 to 63 tap values
PIPE_SEL              => "FALSE",
REFCLK_FREQUENCY      => 200.0,
                      -- Frequency used for IDELAYCTRL
                      -- 175.0 to 225.0
SIGNAL_PATTERN        => "DATA"
                      -- Input signal type, "CLOCK" or "DATA"
)
port map (
DATAOUT           => i_idelaye2_dout,
DATAIN            => '0',
C                 => p_in_clkdiv,
CE                => '0',--in_delay_ce,
INC               => '0',--in_delay_inc_dec,
IDATAIN           => i_serial_din,
LD                => '0',--i_in_delay_reset,
REGRST            => p_in_deser_rst,
LDPIPEEN          => '0',
CNTVALUEIN        => (others => '0'), --in_delay_tap_in_int,
CNTVALUEOUT       => open, --in_delay_tap_out_int,
CINVCTRL          => '0'
);

m_iserdese2_master : ISERDESE2
generic map (
DATA_RATE         => "DDR",
DATA_WIDTH        => 10,
INIT_Q1           => '0',
INIT_Q2           => '0',
INIT_Q3           => '0',
INIT_Q4           => '0',
INTERFACE_TYPE    => "NETWORKING",
NUM_CE            => 2,
SERDES_MODE       => "MASTER",
--
DYN_CLKDIV_INV_EN => "FALSE",
DYN_CLK_INV_EN    => "FALSE",
IOBDELAY          => "IFD",  --Use input at DDLY to output the data on Q1-Q6
OFB_USED          => "FALSE",
SRVAL_Q1          => '0',
SRVAL_Q2          => '0',
SRVAL_Q3          => '0',
SRVAL_Q4          => '0'
)
port map (
Q1                => i_deser_d(0),
Q2                => i_deser_d(1),
Q3                => i_deser_d(2),
Q4                => i_deser_d(3),
Q5                => i_deser_d(4),
Q6                => i_deser_d(5),
Q7                => i_deser_d(6),
Q8                => i_deser_d(7),
SHIFTOUT1         => icascade1,       -- Cascade connection to Slave
SHIFTOUT2         => icascade2,       -- Cascade connection to Slave
BITSLIP           => i_bitslip,                  -- 1-bit Invoke Bitslip. This can be used with any
                                               -- DATA_WIDTH, cascaded or not.
CE1               => p_in_clken,
CE2               => p_in_clken,
CLK               => p_in_clk,               -- Fast Source Synchronous SERDES clock from BUFIO
CLKB              => p_in_clkinv,           -- Locally inverted clock
CLKDIV            => p_in_clkdiv,                  -- Slow clock driven by BUFR
CLKDIVP           => '0',
D                 => '0',
DDLY              => i_idelaye2_dout,
RST               => p_in_deser_rst,
SHIFTIN1          => '0',
SHIFTIN2          => '0',
-- unused connections
DYNCLKDIVSEL      => '0',
DYNCLKSEL         => '0',
OFB               => '0',
OCLK              => '0',
OCLKB             => '0',
O                 => open -- unregistered output of ISERDESE1
);


m_iserdese2_slave : ISERDESE2
generic map (
DATA_RATE         => "DDR",
DATA_WIDTH        => 10,
INIT_Q1           => '0',
INIT_Q2           => '0',
INIT_Q3           => '0',
INIT_Q4           => '0',
INTERFACE_TYPE    => "NETWORKING",
NUM_CE            => 2,
SERDES_MODE       => "SLAVE",
--
DYN_CLKDIV_INV_EN => "FALSE",
DYN_CLK_INV_EN    => "FALSE",
IOBDELAY          => "NONE",  -- Use input at DDLY to output the data on Q1-Q6
OFB_USED          => "FALSE",
SRVAL_Q1          => '0',
SRVAL_Q2          => '0',
SRVAL_Q3          => '0',
SRVAL_Q4          => '0'
)
port map (
Q1                => open,
Q2                => open,
Q3                => i_deser_d(8) ,
Q4                => i_deser_d(9) ,
Q5                => i_deser_d(10),
Q6                => i_deser_d(11),
Q7                => i_deser_d(12),
Q8                => i_deser_d(13),
SHIFTOUT1         => open,
SHIFTOUT2         => open,
SHIFTIN1          => icascade1,       -- Cascade connections from Master
SHIFTIN2          => icascade2,       -- Cascade connections from Master
BITSLIP           => i_bitslip,                  -- 1-bit Invoke Bitslip. This can be used with any
                                               -- DATA_WIDTH, cascaded or not.
CE1               => p_in_clken,
CE2               => p_in_clken,
CLK               => p_in_clk,               -- Fast source synchronous serdes clock
CLKB              => p_in_clkinv,           -- locally inverted clock
CLKDIV            => p_in_clkdiv,                  -- Slow clock sriven by BUFR.
CLKDIVP           => '0',
D                 => '0',                      -- Slave ISERDES module. No need to connect D, DDLY
DDLY              => '0',
RST               => p_in_deser_rst,
-- unused connections
DYNCLKDIVSEL      => '0',
DYNCLKSEL         => '0',
OFB               => '0',
OCLK              => '0',
OCLKB             => '0',
O                 => open                    -- unregistered output of ISERDESE1
);

process(p_in_clkdiv)
begin
if rising_edge(p_in_clkdiv) then
  if p_in_deser_rst = '1' then
    i_bitslip <= '0';
    i_aligen_done <= '1';
    i_fsm_aligen_cs <= S_IDLE;
    i_cntok <= (others => '0');

  else

    case i_fsm_aligen_cs is

      when S_IDLE =>

          i_bitslip <= '0';
          i_fsm_aligen_cs <= S_BITSLIP_ANLZ;

      when S_BITSLIP_ANLZ =>

          if i_deser_d(G_BIT_COUNT - 1 downto 0) /= TO_UNSIGNED(C_CCD_CHSYNC_TRAINING, G_BIT_COUNT) then
            i_bitslip <= '1';
            i_fsm_aligen_cs <= S_BITSLIP_WAIT0;
          else
            i_fsm_aligen_cs <= S_BITSLIP_ANLZ2;
          end if;

      when S_BITSLIP_WAIT0 =>

           i_bitslip <= '0';
           i_fsm_aligen_cs <= S_BITSLIP_WAIT1;

      when S_BITSLIP_WAIT1 =>

           i_fsm_aligen_cs <= S_BITSLIP_WAIT2;

      when S_BITSLIP_WAIT2 =>

           i_fsm_aligen_cs <= S_BITSLIP_ANLZ;

      when S_ALIGEN_DONE =>

          i_bitslip <= '0';
          i_aligen_done <= '1';
          i_fsm_aligen_cs <= S_ALIGEN_DONE;

      when S_BITSLIP_ANLZ2 =>

          if i_deser_d(G_BIT_COUNT - 1 downto 0) = TO_UNSIGNED(C_CCD_CHSYNC_TRAINING, G_BIT_COUNT) then
            if i_cntok = TO_UNSIGNED(C_CCD_CHSYNC_TRAINING, i_cntok'length) then
              i_cntok <= (others => '0');
              i_fsm_aligen_cs <= S_ALIGEN_DONE;
            else
              i_cntok <= i_cntok + 1;
              i_fsm_aligen_cs <= S_BITSLIP_ANLZ2;
            end if;
          else
            i_fsm_aligen_cs <= S_BITSLIP_ANLZ;
          end if;

    end case;

  end if;
end if;
end process;


p_out_rxd <= std_logic_vector(i_deser_d(p_out_rxd'range));

p_out_aligen_done <= i_aligen_done;


end xilinx;




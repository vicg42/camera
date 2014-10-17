-------------------------------------------------------------------------
-- Company     : Yansar
-- Engineer    : Golovachenko Victor
--
-- Create Date : 11.09.2014 10:34:16
-- Module Name : ccd_deser (deserilazer)
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
use work.ccd_pkg.all;

entity ccd_deser is
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
end ccd_deser;

architecture xilinx of ccd_deser is

type TFsm_align is (
S_IDLE          ,
S_DESER_RST     ,
S_WAIT          ,
S_BITSLIP_ANLZ  ,
S_BITSLIP_WAIT  ,
S_ALIGN_DONE    ,
S_ALIGN_ANLZ
);

signal i_fsm_align_cs        : TFsm_align;

signal i_ser_din             : std_logic;

signal i_idelaye2_ld         : std_logic;
signal i_idelaye2_dout       : std_logic;
signal i_idelaye2_ce         : std_logic;
signal i_idelaye2_inc        : std_logic;
signal i_idelaye2_tapcnt     : unsigned(5 downto 0);

signal i_deser_rst           : std_logic;
signal i_deser_d             : unsigned(13 downto 0);
signal sr_deser_d            : unsigned(p_out_data'range);
signal icascade1             : std_logic;
signal icascade2             : std_logic;

signal i_align_ok            : std_logic;
signal i_bitslip_cnt         : unsigned(3 downto 0);
signal i_bitslip             : std_logic;
signal i_cntok               : unsigned(12 downto 0);

signal i_cntdly              : unsigned(6 downto 0);



begin


p_out_tst <= (others => '0');


m_ibufds : IBUFDS
--generic map (
--DIFF_TERM  => TRUE -- define into ucf file!!!
--)
port map (
I   => p_in_data_p,
IB  => p_in_data_n,
O   => i_ser_din
);


m_idelaye2 : IDELAYE2
generic map (
CINVCTRL_SEL          => "FALSE"   ,-- Enable dynamic clock inversion (FALSE, TRUE)
DELAY_SRC             => "IDATAIN" ,-- Delay input (IDATAIN, DATAIN)
HIGH_PERFORMANCE_MODE => "TRUE"    ,-- Reduced jitter ("TRUE"), Reduced power ("FALSE")
IDELAY_TYPE           => "VARIABLE",-- FIXED, VARIABLE, VAR_LOAD, VAR_LOAD_PIPE
IDELAY_VALUE          => 0         ,-- Input delay tap setting (0-31)
PIPE_SEL              => "FALSE"   ,-- Select pipelined mode, FALSE, TRUE
REFCLK_FREQUENCY      => 200.0     ,-- IDELAYCTRL clock input frequency in MHz (190.0-210.0, 290.0-310.0).
SIGNAL_PATTERN        => "DATA"     -- DATA, CLOCK input signal
)
port map (
DATAOUT           => i_idelaye2_dout,
DATAIN            => '0',
C                 => p_in_clkdiv,
CE                => i_idelaye2_ce,
INC               => i_idelaye2_inc,
IDATAIN           => i_ser_din,
LD                => i_idelaye2_ld,
REGRST            => i_deser_rst, --p_in_rst,--
LDPIPEEN          => '0',
CNTVALUEIN        => (others => '0'),
CNTVALUEOUT       => open,
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
BITSLIP           => i_bitslip,       -- 1-bit Invoke Bitslip. This can be used with any
                                      -- DATA_WIDTH, cascaded or not.
CE1               => p_in_clken,
CE2               => p_in_clken,
CLK               => p_in_clk,        -- Fast Source Synchronous SERDES clock from BUFIO
CLKB              => p_in_clkinv,     -- Locally inverted clock
CLKDIV            => p_in_clkdiv,     -- Slow clock driven by BUFR
CLKDIVP           => '0',
D                 => '0',
DDLY              => i_idelaye2_dout,
RST               => i_deser_rst, --p_in_rst,--
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
BITSLIP           => i_bitslip,       -- 1-bit Invoke Bitslip. This can be used with any
                                      -- DATA_WIDTH, cascaded or not.
CE1               => p_in_clken,
CE2               => p_in_clken,
CLK               => p_in_clk,        -- Fast source synchronous serdes clock
CLKB              => p_in_clkinv,     -- locally inverted clock
CLKDIV            => p_in_clkdiv,     -- Slow clock sriven by BUFR.
CLKDIVP           => '0',
D                 => '0',             -- Slave ISERDES module. No need to connect D, DDLY
DDLY              => '0',
RST               => i_deser_rst, --p_in_rst,--
-- unused connections
DYNCLKDIVSEL      => '0',
DYNCLKSEL         => '0',
OFB               => '0',
OCLK              => '0',
OCLKB             => '0',
O                 => open             -- unregistered output of ISERDESE1
);


--################################
--FSM ccd video data align
--################################
process(p_in_clkdiv)
begin
if rising_edge(p_in_clkdiv) then
  if p_in_rst = '1' then
    i_fsm_align_cs <= S_IDLE;
    i_align_ok <= '0';

    i_bitslip <= '0';
    i_bitslip_cnt <= (others => '0');

    i_idelaye2_tapcnt <= (others => '0');
    i_idelaye2_inc <= '0';
    i_idelaye2_ce <= '0';
    i_idelaye2_ld <= '0';

    i_cntok <= (others => '0');

    i_cntdly <= (others => '0');
    i_deser_rst <= '0';

    sr_deser_d <= (others => '0');

  else

    sr_deser_d <= i_deser_d(G_BIT_COUNT - 1 downto 0);

    case i_fsm_align_cs is

      when S_IDLE =>

          i_bitslip <= '0';
          i_deser_rst <= '0';
          i_idelaye2_inc <= '0';
          i_fsm_align_cs <= S_DESER_RST;

      when S_DESER_RST =>

          if i_cntdly = TO_UNSIGNED(30, i_cntdly'length) then
            i_deser_rst <= '0';
            i_cntdly <= (others => '0');
            i_fsm_align_cs <= S_WAIT;
          else
            i_deser_rst <= '1';
            i_cntdly <= i_cntdly + 1;
          end if;

      when S_WAIT =>

          if i_cntdly = TO_UNSIGNED(10, i_cntdly'length) then
            i_cntdly <= (others => '0');
            i_idelaye2_ld <= '1';
            i_fsm_align_cs <= S_BITSLIP_ANLZ;
          else
            i_cntdly <= i_cntdly + 1;
          end if;


      when S_BITSLIP_ANLZ =>

          i_idelaye2_ld <= '0';
          i_cntok <= (others => '0');

          if sr_deser_d /= TO_UNSIGNED(C_CCD_CHSYNC_TRAINING, sr_deser_d'length) then

            if i_bitslip_cnt = TO_UNSIGNED(10, G_BIT_COUNT) then
              i_bitslip_cnt <= (others => '0');

              --idelaye2 adjustment
              i_idelaye2_tapcnt <= i_idelaye2_tapcnt + 1;
              i_idelaye2_inc <= '1';
              i_idelaye2_ce <= '1';--not i_idelaye2_tapcnt(5);

              if i_idelaye2_tapcnt = (i_idelaye2_tapcnt'range => '1') then
                i_fsm_align_cs <= S_IDLE;
              else
                i_fsm_align_cs <= S_BITSLIP_WAIT;
              end if;

            else
              i_bitslip_cnt <= i_bitslip_cnt + 1;
              i_fsm_align_cs <= S_BITSLIP_WAIT;

            end if;

            i_bitslip <= '1';

          else
            i_fsm_align_cs <= S_ALIGN_ANLZ;

          end if;

      when S_BITSLIP_WAIT =>

           i_idelaye2_inc <= '0';
           i_bitslip <= '0';

          if i_cntdly = TO_UNSIGNED(2, i_cntdly'length) then
            i_cntdly <= (others => '0');
            i_fsm_align_cs <= S_BITSLIP_ANLZ;
          else
            i_cntdly <= i_cntdly + 1;
          end if;

      when S_ALIGN_DONE =>

          i_bitslip <= '0';
          i_align_ok <= '1';
          i_fsm_align_cs <= S_ALIGN_DONE;

      when S_ALIGN_ANLZ =>

          if sr_deser_d /= TO_UNSIGNED(C_CCD_CHSYNC_TRAINING, sr_deser_d'length) then

            if i_cntok = (i_cntok'range => '1') then
              i_cntok <= (others => '0');
              i_fsm_align_cs <= S_ALIGN_DONE;

            else
              i_cntok <= i_cntok + 1;
              i_fsm_align_cs <= S_ALIGN_ANLZ;

            end if;

          else

            i_fsm_align_cs <= S_BITSLIP_ANLZ;

          end if;

    end case;

  end if;
end if;
end process;


p_out_data <= std_logic_vector(sr_deser_d);
p_out_align_ok <= i_align_ok;


end xilinx;




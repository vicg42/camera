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
--use ieee.std_logic_signed.all;

library unisim;
use unisim.vcomponents.all;

library work;
use work.ccd_pkg.all;
use work.reduce_pack.all;

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

constant CI_DATA_STABLE_COUNT : integer := 256;
constant CI_IDELAY_TAP_COUNT : integer := 64;
constant CI_IDELAY_LATENCY   : integer := 64;
constant CI_BITSLIP_DELAY    : integer := 20;
constant CI_TRY_COUNT        : integer := 50;
--constant CI_BITSLIP_RETRY_COUNT : integer := 32;

type TDataValid is array (0 to G_BIT_COUNT - 1 ) of unsigned(G_BIT_COUNT - 1 downto 0);
constant CI_VALID_DATA : TDataValid := (
TO_UNSIGNED(16#3A6#, G_BIT_COUNT),
TO_UNSIGNED(16#34D#, G_BIT_COUNT),
TO_UNSIGNED(16#29B#, G_BIT_COUNT),
TO_UNSIGNED(16#137#, G_BIT_COUNT),
TO_UNSIGNED(16#26E#, G_BIT_COUNT),
TO_UNSIGNED(16#0DD#, G_BIT_COUNT),
TO_UNSIGNED(16#1BA#, G_BIT_COUNT),
TO_UNSIGNED(16#374#, G_BIT_COUNT),
TO_UNSIGNED(16#2E9#, G_BIT_COUNT),
TO_UNSIGNED(16#1D3#, G_BIT_COUNT)
);

signal i_ser_din             : std_logic;
signal i_idelaye2_ld         : std_logic;
signal i_idelaye2_dout       : std_logic;
signal i_idelaye2_ce         : std_logic;
signal i_idelaye2_inc        : std_logic;
signal i_idelaye2_tapcnt     : unsigned(5 downto 0);

signal i_deser_rst           : std_logic;
signal i_deser_d             : unsigned(13 downto 0);
signal icascade1             : std_logic;
signal icascade2             : std_logic;

signal i_align_ok            : std_logic;
signal i_bitslip_cnt         : unsigned(3 downto 0);
signal i_bitslip             : std_logic;
signal i_cntok               : unsigned(12 downto 0);

signal i_cntdly              : unsigned(15 downto 0);

type TFsm_Align is (
S_IDLE            ,
S_RST_DESER       ,
S_DATA_CHNG       ,
S_DATA_STBL       ,
S_FIND_EDGE0      ,
S_FIND_EDGE0_WAIT ,
S_CUR_POINT       ,
S_CUR_POINT_WAIT  ,
S_FIND_EDGE1      ,
S_FIND_EDGE1_WAIT ,
S_MDL_POINT       ,
S_MDL_POINT_WAIT  ,
S_ALIGN_START     ,
S_ALIGN_WAIT      ,
S_ALIGN_DONE
--S_RST_DLY
);
signal i_fsm_align : TFsm_Align;

signal sr_deser_d0       : unsigned (G_BIT_COUNT - 1 downto 0);
signal i_data_chng       : std_logic := '0';

signal i_align_start     : std_logic;
signal i_align_done      : std_logic;

signal i_cnttap0         : unsigned (5 downto 0);
signal i_cnttap1         : unsigned (5 downto 0);
signal i_cnttap          : unsigned (7 downto 0);
signal i_cnttap0_sv      : unsigned (5 downto 0);
signal i_cnttap1_sv      : unsigned (5 downto 0);
signal i_cnttap_midle    : unsigned (5 downto 0);
signal i_deser_d_sv      : unsigned (G_BIT_COUNT - 1 downto 0);
signal i_cnttry          : unsigned (5 downto 0);

signal i_bitslip_work    : std_logic;

signal i_rst_width       : unsigned (3 downto 0);

signal tst_fsm_align,tst_fsm_align_dly : std_logic_vector(3 downto 0);
signal tst_align_dchng : std_logic;



begin


p_out_tst(0) <= OR_reduce(tst_fsm_align_dly) or tst_align_dchng;




process(p_in_rst, p_in_clkdiv)
begin
if rising_edge(p_in_clkdiv) then
  tst_fsm_align_dly <= tst_fsm_align;
  tst_align_dchng <= i_align_ok and i_data_chng;
end if;
end process;

 --std_logic_vector(TO_UNSIGNED(16#0F#,tst_fsm_align'length)) when i_fsm_align = S_RST_DLY         else
tst_fsm_align <= std_logic_vector(TO_UNSIGNED(16#0E#,tst_fsm_align'length)) when i_fsm_align = S_RST_DESER       else
                 std_logic_vector(TO_UNSIGNED(16#0D#,tst_fsm_align'length)) when i_fsm_align = S_DATA_CHNG       else
                 std_logic_vector(TO_UNSIGNED(16#0C#,tst_fsm_align'length)) when i_fsm_align = S_DATA_STBL       else
                 std_logic_vector(TO_UNSIGNED(16#0B#,tst_fsm_align'length)) when i_fsm_align = S_FIND_EDGE0      else
                 std_logic_vector(TO_UNSIGNED(16#0A#,tst_fsm_align'length)) when i_fsm_align = S_FIND_EDGE0_WAIT else
                 std_logic_vector(TO_UNSIGNED(16#09#,tst_fsm_align'length)) when i_fsm_align = S_CUR_POINT       else
                 std_logic_vector(TO_UNSIGNED(16#08#,tst_fsm_align'length)) when i_fsm_align = S_CUR_POINT_WAIT  else
                 std_logic_vector(TO_UNSIGNED(16#07#,tst_fsm_align'length)) when i_fsm_align = S_FIND_EDGE1      else
                 std_logic_vector(TO_UNSIGNED(16#06#,tst_fsm_align'length)) when i_fsm_align = S_FIND_EDGE1_WAIT else
                 std_logic_vector(TO_UNSIGNED(16#05#,tst_fsm_align'length)) when i_fsm_align = S_MDL_POINT       else
                 std_logic_vector(TO_UNSIGNED(16#04#,tst_fsm_align'length)) when i_fsm_align = S_MDL_POINT_WAIT  else
                 std_logic_vector(TO_UNSIGNED(16#03#,tst_fsm_align'length)) when i_fsm_align = S_ALIGN_START     else
                 std_logic_vector(TO_UNSIGNED(16#02#,tst_fsm_align'length)) when i_fsm_align = S_ALIGN_WAIT      else
                 std_logic_vector(TO_UNSIGNED(16#01#,tst_fsm_align'length)) when i_fsm_align = S_ALIGN_DONE      else
                 std_logic_vector(TO_UNSIGNED(16#00#,tst_fsm_align'length));-- when i_fsm_align = S_IDLE            else


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
IDELAY_VALUE          => 13         ,-- Input delay tap setting (0-31)
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
LD                => i_align_start,--i_idelaye2_ld,
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

p_out_data <= std_logic_vector(i_deser_d(p_out_data'range));
p_out_align_ok <= i_align_ok;


--################################
--FSM ccd video data align
--################################

process(p_in_rst, p_in_clkdiv)
begin
if (p_in_rst = '1') then
  sr_deser_d0 <= (others => '0');
  i_data_chng <= '0';

elsif rising_edge(p_in_clkdiv) then
  sr_deser_d0(G_BIT_COUNT - 1 downto 0) <= i_deser_d(G_BIT_COUNT - 1 downto 0);

  if sr_deser_d0 /= i_deser_d(G_BIT_COUNT - 1 downto 0) then
    i_data_chng <= '1';
  else
    i_data_chng <= '0';
  end if;
end if;
end process;

i_align_start <= p_in_tst(0);



process(p_in_rst, p_in_clkdiv)
variable valid : std_logic;
begin
if (p_in_rst = '1') then

    i_deser_rst    <= '0';
    i_idelaye2_inc <= '0';
    i_idelaye2_ce  <= '0';
    i_bitslip      <= '0';
    i_bitslip_work <= '0';

    i_align_ok <= '0';

    i_cntdly <= (others => '0');
    i_cnttap0 <= (others => '0');
    i_cnttap1 <= (others => '0');
    i_cnttap  <= (others => '0');
    i_cnttap_midle <= (others => '0');
    i_cnttry  <= (others => '0');

    i_cnttap0_sv <= (others => '0');
    i_cnttap1_sv <= (others => '0');
    i_deser_d_sv <= (others => '0');

    valid := '0';

    i_fsm_align <= S_IDLE;

elsif rising_edge(p_in_clkdiv) then

    valid := '0';

    case i_fsm_align is

        when S_IDLE =>

            if (i_align_start = '1') then
                i_align_ok <= '0';

                i_deser_rst    <= '1';
                i_idelaye2_inc <= '0';
                i_idelaye2_ce  <= '0';

                i_fsm_align <= S_RST_DESER;

            end if;


        when S_RST_DESER =>

            i_cnttap_midle <= (others => '0');
            i_cntdly <= (others => '0');
            i_cnttap0 <= (others => '0');
            i_cnttap1 <= (others => '0');
            i_cnttap  <= (others => '0');

            i_bitslip <= '0';
            i_bitslip_work <= '0';
            i_idelaye2_ce  <= '0';
            i_idelaye2_inc <= '0';
            i_deser_rst    <= '0';

            i_fsm_align <= S_DATA_CHNG;


        when S_DATA_CHNG =>

            i_idelaye2_ce  <= '0';
            i_idelaye2_inc <= '0';

            if (i_data_chng = '0') then
              i_fsm_align <= S_DATA_STBL;
            end if;


        when S_DATA_STBL =>

            i_cnttap <= (others => '0');

            if (i_data_chng = '1') then

              if i_cnttry = TO_UNSIGNED(CI_TRY_COUNT - 1, i_cnttry'length) then
                i_cnttry <= (others => '0');

                i_deser_rst <= '1';
                i_fsm_align <= S_RST_DESER;

              else
                i_cnttry <= i_cnttry + 1;

                i_idelaye2_ce  <= '1';
                i_idelaye2_inc <= '0';
                i_fsm_align <= S_DATA_CHNG;

              end if;

            else
                if i_cntdly = TO_UNSIGNED(CI_DATA_STABLE_COUNT - 1, i_cntdly'length) then
                    i_cntdly <= (others => '0');

                    i_deser_d_sv <= i_deser_d(G_BIT_COUNT - 1 downto 0);
                    i_fsm_align <= S_FIND_EDGE0;

                else
                    i_cntdly <= i_cntdly + 1;
                end if;
            end if;


        when S_FIND_EDGE0 =>

            i_cntdly <= (others => '0');

            i_idelaye2_ce  <= '1';
            i_idelaye2_inc <= '0';

            i_cnttap0 <= i_cnttap0 + 1;

            i_fsm_align <= S_FIND_EDGE0_WAIT;


        when S_FIND_EDGE0_WAIT =>

            i_idelaye2_ce <= '0';

            if i_cntdly = TO_UNSIGNED(CI_IDELAY_LATENCY - 1, i_cntdly'length) then
              i_cntdly <= (others => '0');

              if i_cnttap0 = TO_UNSIGNED((CI_IDELAY_TAP_COUNT / 2), i_cnttap0'length) then
                  i_cnttap0_sv <= i_cnttap0;

                  i_fsm_align <= S_CUR_POINT;

              else

                  if i_deser_d_sv /= i_deser_d(G_BIT_COUNT - 1 downto 0) then
                    i_cnttap0_sv <= i_cnttap0;

                    i_fsm_align <= S_CUR_POINT;

                  else
                    i_fsm_align <= S_FIND_EDGE0;

                  end if;

              end if;

            else
                i_cntdly <= i_cntdly + 1;

            end if;


        when S_CUR_POINT =>

            i_cntdly <= (others => '0');

            i_idelaye2_ce  <= '1';
            i_idelaye2_inc <= '1';

            i_cnttap0 <= i_cnttap0 - 1;
            i_cnttap <= i_cnttap + 1;
            i_fsm_align <= S_CUR_POINT_WAIT;

        when S_CUR_POINT_WAIT =>

            i_idelaye2_ce  <= '0';

            if i_cntdly = TO_UNSIGNED(CI_IDELAY_LATENCY - 1, i_cntdly'length) then
              i_cntdly <= (others => '0');

              if i_cnttap0 = TO_UNSIGNED(0, i_cnttap0'length) then
                  i_deser_d_sv <= i_deser_d(G_BIT_COUNT - 1 downto 0);
                  i_fsm_align <= S_FIND_EDGE1;

              else
                  i_fsm_align <= S_CUR_POINT;

              end if;

            else
                i_cntdly <= i_cntdly + 1;

            end if;



        when S_FIND_EDGE1 =>

            i_cntdly <= (others => '0');

            i_idelaye2_ce  <= '1';
            i_idelaye2_inc <= '1';

            i_cnttap1 <= i_cnttap1 + 1;
            i_cnttap <= i_cnttap + 1;

            i_fsm_align <= S_FIND_EDGE1_WAIT;


        when S_FIND_EDGE1_WAIT =>

            i_idelaye2_ce <= '0';

            if i_cntdly = TO_UNSIGNED(CI_IDELAY_LATENCY - 1, i_cntdly'length) then
              i_cntdly <= (others => '0');

              if i_cnttap1 = TO_UNSIGNED((CI_IDELAY_TAP_COUNT / 2), i_cnttap1'length) then
                  i_cnttap1_sv <= i_cnttap1;

                  i_fsm_align <= S_MDL_POINT;

              else

                  if i_deser_d_sv /= i_deser_d(G_BIT_COUNT - 1 downto 0) then
                    i_cnttap1_sv <= i_cnttap1;

                    i_fsm_align <= S_MDL_POINT;

                  else
                    i_fsm_align <= S_FIND_EDGE1;

                  end if;

              end if;

            else
                i_cntdly <= i_cntdly + 1;

            end if;


        when S_MDL_POINT =>

            i_cnttap1 <= (others => '0');
            i_cnttap_midle <= i_cnttap0_sv + i_cnttap1_sv;

            i_cntdly <= (others => '0');

            i_idelaye2_ce  <= '1';
            i_idelaye2_inc <= '0';

            i_cnttap <= i_cnttap - 1;
            i_fsm_align <= S_MDL_POINT_WAIT;


        when S_MDL_POINT_WAIT =>

            i_idelaye2_ce <= '0';

            if i_cntdly = TO_UNSIGNED(CI_IDELAY_LATENCY - 1, i_cntdly'length) then
              i_cntdly <= (others => '0');

              if i_cnttap = ('0' & i_cnttap_midle(i_cnttap_midle'high downto 1)) then
                  i_deser_d_sv <= i_deser_d(G_BIT_COUNT - 1 downto 0);
                  i_fsm_align <= S_ALIGN_START;

              else
                  i_fsm_align <= S_MDL_POINT;

              end if;

            else
                i_cntdly <= i_cntdly + 1;

            end if;


        when S_ALIGN_START =>

            if (i_deser_d(i_deser_d_sv'range) = TO_UNSIGNED(C_CCD_CHSYNC_TRAINING, G_BIT_COUNT)) then
                i_fsm_align <= S_ALIGN_DONE;

            else
                if i_bitslip_work = '1' and (i_deser_d_sv = i_deser_d(G_BIT_COUNT - 1 downto 0)) then

                  i_deser_rst <= '1';
                  i_fsm_align <= S_RST_DESER;

                else
                  i_bitslip <= '1';
                  i_bitslip_work <= '1';
                  i_fsm_align <= S_ALIGN_WAIT;

                end if;

            end if;


        when S_ALIGN_WAIT =>

            i_bitslip <= '0';

            if i_cntdly = TO_UNSIGNED(CI_BITSLIP_DELAY - 1, i_cntdly'length) then
              i_cntdly <= (others => '0');
              i_fsm_align <= S_ALIGN_START;

            else
                i_cntdly <= i_cntdly + 1;

            end if;


        when S_ALIGN_DONE =>

            i_deser_rst    <= '0';
            i_idelaye2_inc <= '0';
            i_idelaye2_ce  <= '0';
            i_bitslip      <= '0';

            i_align_ok <= '1';
            i_fsm_align <= S_IDLE;

    end case;
end if;
end process;




end xilinx;




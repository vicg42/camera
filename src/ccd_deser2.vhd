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

signal i_ser_din             : std_logic;

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

signal i_cntdly              : unsigned(6 downto 0);


type TFsm_Handshake is (
S_IDLE,
S_WAIT_ACK_HIGH,
S_WAIT_ACK_LOW
);
signal i_fsm_handshake : TFsm_Handshake;

type TFsm_Serdesseq is (
--ResetFifo,
S_IDLE,
S_TRAIN_SERDES,
S_WAIT_TRAIN_SERDES_BUSYON,
S_WAIT_TRAIN_SERDES_BUSYOFF
);
signal i_fsm_serdesseq : TFsm_Serdesseq;

type TFsm_Align is (
S_IDLE,
S_RST_DELAY,
S_WAIT_RST_DELAY,
S_GET_EDGE,
S_CHK_EDGE,
S_WAIT_SAMPLE_STABLE,
S_COMPARE_TRAINING,
S_VALID_BEGIN_FOUND,
S_CHK_FIRST_EDGE_CHANGED,
S_CHK_FIRST_EDGE_STABLE,
S_CHK_SECOND_EDGE_CHANGED,
S_WINDOW_FOUND,
S_RST_DELAY_MAN,
S_START_WORD_ALIGN,
S_DO_WORD_ALIGN,
S_ALIGNMENT_DONE
);
signal i_fsm_align : TFsm_Align;


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
LD                => '0',
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
gen_edge_detect: for i in 0 to (DATAWIDTH-2) generate
edge_int(i) <= i_deser_d(i) xor i_deser_d(i+1);
end generate;
edge_int(DATAWIDTH-1) <= i_deser_d(0) xor i_deser_d(DATAWIDTH-1);

edgeprocess: process(CLOCK)
variable edge_tmp : std_logic := '0';
begin
if (CLOCK'event and CLOCK = '1') then
  -- funny workaround to make OR-ing of parametrisable signals into one signal work
  if (start_handshake = '1') then
    edge_tmp := '0';
  else
    for i in 0 to DATAWIDTH-1 loop
      edge_tmp := edge_tmp or edge_int(i);
    end loop;
    edge_int_or <= edge_tmp;
  end if;
end if;
end process;

handshaker: process(RESET, CLOCK)
begin
if (RESET = '1') then
  REQ            <= '0';
  end_handshake  <= '0';
  i_fsm_handshake <= S_IDLE;
  TIMEOUTONACK   <= '0';
  TimeOutCntr    <= TimeOutCntrLd;

elsif (CLOCK'EVENT and CLOCK = '1') then

  -- defaults
  end_handshake   <= '0';

  case i_fsm_handshake is
    when S_IDLE =>

      if ALIGN_START='1'then
          TIMEOUTONACK <= '0';
          TimeOutCntr <= TimeOutCntrLd;
      end if;

      if (start_handshake = '1') then
          REQ <= '1';
          i_fsm_handshake <= S_WAIT_ACK_HIGH;
      end if;

    when S_WAIT_ACK_HIGH =>
      if (ACK = '1') then
          REQ <= '0';
          i_fsm_handshake <= S_WAIT_ACK_LOW;
          TimeOutCntr <= TimeOutCntrLd;

      elsif(TimeOutCntr(TimeOutCntr'high) = '1') then
          TIMEOUTONACK <=  '1';
          i_fsm_handshake <= S_IDLE;
          TimeOutCntr <= TimeOutCntrLd;
          end_handshake <= '1';
      else
          TimeOutCntr <= TimeOutCntr - '1' ;
      end if;

    when S_WAIT_ACK_LOW =>
      if (ACK = '0') then
          end_handshake <= '1';
          i_fsm_handshake <= S_IDLE;
          TimeOutCntr <= TimeOutCntrLd;

      elsif(TimeOutCntr(TimeOutCntr'high) = '1') then
          TIMEOUTONACK <=  '1';
          i_fsm_handshake <= S_IDLE;
          TimeOutCntr <= TimeOutCntrLd;
          end_handshake <= '1';
      else
          TimeOutCntr <= TimeOutCntr - '1';
      end if;

    when others =>
        i_fsm_handshake <= S_IDLE;

  end case;
end if;
end process handshaker;


CTRL_SEL <= selector;

alignsequencer: process(RESET, CLOCK)
begin
if (RESET = '1') then
  selector       <= (others => '0');
  SerdesCntr     <= std_logic_vector(TO_SIGNED(3,(SerdesCntr'high+1)));

  ALIGN_BUSY     <= '0';
  ALIGNED        <= '0';

  start_align_i  <= '0';

  CTRL_FIFO_RESET <= '1';
  CTRL_SAMPLEINFIRSTBIT   <= (others => '0');
  CTRL_SAMPLEINLASTBIT    <= (others => '0');
  CTRL_SAMPLEINOTHERBIT   <= (others => '0');

  i_fsm_serdesseq  <= S_IDLE;

elsif (CLOCK'EVENT and CLOCK = '1') then

  start_align_i   <= '0';

  case i_fsm_serdesseq is

      when S_IDLE =>
        --CTRL_FIFO_RESET <= '0';
        if (ALIGN_START = '1') then
          CTRL_FIFO_RESET <= '1';
          ALIGN_BUSY      <= '1';
          start_align_i   <= '1';
          SerdesCntr      <=  std_logic_vector(TO_SIGNED((NROF_CONN-2),(SerdesCntr'high+1)));
          selector        <= (others => '0');
          i_fsm_serdesseq  <= S_TRAIN_SERDES;
        end if;

      when S_TRAIN_SERDES =>
        i_fsm_serdesseq  <= S_WAIT_TRAIN_SERDES_BUSYON;

      when S_WAIT_TRAIN_SERDES_BUSYON =>
        if (busy_align_i = '1') then
          i_fsm_serdesseq  <= S_WAIT_TRAIN_SERDES_BUSYOFF;
        end if;

      when S_WAIT_TRAIN_SERDES_BUSYOFF =>
        if (busy_align_i = '0') then
            CTRL_SAMPLEINFIRSTBIT(TO_INTEGER(UNSIGNED(selector)))<= CTRL_SAMPLEINFIRSTBIT_i;
            CTRL_SAMPLEINLASTBIT(TO_INTEGER(UNSIGNED(selector))) <= CTRL_SAMPLEINLASTBIT_i;
            CTRL_SAMPLEINOTHERBIT(TO_INTEGER(UNSIGNED(selector)))<= CTRL_SAMPLEINOTHERBIT_i;
            if (SerdesCntr(SerdesCntr'high) = '1') then
              ALIGNED         <= '1';
              ALIGN_BUSY      <= '0';
              CTRL_FIFO_RESET <= '0';
              i_fsm_serdesseq  <= S_IDLE;
            else
              start_align_i <= '1';
              selector <= selector + '1';
              SerdesCntr <= SerdesCntr - '1';
              i_fsm_serdesseq <= S_TRAIN_SERDES;
            end if;
        end if;

      when others =>
          i_fsm_serdesseq <= S_IDLE;
  end case;
end if;
end process alignsequencer;

aligning: process(RESET, CLOCK)
variable index : integer range 0 to 65535;
begin
if (RESET = '1') then

    done_align_i    <= '0';
    busy_align_i    <= '0';

    CTRL_RESET          <= '1';
    CTRL_INC            <= '0';
    CTRL_CE             <= '0';
    CTRL_BITSLIP        <= '0';

    CTRL_SAMPLEINFIRSTBIT_i   <= '0';
    CTRL_SAMPLEINLASTBIT_i    <= '0';
    CTRL_SAMPLEINOTHERBIT_i   <= '0';

    edge_init           <= (others => '0');
    data_init           <= (others => '0');

    EDGE_DETECT         <= (others => '0');
    TRAINING_DETECT     <= (others => '0');
    STABLE_DETECT       <= (others => '0');
    FIRST_EDGE_FOUND    <= (others => '0');
    SECOND_EDGE_FOUND   <= (others => '0');
    WORD_ALIGN          <= (others => '0');
    NROF_RETRIES        <= (others => '0');
    TAP_SETTING         <= (others => '0');
    WINDOW_WIDTH        <= (others => '0');

    start_handshake <= '0';

    maxcount            <= (others => '1');
    tapcount            <= (others => '0');
    windowcount         <= (others => '0');
    bitcount            <= (others => '0');
    retries             <= (others => '0');

    compare             <= (others => (others => '0'));

    RetryCntr           <= (others => '1');
    GenCntr             <= (others => '1');

    index               := 0;
    i_fsm_align <= S_IDLE;

elsif (CLOCK'event and CLOCK = '1') then
    --defaults
    done_align_i    <= '0';
    start_handshake <= '0';

    index               := TO_INTEGER(UNSIGNED(selector));

    -- generate compare words
    -- the 2 last versions will be the 'special' words that when stable sampling
    -- occurs on both of them the resulting parallel words will be skewed.
    -- In this case the data written into the FIFO has to be compensated for the skew
    --
    for i in 0 to (DATAWIDTH-1) loop
        compare(i) <= STD_LOGIC_VECTOR(UNSIGNED(TRAINING) ROL (i+6));
    end loop;

    case i_fsm_align is
        when S_IDLE =>
            busy_align_i    <= '0';
            if (start_align_i = '1') then
                 busy_align_i    <= '1';
                --reset status words
                 EDGE_DETECT(index)         <= '0';
                 TRAINING_DETECT(index)     <= '0';
                 STABLE_DETECT(index)       <= '0';
                 FIRST_EDGE_FOUND(index)    <= '0';
                 SECOND_EDGE_FOUND(index)   <= '0';
                 WORD_ALIGN(index)          <= '0';
                 NROF_RETRIES((16*index)+15 downto 16*index)    <= (others => '0');
                 TAP_SETTING((10*index)+9 downto 10*index)      <= (others => '0');
                 WINDOW_WIDTH((10*index)+9 downto 10*index)     <= (others => '0');

                 tapcount            <= (others => '0');
                 windowcount         <= (others => '0');
                 bitcount            <= (others => '0');
                 Maxcount            <= std_logic_vector(TO_UNSIGNED((TAP_COUNT_MAX-1),(Maxcount'high+1)));
                 retries             <= (others => '0');
                 RetryCntr           <= retry_count_load;

                if (AUTOALIGN = '1') then -- use training algorithm
                    CTRL_RESET      <= '1';
                    CTRL_INC        <= '0';
                    CTRL_CE         <= '0';
                    start_handshake <= '1';
                    CTRL_SAMPLEINFIRSTBIT_i   <= '0';
                    CTRL_SAMPLEINLASTBIT_i    <= '0';
                    CTRL_SAMPLEINOTHERBIT_i   <= '0';
                    i_fsm_align      <= S_RST_DELAY;
                else                      -- manually set tapcount
                    start_handshake <= '1';
                    CTRL_RESET      <= '1';
                    CTRL_INC        <= '0';
                    CTRL_CE         <= '0';
                    GenCntr         <= "000000" & MANUAL_TAP;
                    CTRL_SAMPLEINFIRSTBIT_i   <= '0';
                    CTRL_SAMPLEINLASTBIT_i    <= '0';
                    CTRL_SAMPLEINOTHERBIT_i   <= '0';
                    i_fsm_align      <= S_RST_DELAY_MAN;
                end if;
            end if;

        when S_RST_DELAY =>
            GenCntr         <= std_logic_vector(TO_UNSIGNED((STABLE_COUNT-1),(GenCntr'high+1)));
            if (end_handshake = '1') then
               i_fsm_align       <= S_WAIT_RST_DELAY;
            end if;

        when S_WAIT_RST_DELAY =>
            start_handshake     <= '1';
            --do nothing
            CTRL_RESET          <= '0';
            CTRL_INC            <= '0';
            CTRL_CE             <= '0';
            i_fsm_align          <= S_GET_EDGE;

        when S_GET_EDGE =>
            if (end_handshake = '1') then
                EDGE_DETECT(index)   <= edge_int_or;
                i_fsm_align           <= S_CHK_EDGE;
            end if;

        when S_CHK_EDGE =>
            if (RetryCntr(RetryCntr'high) = '1') then -- no stable edge found within retry limit
                NROF_RETRIES((16*index)+15 downto 16*index)    <= retries;
                TAP_SETTING((10*index)+9 downto 10*index)      <= tapcount;
                i_fsm_align   <= S_IDLE;
            else
                RetryCntr  <= RetryCntr - '1';
                if (edge_int_or = '1') then             -- edge found, check stability
                    DATA_init       <= CTRL_DATA;       -- memorize data
                    edge_init       <= edge_int;        -- memorize data edges
                    start_handshake <= '1';
                    --do nothing
                    CTRL_RESET      <= '0';
                    CTRL_INC        <= '0';
                    CTRL_CE         <= '0';
                    i_fsm_align      <= S_WAIT_SAMPLE_STABLE;
                else
                    start_handshake <= '1';    -- no edge found but retrylimit not yet reached, increment tap and try again
                    if (Maxcount(Maxcount'high) = '1') then
                            retries         <= retries + '1';
                            RetryCntr       <= RetryCntr - '1';
                            tapcount        <= (others => '0');
                            CTRL_RESET      <= '1';
                            CTRL_INC        <= '0';
                            CTRL_CE         <= '0';
                            Maxcount        <= std_logic_vector(TO_UNSIGNED((TAP_COUNT_MAX-1),(Maxcount'high+1)));
                            i_fsm_align      <= S_RST_DELAY;
                    else
                            retries         <= retries + '1';
                            RetryCntr       <= RetryCntr - '1';
                            tapcount        <= tapcount + '1';
                            Maxcount        <= Maxcount - '1';
                            CTRL_RESET      <= '0';
                            CTRL_INC        <= '1';
                            CTRL_CE         <= '1';
                            i_fsm_align      <= S_GET_EDGE;
                    end if;
                end if;
            end if;

        when S_WAIT_SAMPLE_STABLE =>
            if (end_handshake = '1') then
                if (GenCntr(GenCntr'high) = '1') then  -- sampled x times the same edge data
                    STABLE_DETECT(index)   <= '1';
                    GenCntr                   <= std_logic_vector(TO_UNSIGNED((DATAWIDTH-1),(GenCntr'high+1)));      --recycle stablecounter for compare purposes
                    i_fsm_align                <= S_COMPARE_TRAINING;
                else
                   if (edge_init /= edge_int) then     -- data not the same, increment tab and try again
                        start_handshake <= '1';
                        retries               <= retries + '1';
                        RetryCntr             <= RetryCntr - '1';
                        if (Maxcount(Maxcount'high) = '1') then
                            tapcount              <= (others => '0');
                            CTRL_RESET            <= '1';
                            CTRL_INC              <= '0';
                            CTRL_CE               <= '0';
                            Maxcount              <= std_logic_vector(TO_UNSIGNED((TAP_COUNT_MAX-1),(Maxcount'high+1)));
                            i_fsm_align            <= S_RST_DELAY;
                        else
                            tapcount              <= tapcount + '1';
                            Maxcount              <= Maxcount - '1';
                            CTRL_RESET            <= '0';
                            CTRL_INC              <= '1';
                            CTRL_CE               <= '1';
                            GenCntr               <= StableCntrLoad;
                            i_fsm_align            <= S_GET_EDGE;
                        end if;
                    else
                        GenCntr               <= GenCntr - '1';
                        CTRL_RESET            <= '0';
                        CTRL_INC              <= '0';
                        CTRL_CE               <= '0';
                        start_handshake       <= '1';
                    end if;
                end if;
            end if;


        -- the data detected as 'stable' in the previous state should be the training word.
        -- therefore no new data is 'grabbed' from the serdes module

        when S_COMPARE_TRAINING =>
            if (GenCntr(GenCntr'high) = '1') then
               start_handshake       <= '1';
               if (Maxcount(Maxcount'high) = '1') then
                    tapcount              <= (others => '0');
                    CTRL_RESET            <= '1';
                    CTRL_INC              <= '0';
                    CTRL_CE               <= '0';
                    Maxcount              <= std_logic_vector(TO_UNSIGNED((TAP_COUNT_MAX-1),(Maxcount'high+1)));
                    i_fsm_align            <= S_RST_DELAY;
               else
                    retries               <= retries + '1';
                    RetryCntr             <= RetryCntr - '1';
                    tapcount              <= tapcount + '1';
                    Maxcount              <= Maxcount - '1';
                    CTRL_RESET            <= '0';
                    CTRL_INC              <= '1';
                    CTRL_CE               <= '1';
                    GenCntr               <= StableCntrLoad;
                    i_fsm_align            <= S_GET_EDGE;
              end if;
            else
                if (CTRL_DATA = compare(TO_INTEGER(UNSIGNED(GenCntr)))) then
                    TRAINING_DETECT(index)   <= '1';

                    if (GenCntr = DATAWIDTH-1) then
                        CTRL_SAMPLEINFIRSTBIT_i <= '0';
                        CTRL_SAMPLEINLASTBIT_i  <= '1';
                        CTRL_SAMPLEINOTHERBIT_i <= '0';
                    elsif (GenCntr = DATAWIDTH-2) then
                        CTRL_SAMPLEINFIRSTBIT_i <= '1';
                        CTRL_SAMPLEINLASTBIT_i  <= '0';
                        CTRL_SAMPLEINOTHERBIT_i <= '0';
                    else
                        CTRL_SAMPLEINFIRSTBIT_i <= '0';
                        CTRL_SAMPLEINLASTBIT_i  <= '0';
                        CTRL_SAMPLEINOTHERBIT_i <= '1';
                    end if;

                    i_fsm_align               <= S_VALID_BEGIN_FOUND;
                end if;
                GenCntr             <= GenCntr - '1';
            end if;

        when S_VALID_BEGIN_FOUND =>
            start_handshake <= '1';
            Maxcount        <= Maxcount - '1';
            tapcount        <= tapcount + '1';
            CTRL_RESET      <= '0';
            CTRL_INC        <= '1';
            CTRL_CE         <= '1';
            i_fsm_align      <= S_CHK_FIRST_EDGE_CHANGED;

        when S_CHK_FIRST_EDGE_CHANGED =>
            if (end_handshake = '1') then
                IF (
                    ((CTRL_DATA = STD_LOGIC_VECTOR(UNSIGNED(DATA_init) ROR 1)) and (INVERSE_BITORDER = FALSE)) or
                    ((CTRL_DATA = STD_LOGIC_VECTOR(UNSIGNED(DATA_init) ROL 1)) and (INVERSE_BITORDER = TRUE))
                        ) THEN  --edge found (1 time)
                    start_handshake <= '1';
                    CTRL_RESET      <= '0';
                    CTRL_INC        <= '0';
                    CTRL_CE         <= '0';
                    GenCntr         <= std_logic_vector(TO_UNSIGNED((STABLE_COUNT-1),(GenCntr'high+1)));
                    i_fsm_align      <= S_CHK_FIRST_EDGE_STABLE;
                else
                    start_handshake <= '1';
                    if (Maxcount(Maxcount'high) = '1') then
                        tapcount        <= (others => '0');
                        CTRL_RESET      <= '1';
                        CTRL_INC        <= '0';
                        CTRL_CE         <= '0';
                        Maxcount        <= std_logic_vector(TO_UNSIGNED((TAP_COUNT_MAX-1),(Maxcount'high+1)));
                        i_fsm_align      <= S_RST_DELAY;
                    else
                        Maxcount        <= Maxcount - '1';
                        tapcount        <= tapcount + '1';
                        CTRL_RESET      <= '0';
                        CTRL_INC        <= '1';
                        CTRL_CE         <= '1';
                    end if;
                end if;
            end if;

        when S_CHK_FIRST_EDGE_STABLE =>
            if (end_handshake = '1') then
                start_handshake             <= '1';
                if (GenCntr(GenCntr'high) = '1') then -- edge detected ok
                    windowcount                 <= windowcount + '1';
                    bitcount                    <= bitcount + '1';
                    tapcount                    <= tapcount + '1';
                    Maxcount                    <= Maxcount - '1';
                    CTRL_RESET                  <= '0';
                    CTRL_INC                    <= '1';
                    CTRL_CE                     <= '1';
                    FIRST_EDGE_FOUND(index)     <= '1';
                    i_fsm_align                  <= S_CHK_SECOND_EDGE_CHANGED;
                else
                    GenCntr                     <= GenCntr - '1';
                    IF (
                    ((CTRL_DATA = STD_LOGIC_VECTOR(UNSIGNED(DATA_init) ROR 1)) and (INVERSE_BITORDER = FALSE)) or
                    ((CTRL_DATA = STD_LOGIC_VECTOR(UNSIGNED(DATA_init) ROL 1)) and (INVERSE_BITORDER = TRUE))
                        ) THEN
                        CTRL_RESET          <= '0';
                        CTRL_INC            <= '0';
                        CTRL_CE             <= '0';
                    else -- edge changed during stability test
                        GenCntr             <= std_logic_vector(TO_UNSIGNED((STABLE_COUNT-1),(GenCntr'high+1)));
                        tapcount            <= tapcount + '1'; -- increment tapcount by one and try again
                        bitcount            <= bitcount + '1';
                        Maxcount            <= Maxcount - '1';
                        CTRL_RESET          <= '0';
                        CTRL_INC            <= '1';
                        CTRL_CE             <= '1';
                        i_fsm_align          <= S_CHK_FIRST_EDGE_CHANGED;
                    end if;
                end if;
            end if;

        when S_CHK_SECOND_EDGE_CHANGED =>
            if (end_handshake = '1') then
                IF (
                    ((CTRL_DATA = STD_LOGIC_VECTOR(UNSIGNED(DATA_init) ROR 2)) and (INVERSE_BITORDER = FALSE)) or
                    ((CTRL_DATA = STD_LOGIC_VECTOR(UNSIGNED(DATA_init) ROL 2)) and (INVERSE_BITORDER = TRUE))
                        ) THEN   -- 2nd edge found, window found
                    SECOND_EDGE_FOUND(index)                      <= '1';
                    WINDOW_WIDTH((10*index)+9 downto 10*index) <= windowcount;
                    BIT_WIDTH((10*index)+9 downto 10*index) <= bitcount;
                    GenCntr             <= ("0000000" & windowcount(9 downto 1)) - "10"; --divide by 2
                    start_handshake     <= '1';
                    tapcount            <= tapcount - '1';
                    CTRL_RESET          <= '0';
                    CTRL_INC            <= '0';
                    CTRL_CE             <= '1';
                    i_fsm_align          <= S_WINDOW_FOUND;
                else
                        start_handshake <= '1';
                        if (Maxcount(Maxcount'high) = '1') then  --overrun tapcount
                            CTRL_RESET      <= '1';
                            CTRL_INC        <= '0';
                            CTRL_CE         <= '0';
                            i_fsm_align   <= S_RST_DELAY;
                        else
                            windowcount     <= windowcount + '1';
                            bitcount        <= bitcount + '1';
                            Maxcount        <= Maxcount - '1';
                            tapcount        <= tapcount + '1';
                            CTRL_RESET      <= '0';
                            CTRL_INC        <= '1';
                            CTRL_CE         <= '1';
                        end if;
                end if;
            end if;

        when S_WINDOW_FOUND =>
            if (end_handshake = '1') then
                if (GenCntr(GenCntr'high) = '1') then
                   --TAP_SETTING((10*index)+9 downto 10*index)      <= tapcount;
                   i_fsm_align   <= S_START_WORD_ALIGN;
                else
                   start_handshake     <= '1';
                   tapcount            <= tapcount - '1';
                   GenCntr             <= GenCntr - '1';
                   CTRL_RESET          <= '0';
                   CTRL_INC            <= '0';
                   CTRL_CE             <= '1';
                end if;
            end if;

        when S_RST_DELAY_MAN =>
            if (end_handshake = '1') then
               if (GenCntr(GenCntr'high) = '1') then
                   i_fsm_align          <= S_START_WORD_ALIGN;
                   --TAP_SETTING((10*index)+9 downto 10*index)      <= tapcount;
               else
                   GenCntr             <= GenCntr - '1';
                   start_handshake     <= '1';
                   tapcount            <= tapcount + '1';
                   CTRL_RESET          <= '0';
                   CTRL_INC            <= '1';
                   CTRL_CE             <= '1';
               end if;
            end if;

-- wordalignment, can fail in manual tap mode, or when bitalign algorithm fails

        when S_START_WORD_ALIGN =>
            if (CTRL_DATA = TRAINING) then
                WORD_ALIGN(index)   <= '1';
                i_fsm_align          <= S_ALIGNMENT_DONE;
            else
                start_handshake     <= '1';
                GenCntr             <= std_logic_vector(TO_UNSIGNED((DATAWIDTH-2),(GenCntr'high+1)));
                CTRL_RESET          <= '0';
                CTRL_INC            <= '0';
                CTRL_CE             <= '0';
                CTRL_BITSLIP        <= '1';
                i_fsm_align          <= S_DO_WORD_ALIGN;
            end if;

        when S_DO_WORD_ALIGN =>
            if (end_handshake = '1') then
                if (CTRL_DATA = TRAINING) then
                    WORD_ALIGN(index)   <= '1';
                    i_fsm_align          <= S_ALIGNMENT_DONE;
                else
                    if (GenCntr(GenCntr'high) = '1') then --alignment failed
                        TAP_SETTING((10*index)+9 downto 10*index)      <= tapcount;
                        NROF_RETRIES((16*index)+15 downto 16*index)    <= retries;
                        i_fsm_align      <= S_IDLE;
                    else
                        start_handshake <= '1';
                        CTRL_BITSLIP    <= '1';
                        GenCntr             <= GenCntr - '1';
                    end if;
                end if;
            end if;

        when S_ALIGNMENT_DONE =>
            done_align_i        <= '1';
            CTRL_RESET          <= '0';
            CTRL_INC            <= '0';
            CTRL_CE             <= '0';
            CTRL_BITSLIP        <= '0';
            NROF_RETRIES((16*index)+15 downto 16*index)    <= retries;
            TAP_SETTING((10*index)+9 downto 10*index)      <= tapcount;
            i_fsm_align          <= S_IDLE;

        when others =>
            i_fsm_align   <= S_IDLE;

    end case;
end if;
end process;


end xilinx;




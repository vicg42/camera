-------------------------------------------------------------------------
-- Company     : Yansar
-- Engineer    : Golovachenko Victor
--
-- Create Date : 01.12.2014 12:24:34
-- Module Name : bridge_main
--
-------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.reduce_pack.all;
use work.vicg_common_pkg.all;
use work.clocks_pkg.all;

library unisim;
use unisim.vcomponents.all;

entity bridge_main is
port(
pin_in_rs232_rx     : in    std_logic;
pin_out_rs232_tx    : out   std_logic;

pin_in_rs485_rx     : in    std_logic;
pin_out_rs485_tx    : out   std_logic;
pin_out_rs485_dir   : out   std_logic;

--------------------------------------------------
--DBG
--------------------------------------------------
pin_out_TP2         : out   std_logic_vector(2 downto 2);
pin_out_led         : out   std_logic_vector(0 downto 0);
pin_out_TP          : out   std_logic;
pin_out_TP3         : out   std_logic;

--------------------------------------------------
--Reference clock
--------------------------------------------------
pin_in_refclk       : in    TRefclk_pinin
);
end entity bridge_main;

architecture behavioral of bridge_main is

component clocks is
generic(
G_VOUT_TYPE : string := "VGA"
);
port(
p_out_rst  : out   std_logic;
p_out_gclk : out   std_logic_vector(7 downto 0);

p_in_clk   : in    TRefclk_pinin
);
end component clocks;

component fpga_test_01
generic(
G_BLINK_T05   : integer:=10#125#; -- 1/2 периода мигани€ светодиода.(врем€ в ms)
G_CLK_T05us   : integer:=10#1000# -- кол-во периодов частоты порта p_in_clk
                                  -- укладывающиес_ в 1/2 периода 1us
);
port(
p_out_test_led : out   std_logic;--мигание сведодиода
p_out_test_done: out   std_logic;--сигнал переходи в '1' через 3 сек.

p_out_1us      : out   std_logic;
p_out_1ms      : out   std_logic;
-------------------------------
--System
-------------------------------
p_in_clk       : in    std_logic;
p_in_rst       : in    std_logic
);
end component fpga_test_01;

component uart_rx6 is
Port (
serial_in           : in  std_logic;
en_16_x_baud        : in  std_logic;
data_out            : out std_logic_vector(7 downto 0);
buffer_read         : in  std_logic;
buffer_data_present : out std_logic;
buffer_half_full    : out std_logic;
buffer_full         : out std_logic;
buffer_reset        : in  std_logic;
clk                 : in  std_logic
);
end component uart_rx6;

component uart_tx6 is
Port (
data_in             : in  std_logic_vector(7 downto 0);
en_16_x_baud        : in  std_logic;
serial_out          : out std_logic;
buffer_write        : in  std_logic;
buffer_data_present : out std_logic;
buffer_half_full    : out std_logic;
buffer_full         : out std_logic;
buffer_reset        : in  std_logic;
clk                 : in  std_logic
);
end component uart_tx6;

--1) The Сen_16_x_baudТ signal must therefore have a pulse rate of 16 x 19200 = 307200 pulses per second
--2) With a 200MHz clock this equates to one enable pulse every 200,000,000 / 307200 = 651,0416 clock cycles.

--G_BAUDCNT_VAL => 34 --for baudrate 115200; uart_refclk = 62MHz
--G_BAUDCNT_VAL => 201 --for baudrate 19200; uart_refclk = 62MHz
--G_BAUDCNT_VAL => 650 --for baudrate 19200; uart_refclk = 200MHz
constant CI_BAUD_COUNT : integer := 201;

type TSys is record
clk : std_logic;
rst : std_logic;
end record;
signal i_sys              : TSys;

signal g_usrclk           : std_logic_vector(7 downto 0);
signal i_test_led         : std_logic_vector(1 downto 0);

signal i_baud_count       : integer range 0 to CI_BAUD_COUNT := 0;
signal i_en_16_x_baud     : std_logic := '0';

signal i_rx232_rxd        : std_logic_vector(7 downto 0);
signal i_rs232_rxd_rd     : std_logic;
signal i_rs232_rxrdy      : std_logic;
signal i_rx232_txd        : std_logic_vector(7 downto 0);
signal i_rs232_txd_wr     : std_logic;
signal i_rs232_txd_busy   : std_logic;

signal i_rx485_rxd        : std_logic_vector(7 downto 0);
signal i_rs485_rxd_rd     : std_logic;
signal i_rs485_rxrdy      : std_logic;
signal i_rx485_txd        : std_logic_vector(7 downto 0);
signal i_rs485_txd_wr     : std_logic;
signal i_rs485_txd_busy   : std_logic;

signal i_rs485_rxen       : std_logic;
signal i_rs485_rx         : std_logic;

type TFsm_RS232_rx is (
S_RS232_RD,
S_RS485_WR
);
signal i_fsm_RS232_rxcs   : TFsm_RS232_rx;

type TFsm_RS485_rx is (
S_RS485_RD,
S_RS232_WR
);
signal i_fsm_RS485_rxcs   : TFsm_RS485_rx;

signal i_rs485_dir       : std_logic;
signal i_timeout_cnt      : unsigned(15 downto 0);

signal i_1us              : std_logic;
signal i_tst              : std_logic_vector(1 downto 0);

attribute keep : string;
attribute keep of i_sys : signal is "true";

signal tst_rs232_txd_busy : std_logic;
signal tst_rs485_txd_busy : std_logic;
signal tst_rs232_rx       : std_logic;
signal tst_rs232_tx       : std_logic;
signal i_rs232_rx         : std_logic;
signal i_rs232_tx         : std_logic;
signal i_rs485_tx         : std_logic;
signal tst_rs485_rx       : std_logic;
signal tst_rs485_tx       : std_logic;
signal tst_rs232_rxrdy, tst_rs485_rxrdy : std_logic;
signal tst_timeout_en     : std_logic;
signal tst_timeout_en2    : std_logic;

begin --architecture behavioral


m_clocks : clocks
generic map(
G_VOUT_TYPE => "VGA"
)
port map(
p_out_rst  => i_sys.rst,
p_out_gclk => g_usrclk,

p_in_clk   => pin_in_refclk
);

i_sys.clk <= g_usrclk(7);

baud_rate : process(i_sys)
begin
if rising_edge(i_sys.clk) then
  if i_baud_count = CI_BAUD_COUNT then
    i_baud_count <= 0;
    i_en_16_x_baud <= '1';
  else
    i_baud_count <= i_baud_count + 1;
    i_en_16_x_baud <= '0';
  end if;
end if;
end process baud_rate;


----------------------------------------
--RS232 -> RS485
----------------------------------------
i_rs232_rx <= pin_in_rs232_rx;

m_rs232_rx : uart_rx6
port map(
serial_in           => i_rs232_rx,--pin_in_rs232_rx,
en_16_x_baud        => i_en_16_x_baud,
data_out            => i_rx232_rxd,
buffer_read         => i_rs232_rxd_rd,
buffer_data_present => i_rs232_rxrdy,
buffer_half_full    => open,
buffer_full         => open,
buffer_reset        => i_sys.rst,
clk                 => i_sys.clk
);

process(i_sys)
begin
if rising_edge(i_sys.clk) then
  if i_sys.rst = '1' then
    i_fsm_RS232_rxcs <= S_RS232_RD;
    i_rs232_rxd_rd <= '0';
    i_rx485_txd <= (others => '0');
    i_rs485_txd_wr <= '0';

    i_rs485_dir <= '0';
    i_timeout_cnt <= ( others => '0');

  else
    case i_fsm_RS232_rxcs is

      when S_RS232_RD   =>
        i_rs485_txd_wr <= '0';

        if i_rs232_rxrdy = '1' then
          i_rx485_txd <= i_rx232_rxd;
          i_rs232_rxd_rd <= '1';
          i_fsm_RS232_rxcs <= S_RS485_WR;
        end if;

      when S_RS485_WR =>
        i_rs232_rxd_rd <= '0';

        if i_rs485_txd_busy = '0' then
          i_rs485_txd_wr <= '1';
          i_fsm_RS232_rxcs <= S_RS232_RD;
        end if;

    end case;


    if i_rs485_txd_wr = '1'  then
      i_rs485_dir <= '1';--1/0 - Send/Receive
      i_timeout_cnt <= ( others => '0');

    elsif i_timeout_cnt > TO_UNSIGNED(600, i_timeout_cnt'length) then
      i_rs485_dir <= '0';
      i_timeout_cnt <= ( others => '0');

    elsif i_rs485_dir = '1' and i_1us = '1' then
      i_timeout_cnt <= i_timeout_cnt + 1;

    end if;

  end if;
end if;
end process;


m_rs485_tx : uart_tx6
port map(
data_in             => i_rx485_txd,
en_16_x_baud        => i_en_16_x_baud,
serial_out          => i_rs485_tx,--pin_out_rs485_tx,
buffer_write        => i_rs485_txd_wr,
buffer_data_present => i_rs485_txd_busy,
buffer_half_full    => open,
buffer_full         => open,
buffer_reset        => i_sys.rst,
clk                 => i_sys.clk
);
pin_out_rs485_tx <= i_rs485_tx;


process(i_sys)
begin
if rising_edge(i_sys.clk) then
  if i_sys.rst = '1' then

  else


  end if;
end if;
end process;

----------------------------------------
--RS232 <- RS485
----------------------------------------
pin_out_rs485_dir <= i_rs485_dir;--i_rs485_txd_busy;

--i_rs485_rxen <= not i_rs485_txd_busy;
--i_rs485_rx <= i_rs485_rxen and pin_in_rs485_rx;

i_rs485_rx <= pin_in_rs485_rx and not i_rs485_dir;

m_rs485_rx : uart_rx6
port map(
serial_in           => i_rs485_rx,
en_16_x_baud        => i_en_16_x_baud,
data_out            => i_rx485_rxd,
buffer_read         => i_rs485_rxd_rd,
buffer_data_present => i_rs485_rxrdy,
buffer_half_full    => open,
buffer_full         => open,
buffer_reset        => i_sys.rst,
clk                 => i_sys.clk
);

process(i_sys)
begin
if rising_edge(i_sys.clk) then
  if i_sys.rst = '1' then
    i_fsm_RS485_rxcs <= S_RS485_RD;
    i_rs485_rxd_rd <= '0';
    i_rx232_txd <= (others => '0');
    i_rs232_txd_wr <= '0';
  else
    case i_fsm_RS485_rxcs is

      when S_RS485_RD   =>
        i_rs232_txd_wr <= '0';

        if i_rs485_rxrdy = '1' then
          i_rx232_txd <= i_rx485_rxd;
          i_rs485_rxd_rd <= '1';
          i_fsm_RS485_rxcs <= S_RS232_WR;
        end if;

      when S_RS232_WR =>
        i_rs485_rxd_rd <= '0';

        if i_rs232_txd_busy = '0' then
          i_rs232_txd_wr <= '1';
          i_fsm_RS485_rxcs <= S_RS485_RD;
        end if;

    end case;
  end if;
end if;
end process;

m_rs232_tx : uart_tx6
port map(
data_in             => i_rx232_txd,
en_16_x_baud        => i_en_16_x_baud,
serial_out          => i_rs232_tx, --pin_out_rs232_tx,
buffer_write        => i_rs232_txd_wr,
buffer_data_present => i_rs232_txd_busy,
buffer_half_full    => open,
buffer_full         => open,
buffer_reset        => i_sys.rst,
clk                 => i_sys.clk
);

pin_out_rs232_tx <= i_rs232_tx;

--***********************************************************
--DBG
--***********************************************************
pin_out_led(0) <= i_test_led(0);


m_led1_tst: fpga_test_01
generic map(
G_BLINK_T05   =>10#250#,
G_CLK_T05us   =>10#31#
)
port map(
p_out_test_led => i_test_led(0),
p_out_test_done=> open,

p_out_1us      => i_1us,
p_out_1ms      => open,
-------------------------------
--System
-------------------------------
p_in_clk       => i_sys.clk,
p_in_rst       => i_sys.rst
);

pin_out_TP2(2) <= i_rs485_dir;
pin_out_TP3 <= i_rs485_tx;

pin_out_TP <= tst_rs232_txd_busy or tst_rs485_txd_busy
                  or tst_rs232_rx or tst_rs232_tx
                  or tst_rs232_rxrdy or tst_rs485_rxrdy
                  or tst_rs485_rx or tst_rs485_tx
                  or tst_timeout_en2;

process(i_sys)
begin
if rising_edge(i_sys.clk) then
  tst_rs232_txd_busy <= i_rs232_txd_busy;
  tst_rs485_txd_busy <= i_rs485_txd_busy;
  tst_rs232_rxrdy <= i_rs232_rxrdy;
  tst_rs485_rxrdy <= i_rs485_rxrdy;
  tst_rs232_rx <= i_rs232_rx;
  tst_rs232_tx <= i_rs232_tx;
  tst_rs485_rx <= i_rs485_rx;
  tst_rs485_tx <= i_rs485_tx;
  tst_timeout_en <= i_rs485_dir;
  tst_timeout_en2 <= not i_rs485_dir and tst_timeout_en;
end if;
end process;


end architecture behavioral;


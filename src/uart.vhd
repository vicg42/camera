-------------------------------------------------------------------------
-- Company     : Yansar
-- Engineer    : Golovachenko Victor
--
-- Create Date : 05.01.2015 10:04:07
-- Module Name : uart
--
-------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart is
generic(
G_BAUDCNT_VAL: integer:=64 --G_BAUDCNT_VAL = Fuart_refclk/(16 * UART_BAUDRATE)
                           --Например: FFuart_refclk=40MHz, UART_BAUDRATE=115200
                           --
                           -- 40000000/(16 *115200)=21,701 - округляем до ближайшего цеого, т.е = 22
);
port(
-------------------------------
--UART
-------------------------------
p_out_uart_tx    : out   std_logic;
p_in_uart_rx     : in    std_logic;

-------------------------------
--USR IF
-------------------------------
p_out_usr_rxd    : out   std_logic_vector(7 downto 0);
p_out_usr_rxrdy  : out   std_logic;
p_in_usr_rd      : in    std_logic;

p_in_usr_txd     : in    std_logic_vector(7 downto 0);
p_out_usr_txrdy  : out   std_logic;
p_in_usr_wr      : in    std_logic;

-------------------------------
--DBG
-------------------------------
p_in_tst         : in    std_logic_vector(31 downto 0);
p_out_tst        : out   std_logic_vector(31 downto 0);

-------------------------------
--System
-------------------------------
p_in_clk         : in    std_logic;
p_in_rst         : in    std_logic
);
end entity uart;

architecture behavioral of uart is

component uart_rx6 is
  port (           serial_in : in std_logic;
                en_16_x_baud : in std_logic;
                    data_out : out std_logic_vector(7 downto 0);
                 buffer_read : in std_logic;
         buffer_data_present : out std_logic;
            buffer_half_full : out std_logic;
                 buffer_full : out std_logic;
                buffer_reset : in std_logic;
                         clk : in std_logic);
  end component;

component uart_tx6 is
  port (             data_in : in std_logic_vector(7 downto 0);
                en_16_x_baud : in std_logic;
                  serial_out : out std_logic;
                buffer_write : in std_logic;
         buffer_data_present : out std_logic;
            buffer_half_full : out std_logic;
                 buffer_full : out std_logic;
                buffer_reset : in std_logic;
                         clk : in std_logic);
  end component;

signal i_en_16_x_baud         : std_logic;
signal i_baud_cnt             : integer range 0 to (G_BAUDCNT_VAL) := 0;
signal i_txbuf_hfull          : std_logic;
signal i_usr_rxrdy            : std_logic;
signal sr_usr_rxrdy           : std_logic_vector(0 to 1) := (others => '0');
signal i_buffer_data_present  : std_logic;
signal i_uart_txd             : std_logic_vector(p_in_usr_txd'range);
signal i_uart_txd_wr          : std_logic;

type fsm_state is (
S_TX_IDLE,
S_TX_SOF_WAIT,
S_TX_EOF_WAIT
);
signal fsm_state_cs           : fsm_state;
signal tst_buffer_data_present: std_logic;

begin --architecture behavioral


process(p_in_clk)
begin
if rising_edge(p_in_clk) then
  if i_baud_cnt = (G_BAUDCNT_VAL) then
    i_en_16_x_baud <= '1';
    i_baud_cnt <= 0;
  else
    i_en_16_x_baud <= '0';
    i_baud_cnt <= i_baud_cnt + 1;
  end if;
end if;
end process;


m_rx : uart_rx6
port map(
serial_in           => p_in_uart_rx,
en_16_x_baud        => i_en_16_x_baud,
data_out            => p_out_usr_rxd,
buffer_read         => p_in_usr_rd,
buffer_data_present => i_usr_rxrdy,
buffer_half_full    => open,
buffer_full         => open,
buffer_reset        => p_in_rst,
clk                 => p_in_clk
);

process(p_in_clk)
begin
if rising_edge(p_in_clk) then
  sr_usr_rxrdy <= i_usr_rxrdy & sr_usr_rxrdy(0 to 0);
  p_out_usr_rxrdy <= sr_usr_rxrdy(0) and not sr_usr_rxrdy(1);
end if;
end process;

process(p_in_rst, p_in_clk)
begin
if rising_edge(p_in_clk) then
  if p_in_rst = '1' then
    fsm_state_cs <= S_TX_IDLE;
    i_txbuf_hfull <= '0';
    i_uart_txd <= (others => '0');
    i_uart_txd_wr <= '0';
  else
    case fsm_state_cs is
      when S_TX_IDLE   =>
        if p_in_usr_wr = '1' then
          i_uart_txd <= p_in_usr_txd;
          i_uart_txd_wr <= '1';
          i_txbuf_hfull <= '1';
          fsm_state_cs <= S_TX_SOF_WAIT;
        end if;

      when S_TX_SOF_WAIT =>
        i_uart_txd_wr <= '0';

        if i_buffer_data_present = '1' then
          fsm_state_cs <= S_TX_EOF_WAIT;
        end if;

      when S_TX_EOF_WAIT =>
        if i_buffer_data_present = '0' then
          i_txbuf_hfull <= '0';
          fsm_state_cs <= S_TX_IDLE;
        end if;
    end case;
  end if;
end if;
end process;


m_tx : uart_tx6
port map(
data_in             => i_uart_txd,
en_16_x_baud        => i_en_16_x_baud,
serial_out          => p_out_uart_tx,
buffer_write        => i_uart_txd_wr,
buffer_data_present => i_buffer_data_present,
buffer_half_full    => open,
buffer_full         => open,
buffer_reset        => p_in_rst,
clk                 => p_in_clk
);

p_out_usr_txrdy <= i_txbuf_hfull;


------------------------------------
--DBG
------------------------------------
p_out_tst(31 downto 1) <= (others => '0');
p_out_tst(0) <= tst_buffer_data_present;

process(p_in_clk)
begin
if rising_edge(p_in_clk) then
  tst_buffer_data_present <= i_buffer_data_present;
end if;
end process;

end architecture behavioral;

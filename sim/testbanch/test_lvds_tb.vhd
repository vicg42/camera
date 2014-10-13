library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

entity test_lvds_tb is
generic(
G_BIT_COUNT : integer := 10
);
port(
p_out_tst    : out std_logic_vector(31 downto 0);
p_out_data   : out std_logic_vector(G_BIT_COUNT - 1 downto 0);
p_out_align  : out std_logic
);
end test_lvds_tb;

architecture behavioral of test_lvds_tb is

constant CI_CLK_PERIOD : time    := 3.225 ns;--310MHz--10 ns; -- 100 MHz clk

component test_lvds_snd
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
end component test_lvds_snd;

component test_lvds_rcv
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
end component test_lvds_rcv;


signal i_sys_rst         : std_logic := '1';
signal i_sys_clk         : std_logic := '0';

signal i_usr_d           : unsigned(G_BIT_COUNT - 1 downto 0) := (others => '0');
signal i_usr_dclk        : std_logic := '0';
signal i_usr_dclken      : std_logic := '0';

signal i_snd_lvds_p      : std_logic_vector(0 downto 0);
signal i_snd_lvds_n      : std_logic_vector(0 downto 0);
signal i_snd_lvds_clk_p  : std_logic;
signal i_snd_lvds_clk_n  : std_logic;
signal i_rcv_lvds_p      : std_logic_vector(0 downto 0);
signal i_rcv_lvds_n      : std_logic_vector(0 downto 0);
signal i_rcv_lvds_clk_p  : std_logic;
signal i_rcv_lvds_clk_n  : std_logic;

signal i_align_start     : std_logic := '0';

type TFsm_send is (
S_IDLE          ,
S_SND_0         ,
S_SND_STABLE_0
--S_SND_1         ,
--S_SND_STABLE_1
);

signal i_fsm_send        : TFsm_send;
signal i_cntdly          : unsigned(31 downto 0) := (others => '0');

signal i_align_done_out  : std_logic;


begin

i_sys_rst <= '1', '0' after 1 us;

clk_gen : process
begin
wait for (CI_CLK_PERIOD / 2);
i_sys_clk <= not i_sys_clk;
end process;


p_out_align <= i_align_done_out;

m_snd : test_lvds_snd
generic map (
G_BIT_COUNT => G_BIT_COUNT
)
port map(
p_in_data         => std_logic_vector(i_usr_d),
p_out_dclk        => i_usr_dclk,
p_out_dclken      => i_usr_dclken,

p_out_lvds_data_p => i_snd_lvds_p,
p_out_lvds_data_n => i_snd_lvds_n,
p_out_lvds_clk_p  => i_snd_lvds_clk_p,
p_out_lvds_clk_n  => i_snd_lvds_clk_n,

p_in_sys_clk      => i_sys_clk,
p_in_sys_rst      => i_sys_rst
);


i_rcv_lvds_p <= transport i_snd_lvds_p after 0.750 ns;
i_rcv_lvds_n <= transport i_snd_lvds_n after 0.750 ns;

i_rcv_lvds_clk_p <= i_snd_lvds_clk_p;
i_rcv_lvds_clk_n <= i_snd_lvds_clk_n;


m_rcv : test_lvds_rcv
generic map (
G_BIT_COUNT => G_BIT_COUNT
)
port map(
p_in_align_start => i_align_start,
p_out_data       => p_out_data,
p_out_align      => i_align_done_out,

p_in_lvds_data_p => i_rcv_lvds_p,
p_in_lvds_data_n => i_rcv_lvds_n,
p_in_lvds_clk_p  => i_rcv_lvds_clk_p,
p_in_lvds_clk_n  => i_rcv_lvds_clk_n,

p_out_tst         => p_out_tst,
p_in_sys_clk      => i_sys_clk,
p_in_sys_rst      => i_sys_rst
);


process(i_sys_rst, i_usr_dclk)
begin
if rising_edge(i_usr_dclk) then
  if i_usr_dclken = '0' then
    i_usr_d <= (others => '0');
    i_fsm_send <= S_IDLE;
    i_cntdly <= (others => '0');

  else

    case i_fsm_send is

      when S_IDLE =>

          i_usr_d <= (others => '0');
          i_fsm_send <= S_SND_0;

      when S_SND_0 =>

--          if i_cntdly = TO_UNSIGNED(350, i_cntdly'length) then --OK
--          if i_cntdly = TO_UNSIGNED(503, i_cntdly'length) then
          if i_cntdly = TO_UNSIGNED(1003, i_cntdly'length) then
            i_cntdly <= (others => '0');
            i_usr_d <= TO_UNSIGNED(16#3A6#, i_usr_d'length);
            i_fsm_send <= S_SND_STABLE_0;
          else
            i_cntdly <= i_cntdly + 1;
            i_usr_d <= i_usr_d + 1;
          end if;

      when S_SND_STABLE_0 =>

--          if i_cntdly = TO_UNSIGNED(1024 * 11, i_cntdly'length) then
--            i_cntdly <= (others => '0');
            if i_align_done_out = '1' then
            i_fsm_send <= S_SND_0;
            else
            i_fsm_send <= S_SND_STABLE_0;
            end if;
--          else
--            i_cntdly <= i_cntdly + 1;
--          end if;
--

--      when S_SND_1 =>
--
--          if i_cntdly = TO_UNSIGNED(10, i_cntdly'length) then
--            i_cntdly <= (others => '0');
--            i_fsm_send <= S_SND_STABLE_1;
--          else
--            i_cntdly <= i_cntdly + 1;
--            i_usr_d <= i_usr_d + 1;
--          end if;
--
--      when S_SND_STABLE_1 =>
--
--          if i_cntdly = TO_UNSIGNED(5, i_cntdly'length) then
--            i_cntdly <= (others => '0');
--            i_fsm_send <= S_SND_0;
--          else
--            i_cntdly <= i_cntdly + 1;
--            i_usr_d <= i_usr_d + 1;
--          end if;

    end case;

  end if;
end if;
end process;




process
begin

i_align_start <= '0';

wait for 1.2 us;

wait until rising_edge(i_usr_dclk);
i_align_start <= '1';
wait until rising_edge(i_usr_dclk);
i_align_start <= '0';


wait until rising_edge(i_usr_dclk) and i_align_done_out = '1';
i_align_start <= '1';
wait until rising_edge(i_usr_dclk);
i_align_start <= '0';

wait;

end process;

end behavioral;


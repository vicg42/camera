library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;

library std;
use std.textio.all;

library work;
use work.all;

entity deser_lvds_ccd_tb is
end deser_lvds_ccd_tb;

architecture test of deser_lvds_ccd_tb is

component deser_lvds_ccd_exdes
generic (
  -- width of the data for the system
  sys_w      : integer := 16;
  -- width of the data for the device
  dev_w      : integer := 160
);
port (
  PATTERN_COMPLETED_OUT     : out   std_logic_vector (1 downto 0);
  -- From the system into the device
  DATA_IN_FROM_PINS_P      : in    std_logic_vector(sys_w-1 downto 0);
  DATA_IN_FROM_PINS_N      : in    std_logic_vector(sys_w-1 downto 0);
  DATA_OUT_TO_PINS_P         : out   std_logic_vector(sys_w-1 downto 0);
  DATA_OUT_TO_PINS_N         : out   std_logic_vector(sys_w-1 downto 0);
  CLK_TO_PINS_FWD_P         : out std_logic;
  CLK_TO_PINS_FWD_N         : out std_logic;

  CLK_IN_P                 : in    std_logic;
  CLK_IN_N                 : in    std_logic;
  CLK_IN_FWD_P             : in    std_logic;
  CLK_IN_FWD_N             : in    std_logic;
  DELAY_LOCKED             : out   std_logic;
  REF_CLOCK                : in    std_logic;
  CLK_RESET                : in    std_logic;
  IO_RESET                 : in    std_logic);
end component;
  constant clk_per         : time    := 3.225 ns;--310MHz--10 ns; -- 100 MHz clk
  constant sys_w           : integer := 16;
  constant dev_w           : integer := 160;
  constant num_serial_bits : integer := dev_w/sys_w;
  -- From the system into the device
  signal   data_in_from_pins_p : std_logic_vector(sys_w-1 downto 0);
  signal   data_in_from_pins_n : std_logic_vector(sys_w-1 downto 0);
  signal   data_out_to_pins_p : std_logic_vector(sys_w-1 downto 0);
  signal   data_out_to_pins_n : std_logic_vector(sys_w-1 downto 0);
  signal clk_in_fwd_p               : std_logic;
  signal clk_in_fwd_n               : std_logic;
  signal clk_to_pins_fwd_p          : std_logic;
  signal clk_to_pins_fwd_n          : std_logic;
  signal   clk_in             : std_logic := '0';
  signal   clk_in_p           : std_logic;
  signal   clk_in_n           : std_logic;
  signal   clk_reset          : std_logic;
  signal   io_reset           : std_logic;
  signal   pattern_completed_out : std_logic_vector (1 downto 0);
  signal   timeout_counter    : std_logic_vector (10 downto 0) := "00000000000";
  signal   bitslip_timeout : std_logic_vector (16 downto 0) := "00000000000000000";


begin

  -- Any aliases
   clk_in_p <= clk_in;
   clk_in_n <= not clk_in;

  -- clock generator- 100 MHz simulation clock
  --------------------------------------------
  process begin
    wait for (clk_per/2);
    clk_in <= not clk_in;
  end process;





  -- Test sequence
  process
    procedure simtimeprint is
      variable outline : line;
    begin
      write(outline, string'("## SYSTEM_CYCLE_COUNTER "));
      write(outline, NOW/clk_per);
      write(outline, string'(" ns"));
      writeline(output,outline);
    end simtimeprint;
  begin
   -- data_in_from_pins <= (others => '0');
    -- reset the logic
    clk_reset   <= '1';
    io_reset    <= '1';

    wait for (18*clk_per);
    clk_reset   <= '0';

    wait for (30*clk_per);
    io_reset    <= '0';
    wait;
  end process;

process (clk_in)
    procedure simtimeprint is
      variable outline : line;
    begin
      write(outline, string'("## SYSTEM_CYCLE_COUNTER "));
      write(outline, NOW/clk_per);
      write(outline, string'(" ns"));
      writeline(output,outline);
    end simtimeprint;
begin
    if (clk_in'event and clk_in = '1') then
    if (io_reset = '0') then
       timeout_counter <= timeout_counter + '1';
       if ((timeout_counter = "11111010000") and (pattern_completed_out = "00")) then
         simtimeprint;
         report "ERROR : SIMULATION TIMED OUT" severity failure;
       end if;
    end if;
    end if;
end process;


process (clk_in)
    procedure simtimeprint is
      variable outline : line;
    begin
      write(outline, string'("## SYSTEM_CYCLE_COUNTER "));
      write(outline, NOW/clk_per);
      write(outline, string'(" ns"));
      writeline(output,outline);
    end simtimeprint;
begin
    if (clk_in'event and clk_in = '1') then
    if (io_reset = '0') then
    if (pattern_completed_out = "00") then
       report "SIMULATION started" severity note;
    elsif (pattern_completed_out = "10") then
       simtimeprint;
       report "ERROR : SIMULATION FAILED. SERDES Design" severity failure;
    elsif (pattern_completed_out = "01") then
       bitslip_timeout <= bitslip_timeout + '1';
       if (bitslip_timeout = "11111111111111111") then
          simtimeprint;
          report "ERROR: TOO LONG A TIME FOR BITSLIP COMPLETION" severity failure;
       end if;
       report "SIMULATION in progress: BITSLIPS found, data checking in progress" severity note;
    elsif (pattern_completed_out = "11") then
       bitslip_timeout <= (others => '0');
       simtimeprint;
       report "Test Completed Successfully" severity note;
       report "SIMULATION STOPPED." severity failure;
    else
       simtimeprint;
       report "ERROR : unknown state. SERDES Design" severity failure;
    end if;
    end if;
    end if;
end process;

    data_in_from_pins_p <= transport data_out_to_pins_p after 0.750 ns;
    data_in_from_pins_n <= transport data_out_to_pins_n after 0.750 ns;

      clk_in_fwd_p  <=   clk_to_pins_fwd_p;
    clk_in_fwd_n  <=   clk_to_pins_fwd_n;


  -- Instantiation of the example design

  dut : deser_lvds_ccd_exdes
  generic map
  (
   sys_w => 16,
   dev_w => 160
   )
  port map
  (
   PATTERN_COMPLETED_OUT      => pattern_completed_out,
   -- From the system into the device
   DATA_IN_FROM_PINS_P       => data_in_from_pins_p,
   DATA_IN_FROM_PINS_N       => data_in_from_pins_n,
   DATA_OUT_TO_PINS_P        => data_out_to_pins_p,
   DATA_OUT_TO_PINS_N        => data_out_to_pins_n,
   CLK_TO_PINS_FWD_P         => clk_to_pins_fwd_p,
   CLK_TO_PINS_FWD_N         => clk_to_pins_fwd_n,
   CLK_IN_FWD_P              => clk_in_fwd_p,
   CLK_IN_FWD_N              => clk_in_fwd_n,
   CLK_IN_P                  => clk_in_p,
   CLK_IN_N                  => clk_in_n,
    DELAY_LOCKED            => open,
    REF_CLOCK               => clk_in,
   CLK_RESET                 => clk_reset,
   IO_RESET                  => io_reset);
end test;


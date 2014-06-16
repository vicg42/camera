library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_misc.and_reduce;

library unisim;
use unisim.vcomponents.all;

library work;
use work.ccd_vita25K_pkg.all;
use work.prj_cfg.all;

entity deser_lvds_ccd_exdes is
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
end deser_lvds_ccd_exdes;

architecture xilinx of deser_lvds_ccd_exdes is

signal p_in_ccd   : TCCD_PortIN;

component ccd_vita25K is
port(
p_in_ccd   : in   TCCD_PortIN;
p_out_ccd  : out  TCCD_PortOUT;

p_out_video_vs  : out std_logic;
p_out_video_hs  : out std_logic;
p_out_video_den : out std_logic;
p_out_video_d   : out std_logic_vector((C_PCFG_CCD_LVDS_COUNT
                                          * C_PCFG_CCD_BIT_PER_PIXEL) - 1 downto 0);
p_out_video_clk : out std_logic;

p_in_refclk : in   std_logic;
p_in_ccdclk : in   std_logic;
p_in_rst    : in   std_logic
);
end component;

component deser_lvds_ccd is
generic
 (-- width of the data for the system
  sys_w       : integer := 16;
  -- width of the data for the device
  dev_w       : integer := 160);
port
 (
  -- From the system into the device
  DATA_IN_FROM_PINS_P     : in    std_logic_vector(sys_w-1 downto 0);
  DATA_IN_FROM_PINS_N     : in    std_logic_vector(sys_w-1 downto 0);
  DATA_IN_TO_DEVICE       : out   std_logic_vector(dev_w-1 downto 0);

-- Input, Output delay control signals
  IN_DELAY_RESET          : in    std_logic;                    -- Active high synchronous reset for input delay
  IN_DELAY_DATA_CE        : in    std_logic_vector(sys_w -1 downto 0);                    -- Enable signal for delay
  IN_DELAY_DATA_INC       : in    std_logic_vector(sys_w -1 downto 0);                    -- Delay increment (high), decrement (low) signal
  IN_DELAY_TAP_IN         : in    std_logic_vector(5*sys_w -1 downto 0); -- Dynamically loadable delay tap value for input delay
  IN_DELAY_TAP_OUT        : out   std_logic_vector(5*sys_w -1 downto 0); -- Delay tap value for monitoring input delay
  DELAY_LOCKED            : out   std_logic;                    -- Locked signal from IDELAYCTRL
  REF_CLOCK               : in    std_logic;                    -- Reference Clock for IDELAYCTRL. Has to come from BUFG.
  BITSLIP                 : in    std_logic;                    -- Bitslip module is enabled in NETWORKING mode
                                                                -- User should tie it to '0' if not needed

MMCM_LOCKED             : out   std_logic;
CLK_IN_CCD              : in    std_logic;

-- Clock and reset signals
CLK_OUT_P               : out   std_logic;                    -- Differential fast clock from IOB
CLK_OUT_N               : out   std_logic;
  CLK_IN_P                : in    std_logic;                    -- Differential fast clock from IOB
  CLK_IN_N                : in    std_logic;
  CLK_DIV_OUT             : out   std_logic;                    -- Slow clock output
  CLK_RESET               : in    std_logic;                    -- Reset signal for Clock circuit
  IO_RESET                : in    std_logic);                   -- Reset signal for IO circuit
end component;

   constant num_serial_bits  : integer := dev_w/sys_w;
   signal unused             : std_logic;
   signal clkin1             : std_logic;
   signal count_out          : std_logic_vector (num_serial_bits-1 downto 0);
   signal local_counter      : std_logic_vector(num_serial_bits-1 downto 0);
   signal count_out1         : std_logic_vector (num_serial_bits-1 downto 0);
   signal count_out2         : std_logic_vector (num_serial_bits-1 downto 0); signal usr_cnt : std_logic_vector (9 downto 0);
   signal pat_out            : std_logic_vector (num_serial_bits-1 downto 0); signal equal_cnt : std_logic_vector (2 downto 0);
   signal pattern_completed    : std_logic_vector (1 downto 0) := "00";
   signal clk_in_int_inv       : std_logic;
   -- This example design doesn't use the variable delay programming
   signal delay_busy           : std_logic;
   signal delay_clk            : std_logic := '0';
   signal delay_data_cal       : std_logic := '0';
   signal delay_data_ce        : std_logic := '0';
   signal delay_reset          : std_logic := '0';
   signal delay_data_inc       : std_logic := '0';
   signal delay_tap_in         : std_logic_vector (4 downto 0) := "00000";
            -- connection between ram and io circuit
   signal data_in_to_device         : std_logic_vector(dev_w-1 downto 0);
   signal data_in_to_device_int2    : std_logic_vector(dev_w-1 downto 0);
   signal data_in_to_device_int3    : std_logic_vector(dev_w-1 downto 0);

   signal data_out_from_device : std_logic_vector(dev_w-1 downto 0);

--   type serdarr is array (0 to 13) of std_logic_vector(sys_w-1 downto 0);
   type serdarr is array (0 to sys_w-1) of std_logic_vector(13 downto 0);
   signal oserdes_d                : serdarr := (( others => (others => '0')));
   signal ocascade_ms_d            : std_logic_vector(sys_w-1 downto 0);
   signal ocascade_ms_t            : std_logic_vector(sys_w-1 downto 0);
   signal ocascade_sm_d            : std_logic_vector(sys_w-1 downto 0);
   signal ocascade_sm_t            : std_logic_vector(sys_w-1 downto 0);
   signal serdesstrobe             : std_logic;

   signal data_out_from_device_q    : std_logic_vector(dev_w-1 downto 0) ;
   signal data_out_to_pins_int      : std_logic_vector(sys_w-1 downto 0);
   signal data_out_to_pins_predelay : std_logic_vector(sys_w-1 downto 0);
   constant clock_enable            : std_logic := '1';

   signal clk_div_out          : std_logic;
   signal ref_clk_int         : std_logic;
   signal clk_fwd_out          : std_logic;
   signal clk_fwd_int          : std_logic;
   signal clk_in_pll           : std_logic;
   signal clk_div_in_int       : std_logic;
   signal clk_div_in           : std_logic;
   signal locked               : std_logic;
--   signal clkin1             : std_logic;
  -- Output clock buffering / unused connectors
   signal clkfbout             : std_logic;
   signal clkfbout_buf         : std_logic;
   signal clkfboutb_unused     : std_logic;
   signal clkout0              : std_logic;
   signal clkout0b_unused      : std_logic;
   signal clkout1          : std_logic;
   signal clkout1b_unused  : std_logic;
   signal clkout2_unused   : std_logic;
   signal clkout2b_unused  : std_logic;
   signal clkout3_unused   : std_logic;
   signal clkout3b_unused  : std_logic;
   signal clkout4_unused   : std_logic;
   signal clkout5_unused   : std_logic;
   signal clkout6_unused   : std_logic;
  -- Dynamic programming unused signals
   signal do_unused        : std_logic_vector(15 downto 0);
   signal drdy_unused      : std_logic;
  -- Dynamic phase shift unused signals
   signal psdone_unused    : std_logic;
  -- Unused status signals
   signal clkfbstopped_unused : std_logic;
   signal clkinstopped_unused : std_logic;
   signal rst_sync      : std_logic;
   signal rst_sync_int  : std_logic;
   signal rst_sync_int1 : std_logic;
   signal rst_sync_int2 : std_logic;
   signal rst_sync_int3 : std_logic;
   signal rst_sync_int4 : std_logic;
   signal rst_sync_int5 : std_logic;
   signal rst_sync_int6 : std_logic;
   signal rst_sync_d      : std_logic;
   signal rst_sync_int_d  : std_logic;
   signal rst_sync_int1_d : std_logic;
   signal rst_sync_int2_d : std_logic;
   signal rst_sync_int3_d : std_logic;
   signal rst_sync_int4_d : std_logic;
   signal rst_sync_int5_d : std_logic;
   signal rst_sync_int6_d : std_logic;
   signal bitslip       : std_logic := '0';
   signal bitslip_int   : std_logic := '0';
   signal equal         : std_logic := '0';
   signal equal1        : std_logic := '0';
   signal count_out3    : std_logic_vector(2 downto 0);
   signal start_count   : std_logic := '0';
   signal start_check   : std_logic := '0';
   signal bit_count     : std_logic_vector (2 downto 0);
   type delay_arr is array (0 to sys_w -1) of std_logic_vector(num_serial_bits-1 downto 0);
   signal data_delay_int1 : delay_arr;
   signal data_delay_int2 : delay_arr;
   signal data_delay     : delay_arr;
   signal slave_shiftout          : std_logic_vector(sys_w-1 downto 0);

   attribute KEEP : string;
   attribute KEEP of clk_div_in_int : signal is "TRUE";
   attribute KEEP of clk_div_out : signal is "TRUE";



begin

   process (clk_div_out, IO_RESET) begin
     if (IO_RESET = '1') then
       rst_sync <= '1';
       rst_sync_int <= '1';
       rst_sync_int1 <= '1';
       rst_sync_int2 <= '1';
       rst_sync_int3 <= '1';
       rst_sync_int4 <= '1';
       rst_sync_int5 <= '1';
       rst_sync_int6 <= '1';
     elsif (clk_div_out = '1' and clk_div_out'event) then
       rst_sync <= '0';
       rst_sync_int <= rst_sync;
       rst_sync_int1 <= rst_sync_int;
       rst_sync_int2 <= rst_sync_int1;
       rst_sync_int3 <= rst_sync_int2;
       rst_sync_int4 <= rst_sync_int3;
       rst_sync_int5 <= rst_sync_int4;
       rst_sync_int6 <= rst_sync_int5;
     end if;
   end process;

   process (clk_div_in, IO_RESET) begin
     if (IO_RESET = '1') then
       rst_sync_d <= '1';
       rst_sync_int_d <= '1';
       rst_sync_int1_d <= '1';
       rst_sync_int2_d <= '1';
       rst_sync_int3_d <= '1';
       rst_sync_int4_d <= '1';
       rst_sync_int5_d <= '1';
       rst_sync_int6_d <= '1';
     elsif (clk_div_in = '1' and clk_div_in'event) then
       rst_sync_d <= '0';
       rst_sync_int_d <= rst_sync_d;
       rst_sync_int1_d <= rst_sync_int_d;
       rst_sync_int2_d <= rst_sync_int1_d;
       rst_sync_int3_d <= rst_sync_int2_d;
       rst_sync_int4_d <= rst_sync_int3_d;
       rst_sync_int5_d <= rst_sync_int4_d;
       rst_sync_int6_d <= rst_sync_int5_d;
     end if;
   end process;

   delay_clk <= clk_div_out;


   clkin_in_buf : IBUFGDS
    port map
      (O  => clkin1,
       I  => CLK_IN_P,
       IB => CLK_IN_N);

  mmcm_adv_inst : MMCME2_ADV
  generic map
   (BANDWIDTH            => "OPTIMIZED",
    CLKOUT4_CASCADE      => FALSE,
    COMPENSATION         => "ZHOLD",
    STARTUP_WAIT         => FALSE,
    DIVCLK_DIVIDE        => 1,
    CLKFBOUT_PHASE       => 0.000,
    CLKFBOUT_USE_FINE_PS => FALSE,
    CLKIN1_PERIOD        => 3.225,--10.0,             --
    CLKFBOUT_MULT_F      => 2.000,--10.000,           --
    CLKOUT0_DIVIDE_F     => 2.000,--10.000,           --
    CLKOUT1_DIVIDE       => 10,   --5*num_serial_bits,--
    CLKOUT0_PHASE        => 0.000,
    CLKOUT0_DUTY_CYCLE   => 0.500,
    CLKOUT0_USE_FINE_PS  => FALSE,
    CLKOUT1_PHASE        => 0.000,
    CLKOUT1_DUTY_CYCLE   => 0.500,
--    CLKOUT1_DIVIDE       => 10,
--    CLKOUT1_PHASE        => 0.000,
--    CLKOUT1_DUTY_CYCLE   => 0.500,
    CLKOUT1_USE_FINE_PS  => FALSE,
    REF_JITTER1          => 0.010)
  port map
    -- Output clocks
   (CLKFBOUT            => clkfbout,
    CLKFBOUTB           => clkfboutb_unused,
    CLKOUT0             => clkout0,
    CLKOUT0B            => clkout0b_unused,
    CLKOUT1             => clk_div_in_int,
    CLKOUT1B            => clkout1b_unused,
    CLKOUT2             => clkout2_unused,
    CLKOUT2B            => clkout2b_unused,
    CLKOUT3             => clkout3_unused,
    CLKOUT3B            => clkout3b_unused,
    CLKOUT4             => clkout4_unused,
    CLKOUT5             => clkout5_unused,
    CLKOUT6             => clkout6_unused,
    -- Input clock control
    CLKFBIN             => clkfbout_buf,
    CLKIN1              => clkin1,
    CLKIN2              => '0',
    -- Tied to always select the primary input clock
    CLKINSEL            => '1',
    -- Ports for dynamic reconfiguration
    DADDR               => (others => '0'),
    DCLK                => '0',
    DEN                 => '0',
    DI                  => (others => '0'),
    DO                  => do_unused,
    DRDY                => drdy_unused,
    DWE                 => '0',
    -- Ports for dynamic phase shift
    PSCLK               => '0',
    PSEN                => '0',
    PSINCDEC            => '0',
    PSDONE              => psdone_unused,
    -- Other control and status signals
    LOCKED              => locked,
    CLKINSTOPPED        => clkinstopped_unused,
    CLKFBSTOPPED        => clkfbstopped_unused,
    PWRDWN              => '0',
    RST                 => CLK_RESET);


  -- Output buffering
  -------------------------------------
   clkf_buf : BUFG
    port map
      (O => clkfbout_buf,
       I => clkfbout);


   clkout1_buf : BUFG
    port map
      (O   => clk_in_pll,
       I   => clkout0);

   clkout2_buf : BUFG
    port map
      (O   => clk_div_in,
       I   => clk_div_in_int);

   refclk_in : IBUFG
    port map
      (O => ref_clk_int,
       I => REF_CLOCK);


   process(clk_div_in) begin
   if (clk_div_in='1' and clk_div_in'event) then
     if (rst_sync_int6_d = '1') then
       equal1 <= '0';
     else
       if (count_out3 = "100") then
          equal1 <= equal;
       else
          equal1 <= equal1;
       end if;
     end if;
    end if;
   end process;


   process(clk_div_in) begin
   if (clk_div_in='1' and clk_div_in'event) then
     if (rst_sync_int6_d = '1') then
       count_out3 <= (others => '0');
     elsif (equal = '1' and count_out3 < "100" ) then
       count_out3 <= count_out3 + 1;
     else
       count_out3 <= (others => '0');
     end if;
    end if;
   end process;

   process(clk_div_in) begin
   if (clk_div_in='1' and clk_div_in'event) then
     if (rst_sync_int6_d = '1') then
       count_out1 <= (others => '0');
       pat_out <= "1011010011";
       count_out1 <= (others => '0');
     elsif locked='1' then
     if equal1='0' then
      pat_out <= "1011010011";
       count_out1 <= (others => '0');
    else
       count_out1 <= count_out1 + 1;
     end if;
    end if;
   end if;
  end process;


process(clk_div_in)
begin
if (clk_div_in='1' and clk_div_in'event) then
  if (rst_sync_int6_d = '1') then
    usr_cnt <= (others=>'0');
  else
    if usr_cnt(9) /= '1' then
    usr_cnt <= usr_cnt + 1;
    end if;
  end if;
end if;
end process;

   process(clk_div_in) begin
   if (clk_div_in='1' and clk_div_in'event) then
     if (rst_sync_int6_d = '1') then
       count_out2 <= (others => '0');
     elsif equal1='1' then
       count_out2 <= count_out1;
     else
        if usr_cnt(9) /= '1' then
          count_out2 <= usr_cnt(count_out2'range);
        else
       count_out2 <= pat_out;
       end if;
     end if;
    end if;
   end process;

   process(clk_div_in) begin
   if (clk_div_in='1' and clk_div_in'event) then
     if (rst_sync_int6_d = '1') then
       count_out <= (others => '0');
     else
       count_out <= count_out2;
     end if;
    end if;
   end process;



pinsss:for pin_count in 0 to sys_w-1 generate begin
   data_out_from_device(((pin_count + 1) * num_serial_bits) - 1 downto (pin_count * num_serial_bits)) <= count_out;
end generate pinsss;

gen_dout : for lvds_ch in 0 to sys_w - 1 generate begin
data_delay(lvds_ch) <= data_in_to_device(((lvds_ch + 1) * num_serial_bits) - 1 downto (lvds_ch * num_serial_bits));
--DATA_IN_TO_DEVICE((lvds_ch * C_BITCOUNT) + bitnum) <= i_deser_d(lvds_ch)(bitnum);
end generate gen_dout;

--   data_delay(0) <=                 data_in_to_device(144) &
--                data_in_to_device(128) &
--                data_in_to_device(112) &
--                data_in_to_device(96) &
--                data_in_to_device(80) &
--                data_in_to_device(64) &
--                data_in_to_device(48) &
--                data_in_to_device(32) &
--                data_in_to_device(16) &
--   data_in_to_device(0);
--   data_delay(1) <=                 data_in_to_device(145) &
--                data_in_to_device(129) &
--                data_in_to_device(113) &
--                data_in_to_device(97) &
--                data_in_to_device(81) &
--                data_in_to_device(65) &
--                data_in_to_device(49) &
--                data_in_to_device(33) &
--                data_in_to_device(17) &
--   data_in_to_device(1);
--   data_delay(2) <=                 data_in_to_device(146) &
--                data_in_to_device(130) &
--                data_in_to_device(114) &
--                data_in_to_device(98) &
--                data_in_to_device(82) &
--                data_in_to_device(66) &
--                data_in_to_device(50) &
--                data_in_to_device(34) &
--                data_in_to_device(18) &
--   data_in_to_device(2);
--   data_delay(3) <=                 data_in_to_device(147) &
--                data_in_to_device(131) &
--                data_in_to_device(115) &
--                data_in_to_device(99) &
--                data_in_to_device(83) &
--                data_in_to_device(67) &
--                data_in_to_device(51) &
--                data_in_to_device(35) &
--                data_in_to_device(19) &
--   data_in_to_device(3);
--   data_delay(4) <=                 data_in_to_device(148) &
--                data_in_to_device(132) &
--                data_in_to_device(116) &
--                data_in_to_device(100) &
--                data_in_to_device(84) &
--                data_in_to_device(68) &
--                data_in_to_device(52) &
--                data_in_to_device(36) &
--                data_in_to_device(20) &
--   data_in_to_device(4);
--   data_delay(5) <=                 data_in_to_device(149) &
--                data_in_to_device(133) &
--                data_in_to_device(117) &
--                data_in_to_device(101) &
--                data_in_to_device(85) &
--                data_in_to_device(69) &
--                data_in_to_device(53) &
--                data_in_to_device(37) &
--                data_in_to_device(21) &
--   data_in_to_device(5);
--   data_delay(6) <=                 data_in_to_device(150) &
--                data_in_to_device(134) &
--                data_in_to_device(118) &
--                data_in_to_device(102) &
--                data_in_to_device(86) &
--                data_in_to_device(70) &
--                data_in_to_device(54) &
--                data_in_to_device(38) &
--                data_in_to_device(22) &
--   data_in_to_device(6);
--   data_delay(7) <=                 data_in_to_device(151) &
--                data_in_to_device(135) &
--                data_in_to_device(119) &
--                data_in_to_device(103) &
--                data_in_to_device(87) &
--                data_in_to_device(71) &
--                data_in_to_device(55) &
--                data_in_to_device(39) &
--                data_in_to_device(23) &
--   data_in_to_device(7);
--   data_delay(8) <=                 data_in_to_device(152) &
--                data_in_to_device(136) &
--                data_in_to_device(120) &
--                data_in_to_device(104) &
--                data_in_to_device(88) &
--                data_in_to_device(72) &
--                data_in_to_device(56) &
--                data_in_to_device(40) &
--                data_in_to_device(24) &
--   data_in_to_device(8);
--   data_delay(9) <=                 data_in_to_device(153) &
--                data_in_to_device(137) &
--                data_in_to_device(121) &
--                data_in_to_device(105) &
--                data_in_to_device(89) &
--                data_in_to_device(73) &
--                data_in_to_device(57) &
--                data_in_to_device(41) &
--                data_in_to_device(25) &
--   data_in_to_device(9);
--   data_delay(10) <=                 data_in_to_device(154) &
--                data_in_to_device(138) &
--                data_in_to_device(122) &
--                data_in_to_device(106) &
--                data_in_to_device(90) &
--                data_in_to_device(74) &
--                data_in_to_device(58) &
--                data_in_to_device(42) &
--                data_in_to_device(26) &
--   data_in_to_device(10);
--   data_delay(11) <=                 data_in_to_device(155) &
--                data_in_to_device(139) &
--                data_in_to_device(123) &
--                data_in_to_device(107) &
--                data_in_to_device(91) &
--                data_in_to_device(75) &
--                data_in_to_device(59) &
--                data_in_to_device(43) &
--                data_in_to_device(27) &
--   data_in_to_device(11);
--   data_delay(12) <=                 data_in_to_device(156) &
--                data_in_to_device(140) &
--                data_in_to_device(124) &
--                data_in_to_device(108) &
--                data_in_to_device(92) &
--                data_in_to_device(76) &
--                data_in_to_device(60) &
--                data_in_to_device(44) &
--                data_in_to_device(28) &
--   data_in_to_device(12);
--   data_delay(13) <=                 data_in_to_device(157) &
--                data_in_to_device(141) &
--                data_in_to_device(125) &
--                data_in_to_device(109) &
--                data_in_to_device(93) &
--                data_in_to_device(77) &
--                data_in_to_device(61) &
--                data_in_to_device(45) &
--                data_in_to_device(29) &
--   data_in_to_device(13);
--   data_delay(14) <=                 data_in_to_device(158) &
--                data_in_to_device(142) &
--                data_in_to_device(126) &
--                data_in_to_device(110) &
--                data_in_to_device(94) &
--                data_in_to_device(78) &
--                data_in_to_device(62) &
--                data_in_to_device(46) &
--                data_in_to_device(30) &
--   data_in_to_device(14);
--   data_delay(15) <=                 data_in_to_device(159) &
--                data_in_to_device(143) &
--                data_in_to_device(127) &
--                data_in_to_device(111) &
--                data_in_to_device(95) &
--                data_in_to_device(79) &
--                data_in_to_device(63) &
--                data_in_to_device(47) &
--                data_in_to_device(31) &
--   data_in_to_device(15);

   process (clk_div_out) begin
   if (clk_div_out='1' and clk_div_out'event) then
     if (rst_sync_int6 = '1') then
       start_check <= '0';
     else
       if (data_delay(0) /= "0000000000") then

         start_check <= '1';
       end if;
     end if;
    end if;
   end process;

   process (clk_div_out) begin
   if (clk_div_out='1' and clk_div_out'event) then
     if (rst_sync_int6 = '1') then
       start_count <= '0';
     else
       if (data_delay(0) = "0000000001" and equal = '1') then

         start_count <= '1';
       end if;
     end if;
    end if;
   end process;

   process (clk_div_out) begin
   if (clk_div_out='1' and clk_div_out'event) then
     if (rst_sync_int6 = '1') then
       local_counter <= (others =>'0');
     else
       if start_count = '1' then
         local_counter <= local_counter + 1;
       else
         local_counter <= (others =>'0');
       end if;
     end if;
    end if;
   end process;

   process (clk_div_out) begin
   if (clk_div_out='1' and clk_div_out'event) then
     if (rst_sync_int6 = '1') then
       data_delay_int1(0) <= (others => '0');
       data_delay_int2(0) <= (others => '0');
       data_delay_int1(1) <= (others => '0');
       data_delay_int2(1) <= (others => '0');
       data_delay_int1(2) <= (others => '0');
       data_delay_int2(2) <= (others => '0');
       data_delay_int1(3) <= (others => '0');
       data_delay_int2(3) <= (others => '0');
       data_delay_int1(4) <= (others => '0');
       data_delay_int2(4) <= (others => '0');
       data_delay_int1(5) <= (others => '0');
       data_delay_int2(5) <= (others => '0');
       data_delay_int1(6) <= (others => '0');
       data_delay_int2(6) <= (others => '0');
       data_delay_int1(7) <= (others => '0');
       data_delay_int2(7) <= (others => '0');
       data_delay_int1(8) <= (others => '0');
       data_delay_int2(8) <= (others => '0');
       data_delay_int1(9) <= (others => '0');
       data_delay_int2(9) <= (others => '0');
       data_delay_int1(10) <= (others => '0');
       data_delay_int2(10) <= (others => '0');
       data_delay_int1(11) <= (others => '0');
       data_delay_int2(11) <= (others => '0');
       data_delay_int1(12) <= (others => '0');
       data_delay_int2(12) <= (others => '0');
       data_delay_int1(13) <= (others => '0');
       data_delay_int2(13) <= (others => '0');
       data_delay_int1(14) <= (others => '0');
       data_delay_int2(14) <= (others => '0');
       data_delay_int1(15) <= (others => '0');
       data_delay_int2(15) <= (others => '0');
     else
       data_delay_int1(0) <= data_delay(0);
       data_delay_int2(0) <= data_delay_int1(0);
       data_delay_int1(1) <= data_delay(1);
       data_delay_int2(1) <= data_delay_int1(1);
       data_delay_int1(2) <= data_delay(2);
       data_delay_int2(2) <= data_delay_int1(2);
       data_delay_int1(3) <= data_delay(3);
       data_delay_int2(3) <= data_delay_int1(3);
       data_delay_int1(4) <= data_delay(4);
       data_delay_int2(4) <= data_delay_int1(4);
       data_delay_int1(5) <= data_delay(5);
       data_delay_int2(5) <= data_delay_int1(5);
       data_delay_int1(6) <= data_delay(6);
       data_delay_int2(6) <= data_delay_int1(6);
       data_delay_int1(7) <= data_delay(7);
       data_delay_int2(7) <= data_delay_int1(7);
       data_delay_int1(8) <= data_delay(8);
       data_delay_int2(8) <= data_delay_int1(8);
       data_delay_int1(9) <= data_delay(9);
       data_delay_int2(9) <= data_delay_int1(9);
       data_delay_int1(10) <= data_delay(10);
       data_delay_int2(10) <= data_delay_int1(10);
       data_delay_int1(11) <= data_delay(11);
       data_delay_int2(11) <= data_delay_int1(11);
       data_delay_int1(12) <= data_delay(12);
       data_delay_int2(12) <= data_delay_int1(12);
       data_delay_int1(13) <= data_delay(13);
       data_delay_int2(13) <= data_delay_int1(13);
       data_delay_int1(14) <= data_delay(14);
       data_delay_int2(14) <= data_delay_int1(14);
       data_delay_int1(15) <= data_delay(15);
       data_delay_int2(15) <= data_delay_int1(15);
     end if;
   end if;
   end process;

   process (clk_div_out) begin
   if (clk_div_out='1' and clk_div_out'event) then
     if rst_sync_int6 = '1' then
       bitslip_int <= '0';
       equal <= '0';
     else
      if (equal = '0' and locked = '1' and start_check = '1') then
        if (
      (data_delay(15) = pat_out) and
      (data_delay(14) = pat_out) and
      (data_delay(13) = pat_out) and
      (data_delay(12) = pat_out) and
      (data_delay(11) = pat_out) and
      (data_delay(10) = pat_out) and
      (data_delay(9) = pat_out) and
      (data_delay(8) = pat_out) and
      (data_delay(7) = pat_out) and
      (data_delay(6) = pat_out) and
      (data_delay(5) = pat_out) and
      (data_delay(4) = pat_out) and
      (data_delay(3) = pat_out) and
      (data_delay(2) = pat_out) and
      (data_delay(1) = pat_out) and
      (data_delay(0) = pat_out)) then
          bitslip_int <= '0';
          equal <= '1';
        else
          bitslip_int <= '1';
          equal <= '0';
        end if;
      else
        bitslip_int <= '0';
      end if;
     end if;
    end if;
   end process;

   process (clk_div_out) begin
   if (clk_div_out='1' and clk_div_out'event) then
     if (rst_sync_int6 = '1') then
       bitslip <= '0';
       bit_count <= "000";
     else
       bit_count <= bit_count + '1';
         if bit_count = "111" then
           if bitslip_int='1' then
             bitslip <= not(bitslip);
           else
             bitslip <= '0';
           end if;
         else
           bitslip <= '0';
         end if;
      end if;
     end if;
   end process;

   process (clk_div_out) begin
   if (clk_div_out='1' and clk_div_out'event) then
     if equal = '1' then
      if (
        (data_delay_int2(1) = local_counter) and
        (data_delay_int2(2) = local_counter) and
        (data_delay_int2(3) = local_counter) and
        (data_delay_int2(4) = local_counter) and
        (data_delay_int2(5) = local_counter) and
        (data_delay_int2(6) = local_counter) and
        (data_delay_int2(7) = local_counter) and
        (data_delay_int2(8) = local_counter) and
        (data_delay_int2(9) = local_counter) and
        (data_delay_int2(10) = local_counter) and
        (data_delay_int2(11) = local_counter) and
        (data_delay_int2(12) = local_counter) and
        (data_delay_int2(13) = local_counter) and
        (data_delay_int2(14) = local_counter) and
        (data_delay_int2(15) = local_counter) and
        (data_delay_int2(0) = local_counter)) then
        if (local_counter = "1111111111") then
          pattern_completed <= "11";
        -- all over
        else
          pattern_completed <= "01";
          -- bitslip done, data checking in progress
        end if;
     else
          if (start_count = '1') then
             pattern_completed <= "10";
         -- incorrect data
          else
             pattern_completed <= pattern_completed;
          end if;
     end if;
   else
          pattern_completed <= "00";
         -- yet to get bitslip
   end if;
  end if;
 end process;




   PATTERN_COMPLETED_OUT <= pattern_completed;







     clk_in_int_inv <= not(clk_in_pll);

  pins: for pin_count in 0 to sys_w-1 generate
    -- Instantiate the buffers
    ----------------------------------
     obufds_inst : OBUFDS
       generic map (
         IOSTANDARD => "LVDS_25")
       port map (
         O          => DATA_OUT_TO_PINS_P  (pin_count),
         OB         => DATA_OUT_TO_PINS_N  (pin_count),
         I          => data_out_to_pins_predelay(pin_count));

     -- Instantiate the serdes primitive
     ----------------------------------

     -- declare the oserdes
     oserdese2_master : OSERDESE2
       generic map (
         DATA_RATE_OQ   => "DDR",
         DATA_RATE_TQ   => "SDR",
         DATA_WIDTH     => 10,

         TRISTATE_WIDTH => 1,
         TBYTE_CTL      => "FALSE",
         TBYTE_SRC      => "FALSE",
    --     SRTYPE         => "SYNC",
    -- commenting as synth gives error
         SERDES_MODE    => "MASTER")
       port map (
         D1             => oserdes_d(pin_count)(13),
         D2             => oserdes_d(pin_count)(12),
         D3             => oserdes_d(pin_count)(11),
         D4             => oserdes_d(pin_count)(10),
         D5             => oserdes_d(pin_count)(9) ,
         D6             => oserdes_d(pin_count)(8) ,
         D7             => oserdes_d(pin_count)(7) ,
         D8             => oserdes_d(pin_count)(6) ,
         T1             => '0',
         T2             => '0',
         T3             => '0',
         T4             => '0',
         SHIFTIN1       => ocascade_sm_d(pin_count),
         SHIFTIN2       => ocascade_sm_t(pin_count),
         SHIFTOUT1      => open,
         SHIFTOUT2      => open,
         OCE            => clock_enable,
         CLK            => clk_in_pll,
         CLKDIV         => clk_div_in,
         OQ             => data_out_to_pins_predelay(pin_count),
         TQ             => open,
         OFB            => open,
         TBYTEIN        => '0',
         TBYTEOUT       => open,
         TFB            => open,
         TCE            => '0',
         RST            => IO_RESET);

     oserdese2_slave : OSERDESE2
       generic map (
         DATA_RATE_OQ   => "DDR",
         DATA_RATE_TQ   => "SDR", -- "DDR",
         DATA_WIDTH     => 10,
         TRISTATE_WIDTH => 1,
   --      SRTYPE         => "SYNC",
         TBYTE_CTL      => "FALSE",
         TBYTE_SRC      => "FALSE",
         SERDES_MODE    => "SLAVE")
   --      INIT_OQ        => 0,
   --      INIT_TQ        => 0,
       port map (
         D1             => '0',
         D2             => '0',
         D3             => oserdes_d(pin_count)(5),
         D4             => oserdes_d(pin_count)(4),
         D5             => oserdes_d(pin_count)(3),
         D6             => oserdes_d(pin_count)(2),
         D7             => oserdes_d(pin_count)(1),
         D8             => oserdes_d(pin_count)(0),
         T1             => '0',
         T2             => '0',
         T3             => '0',
         T4             => '0',
         SHIFTOUT1      => ocascade_sm_d(pin_count),
         SHIFTOUT2      => ocascade_sm_t(pin_count),
         SHIFTIN1       => '0',
         SHIFTIN2       => '0',
         OCE            => clock_enable,
         CLK            => clk_in_pll,
         CLKDIV         => clk_div_in,
         OQ             => open, --data_out_to_pins_predelay(pin_count),
         TQ             => open,
         OFB            => open,
         TFB            => open,
         TBYTEIN       => '0',
         TBYTEOUT      => open,
         TCE            => '0',
         RST            => IO_RESET);


     -- Concatenate the serdes outputs together. Keep the timesliced
     --   bits together, and placing the earliest bits on the right
     --   ie, if data comes in 0, 1, 2, 3, 4, 5, 6, 7, ...
     --       the output will be 3210, 7654, ...
     -------------------------------------------------------------
    out_slices: for slice_count in 0 to num_serial_bits-1 generate begin

        oserdes_d(pin_count)(14 - slice_count - 1) <=
           data_out_from_device((pin_count * num_serial_bits) + slice_count);

     end generate out_slices;
  end generate pins;

     clk_fwd : OSERDESE2
       generic map (
         DATA_RATE_OQ   => "DDR",
         DATA_RATE_TQ   => "SDR",
         DATA_WIDTH     => 4,
         TRISTATE_WIDTH => 1,
         SERDES_MODE    => "MASTER")
       port map (
         D1             => '1',
         D2             => '0',
         D3             => '1',
         D4             => '0',
         D5             => '1',
         D6             => '0',
         D7             => '1',
         D8             => '0',
         T1             => '0',
         T2             => '0',
         T3             => '0',
         T4             => '0',
         SHIFTIN1       => '0',
         SHIFTIN2       => '0',
         SHIFTOUT1      => open,
         SHIFTOUT2      => open,
         OCE            => locked,
         CLK            => clk_in_pll,
         CLKDIV         => clk_div_in,
         OQ             => clk_fwd_out,
         TQ             => open,
         OFB            => open,
         TBYTEIN        => '0',
         TBYTEOUT       => open,
         TFB            => open,
         TCE            => '0',
         RST            => IO_RESET);

          obufds_clk_inst : OBUFDS
           generic map (
             IOSTANDARD => "LVDS_25")
           port map (
             O          => CLK_TO_PINS_FWD_P,
             OB         => CLK_TO_PINS_FWD_N,
             I          => clk_fwd_out);

--   -- Instantiate the IO design
--   io_inst : deser_lvds_ccd
--   port map
--   (
--    -- From the system into the device
--    DATA_IN_FROM_PINS_P     => DATA_IN_FROM_PINS_P,
--    DATA_IN_FROM_PINS_N     => DATA_IN_FROM_PINS_N,
--    DATA_IN_TO_DEVICE       => data_in_to_device,
--
--    IN_DELAY_RESET            => '0',
--    IN_DELAY_DATA_CE          => (others => '0'),
--    IN_DELAY_DATA_INC         => (others => '0'),
--    IN_DELAY_TAP_IN           => (others => '0'),
--    IN_DELAY_TAP_OUT          => open,
--    DELAY_LOCKED            => DELAY_LOCKED,
--    REF_CLOCK               => ref_clk_int,
--    BITSLIP                 => bitslip,              -- This example design does not implement Bitslip
--
--MMCM_LOCKED => open,
--CLK_IN_CCD  => '0',
--
---- Clock and reset signals
--CLK_OUT_P => open,
--CLK_OUT_N => open,
--    CLK_IN_P                => CLK_IN_FWD_P,
--    CLK_IN_N                => CLK_IN_FWD_N,
--    CLK_DIV_OUT             => clk_div_out,
--    CLK_RESET               => CLK_RESET,
--    IO_RESET                => rst_sync_int);

gen : for i in 0 to C_PCFG_CCD_LVDS_COUNT - 1 generate begin
p_in_ccd.data_p(i) <= DATA_IN_FROM_PINS_P(i);
p_in_ccd.data_n(i) <= DATA_IN_FROM_PINS_N(i);
end generate;

p_in_ccd.clk_p <= CLK_IN_FWD_P;
p_in_ccd.clk_n <= CLK_IN_FWD_N;

m_ccd : ccd_vita25K
port map(
p_in_ccd   => p_in_ccd,
p_out_ccd  => open,

p_out_video_vs  => open,
p_out_video_hs  => open,
p_out_video_den => open,
p_out_video_d   => data_in_to_device,
p_out_video_clk => clk_div_out,

p_in_refclk => ref_clk_int,
p_in_ccdclk => '0',
p_in_rst    => CLK_RESET
);


end xilinx;

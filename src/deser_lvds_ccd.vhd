
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

entity deser_lvds_ccd is
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

-- Clock and reset signals
  CLK_IN_P                : in    std_logic;                    -- Differential fast clock from IOB
  CLK_IN_N                : in    std_logic;
  CLK_DIV_OUT             : out   std_logic;--_vector(1 downto 0);                    -- Slow clock output
  CLK_RESET               : in    std_logic;                    -- Reset signal for Clock circuit
  IO_RESET                : in    std_logic);                   -- Reset signal for IO circuit
end deser_lvds_ccd;

architecture xilinx of deser_lvds_ccd is

component deser_clock_gen is
generic (
CLKIN_PERIOD    : real := 6.000 ;     -- clock period (ns) of input clock on clkin_p
MMCM_MODE       : integer := 1 ;      -- Parameter to set multiplier for MMCM either 1 or 2 to get VCO in correct operating range. 1 multiplies clock by 7, 2 multiplies clock by 14
MMCM_MODE_REAL  : real := 1.000 ;     -- Parameter to set multiplier for MMCM either 1 or 2 to get VCO in correct operating range. 1 multiplies clock by 7, 2 multiplies clock by 14
TX_CLOCK        : string := "BUFIO" ; -- Parameter to set transmission clock buffer type, BUFIO, BUF_H, BUF_G
INTER_CLOCK     : string := "BUF_R" ; -- Parameter to set intermediate clock buffer type, BUFR, BUF_H, BUF_G
PIXEL_CLOCK     : string := "BUF_G" ; -- Parameter to set final clock buffer type, BUF_R, BUF_H, BUF_G
USE_PLL         : boolean := FALSE ;  -- Parameter to enable PLL use rather than MMCM use, note, PLL does not support BUFIO and BUFR
DIFF_TERM       : boolean := TRUE     -- Enable or disable internal differential termination
);
port  (
reset     :  in std_logic ;     -- reset (active high)
clkin_p   :  in std_logic ;     -- differential clock input
clkin_n   :  in std_logic ;     -- differential clock input
txclk     : out std_logic ;     -- CLK for serdes
pixel_clk : out std_logic ;     -- Pixel clock output
txclk_div : out std_logic ;     -- CLKDIV for serdes, and gearbox output = pixel clock / 2
mmcm_lckd : out std_logic ;     -- Locked output from MMCM
status    : out std_logic_vector(6 downto 0)   -- Status bus
);
end component;

  attribute CORE_GENERATION_INFO            : string;
  attribute CORE_GENERATION_INFO of xilinx  : architecture is "deser_lvds_ccd,selectio_wiz_v4_1,{component_name=deser_lvds_ccd,bus_dir=INPUTS,bus_sig_type=DIFF,bus_io_std=LVDS_25,use_serialization=true,use_phase_detector=false,serialization_factor=10,enable_bitslip=false,enable_train=false,system_data_width=16,bus_in_delay=NONE,bus_out_delay=NONE,clk_sig_type=DIFF,clk_io_std=LVCMOS18,clk_buf=BUFIO2,active_edge=RISING,clk_delay=NONE,v6_bus_in_delay=VAR_LOADABLE,v6_bus_out_delay=NONE,v6_clk_buf=BUFIO,v6_active_edge=DDR,v6_ddr_alignment=SAME_EDGE_PIPELINED,v6_oddr_alignment=SAME_EDGE,ddr_alignment=C0,v6_interface_type=NETWORKING,interface_type=NETWORKING,v6_bus_in_tap=1,v6_bus_out_tap=0,v6_clk_io_std=LVDS_25,v6_clk_sig_type=DIFF}";
  constant clock_enable            : std_logic := '1';
  signal unused : std_logic;
  signal clk_in_int                : std_logic;
  signal clk_div                   : std_logic_vector(0 downto 0);
  signal clk_div_int               : std_logic_vector(0 downto 0);
  signal clk_in_int_buf            : std_logic_vector(0 downto 0);


  -- After the buffer
  signal data_in_from_pins_int     : std_logic_vector(sys_w-1 downto 0);
  -- Between the delay and serdes
  signal data_in_from_pins_delay   : std_logic_vector(sys_w-1 downto 0);
  signal in_delay_ce              : std_logic_vector(sys_w-1 downto 0);
  signal in_delay_inc_dec         : std_logic_vector(sys_w-1 downto 0);
  type loadarr is array (0 to sys_w-1) of std_logic_vector(4 downto 0);
  signal in_delay_tap_in_int       : loadarr := (( others => (others => '0')));
  signal in_delay_tap_out_int      : loadarr := (( others => (others => '0')));
  signal ce_out_uc              : std_logic;
  signal inc_out_uc             : std_logic;
  signal regrst_out_uc          : std_logic;
  constant num_serial_bits         : integer := dev_w/sys_w;
  type serdarr is array (0 to 13) of std_logic_vector(sys_w-1 downto 0);
  -- Array to use intermediately from the serdes to the internal
  --  devices. bus "0" is the leftmost bus
  -- * fills in starting with 0
  signal iserdes_q                 : serdarr := (( others => (others => '0')));
  signal serdesstrobe             : std_logic;
  signal icascade1                : std_logic_vector(sys_w-1 downto 0);
  signal icascade2                : std_logic_vector(sys_w-1 downto 0);
  signal clk_in_int_inv           : std_logic_vector(0 downto 0);
  signal i_io_reset               : std_logic;
  signal i_mmcm_lckd              : std_logic;

  attribute IODELAY_GROUP : string;
  attribute IODELAY_GROUP of delayctrl : label is "deser_lvds_ccd_group";

begin

  in_delay_ce <= IN_DELAY_DATA_CE;
  in_delay_inc_dec <= IN_DELAY_DATA_INC;
  gen : for i in 0 to sys_w - 1 generate
  in_delay_tap_in_int(i) <= IN_DELAY_TAP_IN(5*(i + 1) -1 downto 5*(i));
  IN_DELAY_TAP_OUT(5*(i + 1) -1 downto 5*(i)) <= in_delay_tap_out_int(i);
  end generate;

  -- Create the clock logic
  CLK_DIV_OUT <= clk_div(0);

m_clk_gen : deser_clock_gen
generic map(
CLKIN_PERIOD    => 3.225  , -- clock period (ns) of input clock on clkin_p
MMCM_MODE       => 1      , -- Parameter to set multiplier for MMCM either 1 or 2 to get VCO in correct operating range. 1 multiplies clock by 7, 2 multiplies clock by 14
MMCM_MODE_REAL  => 1.000  , -- Parameter to set multiplier for MMCM either 1 or 2 to get VCO in correct operating range. 1 multiplies clock by 7, 2 multiplies clock by 14
TX_CLOCK        => "BUF_G", -- Parameter to set transmission clock buffer type, BUFIO, BUF_H, BUF_G
INTER_CLOCK     => "BUF_G", -- Parameter to set intermediate clock buffer type, BUFR, BUF_H, BUF_G
PIXEL_CLOCK     => "BUF_G", -- Parameter to set final clock buffer type, BUF_R, BUF_H, BUF_G
USE_PLL         => FALSE  , -- Parameter to enable PLL use rather than MMCM use, note, PLL does not support BUFIO and BUFR
DIFF_TERM       => TRUE     -- Enable or disable internal differential termination
)
port map(
reset     => CLK_RESET,
clkin_p   => CLK_IN_P,
clkin_n   => CLK_IN_N,
txclk     => open,
pixel_clk => clk_in_int,
txclk_div => clk_div(0),
mmcm_lckd => i_mmcm_lckd,
status    => open
);

i_io_reset <= IO_RESET or (not i_mmcm_lckd);

clk_in_int_buf(0) <= clk_in_int;

  -- We have multiple bits- step over every bit, instantiating the required elements
  pins: for pin_count in 0 to sys_w - 1 generate
  attribute IODELAY_GROUP of idelaye2_bus: label is "deser_lvds_ccd_group";
  begin

    -- Instantiate the buffers
    ----------------------------------
    -- Instantiate a buffer for every bit of the data bus
     ibufds_inst : IBUFDS
       generic map (
         DIFF_TERM  => FALSE,             -- Differential termination
         IOSTANDARD => "LVDS_25")
       port map (
         I          => DATA_IN_FROM_PINS_P  (pin_count),
         IB         => DATA_IN_FROM_PINS_N  (pin_count),
         O          => data_in_from_pins_int(pin_count));

    -- Instantiate the delay primitive
    -----------------------------------

     idelaye2_bus : IDELAYE2
       generic map (
         CINVCTRL_SEL           => "FALSE",            -- TRUE, FALSE
         DELAY_SRC              => "IDATAIN",        -- IDATAIN, DATAIN
         HIGH_PERFORMANCE_MODE  => "FALSE",             -- TRUE, FALSE
         IDELAY_TYPE            => "VAR_LOAD",          -- FIXED, VARIABLE, or VAR_LOADABLE
         IDELAY_VALUE           => 1,                -- 0 to 31
         REFCLK_FREQUENCY       => 200.0,
         PIPE_SEL               => "FALSE",
         SIGNAL_PATTERN         => "DATA"           -- CLOCK, DATA
         )
         port map (
         DATAOUT                => data_in_from_pins_delay(pin_count),
         DATAIN                 => '0', -- Data from FPGA logic
         C                      => clk_div(0),
         CE                     => in_delay_ce(pin_count), --IN_DELAY_DATA_CE,
         INC                    => in_delay_inc_dec(pin_count), --IN_DELAY_DATA_INC,
         IDATAIN                => data_in_from_pins_int  (pin_count), -- Driven by IOB
         LD                     => IN_DELAY_RESET,
         REGRST                 => i_io_reset,
         LDPIPEEN               => '0',
         CNTVALUEIN             => in_delay_tap_in_int(pin_count), --IN_DELAY_TAP_IN,
         CNTVALUEOUT            => in_delay_tap_out_int(pin_count), --IN_DELAY_TAP_OUT,
         CINVCTRL               => '0'
         );


     -- Instantiate the serdes primitive
     ----------------------------------

     clk_in_int_inv(0) <= not (clk_in_int_buf(0));


     -- declare the iserdes
     iserdese2_master : ISERDESE2
       generic map (
         DATA_RATE         => "DDR",
         DATA_WIDTH        => 10,
         INTERFACE_TYPE    => "NETWORKING",
         DYN_CLKDIV_INV_EN => "FALSE",
         DYN_CLK_INV_EN    => "FALSE",
         NUM_CE            => 2,
         OFB_USED          => "FALSE",
         IOBDELAY          => "IFD",                              -- Use input at DDLY to output the data on Q1-Q6
         SERDES_MODE       => "MASTER")
       port map (
         Q1                => iserdes_q(0)(pin_count),
         Q2                => iserdes_q(1)(pin_count),
         Q3                => iserdes_q(2)(pin_count),
         Q4                => iserdes_q(3)(pin_count),
         Q5                => iserdes_q(4)(pin_count),
         Q6                => iserdes_q(5)(pin_count),
         Q7                => iserdes_q(6)(pin_count),
         Q8                => iserdes_q(7)(pin_count),
         SHIFTOUT1         => icascade1(pin_count),               -- Cascade connection to Slave ISERDES
         SHIFTOUT2         => icascade2(pin_count),               -- Cascade connection to Slave ISERDES
         BITSLIP           => BITSLIP,                            -- 1-bit Invoke Bitslip. This can be used with any
                                                                  -- DATA_WIDTH, cascaded or not.
         CE1               => clock_enable,                       -- 1-bit Clock enable input
         CE2               => clock_enable,                       -- 1-bit Clock enable input
         CLK               => clk_in_int_buf(0),                     -- Fast Source Synchronous SERDES clock from BUFIO
         CLKB              => clk_in_int_inv(0),                     -- Locally inverted clock
         CLKDIV            => clk_div(0),                            -- Slow clock driven by BUFR
         CLKDIVP           => '0',
         D                 => '0',
         DDLY              => data_in_from_pins_delay(pin_count), -- 1-bit Input signal from IODELAYE1.
         RST               => i_io_reset,                           -- 1-bit Asynchronous reset only.
         SHIFTIN1          => '0',
         SHIFTIN2          => '0',
        -- unused connections
         DYNCLKDIVSEL      => '0',
         DYNCLKSEL         => '0',
         OFB               => '0',
         OCLK              => '0',
         OCLKB             => '0',
         O                 => open);                              -- unregistered output of ISERDESE1

     iserdese2_slave : ISERDESE2
       generic map (
         DATA_RATE         => "DDR",
         DATA_WIDTH        => 10,
         INTERFACE_TYPE    => "NETWORKING",
         DYN_CLKDIV_INV_EN => "FALSE",
         DYN_CLK_INV_EN    => "FALSE",
         NUM_CE            => 2,
         OFB_USED          => "FALSE",
         IOBDELAY          => "IFD",                              -- Use input at DDLY to output the data on Q1-Q6
         SERDES_MODE       => "SLAVE")
       port map (
         Q1                => open,
         Q2                => open,
         Q3                => iserdes_q(8)(pin_count),
         Q4                => iserdes_q(9)(pin_count),
         Q5                => iserdes_q(10)(pin_count),
         Q6                => iserdes_q(11)(pin_count),
         Q7                => iserdes_q(12)(pin_count),
         Q8                => iserdes_q(13)(pin_count),
         SHIFTOUT1         => open,
         SHIFTOUT2         => open,
         SHIFTIN1          => icascade1(pin_count),               -- Cascade connections from Master ISERDES
         SHIFTIN2          => icascade2(pin_count),               -- Cascade connections from Master ISERDES
         BITSLIP           => BITSLIP,                            -- 1-bit Invoke Bitslip. This can be used with any
                                                                  -- DATA_WIDTH, cascaded or not.
         CE1               => clock_enable,                       -- 1-bit Clock enable input
         CE2               => clock_enable,                       -- 1-bit Clock enable input
         CLK               => clk_in_int_buf(0),                     -- Fast source synchronous serdes clock
         CLKB              => clk_in_int_inv(0),                     -- locally inverted clock
         CLKDIV            => clk_div(0),                            -- Slow clock sriven by BUFR.
         CLKDIVP           => '0',
         D                 => '0',                                -- Slave ISERDES module. No need to connect D, DDLY
         DDLY              => '0',
         RST               => i_io_reset,                           -- 1-bit Asynchronous reset only.
        -- unused connections
         DYNCLKDIVSEL      => '0',
         DYNCLKSEL         => '0',
         OFB               => '0',
          OCLK             => '0',
          OCLKB            => '0',
          O                => open);                              -- unregistered output of ISERDESE1

     -- Concatenate the serdes outputs together. Keep the timesliced
     --   bits together, and placing the earliest bits on the right
     --   ie, if data comes in 0, 1, 2, 3, 4, 5, 6, 7, ...
     --       the output will be 3210, 7654, ...
     -------------------------------------------------------------

     in_slices: for slice_count in 0 to num_serial_bits-1 generate begin
        -- This places the first data in time on the right
        DATA_IN_TO_DEVICE(slice_count*sys_w+sys_w-1 downto slice_count*sys_w) <=
          iserdes_q(num_serial_bits-slice_count-1);
        -- To place the first data in time on the left, use the
        --   following code, instead
        -- DATA_IN_TO_DEVICE(slice_count*sys_w+sys_w-1 downto sys_w) <=
        --   iserdes_q(slice_count);
     end generate in_slices;


  end generate pins;

-- IDELAYCTRL is needed for calibration
delayctrl : IDELAYCTRL
    port map (
     RDY    => DELAY_LOCKED,
     REFCLK => REF_CLOCK,
     RST    => i_io_reset
     );




end xilinx;




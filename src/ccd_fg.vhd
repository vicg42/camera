-------------------------------------------------------------------------
-- Company     : Yansar
-- Engineer    : Golovachenko Victor
--
-- Create Date : 11.09.2014 10:34:22
-- Module Name : ccd_fg (frame grabber)
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
use work.reduce_pack.all;
use work.ccd_pkg.all;
use work.vicg_common_pkg.all;

entity ccd_fg is
generic(
G_LVDS_CH_COUNT : integer := 16;
G_SYNC_LINE_COUNT : integer := 1;
G_CCD_BIT_COUNT : integer := 10;
G_VD_BIT_COUNT  : integer := 10
);
port(
p_in_ccd        : in    TCCD_pinin;
p_out_ccd       : out   TCCD_pinout;

p_out_vfr_data  : out   std_logic_vector((((G_LVDS_CH_COUNT - G_SYNC_LINE_COUNT))
                                               * selval(16, 32, G_VD_BIT_COUNT = 8)) - 1 downto 0);
p_out_vfr_den   : out   std_logic;
p_out_vfr_vs    : out   std_logic;
p_out_vfr_hs    : out   std_logic;
p_out_vfr_clk   : out   std_logic;

p_out_status    : out   std_logic_vector(C_CCD_FG_STATUS_LAST_BIT downto 0);

p_out_tst       : out   std_logic_vector(31 downto 0);
p_in_tst        : in    std_logic_vector(31 downto 0);

p_in_ccdinit    : in    std_logic;
p_in_ccdclk     : in    std_logic;
p_in_refclk     : in    std_logic;
p_in_rst        : in    std_logic
);
end entity ccd_fg;

architecture xilinx of ccd_fg is

component ccd_deser is
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
end component ccd_deser;

component ccd_deser_clk is
generic (
CLKIN_DIFF      : boolean := TRUE ;
CLKIN_PERIOD    : real := 6.000 ;
MULT_F          : integer := 1 ;
MULT_F_REAL     : real := 1.000 ;
DIVIDE_F_REAL   : real := 1.000 ;
DIVIDE_1        : integer := 1 ;
TX_CLOCK        : string := "BUFIO" ;
INTER_CLOCK     : string := "BUF_R" ;
PIXEL_CLOCK     : string := "BUF_G" ;
USE_PLL         : boolean := FALSE ;
DIFF_TERM       : boolean := TRUE
);
port  (
reset     :  in std_logic ;
clkin_p   :  in std_logic ;
clkin_n   :  in std_logic ;
txclk     : out std_logic ;
pixel_clk : out std_logic ;
txclk_div : out std_logic ;
mmcm_lckd : out std_logic ;
status    : out std_logic_vector(6 downto 0);
p_in_tst  : in  std_logic_vector(31 downto 0);
p_out_tst : out std_logic_vector(31 downto 0)
);
end component ccd_deser_clk;

signal i_mmcm_lckd      : std_logic;
signal i_mmcm_rst       : std_logic;

signal i_idelayctrl_rdy : std_logic_vector(1 downto 0);

--signal i_clk_en         : std_logic;
signal i_clk            : std_logic;
signal i_clk_inv        : std_logic;
signal i_clk_div        : std_logic;

signal i_deser_rdy      : std_logic;
signal i_deser_rst      : std_logic;
type TDeserData is array (0 to G_LVDS_CH_COUNT - 1)
  of std_logic_vector(G_CCD_BIT_COUNT - 1 downto 0);
signal i_deser_d        : TDeserData := (( others => (others => '0')));
signal i_deser_dout     : TDeserData := (( others => (others => '0')));
signal i_align_ok       : std_logic_vector(G_LVDS_CH_COUNT - 1 downto 0);
signal tst_align_ok     : std_logic_vector(G_LVDS_CH_COUNT - 1 downto 0) := (others => '0');
signal i_align_start    : std_logic := '0';


type TPix_sr is array (0 to 2) of std_logic_vector(G_VD_BIT_COUNT - 1 downto 0);
type TRxD2_sr is array (0 to G_LVDS_CH_COUNT - G_SYNC_LINE_COUNT - 1) of TPix_sr;

type TRxD_sr is array (0 to G_LVDS_CH_COUNT - G_SYNC_LINE_COUNT - 1)
  of std_logic_vector(G_VD_BIT_COUNT - 1 downto 0);
signal sr_rxd           : TRxD2_sr;
signal i_vfr_pix        : TRxD_sr;
signal sr_vfr_pix       : TRxD_sr;

signal i_sync_d         : unsigned(G_CCD_BIT_COUNT - 1 downto 0);

signal i_vfr_vs         : std_logic;
signal i_vfr_hs         : std_logic;
signal i_vfr_den        : std_logic;
signal i_vfr_bl         : std_logic;
signal i_crc            : std_logic;
signal i_vfr_den_out    : std_logic := '0';
signal i_vfr_vs_out     : std_logic := '0';
signal i_vfr_hs_out     : std_logic := '0';

signal i_kernel_cnt     : unsigned(1 downto 0);

type TKernelPix is array (0 to G_LVDS_CH_COUNT - G_SYNC_LINE_COUNT - 1)
    of std_logic_vector(selval(16, 32, G_VD_BIT_COUNT = 8) - 1 downto 0);
signal i_kernel_pix     : TKernelPix;

signal i_vfr_pix_out    : std_logic_vector(p_out_vfr_data'range);

signal sr_btn_push      : unsigned(0 to 1) := (others => '0');
signal i_btn_push       : std_logic := '0';
signal tst_ccd_deser_in : std_logic_vector(31 downto 0);

type TTstDeserData is array (0 to G_LVDS_CH_COUNT - 1)
  of std_logic_vector(31 downto 0);
signal tst_ccd_deser_out : TTstDeserData;

signal i_align_ok_all  : std_logic := '0';
signal sr_syn_fs       : std_logic_vector(0 to 1);
signal sr_syn_ls       : std_logic_vector(0 to 1);

signal i_pixen         : std_logic;
signal sr_pixen        : std_logic_vector(0 to 1);

signal i_syn_fs        : std_logic;
signal i_syn_fe        : std_logic;
signal i_syn_ls        : std_logic;
signal i_syn_le        : std_logic;
signal i_syn_img       : std_logic;
signal i_syn_crc       : std_logic;
signal i_syn_bl        : std_logic;

signal tst_syn_fs      : std_logic;
signal tst_syn_fe      : std_logic;
signal tst_syn_ls      : std_logic;
signal tst_syn_le      : std_logic;
signal tst_syn_img     : std_logic;
signal tst_syn_crc     : std_logic;
signal tst_syn_bl      : std_logic;

signal tt_vfr_den      : std_logic;
signal tst_data        : unsigned(G_CCD_BIT_COUNT - 1 downto 0) := (others => '0');

signal tst_fr          : std_logic;


begin --architecture xilinx

-- IDELAYCTRL is needed for calibration
gen_delayctrl: for i in 0 to 1 generate begin
m_delayctrl : IDELAYCTRL
port map (
RDY    => i_idelayctrl_rdy(i),
REFCLK => p_in_refclk,
RST    => p_in_rst
);
end generate gen_delayctrl;

m_clk_fpga2ccd : OBUFDS
port map (
O  => p_out_ccd.clk_p,
OB => p_out_ccd.clk_n,
I  => p_in_ccdclk
);

m_clk_gen : ccd_deser_clk
generic map(
CLKIN_DIFF      => TRUE   ,
CLKIN_PERIOD    => 3.225  , -- clock period (ns) of input clock on clkin_p
MULT_F          => 1,
MULT_F_REAL     => Real(selval(2, 4, G_CCD_BIT_COUNT = 10)),
DIVIDE_F_REAL   => Real(selval(2, 32, G_CCD_BIT_COUNT = 10)),
DIVIDE_1        => selval(10, 16, G_CCD_BIT_COUNT = 10),
TX_CLOCK        => "BUF_G",
INTER_CLOCK     => "BUF_G",
PIXEL_CLOCK     => "BUF_G",
USE_PLL         => FALSE  ,
DIFF_TERM       => TRUE

)
port map(
clkin_p   => p_in_ccd.clk_p,
clkin_n   => p_in_ccd.clk_n,
txclk     => open,
pixel_clk => i_clk,
txclk_div => i_clk_div,
mmcm_lckd => i_mmcm_lckd,
status    => open,

p_in_tst  => p_in_tst,
p_out_tst => open,

reset     => i_mmcm_rst
);

i_mmcm_rst <= not p_in_ccdinit;
i_clk_inv <= not (i_clk);

i_deser_rdy <= i_mmcm_lckd and AND_Reduce(i_idelayctrl_rdy);
i_deser_rst <= not i_deser_rdy;


--###########################################
--Recieve data from lvds channel
--###########################################
gen_lvds_ch: for lvds_ch in 0 to G_LVDS_CH_COUNT - 1 generate
begin

m_deser : ccd_deser
generic map(
G_BIT_COUNT => G_CCD_BIT_COUNT
)
port map(
p_in_data_p    => p_in_ccd.data_p(lvds_ch),
p_in_data_n    => p_in_ccd.data_n(lvds_ch),

p_out_data     => i_deser_d(lvds_ch)(G_CCD_BIT_COUNT - 1 downto 0),
p_out_align_ok => i_align_ok(lvds_ch),

p_out_tst      => tst_ccd_deser_out(lvds_ch),
p_in_tst       => tst_ccd_deser_in,

p_in_clken     => '1', --i_clk_en
p_in_clkdiv    => i_clk_div,
p_in_clk       => i_clk,
p_in_clkinv    => i_clk_inv,
p_in_rst       => i_deser_rst
);


gen_dout : for bitnum in 0 to G_CCD_BIT_COUNT - 1 generate
begin
--i_deser_dout(lvds_ch)(bitnum) <= i_deser_d(lvds_ch)(G_CCD_BIT_COUNT - bitnum - 1);
i_deser_dout(lvds_ch)(bitnum) <= i_deser_d(lvds_ch)(bitnum);
end generate gen_dout;

end generate gen_lvds_ch;



--###########################################
--SYNC detect
--###########################################
i_sync_d <= UNSIGNED(i_deser_dout(0));

i_syn_fs  <= '1' when (i_sync_d = TO_UNSIGNED(C_CCD_CHSYNC_FS      , i_sync_d'length)) else '0';
i_syn_fe  <= '1' when (i_sync_d = TO_UNSIGNED(C_CCD_CHSYNC_FE      , i_sync_d'length)) else '0';
i_syn_ls  <= '1' when (i_sync_d = TO_UNSIGNED(C_CCD_CHSYNC_LS      , i_sync_d'length)) else '0';
i_syn_le  <= '1' when (i_sync_d = TO_UNSIGNED(C_CCD_CHSYNC_LE      , i_sync_d'length)) else '0';
i_syn_img <= '1' when (i_sync_d = TO_UNSIGNED(C_CCD_CHSYNC_IMAGE   , i_sync_d'length)) else '0';
i_syn_crc <= '1' when (i_sync_d = TO_UNSIGNED(C_CCD_CHSYNC_CRC     , i_sync_d'length)) else '0';
i_syn_bl  <= '1' when (i_sync_d = TO_UNSIGNED(C_CCD_CHSYNC_BLACKPIX, i_sync_d'length)) else '0';

process(i_clk_div)
begin
  if rising_edge(i_clk_div) then
    for lvds_ch in 1 to G_LVDS_CH_COUNT - 1 loop
      sr_rxd(lvds_ch - 1) <= i_deser_dout(lvds_ch)
                               (G_CCD_BIT_COUNT - 1 downto (G_CCD_BIT_COUNT - G_VD_BIT_COUNT)) & sr_rxd(lvds_ch - 1)(0 to 1);
      i_vfr_pix(lvds_ch - 1) <= sr_rxd(lvds_ch - 1)(2);

    end loop;
  end if;
end process;

process(i_clk_div)
begin
if rising_edge(i_clk_div) then
  if i_deser_rst = '1' then
    sr_syn_fs <= (others => '0');
    sr_syn_ls <= (others => '0');
    i_pixen <= '0';
    sr_pixen <= (others => '0');
    i_vfr_den <= '0';

  else

      sr_syn_fs <= i_syn_fs & sr_syn_fs(0 to 0);
      sr_syn_ls <= i_syn_ls & sr_syn_ls(0 to 0);

      if (sr_syn_fs(1) = '1' or sr_syn_ls(1) = '1') and i_syn_img = '1' then
        i_pixen <= '1';
      elsif i_syn_crc = '1' then
        i_pixen <= '0';
      end if;

      sr_pixen <= i_pixen & sr_pixen(0 to 0);
      i_vfr_den <= i_pixen or sr_pixen(1);

  end if;
end if;
end process;


p_out_vfr_data <= i_vfr_pix_out;
p_out_vfr_den  <= i_vfr_den_out and AND_reduce(tst_align_ok);
p_out_vfr_vs   <= i_vfr_vs_out ;
p_out_vfr_hs   <= i_vfr_hs_out ;
p_out_vfr_clk  <= i_clk_div;

p_out_status(C_CCD_FG_STATUS_ALIGN_OK_BIT) <= AND_reduce(tst_align_ok);
p_out_status(C_CCD_FG_STATUS_DRY_BIT) <= i_deser_rdy;



--###########################################
--Byte Remapping
--###########################################
process(i_clk_div)
begin
if rising_edge(i_clk_div) then

  i_vfr_den_out  <= (i_vfr_den and i_kernel_cnt(0));
  i_vfr_vs_out   <= i_vfr_vs ;
  i_vfr_hs_out   <= i_vfr_hs ;

  if i_vfr_den = '0' then
    i_kernel_cnt <= (others => '0');

  else

    i_kernel_cnt <= i_kernel_cnt + 1;

    for lvds_ch in 0 to i_kernel_pix'length - 1 loop
      if i_kernel_cnt(0) = '0' then
        sr_vfr_pix(lvds_ch) <= i_vfr_pix(lvds_ch);

      else

        if i_kernel_cnt(1) = '0' then

          i_kernel_pix(lvds_ch)(((i_kernel_pix(lvds_ch)'length / 2) * 1) - 1
              downto (i_kernel_pix(lvds_ch)'length / 2) * 0)
                      <= std_logic_vector(RESIZE(UNSIGNED(sr_vfr_pix(lvds_ch))
                                                  , (i_kernel_pix(lvds_ch)'length / 2)));

          i_kernel_pix(lvds_ch)(((i_kernel_pix(lvds_ch)'length / 2) * 2) - 1
              downto (i_kernel_pix(lvds_ch)'length / 2) * 1)
                      <= std_logic_vector(RESIZE(UNSIGNED(i_vfr_pix(lvds_ch))
                                                  , (i_kernel_pix(lvds_ch)'length / 2)));

        else

          i_kernel_pix(i_kernel_pix'length - 1 - lvds_ch)(((i_kernel_pix(lvds_ch)'length / 2) * 1) - 1
              downto (i_kernel_pix(lvds_ch)'length / 2) * 0)
                      <= std_logic_vector(RESIZE(UNSIGNED(i_vfr_pix(lvds_ch))
                                                  , (i_kernel_pix(lvds_ch)'length / 2)));

          i_kernel_pix(i_kernel_pix'length - 1 - lvds_ch)(((i_kernel_pix(lvds_ch)'length / 2) * 2) - 1
              downto (i_kernel_pix(lvds_ch)'length / 2) * 1)
                      <= std_logic_vector(RESIZE(UNSIGNED(sr_vfr_pix(lvds_ch))
                                                  , (i_kernel_pix(lvds_ch)'length / 2)));

        end if;
      end if;
    end loop;

  end if;

end if;
end process;


gen_fifo_di: for lvds_ch in 0 to i_kernel_pix'length - 1 generate
begin
i_vfr_pix_out((i_kernel_pix(lvds_ch)'length * (lvds_ch + 1)) - 1
                   downto (i_kernel_pix(lvds_ch)'length * lvds_ch)) <= i_kernel_pix(lvds_ch);
end generate gen_fifo_di;


process(i_clk_div)
begin
  if rising_edge(i_clk_div) then
    i_align_start <= p_in_tst(5);

    if i_syn_fs = '1' then
    tst_fr <= '1';
    elsif i_syn_fe = '1' then
    tst_fr <= '0';
    end if;

  end if;
end process;

tst_ccd_deser_in(0) <= i_align_start; --i_btn_push
tst_ccd_deser_in(31 downto 1) <= (others => '0');


--################################################
--DBG
--################################################
process(i_clk_div)
begin
  if rising_edge(i_clk_div) then

--    if p_in_ccdinit = '0' then
--    sr_btn_push <= (others => '0');
--    else
--    sr_btn_push <= p_in_tst(0) & sr_btn_push(0 to 0);
--    end if;
--
--    i_btn_push <= sr_btn_push(0) and not sr_btn_push(1);

    tst_align_ok <= i_align_ok(i_align_ok'high downto 16) & '1' & i_align_ok(14 downto 0);

    i_align_ok_all <= AND_reduce(tst_align_ok);


    tst_syn_fs  <= i_syn_fs ;
    tst_syn_fe  <= i_syn_fe ;
    tst_syn_bl  <= i_syn_bl ;
  end if;
end process;

p_out_tst(0) <= i_vfr_bl or i_align_ok_all -- or tst_ccd_deser_out(0)(0) or tst_ccd_deser_out(15)(0);
or tst_syn_fs
or tst_syn_fe
or tst_syn_bl;

p_out_tst(1) <= tst_fr;
p_out_tst(2) <= i_pixen;
p_out_tst(31 downto 3) <= (others => '0');


--process(i_clk_div)
--begin
--  if rising_edge(i_clk_div) then
--      if i_pixen = '1' or sr_pixen(1) = '1' then
--        tst_data <= tst_data + 1;
--      else
--        tst_data <= (others => '0');
--      end if;
--  end if;
--end process;
--
--gen_dout_pix : for lvds_ch in 1 to G_LVDS_CH_COUNT - 1 generate
--begin
--i_vfr_pix(lvds_ch - 1) <= std_logic_vector(tst_data(G_CCD_BIT_COUNT - 1 downto (G_CCD_BIT_COUNT - G_VD_BIT_COUNT)));
--end generate gen_dout_pix;

end architecture xilinx;


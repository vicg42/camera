-------------------------------------------------------------------------
-- Company     : Yansar
-- Engineer    : Golovachenko Victor
--
-- Create Date : 13.06.2014 15:09:01
-- Module Name : ccd_vita25K_pkg
--
-- Description :
--
-- Revision:
-- Revision 0.01 - File Created
--
-------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.prj_cfg.all;

package ccd_vita25K_pkg is

--Codes SYNC Channel:
--10Bit per pix
constant C_CCD_CHSYNC_TRAINING : integer := 16#3A6#;
constant C_CCD_CHSYNC_BLACKPIX : integer := 16#015#;
constant C_CCD_CHSYNC_CRC      : integer := 16#059#;
constant C_CCD_CHSYNC_IMAGE    : integer := 16#035#;
constant C_CCD_CHSYNC_FS       : integer := 16#2AA#;-- 10_1|010_1010
constant C_CCD_CHSYNC_FE       : integer := 16#32A#;-- 11_0|010_1010
constant C_CCD_CHSYNC_LS       : integer := 16#3AA#;-- 00_1|010_1010
constant C_CCD_CHSYNC_LE       : integer := 16#22A#;-- 01_0|010_1010

constant C_CCD_SPI_AWIDTH : integer := 9 + 1;--9 bit - Adress Registers + 1 bit command(write/read)
constant C_CCD_SPI_DWIDTH : integer := 16;


--Power Up sequences
type TCCD_RegINIT is array (0 to 19)
  of std_logic_vector(C_CCD_SPI_AWIDTH - 1 + C_CCD_SPI_DWIDTH - 1 downto 0);

--constant C_CCD_REGINIT : TCCD_RegINIT := (
--std_logic_vector(TO_UNSIGNED(10#002#, C_CCD_SPI_AWIDTH - 1)) & std_logic_vector(TO_UNSIGNED(16#0001#, C_CCD_SPI_DWIDTH)),
--std_logic_vector(TO_UNSIGNED(10#032#, C_CCD_SPI_AWIDTH - 1)) & std_logic_vector(TO_UNSIGNED(16#2002#, C_CCD_SPI_DWIDTH)),
--std_logic_vector(TO_UNSIGNED(10#034#, C_CCD_SPI_AWIDTH - 1)) & std_logic_vector(TO_UNSIGNED(16#0001#, C_CCD_SPI_DWIDTH)),
--std_logic_vector(TO_UNSIGNED(10#065#, C_CCD_SPI_AWIDTH - 1)) & std_logic_vector(TO_UNSIGNED(16#008B#, C_CCD_SPI_DWIDTH)),
--std_logic_vector(TO_UNSIGNED(10#066#, C_CCD_SPI_AWIDTH - 1)) & std_logic_vector(TO_UNSIGNED(16#53C6#, C_CCD_SPI_DWIDTH)),
--std_logic_vector(TO_UNSIGNED(10#067#, C_CCD_SPI_AWIDTH - 1)) & std_logic_vector(TO_UNSIGNED(16#0844#, C_CCD_SPI_DWIDTH)),
--std_logic_vector(TO_UNSIGNED(10#068#, C_CCD_SPI_AWIDTH - 1)) & std_logic_vector(TO_UNSIGNED(16#0086#, C_CCD_SPI_DWIDTH)),
--std_logic_vector(TO_UNSIGNED(10#128#, C_CCD_SPI_AWIDTH - 1)) & std_logic_vector(TO_UNSIGNED(16#4520#, C_CCD_SPI_DWIDTH)),
--std_logic_vector(TO_UNSIGNED(10#204#, C_CCD_SPI_AWIDTH - 1)) & std_logic_vector(TO_UNSIGNED(16#09E5#, C_CCD_SPI_DWIDTH)),
--std_logic_vector(TO_UNSIGNED(10#224#, C_CCD_SPI_AWIDTH - 1)) & std_logic_vector(TO_UNSIGNED(16#3E04#, C_CCD_SPI_DWIDTH)),
--std_logic_vector(TO_UNSIGNED(10#225#, C_CCD_SPI_AWIDTH - 1)) & std_logic_vector(TO_UNSIGNED(16#6733#, C_CCD_SPI_DWIDTH)),
--std_logic_vector(TO_UNSIGNED(10#129#, C_CCD_SPI_AWIDTH - 1)) & std_logic_vector(TO_UNSIGNED(16#C001#, C_CCD_SPI_DWIDTH)),
--std_logic_vector(TO_UNSIGNED(10#447#, C_CCD_SPI_AWIDTH - 1)) & std_logic_vector(TO_UNSIGNED(16#0BF1#, C_CCD_SPI_DWIDTH)),
--std_logic_vector(TO_UNSIGNED(10#448#, C_CCD_SPI_AWIDTH - 1)) & std_logic_vector(TO_UNSIGNED(16#0BC3#, C_CCD_SPI_DWIDTH)),
--std_logic_vector(TO_UNSIGNED(10#032#, C_CCD_SPI_AWIDTH - 1)) & std_logic_vector(TO_UNSIGNED(16#2003#, C_CCD_SPI_DWIDTH)),
--std_logic_vector(TO_UNSIGNED(10#064#, C_CCD_SPI_AWIDTH - 1)) & std_logic_vector(TO_UNSIGNED(16#0001#, C_CCD_SPI_DWIDTH)),
--std_logic_vector(TO_UNSIGNED(10#040#, C_CCD_SPI_AWIDTH - 1)) & std_logic_vector(TO_UNSIGNED(16#0003#, C_CCD_SPI_DWIDTH)),
--std_logic_vector(TO_UNSIGNED(10#048#, C_CCD_SPI_AWIDTH - 1)) & std_logic_vector(TO_UNSIGNED(16#0001#, C_CCD_SPI_DWIDTH)),
--std_logic_vector(TO_UNSIGNED(10#112#, C_CCD_SPI_AWIDTH - 1)) & std_logic_vector(TO_UNSIGNED(16#0007#, C_CCD_SPI_DWIDTH)),
--std_logic_vector(TO_UNSIGNED(10#192#, C_CCD_SPI_AWIDTH - 1)) & std_logic_vector(TO_UNSIGNED(16#0001#, C_CCD_SPI_DWIDTH))  --Reg 192[0]=1 - Start Image Capture CCD
--);
constant C_CCD_REGINIT : TCCD_RegINIT := (
std_logic_vector(TO_UNSIGNED(10#002#, C_CCD_SPI_AWIDTH - 1)) & std_logic_vector(TO_UNSIGNED(16#0001#, C_CCD_SPI_DWIDTH)),
std_logic_vector(TO_UNSIGNED(10#032#, C_CCD_SPI_AWIDTH - 1)) & std_logic_vector(TO_UNSIGNED(16#0005#, C_CCD_SPI_DWIDTH)),
std_logic_vector(TO_UNSIGNED(10#034#, C_CCD_SPI_AWIDTH - 1)) & std_logic_vector(TO_UNSIGNED(16#0001#, C_CCD_SPI_DWIDTH)),
std_logic_vector(TO_UNSIGNED(10#065#, C_CCD_SPI_AWIDTH - 1)) & std_logic_vector(TO_UNSIGNED(16#808B#, C_CCD_SPI_DWIDTH)),
std_logic_vector(TO_UNSIGNED(10#066#, C_CCD_SPI_AWIDTH - 1)) & std_logic_vector(TO_UNSIGNED(16#53C6#, C_CCD_SPI_DWIDTH)),
std_logic_vector(TO_UNSIGNED(10#067#, C_CCD_SPI_AWIDTH - 1)) & std_logic_vector(TO_UNSIGNED(16#0844#, C_CCD_SPI_DWIDTH)),
std_logic_vector(TO_UNSIGNED(10#068#, C_CCD_SPI_AWIDTH - 1)) & std_logic_vector(TO_UNSIGNED(16#0086#, C_CCD_SPI_DWIDTH)),
std_logic_vector(TO_UNSIGNED(10#128#, C_CCD_SPI_AWIDTH - 1)) & std_logic_vector(TO_UNSIGNED(16#4520#, C_CCD_SPI_DWIDTH)),
std_logic_vector(TO_UNSIGNED(10#204#, C_CCD_SPI_AWIDTH - 1)) & std_logic_vector(TO_UNSIGNED(16#09E5#, C_CCD_SPI_DWIDTH)),
std_logic_vector(TO_UNSIGNED(10#224#, C_CCD_SPI_AWIDTH - 1)) & std_logic_vector(TO_UNSIGNED(16#3E04#, C_CCD_SPI_DWIDTH)),
std_logic_vector(TO_UNSIGNED(10#225#, C_CCD_SPI_AWIDTH - 1)) & std_logic_vector(TO_UNSIGNED(16#6733#, C_CCD_SPI_DWIDTH)),
std_logic_vector(TO_UNSIGNED(10#129#, C_CCD_SPI_AWIDTH - 1)) & std_logic_vector(TO_UNSIGNED(16#C001#, C_CCD_SPI_DWIDTH)),
std_logic_vector(TO_UNSIGNED(10#447#, C_CCD_SPI_AWIDTH - 1)) & std_logic_vector(TO_UNSIGNED(16#0BF1#, C_CCD_SPI_DWIDTH)),
std_logic_vector(TO_UNSIGNED(10#448#, C_CCD_SPI_AWIDTH - 1)) & std_logic_vector(TO_UNSIGNED(16#0BC3#, C_CCD_SPI_DWIDTH)),
std_logic_vector(TO_UNSIGNED(10#032#, C_CCD_SPI_AWIDTH - 1)) & std_logic_vector(TO_UNSIGNED(16#0005#, C_CCD_SPI_DWIDTH)),
std_logic_vector(TO_UNSIGNED(10#064#, C_CCD_SPI_AWIDTH - 1)) & std_logic_vector(TO_UNSIGNED(16#0001#, C_CCD_SPI_DWIDTH)),
std_logic_vector(TO_UNSIGNED(10#040#, C_CCD_SPI_AWIDTH - 1)) & std_logic_vector(TO_UNSIGNED(16#0002#, C_CCD_SPI_DWIDTH)),
std_logic_vector(TO_UNSIGNED(10#048#, C_CCD_SPI_AWIDTH - 1)) & std_logic_vector(TO_UNSIGNED(16#0001#, C_CCD_SPI_DWIDTH)),
std_logic_vector(TO_UNSIGNED(10#112#, C_CCD_SPI_AWIDTH - 1)) & std_logic_vector(TO_UNSIGNED(16#0007#, C_CCD_SPI_DWIDTH)),
std_logic_vector(TO_UNSIGNED(10#192#, C_CCD_SPI_AWIDTH - 1)) & std_logic_vector(TO_UNSIGNED(16#0001#, C_CCD_SPI_DWIDTH))  --Reg 192[0]=1 - Start Image Capture CCD
);

constant C_CCD_SPI_READ_START_REG : integer := 0;


type TCCD_pinin is record
data_p : std_logic_vector(C_PCFG_CCD_LVDS_COUNT - 1 downto 0);
data_n : std_logic_vector(C_PCFG_CCD_LVDS_COUNT - 1 downto 0);

clk_p : std_logic;
clk_n : std_logic;

miso  : std_logic;
end record;

type TCCD_pinout is record
clk_p : std_logic;
clk_n : std_logic;

rst_n : std_logic;
trig  : std_logic;

sck  : std_logic;
ss_n : std_logic;
mosi : std_logic;--Master OUT, Slave IN
end record;

end ccd_vita25K_pkg;


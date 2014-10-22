-------------------------------------------------------------------------
-- Company     : Yansar
-- Engineer    : Golovachenko Victor
--
-- Create Date : 13.06.2014 15:09:01
-- Module Name : ccd_pkg
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

library work;
use work.prj_cfg.all;

package ccd_pkg is

--Codes SYNC Channel:
--10Bit per pix
constant C_CCD_CHSYNC_TRAINING : integer := 16#3A6#;
constant C_CCD_CHSYNC_BLACKPIX : integer := 16#015#;
constant C_CCD_CHSYNC_CRC      : integer := 16#059#;
constant C_CCD_CHSYNC_IMAGE    : integer := 16#035#;
constant C_CCD_CHSYNC_FS       : integer := 16#2AA#;-- 10_1010_1010
constant C_CCD_CHSYNC_FE       : integer := 16#32A#;-- 11_0010_1010
constant C_CCD_CHSYNC_LS       : integer := 16#0AA#;-- 00_1010_1010
constant C_CCD_CHSYNC_LE       : integer := 16#12A#;-- 01_0010_1010

constant C_CCD_SPI_AWIDTH : integer := 9 + 1;--9 bit - Adress Registers + 1 bit command(write/read)
constant C_CCD_SPI_DWIDTH : integer := 16;


--Power Up sequences
type TCCD_RegINIT is array (0 to 19)
  of std_logic_vector(C_CCD_SPI_AWIDTH - 1 + C_CCD_SPI_DWIDTH - 1 downto 0);

constant C_CCD_REGINIT : TCCD_RegINIT := (
std_logic_vector(TO_UNSIGNED(10#002#, C_CCD_SPI_AWIDTH - 1)) & std_logic_vector(TO_UNSIGNED(16#0001#, C_CCD_SPI_DWIDTH)),
std_logic_vector(TO_UNSIGNED(10#032#, C_CCD_SPI_AWIDTH - 1)) & std_logic_vector(TO_UNSIGNED(16#2002#, C_CCD_SPI_DWIDTH)),
std_logic_vector(TO_UNSIGNED(10#034#, C_CCD_SPI_AWIDTH - 1)) & std_logic_vector(TO_UNSIGNED(16#0001#, C_CCD_SPI_DWIDTH)),
std_logic_vector(TO_UNSIGNED(10#065#, C_CCD_SPI_AWIDTH - 1)) & std_logic_vector(TO_UNSIGNED(16#008B#, C_CCD_SPI_DWIDTH)),
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
std_logic_vector(TO_UNSIGNED(10#032#, C_CCD_SPI_AWIDTH - 1)) & std_logic_vector(TO_UNSIGNED(16#2003#, C_CCD_SPI_DWIDTH)),
std_logic_vector(TO_UNSIGNED(10#064#, C_CCD_SPI_AWIDTH - 1)) & std_logic_vector(TO_UNSIGNED(16#0001#, C_CCD_SPI_DWIDTH)),
std_logic_vector(TO_UNSIGNED(10#040#, C_CCD_SPI_AWIDTH - 1)) & std_logic_vector(TO_UNSIGNED(16#0003#, C_CCD_SPI_DWIDTH)),
std_logic_vector(TO_UNSIGNED(10#048#, C_CCD_SPI_AWIDTH - 1)) & std_logic_vector(TO_UNSIGNED(16#0001#, C_CCD_SPI_DWIDTH)),
std_logic_vector(TO_UNSIGNED(10#112#, C_CCD_SPI_AWIDTH - 1)) & std_logic_vector(TO_UNSIGNED(16#0007#, C_CCD_SPI_DWIDTH)),
std_logic_vector(TO_UNSIGNED(10#192#, C_CCD_SPI_AWIDTH - 1)) & std_logic_vector(TO_UNSIGNED(16#0000#, C_CCD_SPI_DWIDTH))  --Reg 192[0]=1 - Start Image Capture CCD
);
--std_logic_vector(TO_UNSIGNED(10#144#, C_CCD_SPI_AWIDTH - 1)) & std_logic_vector(TO_UNSIGNED(16#0000#, C_CCD_SPI_DWIDTH)), --Enable test pattern

--
type TCCD_ExpINIT is array (0 to 4 - 1)
  of std_logic_vector(C_CCD_SPI_AWIDTH - 1 + C_CCD_SPI_DWIDTH - 1 downto 0);

constant C_CCD_EXPINIT : TCCD_ExpINIT := (
std_logic_vector(TO_UNSIGNED(194, C_CCD_SPI_AWIDTH - 1)) & std_logic_vector(TO_UNSIGNED(4    , C_CCD_SPI_DWIDTH)), --fr_mode
std_logic_vector(TO_UNSIGNED(199, C_CCD_SPI_AWIDTH - 1)) & std_logic_vector(TO_UNSIGNED(32   , C_CCD_SPI_DWIDTH)), --mult_timer
std_logic_vector(TO_UNSIGNED(200, C_CCD_SPI_AWIDTH - 1)) & std_logic_vector(TO_UNSIGNED(19375, C_CCD_SPI_DWIDTH)), --fr_length
std_logic_vector(TO_UNSIGNED(201, C_CCD_SPI_AWIDTH - 1)) & std_logic_vector(TO_UNSIGNED(44562, C_CCD_SPI_DWIDTH))  --exposure
);

--
type TCCD_WinINIT is array (0 to (2 + (3 * 4)) - 1)
  of std_logic_vector(C_CCD_SPI_AWIDTH - 1 + C_CCD_SPI_DWIDTH - 1 downto 0);

--X0,X1 - must be multiples 64!!!
constant C_CCD_DEFAULT_WIN0_X0 :integer := ((5120 / 64) / 2) - ((C_PCFG_CCD_WIN_X / 64) / 2); --X_START
constant C_CCD_DEFAULT_WIN0_Y0 :integer :=  (5120 / 2)       - (C_PCFG_CCD_WIN_Y / 2);        --X_END
constant C_CCD_DEFAULT_WIN0_X1 :integer := ((5120 / 64) / 2) + ((C_PCFG_CCD_WIN_X / 64) / 2); --Y_START
constant C_CCD_DEFAULT_WIN0_Y1 :integer :=  (5120 / 2)       + (C_PCFG_CCD_WIN_Y / 2);        --Y_END

constant C_CCD_DEFAULT_WIN1_X0 :integer := 0        ;
constant C_CCD_DEFAULT_WIN1_Y0 :integer := 0        ;
constant C_CCD_DEFAULT_WIN1_X1 :integer := 4096 / 64;
constant C_CCD_DEFAULT_WIN1_Y1 :integer := 4096     ;

constant C_CCD_DEFAULT_WIN2_X0 :integer := 0        ;
constant C_CCD_DEFAULT_WIN2_Y0 :integer := 0        ;
constant C_CCD_DEFAULT_WIN2_X1 :integer := 4096 / 64;
constant C_CCD_DEFAULT_WIN2_Y1 :integer := 4096     ;

constant C_CCD_DEFAULT_WIN3_X0 :integer := 0        ;
constant C_CCD_DEFAULT_WIN3_Y0 :integer := 0        ;
constant C_CCD_DEFAULT_WIN3_X1 :integer := 4096 / 64;
constant C_CCD_DEFAULT_WIN3_Y1 :integer := 4096     ;

constant C_CCD_WININIT : TCCD_WinINIT := (
std_logic_vector(TO_UNSIGNED(195, C_CCD_SPI_AWIDTH - 1)) & std_logic_vector(TO_UNSIGNED(16#0001#, C_CCD_SPI_DWIDTH)), --RIO_ACTIVE(15..0)
std_logic_vector(TO_UNSIGNED(196, C_CCD_SPI_AWIDTH - 1)) & std_logic_vector(TO_UNSIGNED(16#0000#, C_CCD_SPI_DWIDTH)), --RIO_ACTIVE(31..16)

--RIO_0
std_logic_vector(TO_UNSIGNED((256 + (3 * 0) + 0), C_CCD_SPI_AWIDTH - 1)) & std_logic_vector(TO_UNSIGNED(C_CCD_DEFAULT_WIN0_X1 - 1, C_CCD_SPI_DWIDTH / 2))
                                                                         & std_logic_vector(TO_UNSIGNED(C_CCD_DEFAULT_WIN0_X0    , C_CCD_SPI_DWIDTH / 2)),
std_logic_vector(TO_UNSIGNED((256 + (3 * 0) + 1), C_CCD_SPI_AWIDTH - 1)) & std_logic_vector(TO_UNSIGNED(C_CCD_DEFAULT_WIN0_Y0    , C_CCD_SPI_DWIDTH))    ,
std_logic_vector(TO_UNSIGNED((256 + (3 * 0) + 2), C_CCD_SPI_AWIDTH - 1)) & std_logic_vector(TO_UNSIGNED(C_CCD_DEFAULT_WIN0_Y1 - 1, C_CCD_SPI_DWIDTH))    ,

--RIO_1
std_logic_vector(TO_UNSIGNED((256 + (3 * 1) + 0), C_CCD_SPI_AWIDTH - 1)) & std_logic_vector(TO_UNSIGNED(C_CCD_DEFAULT_WIN1_X1 - 1, C_CCD_SPI_DWIDTH / 2))
                                                                         & std_logic_vector(TO_UNSIGNED(C_CCD_DEFAULT_WIN1_X0    , C_CCD_SPI_DWIDTH / 2)),
std_logic_vector(TO_UNSIGNED((256 + (3 * 1) + 1), C_CCD_SPI_AWIDTH - 1)) & std_logic_vector(TO_UNSIGNED(C_CCD_DEFAULT_WIN1_Y0    , C_CCD_SPI_DWIDTH))    ,
std_logic_vector(TO_UNSIGNED((256 + (3 * 1) + 2), C_CCD_SPI_AWIDTH - 1)) & std_logic_vector(TO_UNSIGNED(C_CCD_DEFAULT_WIN1_Y1 - 1, C_CCD_SPI_DWIDTH))    ,

--RIO_2
std_logic_vector(TO_UNSIGNED((256 + (3 * 2) + 0), C_CCD_SPI_AWIDTH - 1)) & std_logic_vector(TO_UNSIGNED(C_CCD_DEFAULT_WIN2_X1 - 1, C_CCD_SPI_DWIDTH / 2))
                                                                         & std_logic_vector(TO_UNSIGNED(C_CCD_DEFAULT_WIN2_X0    , C_CCD_SPI_DWIDTH / 2)),
std_logic_vector(TO_UNSIGNED((256 + (3 * 2) + 1), C_CCD_SPI_AWIDTH - 1)) & std_logic_vector(TO_UNSIGNED(C_CCD_DEFAULT_WIN2_Y0    , C_CCD_SPI_DWIDTH))    ,
std_logic_vector(TO_UNSIGNED((256 + (3 * 2) + 2), C_CCD_SPI_AWIDTH - 1)) & std_logic_vector(TO_UNSIGNED(C_CCD_DEFAULT_WIN2_Y1 - 1, C_CCD_SPI_DWIDTH))    ,

--RIO_3
std_logic_vector(TO_UNSIGNED((256 + (3 * 3) + 0), C_CCD_SPI_AWIDTH - 1)) & std_logic_vector(TO_UNSIGNED(C_CCD_DEFAULT_WIN3_X1 - 1, C_CCD_SPI_DWIDTH / 2))
                                                                         & std_logic_vector(TO_UNSIGNED(C_CCD_DEFAULT_WIN3_X0    , C_CCD_SPI_DWIDTH / 2)),
std_logic_vector(TO_UNSIGNED((256 + (3 * 3) + 1), C_CCD_SPI_AWIDTH - 1)) & std_logic_vector(TO_UNSIGNED(C_CCD_DEFAULT_WIN3_Y0    , C_CCD_SPI_DWIDTH))    ,
std_logic_vector(TO_UNSIGNED((256 + (3 * 3) + 2), C_CCD_SPI_AWIDTH - 1)) & std_logic_vector(TO_UNSIGNED(C_CCD_DEFAULT_WIN3_Y1 - 1, C_CCD_SPI_DWIDTH))
);


--constant C_CCD_REGINIT : TCCD_RegINIT := (
--std_logic_vector(TO_UNSIGNED(10#002#, C_CCD_SPI_AWIDTH - 1)) & std_logic_vector(TO_UNSIGNED(16#0001#, C_CCD_SPI_DWIDTH)),
--std_logic_vector(TO_UNSIGNED(10#032#, C_CCD_SPI_AWIDTH - 1)) & std_logic_vector(TO_UNSIGNED(16#0005#, C_CCD_SPI_DWIDTH)),
--std_logic_vector(TO_UNSIGNED(10#034#, C_CCD_SPI_AWIDTH - 1)) & std_logic_vector(TO_UNSIGNED(16#0001#, C_CCD_SPI_DWIDTH)),
--std_logic_vector(TO_UNSIGNED(10#065#, C_CCD_SPI_AWIDTH - 1)) & std_logic_vector(TO_UNSIGNED(16#808B#, C_CCD_SPI_DWIDTH)),
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
--std_logic_vector(TO_UNSIGNED(10#032#, C_CCD_SPI_AWIDTH - 1)) & std_logic_vector(TO_UNSIGNED(16#0005#, C_CCD_SPI_DWIDTH)),
--std_logic_vector(TO_UNSIGNED(10#064#, C_CCD_SPI_AWIDTH - 1)) & std_logic_vector(TO_UNSIGNED(16#0001#, C_CCD_SPI_DWIDTH)),
--std_logic_vector(TO_UNSIGNED(10#040#, C_CCD_SPI_AWIDTH - 1)) & std_logic_vector(TO_UNSIGNED(16#0002#, C_CCD_SPI_DWIDTH)),
--std_logic_vector(TO_UNSIGNED(10#048#, C_CCD_SPI_AWIDTH - 1)) & std_logic_vector(TO_UNSIGNED(16#0001#, C_CCD_SPI_DWIDTH)),
--std_logic_vector(TO_UNSIGNED(10#112#, C_CCD_SPI_AWIDTH - 1)) & std_logic_vector(TO_UNSIGNED(16#0007#, C_CCD_SPI_DWIDTH)),
--std_logic_vector(TO_UNSIGNED(10#192#, C_CCD_SPI_AWIDTH - 1)) & std_logic_vector(TO_UNSIGNED(16#0001#, C_CCD_SPI_DWIDTH))  --Reg 192[0]=1 - Start Image Capture CCD
--);


--From AND9049-D.pdf - VITA Family Global Reset (IMPLEMENTATION FOR VITA25K)
type TCCD_RegINIT2 is array (0 to 54)
  of std_logic_vector(C_CCD_SPI_AWIDTH - 1 + C_CCD_SPI_DWIDTH - 1 downto 0);

constant C_CCD_REGINIT2 : TCCD_RegINIT2 := (
std_logic_vector(TO_UNSIGNED(10#384#, C_CCD_SPI_AWIDTH - 1)) & std_logic_vector(TO_UNSIGNED(16#1010#, C_CCD_SPI_DWIDTH)),
std_logic_vector(TO_UNSIGNED(10#385#, C_CCD_SPI_AWIDTH - 1)) & std_logic_vector(TO_UNSIGNED(16#729F#, C_CCD_SPI_DWIDTH)),
std_logic_vector(TO_UNSIGNED(10#386#, C_CCD_SPI_AWIDTH - 1)) & std_logic_vector(TO_UNSIGNED(16#729F#, C_CCD_SPI_DWIDTH)),
std_logic_vector(TO_UNSIGNED(10#387#, C_CCD_SPI_AWIDTH - 1)) & std_logic_vector(TO_UNSIGNED(16#729F#, C_CCD_SPI_DWIDTH)),
std_logic_vector(TO_UNSIGNED(10#388#, C_CCD_SPI_AWIDTH - 1)) & std_logic_vector(TO_UNSIGNED(16#729F#, C_CCD_SPI_DWIDTH)),
std_logic_vector(TO_UNSIGNED(10#389#, C_CCD_SPI_AWIDTH - 1)) & std_logic_vector(TO_UNSIGNED(16#701F#, C_CCD_SPI_DWIDTH)),
std_logic_vector(TO_UNSIGNED(10#390#, C_CCD_SPI_AWIDTH - 1)) & std_logic_vector(TO_UNSIGNED(16#701F#, C_CCD_SPI_DWIDTH)),
std_logic_vector(TO_UNSIGNED(10#391#, C_CCD_SPI_AWIDTH - 1)) & std_logic_vector(TO_UNSIGNED(16#549F#, C_CCD_SPI_DWIDTH)),
std_logic_vector(TO_UNSIGNED(10#392#, C_CCD_SPI_AWIDTH - 1)) & std_logic_vector(TO_UNSIGNED(16#549F#, C_CCD_SPI_DWIDTH)),
std_logic_vector(TO_UNSIGNED(10#393#, C_CCD_SPI_AWIDTH - 1)) & std_logic_vector(TO_UNSIGNED(16#541F#, C_CCD_SPI_DWIDTH)),
std_logic_vector(TO_UNSIGNED(10#394#, C_CCD_SPI_AWIDTH - 1)) & std_logic_vector(TO_UNSIGNED(16#541F#, C_CCD_SPI_DWIDTH)),
std_logic_vector(TO_UNSIGNED(10#395#, C_CCD_SPI_AWIDTH - 1)) & std_logic_vector(TO_UNSIGNED(16#101F#, C_CCD_SPI_DWIDTH)),
std_logic_vector(TO_UNSIGNED(10#396#, C_CCD_SPI_AWIDTH - 1)) & std_logic_vector(TO_UNSIGNED(16#101F#, C_CCD_SPI_DWIDTH)),
std_logic_vector(TO_UNSIGNED(10#397#, C_CCD_SPI_AWIDTH - 1)) & std_logic_vector(TO_UNSIGNED(16#1110#, C_CCD_SPI_DWIDTH)),
std_logic_vector(TO_UNSIGNED(10#219#, C_CCD_SPI_AWIDTH - 1)) & std_logic_vector(TO_UNSIGNED(16#412E#, C_CCD_SPI_DWIDTH)),
std_logic_vector(TO_UNSIGNED(10#430#, C_CCD_SPI_AWIDTH - 1)) & std_logic_vector(TO_UNSIGNED(16#0100#, C_CCD_SPI_DWIDTH)),
std_logic_vector(TO_UNSIGNED(10#431#, C_CCD_SPI_AWIDTH - 1)) & std_logic_vector(TO_UNSIGNED(16#03F1#, C_CCD_SPI_DWIDTH)),
std_logic_vector(TO_UNSIGNED(10#432#, C_CCD_SPI_AWIDTH - 1)) & std_logic_vector(TO_UNSIGNED(16#03C5#, C_CCD_SPI_DWIDTH)),
std_logic_vector(TO_UNSIGNED(10#433#, C_CCD_SPI_AWIDTH - 1)) & std_logic_vector(TO_UNSIGNED(16#0341#, C_CCD_SPI_DWIDTH)),
std_logic_vector(TO_UNSIGNED(10#434#, C_CCD_SPI_AWIDTH - 1)) & std_logic_vector(TO_UNSIGNED(16#0141#, C_CCD_SPI_DWIDTH)),
std_logic_vector(TO_UNSIGNED(10#435#, C_CCD_SPI_AWIDTH - 1)) & std_logic_vector(TO_UNSIGNED(16#214F#, C_CCD_SPI_DWIDTH)),
std_logic_vector(TO_UNSIGNED(10#436#, C_CCD_SPI_AWIDTH - 1)) & std_logic_vector(TO_UNSIGNED(16#2145#, C_CCD_SPI_DWIDTH)),
std_logic_vector(TO_UNSIGNED(10#437#, C_CCD_SPI_AWIDTH - 1)) & std_logic_vector(TO_UNSIGNED(16#0141#, C_CCD_SPI_DWIDTH)),
std_logic_vector(TO_UNSIGNED(10#438#, C_CCD_SPI_AWIDTH - 1)) & std_logic_vector(TO_UNSIGNED(16#0101#, C_CCD_SPI_DWIDTH)),
std_logic_vector(TO_UNSIGNED(10#439#, C_CCD_SPI_AWIDTH - 1)) & std_logic_vector(TO_UNSIGNED(16#0B8C#, C_CCD_SPI_DWIDTH)),
std_logic_vector(TO_UNSIGNED(10#440#, C_CCD_SPI_AWIDTH - 1)) & std_logic_vector(TO_UNSIGNED(16#0B8C#, C_CCD_SPI_DWIDTH)),
std_logic_vector(TO_UNSIGNED(10#441#, C_CCD_SPI_AWIDTH - 1)) & std_logic_vector(TO_UNSIGNED(16#0B8C#, C_CCD_SPI_DWIDTH)),
std_logic_vector(TO_UNSIGNED(10#442#, C_CCD_SPI_AWIDTH - 1)) & std_logic_vector(TO_UNSIGNED(16#0B8C#, C_CCD_SPI_DWIDTH)),
std_logic_vector(TO_UNSIGNED(10#443#, C_CCD_SPI_AWIDTH - 1)) & std_logic_vector(TO_UNSIGNED(16#0381#, C_CCD_SPI_DWIDTH)),
std_logic_vector(TO_UNSIGNED(10#444#, C_CCD_SPI_AWIDTH - 1)) & std_logic_vector(TO_UNSIGNED(16#0181#, C_CCD_SPI_DWIDTH)),
std_logic_vector(TO_UNSIGNED(10#445#, C_CCD_SPI_AWIDTH - 1)) & std_logic_vector(TO_UNSIGNED(16#218F#, C_CCD_SPI_DWIDTH)),
std_logic_vector(TO_UNSIGNED(10#446#, C_CCD_SPI_AWIDTH - 1)) & std_logic_vector(TO_UNSIGNED(16#2185#, C_CCD_SPI_DWIDTH)),
std_logic_vector(TO_UNSIGNED(10#447#, C_CCD_SPI_AWIDTH - 1)) & std_logic_vector(TO_UNSIGNED(16#0181#, C_CCD_SPI_DWIDTH)),
std_logic_vector(TO_UNSIGNED(10#448#, C_CCD_SPI_AWIDTH - 1)) & std_logic_vector(TO_UNSIGNED(16#0100#, C_CCD_SPI_DWIDTH)),
std_logic_vector(TO_UNSIGNED(10#449#, C_CCD_SPI_AWIDTH - 1)) & std_logic_vector(TO_UNSIGNED(16#0100#, C_CCD_SPI_DWIDTH)),
std_logic_vector(TO_UNSIGNED(10#450#, C_CCD_SPI_AWIDTH - 1)) & std_logic_vector(TO_UNSIGNED(16#0BF1#, C_CCD_SPI_DWIDTH)),
std_logic_vector(TO_UNSIGNED(10#451#, C_CCD_SPI_AWIDTH - 1)) & std_logic_vector(TO_UNSIGNED(16#0BC3#, C_CCD_SPI_DWIDTH)),
std_logic_vector(TO_UNSIGNED(10#452#, C_CCD_SPI_AWIDTH - 1)) & std_logic_vector(TO_UNSIGNED(16#0BC2#, C_CCD_SPI_DWIDTH)),
std_logic_vector(TO_UNSIGNED(10#453#, C_CCD_SPI_AWIDTH - 1)) & std_logic_vector(TO_UNSIGNED(16#0341#, C_CCD_SPI_DWIDTH)),
std_logic_vector(TO_UNSIGNED(10#454#, C_CCD_SPI_AWIDTH - 1)) & std_logic_vector(TO_UNSIGNED(16#0141#, C_CCD_SPI_DWIDTH)),
std_logic_vector(TO_UNSIGNED(10#455#, C_CCD_SPI_AWIDTH - 1)) & std_logic_vector(TO_UNSIGNED(16#214F#, C_CCD_SPI_DWIDTH)),
std_logic_vector(TO_UNSIGNED(10#456#, C_CCD_SPI_AWIDTH - 1)) & std_logic_vector(TO_UNSIGNED(16#2145#, C_CCD_SPI_DWIDTH)),
std_logic_vector(TO_UNSIGNED(10#457#, C_CCD_SPI_AWIDTH - 1)) & std_logic_vector(TO_UNSIGNED(16#0141#, C_CCD_SPI_DWIDTH)),
std_logic_vector(TO_UNSIGNED(10#458#, C_CCD_SPI_AWIDTH - 1)) & std_logic_vector(TO_UNSIGNED(16#0101#, C_CCD_SPI_DWIDTH)),
std_logic_vector(TO_UNSIGNED(10#459#, C_CCD_SPI_AWIDTH - 1)) & std_logic_vector(TO_UNSIGNED(16#0B8C#, C_CCD_SPI_DWIDTH)),
std_logic_vector(TO_UNSIGNED(10#460#, C_CCD_SPI_AWIDTH - 1)) & std_logic_vector(TO_UNSIGNED(16#0B8C#, C_CCD_SPI_DWIDTH)),
std_logic_vector(TO_UNSIGNED(10#461#, C_CCD_SPI_AWIDTH - 1)) & std_logic_vector(TO_UNSIGNED(16#0B8C#, C_CCD_SPI_DWIDTH)),
std_logic_vector(TO_UNSIGNED(10#462#, C_CCD_SPI_AWIDTH - 1)) & std_logic_vector(TO_UNSIGNED(16#0B8C#, C_CCD_SPI_DWIDTH)),
std_logic_vector(TO_UNSIGNED(10#463#, C_CCD_SPI_AWIDTH - 1)) & std_logic_vector(TO_UNSIGNED(16#0381#, C_CCD_SPI_DWIDTH)),
std_logic_vector(TO_UNSIGNED(10#464#, C_CCD_SPI_AWIDTH - 1)) & std_logic_vector(TO_UNSIGNED(16#0181#, C_CCD_SPI_DWIDTH)),
std_logic_vector(TO_UNSIGNED(10#465#, C_CCD_SPI_AWIDTH - 1)) & std_logic_vector(TO_UNSIGNED(16#218F#, C_CCD_SPI_DWIDTH)),
std_logic_vector(TO_UNSIGNED(10#466#, C_CCD_SPI_AWIDTH - 1)) & std_logic_vector(TO_UNSIGNED(16#2185#, C_CCD_SPI_DWIDTH)),
std_logic_vector(TO_UNSIGNED(10#467#, C_CCD_SPI_AWIDTH - 1)) & std_logic_vector(TO_UNSIGNED(16#0181#, C_CCD_SPI_DWIDTH)),
std_logic_vector(TO_UNSIGNED(10#468#, C_CCD_SPI_AWIDTH - 1)) & std_logic_vector(TO_UNSIGNED(16#0100#, C_CCD_SPI_DWIDTH)),
std_logic_vector(TO_UNSIGNED(10#197#, C_CCD_SPI_AWIDTH - 1)) & std_logic_vector(TO_UNSIGNED(16#0115#, C_CCD_SPI_DWIDTH)) --bit[8]=0/1 - blank out first line (No blank-out/Blank-out
);

type TCCD_pinin is record
data_p : std_logic_vector(C_PCFG_CCD_LVDS_COUNT - 1 downto 0);
data_n : std_logic_vector(C_PCFG_CCD_LVDS_COUNT - 1 downto 0);

clk_p : std_logic;
clk_n : std_logic;

miso  : std_logic;

monitor : std_logic_vector(2 downto 0);
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


type TCCD_vout is record
data : std_logic_vector((C_PCFG_CCD_LVDS_COUNT * C_PCFG_CCD_BIT_PER_PIXEL) - 1 downto 0);
den  : std_logic;
vs   : std_logic;
hs   : std_logic;
clk  : std_logic;
end record;

--CCD_FG
constant C_CCD_FG_STATUS_DRY_BIT      : integer := 0;
constant C_CCD_FG_STATUS_ALIGN_OK_BIT : integer := 1;
constant C_CCD_FG_STATUS_LAST_BIT : integer := C_CCD_FG_STATUS_ALIGN_OK_BIT;

--CCD_GLOB
constant C_CCD_STATUS_INIT_OK_BIT  : integer := 0;
constant C_CCD_STATUS_ALIGN_OK_BIT : integer := 1;
constant C_CCD_STATUS_LAST_BIT : integer := C_CCD_STATUS_ALIGN_OK_BIT;

end package ccd_pkg;


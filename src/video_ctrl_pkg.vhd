-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 05.06.2012 10:17:58
-- Module Name : video_ctrl_pkg
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

package video_ctrl_pkg is

constant C_VCTRL_VCH_COUNT : integer := 1;
--                                                   --Пиксели видеокадра(VLINE_LSB - 1...0)
constant C_VCTRL_MEM_VLINE_L_BIT  : integer:=13;--Строки видеокадра (MSB...LSB)
constant C_VCTRL_MEM_VLINE_M_BIT  : integer:=25;
constant C_VCTRL_MEM_VFR_L_BIT    : integer:=26;--Номер кадра (MSB...LSB) - Видеобуфера
constant C_VCTRL_MEM_VFR_M_BIT    : integer:=26;
--constant C_VCTRL_MEM_VCH_L_BIT    : integer:=29;--Номер видео канала (MSB...LSB)
--constant C_VCTRL_MEM_VCH_M_BIT    : integer:=31;

type TFrXYMirror is record
pix : std_logic;
row : std_logic;
end record;

--координаты
type TFrXY is record
pix : std_logic_vector(15 downto 0);
row : std_logic_vector(15 downto 0);
end record;

--skip -- начало зоны
--activ - размер зоны
type TFrXYParam is record
skip  : TFrXY;
activ : TFrXY;
end record;
--Type TFrXYParams is array (0 to C_VCTRL_VCH_COUNT - 1) of TFrXYParam;
--
----Параметры Видеоканала
--type TVctrlChParam is record
--mem_addr_wr    : std_logic_vector(31 downto 0);
--mem_addr_rd    : std_logic_vector(31 downto 0);
--fr_size        : TFrXYParam;
--fr_mirror      : TFrXYMirror;
--end record;
--type TVctrlChParams is array (0 to C_VCTRL_VCH_COUNT - 1) of TVctrlChParam;
--
----Параметры VCTRL
--type TVctrlParam is record
--mem_wd_trn_len  : std_logic_vector(7 downto 0);
--mem_rd_trn_len  : std_logic_vector(7 downto 0);
--ch              : TVctrlChParams;
--end record;

--Параметры модуля записи
type TWriterVCHParam is record
--mem_adr        : std_logic_vector(31 downto 0);
fr_size        : TFrXYParam;
end record;
Type TWriterVCHParams is array (0 to C_VCTRL_VCH_COUNT - 1) of TWriterVCHParam;

--Параметры модуля чтения
type TReaderVCHParam is record
--mem_adr        : std_logic_vector(31 downto 0);
fr_size        : TFrXYParam;
--fr_mirror      : TFrXYMirror;
end record;
Type TReaderVCHParams is array (0 to C_VCTRL_VCH_COUNT - 1) of TReaderVCHParam;


Type TVfrBufs is array (0 to C_VCTRL_VCH_COUNT - 1) of std_logic_vector(C_VCTRL_MEM_VFR_M_BIT - C_VCTRL_MEM_VFR_L_BIT downto 0);

Type TVMrks is array (0 to C_VCTRL_VCH_COUNT - 1) of std_logic_vector(31 downto 0);

end video_ctrl_pkg;


package body video_ctrl_pkg is

end video_ctrl_pkg;


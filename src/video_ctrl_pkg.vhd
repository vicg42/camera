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

type TFrXYMirror is record
x : std_logic;
y : std_logic;
end record;

type TFrXY is record
pix : std_logic_vector(15 downto 0);
row : std_logic_vector(15 downto 0);
end record;

type TFrXYParam is record
skip  : TFrXY;
activ : TFrXY;
end record;

--Параметры модуля записи
type TWriterVCHParam is record
fr_size        : TFrXYParam;
end record;
Type TWriterVCHParams is array (0 to C_VCTRL_VCH_COUNT - 1) of TWriterVCHParam;

--Параметры модуля чтения
type TReaderVCHParam is record
fr_size        : TFrXYParam;
frw_size       : TFrXYParam;
fr_mirror      : TFrXYMirror;
end record;
Type TReaderVCHParams is array (0 to C_VCTRL_VCH_COUNT - 1) of TReaderVCHParam;


Type TVfrBufs is array (0 to C_VCTRL_VCH_COUNT - 1) of std_logic_vector(C_VCTRL_MEM_VFR_M_BIT - C_VCTRL_MEM_VFR_L_BIT downto 0);

Type TVMrks is array (0 to C_VCTRL_VCH_COUNT - 1) of std_logic_vector(31 downto 0);

end package video_ctrl_pkg;

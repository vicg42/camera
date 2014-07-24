-------------------------------------------------------------------------
-- Company     : Ynasar
-- Engineer    : Golovachenko Victor
--
-- Create Date : 24.06.2014 9:41:44
-- Module Name : video_ctrl
--
-- Назначение/Описание :
--
-- Revision:
-- Revision 0.01 - File Created
-------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.vicg_common_pkg.all;
use work.reduce_pack.all;
use work.video_ctrl_pkg.all;
use work.mem_wr_pkg.all;

entity video_ctrl is
generic(
G_USR_OPT : std_logic_vector(7 downto 0) := (others=>'0');
G_DBGCS  : string := "OFF";
G_CCD_DWIDTH : integer := 256;
G_MEM_AWIDTH : integer := 32;
G_MEMWR_DWIDTH : integer := 32;
G_MEMRD_DWIDTH : integer := 32
);
port(
-------------------------------
--CFG
-------------------------------
p_in_vwrite_en        : in   std_logic;
p_in_memtrn_lenwr     : in   std_logic_vector(7 downto 0);
p_in_memtrn_lenrd     : in   std_logic_vector(7 downto 0);
p_in_vwrite_prm       : in   TWriterVCHParams;
p_in_vread_prm        : in   TReaderVCHParams;

-------------------------------
--CCD
-------------------------------
p_in_ccd_d            : in    std_logic_vector(G_CCD_DWIDTH - 1 downto 0);
p_in_ccd_den          : in    std_logic;
p_in_ccd_hs           : in    std_logic;
p_in_ccd_vs           : in    std_logic;
p_in_ccd_dclk         : in    std_logic;

---------------------------------
----VBUFI
---------------------------------
--p_in_vbufi_do         : in    std_logic_vector(G_MEMWR_DWIDTH - 1 downto 0);
--p_out_vbufi_rd        : out   std_logic;
--p_in_vbufi_empty      : in    std_logic;
--p_in_vbufi_full       : in    std_logic;
--p_in_vbufi_pfull      : in    std_logic;

-------------------------------
--VBUFO
-------------------------------
p_in_vbufo_rdclk      : in    std_logic;
p_out_vbufo_do        : out   std_logic_vector(8 - 1 downto 0);
p_in_vbufo_rd         : in    std_logic;
p_out_vbufo_empty     : out   std_logic;

---------------------------------
--MEM
---------------------------------
--CH WRITE
p_out_memwr           : out   TMemIN;
p_in_memwr            : in    TMemOUT;
--CH READ
p_out_memrd           : out   TMemIN;
p_in_memrd            : in    TMemOUT;

-------------------------------
--Технологический
-------------------------------
p_in_tst              : in    std_logic_vector(31 downto 0);
p_out_tst             : out   std_logic_vector(31 downto 0);

-------------------------------
--System
-------------------------------
p_in_clk              : in    std_logic;
p_in_rst              : in    std_logic
);
end video_ctrl;

architecture behavioral of video_ctrl is

component vbufi
port(
din         : IN  std_logic_vector(G_CCD_DWIDTH - 1 downto 0);
wr_en       : IN  std_logic;
wr_clk      : IN  std_logic;

dout        : OUT std_logic_vector(G_MEMWR_DWIDTH - 1 downto 0);
rd_en       : IN  std_logic;
rd_clk      : IN  std_logic;

empty       : OUT std_logic;
full        : OUT std_logic;
prog_full   : OUT std_logic;

rst         : IN  std_logic
);
end component;

component vbufo
port(
din         : IN  std_logic_vector(G_MEMRD_DWIDTH - 1 downto 0);
wr_en       : IN  std_logic;
wr_clk      : IN  std_logic;

dout        : OUT std_logic_vector(8 - 1 downto 0);
rd_en       : IN  std_logic;
rd_clk      : IN  std_logic;

empty       : OUT std_logic;
full        : OUT std_logic;
prog_full   : OUT std_logic;

rst         : IN  std_logic
);
end component;

component video_writer
generic(
G_USR_OPT         : std_logic_vector(3 downto 0):=(others=>'0');
G_DBGCS           : string :="OFF";
G_MEM_AWIDTH      : integer:=32;
G_MEM_DWIDTH      : integer:=32
);
port(
-------------------------------
--Конфигурирование
-------------------------------
p_in_mem_trn_len      : in    std_logic_vector(7 downto 0);
p_in_prm_vch          : in    TWriterVCHParams;
p_in_work_en          : in    std_logic;
p_in_vfr_buf          : in    TVfrBufs;

--Статусы
p_out_vfr_rdy         : out   std_logic;--_vector(C_VCTRL_VCH_COUNT - 1 downto 0);

----------------------------
--Upstream Port
----------------------------
p_in_upp_data         : in    std_logic_vector(G_MEM_DWIDTH - 1 downto 0);
p_out_upp_data_rd     : out   std_logic;
p_in_upp_buf_empty    : in    std_logic;
p_in_upp_buf_full     : in    std_logic;
p_in_upp_buf_pfull    : in    std_logic;

---------------------------------
--Связь с mem_ctrl.vhd
---------------------------------
p_out_mem             : out   TMemIN;
p_in_mem              : in    TMemOUT;

-------------------------------
--Технологический
-------------------------------
p_in_tst              : in    std_logic_vector(31 downto 0);
p_out_tst             : out   std_logic_vector(31 downto 0);

-------------------------------
--System
-------------------------------
p_in_clk              : in    std_logic;
p_in_rst              : in    std_logic
);
end component;

component video_reader
generic(
G_USR_OPT         : std_logic_vector(3 downto 0):=(others=>'0');
G_DBGCS           : string:="OFF";
G_MEM_AWIDTH      : integer:=32;
G_MEM_DWIDTH      : integer:=32
);
port(
-------------------------------
--Конфигурирование
-------------------------------
p_in_mem_trn_len     : in    std_logic_vector(7 downto 0);
p_in_prm_vch         : in    TReaderVCHParams;
p_in_work_en         : in    std_logic;
p_in_vfr_buf         : in    TVfrBufs;
p_in_vfr_nrow        : in    std_logic;

--Статусы
p_out_vch_fr_new     : out   std_logic;
p_out_vch_rd_done    : out   std_logic;
p_out_vch            : out   std_logic_vector(3 downto 0);
p_out_vch_active_pix : out   std_logic_vector(15 downto 0);
p_out_vch_active_row : out   std_logic_vector(15 downto 0);
p_out_vch_mirx       : out   std_logic;

----------------------------
--Upstream Port
----------------------------
p_out_upp_data       : out   std_logic_vector(G_MEM_DWIDTH - 1 downto 0);
p_out_upp_data_wd    : out   std_logic;
p_in_upp_buf_empty   : in    std_logic;
p_in_upp_buf_full    : in    std_logic;

---------------------------------
--Связь с mem_ctrl.vhd
---------------------------------
p_out_mem            : out   TMemIN;
p_in_mem             : in    TMemOUT;

-------------------------------
--Технологический
-------------------------------
p_in_tst             : in    std_logic_vector(31 downto 0);
p_out_tst            : out   std_logic_vector(31 downto 0);

-------------------------------
--System
-------------------------------
p_in_clk             : in    std_logic;
p_in_rst             : in    std_logic
);
end component;

signal i_vbuf_wr                         : TVfrBufs;
signal i_vbuf_rd                         : TVfrBufs;
signal i_vwrite_vfr_rdy                  : std_logic;--_vector(C_VCTRL_VCH_COUNT - 1 downto 0);
signal i_vbufo_full                      : std_logic;
signal i_vbufo_rst                       : std_logic;

signal i_vbufi_do                        : std_logic_vector(G_MEMWR_DWIDTH - 1 downto 0);
signal i_vbufi_rd                        : std_logic;
signal i_vbufi_empty                     : std_logic;
signal i_vbufi_full                      : std_logic;
signal i_vbufi_pfull                     : std_logic;
signal i_vfr_rdy                         : std_logic := '0';
signal i_vread_en                        : std_logic := '0';
signal i_vwrite_en                       : std_logic := '0';
signal sr_vwrite_en                      : std_logic_vector(0 to 1);
signal i_vreader_dout                    : std_logic_vector(G_MEMRD_DWIDTH - 1 downto 0);
signal i_vreader_dout_en                 : std_logic;

signal tst_vwriter_out                   : std_logic_vector(31 downto 0);
signal tst_vreader_out                   : std_logic_vector(31 downto 0);
signal tst_ctrl                          : std_logic_vector(31 downto 0);


--MAIN
begin


------------------------------------
--Технологические сигналы
------------------------------------
gen_dbgcs_off : if strcmp(G_DBGCS,"OFF") generate
p_out_tst(0) <= '0';
p_out_tst(4 downto 1) <=tst_vwriter_out(4 downto 1);
p_out_tst(8 downto 5) <=tst_vreader_out(3 downto 0);
p_out_tst(15 downto 9) <= (others=>'0');
p_out_tst(19 downto 16) <= (others=>'0');
p_out_tst(25 downto 20) <= (others=>'0');
p_out_tst(31 downto 26) <= tst_vwriter_out(31 downto 26);
end generate gen_dbgcs_off;

gen_dbgcs_on : if strcmp(G_DBGCS,"ON") generate
p_out_tst(0) <= OR_reduce(tst_vwriter_out) or OR_reduce(tst_vreader_out);
p_out_tst(4 downto 1) <= tst_vwriter_out(3 downto 0);
p_out_tst(8 downto 5) <= tst_vreader_out(3 downto 0);
p_out_tst(9)          <= tst_vwriter_out(4);
p_out_tst(10)         <= tst_vreader_out(4);
p_out_tst(25 downto 11) <= (others=>'0');
p_out_tst(31 downto 26) <= tst_vwriter_out(31 downto 26);
end generate gen_dbgcs_on;


----------------------------------------------------
--Выходной видеобуфер
----------------------------------------------------
m_bufi : vbufi
port map(
din         => p_in_ccd_d,
wr_en       => p_in_ccd_den,
wr_clk      => p_in_ccd_dclk,

dout        => i_vbufi_do,
rd_en       => i_vbufi_rd,
rd_clk      => p_in_clk,

empty       => i_vbufi_empty,
full        => i_vbufi_full,
prog_full   => i_vbufi_pfull,

rst         => p_in_rst
);

--###########################################
--Запись видео информации в ОЗУ
--###########################################
m_frwr : video_writer
generic map(
G_USR_OPT         => G_USR_OPT(3 downto 0),
G_DBGCS           => G_DBGCS,
G_MEM_AWIDTH      => G_MEM_AWIDTH,
G_MEM_DWIDTH      => G_MEMWR_DWIDTH
)
port map(
-------------------------------
--Конфигурирование
-------------------------------
p_in_mem_trn_len      => p_in_memtrn_lenwr,
p_in_prm_vch          => p_in_vwrite_prm,
p_in_work_en          => i_vwrite_en,
p_in_vfr_buf          => i_vbuf_wr,

--Статусы
p_out_vfr_rdy         => i_vwrite_vfr_rdy,

----------------------------
--Upstream Port
----------------------------
p_in_upp_data         => i_vbufi_do,
p_out_upp_data_rd     => i_vbufi_rd,
p_in_upp_buf_empty    => i_vbufi_empty,
p_in_upp_buf_full     => i_vbufi_full,
p_in_upp_buf_pfull    => i_vbufi_pfull,

---------------------------------
--Связь с mem_ctrl.vhd
---------------------------------
p_out_mem             => p_out_memwr,
p_in_mem              => p_in_memwr,

-------------------------------
--Технологический
-------------------------------
p_in_tst              => tst_ctrl(31 downto 0),--(others=>'0'),
p_out_tst             => tst_vwriter_out,

-------------------------------
--System
-------------------------------
p_in_clk              => p_in_clk,
p_in_rst              => p_in_rst
);


process(p_in_clk)
begin
if rising_edge(p_in_clk) then
  if p_in_rst = '1' then
    i_vfr_rdy <= '0';
    i_vread_en <= '0';

  else
    i_vwrite_en <= p_in_vwrite_en;

    if i_vwrite_vfr_rdy = '1' then
      i_vfr_rdy <= '1';
    end if;

    if i_vwrite_en = '0' then
      i_vread_en <= '0';

    elsif i_vfr_rdy = '1' then
      if i_vwrite_en = '1' then
        i_vread_en <= '1';
      end if;
    end if;

  end if;
end if;
end process;


--###########################################
--Модуль чтение видео информации из ОЗУ
--###########################################
m_frrd : video_reader
generic map(
G_USR_OPT         => G_USR_OPT(7 downto 4),
G_DBGCS           => G_DBGCS,
G_MEM_AWIDTH      => G_MEM_AWIDTH,
G_MEM_DWIDTH      => G_MEMRD_DWIDTH
)
port map(
-------------------------------
--Конфигурирование
-------------------------------
p_in_mem_trn_len      => p_in_memtrn_lenrd,
p_in_prm_vch          => p_in_vread_prm,
p_in_work_en          => i_vread_en,
p_in_vfr_buf          => i_vbuf_rd,
p_in_vfr_nrow         => '0',

--Статусы
p_out_vch_fr_new      => open,
p_out_vch_rd_done     => open,
p_out_vch             => open,
p_out_vch_active_pix  => open,
p_out_vch_active_row  => open,
p_out_vch_mirx        => open,

----------------------------
--Upstream Port
----------------------------
p_out_upp_data        => i_vreader_dout,
p_out_upp_data_wd     => i_vreader_dout_en,
p_in_upp_buf_empty    => '0',
p_in_upp_buf_full     => i_vbufo_full,

---------------------------------
--Связь с mem_ctrl.vhd
---------------------------------
p_out_mem             => p_out_memrd,
p_in_mem              => p_in_memrd,

-------------------------------
--Технологический
-------------------------------
p_in_tst              => tst_ctrl(31 downto 0),--(others=>'0'),
p_out_tst             => tst_vreader_out,

-------------------------------
--System
-------------------------------
p_in_clk              => p_in_clk,
p_in_rst              => p_in_rst
);


----------------------------------------------------
--Выходной видеобуфер
----------------------------------------------------
m_bufo : vbufo
port map(
din         => i_vreader_dout,
wr_en       => i_vreader_dout_en,
wr_clk      => p_in_clk,

dout        => p_out_vbufo_do,
rd_en       => p_in_vbufo_rd,
rd_clk      => p_in_vbufo_rdclk,

empty       => p_out_vbufo_empty,
full        => open,
prog_full   => i_vbufo_full,

rst         => i_vbufo_rst
);

i_vbufo_rst <= p_in_rst or p_in_tst(0);




--END MAIN
end behavioral;


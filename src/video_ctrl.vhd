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
G_VBUFI_DWIDTH : integer := 32;
G_VBUFO_DWIDTH : integer := 32;
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
p_in_vread_sync       : in   std_logic;

-------------------------------
--CCD
-------------------------------
p_in_ccd_d            : in    std_logic_vector(G_VBUFI_DWIDTH - 1 downto 0);
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
p_out_vbufo_do        : out   std_logic_vector(G_VBUFO_DWIDTH - 1 downto 0);
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
end entity video_ctrl;

architecture behavioral of video_ctrl is

constant CI_FILTER_BRAM_SIZE_BYTE : integer := 8192;

component vbufi
port(
din         : IN  std_logic_vector(G_VBUFI_DWIDTH - 1 downto 0);
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
end component vbufi;

component vbufo
port(
din         : IN  std_logic_vector(G_MEMRD_DWIDTH - 1 downto 0);
wr_en       : IN  std_logic;
wr_clk      : IN  std_logic;

dout        : OUT std_logic_vector(G_VBUFO_DWIDTH - 1 downto 0);
rd_en       : IN  std_logic;
rd_clk      : IN  std_logic;

empty       : OUT std_logic;
full        : OUT std_logic;
prog_full   : OUT std_logic;

rst         : IN  std_logic
);
end component vbufo;

component vbufo2
port(
din         : IN  std_logic_vector(G_VBUFO_DWIDTH - 1 downto 0);
wr_en       : IN  std_logic;
wr_clk      : IN  std_logic;

dout        : OUT std_logic_vector(G_VBUFO_DWIDTH - 1 downto 0);
rd_en       : IN  std_logic;
rd_clk      : IN  std_logic;

empty       : OUT std_logic;
full        : OUT std_logic;
prog_full   : OUT std_logic;

rst         : IN  std_logic
);
end component vbufo2;

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
end component video_writer;

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
p_in_vread_sync      : in    std_logic;

--Статусы
p_out_vch_fr_new     : out   std_logic;
p_out_vch_rd_done    : out   std_logic;
p_out_vch            : out   std_logic_vector(3 downto 0);
p_out_vch_active_pix : out   std_logic_vector(15 downto 0);
p_out_vch_active_row : out   std_logic_vector(15 downto 0);
p_out_vch_mirx       : out   std_logic;
p_out_vch_eof        : out   std_logic;

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
end component video_reader;

component vmirx_main is
generic(
G_BRAM_SIZE_BYTE : integer := 8;
G_DI_WIDTH : integer := 8;
G_DO_WIDTH : integer := 8
);
port(
-------------------------------
--CFG
-------------------------------
p_in_cfg_mirx       : in    std_logic;
p_in_cfg_pix_count  : in    std_logic_vector(15 downto 0);

----------------------------
--Upstream Port (IN)
----------------------------
p_in_upp_data       : in    std_logic_vector(G_DI_WIDTH - 1 downto 0);
p_in_upp_wr         : in    std_logic;
p_out_upp_rdy_n     : out   std_logic;
p_in_upp_eof        : in    std_logic;

----------------------------
--Downstream Port (OUT)
----------------------------
p_out_dwnp_data     : out   std_logic_vector(G_DO_WIDTH - 1 downto 0);
p_out_dwnp_wr       : out   std_logic;
p_in_dwnp_rdy_n     : in    std_logic;
p_out_dwnp_eof      : out   std_logic;
p_out_dwnp_eol      : out   std_logic;

-------------------------------
--DBG
-------------------------------
p_in_tst            : in    std_logic_vector(31 downto 0);
p_out_tst           : out   std_logic_vector(31 downto 0);

-------------------------------
--System
-------------------------------
p_in_clk            : in    std_logic;
p_in_rst            : in    std_logic
);
end component vmirx_main;

component bayer_main is
generic(
G_BRAM_SIZE_BYTE : integer := 12;
G_DWIDTH : integer := 8
);
port(
-------------------------------
--CFG
-------------------------------
p_in_cfg_colorfst  : in    std_logic_vector(1 downto 0);
p_in_cfg_pix_count : in    std_logic_vector(15 downto 0);
p_in_cfg_init      : in    std_logic;

----------------------------
--Upstream Port (IN)
----------------------------
p_in_upp_data      : in    std_logic_vector(G_DWIDTH - 1 downto 0);
p_in_upp_wr        : in    std_logic;
p_out_upp_rdy_n    : out   std_logic;
p_in_upp_eof       : in    std_logic;

----------------------------
--Downstream Port (OUT)
----------------------------
p_out_dwnp_data    : out   std_logic_vector((G_DWIDTH * 3) - 1 downto 0);
p_out_dwnp_wr      : out   std_logic;
p_in_dwnp_rdy_n    : in    std_logic;
p_out_dwnp_eof     : out   std_logic;
p_out_dwnp_eol     : out   std_logic;

-------------------------------
--DBG
-------------------------------
p_in_tst           : in    std_logic_vector(31 downto 0);
p_out_tst          : out   std_logic_vector(31 downto 0);

-------------------------------
--System
-------------------------------
p_in_clk           : in    std_logic;
p_in_rst           : in    std_logic
);
end component bayer_main;


signal i_ccd_d_swap                      : std_logic_vector(p_in_ccd_d'range);
signal i_vbuf_wr                         : TVfrBufs;
signal i_vbuf_rd                         : TVfrBufs;
signal i_vwrite_vfr_rdy                  : std_logic;
signal i_vbufo_wr                        : std_logic;
signal i_vbufo_di                        : std_logic_vector(G_MEMRD_DWIDTH - 1 downto 0);
signal i_vbufo_full                      : std_logic;
signal i_vbufo_rst                       : std_logic;
signal i_vbufi_do                        : std_logic_vector(G_MEMWR_DWIDTH - 1 downto 0);
signal i_vbufi_rd                        : std_logic;
signal i_vbufi_empty                     : std_logic;
signal i_vbufi_full                      : std_logic;
signal i_vbufi_pfull                     : std_logic;
signal i_vbufi_rst                       : std_logic;
signal i_vfr_rdy                         : std_logic := '0';
signal i_vread_en                        : std_logic := '0';
signal i_vwrite_en                       : std_logic := '0';
signal i_vreader_do                      : std_logic_vector(G_MEMRD_DWIDTH - 1 downto 0);
signal i_vreader_den                     : std_logic;
signal i_vreader_eof                     : std_logic;
signal i_vreader_active_pix              : std_logic_vector(15 downto 0);
signal i_vreader_active_row              : std_logic_vector(15 downto 0);
signal i_vreader_vfr_new                 : std_logic;
signal i_vreader_mirx                    : std_logic;
signal i_mirx_rdy_n                      : std_logic;
signal i_mirx_do                         : std_logic_vector(8 - 1 downto 0);
signal i_mirx_den                        : std_logic;
signal i_mirx_eof                        : std_logic;
signal i_mirx_eol                        : std_logic;
signal i_bayer_rdy_n                     : std_logic;
signal i_bayer_do                        : std_logic_vector((8 * 3) - 1 downto 0);
signal i_bayer_den                       : std_logic;
signal i_bayer_eof                       : std_logic;

signal tst_vwriter_out                   : std_logic_vector(31 downto 0);
signal tst_vreader_out                   : std_logic_vector(31 downto 0);
signal tst_ctrl                          : std_logic_vector(31 downto 0);
signal i_vbufo_empty                     : std_logic;
signal tst_vbufi_empty                   : std_logic;
signal tst_vbufi_pfull                   : std_logic;
signal tst_vbufo_empty                   : std_logic;
signal tst_vbufo_full                    : std_logic;


begin ----architecture behavioral


------------------------------------
--Технологические сигналы
------------------------------------
gen_dbgcs_off : if strcmp(G_DBGCS,"OFF") generate
p_out_tst(0) <= '0';
p_out_tst(4 downto 1) <=tst_vwriter_out(4 downto 1);
p_out_tst(8 downto 5) <=tst_vreader_out(3 downto 0);
p_out_tst(9)          <= i_vread_en;
p_out_tst(15 downto 10) <= (others=>'0');
p_out_tst(19 downto 16) <= (others=>'0');
p_out_tst(25 downto 20) <= (others=>'0');
p_out_tst(31 downto 26) <= tst_vwriter_out(31 downto 26);
end generate gen_dbgcs_off;

gen_dbgcs_on : if strcmp(G_DBGCS,"ON") generate
p_out_tst(0) <= OR_reduce(tst_vwriter_out) or OR_reduce(tst_vreader_out);
p_out_tst(4 downto 1) <= tst_vwriter_out(3 downto 0);
p_out_tst(8 downto 5) <= tst_vreader_out(3 downto 0);
p_out_tst(9)          <= i_vread_en;
p_out_tst(10)         <= tst_vreader_out(4)
or tst_vbufi_empty
or tst_vbufi_pfull
or tst_vbufo_empty
or tst_vbufo_full;

p_out_tst(25 downto 11) <= (others=>'0');
p_out_tst(31 downto 26) <= tst_vwriter_out(31 downto 26);

process(p_in_clk)
begin
if rising_edge(p_in_clk) then
tst_vbufi_empty <= i_vbufi_empty;
tst_vbufi_pfull <= i_vbufi_pfull;
tst_vbufo_empty <= i_vbufo_empty;
tst_vbufo_full  <= i_vbufo_full ;
end if;
end process;

end generate gen_dbgcs_on;


----------------------------------------------------
--Выходной видеобуфер
----------------------------------------------------
gen_bufi_swap : for i in 0 to (G_VBUFI_DWIDTH / G_MEMWR_DWIDTH) - 1 generate begin
i_ccd_d_swap((i_ccd_d_swap'length - (G_MEMWR_DWIDTH * i)) - 1 downto
                              (i_ccd_d_swap'length - (G_MEMWR_DWIDTH * (i + 1)) ))
                                      <= p_in_ccd_d(G_MEMWR_DWIDTH * (i + 1) - 1 downto (G_MEMWR_DWIDTH * i));
end generate gen_bufi_swap;

m_bufi : vbufi
port map(
din         => i_ccd_d_swap,
wr_en       => p_in_ccd_den,
wr_clk      => p_in_ccd_dclk,

dout        => i_vbufi_do,
rd_en       => i_vbufi_rd,
rd_clk      => p_in_clk,

empty       => i_vbufi_empty,
full        => i_vbufi_full ,
prog_full   => i_vbufi_pfull,

rst         => i_vbufi_rst
);

i_vbufi_rst <= p_in_rst;-- or not p_in_vwrite_en;


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
    i_vwrite_en <= '0';

  else
    if i_vbufi_empty = '0' then
      i_vwrite_en <= '1';
    end if;

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
p_in_vfr_nrow         => i_mirx_eol,
p_in_vread_sync       => p_in_vread_sync,

--Статусы
p_out_vch_fr_new      => i_vreader_vfr_new,
p_out_vch_rd_done     => open,
p_out_vch             => open,
p_out_vch_active_pix  => i_vreader_active_pix,
p_out_vch_active_row  => i_vreader_active_row,
p_out_vch_mirx        => i_vreader_mirx,
p_out_vch_eof         => i_vreader_eof,

----------------------------
--Upstream Port
----------------------------
p_out_upp_data        => i_vreader_do,
p_out_upp_data_wd     => i_vreader_den,
p_in_upp_buf_empty    => '0',
p_in_upp_buf_full     => i_mirx_rdy_n, --i_vbufo_full,

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


-------------------------------
--Отзеркаливания по Х
-------------------------------
m_vmirx : vmirx_main
generic map(
G_BRAM_SIZE_BYTE => CI_FILTER_BRAM_SIZE_BYTE,
G_DI_WIDTH => G_MEMRD_DWIDTH,
G_DO_WIDTH => 8
)
port map(
-------------------------------
--CFG
-------------------------------
p_in_cfg_mirx       => i_vreader_mirx,
p_in_cfg_pix_count  => i_vreader_active_pix,

----------------------------
--Upstream Port (IN)
----------------------------
p_in_upp_data       => i_vreader_do,
p_in_upp_wr         => i_vreader_den,
p_out_upp_rdy_n     => i_mirx_rdy_n,
p_in_upp_eof        => i_vreader_eof,

----------------------------
--Downstream Port (OUT)
----------------------------
p_out_dwnp_data     => i_mirx_do,     --i_mirx_do,    --
p_out_dwnp_wr       => i_mirx_den,    --i_mirx_den,   --
p_in_dwnp_rdy_n     => i_bayer_rdy_n, --i_vbufo_full, --
p_out_dwnp_eof      => i_mirx_eof,    --i_mirx_eof,   --
p_out_dwnp_eol      => i_mirx_eol,    --i_mirx_eol,   --

-------------------------------
--DBG
-------------------------------
p_in_tst            => (others => '0'),
p_out_tst           => open,

-------------------------------
--System
-------------------------------
p_in_clk            => p_in_clk,
p_in_rst            => i_vbufo_rst
);


m_bayer : bayer_main
generic map(
G_BRAM_SIZE_BYTE => CI_FILTER_BRAM_SIZE_BYTE,
G_DWIDTH => 8
)
port map(
-------------------------------
--CFG
-------------------------------
p_in_cfg_colorfst  => (others => '0'),
p_in_cfg_pix_count => i_vreader_active_pix,
p_in_cfg_init      => '0',

----------------------------
--Upstream Port (IN)
----------------------------
p_in_upp_data      => i_mirx_do,
p_in_upp_wr        => i_mirx_den,
p_out_upp_rdy_n    => i_bayer_rdy_n,
p_in_upp_eof       => i_mirx_eof,

----------------------------
--Downstream Port (OUT)
----------------------------
p_out_dwnp_data    => i_bayer_do,
p_out_dwnp_wr      => i_bayer_den,
p_in_dwnp_rdy_n    => i_vbufo_full,
p_out_dwnp_eof     => i_bayer_eof,
p_out_dwnp_eol     => open,

-------------------------------
--DBG
-------------------------------
p_in_tst           => (others => '0'),
p_out_tst          => open,

-------------------------------
--System
-------------------------------
p_in_clk           => p_in_clk,
p_in_rst           => i_vbufo_rst
);


----------------------------------------------------
--Выходной видеобуфер
----------------------------------------------------
--gen_bufo_swap : for i in 0 to (G_MEMRD_DWIDTH / p_out_vbufo_do'length) - 1 generate begin
--i_vbufo_di((i_vbufo_di'length - (p_out_vbufo_do'length * i)) - 1 downto
--                              (i_vbufo_di'length - (p_out_vbufo_do'length * (i + 1)) ))
--                                      <= i_mirx_do(p_out_vbufo_do'length * (i + 1) - 1 downto (p_out_vbufo_do'length * i));
--end generate gen_bufo_swap;

i_vbufo_di <= std_logic_vector(RESIZE(UNSIGNED(i_bayer_do), i_vbufo_di'length));
i_vbufo_wr <= i_bayer_den;
--i_vbufo_di <= std_logic_vector(RESIZE(UNSIGNED(i_mirx_do), i_vbufo_di'length));
--i_vbufo_wr <= i_mirx_den;

m_bufo : vbufo
port map(
din         => i_vbufo_di,
wr_en       => i_vbufo_wr,
wr_clk      => p_in_clk,

dout        => p_out_vbufo_do,
rd_en       => p_in_vbufo_rd,
rd_clk      => p_in_vbufo_rdclk,

empty       => i_vbufo_empty,
full        => open,
prog_full   => i_vbufo_full,

rst         => i_vbufo_rst
);

i_vbufo_rst <= p_in_rst or not i_vread_en;

p_out_vbufo_empty <= i_vbufo_empty;


end architecture behavioral;


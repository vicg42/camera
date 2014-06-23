-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 05.06.2012 10:17:52
-- Module Name : video_ctrl
--
-- Назначение/Описание :
--  Формирование/Запись/Чтение кадров видеоканалов
--
-- Revision:
-- Revision 0.01 - File Created
-------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_misc.all;
use ieee.std_logic_unsigned.all;

library work;
use work.vicg_common_pkg.all;
use work.prj_def.all;
use work.video_ctrl_pkg.all;
use work.mem_wr_pkg.all;

entity video_ctrl is
generic(
G_USR_OPT : std_logic_vector(7 downto 0):=(others=>'0');
G_DBGCS  : string:="OFF";
G_SIM    : string:="OFF";

G_MEM_AWIDTH : integer:=32;
G_MEMWR_DWIDTH : integer:=32;
G_MEMRD_DWIDTH : integer:=32
);
port(
-------------------------------
--HOST
-------------------------------
p_in_hrdchsel         : in    std_logic_vector(3 downto 0);   --Номер видео канала который будет читать ХОСТ
p_in_hrdstart         : in    std_logic;                      --Начало чтенения видеоканала
p_in_hrddone          : in    std_logic;                      --Подтверждение вычетки данных видеоканала
p_out_hirq            : out   std_logic_vector(C_VCTRL_VCH_COUNT - 1 downto 0);--Готовность кадра соответствующего видеоканала
p_out_hdrdy           : out   std_logic_vector(C_VCTRL_VCH_COUNT - 1 downto 0);--Прерываение соответствующего видеоканала(Кадр готов)
p_out_hfrmrk          : out   std_logic_vector(31 downto 0);

p_in_vbufo_rdclk      : in    std_logic;
p_out_vbufo_do        : out   std_logic_vector(G_MEMRD_DWIDTH - 1 downto 0);--Видео данные для ХОСТА
p_in_vbufo_rd         : in    std_logic;
p_out_vbufo_empty     : out   std_logic;

-------------------------------
--VBUFI
-------------------------------
p_in_vbufi_do         : in    std_logic_vector(G_MEMWR_DWIDTH - 1 downto 0);
p_out_vbufi_rd        : out   std_logic;
p_in_vbufi_empty      : in    std_logic;
p_in_vbufi_full       : in    std_logic;
p_in_vbufi_pfull      : in    std_logic;

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

component host_vbuf
port(
din         : IN  std_logic_vector(G_MEMRD_DWIDTH - 1 downto 0);
wr_en       : IN  std_logic;
wr_clk      : IN  std_logic;

dout        : OUT std_logic_vector(G_MEMRD_DWIDTH - 1 downto 0);
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
G_MEM_BANK_M_BIT  : integer:=29;
G_MEM_BANK_L_BIT  : integer:=28;

G_MEM_VCH_M_BIT   : integer:=25;
G_MEM_VCH_L_BIT   : integer:=24;
G_MEM_VFR_M_BIT   : integer:=23;
G_MEM_VFR_L_BIT   : integer:=23;
G_MEM_VLINE_M_BIT : integer:=22;
G_MEM_VLINE_L_BIT : integer:=12;

G_MEM_AWIDTH      : integer:=32;
G_MEM_DWIDTH      : integer:=32
);
port(
-------------------------------
-- Конфигурирование
-------------------------------
p_in_cfg_mem_trn_len  : in    std_logic_vector(7 downto 0);
p_in_cfg_prm_vch      : in    TWriterVCHParams;

p_in_vfr_buf          : in    TVfrBufs;

--Статусы
p_out_vfr_rdy         : out   std_logic_vector(C_VCTRL_VCH_COUNT - 1 downto 0);

----------------------------
--Upstream Port
----------------------------
p_in_upp_data         : in    std_logic_vector(G_MEM_DWIDTH - 1 downto 0);
p_out_upp_data_rd     : out   std_logic;
p_in_upp_buf_empty    : in    std_logic;
p_in_upp_buf_full     : in    std_logic;
p_in_upp_buf_pfull    : in    std_logic;

---------------------------------
-- Связь с mem_ctrl.vhd
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
G_ROTATE          : string:="OFF";
G_ROTATE_BUF_COUNT: integer:=16;
G_MEM_BANK_M_BIT  : integer:=29;
G_MEM_BANK_L_BIT  : integer:=28;

G_MEM_VCH_M_BIT   : integer:=25;
G_MEM_VCH_L_BIT   : integer:=24;
G_MEM_VFR_M_BIT   : integer:=23;
G_MEM_VFR_L_BIT   : integer:=23;
G_MEM_VLINE_M_BIT : integer:=22;
G_MEM_VLINE_L_BIT : integer:=12;

G_MEM_AWIDTH      : integer:=32;
G_MEM_DWIDTH      : integer:=32
);
port(
-------------------------------
-- Конфигурирование
-------------------------------
p_in_cfg_mem_trn_len : in    std_logic_vector(7 downto 0);
p_in_cfg_prm_vch     : in    TReaderVCHParams;

p_in_hrd_chsel       : in    std_logic_vector(3 downto 0);
p_in_hrd_start       : in    std_logic;
p_in_hrd_done        : in    std_logic;

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
-- Связь с mem_ctrl.vhd
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


constant CI_VBUF_COUNT                   : integer := pwr(2, (C_VCTRL_MEM_VFR_M_BIT - C_VCTRL_MEM_VFR_L_BIT + 1));
Type TVMrks_vbuf is array (0 to CI_VBUF_COUNT - 1) of std_logic_vector(31 downto 0);
Type TVMrks_vbufs is array (0 to C_VCTRL_VCH_COUNT - 1) of TVMrks_vbuf;

type TArrayCntWidth is array (0 to C_VCTRL_VCH_COUNT - 1) of std_logic_vector(3 downto 0);
signal i_vrd_irq_width_cnt               : TArrayCntWidth;
signal i_vrd_irq_width                   : std_logic_vector(C_VCTRL_VCH_COUNT - 1 downto 0);
signal i_vrd_irq                         : std_logic_vector(C_VCTRL_VCH_COUNT - 1 downto 0);
signal i_vbuf_hold                       : std_logic_vector(C_VCTRL_VCH_COUNT - 1 downto 0);
signal i_vfrmrk                          : TVMrks_vbufs;
signal i_vfrmrk_out                      : std_logic_vector(31 downto 0);

signal i_vbuf_wr                         : TVfrBufs;
signal i_vbuf_rd                         : TVfrBufs;

signal i_vwrite_vfr_rdy                  : std_logic_vector(C_VCTRL_VCH_COUNT - 1 downto 0);

signal i_vreader_rd_done                 : std_logic;
signal i_vreader_rq_next_line            : std_logic;
signal i_vreader_vch                     : std_logic_vector(3 downto 0);
signal i_vreader_active_pix              : std_logic_vector(15 downto 0);
signal i_vreader_mirx                    : std_logic;
signal i_vreader_dout                    : std_logic_vector(G_MEMRD_DWIDTH - 1 downto 0);
signal i_vreader_dout_en                 : std_logic;

signal i_vmir_rdy_n                      : std_logic;
signal i_vmir_dout                       : std_logic_vector(G_MEMRD_DWIDTH - 1 downto 0);
signal i_vmir_dout_en                    : std_logic;

signal i_vbufo_full                      : std_logic;
signal i_vbufout_rst                     : std_logic;

signal tst_vwriter_out                   : std_logic_vector(31 downto 0);
signal tst_vreader_out                   : std_logic_vector(31 downto 0);
signal tst_ctrl                          : std_logic_vector(31 downto 0);

type TVfrSkip is array (0 to C_VCTRL_VCH_COUNT - 1)
  of std_logic_vector(C_VCTRL_MEM_VFR_M_BIT - C_VCTRL_MEM_VFR_L_BIT downto 0);
signal i_vfrskip                         : TVfrSkip;

--signal tst_dbg_pictire                   : std_logic;
--signal tst_dbg_rd_hold                   : std_logic;


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



-------------------------------
-- Запись видео информации в ОЗУ
-------------------------------
m_video_writer : video_writer
generic map(
G_USR_OPT         => G_USR_OPT(3 downto 0),
G_DBGCS           => G_DBGCS,
G_MEM_BANK_M_BIT  => C_VCTRL_REG_MEM_ADR_BANK_M_BIT,
G_MEM_BANK_L_BIT  => C_VCTRL_REG_MEM_ADR_BANK_L_BIT,

G_MEM_VCH_M_BIT   => C_VCTRL_MEM_VCH_M_BIT,
G_MEM_VCH_L_BIT   => C_VCTRL_MEM_VCH_L_BIT,
G_MEM_VFR_M_BIT   => C_VCTRL_MEM_VFR_M_BIT,
G_MEM_VFR_L_BIT   => C_VCTRL_MEM_VFR_L_BIT,
G_MEM_VLINE_M_BIT => C_VCTRL_MEM_VLINE_M_BIT,
G_MEM_VLINE_L_BIT => C_VCTRL_MEM_VLINE_L_BIT,

G_MEM_AWIDTH      => G_MEM_AWIDTH,
G_MEM_DWIDTH      => G_MEMWR_DWIDTH
)
port map(
-------------------------------
-- Конфигурирование
-------------------------------
p_in_cfg_load         => vclk_vprm_set,
p_in_cfg_mem_trn_len  => i_vprm.mem_wd_trn_len,
p_in_cfg_prm_vch      => i_wrprm_vch,
p_in_cfg_set_idle_vch => vclk_set_idle_vch,

p_in_vfr_buf          => i_vbuf_wr,

--Статусы
p_out_vfr_rdy         => i_vwrite_vfr_rdy,

----------------------------
--Upstream Port
----------------------------
p_in_upp_data         => p_in_vbufi_do,
p_out_upp_data_rd     => p_out_vbufi_rd,
p_in_upp_buf_empty    => p_in_vbufi_empty,
p_in_upp_buf_full     => p_in_vbufi_full,
p_in_upp_buf_pfull    => p_in_vbufi_pfull,

---------------------------------
-- Связь с mem_ctrl.vhd
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


----------------------------------------------------
--Управление видео буферами
----------------------------------------------------
gen_vch : for ch in 0 to C_VCTRL_VCH_COUNT - 1 generate

--Готовим параметры для модуля чтения
i_rdprm_vch(ch).mem_adr   <= i_vprm.ch(ch).mem_addr_rd;
i_rdprm_vch(ch).fr_size   <= i_vprm.ch(ch).fr_size;
i_rdprm_vch(ch).fr_mirror <= i_vprm.ch(ch).fr_mirror;
i_rdprm_vch(ch).step_rd   <= i_vprm.ch(ch).step_rd;

--Готовим параметры для модуля записи
i_wrprm_vch(ch).mem_adr   <= i_vprm.ch(ch).mem_addr_wr;
i_wrprm_vch(ch).fr_size   <= i_vprm.ch(ch).fr_size;

--Растягиваем импульcы генерации прерываний чтения видеоканалов
process(p_in_clk)
begin
if rising_edge(p_in_clk) then
  if p_in_rst = '1' then
    i_vrd_irq_width_cnt(ch) <= (others=>'0');
    i_vrd_irq_width(ch) <= '0';

  else

      if i_vrd_irq(ch) = '1' then
        i_vrd_irq_width(ch) <= '1';
      elsif i_vrd_irq_width_cnt(ch)(i_vrd_irq_width_cnt(ch)'high) = '1' then
        i_vrd_irq_width(ch) <= '0';
      end if;

      if i_vrd_irq_width(ch) = '0' then
        i_vrd_irq_width_cnt(ch) <= (others=>'0');
      else
        i_vrd_irq_width_cnt(ch) <= i_vrd_irq_width_cnt(ch) + 1;
      end if;

  end if;
end if;
end process;

--Запись Видео
process(p_in_clk)
begin
if rising_edge(p_in_clk) then
  if p_in_rst = '1' then
    i_vbuf_wr(ch) <= (others=>'0');
    for buf in 0 to CI_VBUF_COUNT - 1 loop
    i_vfrmrk(ch)(buf) <= (others=>'0');
    end loop;
    i_vfrskip(ch) <= (others=>'0');

  else

        --Выбираем видеобуфер для записи:
        if vclk_set_idle_vch(ch) = '1' then
          i_vbuf_wr(ch) <= (others=>'0');

        elsif i_vwrite_vfr_rdy(ch) = '1' then
            if i_vbuf_hold(ch) = '1' then
                if i_vbuf_wr(ch) /= i_vbuf_rd(ch) then
                  i_vbuf_wr(ch) <= i_vbuf_wr(ch) + 1;
                end if;
            else
              i_vbuf_wr(ch) <= i_vbuf_wr(ch) + 1;
            end if;
        end if;

        --Подсчет записаных кадров в течении чтения данных ХОСТОМ
        if i_vbuf_hold(ch) = '0' then
          i_vfrskip(ch) <= (others=>'0');
        else
          if i_vwrite_vfr_rdy(ch) = '1' and
             i_vreader_vch = ch and i_vreader_rd_done = '1' then

            i_vfrskip(ch) <= i_vfrskip(ch);

          elsif i_vreader_vch = ch and i_vreader_rd_done = '1' and
                i_vfrskip(ch) /= (i_vfrskip(ch)'range => '0') then

            i_vfrskip(ch) <= i_vfrskip(ch) - 1;

          elsif i_vwrite_vfr_rdy(ch) = '1' and
                i_vfrskip(ch) /= (i_vfrskip(ch)'range => '1') then

            i_vfrskip(ch) <= i_vfrskip(ch) + 1;

          end if;
        end if;

  end if;
end if;
end process;

--Чтение Видео
process(p_in_clk)
begin
if rising_edge(p_in_clk) then
  if p_in_rst = '1' then

    i_vbuf_rd(ch) <= (others=>'0');
    i_vbuf_hold(ch) <= '0';
    i_vrd_irq(ch) <= '0';

  else

        --Выбираем видеобуфер для чтения
        if vclk_set_idle_vch(ch) = '1' then
          i_vbuf_rd(ch) <= (others=>'0');

        elsif i_vfrskip(ch) /= (i_vfrskip(ch)'range => '0') and
              i_vreader_vch = ch and i_vreader_rd_done = '1' then

          i_vbuf_rd(ch) <= i_vbuf_rd(ch) + 1;

        elsif i_vwrite_vfr_rdy(ch) = '1' and i_vbuf_hold(ch) = '0' then
          i_vbuf_rd(ch) <= i_vbuf_wr(ch);

        end if;

        --Захват видеобуфера для Чтения ХОСТОМ
        if i_vwrite_vfr_rdy(ch) = '1' then
          i_vbuf_hold(ch) <= '1';

        elsif (i_vfrskip(ch) = (i_vfrskip(ch)'range => '0') and
              i_vreader_vch = ch and i_vreader_rd_done = '1') or
              vclk_set_idle_vch(ch) = '1' then

          i_vbuf_hold(ch) <= '0';
        end if;

        --Прерываение - Можно вычитывать кадр
        if i_vfrskip(ch) = (i_vfrskip(ch)'range => '0') then
          i_vrd_irq(ch) <= i_vwrite_vfr_rdy(ch) and not i_vbuf_hold(ch);

        elsif i_vreader_vch = ch then
          i_vrd_irq(ch) <= i_vreader_rd_done;

        end if;

  end if;
end if;
end process;
end generate gen_vch;


-------------------------------
--Модуль чтение видео информации из ОЗУ
-------------------------------
m_video_reader : video_reader
generic map(
G_USR_OPT         => G_USR_OPT(7 downto 4),
G_DBGCS           => G_DBGCS,
G_ROTATE          => G_ROTATE,
G_ROTATE_BUF_COUNT=> G_ROTATE_BUF_COUNT,
G_MEM_BANK_M_BIT  => C_VCTRL_REG_MEM_ADR_BANK_M_BIT,
G_MEM_BANK_L_BIT  => C_VCTRL_REG_MEM_ADR_BANK_L_BIT,

G_MEM_VCH_M_BIT   => C_VCTRL_MEM_VCH_M_BIT,
G_MEM_VCH_L_BIT   => C_VCTRL_MEM_VCH_L_BIT,
G_MEM_VFR_M_BIT   => C_VCTRL_MEM_VFR_M_BIT,
G_MEM_VFR_L_BIT   => C_VCTRL_MEM_VFR_L_BIT,
G_MEM_VLINE_M_BIT => C_VCTRL_MEM_VLINE_M_BIT,
G_MEM_VLINE_L_BIT => C_VCTRL_MEM_VLINE_L_BIT,

G_MEM_AWIDTH      => G_MEM_AWIDTH,
G_MEM_DWIDTH      => G_MEMRD_DWIDTH
)
port map(
-------------------------------
-- Конфигурирование
-------------------------------
p_in_cfg_mem_trn_len  => i_vprm.mem_rd_trn_len,
p_in_cfg_prm_vch      => i_rdprm_vch,

p_in_hrd_chsel        => p_in_hrdchsel,
p_in_hrd_start        => p_in_hrdstart,
p_in_hrd_done         => p_in_hrddone,

p_in_vfr_buf          => i_vbuf_rd,
p_in_vfr_nrow         => i_vreader_rq_next_line,

--Статусы
p_out_vch_fr_new      => open,
p_out_vch_rd_done     => i_vreader_rd_done,
p_out_vch             => i_vreader_vch,
p_out_vch_active_pix  => i_vreader_active_pix,
p_out_vch_active_row  => open,
p_out_vch_mirx        => i_vreader_mirx,

----------------------------
--Upstream Port
----------------------------
p_out_upp_data        => i_vreader_dout,
p_out_upp_data_wd     => i_vreader_dout_en,
p_in_upp_buf_empty    => '0',
p_in_upp_buf_full     => i_vbufo_full,

---------------------------------
-- Связь с mem_ctrl.vhd
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
m_vbufo : host_vbuf
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

rst         => i_vbufout_rst
);

i_vbufout_rst <= p_in_rst or p_in_tst(0);

p_out_hirq <= i_vrd_irq_width;
p_out_hdrdy <= i_vbuf_hold;
p_out_hfrmrk <= i_vfrmrk_out;


--END MAIN
end behavioral;


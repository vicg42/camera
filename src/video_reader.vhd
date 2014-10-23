-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 17.01.2013 11:13:38
-- Module Name : video_reader
--
-- Назначение/Описание :
--  Чтение кадра видеоканала из ОЗУ
--
-------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.reduce_pack.all;
use work.vicg_common_pkg.all;
use work.video_ctrl_pkg.all;
use work.mem_wr_pkg.all;

entity video_reader is
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
p_in_mem_trn_len     : in    std_logic_vector(7 downto 0);
p_in_prm_vch         : in    TReaderVCHParams;
p_in_work_en         : in    std_logic;
p_in_vfr_buf         : in    TVfrBufs;                    --Номер видеобувера с готовым кадром для соответствующего видеоканала
p_in_vfr_nrow        : in    std_logic;                   --Разрешение чтения следующей строки
p_in_vread_sync      : in    std_logic;

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
p_out_upp_data       : out   std_logic_vector(G_MEM_DWIDTH-1 downto 0);
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
end entity video_reader;

architecture behavioral of video_reader is

--Small delay for simulation purposes.
constant dly : time := 1 ps;

type TFsm_state is (
S_IDLE,
S_MEM_START,
S_MEM_RD,
S_ROW_NXT
);
signal i_fsm_state_cs              : TFsm_state;

signal i_mem_adr                   : unsigned(31 downto 0) := (others => '0');
signal i_mem_trn_len               : unsigned(15 downto 0) := (others => '0');
signal i_mem_dlen_rq               : unsigned(15 downto 0) := (others => '0');
signal i_mem_start                 : std_logic;
signal i_mem_dir                   : std_logic;
signal i_mem_done                  : std_logic;
signal i_vfr_pix_count_byte        : unsigned(15 downto 0) := (others => '0');
signal i_vfrw_pix_count_byte       : unsigned(15 downto 0) := (others => '0');
signal i_vfr_rowcnt                : unsigned(15 downto 0) := (others => '0');
signal i_vfr_rowcnt_tmp            : unsigned(15 downto 0) := (others => '0');
signal i_mem_adr_t                 : unsigned(31 downto 0) := (others => '0');
signal i_vfr_skip_row              : unsigned(i_vfr_rowcnt'range) := (others => '0');
signal i_vfr_skip_pix              : unsigned(i_vfr_pix_count_byte'range) := (others => '0');
signal i_vfr_row_count             : unsigned(i_vfr_rowcnt'range) := (others => '0');
signal i_vfr_mirror                : TFrXYMirror;
signal i_vfr_new                   : std_logic;
signal i_padding                   : std_logic := '0';
signal i_upp_buf_full              : std_logic;
signal i_data_null                 : std_logic_vector(G_MEM_DWIDTH - 1 downto 0);
signal sr_vread_sync               : std_logic_vector(0 to 1);
signal i_vread_sync                : std_logic;

signal tst_mem_wr_out              : std_logic_vector(31 downto 0);
signal tst_fsmstate,tst_fsm_cs_dly : unsigned(3 downto 0) := (others => '0');

signal i_debayer_colorfst          : std_logic_vector(1 downto 0);
signal i_debayer_off               : std_logic;

begin --architecture behavioral


i_data_null <= (others=>'0');

------------------------------------
--Технологические сигналы
------------------------------------
--p_out_tst(31 downto 0) <= (others=>'0');
p_out_tst(5 downto 0) <= tst_mem_wr_out(5 downto 0);
p_out_tst(7 downto 6) <= (others=>'0');
p_out_tst(10 downto 8) <= std_logic_vector(tst_fsm_cs_dly(2 downto 0));
p_out_tst(11) <= '0';
p_out_tst(28 downto 12) <= (others => '0');
p_out_tst(30 downto 29) <= i_debayer_colorfst;
p_out_tst(31) <= i_debayer_off;


process(p_in_clk)
begin
  if rising_edge(p_in_clk) then
    tst_fsm_cs_dly <= tst_fsmstate;
  end if;
end process;
tst_fsmstate <= TO_UNSIGNED(16#01#,tst_fsmstate'length) when i_fsm_state_cs = S_MEM_START       else
                TO_UNSIGNED(16#02#,tst_fsmstate'length) when i_fsm_state_cs = S_MEM_RD          else
                TO_UNSIGNED(16#00#,tst_fsmstate'length); --i_fsm_state_cs = S_IDLE              else


------------------------------------------------
--Статусы
------------------------------------------------
p_out_vch_fr_new <= i_vfr_new;
p_out_vch_rd_done <= '0';
p_out_vch <= (others=>'0');
p_out_vch_active_pix <= std_logic_vector(i_vfr_pix_count_byte);
p_out_vch_active_row <= std_logic_vector(i_vfr_row_count);
p_out_vch_mirx  <= i_vfr_mirror.x;


------------------------------------------------
--Автомат Чтения видео кадра
------------------------------------------------
i_vfr_rowcnt_tmp <= i_vfr_rowcnt + i_vfr_skip_row;

process(p_in_clk)
begin
if rising_edge(p_in_clk) then
  if p_in_rst = '1' then

    i_fsm_state_cs <= S_IDLE;
    i_mem_adr <= (others=>'0');
    i_mem_dlen_rq <= (others=>'0');
    i_mem_trn_len <= (others=>'0');
    i_mem_dir <= '0';
    i_mem_start <= '0';
    i_vfr_rowcnt <= (others=>'0');
    i_padding <= '0';

    i_vfr_skip_row <= (others => '0');
    i_vfr_skip_pix <= (others => '0');
    i_vfr_pix_count_byte <= (others => '0');
    i_vfr_row_count <= (others => '0');
    i_vfrw_pix_count_byte <= (others => '0');

    i_vfr_mirror.x <= '0';
    i_vfr_mirror.y <= '0';

    i_vfr_new <= '0';

    sr_vread_sync <= (others => '0');
    i_vread_sync <= '0';

    i_debayer_colorfst <= (others => '0');
    i_debayer_off <= '0';

  else

    sr_vread_sync <= p_in_vread_sync & sr_vread_sync(0 to 0);
    i_vread_sync <= sr_vread_sync(0) and not sr_vread_sync(1);

    case i_fsm_state_cs is

      --------------------------------------
      --Исходное состояние
      --------------------------------------
      when S_IDLE =>

        i_padding <= '0';

        if p_in_work_en = '1' and i_vread_sync = '1' then
          i_vfr_skip_row <= UNSIGNED(p_in_prm_vch(0).fr_size.skip.row(i_vfr_skip_row'range));
          i_vfr_skip_pix <= UNSIGNED(p_in_prm_vch(0).fr_size.skip.pix(i_vfr_skip_pix'range));
          i_vfr_pix_count_byte <= UNSIGNED(p_in_prm_vch(0).fr_size.activ.pix(i_vfr_pix_count_byte'range));
          i_vfrw_pix_count_byte <= UNSIGNED(p_in_prm_vch(0).frw_size.activ.pix(i_vfrw_pix_count_byte'range));
          i_vfr_row_count <= UNSIGNED(p_in_prm_vch(0).fr_size.activ.row(i_vfr_row_count'range));

          i_debayer_colorfst <= p_in_prm_vch(0).debayer_colorfst;
          i_debayer_off <= p_in_prm_vch(0).debayer_off;

          if p_in_prm_vch(0).fr_mirror.y = '0' then
            i_vfr_rowcnt <= (others=>'0');
          else
            i_vfr_rowcnt <= UNSIGNED(p_in_prm_vch(0).fr_size.activ.row(i_vfr_row_count'range)) - 1;
          end if;

          i_vfr_mirror <= p_in_prm_vch(0).fr_mirror;

          i_vfr_new <= '1';

          i_fsm_state_cs <= S_MEM_START;
        end if;

      --------------------------------------
      --Запускаем операцию чтения ОЗУ
      --------------------------------------
      when S_MEM_START =>

        i_vfr_new <= '0';

        if p_in_work_en = '0' then
          i_fsm_state_cs <= S_IDLE;

        else

          i_mem_adr <= i_vfrw_pix_count_byte * i_vfr_rowcnt_tmp;

          i_mem_dlen_rq <= RESIZE(i_vfr_pix_count_byte(i_vfr_pix_count_byte'high downto log2(G_MEM_DWIDTH / 8))
                                                                                , i_mem_dlen_rq'length)
                           + (TO_UNSIGNED(0, i_mem_dlen_rq'length - 2)
                              & OR_reduce(i_vfr_pix_count_byte(log2(G_MEM_DWIDTH / 8) - 1 downto 0)));

          i_mem_trn_len <= RESIZE(UNSIGNED(p_in_mem_trn_len), i_mem_trn_len'length);

          i_mem_dir <= C_MEMWR_READ;
          i_mem_start <= '1';
          i_fsm_state_cs <= S_MEM_RD;

        end if;

      ------------------------------------------------
      --Чтение данных
      ------------------------------------------------
      when S_MEM_RD =>

        i_mem_start <= '0';

        if i_mem_done = '1' then
          i_fsm_state_cs <= S_ROW_NXT;
        end if;

      ------------------------------------------------
      --Ждем запроса на чтение следующей строки
      ------------------------------------------------
      when S_ROW_NXT =>

        if p_in_work_en = '0' then
          i_padding <= '1';
        end if;

        if p_in_vfr_nrow = '1' then
          if (i_vfr_rowcnt = (i_vfr_row_count - 1) and i_vfr_mirror.y = '0')
            or (i_vfr_rowcnt = (i_vfr_rowcnt'range => '0') and i_vfr_mirror.y = '1')
              or i_padding = '1' then

            i_fsm_state_cs <= S_IDLE;

          else
            if i_vfr_mirror.y = '0' then
              i_vfr_rowcnt <= i_vfr_rowcnt + 1;
            else
              i_vfr_rowcnt <= i_vfr_rowcnt - 1;
            end if;

            i_fsm_state_cs <= S_MEM_START;

          end if;
        end if;

    end case;

  end if;
end if;
end process;


--------------------------------------------------------
--Модуль записи/чтения данных ОЗУ (mem_ctrl.vhd)
--------------------------------------------------------
i_upp_buf_full <= p_in_upp_buf_full and not i_padding;

i_mem_adr_t <= i_mem_adr + RESIZE(UNSIGNED(i_vfr_skip_pix), i_mem_adr_t'length);

m_mem_wr : mem_wr
generic map(
--G_USR_OPT        => G_USR_OPT,
G_MEM_BANK_M_BIT => 31,
G_MEM_BANK_L_BIT => 30,
G_MEM_AWIDTH     => G_MEM_AWIDTH,
G_MEM_DWIDTH     => G_MEM_DWIDTH
)
port map
(
-------------------------------
--Конфигурирование
-------------------------------
p_in_cfg_mem_adr     => std_logic_vector(i_mem_adr_t)    ,
p_in_cfg_mem_trn_len => std_logic_vector(i_mem_trn_len),
p_in_cfg_mem_dlen_rq => std_logic_vector(i_mem_dlen_rq),
p_in_cfg_mem_wr      => i_mem_dir,
p_in_cfg_mem_start   => i_mem_start,
p_out_cfg_mem_done   => i_mem_done,

-------------------------------
--Связь с пользовательскими буферами
-------------------------------
p_in_usr_txbuf_dout  => i_data_null,
p_out_usr_txbuf_rd   => open,
p_in_usr_txbuf_empty => '0',

p_out_usr_rxbuf_din  => p_out_upp_data,
p_out_usr_rxbuf_wd   => p_out_upp_data_wd,
p_in_usr_rxbuf_full  => i_upp_buf_full,

---------------------------------
--Связь с mem_ctrl.vhd
---------------------------------
p_out_mem            => p_out_mem,
p_in_mem             => p_in_mem,

-------------------------------
--System
-------------------------------
p_in_tst             => p_in_tst,
p_out_tst            => tst_mem_wr_out,

p_in_clk             => p_in_clk,
p_in_rst             => p_in_rst
);


end architecture behavioral;

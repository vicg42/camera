-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 17.01.2013 11:13:58
-- Module Name : video_writer
--
-- Назначение/Описание :
--
-------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_misc.all;
use ieee.std_logic_unsigned.all;

library work;
use work.vicg_common_pkg.all;
use work.video_ctrl_pkg.all;
use work.mem_wr_pkg.all;

entity video_writer is
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
p_in_mem_trn_len      : in    std_logic_vector(7 downto 0);--Размер одиночной транзакции MEM_WR
p_in_prm_vch          : in    TWriterVCHParams;            --Параметры записи видео каналов
p_in_work_en          : in    std_logic;
p_in_vfr_buf          : in    TVfrBufs;                    --Номер буфера где будет формироваться текущий кадр

--Статусы
p_out_vfr_rdy         : out   std_logic_vector(C_VCTRL_VCH_COUNT - 1 downto 0);--Кадр готов для соответствующего видеоканала

----------------------------
--Upstream Port (Связь с буфером видеопакетов)
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
end video_writer;

architecture behavioral of video_writer is

--Small delay for simulation purposes.
constant dly : time := 1 ps;

type fsm_state is (
S_IDLE,
S_MEM_START,
S_MEM_WR
);
signal fsm_state_cs: fsm_state;

signal i_mem_adr                   : std_logic_vector(31 downto 0);
signal i_mem_trn_len               : std_logic_vector(15 downto 0);
signal i_mem_dlen_rq               : std_logic_vector(15 downto 0);
signal i_mem_start                 : std_logic;
signal i_mem_dir                   : std_logic;
signal i_mem_done                  : std_logic;
signal i_pix_count_byte            : std_logic_vector(15 downto 0);
signal i_vfr_rowcnt                : std_logic_vector(C_VCTRL_MEM_VLINE_M_BIT - C_VCTRL_MEM_VLINE_L_BIT downto 0);
signal i_vfr_rdy                   : std_logic_vector(p_out_vfr_rdy'range);
signal i_padding                   : std_logic;
signal i_upp_buf_empty             : std_logic;

signal tst_mem_wr_out              : std_logic_vector(31 downto 0);
signal tst_fsmstate,tst_fsm_cs_dly : std_logic_vector(3 downto 0);


--MAIN
begin


------------------------------------
--Технологические сигналы
------------------------------------
--p_out_tst(31 downto 0) <= (others=>'0');
p_out_tst(5 downto 0) <= tst_mem_wr_out(5 downto 0);
p_out_tst(7 downto 6) <= (others=>'0');
p_out_tst(10 downto 8 )<= tst_fsm_cs_dly(2 downto 0);
p_out_tst(11) <= '0';
p_out_tst(21 downto 16) <= tst_mem_wr_out(21 downto 16);--i_mem_trn_len(5 downto 0);
p_out_tst(31 downto 22) <= (others=>'0');


process(p_in_clk)
begin
  if rising_edge(p_in_clk) then
    tst_fsm_cs_dly <= tst_fsmstate;
  end if;
end process;
tst_fsmstate <= CONV_STD_LOGIC_VECTOR(16#01#, tst_fsmstate'length) when fsm_state_cs = S_MEM_START else
                CONV_STD_LOGIC_VECTOR(16#02#, tst_fsmstate'length) when fsm_state_cs = S_MEM_WR    else
                CONV_STD_LOGIC_VECTOR(16#00#, tst_fsmstate'length); --fsm_state_cs = S_IDLE        else


------------------------------------------------
--Статусы
------------------------------------------------
p_out_vfr_rdy <= i_vfr_rdy;


------------------------------------------------
--Автомат записи видео информации
------------------------------------------------
i_pix_count_byte <= p_in_prm_vch(0)
                    .fr_size.activ
                    .pix(p_in_prm_vch(0).fr_size.activ.pix'length - 1 downto 0);

process(p_in_clk)
begin
if rising_edge(p_in_clk) then
  if p_in_rst = '1' then

    fsm_state_cs <= S_IDLE;
    i_vfr_rdy <= (others=>'0');
    i_vfr_rowcnt <= (others=>'0');
    i_mem_adr <= (others=>'0');
    i_mem_dlen_rq <= (others=>'0');
    i_mem_trn_len <= (others=>'0');
    i_mem_dir <= '0';
    i_mem_start <= '0';
    i_padding <= '0';

  else

    case fsm_state_cs is

      --------------------------------------
      --Исходное состояние
      --------------------------------------
      when S_IDLE =>

        --Ждем когда появятся данные в буфере
        i_vfr_rdy <= (others=>'0');
        i_vfr_rowcnt <= (others=>'0');

        if p_in_upp_buf_empty = '0' and p_in_work_en = '1' then
          fsm_state_cs <= S_MEM_START;
        end if;

      --------------------------------------
      --Запускаем операцию записи ОЗУ
      --------------------------------------
      when S_MEM_START =>

        if p_in_work_en = '1' then
          fsm_state_cs <= S_IDLE;

        else

          i_mem_adr(C_VCTRL_MEM_VLINE_M_BIT downto C_VCTRL_MEM_VLINE_L_BIT) <= i_vfr_rowcnt;
          i_mem_adr(C_VCTRL_MEM_VLINE_L_BIT - 1 downto 0) <= (others=>'0');

          i_mem_dlen_rq <= EXT(i_pix_count_byte(i_pix_count_byte'high downto log2(G_MEM_DWIDTH / 8))
                                                                                , i_mem_dlen_rq'length)
                           + OR_reduce(i_pix_count_byte(log2(G_MEM_DWIDTH / 8) - 1 downto 0));
          i_mem_trn_len <= EXT(p_in_mem_trn_len, i_mem_trn_len'length);
          i_mem_dir <= C_MEMWR_WRITE;

          i_mem_start <= '1';
          fsm_state_cs <= S_MEM_WR;
        end if;

      ------------------------------------------------
      --Запись данных
      ------------------------------------------------
      when S_MEM_WR =>

        if p_in_work_en = '1' then
          i_padding <= '1';
        end if;

        i_mem_start <= '0';
        if i_mem_done = '1' then
          if i_vfr_rowcnt = (p_in_prm_vch(0)
                              .fr_size.activ.row(i_vfr_rowcnt'range) - 1) or i_padding = '1' then

            i_vfr_rdy(0) <= '1';
            fsm_state_cs <= S_IDLE;
          else
            i_vfr_rowcnt <= i_vfr_rowcnt + 1;
            fsm_state_cs <= S_MEM_START;
          end if;
        end if;

    end case;

  end if;
end if;--p_in_rst,
end process;


--------------------------------------------------------
--Модуль записи/чтения данных ОЗУ (mem_ctrl.vhd)
--------------------------------------------------------
i_upp_buf_empty <= p_in_upp_buf_empty and not i_padding;

m_mem_wr : mem_wr
generic map(
--G_USR_OPT        => G_USR_OPT,
G_MEM_BANK_M_BIT => 31,
G_MEM_BANK_L_BIT => 30,
G_MEM_AWIDTH     => G_MEM_AWIDTH,
G_MEM_DWIDTH     => G_MEM_DWIDTH
)
port map(
-------------------------------
--Конфигурирование
-------------------------------
p_in_cfg_mem_adr     => i_mem_adr,
p_in_cfg_mem_trn_len => i_mem_trn_len,
p_in_cfg_mem_dlen_rq => i_mem_dlen_rq,
p_in_cfg_mem_wr      => i_mem_dir,
p_in_cfg_mem_start   => i_mem_start,
p_out_cfg_mem_done   => i_mem_done,

-------------------------------
--Связь с пользовательскими буферами
-------------------------------
p_in_usr_txbuf_dout  => p_in_upp_data,
p_out_usr_txbuf_rd   => p_out_upp_data_rd,
p_in_usr_txbuf_empty => i_upp_buf_empty,

p_out_usr_rxbuf_din  => open,
p_out_usr_rxbuf_wd   => open,
p_in_usr_rxbuf_full  => '0',

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


--END MAIN
end behavioral;


-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 2010.07
-- Module Name : vmirx_main
--
-- Назначение/Описание :
--  Модуль реализует отзеркаливание строки видео инфомации по оси X
--
-- Revision:
--
-------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.reduce_pack.all;
use work.vicg_common_pkg.all;

entity vmirx_main is
generic(
G_BRAM_AWIDTH : integer:=8;
G_DWIDTH : integer:=8
);
port(
-------------------------------
-- Управление
-------------------------------
p_in_cfg_mirx       : in    std_logic;                    --1/0 - Вкл./Выкл отзеркаливание строки видеоданных
p_in_cfg_pix_count  : in    std_logic_vector(15 downto 0);--Кол-во пиксел в byte

p_out_cfg_mirx_done : out   std_logic;                    --Обработка завершена.

----------------------------
--Upstream Port (входные данные)
----------------------------
--p_in_upp_clk        : in    std_logic;
p_in_upp_data       : in    std_logic_vector(G_DWIDTH - 1 downto 0);
p_in_upp_wd         : in    std_logic;                    --Запись данных в модуль vmirx_main.vhd
p_out_upp_rdy_n     : out   std_logic;                    --0 - Модуль vmirx_main.vhd готов к приему данных

----------------------------
--Downstream Port (результат)
----------------------------
--p_in_dwnp_clk       : in    std_logic;
p_out_dwnp_data     : out   std_logic_vector(G_DWIDTH - 1 downto 0);
p_out_dwnp_wd       : out   std_logic;                    --Запись данных в приемник
p_in_dwnp_rdy_n     : in    std_logic;                    --0 - порт приемника готов к приему даннвх

-------------------------------
--Технологический
-------------------------------
p_in_tst            : in    std_logic_vector(31 downto 0);
p_out_tst           : out   std_logic_vector(31 downto 0);

-------------------------------
--System
-------------------------------
p_in_clk            : in    std_logic;
p_in_rst            : in    std_logic
);
end entity vmirx_main;

architecture behavioral of vmirx_main is

constant dly : time := 1 ps;

component vmirx_bram
port(
addra: in  std_logic_vector(G_BRAM_AWIDTH - 1 downto 0);
dina : in  std_logic_vector(G_DWIDTH - 1 downto 0);
douta: out std_logic_vector(G_DWIDTH - 1 downto 0);
ena  : in  std_logic;
wea  : in  std_logic_vector(0 downto 0);
clka : in  std_logic;
rsta : in  std_logic;

addrb: in  std_logic_vector(G_BRAM_AWIDTH - 1 downto 0);
dinb : in  std_logic_vector(G_DWIDTH - 1 downto 0);
doutb: out std_logic_vector(G_DWIDTH - 1 downto 0);
enb  : in  std_logic;
web  : in  std_logic_vector(0 downto 0);
clkb : in  std_logic;
rstb : in  std_logic
);
end component vmirx_bram;


signal i_upp_data        : std_logic_vector(G_DWIDTH - 1 downto 0);
signal i_upp_data_swap   : std_logic_vector(G_DWIDTH - 1 downto 0);
signal i_upp_wd          : std_logic;

type fsm_state is (
S_BUF_WR,
S_BUF_RD_SOF,
S_BUF_RD,
S_BUF_RD_EOF
);
signal fsm_state_cs: fsm_state;

signal i_pix_count       : unsigned(p_in_cfg_pix_count'range);
signal i_mirx_done       : std_logic;

signal i_buf_adr         : unsigned(p_in_cfg_pix_count'range);
signal i_buf_di          : std_logic_vector(G_DWIDTH - 1 downto 0);
signal i_buf_do          : std_logic_vector(G_DWIDTH - 1 downto 0);
signal i_buf_dir         : std_logic;
signal i_buf_ena         : std_logic;
signal i_buf_enb         : std_logic;
signal i_read_en         : std_logic;

signal i_gnd             : std_logic_vector(G_DWIDTH - 1 downto 0);

signal tst_fsmstate     : unsigned(1 downto 0);
signal tst_fsmstate_out : std_logic_vector(1 downto 0);
signal tst_buf_enb : std_logic;
signal tst_hbufo_pfull : std_logic;


begin --architecture behavioral

--assert ( not (TO_UNSIGNED((pwr(2, (p_in_cfg_pix_count'length / (G_DWIDTH/8))) - 1), p_in_cfg_pix_count'length)) >
--         TO_UNSIGNED((pwr(2, G_BRAM_AWIDTH) - 1), p_in_cfg_pix_count'length) )
--report "ERROR: BRAM Mirror DEPTH is small"
--severity error;


i_gnd <= (others=>'0');

------------------------------------
--Технологические сигналы
------------------------------------
p_out_tst(0) <= OR_reduce(tst_fsmstate_out) or tst_buf_enb or tst_hbufo_pfull;
p_out_tst(31 downto 1) <= (others=>'0');

process(p_in_clk)
begin
  if rising_edge(p_in_clk) then
    tst_fsmstate_out <= std_logic_vector(tst_fsmstate);
    tst_buf_enb <= i_buf_enb;
    tst_hbufo_pfull <= p_in_dwnp_rdy_n;
  end if;
end process;

tst_fsmstate <= TO_UNSIGNED(16#01#, tst_fsmstate'length) when fsm_state_cs = S_BUF_RD_SOF  else
                TO_UNSIGNED(16#02#, tst_fsmstate'length) when fsm_state_cs = S_BUF_RD      else
                TO_UNSIGNED(16#03#, tst_fsmstate'length) when fsm_state_cs = S_BUF_RD_EOF  else
                TO_UNSIGNED(16#00#, tst_fsmstate'length); --fsm_state_cs = S_BUF_WR          else


------------------------------------------------
--Связь с Upstream Port
------------------------------------------------
i_upp_data <= p_in_upp_data;
i_upp_wd <= p_in_upp_wd;

p_out_upp_rdy_n <= i_buf_dir;

-------------------------------
--Вывод результата
-------------------------------
p_out_dwnp_data <= i_buf_do;
p_out_dwnp_wd <= not p_in_dwnp_rdy_n and i_buf_dir;


-------------------------------
--Инициализация
-------------------------------
i_pix_count <= RESIZE(UNSIGNED(p_in_cfg_pix_count(p_in_cfg_pix_count'high downto log2(G_DWIDTH / 8)))
                                                                    , i_pix_count'length)
               + (TO_UNSIGNED(0, i_pix_count'length - 2)
                  & OR_reduce(p_in_cfg_pix_count(log2(G_DWIDTH / 8) - 1 downto 0)));

-------------------------------
--Статус
-------------------------------
p_out_cfg_mirx_done <= i_mirx_done;


--------------------------------------
--Запись/Чтение Буфера строки
--------------------------------------
process(p_in_clk)
begin
if rising_edge(p_in_clk) then
  if p_in_rst = '1' then

    fsm_state_cs <= S_BUF_WR;

    i_buf_dir <= '0';
    i_buf_adr <= (others=>'0');
    i_mirx_done <= '1';
    i_read_en <= '0';

  else

    case fsm_state_cs is

      --------------------------------------
      --Запись данных строки в буфер
      --------------------------------------
      when S_BUF_WR =>
        i_mirx_done <= '0';

        if i_upp_wd = '1' then
          if i_buf_adr = (i_pix_count - 1) then
            if p_in_cfg_mirx = '0' then
              i_buf_adr <= (others=>'0');
            end if;
            i_read_en <= '1';

            fsm_state_cs <= S_BUF_RD_SOF;
          else
            i_buf_adr <= i_buf_adr + 1;
          end if;
        end if;

      --------------------------------------
      --
      --------------------------------------
      when S_BUF_RD_SOF =>
        i_buf_dir <= '1';--Переключаемся на чтение m_row_buf

        if p_in_cfg_mirx = '0' then
          i_buf_adr <= i_buf_adr + 1;
        else
          i_buf_adr <= i_buf_adr - 1;
        end if;
        fsm_state_cs <= S_BUF_RD;

      --------------------------------------
      --Чтение данных из буфера строки
      --------------------------------------
      when S_BUF_RD =>

        if p_in_dwnp_rdy_n = '0' then

            --Отзеркаливание по Х: ЕСТЬ
            if (p_in_cfg_mirx = '0' and i_buf_adr = (i_pix_count - 1)) or
               (p_in_cfg_mirx = '1' and i_buf_adr = (i_buf_adr'range => '0')) then

              fsm_state_cs <= S_BUF_RD_EOF;
            else
              if p_in_cfg_mirx = '0' then
                i_buf_adr <= i_buf_adr + 1;
              else
                i_buf_adr <= i_buf_adr - 1;
              end if;
            end if;

        end if;

      --------------------------------------
      --
      --------------------------------------
      when S_BUF_RD_EOF =>
        if p_in_dwnp_rdy_n = '0' then
          i_mirx_done <= '1';
          i_buf_dir <= '0';--Переключаемся на Запись m_row_buf
          i_read_en <= '0';
          if p_in_cfg_mirx = '0' then
            i_buf_adr <= (others=>'0');
          end if;
          fsm_state_cs <= S_BUF_WR;
        end if;
    end case;

  end if;
end if;
end process;


--Если Отзеркаливание ЕСТЬ, то для 1Pix=8Bit
gen_swap : for i in 0 to i_upp_data'length / 8 - 1 generate
i_upp_data_swap((i_upp_data_swap'length - (8 * i)) - 1 downto
                (i_upp_data_swap'length - (8 * (i + 1)))) <= i_upp_data((8 * (i + 1) - 1) downto (8 * i));
end generate gen_swap;

--Запись данных
i_buf_di <= i_upp_data_swap when p_in_cfg_mirx = '1' else i_upp_data;
i_buf_ena <= not i_buf_dir and i_upp_wd;

--Чтение данных
i_buf_enb <= (not p_in_dwnp_rdy_n or not i_buf_dir) and i_read_en;

m_bufline : vmirx_bram
port map(
addra => std_logic_vector(i_buf_adr(G_BRAM_AWIDTH - 1 downto 0)),
dina  => i_buf_di,
douta => open,
ena   => i_buf_ena,
wea   => "1",
clka  => p_in_clk,
rsta  => p_in_rst,

addrb => std_logic_vector(i_buf_adr(G_BRAM_AWIDTH - 1 downto 0)),
dinb  => i_gnd,
doutb => i_buf_do,
enb   => i_buf_enb,
web   => "0",
clkb  => p_in_clk,
rstb  => p_in_rst
);

end architecture behavioral;

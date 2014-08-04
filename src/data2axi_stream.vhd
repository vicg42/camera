-------------------------------------------------------------------------
-- Company     : Yansar
-- Engineer    : Golovachenko Victor
--
-- Create Date : 01.08.2014 15:18:58
-- Module Name : data2axistream
--
-- Назначение/Описание :
--  Запись/Чтение данных ОЗУ
--
--
-- Revision:
-- Revision 0.01 - File Created
--
-------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.reduce_pack.all;
use work.vicg_common_pkg.all;

entity data2axistream is
generic(
G_VFR_PIX_COUNT : integer := 8;
G_VFR_ROW_COUNT : integer := 8;
G_BUFI_DWIDTH   : integer := 8;
G_AXI_DWIDTH    : integer := 8
);
port(
---------------------------------
----
---------------------------------
--p_in_vfr_pix     : in    std_logic_vector(15 downto 0);
--p_in_vfr_row     : in    std_logic_vector(15 downto 0);
p_in_work       : in    std_logic;

-------------------------------
--
-------------------------------
p_in_bufi_dout  : in    std_logic_vector(G_BUFI_DWIDTH - 1 downto 0);
p_out_bufi_rd   : out   std_logic;
p_in_bufi_empty : in    std_logic;

p_out_axi_stream_tdata  : out   std_logic_vector(G_AXI_DWIDTH - 1 downto 0);
p_out_axi_stream_tvalid : out   std_logic;
p_out_axi_stream_tuser  : out   std_logic; --SOF (start of frame)
p_out_axi_stream_tlast  : out   std_logic; --EOL (End of line)
p_in_axi_stream_tready  : in    std_logic;

-------------------------------
--Технологические сигналы
-------------------------------
p_in_tst             : in    std_logic_vector(31 downto 0);
p_out_tst            : out   std_logic_vector(31 downto 0);

-------------------------------
--System
-------------------------------
p_in_clk             : in    std_logic;
p_in_rst             : in    std_logic
);
end entity data2axistream;

architecture behavioral of data2axistream is

signal i_rd_work           : std_logic := '0';
signal i_pix_cnt           : unsigned(log2(G_VFR_PIX_COUNT) - 1 downto 0) := (others => '0');
signal i_row_cnt           : unsigned(log2(G_VFR_ROW_COUNT) - 1 downto 0) := (others => '0');

signal i_bufi_rd           : std_logic;


--MAIN
begin


p_out_axi_stream_tdata <= p_in_bufi_dout;
p_out_axi_stream_tvalid <= not p_in_bufi_empty;
p_out_axi_stream_tuser <= not p_in_bufi_empty and p_in_axi_stream_tready
    when i_rd_work = '1' and i_pix_cnt = (i_pix_cnt'range => '0') and i_row_cnt = (i_row_cnt'range => '0') else '0';

p_out_axi_stream_tlast <= not p_in_bufi_empty and p_in_axi_stream_tready
    when i_rd_work = '1' and i_pix_cnt = TO_UNSIGNED(G_VFR_PIX_COUNT - 1, i_pix_cnt'length) else '0';

p_out_bufi_rd <= i_bufi_rd;

i_bufi_rd <= not p_in_bufi_empty and p_in_axi_stream_tready and i_rd_work;


read_bufi : process(p_in_clk)
begin
if rising_edge(p_in_clk) then
  if p_in_rst = '1' then

    i_rd_work <= '0';
    i_pix_cnt <= (others=>'0');
    i_row_cnt <= (others => '0');

  else

    i_rd_work <= p_in_work;

      if i_rd_work = '0'  then

        i_pix_cnt <= (others=>'0');
        i_row_cnt <= (others => '0');

      else

        if i_bufi_rd = '1' then
          if i_pix_cnt = (TO_UNSIGNED(G_VFR_PIX_COUNT - 1, i_pix_cnt'length)) then
            i_pix_cnt <= (others => '0');

            if i_row_cnt = (TO_UNSIGNED(G_VFR_ROW_COUNT - 1, i_row_cnt'length)) then
              i_row_cnt <= (others => '0');

            else
              i_row_cnt <= i_row_cnt + 1;
            end if;

          else
            i_pix_cnt <= i_pix_cnt + 1;
          end if;
        end if;

      end if;

  end if;
end if;
end process read_bufi;


--END MAIN
end architecture behavioral;


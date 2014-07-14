-------------------------------------------------------------------------
-- Company     : Yansar
-- Engineer    : Golovachenko Victor
--
-- Create Date : 19.06.2014 11:14:45
-- Module Name : ccd_spi
--
-- Назначение/Описание :
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
use work.ccd_vita25K_pkg.all;
use work.spi_pkg.all;
use work.vicg_common_pkg.all;
use work.reduce_pack.all;

entity ccd_spi is
generic(
G_SIM : string := "OFF"
);
port(
p_out_physpi    : out  TSPI_pinout;
p_in_physpi     : in   TSPI_pinin;
p_out_ccdrst_n  : out  std_logic;

--p_in_fifo_dout  : in   std_logic_vector(15 downto 0);
--p_out_fifo_rd   : out  std_logic;
--p_in_fifo_empty : in   std_logic;

p_out_init_done : out  std_logic;

p_out_tst       : out  std_logic_vector(31 downto 0);
p_in_tst        : in   std_logic_vector(31 downto 0);

p_in_clk        : in   std_logic;
p_in_rst        : in   std_logic
);
end;

architecture behavior of ccd_spi is

component spi_core is
generic(
G_AWIDTH : integer := 16;
G_DWIDTH : integer := 16
);
port(
p_in_adr    : in   std_logic_vector(G_AWIDTH - 1 downto 0);
p_in_data   : in   std_logic_vector(G_DWIDTH - 1 downto 0); --FPGA -> DEV
p_out_data  : out  std_logic_vector(G_DWIDTH - 1 downto 0); --FPGA <- DEV
p_in_dir    : in   std_logic;
p_in_start  : in   std_logic;

p_out_busy  : out  std_logic;

p_out_physpi : out TSPI_pinout;
p_in_physpi  : in  TSPI_pinin;

p_out_tst    : out std_logic_vector(31 downto 0);
p_in_tst     : in  std_logic_vector(31 downto 0);

p_in_clk_en : in   std_logic;
p_in_clk    : in   std_logic;
p_in_rst    : in   std_logic
);
end component;

type TFsm_spireg is (
S_IDLE,
S_INIT_WR,
S_INIT_WR_1,
S_INIT_WR_2,
S_INIT_RD,
S_INIT_RD_1,
S_INIT_RD_2,

S_REG_USR,
S_RD_CHIPID,
S_RD_CHIPID_1,
S_RD_CHIPID_2,
S_ERR,
S_CCD_RST_DONE,
S_WAIT1_BTN
);

signal i_fsm_spi_cs     : TFsm_spireg;

signal i_clkcnt         : unsigned(5 downto 0) := (others => '0');
signal i_clk_en         : std_logic := '0';

signal i_busy           : std_logic := '0';
signal i_spi_core_dir   : std_logic := '0';
signal i_spi_core_start : std_logic := '0';
signal i_adr            : std_logic_vector(9 downto 0) := (others => '0');
signal i_txd            : std_logic_vector(15 downto 0) := (others => '0');
signal i_rxd            : std_logic_vector(15 downto 0) := (others => '0');

signal i_regcnt         : unsigned(4 downto 0) := (others => '0');
signal i_cntdelay       : unsigned(9 downto 0) := (others => '0');
signal i_ccd_rst_n      : std_logic := '0';
signal i_init_done      : std_logic := '0';

signal i_btn_push_tmp   : std_logic := '0';
signal i_btn_push       : std_logic := '0';
signal tst_fsmstate,tst_fsmstate_dly : std_logic_vector(3 downto 0) := (others => '0');
signal i_spi_core_tst_out : std_logic_vector(31 downto 0) := (others => '0');
signal i_id_rd_done       : std_logic := '0';


--MAIN
begin

p_out_tst(0) <= i_clkcnt(5);
p_out_tst(1) <= OR_reduce(tst_fsmstate_dly);
p_out_tst(2) <= i_spi_core_tst_out(1);
p_out_tst(3) <= OR_reduce(i_rxd);
p_out_tst(31 downto 4) <= (others => '0');

p_out_ccdrst_n <= i_ccd_rst_n;

p_out_init_done <= i_init_done;

process(p_in_clk)
begin
  if rising_edge(p_in_clk) then
    i_clkcnt <= i_clkcnt + 1;

    if i_clkcnt = (i_clkcnt'range => '1') then
      i_clk_en <= '1';
    else
      i_clk_en <= '0';
    end if;
  end if;
end process;


process(p_in_clk)
begin
  if rising_edge(p_in_clk) then
    if p_in_rst = '1' then
      i_regcnt <= (others => '0'); i_cntdelay <= (others => '0');
      i_adr <= (others => '0'); i_ccd_rst_n <= '0'; i_id_rd_done <= '0';
      i_txd <= (others => '0');
      i_spi_core_dir <= '0';
      i_spi_core_start <= '0';
      i_init_done <= '0';
      i_fsm_spi_cs <= S_IDLE;

    else
      if i_clk_en = '1' then

        case i_fsm_spi_cs is

          when S_IDLE =>

            if i_btn_push = '1' then
              i_ccd_rst_n <= '0';
              i_regcnt <= (others => '0');
              i_fsm_spi_cs <= S_CCD_RST_DONE;
            end if;

          --------------------------------
          --CCD INIT (Enable clock management)
          --------------------------------
          when S_INIT_WR =>

            for i in 0 to C_CCD_REGINIT'length - 1 loop
              if i_regcnt = i then
                i_adr <= C_CCD_REGINIT(i)(24 downto 16) & '1';--RegAdr & CMD(0/1 -Read/Write)
                i_txd <= C_CCD_REGINIT(i)(15 downto 0);
              end if;
            end loop;

            i_spi_core_dir <= C_SPI_WRITE;
            i_spi_core_start <= '1';
            i_fsm_spi_cs <= S_INIT_WR_1;

          when S_INIT_WR_1 =>

            i_spi_core_start <= '0';
            i_fsm_spi_cs <= S_INIT_WR_2;

          when S_INIT_WR_2 =>

            if i_busy = '0' then
              i_fsm_spi_cs <= S_INIT_RD;
--              i_fsm_spi_cs <= S_WAIT1_BTN;
--              i_regcnt <= i_regcnt + 1;
            end if;

          --Check it
          when S_INIT_RD =>

--            if i_btn_push = '1' then
            i_adr <= i_adr(i_adr'length - 1 downto 1) & '0';--RegAdr & CMD(0/1 -Read/Write)
            i_spi_core_dir <= C_SPI_READ;
            i_spi_core_start <= '1';
            i_fsm_spi_cs <= S_INIT_RD_1;
--            end if;

          when S_INIT_RD_1 =>

            i_spi_core_start <= '0';
            i_fsm_spi_cs <= S_INIT_RD_2;

          when S_INIT_RD_2 =>

            if i_busy = '0' then

              if i_rxd /= i_txd then
                i_fsm_spi_cs <= S_ERR;
              else
                i_fsm_spi_cs <= S_WAIT1_BTN;
              end if;

              i_regcnt <= i_regcnt + 1;

            end if;

          --------------------------------
          --CCD User Reg Control
          --------------------------------
          when S_REG_USR =>
            i_spi_core_dir <= C_SPI_WRITE;
            i_spi_core_start <= '0';
            i_fsm_spi_cs <= S_REG_USR;

          --------------------------------
          --
          --------------------------------
          when S_RD_CHIPID =>

            i_adr <= "0000" & std_logic_vector(i_regcnt) & '0';--RegAdr & CMD(0/1 -Read/Write)
            i_spi_core_dir <= C_SPI_READ;
            i_spi_core_start <= '1';
            i_fsm_spi_cs <= S_RD_CHIPID_1;

          when S_RD_CHIPID_1 =>

            i_spi_core_start <= '0';
            i_fsm_spi_cs <= S_RD_CHIPID_2;

          when S_RD_CHIPID_2 =>

            if i_busy = '0' then
              if i_adr(i_adr'length - 1 downto 1) = std_logic_vector(TO_UNSIGNED(10#00#,i_adr'length - 1)) then
                if i_rxd /= std_logic_vector(TO_UNSIGNED(16#56FA#,i_rxd'length)) then
                  i_regcnt <= (others => '0');
                  i_fsm_spi_cs <= S_ERR;
                else
                  i_regcnt <= i_regcnt + 1;
                  i_fsm_spi_cs <= S_RD_CHIPID;--S_WAIT1_BTN;
                end if;

              elsif i_adr(i_adr'length - 1 downto 1) = std_logic_vector(TO_UNSIGNED(10#01#,i_adr'length - 1)) then
                i_regcnt <= (others => '0');

                if i_rxd /= std_logic_vector(TO_UNSIGNED(16#01#,i_rxd'length)) then
                  i_fsm_spi_cs <= S_ERR;
                else
                  i_id_rd_done <= '1';
                  i_fsm_spi_cs <= S_WAIT1_BTN;
                end if;

              end if;
            end if;

          when S_ERR =>

            i_fsm_spi_cs <= S_ERR;

          when S_CCD_RST_DONE =>

              i_fsm_spi_cs <= S_WAIT1_BTN;
              i_ccd_rst_n <= '1';

          when S_WAIT1_BTN =>

            if i_btn_push = '1' then
              if i_regcnt = TO_UNSIGNED(C_CCD_REGINIT'length, i_regcnt'length) then
                i_init_done <= '1';
                i_fsm_spi_cs <= S_REG_USR;
              else
                if i_id_rd_done = '0' then
                  i_fsm_spi_cs <= S_RD_CHIPID;
                else
                  i_fsm_spi_cs <= S_INIT_WR;
                end if;
              end if;
            end if;

        end case;

      end if; --if i_clk_en = '1' then
    end if;
  end if;
end process;


m_spi_core : spi_core
generic map(
G_AWIDTH => C_CCD_SPI_AWIDTH + 1,
G_DWIDTH => C_CCD_SPI_DWIDTH
)
port map(
p_in_adr    => i_adr,
p_in_data   => i_txd,
p_out_data  => i_rxd,
p_in_dir    => i_spi_core_dir,
p_in_start  => i_spi_core_start,

p_out_busy  => i_busy,

p_out_physpi => p_out_physpi,
p_in_physpi  => p_in_physpi,

p_out_tst    => i_spi_core_tst_out,
p_in_tst     => p_in_tst,

p_in_clk_en => i_clk_en,
p_in_clk    => p_in_clk,
p_in_rst    => p_in_rst
);

process(p_in_clk)
begin
  if rising_edge(p_in_clk) then

    if i_clk_en = '1' and i_btn_push = '1' then
      i_btn_push_tmp <= '0';
    elsif p_in_tst(0) = '1' then
      i_btn_push_tmp <= '1';
    end if;

    if i_clk_en = '1' and i_btn_push_tmp = '1' then
      i_btn_push <= '1';
    elsif i_clk_en = '1' and i_btn_push = '1' then
      i_btn_push <= '0';
    end if;

    tst_fsmstate_dly <= tst_fsmstate;
  end if;
end process;


tst_fsmstate <= std_logic_vector(TO_UNSIGNED(16#0D#,tst_fsmstate'length)) when i_fsm_spi_cs = S_WAIT1_BTN     else
                std_logic_vector(TO_UNSIGNED(16#0C#,tst_fsmstate'length)) when i_fsm_spi_cs = S_CCD_RST_DONE       else
                std_logic_vector(TO_UNSIGNED(16#0B#,tst_fsmstate'length)) when i_fsm_spi_cs = S_REG_USR       else
                std_logic_vector(TO_UNSIGNED(16#0A#,tst_fsmstate'length)) when i_fsm_spi_cs = S_ERR           else
                std_logic_vector(TO_UNSIGNED(16#09#,tst_fsmstate'length)) when i_fsm_spi_cs = S_RD_CHIPID     else
                std_logic_vector(TO_UNSIGNED(16#08#,tst_fsmstate'length)) when i_fsm_spi_cs = S_RD_CHIPID_1   else
                std_logic_vector(TO_UNSIGNED(16#07#,tst_fsmstate'length)) when i_fsm_spi_cs = S_RD_CHIPID_2   else
                std_logic_vector(TO_UNSIGNED(16#06#,tst_fsmstate'length)) when i_fsm_spi_cs = S_INIT_WR       else
                std_logic_vector(TO_UNSIGNED(16#05#,tst_fsmstate'length)) when i_fsm_spi_cs = S_INIT_WR_1     else
                std_logic_vector(TO_UNSIGNED(16#04#,tst_fsmstate'length)) when i_fsm_spi_cs = S_INIT_WR_2     else
                std_logic_vector(TO_UNSIGNED(16#03#,tst_fsmstate'length)) when i_fsm_spi_cs = S_INIT_RD       else
                std_logic_vector(TO_UNSIGNED(16#02#,tst_fsmstate'length)) when i_fsm_spi_cs = S_INIT_RD_1     else
                std_logic_vector(TO_UNSIGNED(16#01#,tst_fsmstate'length)) when i_fsm_spi_cs = S_INIT_RD_2     else
                std_logic_vector(TO_UNSIGNED(16#00#,tst_fsmstate'length)); --i_fsm_spi_cs = S_IDLE              else


--END MAIN
end architecture;


-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 17.01.2013 11:13:58
-- Module Name : video_writer
--
-- ����������/�������� :
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

entity video_writer is
generic(
G_USR_OPT         : std_logic_vector(3 downto 0):=(others=>'0');
G_DBGCS           : string :="OFF";
G_MEM_AWIDTH      : integer:=32;
G_MEM_DWIDTH      : integer:=32
);
port(
-------------------------------
--����������������
-------------------------------
p_in_mem_trn_len      : in    std_logic_vector(7 downto 0);--������ ��������� ���������� MEM_WR
p_in_prm_vch          : in    TWriterVCHParams;            --��������� ������ ����� �������
p_in_work_en          : in    std_logic;
p_in_vfr_buf          : in    TVfrBufs;                    --����� ������ ��� ����� ������������� ������� ����

--�������
p_out_vfr_rdy         : out   std_logic;--���� ����� ��� ���������������� �����������

----------------------------
--Upstream Port (����� � ������� ������������)
----------------------------
p_in_upp_data         : in    std_logic_vector(G_MEM_DWIDTH - 1 downto 0);
p_out_upp_data_rd     : out   std_logic;
p_in_upp_buf_empty    : in    std_logic;
p_in_upp_buf_full     : in    std_logic;
p_in_upp_buf_pfull    : in    std_logic;

---------------------------------
--����� � mem_ctrl.vhd
---------------------------------
p_out_mem             : out   TMemIN;
p_in_mem              : in    TMemOUT;

-------------------------------
--���������������
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

type TFsm_state is (
S_IDLE,
S_MEM_START,
S_MEM_WR
);
signal i_fsm_state_cs              : TFsm_state;

signal i_mem_adr                   : unsigned(31 downto 0) := (others => '0');
signal i_mem_trn_len               : unsigned(15 downto 0) := (others => '0');
signal i_mem_dlen_rq               : unsigned(15 downto 0) := (others => '0');
signal i_mem_start                 : std_logic;
signal i_mem_dir                   : std_logic;
signal i_mem_done                  : std_logic;
signal i_pix_count_byte            : unsigned(C_VCTRL_MEM_VLINE_L_BIT - 1 downto 0) := (others => '0');
signal i_vfr_rowcnt                : unsigned(C_VCTRL_MEM_VLINE_M_BIT - C_VCTRL_MEM_VLINE_L_BIT
                                                                              downto 0) := (others => '0');
signal i_padding                   : std_logic;
signal i_upp_buf_empty             : std_logic;
signal i_vfr_rdy                   : std_logic;

signal tst_mem_wr_out              : std_logic_vector(31 downto 0);
signal tst_fsmstate,tst_fsm_cs_dly : unsigned(3 downto 0) := (others => '0');
signal tst_upp_data                : std_logic_vector(p_in_upp_data'range);
signal tst_upp_data_rd,i_upp_data_rd : std_logic;

--MAIN
begin


------------------------------------
--��������������� �������
------------------------------------
--p_out_tst(31 downto 0) <= (others=>'0');
p_out_tst(5 downto 0) <= tst_mem_wr_out(5 downto 0);
p_out_tst(7 downto 6) <= OR_reduce(tst_upp_data) & tst_upp_data_rd;
p_out_tst(10 downto 8 )<= std_logic_vector(tst_fsm_cs_dly(2 downto 0));
p_out_tst(11) <= '0';
p_out_tst(21 downto 16) <= tst_mem_wr_out(21 downto 16);--i_mem_trn_len(5 downto 0);
p_out_tst(31 downto 22) <= (others=>'0');


process(p_in_clk)
begin
  if rising_edge(p_in_clk) then
    tst_fsm_cs_dly <= tst_fsmstate;
    tst_upp_data <= p_in_upp_data;
    tst_upp_data_rd <= i_upp_data_rd;
  end if;
end process;
tst_fsmstate <= TO_UNSIGNED(16#01#, tst_fsmstate'length) when i_fsm_state_cs = S_MEM_START else
                TO_UNSIGNED(16#02#, tst_fsmstate'length) when i_fsm_state_cs = S_MEM_WR    else
                TO_UNSIGNED(16#00#, tst_fsmstate'length); --i_fsm_state_cs = S_IDLE        else


------------------------------------------------
--�������
------------------------------------------------
p_out_vfr_rdy <= i_vfr_rdy;


------------------------------------------------
--������� ������ ����� ����������
------------------------------------------------
i_pix_count_byte <= UNSIGNED(p_in_prm_vch(0).fr_size.activ.pix(i_pix_count_byte'range));

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
    i_vfr_rdy <= '0';

  else

    case i_fsm_state_cs is

      --------------------------------------
      --�������� ���������
      --------------------------------------
      when S_IDLE =>

        i_padding <= '0';
        i_vfr_rowcnt <= (others=>'0');
        i_vfr_rdy <= '0';

        if p_in_upp_buf_empty = '0' and p_in_work_en = '1' then
          i_fsm_state_cs <= S_MEM_START;
        end if;

      --------------------------------------
      --��������� �������� ������ ���
      --------------------------------------
      when S_MEM_START =>

        if p_in_work_en = '0' then
          i_fsm_state_cs <= S_IDLE;

        else
          i_mem_adr(C_VCTRL_MEM_VLINE_M_BIT downto C_VCTRL_MEM_VLINE_L_BIT) <= i_vfr_rowcnt;
          i_mem_adr(C_VCTRL_MEM_VLINE_L_BIT - 1 downto 0) <= (others => '0');

          i_mem_dlen_rq <= RESIZE(i_pix_count_byte(i_pix_count_byte'high downto log2(G_MEM_DWIDTH / 8))
                                                                                , i_mem_dlen_rq'length)
                           + (TO_UNSIGNED(0, i_mem_dlen_rq'length - 2)
                              & OR_reduce(i_pix_count_byte(log2(G_MEM_DWIDTH / 8) - 1 downto 0)));

          i_mem_trn_len <= RESIZE(UNSIGNED(p_in_mem_trn_len), i_mem_trn_len'length);

          i_mem_dir <= C_MEMWR_WRITE;
          i_mem_start <= '1';
          i_fsm_state_cs <= S_MEM_WR;

        end if;

      ------------------------------------------------
      --������ ������
      ------------------------------------------------
      when S_MEM_WR =>

        if p_in_work_en = '0' then
          i_padding <= '1';
        end if;

        i_mem_start <= '0';
        if i_mem_done = '1' then
          if i_vfr_rowcnt = (UNSIGNED(p_in_prm_vch(0).fr_size.activ.row(i_vfr_rowcnt'range)) - 1)
              or i_padding = '1' then

            i_vfr_rdy <= '1';
            i_fsm_state_cs <= S_IDLE;
          else
            i_vfr_rowcnt <= i_vfr_rowcnt + 1;
            i_fsm_state_cs <= S_MEM_START;
          end if;
        end if;

    end case;

  end if;
end if;
end process;


--------------------------------------------------------
--������ ������/������ ������ ��� (mem_ctrl.vhd)
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
--����������������
-------------------------------
p_in_cfg_mem_adr     => std_logic_vector(i_mem_adr)    ,
p_in_cfg_mem_trn_len => std_logic_vector(i_mem_trn_len),
p_in_cfg_mem_dlen_rq => std_logic_vector(i_mem_dlen_rq),
p_in_cfg_mem_wr      => i_mem_dir,
p_in_cfg_mem_start   => i_mem_start,
p_out_cfg_mem_done   => i_mem_done,

-------------------------------
--����� � ����������������� ��������
-------------------------------
p_in_usr_txbuf_dout  => p_in_upp_data,
p_out_usr_txbuf_rd   => i_upp_data_rd,
p_in_usr_txbuf_empty => i_upp_buf_empty,

p_out_usr_rxbuf_din  => open,
p_out_usr_rxbuf_wd   => open,
p_in_usr_rxbuf_full  => '0',

---------------------------------
--����� � mem_ctrl.vhd
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
p_out_upp_data_rd <= i_upp_data_rd;

--END MAIN
end behavioral;


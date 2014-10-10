onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /test_lvds_tb/i_sys_rst
add wave -noupdate /test_lvds_tb/i_sys_clk
add wave -noupdate /test_lvds_tb/i_usr_dclken
add wave -noupdate /test_lvds_tb/i_fsm_send
add wave -noupdate -radix hexadecimal -childformat {{/test_lvds_tb/i_cntdly(31) -radix hexadecimal} {/test_lvds_tb/i_cntdly(30) -radix hexadecimal} {/test_lvds_tb/i_cntdly(29) -radix hexadecimal} {/test_lvds_tb/i_cntdly(28) -radix hexadecimal} {/test_lvds_tb/i_cntdly(27) -radix hexadecimal} {/test_lvds_tb/i_cntdly(26) -radix hexadecimal} {/test_lvds_tb/i_cntdly(25) -radix hexadecimal} {/test_lvds_tb/i_cntdly(24) -radix hexadecimal} {/test_lvds_tb/i_cntdly(23) -radix hexadecimal} {/test_lvds_tb/i_cntdly(22) -radix hexadecimal} {/test_lvds_tb/i_cntdly(21) -radix hexadecimal} {/test_lvds_tb/i_cntdly(20) -radix hexadecimal} {/test_lvds_tb/i_cntdly(19) -radix hexadecimal} {/test_lvds_tb/i_cntdly(18) -radix hexadecimal} {/test_lvds_tb/i_cntdly(17) -radix hexadecimal} {/test_lvds_tb/i_cntdly(16) -radix hexadecimal} {/test_lvds_tb/i_cntdly(15) -radix hexadecimal} {/test_lvds_tb/i_cntdly(14) -radix hexadecimal} {/test_lvds_tb/i_cntdly(13) -radix hexadecimal} {/test_lvds_tb/i_cntdly(12) -radix hexadecimal} {/test_lvds_tb/i_cntdly(11) -radix hexadecimal} {/test_lvds_tb/i_cntdly(10) -radix hexadecimal} {/test_lvds_tb/i_cntdly(9) -radix hexadecimal} {/test_lvds_tb/i_cntdly(8) -radix hexadecimal} {/test_lvds_tb/i_cntdly(7) -radix hexadecimal} {/test_lvds_tb/i_cntdly(6) -radix hexadecimal} {/test_lvds_tb/i_cntdly(5) -radix hexadecimal} {/test_lvds_tb/i_cntdly(4) -radix hexadecimal} {/test_lvds_tb/i_cntdly(3) -radix hexadecimal} {/test_lvds_tb/i_cntdly(2) -radix hexadecimal} {/test_lvds_tb/i_cntdly(1) -radix hexadecimal} {/test_lvds_tb/i_cntdly(0) -radix hexadecimal}} -subitemconfig {/test_lvds_tb/i_cntdly(31) {-height 15 -radix hexadecimal} /test_lvds_tb/i_cntdly(30) {-height 15 -radix hexadecimal} /test_lvds_tb/i_cntdly(29) {-height 15 -radix hexadecimal} /test_lvds_tb/i_cntdly(28) {-height 15 -radix hexadecimal} /test_lvds_tb/i_cntdly(27) {-height 15 -radix hexadecimal} /test_lvds_tb/i_cntdly(26) {-height 15 -radix hexadecimal} /test_lvds_tb/i_cntdly(25) {-height 15 -radix hexadecimal} /test_lvds_tb/i_cntdly(24) {-height 15 -radix hexadecimal} /test_lvds_tb/i_cntdly(23) {-height 15 -radix hexadecimal} /test_lvds_tb/i_cntdly(22) {-height 15 -radix hexadecimal} /test_lvds_tb/i_cntdly(21) {-height 15 -radix hexadecimal} /test_lvds_tb/i_cntdly(20) {-height 15 -radix hexadecimal} /test_lvds_tb/i_cntdly(19) {-height 15 -radix hexadecimal} /test_lvds_tb/i_cntdly(18) {-height 15 -radix hexadecimal} /test_lvds_tb/i_cntdly(17) {-height 15 -radix hexadecimal} /test_lvds_tb/i_cntdly(16) {-height 15 -radix hexadecimal} /test_lvds_tb/i_cntdly(15) {-height 15 -radix hexadecimal} /test_lvds_tb/i_cntdly(14) {-height 15 -radix hexadecimal} /test_lvds_tb/i_cntdly(13) {-height 15 -radix hexadecimal} /test_lvds_tb/i_cntdly(12) {-height 15 -radix hexadecimal} /test_lvds_tb/i_cntdly(11) {-height 15 -radix hexadecimal} /test_lvds_tb/i_cntdly(10) {-height 15 -radix hexadecimal} /test_lvds_tb/i_cntdly(9) {-height 15 -radix hexadecimal} /test_lvds_tb/i_cntdly(8) {-height 15 -radix hexadecimal} /test_lvds_tb/i_cntdly(7) {-height 15 -radix hexadecimal} /test_lvds_tb/i_cntdly(6) {-height 15 -radix hexadecimal} /test_lvds_tb/i_cntdly(5) {-height 15 -radix hexadecimal} /test_lvds_tb/i_cntdly(4) {-height 15 -radix hexadecimal} /test_lvds_tb/i_cntdly(3) {-height 15 -radix hexadecimal} /test_lvds_tb/i_cntdly(2) {-height 15 -radix hexadecimal} /test_lvds_tb/i_cntdly(1) {-height 15 -radix hexadecimal} /test_lvds_tb/i_cntdly(0) {-height 15 -radix hexadecimal}} /test_lvds_tb/i_cntdly
add wave -noupdate -radix hexadecimal /test_lvds_tb/i_usr_d
add wave -noupdate -divider SEND
add wave -noupdate /test_lvds_tb/m_snd/i_clk_div
add wave -noupdate /test_lvds_tb/m_snd/i_mmcm_lckd
add wave -noupdate /test_lvds_tb/m_snd/i_oserdes_clken
add wave -noupdate -radix hexadecimal /test_lvds_tb/m_snd/i_oserdes_din
add wave -noupdate /test_lvds_tb/m_snd/i_oserdes_dout
add wave -noupdate /test_lvds_tb/m_snd/p_out_lvds_data_p
add wave -noupdate /test_lvds_tb/m_snd/p_out_lvds_data_n
add wave -noupdate /test_lvds_tb/m_snd/p_out_lvds_clk_p
add wave -noupdate /test_lvds_tb/m_snd/p_out_lvds_clk_n
add wave -noupdate -divider RECIVER
add wave -noupdate /test_lvds_tb/i_align_start
add wave -noupdate /test_lvds_tb/m_rcv/m_deser/i_align_start
add wave -noupdate /test_lvds_tb/m_rcv/m_deser/i_align_busy
add wave -noupdate /test_lvds_tb/m_rcv/m_deser/p_out_align_ok
add wave -noupdate /test_lvds_tb/m_rcv/m_clk_gen/g_ccd2fpga
add wave -noupdate /test_lvds_tb/m_rcv/i_mmcm_lckd
add wave -noupdate /test_lvds_tb/m_rcv/m_deser/i_fsm_handshake
add wave -noupdate /test_lvds_tb/m_rcv/m_deser/i_fsm_serdesseq
add wave -noupdate -color {Slate Blue} /test_lvds_tb/m_rcv/m_deser/i_fsm_align
add wave -noupdate -radix hexadecimal /test_lvds_tb/m_rcv/m_deser/i_deser_d
add wave -noupdate -radix hexadecimal /test_lvds_tb/m_rcv/m_deser/p_out_data
add wave -noupdate -radix hexadecimal /test_lvds_tb/m_rcv/m_deser/tst_deser_d_sv_ROL
add wave -noupdate -radix hexadecimal /test_lvds_tb/m_rcv/m_deser/tst_deser_d_sv_ROR
add wave -noupdate -radix hexadecimal /test_lvds_tb/m_rcv/m_deser/i_deser_d_sv
add wave -noupdate -radix hexadecimal /test_lvds_tb/m_rcv/m_deser/i_edge
add wave -noupdate -radix hexadecimal /test_lvds_tb/m_rcv/m_deser/i_edge_or
add wave -noupdate -radix hexadecimal /test_lvds_tb/m_rcv/m_deser/i_edge_sv
add wave -noupdate /test_lvds_tb/m_rcv/m_deser/i_handshake_start
add wave -noupdate /test_lvds_tb/m_rcv/m_deser/i_handshake_end
add wave -noupdate /test_lvds_tb/m_rcv/m_deser/i_idelaye2_ce
add wave -noupdate /test_lvds_tb/m_rcv/m_deser/i_idelaye2_inc
add wave -noupdate /test_lvds_tb/m_rcv/m_deser/i_bitslip
add wave -noupdate /test_lvds_tb/m_rcv/m_deser/i_deser_rst
add wave -noupdate /test_lvds_tb/m_rcv/m_deser/i_align_done
add wave -noupdate -radix hexadecimal /test_lvds_tb/m_rcv/m_deser/i_cnt_tap
add wave -noupdate -radix hexadecimal /test_lvds_tb/m_rcv/m_deser/i_cnt_retry
add wave -noupdate -radix hexadecimal /test_lvds_tb/m_rcv/m_deser/i_gen_cntr
add wave -noupdate -radix hexadecimal /test_lvds_tb/m_rcv/m_deser/windowcount
add wave -noupdate -radix hexadecimal -childformat {{/test_lvds_tb/m_rcv/m_deser/sr_train_compare(0) -radix hexadecimal -childformat {{/test_lvds_tb/m_rcv/m_deser/sr_train_compare(0)(9) -radix hexadecimal} {/test_lvds_tb/m_rcv/m_deser/sr_train_compare(0)(8) -radix hexadecimal} {/test_lvds_tb/m_rcv/m_deser/sr_train_compare(0)(7) -radix hexadecimal} {/test_lvds_tb/m_rcv/m_deser/sr_train_compare(0)(6) -radix hexadecimal} {/test_lvds_tb/m_rcv/m_deser/sr_train_compare(0)(5) -radix hexadecimal} {/test_lvds_tb/m_rcv/m_deser/sr_train_compare(0)(4) -radix hexadecimal} {/test_lvds_tb/m_rcv/m_deser/sr_train_compare(0)(3) -radix hexadecimal} {/test_lvds_tb/m_rcv/m_deser/sr_train_compare(0)(2) -radix hexadecimal} {/test_lvds_tb/m_rcv/m_deser/sr_train_compare(0)(1) -radix hexadecimal} {/test_lvds_tb/m_rcv/m_deser/sr_train_compare(0)(0) -radix hexadecimal}}} {/test_lvds_tb/m_rcv/m_deser/sr_train_compare(1) -radix hexadecimal} {/test_lvds_tb/m_rcv/m_deser/sr_train_compare(2) -radix hexadecimal} {/test_lvds_tb/m_rcv/m_deser/sr_train_compare(3) -radix hexadecimal} {/test_lvds_tb/m_rcv/m_deser/sr_train_compare(4) -radix hexadecimal} {/test_lvds_tb/m_rcv/m_deser/sr_train_compare(5) -radix hexadecimal} {/test_lvds_tb/m_rcv/m_deser/sr_train_compare(6) -radix hexadecimal} {/test_lvds_tb/m_rcv/m_deser/sr_train_compare(7) -radix hexadecimal} {/test_lvds_tb/m_rcv/m_deser/sr_train_compare(8) -radix hexadecimal} {/test_lvds_tb/m_rcv/m_deser/sr_train_compare(9) -radix hexadecimal}} -subitemconfig {/test_lvds_tb/m_rcv/m_deser/sr_train_compare(0) {-height 15 -radix hexadecimal -childformat {{/test_lvds_tb/m_rcv/m_deser/sr_train_compare(0)(9) -radix hexadecimal} {/test_lvds_tb/m_rcv/m_deser/sr_train_compare(0)(8) -radix hexadecimal} {/test_lvds_tb/m_rcv/m_deser/sr_train_compare(0)(7) -radix hexadecimal} {/test_lvds_tb/m_rcv/m_deser/sr_train_compare(0)(6) -radix hexadecimal} {/test_lvds_tb/m_rcv/m_deser/sr_train_compare(0)(5) -radix hexadecimal} {/test_lvds_tb/m_rcv/m_deser/sr_train_compare(0)(4) -radix hexadecimal} {/test_lvds_tb/m_rcv/m_deser/sr_train_compare(0)(3) -radix hexadecimal} {/test_lvds_tb/m_rcv/m_deser/sr_train_compare(0)(2) -radix hexadecimal} {/test_lvds_tb/m_rcv/m_deser/sr_train_compare(0)(1) -radix hexadecimal} {/test_lvds_tb/m_rcv/m_deser/sr_train_compare(0)(0) -radix hexadecimal}}} /test_lvds_tb/m_rcv/m_deser/sr_train_compare(0)(9) {-height 15 -radix hexadecimal} /test_lvds_tb/m_rcv/m_deser/sr_train_compare(0)(8) {-height 15 -radix hexadecimal} /test_lvds_tb/m_rcv/m_deser/sr_train_compare(0)(7) {-height 15 -radix hexadecimal} /test_lvds_tb/m_rcv/m_deser/sr_train_compare(0)(6) {-height 15 -radix hexadecimal} /test_lvds_tb/m_rcv/m_deser/sr_train_compare(0)(5) {-height 15 -radix hexadecimal} /test_lvds_tb/m_rcv/m_deser/sr_train_compare(0)(4) {-height 15 -radix hexadecimal} /test_lvds_tb/m_rcv/m_deser/sr_train_compare(0)(3) {-height 15 -radix hexadecimal} /test_lvds_tb/m_rcv/m_deser/sr_train_compare(0)(2) {-height 15 -radix hexadecimal} /test_lvds_tb/m_rcv/m_deser/sr_train_compare(0)(1) {-height 15 -radix hexadecimal} /test_lvds_tb/m_rcv/m_deser/sr_train_compare(0)(0) {-height 15 -radix hexadecimal} /test_lvds_tb/m_rcv/m_deser/sr_train_compare(1) {-height 15 -radix hexadecimal} /test_lvds_tb/m_rcv/m_deser/sr_train_compare(2) {-height 15 -radix hexadecimal} /test_lvds_tb/m_rcv/m_deser/sr_train_compare(3) {-height 15 -radix hexadecimal} /test_lvds_tb/m_rcv/m_deser/sr_train_compare(4) {-height 15 -radix hexadecimal} /test_lvds_tb/m_rcv/m_deser/sr_train_compare(5) {-height 15 -radix hexadecimal} /test_lvds_tb/m_rcv/m_deser/sr_train_compare(6) {-height 15 -radix hexadecimal} /test_lvds_tb/m_rcv/m_deser/sr_train_compare(7) {-height 15 -radix hexadecimal} /test_lvds_tb/m_rcv/m_deser/sr_train_compare(8) {-height 15 -radix hexadecimal} /test_lvds_tb/m_rcv/m_deser/sr_train_compare(9) {-height 15 -radix hexadecimal}} /test_lvds_tb/m_rcv/m_deser/sr_train_compare
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ps} 0}
quietly wave cursor active 0
configure wave -namecolwidth 180
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ps
update
WaveRestoreZoom {0 ps} {105 us}

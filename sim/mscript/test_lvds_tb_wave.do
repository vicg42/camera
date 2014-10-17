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
add wave -noupdate /test_lvds_tb/m_rcv/m_deser/p_out_align_ok
add wave -noupdate /test_lvds_tb/m_rcv/m_deser/p_in_clkdiv
add wave -noupdate /test_lvds_tb/m_rcv/i_mmcm_lckd
add wave -noupdate -color {Slate Blue} /test_lvds_tb/m_rcv/m_deser/i_fsm_align
add wave -noupdate -radix hexadecimal /test_lvds_tb/m_rcv/m_deser/i_deser_d
add wave -noupdate -radix hexadecimal /test_lvds_tb/m_rcv/m_deser/p_out_data
add wave -noupdate -radix hexadecimal /test_lvds_tb/m_rcv/m_deser/i_deser_d_sv0
add wave -noupdate /test_lvds_tb/m_rcv/m_deser/i_idelaye2_ce
add wave -noupdate /test_lvds_tb/m_rcv/m_deser/i_idelaye2_inc
add wave -noupdate /test_lvds_tb/m_rcv/m_deser/i_bitslip
add wave -noupdate /test_lvds_tb/m_rcv/m_deser/i_deser_rst
add wave -noupdate -radix hexadecimal /test_lvds_tb/m_rcv/m_deser/i_cntdly
add wave -noupdate -radix hexadecimal /test_lvds_tb/m_rcv/m_deser/i_cnt_align_retry
add wave -noupdate -radix hexadecimal /test_lvds_tb/m_rcv/m_deser/i_cntwin
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
WaveRestoreZoom {15003145 ps} {15235881 ps}

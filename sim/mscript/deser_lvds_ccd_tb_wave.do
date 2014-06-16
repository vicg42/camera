onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -radix unsigned /deser_lvds_ccd_tb/dut/sys_w
add wave -noupdate -radix unsigned /deser_lvds_ccd_tb/dut/dev_w
add wave -noupdate /deser_lvds_ccd_tb/io_reset
add wave -noupdate /deser_lvds_ccd_tb/clk_reset
add wave -noupdate -divider TX
add wave -noupdate -radix hexadecimal /deser_lvds_ccd_tb/dut/pat_out
add wave -noupdate /deser_lvds_ccd_tb/dut/count_out1
add wave -noupdate /deser_lvds_ccd_tb/dut/count_out2
add wave -noupdate /deser_lvds_ccd_tb/dut/count_out
add wave -noupdate -divider LineTx/Rx
add wave -noupdate /deser_lvds_ccd_tb/dut/equal_cnt
add wave -noupdate -radix binary -childformat {{/deser_lvds_ccd_tb/dut/usr_cnt(9) -radix binary} {/deser_lvds_ccd_tb/dut/usr_cnt(8) -radix binary} {/deser_lvds_ccd_tb/dut/usr_cnt(7) -radix binary} {/deser_lvds_ccd_tb/dut/usr_cnt(6) -radix binary} {/deser_lvds_ccd_tb/dut/usr_cnt(5) -radix binary} {/deser_lvds_ccd_tb/dut/usr_cnt(4) -radix binary} {/deser_lvds_ccd_tb/dut/usr_cnt(3) -radix binary} {/deser_lvds_ccd_tb/dut/usr_cnt(2) -radix binary} {/deser_lvds_ccd_tb/dut/usr_cnt(1) -radix binary} {/deser_lvds_ccd_tb/dut/usr_cnt(0) -radix binary}} -subitemconfig {/deser_lvds_ccd_tb/dut/usr_cnt(9) {-height 15 -radix binary} /deser_lvds_ccd_tb/dut/usr_cnt(8) {-height 15 -radix binary} /deser_lvds_ccd_tb/dut/usr_cnt(7) {-height 15 -radix binary} /deser_lvds_ccd_tb/dut/usr_cnt(6) {-height 15 -radix binary} /deser_lvds_ccd_tb/dut/usr_cnt(5) {-height 15 -radix binary} /deser_lvds_ccd_tb/dut/usr_cnt(4) {-height 15 -radix binary} /deser_lvds_ccd_tb/dut/usr_cnt(3) {-height 15 -radix binary} /deser_lvds_ccd_tb/dut/usr_cnt(2) {-height 15 -radix binary} /deser_lvds_ccd_tb/dut/usr_cnt(1) {-height 15 -radix binary} /deser_lvds_ccd_tb/dut/usr_cnt(0) {-height 15 -radix binary}} /deser_lvds_ccd_tb/dut/usr_cnt
add wave -noupdate /deser_lvds_ccd_tb/dut/count_out3
add wave -noupdate /deser_lvds_ccd_tb/dut/equal
add wave -noupdate /deser_lvds_ccd_tb/dut/start_check
add wave -noupdate -radix hexadecimal /deser_lvds_ccd_tb/dut/bit_count
add wave -noupdate /deser_lvds_ccd_tb/dut/bitslip
add wave -noupdate -divider RX
add wave -noupdate /deser_lvds_ccd_tb/dut/clk_div_out
add wave -noupdate /deser_lvds_ccd_tb/dut/pattern_completed
add wave -noupdate -radix binary /deser_lvds_ccd_tb/dut/data_in_to_device
add wave -noupdate -radix binary /deser_lvds_ccd_tb/dut/data_delay
add wave -noupdate /deser_lvds_ccd_tb/dut/equal
add wave -noupdate /deser_lvds_ccd_tb/dut/start_count
add wave -noupdate /deser_lvds_ccd_tb/dut/local_counter
add wave -noupdate /deser_lvds_ccd_tb/dut/m_ccd/m_deser/sr_sync_rst
add wave -noupdate /deser_lvds_ccd_tb/dut/m_ccd/m_deser/i_mmcm_lckd
add wave -noupdate /deser_lvds_ccd_tb/dut/m_ccd/m_deser/i_idelayctrl_rdy
add wave -noupdate /deser_lvds_ccd_tb/dut/m_ccd/m_deser/i_deser_rdy
add wave -noupdate -radix binary /deser_lvds_ccd_tb/dut/m_ccd/m_deser/i_video_d
add wave -noupdate -radix hexadecimal /deser_lvds_ccd_tb/dut/m_ccd/m_deser/i_video_sync
add wave -noupdate /deser_lvds_ccd_tb/dut/m_ccd/m_deser/i_pattern_det_en
add wave -noupdate /deser_lvds_ccd_tb/dut/m_ccd/m_deser/i_bitslip_en
add wave -noupdate /deser_lvds_ccd_tb/dut/m_ccd/m_deser/i_bitcnt
add wave -noupdate /deser_lvds_ccd_tb/dut/m_ccd/m_deser/i_bitslip
add wave -noupdate /deser_lvds_ccd_tb/dut/m_ccd/m_deser/i_sync_tr_det
add wave -noupdate /deser_lvds_ccd_tb/dut/m_ccd/m_deser/i_sync_tr_det_cnt
add wave -noupdate /deser_lvds_ccd_tb/dut/m_ccd/m_deser/i_video_vs
add wave -noupdate /deser_lvds_ccd_tb/dut/m_ccd/m_deser/i_video_hs
add wave -noupdate /deser_lvds_ccd_tb/dut/m_ccd/m_deser/i_video_den
add wave -noupdate -divider {New Divider}
add wave -noupdate /deser_lvds_ccd_tb/dut/IO_RESET
add wave -noupdate /deser_lvds_ccd_tb/dut/delay_busy
add wave -noupdate /deser_lvds_ccd_tb/dut/delay_clk
add wave -noupdate /deser_lvds_ccd_tb/dut/delay_data_inc
add wave -noupdate /deser_lvds_ccd_tb/dut/delay_data_ce
add wave -noupdate /deser_lvds_ccd_tb/dut/delay_data_cal
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {370825 ps} 0}
quietly wave cursor active 0
configure wave -namecolwidth 230
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
configure wave -timelineunits ns
update
WaveRestoreZoom {0 ps} {11134582 ps}

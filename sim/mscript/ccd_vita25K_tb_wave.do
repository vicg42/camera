onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -radix hexadecimal -childformat {{/ccd_vita25k_tb/pin_in_ccd.data_p -radix hexadecimal} {/ccd_vita25k_tb/pin_in_ccd.data_n -radix hexadecimal} {/ccd_vita25k_tb/pin_in_ccd.clk_p -radix hexadecimal} {/ccd_vita25k_tb/pin_in_ccd.clk_n -radix hexadecimal} {/ccd_vita25k_tb/pin_in_ccd.misO -radix hexadecimal}} -expand -subitemconfig {/ccd_vita25k_tb/pin_in_ccd.data_p {-height 15 -radix hexadecimal} /ccd_vita25k_tb/pin_in_ccd.data_n {-height 15 -radix hexadecimal} /ccd_vita25k_tb/pin_in_ccd.clk_p {-height 15 -radix hexadecimal} /ccd_vita25k_tb/pin_in_ccd.clk_n {-height 15 -radix hexadecimal} /ccd_vita25k_tb/pin_in_ccd.misO {-height 15 -radix hexadecimal}} /ccd_vita25k_tb/pin_in_ccd
add wave -noupdate -radix hexadecimal -childformat {{/ccd_vita25k_tb/pin_out_ccd.clk_p -radix hexadecimal} {/ccd_vita25k_tb/pin_out_ccd.clk_n -radix hexadecimal} {/ccd_vita25k_tb/pin_out_ccd.rst_n -radix hexadecimal} {/ccd_vita25k_tb/pin_out_ccd.trig -radix hexadecimal} {/ccd_vita25k_tb/pin_out_ccd.sck -radix hexadecimal} {/ccd_vita25k_tb/pin_out_ccd.ss_n -radix hexadecimal} {/ccd_vita25k_tb/pin_out_ccd.mosi -radix hexadecimal}} -subitemconfig {/ccd_vita25k_tb/pin_out_ccd.clk_p {-height 15 -radix hexadecimal} /ccd_vita25k_tb/pin_out_ccd.clk_n {-height 15 -radix hexadecimal} /ccd_vita25k_tb/pin_out_ccd.rst_n {-height 15 -radix hexadecimal} /ccd_vita25k_tb/pin_out_ccd.trig {-height 15 -radix hexadecimal} /ccd_vita25k_tb/pin_out_ccd.sck {-height 15 -radix hexadecimal} /ccd_vita25k_tb/pin_out_ccd.ss_n {-height 15 -radix hexadecimal} /ccd_vita25k_tb/pin_out_ccd.mosi {-height 15 -radix hexadecimal}} /ccd_vita25k_tb/pin_out_ccd
add wave -noupdate /ccd_vita25k_tb/g_usrclk
add wave -noupdate /ccd_vita25k_tb/m_ccd/m_deser/m_clk_gen/clkint
add wave -noupdate /ccd_vita25k_tb/m_ccd/m_deser/i_mmcm_lckd
add wave -noupdate /ccd_vita25k_tb/m_ccd/m_deser/clk_in_int
add wave -noupdate /ccd_vita25k_tb/m_clocks/p_out_rst
add wave -noupdate /ccd_vita25k_tb/m_ccd/m_deser/clk_div
add wave -noupdate /ccd_vita25k_tb/i_rst
add wave -noupdate -radix hexadecimal /ccd_vita25k_tb/m_ccd/i_rstcnt
add wave -noupdate /ccd_vita25k_tb/m_ccd/i_ccd_rst_n
add wave -noupdate /ccd_vita25k_tb/m_ccd/m_spi/i_fsm_spi_cs
add wave -noupdate /ccd_vita25k_tb/m_ccd/m_spi/i_clk_en
add wave -noupdate /ccd_vita25k_tb/m_ccd/m_spi/i_clkcnt
add wave -noupdate -radix hexadecimal /ccd_vita25k_tb/m_ccd/m_spi/i_busy
add wave -noupdate -radix hexadecimal /ccd_vita25k_tb/m_ccd/m_spi/i_dir
add wave -noupdate -radix hexadecimal /ccd_vita25k_tb/m_ccd/m_spi/i_start
add wave -noupdate -radix unsigned /ccd_vita25k_tb/m_ccd/m_spi/i_adr
add wave -noupdate -radix hexadecimal /ccd_vita25k_tb/m_ccd/m_spi/i_txd
add wave -noupdate -radix hexadecimal /ccd_vita25k_tb/m_ccd/m_spi/i_rxd
add wave -noupdate -radix hexadecimal /ccd_vita25k_tb/m_ccd/m_spi/i_cnt
add wave -noupdate /ccd_vita25k_tb/m_ccd/m_spi/m_spi_core/i_fsm_core_cs
add wave -noupdate -radix hexadecimal /ccd_vita25k_tb/m_ccd/m_spi/m_spi_core/i_busy
add wave -noupdate -radix hexadecimal /ccd_vita25k_tb/m_ccd/m_spi/m_spi_core/i_sck
add wave -noupdate -radix hexadecimal /ccd_vita25k_tb/m_ccd/m_spi/m_spi_core/i_ss_n
add wave -noupdate -radix hexadecimal /ccd_vita25k_tb/m_ccd/m_spi/m_spi_core/sr_reg
add wave -noupdate -radix hexadecimal /ccd_vita25k_tb/m_ccd/m_spi/m_spi_core/i_bitcnt
add wave -noupdate /ccd_vita25k_tb/pin_out_ccd.mosi
add wave -noupdate /ccd_vita25k_tb/pin_out_ccd.ss_n
add wave -noupdate /ccd_vita25k_tb/pin_out_ccd.sck
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ps} 0}
quietly wave cursor active 0
configure wave -namecolwidth 150
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
WaveRestoreZoom {1997973 ps} {16736949 ps}

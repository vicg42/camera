## Delete existing libraries
file delete -force -- work

vlib work

vlog "c:/Xilinx/14.6/ISE_DS/ISE/verilog/src/glbl.v"

# compile all of the files
vcom -work work ../../../common/hw/lib/vicg/vicg_common_pkg.vhd
vcom -work work ../../../common/hw/lib/vicg/reduce_pack.vhd
vcom -work work ../../../common/hw/video/video_out/vga_gen.vhd
vcom -work work ../../src/clocks_pkg.vhd
vcom -work work ../../src/clocks.vhd
vcom -work work ../testbanch/vga_gen_tb.vhd

# run the simulation
vsim -t ps -L unisim work.vga_gen_tb
#do ccd_vita25K_tb_wave.do

run 1000ns



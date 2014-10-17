## Delete existing libraries
file delete -force -- work

vlib work

vlog "c:/Xilinx/14.6/ISE_DS/ISE/verilog/src/glbl.v"

# compile all of the files
vcom -work work ../../../../lib/common/hw/lib/vicg/reduce_pack.vhd
vcom -work work ../testbanch/prj_cfg_sim.vhd
vcom -work work ../../src/ccd_vita25K_pkg.vhd
#vcom -work work ../../src/ccd_vita25K.vhd
#vcom -work work ../../src/ccd_deser_clock_gen.vhd
vcom -work work ../../src/ccd_deser_clk.vhd
vcom -work work ../../src/ccd_deser2.vhd
vcom -work work ../testbanch/test_lvds_snd.vhd
vcom -work work ../testbanch/test_lvds_rcv.vhd
vcom -work work ../testbanch/test_lvds_tb.vhd

# run the simulation
vsim -c -t ps -voptargs="+acc" -L secureip -L unisim work.test_lvds_tb
do test_lvds_tb_wave.do
#log -r /*
run 100000ns



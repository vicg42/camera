## Delete existing libraries
file delete -force -- work

vlib work

vlog "c:/Xilinx/14.6/ISE_DS/ISE/verilog/src/glbl.v"

# compile all of the files
vcom -work work ../../../common/hw/lib/vicg/vicg_common_pkg.vhd
vcom -work work ../../../common/hw/lib/vicg/reduce_pack.vhd
vcom -work work ../../../common/hw/spi/spi_core_pkg.vhd
vcom -work work ../../../common/hw/spi/spi_core.vhd
vcom -work work ../../src/clocks_pkg.vhd
vcom -work work ../../src/clocks.vhd
vcom -work work ../testbanch/prj_cfg_sim.vhd
vcom -work work ../../src/ccd_vita25K_pkg.vhd
vcom -work work ../../src/ccd_vita25K.vhd
vcom -work work ../../src/ccd_deser_clock_gen.vhd
vcom -work work ../../src/ccd_deser.vhd
vcom -work work ../../src/ccd_spi.vhd
vcom -work work ../testbanch/ccd_vita25K_tb.vhd

# run the simulation
vsim -t ps -L unisim work.ccd_vita25K_tb
do ccd_vita25K_tb_wave.do

run 10000ns



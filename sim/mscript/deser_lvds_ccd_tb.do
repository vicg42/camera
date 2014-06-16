# set up the working directory
set work work
vlib work

# compile all of the files
vcom -work work ../testbanch/prj_cfg_sim.vhd
vcom -work work ../../src/ccd_vita25K_pkg.vhd
vcom -work work ../../src/ccd_vita25K.vhd
vcom -work work ../../src/ccd_deser_clock_gen.vhd
vcom -work work ../../src/ccd_deser.vhd
vcom -work work ../testbanch/deser_lvds_ccd_exdes.vhd
vcom -work work ../testbanch/deser_lvds_ccd_tb.vhd

# run the simulation
vsim -c -t ps -voptargs="+acc" -L secureip -L unisim work.deser_lvds_ccd_tb
do deser_lvds_ccd_tb_wave.do
#log -r /*
run 100000ns



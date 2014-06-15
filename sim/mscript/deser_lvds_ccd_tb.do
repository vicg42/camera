# set up the working directory
set work work
vlib work

# compile all of the files
vcom -work work ../../src/deser_clock_gen.vhd
vcom -work work ../../src/deser_lvds_ccd.vhd
#vcom -work work ../../ise/core_gen/deser_lvds_ccd.vhd
vcom -work work ../testbanch/deser_lvds_ccd_exdes.vhd
vcom -work work ../testbanch/deser_lvds_ccd_tb.vhd

# run the simulation
vsim -c -t ps -voptargs="+acc" -L secureip -L unisim work.deser_lvds_ccd_tb
do deser_lvds_ccd_tb_wave.do
#log -r /*
run 100000ns



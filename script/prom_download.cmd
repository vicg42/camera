setMode -pff
setSubmode -pffspi
setAttribute -configdevice -attr compressed -value "FALSE"
setAttribute -configdevice -attr multiboot -value "FALSE"
setAttribute -configdevice -attr dir -value "UP"
setAttribute -configdevice -attr spiSelected -value "TRUE"
addPromDevice -p 1 -size 32768 -name 32M
addDesign -version 0 -name 0
addDeviceChain -index 0
addDevice -p 1 -file d:\Work\Yansar\camera\firmware\test_tv_main.bit
generate -format mcs -fillvalue FF -output d:\Work\Yansar\camera\firmware\test_tv_main.mcs
setMode -bs
setCable -port auto
identify
attachflash -position 1 -spi "N25Q256"
assignfiletoattachedflash -position 1 -file "D:/Work/Yansar/camera/firmware/test_tv_main.mcs"
program -p 1 -dataWidth 4 -spionly -e -v -loadfpga
quit
setMode -pff
setSubmode -pffserial
setAttribute -configdevice -attr compressed -value "FALSE"
setAttribute -configdevice -attr multiboot -value "FALSE"
addPromDevice -p 1 -name xcf32p
addDesign -version 0 -name 0
addDeviceChain -index 0
addDevice -p 1 -file d:\Work\Yansar\camera\firmware\top.bit
generate -format mcs -fillvalue FF -output d:\Work\Yansar\camera\firmware\top.mcs
setMode -bs
setCable -port auto
identify
assignFile -p 1 -file d:\Work\Yansar\camera\firmware\top.mcs
setAttribute -position 1 -attr readnextdevice -value "(null)"
Program -p 1 -e
quit

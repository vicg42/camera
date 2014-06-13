source "../../common/script/projnav.tcl"
#file mkdir "../ise/prj
cd ../ise/prj

set _cwd [pwd]
puts "Currunt PATH ${_cwd}"

set _usrdef_design "camera"
set _usrdef_entity "camera_main"
set _usrdef_xilinx_family "kintex7"
set _usrdef_chip_family "k7t"
set _usrdef_device "7k410t"
set _usrdef_speed  2
set _usrdef_pkg    "fbg676"
set _usrdef_ucf_filename "camera_main"
set _usrdef_ucf_filepath "..\ucf\camera_main.ucf"

set _VMod $::projNav::VMod
set _VHDMod $::projNav::VHDMod
set _VHDPkg $::projNav::VHDPkg

set _projects [ list \
  [ list \
    $_usrdef_xilinx_family $_usrdef_device $_usrdef_pkg $_usrdef_speed xrc5t1 [ list \
      [ list "../../../common/hw/lib/vicg/vicg_common_pkg.vhd" $_VHDPkg ] \
      [ list "../src/camera_main.v" $_VHDMod ] \
      [ list "../../ucf/camera_main.ucf" "camera_main" ] \
    ] \
  ] \
]

::projNav::makeProjects $_cwd $_usrdef_design $_usrdef_entity $_projects 10

#cd ../src
#exec "updata_ngc.bat"

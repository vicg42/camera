source "../../../lib/common/script/projnav.tcl"
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
      [ list "../../../../lib/common/hw/lib/vicg/vicg_common_pkg.vhd" $_VHDPkg ] \
      [ list "../../../../lib/common/hw/lib/vicg/reduce_pack.vhd" $_VHDPkg ] \
      [ list "../../../../lib/common/hw/spi/spi_core_pkg.vhd" $_VHDPkg ] \
      [ list "../../../../lib/common/hw/spi/spi_core.vhd" $_VHDMod ] \
      [ list "../../../../lib/common/hw/video/video_out/vtest_gen.vhd" $_VHDMod ] \
      [ list "../../../../lib/common/hw/video/video_out/vga_gen.vhd" $_VHDMod ] \
      [ list "../../../../lib/common/hw/video/video_out/tv_gen.vhd" $_VHDMod ] \
      [ list "../../../../lib/common/hw/testing/fpga_test_01.vhd" $_VHDMod ] \
      [ list "../../../../lib/common/hw/timer/time_gen.vhd" $_VHDMod ] \
      [ list "../../../../lib/common/hw/testing/debounce.vhd" $_VHDMod ] \
      [ list "../../../../lib/common/hw/mem/mem_glob_pkg.vhd" $_VHDPkg ] \
      [ list "../../../../lib/common/hw/mem/xilinx/mem_wr_axi_pkg.vhd" $_VHDPkg ] \
      [ list "../../../../lib/common/hw/mem/xilinx/mem_wr_axi.vhd" $_VHDMod ] \
      [ list "../../src/mem_core/rtl/axi/mig_7series_v1_9_axi_ctrl_addr_decode.v" $_VMod ] \
      [ list "../../src/mem_core/rtl/axi/mig_7series_v1_9_axi_ctrl_read.v" $_VMod ] \
      [ list "../../src/mem_core/rtl/axi/mig_7series_v1_9_axi_ctrl_reg.v" $_VMod ] \
      [ list "../../src/mem_core/rtl/axi/mig_7series_v1_9_axi_ctrl_reg_bank.v" $_VMod ] \
      [ list "../../src/mem_core/rtl/axi/mig_7series_v1_9_axi_ctrl_top.v" $_VMod ] \
      [ list "../../src/mem_core/rtl/axi/mig_7series_v1_9_axi_ctrl_write.v" $_VMod ] \
      [ list "../../src/mem_core/rtl/axi/mig_7series_v1_9_axi_mc.v" $_VMod ] \
      [ list "../../src/mem_core/rtl/axi/mig_7series_v1_9_axi_mc_ar_channel.v" $_VMod ] \
      [ list "../../src/mem_core/rtl/axi/mig_7series_v1_9_axi_mc_aw_channel.v" $_VMod ] \
      [ list "../../src/mem_core/rtl/axi/mig_7series_v1_9_axi_mc_b_channel.v" $_VMod ] \
      [ list "../../src/mem_core/rtl/axi/mig_7series_v1_9_axi_mc_cmd_arbiter.v" $_VMod ] \
      [ list "../../src/mem_core/rtl/axi/mig_7series_v1_9_axi_mc_cmd_fsm.v" $_VMod ] \
      [ list "../../src/mem_core/rtl/axi/mig_7series_v1_9_axi_mc_cmd_translator.v" $_VMod ] \
      [ list "../../src/mem_core/rtl/axi/mig_7series_v1_9_axi_mc_incr_cmd.v" $_VMod ] \
      [ list "../../src/mem_core/rtl/axi/mig_7series_v1_9_axi_mc_r_channel.v" $_VMod ] \
      [ list "../../src/mem_core/rtl/axi/mig_7series_v1_9_axi_mc_simple_fifo.v" $_VMod ] \
      [ list "../../src/mem_core/rtl/axi/mig_7series_v1_9_axi_mc_w_channel.v" $_VMod ] \
      [ list "../../src/mem_core/rtl/axi/mig_7series_v1_9_axi_mc_wr_cmd_fsm.v" $_VMod ] \
      [ list "../../src/mem_core/rtl/axi/mig_7series_v1_9_axi_mc_wrap_cmd.v" $_VMod ] \
      [ list "../../src/mem_core/rtl/axi/mig_7series_v1_9_ddr_a_upsizer.v" $_VMod ] \
      [ list "../../src/mem_core/rtl/axi/mig_7series_v1_9_ddr_axi_register_slice.v" $_VMod ] \
      [ list "../../src/mem_core/rtl/axi/mig_7series_v1_9_ddr_axi_upsizer.v" $_VMod ] \
      [ list "../../src/mem_core/rtl/axi/mig_7series_v1_9_ddr_axic_register_slice.v" $_VMod ] \
      [ list "../../src/mem_core/rtl/axi/mig_7series_v1_9_ddr_carry_and.v" $_VMod ] \
      [ list "../../src/mem_core/rtl/axi/mig_7series_v1_9_ddr_carry_latch_and.v" $_VMod ] \
      [ list "../../src/mem_core/rtl/axi/mig_7series_v1_9_ddr_carry_latch_or.v" $_VMod ] \
      [ list "../../src/mem_core/rtl/axi/mig_7series_v1_9_ddr_carry_or.v" $_VMod ] \
      [ list "../../src/mem_core/rtl/axi/mig_7series_v1_9_ddr_command_fifo.v" $_VMod ] \
      [ list "../../src/mem_core/rtl/axi/mig_7series_v1_9_ddr_comparator.v" $_VMod ] \
      [ list "../../src/mem_core/rtl/axi/mig_7series_v1_9_ddr_comparator_sel.v" $_VMod ] \
      [ list "../../src/mem_core/rtl/axi/mig_7series_v1_9_ddr_comparator_sel_static.v" $_VMod ] \
      [ list "../../src/mem_core/rtl/axi/mig_7series_v1_9_ddr_r_upsizer.v" $_VMod ] \
      [ list "../../src/mem_core/rtl/axi/mig_7series_v1_9_ddr_w_upsizer.v" $_VMod ] \
      [ list "../../src/mem_core/rtl/clocking/mig_7series_v1_9_clk_ibuf.v" $_VMod ] \
      [ list "../../src/mem_core/rtl/clocking/mig_7series_v1_9_infrastructure.v" $_VMod ] \
      [ list "../../src/mem_core/rtl/clocking/mig_7series_v1_9_iodelay_ctrl.v" $_VMod ] \
      [ list "../../src/mem_core/rtl/clocking/mig_7series_v1_9_tempmon.v" $_VMod ] \
      [ list "../../src/mem_core/rtl/controller/mig_7series_v1_9_arb_mux.v" $_VMod ] \
      [ list "../../src/mem_core/rtl/controller/mig_7series_v1_9_arb_row_col.v" $_VMod ] \
      [ list "../../src/mem_core/rtl/controller/mig_7series_v1_9_arb_select.v" $_VMod ] \
      [ list "../../src/mem_core/rtl/controller/mig_7series_v1_9_bank_cntrl.v" $_VMod ] \
      [ list "../../src/mem_core/rtl/controller/mig_7series_v1_9_bank_common.v" $_VMod ] \
      [ list "../../src/mem_core/rtl/controller/mig_7series_v1_9_bank_compare.v" $_VMod ] \
      [ list "../../src/mem_core/rtl/controller/mig_7series_v1_9_bank_mach.v" $_VMod ] \
      [ list "../../src/mem_core/rtl/controller/mig_7series_v1_9_bank_queue.v" $_VMod ] \
      [ list "../../src/mem_core/rtl/controller/mig_7series_v1_9_bank_state.v" $_VMod ] \
      [ list "../../src/mem_core/rtl/controller/mig_7series_v1_9_col_mach.v" $_VMod ] \
      [ list "../../src/mem_core/rtl/controller/mig_7series_v1_9_mc.v" $_VMod ] \
      [ list "../../src/mem_core/rtl/controller/mig_7series_v1_9_rank_cntrl.v" $_VMod ] \
      [ list "../../src/mem_core/rtl/controller/mig_7series_v1_9_rank_common.v" $_VMod ] \
      [ list "../../src/mem_core/rtl/controller/mig_7series_v1_9_rank_mach.v" $_VMod ] \
      [ list "../../src/mem_core/rtl/controller/mig_7series_v1_9_round_robin_arb.v" $_VMod ] \
      [ list "../../src/mem_core/rtl/ecc/mig_7series_v1_9_ecc_buf.v" $_VMod ] \
      [ list "../../src/mem_core/rtl/ecc/mig_7series_v1_9_ecc_dec_fix.v" $_VMod ] \
      [ list "../../src/mem_core/rtl/ecc/mig_7series_v1_9_ecc_gen.v" $_VMod ] \
      [ list "../../src/mem_core/rtl/ecc/mig_7series_v1_9_ecc_merge_enc.v" $_VMod ] \
      [ list "../../src/mem_core/rtl/ip_top/mig_7series_v1_9_mem_intfc.v" $_VMod ] \
      [ list "../../src/mem_core/rtl/ip_top/mig_7series_v1_9_memc_ui_top_axi.v" $_VMod ] \
      [ list "../../src/mem_core/rtl/phy/mig_7series_v1_9_ddr_byte_group_io.v" $_VMod ] \
      [ list "../../src/mem_core/rtl/phy/mig_7series_v1_9_ddr_byte_lane.v" $_VMod ] \
      [ list "../../src/mem_core/rtl/phy/mig_7series_v1_9_ddr_calib_top.v" $_VMod ] \
      [ list "../../src/mem_core/rtl/phy/mig_7series_v1_9_ddr_if_post_fifo.v" $_VMod ] \
      [ list "../../src/mem_core/rtl/phy/mig_7series_v1_9_ddr_mc_phy.v" $_VMod ] \
      [ list "../../src/mem_core/rtl/phy/mig_7series_v1_9_ddr_mc_phy_wrapper.v" $_VMod ] \
      [ list "../../src/mem_core/rtl/phy/mig_7series_v1_9_ddr_of_pre_fifo.v" $_VMod ] \
      [ list "../../src/mem_core/rtl/phy/mig_7series_v1_9_ddr_phy_4lanes.v" $_VMod ] \
      [ list "../../src/mem_core/rtl/phy/mig_7series_v1_9_ddr_phy_ck_addr_cmd_delay.v" $_VMod ] \
      [ list "../../src/mem_core/rtl/phy/mig_7series_v1_9_ddr_phy_dqs_found_cal.v" $_VMod ] \
      [ list "../../src/mem_core/rtl/phy/mig_7series_v1_9_ddr_phy_dqs_found_cal_hr.v" $_VMod ] \
      [ list "../../src/mem_core/rtl/phy/mig_7series_v1_9_ddr_phy_init.v" $_VMod ] \
      [ list "../../src/mem_core/rtl/phy/mig_7series_v1_9_ddr_phy_oclkdelay_cal.v" $_VMod ] \
      [ list "../../src/mem_core/rtl/phy/mig_7series_v1_9_ddr_phy_prbs_rdlvl.v" $_VMod ] \
      [ list "../../src/mem_core/rtl/phy/mig_7series_v1_9_ddr_phy_rdlvl.v" $_VMod ] \
      [ list "../../src/mem_core/rtl/phy/mig_7series_v1_9_ddr_phy_tempmon.v" $_VMod ] \
      [ list "../../src/mem_core/rtl/phy/mig_7series_v1_9_ddr_phy_top.v" $_VMod ] \
      [ list "../../src/mem_core/rtl/phy/mig_7series_v1_9_ddr_phy_wrcal.v" $_VMod ] \
      [ list "../../src/mem_core/rtl/phy/mig_7series_v1_9_ddr_phy_wrlvl.v" $_VMod ] \
      [ list "../../src/mem_core/rtl/phy/mig_7series_v1_9_ddr_phy_wrlvl_off_delay.v" $_VMod ] \
      [ list "../../src/mem_core/rtl/phy/mig_7series_v1_9_ddr_prbs_gen.v" $_VMod ] \
      [ list "../../src/mem_core/rtl/ui/mig_7series_v1_9_ui_cmd.v" $_VMod ] \
      [ list "../../src/mem_core/rtl/ui/mig_7series_v1_9_ui_rd_data.v" $_VMod ] \
      [ list "../../src/mem_core/rtl/ui/mig_7series_v1_9_ui_top.v" $_VMod ] \
      [ list "../../src/mem_core/rtl/ui/mig_7series_v1_9_ui_wr_data.v" $_VMod ] \
      [ list "../../src/mem_core/rtl/mem_ctrl_core_axi.v" $_VMod ] \
      [ list "../../src/mem_ctrl_axi_pkg.vhd" $_VHDMod ] \
      [ list "../../src/mem_ctrl_axi.vhd" $_VHDMod ] \
      [ list "../../src/mem_arb.vhd" $_VHDMod ] \
      [ list "../core_gen/vbufi.vhd" $_VHDMod ] \
      [ list "../core_gen/vbufo.vhd" $_VHDMod ] \
      [ list "../core_gen/mem_achcount2_synth.vhd" $_VHDMod ] \
      [ list "../../src/dbg_pkg.vhd" $_VHDPkg ] \
      [ list "../../src/clocks.vhd" $_VHDMod ] \
      [ list "../../src/clocks_pkg.vhd" $_VHDPkg ] \
      [ list "../../src/ccd_vita25k_pkg.vhd" $_VHDPkg ] \
      [ list "../../src/ccd_vita25K.vhd" $_VHDMod ] \
      [ list "../../src/ccd_spi.vhd" $_VHDMod ] \
      [ list "../../src/ccd_fg.vhd" $_VHDMod ] \
      [ list "../../src/ccd_deser_clk.vhd" $_VHDMod ] \
      [ list "../../src/ccd_deser2.vhd" $_VHDMod ] \
      [ list "../../src/vout_pkg.vhd" $_VHDPkg ] \
      [ list "../../src/vout.vhd" $_VHDMod ] \
      [ list "../../src/video_ctrl_pkg.vhd" $_VHDPkg ] \
      [ list "../../src/video_ctrl.vhd" $_VHDMod ] \
      [ list "../../src/video_writer.vhd" $_VHDMod ] \
      [ list "../../src/video_reader.vhd" $_VHDMod ] \
      [ list "../../src/prj_cfg.vhd" $_VHDPkg ] \
      [ list "../../src/camera_main.vhd" $_VHDMod ] \
      [ list "../../ucf/camera_main.ucf" "camera_main" ] \
    ] \
  ] \
]

::projNav::makeProjects $_cwd $_usrdef_design $_usrdef_entity $_projects 10

#cd ../src
#exec "updata_ngc.bat"

# DigitalPilot · DC 源文件清单(配合教程的 dc.tcl/set_env.tcl 使用)
set DESIGN_NAME "$env(DP_DESIGN)"
set rtl_dir "./../0_simulation_pre/rtl"
set RTL_SOURCE_FILES " \
${rtl_dir}/${DESIGN_NAME}.v \
"

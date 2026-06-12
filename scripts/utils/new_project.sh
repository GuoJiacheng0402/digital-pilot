#!/bin/bash
# DigitalPilot · 一键创建教程目录结构的新项目工作区,并铺好各阶段脚本
# 用法: ./new_project.sh <项目目录> [设计名]
set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DP_ROOT="$(readlink -f "$SCRIPT_DIR/../..")"
PROJ=${1:?用法: $0 <项目目录> [设计名] [时钟端口名] [周期ns]}
DESIGN=${2:-my_design}
CLK_PORT=${3:-clk}
CLK_PERIOD=${4:-5.0}
HALF_PERIOD=$(awk "BEGIN{print ${CLK_PERIOD}/2}")
UNCERT_SETUP=${DP_UNCERT_SETUP:-1.0}
UNCERT_HOLD=${DP_UNCERT_HOLD:-0.3}
inst_tmpl() {  # 实例化模板占位符: inst_tmpl <in> <out>
  sed "s/__DESIGN__/${DESIGN}/g; s/__CLK_PORT__/${CLK_PORT}/g; \
       s/__CLK_PERIOD__/${CLK_PERIOD}/g; s/__HALF_PERIOD__/${HALF_PERIOD}/g; \
       s/__UNCERT_SETUP__/${UNCERT_SETUP}/g; s/__UNCERT_HOLD__/${UNCERT_HOLD}/g" "$1" > "$2"
}
mkdir -p "$PROJ"; PROJ=$(readlink -f "$PROJ")

mkdir -p "$PROJ"/{0_simulation_pre/{rtl,tb},1_dc/{tcl,output},2_formality_postdc/tcl,3_simulation_postdc/{rtl,tb},4_innovus/{tcl,work,postdc,postlayout,innovus_files,lef},5_DRC,5_LVS,6_formality_postlayout/tcl,7_StarRC/tcl,8_pt/{tcl,reports},9_simulation_postlayout/{rtl,tb}}

cp "$DP_ROOT/scripts/0_sim_rtl/makefile"      "$PROJ/0_simulation_pre/"
sed "s/DESIGN/${DESIGN}/g" "$DP_ROOT/scripts/0_sim_rtl/filelist.f" > "$PROJ/0_simulation_pre/filelist.f"
inst_tmpl "$DP_ROOT/scripts/1_dc/top.sdc"     "$PROJ/1_dc/tcl/top.sdc"
cp "$DP_ROOT/scripts/1_dc/define.tcl"         "$PROJ/1_dc/tcl/"
cp "$DP_ROOT/scripts/3_sim_postdc/makefile"   "$PROJ/3_simulation_postdc/"
inst_tmpl "$DP_ROOT/scripts/4_innovus/run_innovus.tcl" "$PROJ/4_innovus/tcl/run_innovus.tcl"
cp "$DP_ROOT/scripts/4_innovus/eco_hold_fix.tcl" "$PROJ/4_innovus/tcl/"
sed "s/__DESIGN__/${DESIGN}/g" "$DP_ROOT/scripts/4_innovus/mmmc_wst.view" > "$PROJ/4_innovus/innovus_files/mmmc.view"
cp "$DP_ROOT/scripts/7_starrc/run_3corner.sh" "$PROJ/7_StarRC/"
cp "$DP_ROOT/scripts/7_starrc/starrc_spef.tcl.tmpl" "$PROJ/7_StarRC/"
inst_tmpl "$DP_ROOT/scripts/8_pt/top.sdc"     "$PROJ/8_pt/tcl/top.sdc"
cp "$DP_ROOT/scripts/8_pt/run_3corner.sh"     "$PROJ/8_pt/"
cp "$DP_ROOT/scripts/1_dc/dc.tcl"             "$PROJ/1_dc/tcl/"
cp "$DP_ROOT/scripts/1_dc/set_env.tcl"        "$PROJ/1_dc/tcl/"
cp "$DP_ROOT/scripts/1_dc/dont_use_cell.tcl"  "$PROJ/1_dc/tcl/"
cp "$DP_ROOT/scripts/1_dc/run.sh"             "$PROJ/1_dc/"
sed "s/DESIGN/${DESIGN}/g" "$DP_ROOT/scripts/0_sim_rtl/tb_template.v" > "$PROJ/0_simulation_pre/tb/tb_${DESIGN}.v"
cp "$DP_ROOT/scripts/2_formality/fm.tcl"      "$PROJ/2_formality_postdc/tcl/"
cp "$DP_ROOT/scripts/2_formality/fm.tcl"      "$PROJ/6_formality_postlayout/tcl/"
cp "$DP_ROOT/scripts/2_formality/run.sh"      "$PROJ/2_formality_postdc/"
cp "$DP_ROOT/scripts/2_formality/run.sh"      "$PROJ/6_formality_postlayout/"
sed "s/__DESIGN__/${DESIGN}/g" "$DP_ROOT/scripts/2_formality/dc_setup_postdc.tcl.tmpl"      > "$PROJ/2_formality_postdc/tcl/dc_setup.tcl"
sed "s/__DESIGN__/${DESIGN}/g" "$DP_ROOT/scripts/2_formality/dc_setup_postlayout.tcl.tmpl" > "$PROJ/6_formality_postlayout/tcl/dc_setup.tcl"
cp "$DP_ROOT/scripts/4_innovus/mystreamOut.map" "$PROJ/4_innovus/innovus_files/"
cp "$DP_ROOT/scripts/7_starrc/StarRC_mapfile.map" "$PROJ/7_StarRC/"
cp "$DP_ROOT/scripts/8_pt/pt_corner.tcl.tmpl" "$PROJ/8_pt/"
cp "$DP_ROOT/scripts/8_pt/setenv.tcl.tmpl"    "$PROJ/8_pt/"
cp "$DP_ROOT/scripts/8_pt/run.sh"             "$PROJ/8_pt/"
cp "$DP_ROOT/scripts/9_sim_postlayout/makefile" "$PROJ/9_simulation_postlayout/"
cp "$DP_ROOT/scripts/9_sim_postlayout/run_corner.sh" "$PROJ/9_simulation_postlayout/"

cat > "$PROJ/dp_env.sh" <<ENVEOF
# source 本文件进入项目环境
export DP_ROOT="$DP_ROOT"
export DP_DESIGN=${DESIGN}
source "$DP_ROOT/scripts/00_env/config.sh"
ENVEOF

echo "[DigitalPilot] 项目已创建: $PROJ (设计=$DESIGN 时钟=$CLK_PORT 周期=${CLK_PERIOD}ns)"
echo "下一步:"
echo "  1. 把 RTL 放进 $PROJ/0_simulation_pre/rtl/,tb 放进 tb/"
echo "  2. source $PROJ/dp_env.sh"
echo "  3. 按 docs/00_overview.md 逐阶段执行"

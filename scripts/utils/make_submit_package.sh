#!/bin/bash
# DigitalPilot · 按教程 §1.7 最小清单打提交包
# 用法: ./make_submit_package.sh <项目目录> <输出.zip>
set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../00_env/config.sh"
PROJ=${1:?用法: $0 <项目目录> <输出.zip>}; OUT=${2:?}
PROJ=$(readlink -f "$PROJ"); D=$DP_DESIGN
ST=$(mktemp -d)/pkg/$(basename "$PROJ"); mkdir -p "$ST"
copy(){ mkdir -p "$ST/$(dirname "$1")"; cp "$PROJ/$1" "$ST/$1" 2>/dev/null || echo "  缺: $1"; }
for f in \
  0_simulation_pre/rtl/${D}.v 0_simulation_pre/tb/tb_${D}.v \
  1_dc/output/${D}.v 1_dc/output/${D}.area.rpt 1_dc/output/${D}.power.rpt \
  1_dc/output/${D}.timing.rpt 1_dc/tcl/top.sdc \
  2_formality_postdc/fm.log \
  4_innovus/postlayout/${D}.v 4_innovus/work/my_cmd.cmd \
  5_LVS/${D}.lvs.report \
  6_formality_postlayout/fm.log \
  8_pt/reports/bst_report_analysis_coverage.report \
  8_pt/reports/typ_report_analysis_coverage.report \
  8_pt/reports/wst_report_analysis_coverage.report \
  8_pt/tcl/top.sdc ; do copy "$f"; done
( cd "$(dirname "$ST")" && zip -rq "$OLDPWD/$OUT" "$(basename "$ST")" )
echo "打包完成: $OUT"; unzip -l "$OUT" | tail -3

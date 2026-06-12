#!/bin/bash
# DigitalPilot · 三角后仿一键切角:./run_corner.sh wst|typ|bst
# 假设 rtl/ 下有 ${DESIGN}_{wst,typ,bst}.sdf(来自 8_pt 的 write_sdf),
# tb 的 $sdf_annotate 行含 "_xxx.sdf" 模式。日志存为 run_<corner>.log。
set -e
C=${1:?用法: $0 wst|typ|bst}
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# 鲁棒定位 config.sh:仓库内相对路径 → 项目 dp_env.sh 已 source → DP_ROOT → 默认安装位
if ! type dp_info >/dev/null 2>&1; then
    for _c in "$SCRIPT_DIR/../00_env/config.sh" \
              "${DP_ROOT:-}/scripts/00_env/config.sh" \
              "$HOME/DigitalPilot/scripts/00_env/config.sh"; do
        [ -f "$_c" ] && source "$_c" && break
    done
fi
type dp_info >/dev/null 2>&1 || { echo "ERROR: 找不到 config.sh —— 先 source 项目的 dp_env.sh,或 export DP_ROOT=<DigitalPilot路径>"; exit 1; }
sed -i "s/_\(wst\|typ\|bst\)\.sdf/_${C}.sdf/" tb/tb_*.v
grep sdf_annotate tb/tb_*.v
make run_vcs
cp run.log run_${C}.log; cp sdf.log sdf_${C}.log 2>/dev/null || true
grep -hE "PASS|FAIL" run_${C}.log | tail -1
grep -h "Total errors" sdf_${C}.log | tail -1

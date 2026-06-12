#!/bin/bash
# DigitalPilot · 三角寄生提取:wst(-40C)/typ(25C)/bst(125C) 各出一份 SPEF
set -e
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
dp_source_synopsys
command -v StarXtract >/dev/null || dp_die "StarXtract 不在 PATH"
mkdir -p reports_spef tcl
declare -A TEMP=( [wst]=-40 [typ]=25 [bst]=125 )
for c in wst typ bst; do
    sed "s/__DESIGN__/${DP_DESIGN}/g; s/__CORNER__/${c}/g; s/__TEMP__/${TEMP[$c]}/g" \
        "$SCRIPT_DIR/starrc_spef.tcl.tmpl" > tcl/starrc_${c}_spef.tcl
    mkdir -p reports_spef/starrc_${c}
    dp_info "StarXtract $c ..."
    StarXtract -clean tcl/starrc_${c}_spef.tcl | tee starrc_${c}.log | tail -2
done
ls -la reports_spef/*.spef

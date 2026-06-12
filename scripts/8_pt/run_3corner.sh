#!/bin/bash
# DigitalPilot · PrimeTime 三角签核(自动从模板实例化 wst/typ/bst 并依次执行)
# 判定: reports/<c>_report_analysis_coverage.report 三角 All Checks 全 0 violated
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
command -v pt_shell >/dev/null || dp_die "pt_shell 不在 PATH(source bashrc_synopsys)"
mkdir -p reports log tcl

# setenv.tcl(网表路径/设计名)
[ -f tcl/setenv.tcl ] || sed "s/__DESIGN__/${DP_DESIGN}/g" "$SCRIPT_DIR/setenv.tcl.tmpl" > tcl/setenv.tcl
[ -f tcl/top.sdc ]    || sed "s/__CLK_PORT__/clk/g; s/__CLK_PERIOD__/${DP_CLK_PERIOD}/g; \
    s/__HALF_PERIOD__/$(awk "BEGIN{print ${DP_CLK_PERIOD}/2}")/g; \
    s/__UNCERT_SETUP__/${DP_UNCERT_SETUP}/g; s/__UNCERT_HOLD__/${DP_UNCERT_HOLD}/g" \
    "$SCRIPT_DIR/top.sdc" > tcl/top.sdc

declare -A DB=( [wst]="scx_csm_18ic_ss_1p62v_125c.db" \
                [typ]="scx_csm_18ic_tt_1p8v_25c.db" \
                [bst]="scx_csm_18ic_ff_1p98v_m40c.db" )
for c in wst typ bst; do
    sed "s|__CORNER_DB__|${DB[$c]}|; s/__CORNER__/${c}/g; s/__DESIGN__/${DP_DESIGN}/g" \
        "$SCRIPT_DIR/pt_corner.tcl.tmpl" > tcl/pt_${c}.tcl
    dp_info "PT ${c} ..."
    pt_shell -f tcl/pt_${c}.tcl > log/pt_${c}.log 2>&1 || true
    printf '%s: ' $c
    grep -h "All Checks" reports/${c}_report_analysis_coverage.report 2>/dev/null \
        || echo "FAILED → log/pt_${c}.log"
done

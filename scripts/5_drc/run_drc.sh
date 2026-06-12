#!/bin/bash
# =============================================================================
# run_drc.sh —— Calibre DRC 一键批处理(主 GDS + 标准单元参考 GDS)
#
# 前置: ./gen_stdcell_refs.sh <主GDS> <ref目录>   # 先把空壳标准单元补上
# 用法: ./run_drc.sh <主GDS> <stdcell_ref目录> [运行目录]
# 判定: summary 中 "TOTAL DRC Results Generated: 0 (0)" = 干净;
#       只剩 density 类问题也算可接受(教程原话),修法见 docs/06_calibre_drc.md
# =============================================================================
set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../00_env/config.sh"

GDS=${1:?用法: $0 <主GDS> <stdcell_ref目录> [运行目录]}
REF_DIR=${2:?}; RUN=${3:-./calibre_drc_run}
GDS=$(readlink -f "$GDS"); REF_DIR=$(readlink -f "$REF_DIR")
mkdir -p "$RUN"; RUN=$(readlink -f "$RUN")

# DRC 环境(TECHDIR=GF018_Technology_Files_iso + Rev6 deck 由 env 变量驱动)
dp_source_mentor
source "$DP_ENV_DRC" || dp_die "DRC env source 失败: $DP_ENV_DRC"
command -v calibre >/dev/null || dp_die "calibre 不在 PATH"

REF_GDS_LIST=$(ls "$REF_DIR"/*.gds 2>/dev/null | sed 's/^/"/; s/$/"/' | tr '\n' ' ')
[ -n "$REF_GDS_LIST" ] || dp_die "stdcell_ref 目录里没有 GDS(先跑 gen_stdcell_refs.sh)"

cat > "$RUN/${DP_DESIGN}_drc.svrf" <<EOF
// DigitalPilot 自动生成的 DRC 控制文件
LAYOUT PATH  "$GDS" $REF_GDS_LIST
LAYOUT PRIMARY "$DP_DESIGN"
LAYOUT SYSTEM GDSII
PRECISION 2000
DRC RESULTS DATABASE "${DP_DESIGN}.drc.results" ASCII
DRC SUMMARY REPORT "${DP_DESIGN}.drc.summary" REPLACE HIER
DRC MAXIMUM RESULTS ALL

INCLUDE "$DP_DRC_DECK"
EOF

dp_info "calibre -drc -hier 运行中(约 2-5 分钟)..."
( cd "$RUN" && calibre -drc -hier -64 "${DP_DESIGN}_drc.svrf" > drc_run.log 2>&1 ) || true

SUM="$RUN/${DP_DESIGN}.drc.summary"
[ -f "$SUM" ] || dp_die "没有生成 summary,见 $RUN/drc_run.log(常见:cell undefined → 参考 GDS 不全)"
echo "--------------------------------------------------"
grep -E "TOTAL DRC RuleChecks|TOTAL DRC Results Generated" "$SUM"
echo "--------------------------------------------------"
if grep -q "TOTAL DRC Results Generated:     0" "$SUM"; then
    dp_info "DRC 干净 ✔"
else
    dp_info "存在违例,逐条规则计数:"
    grep -B1 -A0 "TOTAL Result Count" "$SUM" | grep -vE "^--|TOTAL Result Count = 0" | head -20
    echo "  修法速查: density→补 fill;CO.6b 等点状违例→gdstk 打 patch;见 docs/06_calibre_drc.md"
fi

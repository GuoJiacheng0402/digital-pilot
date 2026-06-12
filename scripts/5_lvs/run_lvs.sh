#!/bin/bash
# =============================================================================
# run_lvs.sh —— Calibre LVS 一键批处理(组装 ctl → calibre -lvs -hier)
#
# 前置(按顺序,各自只需跑一次,ECO 后需重跑 1 和 2):
#   1) ../5_drc/gen_stdcell_refs.sh <主GDS> <ref目录>     # 标准单元参考 GDS
#   2) ./gen_src_netlist.sh <innovus网表.v> <src目录>     # SPICE 源网表
#   3) ./add_power_labels.py --gds 主GDS --def 主DEF --out 带标签GDS
#
# 用法: ./run_lvs.sh <带标签GDS> <源网表.src.net> <stdcell_ref目录> [运行目录]
# 判定: 报告出现 "CELL COMPARISON RESULTS ( TOP LEVEL ) ... CORRECT" 即通过
# =============================================================================
set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../00_env/config.sh"

GDS=${1:?用法: $0 <带标签GDS> <源网表> <stdcell_ref目录> [运行目录]}
SRC=${2:?}; REF_DIR=${3:?}; RUN=${4:-./calibre_lvs_run}
GDS=$(readlink -f "$GDS"); SRC=$(readlink -f "$SRC"); REF_DIR=$(readlink -f "$REF_DIR")
mkdir -p "$RUN"; RUN=$(readlink -f "$RUN")

# LVS 环境(注意:与 DRC 环境 TECHDIR 不同,不要混在同一 shell 里)
dp_source_mentor
source "$DP_ENV_LVS" || dp_die "LVS env source 失败: $DP_ENV_LVS"
command -v calibre >/dev/null || dp_die "calibre 不在 PATH"

REF_GDS_LIST=$(ls "$REF_DIR"/*.gds 2>/dev/null | sed 's/^/"/; s/$/"/' | tr '\n' ' ')
[ -n "$REF_GDS_LIST" ] || dp_die "stdcell_ref 目录里没有 GDS: $REF_DIR"

cat > "$RUN/${DP_DESIGN}_lvs.ctl" <<EOF
// DigitalPilot 自动生成的 LVS 控制文件
LAYOUT PATH  "$GDS" $REF_GDS_LIST
LAYOUT PRIMARY "$DP_DESIGN"
LAYOUT SYSTEM GDSII

SOURCE PATH "$SRC"
SOURCE PRIMARY "$DP_DESIGN"
SOURCE SYSTEM SPICE

MASK SVDB DIRECTORY "svdb_${DP_DESIGN}" QUERY
LVS REPORT "${DP_DESIGN}.lvs.report"
LVS REPORT OPTION NONE
LVS FILTER UNUSED OPTION AB RC SOURCE
LVS FILTER UNUSED OPTION AB RC LAYOUT
LVS REPORT MAXIMUM 50
LVS RECOGNIZE GATES ALL
LVS ABORT ON SOFTCHK NO
LVS ABORT ON SUPPLY ERROR YES
LVS IGNORE PORTS NO
LVS ISOLATE SHORTS NO
VIRTUAL CONNECT COLON NO
VIRTUAL CONNECT REPORT NO

LVS EXECUTE ERC YES
ERC RESULTS DATABASE "${DP_DESIGN}.erc.results"
ERC SUMMARY REPORT "${DP_DESIGN}.erc.summary" REPLACE HIER
ERC MAXIMUM RESULTS 1000

DRC ICSTATION YES

// 工艺 LVS deck(precision 已自动修正为 2000,匹配 Innovus GDS;原 deck 为 1000)
INCLUDE "$RUN/deck_precision2000.lvs.ctl"
EOF

# 工艺 deck 的 PRECISION 1000 与 Innovus GDS 的 dbuPerUU 2000 不一致会直接报错:
#   "Rule file precision 1000 is not consistent with database precision 2000"
# 解法与原型项目一致:复制 deck 并仅改 PRECISION(实测 diff 仅此一处)。
sed -E 's/^([[:space:]]*PRECISION[[:space:]]+)1000/\12000/' "$DP_LVS_DECK" > "$RUN/deck_precision2000.lvs.ctl"
grep -m1 -n "^PRECISION" "$RUN/deck_precision2000.lvs.ctl" || dp_die "deck 里没找到 PRECISION 行,人工核查 $DP_LVS_DECK"

dp_info "calibre -lvs -hier 运行中..."
( cd "$RUN" && calibre -lvs -hier "${DP_DESIGN}_lvs.ctl" > lvs_run.log 2>&1 ) || true

RPT="$RUN/${DP_DESIGN}.lvs.report"
[ -s "$RPT" ] || { echo "--- calibre 报错(lvs_run.log 末 15 行) ---"; tail -15 "$RUN/lvs_run.log"; dp_die "报告为空,calibre 未跑完"; }
echo "--------------------------------------------------"
grep -E "CORRECT|INCORRECT" "$RPT" | head -4
grep -E "^ Ports:|^ Nets:|^ Total Inst" "$RPT" | head -6
echo "--------------------------------------------------"
if ! grep -q "CORRECT" "$RPT" || grep -q "INCORRECT" "$RPT"; then
    dp_info "INCORRECT —— 高频原因排查(详见 docs/07_calibre_lvs.md):"
    echo "  1) missing port VDD!/VSS!  → 没用带标签 GDS,或标签层错(应 34/10)"
    echo "  2) 电源短路/大量不匹配      → VDD!/VSS! 标反(add_power_labels.py 不会,手工才会)"
    echo "  3) cell 黑盒/property error → stdcell_ref 没覆盖(ECO 后重跑 gen_stdcell_refs.sh)"
    echo "  4) 源网表过期              → ECO 后必须重跑 gen_src_netlist.sh"
    exit 1
fi
dp_info "LVS CORRECT ✔  报告: $RPT"

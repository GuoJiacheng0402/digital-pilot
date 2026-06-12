#!/bin/bash
# =============================================================================
# gen_stdcell_refs.sh —— 自动生成"标准单元参考 GDS"(DRC/LVS 的关键前置)
#
# 背景(教程没讲的黑盒):
#   Innovus streamOut 的 GDS 只含顶层布线和 via 结构,标准单元(BUFX2/DFFHQX1...)
#   只是"被引用的名字",没有物理几何。直接喂给 Calibre 会报:
#       ERROR: Cell XXX is referenced but not defined.
#   解法:从 csm19ic(标准单元 layout 库)用 Virtuoso XStream Out(strmout)把
#   设计实际用到的那些 cell 的 layout 批量导出成一个参考 GDS,DRC/LVS 时与主 GDS
#   一起挂在 LAYOUT PATH 上,Calibre 按 structure 名自动拼合。
#
# 本脚本自动化全过程:
#   1) 用零依赖 gds_tool.py 扫主 GDS,找出"被引用但未定义"的 structure(精确,无遗漏);
#   2) 过滤出 csm19ic 库里存在 layout 的 cell;
#   3) 在 cds.lib 可见 csm19ic 的目录下调用 strmout 批量导出;
#   4) 校验导出 GDS 覆盖了全部缺失 cell。
#
# 用法:
#   ./gen_stdcell_refs.sh <主GDS路径> <输出目录>
#   例: ./gen_stdcell_refs.sh ../4_innovus/postlayout/function_gen.gds ./stdcell_ref
#
# ECO 之后注意:ECO 可能插入新 cell 类型(DLY*/BUFXL 等),重跑本脚本即可,
#   它总是按"当前主 GDS 实际缺什么"导出,天然覆盖 ECO 增量。
# =============================================================================
set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../00_env/config.sh"

MAIN_GDS=${1:?用法: $0 <主GDS> <输出目录>}
OUT_DIR=${2:?用法: $0 <主GDS> <输出目录>}
MAIN_GDS=$(readlink -f "$MAIN_GDS")
mkdir -p "$OUT_DIR" && OUT_DIR=$(readlink -f "$OUT_DIR")
OUT_GDS=$OUT_DIR/${DP_OA_STDCELL_LAY}_refs_physical.gds

# ---- 1) 扫描主 GDS:被引用但未定义的 structure(零依赖,服务器原生 python3) ----
GDS_TOOL="$SCRIPT_DIR/../utils/gds_tool.py"
dp_info "扫描 $MAIN_GDS 中缺失的标准单元..."
dp_python "$GDS_TOOL" scan-missing "$MAIN_GDS" > "$OUT_DIR/missing_cells.txt"
grep -v '^#' "$OUT_DIR/missing_cells.txt" > "$OUT_DIR/missing_cells.txt.tmp" && \
    mv "$OUT_DIR/missing_cells.txt.tmp" "$OUT_DIR/missing_cells.txt"

N_MISS=$(grep -c . "$OUT_DIR/missing_cells.txt" || true)
[ "$N_MISS" -gt 0 ] || { dp_info "主 GDS 不缺任何 cell,无需参考 GDS。"; exit 0; }
dp_info "缺失 $N_MISS 个 cell,清单: $OUT_DIR/missing_cells.txt"

# ---- 2) 准备 strmout 运行环境(cds.lib 必须能解析 csm19ic) ----
dp_source_cds
command -v strmout >/dev/null || dp_die "strmout 不在 PATH,确认已 source $DP_ENV_CDS"
RUN_DIR=$OUT_DIR/strmout_run && mkdir -p "$RUN_DIR"
cat > "$RUN_DIR/cds.lib" <<EOF
DEFINE ${DP_OA_STDCELL_LAY} ${DP_OA_PDK_DIR}/${DP_OA_STDCELL_LAY}
DEFINE ${DP_OA_TECHLIB} ${DP_OA_PDK_DIR}/${DP_OA_TECHLIB}
EOF

# ---- 3) layer map(csm19ic OA 层 → GDS 层;与工艺 stream map 对齐) ----
# 若仓库已带 map 文件则直接用;否则提示从参考实现复制
MAP_FILE=$SCRIPT_DIR/csm19ic_physical_stream.map
[ -f "$MAP_FILE" ] || dp_die "缺 layer map: $MAP_FILE(随仓库分发,勿删)"
cp "$MAP_FILE" "$RUN_DIR/"

# ---- 4) strmout 批量导出 ----
#   -dbuPerUU 2000 : 必须与 Innovus streamOut 的 Units(2000)一致,否则坐标错位
#   -case Preserve : 保持大小写,structure 名必须与主 GDS 引用完全一致
TOPCELLS=$(paste -sd, "$OUT_DIR/missing_cells.txt")
dp_info "strmout 导出 ${DP_OA_STDCELL_LAY} 库 layout → $OUT_GDS"
( cd "$RUN_DIR" && strmout \
    -library "$DP_OA_STDCELL_LAY" \
    -strmFile "$OUT_GDS" \
    -topCell "$TOPCELLS" \
    -view layout \
    -runDir "$RUN_DIR" \
    -logFile "$RUN_DIR/strmout.log" \
    -summaryFile "$RUN_DIR/strmout.summary" \
    -dbuPerUU 2000 \
    -layerMap "$RUN_DIR/csm19ic_physical_stream.map" \
    -case Preserve \
    -convertDot node )

# ---- 5) 校验:导出的 GDS 必须覆盖全部缺失 cell ----
dp_python "$GDS_TOOL" list-cells "$OUT_GDS" | sort > "$OUT_DIR/exported_cells.txt"
LACK=$(comm -23 <(sort "$OUT_DIR/missing_cells.txt") "$OUT_DIR/exported_cells.txt" | head -20)
if [ -n "$LACK" ]; then
    dp_die "参考 GDS 仍缺 cell(csm19ic 可能没有其 layout,需 setDontUse 后重新 ECO): $LACK"
fi
dp_info "OK: 参考 GDS 覆盖全部 $N_MISS 个缺失 cell(structure 总数 $(wc -l < "$OUT_DIR/exported_cells.txt"),含 pcell 子结构)"

dp_info "完成。Calibre 里这样用(svrf/ctl):"
echo "  LAYOUT PATH \"$MAIN_GDS\" \"$OUT_GDS\""
echo "  LAYOUT PRIMARY \"$DP_DESIGN\""

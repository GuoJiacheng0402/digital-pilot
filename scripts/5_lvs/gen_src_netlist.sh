#!/bin/bash
# =============================================================================
# gen_src_netlist.sh —— 从 Innovus 门级网表批处理生成 LVS 源网表(SPICE/CDL)
#
# 教程的 GUI 路径是:Virtuoso → File→Import→Verilog → 再导出 CDL,全程点鼠标。
# 本脚本是它的全自动等价物,三步工具链(全部命令行,可复现):
#   1) verilog2oa : Verilog 网表 → OA netlist cellview(引用 csm18ic 的 symbol)
#   2) conn2sch   : netlist view → schematic view(自动摆原理图)
#   3) si -batch  : schematic → CDL 源网表(auCdl 风格,Calibre LVS 直接可用)
#
# 关键经验:
#   - refLibs 用 csm18ic(有 symbol/schematic);csm19ic 是 layout 库,这里用不到
#   - 不要用 -tieHigh VDD!/-tieLow VSS!:"!" 转义会失败;电源连接交给
#     GDS 侧的 power label(见 add_power_labels.py)
#   - ECO 之后网表变了,必须重跑本脚本——源网表与 GDS 版本不一致是 LVS
#     INCORRECT 的高频原因
#
# 用法: ./gen_src_netlist.sh <innovus网表.v> <输出目录>
#   例: ./gen_src_netlist.sh ../4_innovus/postlayout/function_gen.v ./lvs_src
# =============================================================================
set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../00_env/config.sh"

VLOG=${1:?用法: $0 <innovus网表.v> <输出目录>}
OUT=${2:?用法: $0 <innovus网表.v> <输出目录>}
VLOG=$(readlink -f "$VLOG"); mkdir -p "$OUT"; OUT=$(readlink -f "$OUT")
OA_DIR=$OUT/oa_batch; NET_DIR=$OUT/netlist_run
mkdir -p "$OA_DIR" "$NET_DIR"

dp_source_cds
command -v verilog2oa >/dev/null || dp_die "verilog2oa 不在 PATH(source $DP_ENV_CDS)"

# cds.lib:让批处理认识 PDK 各库
cat > "$OA_DIR/cds.lib" <<EOF
DEFINE ${DP_OA_STDCELL_SCH} ${DP_OA_PDK_DIR}/${DP_OA_STDCELL_SCH}
DEFINE ${DP_OA_STDCELL_LAY} ${DP_OA_PDK_DIR}/${DP_OA_STDCELL_LAY}
DEFINE ${DP_OA_TECHLIB} ${DP_OA_PDK_DIR}/${DP_OA_TECHLIB}
DEFINE lib_verilogin ${OA_DIR}/lib_verilogin
EOF

dp_info "[1/3] verilog2oa: $VLOG → OA netlist view"
verilog2oa -lib lib_verilogin -libDefFile "$OA_DIR/cds.lib" \
    -libPath "$OA_DIR/lib_verilogin" -overwrite \
    -refLibs "$DP_OA_STDCELL_SCH" -refViews "symbol schematic" \
    -verilog "$VLOG" -blackBox -tolerate \
    -top "$DP_DESIGN" -view netlist -viewType netlist \
    -logFile "$OA_DIR/verilog2oa.log"
grep -q "0 errors" "$OA_DIR/verilog2oa.log" || dp_die "verilog2oa 有 error,见 $OA_DIR/verilog2oa.log"

dp_info "[2/3] conn2sch: netlist → schematic"
conn2sch -lib lib_verilogin -cell "$DP_DESIGN" -view netlist \
    -destlib lib_verilogin -destview schematic \
    -cdslib "$OA_DIR/cds.lib" -log "$OA_DIR/conn2sch.log" -verbose
grep -qi "Generated sheet" "$OA_DIR/conn2sch.log" || dp_die "conn2sch 失败,见 $OA_DIR/conn2sch.log"

dp_info "[3/3] si -batch: schematic → CDL 源网表"
cp "$SCRIPT_DIR/si.env" "$NET_DIR/si.env"
# si.env 是 auCdl netlister 配置(simViewList/simStopList 等),模板随仓库分发
( cd "$NET_DIR" && \
  sed -i "s/__DESIGN__/${DP_DESIGN}/g; s/__LIB__/lib_verilogin/g" si.env && \
  si . -batch -command netlist -cdslib "$OA_DIR/cds.lib" > si_batch.log 2>&1 ) || true

SRC=$(find "$NET_DIR" -name "*.src.net" | head -1)
[ -n "$SRC" ] || dp_die "未生成 .src.net,检查 $NET_DIR/si_batch.log"
cp "$SRC" "$OUT/${DP_DESIGN}.src.net"
dp_info "完成: $OUT/${DP_DESIGN}.src.net ($(wc -l < "$OUT/${DP_DESIGN}.src.net") 行)"
head -3 "$OUT/${DP_DESIGN}.src.net"

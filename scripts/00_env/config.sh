#!/bin/bash
# =============================================================================
# DigitalPilot 全局配置 —— 所有阶段脚本 source 本文件
# 默认值按微电子学院国际校区服务器(/SM01)写好,换环境只改这一个文件。
# =============================================================================

# ---- 设计名(每个项目改这里) ----
export DP_DESIGN=${DP_DESIGN:?请先 export DP_DESIGN=<你的设计名>(或 source 项目的 dp_env.sh)}

# ---- EDA 环境 source 文件 ----
export DP_ENV_SYNOPSYS=/SM01/eda/env_set/bashrc_synopsys   # VCS/DC/Formality/StarRC/PT
export DP_ENV_CDS=/SM01/eda/env_set/bashrc_cds             # Virtuoso/Innovus/strmout/verilog2oa
export DP_ENV_MENTOR=/SM01/eda/env_set/bashrc_mentor       # Calibre

# ---- Calibre 规则环境(DRC 与 LVS 的 TECHDIR 不同,不能混 source!) ----
export DP_ENV_DRC=/SM01/teaching/bs/digitalic/calibre_env/gb018_Source_File_drc_env
# LVS 环境必须用修改版(MIMCAP_SELECTION=2p0fF_OPT_B 等;教学区原版会配错 deck)。
# 修改版随仓库分发,默认即用之;字段含义见 docs/07_calibre_lvs.md
DP_ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
export DP_ENV_LVS=${DP_ENV_LVS:-$DP_ROOT_DIR/scripts/5_lvs/gb018_Source_File_lvs_env}

# ---- 工艺库 ----
export DP_LIB_DIR=/SM01/teaching/bs/digitalic/gb18_dc_lib
export DP_LIB_TT=${DP_LIB_DIR}/scx_csm_18ic_tt_1p8v_25c.lib    # typ
export DP_LIB_SS=${DP_LIB_DIR}/scx_csm_18ic_ss_1p62v_125c.lib  # wst (setup 最难)
export DP_LIB_FF=${DP_LIB_DIR}/scx_csm_18ic_ff_1p98v_m40c.lib  # bst (hold 最难)
export DP_DB_TT=${DP_LIB_DIR}/scx_csm_18ic_tt_1p8v_25c.db
export DP_VLOG_MODEL=${DP_LIB_DIR}/csm18ic.v                   # 标准单元 Verilog 模型(GLS 用)

# ---- OA 库(Virtuoso/Calibre 用) ----
export DP_OA_PDK_DIR=/SM01/teaching/bs/digitalic/IC_ISO_1P6M_2K_2p0fF_B_30K
export DP_OA_TECHLIB=chrt018ull_hv30v   # 工艺库(attach 用)
export DP_OA_STDCELL_SCH=csm18ic        # 标准单元 schematic/symbol(LVS 源网表用)
export DP_OA_STDCELL_LAY=csm19ic        # 标准单元 layout(DRC/LVS 参考 GDS 用)★

# ---- DRC / LVS 规则 deck ----
export DP_DRC_DECK=/SM01/teaching/bs/digitalic/calibre_file_gb180/GF018_Technology_Files_iso/DRC/Calibre/DRC-CC-000178/Rev6/drc_header_06_06
export DP_LVS_DECK=/SM01/teaching/bs/digitalic/calibre_file_gb180/GF018_Technology_Files/LVS/Calibre/LVS-000018/Rev13/cmos018bcdlite_30v_iso.lvs.ctl

# ---- Innovus 物理库 ----
export DP_LEF=${DP_LEF:-../lef/csm18ic_6lm.lef}
export DP_LEF_ANT=${DP_LEF_ANT:-../lef/csm18ic_6lm_antenna.lef}

# ---- 时钟约束(按题目要求改) ----
export DP_CLK_PERIOD=${DP_CLK_PERIOD:-5.0}      # ns
export DP_UNCERT_SETUP=${DP_UNCERT_SETUP:-1.0}  # ns
export DP_UNCERT_HOLD=${DP_UNCERT_HOLD:-0.3}    # ns(注意:教程截图的 1ns 是笔误,题面是 300ps)

# ---- 工具函数 ----
dp_source_synopsys() { source "$DP_ENV_SYNOPSYS" >/dev/null 2>&1; }
dp_source_cds()      { source "$DP_ENV_CDS"      >/dev/null 2>&1; }
dp_source_mentor()   { source "$DP_ENV_MENTOR"   >/dev/null 2>&1; }
dp_die() { echo "[DigitalPilot] ERROR: $*" >&2; exit 1; }
# EDA 环境(尤其 bashrc_cds)会污染 LD_LIBRARY_PATH/PYTHONHOME,使系统 python3
# 报 "symbol lookup error" 或 "No module named encodings"。任何在 source 过
# EDA 环境的 shell 里调 python,一律用本启动器(env -u 真正 unset,置空无效)。
dp_python() { env -u LD_LIBRARY_PATH -u PYTHONPATH -u PYTHONHOME python3 "$@"; }
dp_info() { echo "[DigitalPilot] $*"; }

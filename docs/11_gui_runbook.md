# GUI 答辩演示手册(Virtuoso + Calibre)

批处理是生产路径;但答辩/验收时老师可能要求在 Cadence GUI 里现场跑 DRC/LVS。
本手册是实测过的完整点击路径(含所有踩过的坑)。

## 公共准备

```sh
mkdir -p ~/drc_gui_run && cd ~/drc_gui_run
source /SM01/eda/env_set/bashrc_cds        # virtuoso
source /SM01/eda/env_set/bashrc_mentor     # calibre
# DRC 或 LVS 二选一(互斥,换环境要新开终端):
source /SM01/teaching/bs/digitalic/calibre_env/gb018_Source_File_drc_env   # DRC
# source <课程包>/gb018_Source_File_lvs_env                                # LVS
```

cds.lib 必须含三行 DEFINE(见 docs/01),**改后重启 virtuoso 才生效**。

## DRC(nmDRC)

1. `File→New→Library`:`lib_xstreamin`,Attach 到 `chrt018ull_hv30v`;
2. `File→Import→Stream`:选 Innovus 的 `<design>.gds`,Top Cell=设计名;
   **More Options→Reference Library 加 `chrt018ull_hv30v` 和 `csm19ic`**
   (漏 csm19ic → 标准单元空壳,DRC 报一堆 missing;
   填 Ref Lib 弹窗若 Save 报 permission 错,直接点 OK 跳过 Save 即可);
3. 打开 layout 视图(Calibre 菜单才会出现);
4. `Calibre→Run nmDRC`,Load Runset 弹窗直接关;
   - Rules:deck 用 `$TECHDIR/.../Rev6/drc_header_06_06`(env 已 source 才解析得开);
   - Inputs:Top Cell=设计名,勾 Export from layout viewer;
5. Run。判定:`TOTAL DRC Results Generated: 0 (0)`。

导入后库里出现 `<design>_VIA3..7` 等 cell 属正常(Innovus 过孔单元)。

## LVS(nmLVS)

GUI 手工路径最容易死在电源标签上,**推荐混合打法**:输入文件全部用脚本产物——

- Layout File:`add_power_labels.py` 输出的带标签 GDS + stdcell_ref 两个 GDS(共 3 个);
- **取消勾选 Export from layout viewer**(直接喂文件);
- Source:`gen_src_netlist.sh` 输出的 `.src.net`,**取消 Export from schematic viewer**;
- Rules:`cmos018bcdlite_30v_iso` 系列 ctl(LVS env 的 TECHDIR 与 DRC 不同!)。

判定:`CELL COMPARISON RESULTS (TOP LEVEL): CORRECT`,Ports 两侧相等。

若坚持全 GUI(导 Verilog 建 schematic + 手打标签):
- Import Verilog 的 refLibs 填 `basic analogLib chrt018ull_hv30v csm18ic`,
  Power/Ground 填 `VDD!`/`VSS!`;
- 打标签:先点中电源环金属按 `q` 看它在哪层(**实测电源环主体在 METAL2,不是 M1**),
  标签 Layer 必须选同层 label 层、文字压在金属上、Ctrl+S 保存;
- 视图技巧:`f` 全图 → `Ctrl+F` 只显顶层(藏标准单元)→ `z` 框选放大;
  电源环=外圈两个相套的闭合矩形,外环/内环各一个 net(不是左右/上下分);
  红紫颜色是金属层(竖边/横边),不代表 VDD/VSS;
- 标反的症状:LVS 报电源短路或大量不匹配 → 对调两个标签重跑。

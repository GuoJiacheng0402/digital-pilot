---
name: lib-detective
description: EDA 缺失模型/库文件侦探(学院服务器)。TRIGGER 当任何工具报找不到模型、库、cell:VCS "module not found"、DC "can't read library"、Calibre "Cell referenced but not defined"、LVS 黑盒/missing port、Innovus LEF/lib 缺失、strmout 找不到库。教 AI 自己定位正确文件并接进流程,而不是让用户手找。
---

# Lib Detective:缺失模型文件自助定位

学院服务器上"同一个标准单元"以 **6 种形态**存在于不同地方,工具要哪种就喂哪种。
报错的本质几乎都是"喂错了形态"或"没告诉工具去哪找"。

## 形态地图(先判断工具要什么)

| 形态 | 扩展名/视图 | 在哪 | 谁要它 |
|---|---|---|---|
| 行为模型 | `csm18ic.v` | `/SM01/teaching/bs/digitalic/gb18_dc_lib/csm18ic.v` | VCS 门级仿真(GLS) |
| 时序库(综合) | `.db` | `gb18_dc_lib/scx_csm_18ic_{tt_1p8v_25c,ss_1p62v_125c,ff_1p98v_m40c}.db` | DC/Formality(link_library) |
| 时序库(签核) | `.lib` | 同目录同名 `.lib` | Innovus MMMC / PT |
| 物理抽象 | `.lef` | `csm18ic_6lm.lef` + `csm18ic_6lm_antenna.lef`(教程包/4_innovus/lef) | Innovus |
| 原理图/符号 | OA `schematic/symbol` | OA 库 **csm18ic**(`/SM01/teaching/bs/digitalic/IC_ISO_1P6M_2K_2p0fF_B_30K/csm18ic`) | verilog2oa(LVS 源网表) |
| 版图几何 | OA `layout` | OA 库 **csm19ic**(同目录) | strmout → DRC/LVS 参考 GDS |

**csm18ic vs csm19ic 是最大陷阱**:18=电学视图(schematic/symbol),19=物理视图(layout)。
LVS 源网表用 18,DRC/LVS 参考 GDS 用 19。

## 排查流程(按报错对号入座)

### 1. VCS: `module XXX not found` / 实例化未解析
门级网表里的标准单元没有模型 → filelist.f 加一行:
```
/SM01/teaching/bs/digitalic/gb18_dc_lib/csm18ic.v
```
若缺的不是标准单元而是设计子模块,是 filelist 漏了设计文件。

### 2. DC/PT: `unable to read/link library`
确认 `.db`(DC)或对应角 `.db/.lib`(PT)存在:
```sh
ls /SM01/teaching/bs/digitalic/gb18_dc_lib/ | grep -i <角名或cell名>
```
PT 按 search_path 解析裸文件名——查 setenv.tcl 的 ADDITIONAL_SEARCH_PATH 是否含 gb18_dc_lib。

### 3. Calibre: `Cell XXX referenced but not defined`(高频黑盒!)
主 GDS 里 XXX 是空壳引用。**用 DigitalPilot 一键修**:
```sh
scripts/5_drc/gen_stdcell_refs.sh <主GDS> <ref目录>
```
它自动:零依赖 gds_tool.py 求"被引用−已定义"集合差 → 验证 csm19ic 有这些 cell 的 layout →
strmout 导出参考 GDS。手工核验某 cell 是否在库里:
```sh
ls /SM01/teaching/bs/digitalic/IC_ISO_1P6M_2K_2p0fF_B_30K/csm19ic/XXX/
# 应看到 layout/ 目录;只有 schematic/symbol 说明你看错库了(那是 csm18ic 的形态)
```
若 csm19ic 真没有该 cell 的 layout:这是 ECO/综合用了"不该用的 cell",
回 Innovus `setDontUse` 该 cell 并重新 ECO(参见 eco_hold_fix.tcl 的禁用清单)。

### 4. LVS: 黑盒 / missing port / property error
- 黑盒 cell → 同上,参考 GDS 没覆盖;
- `missing port VDD!/VSS!` → 不是库问题,是 GDS 缺电源标签 → `add_power_labels.py`;
- 源侧报 unresolved → verilog2oa 的 `-refLibs csm18ic` 没给对,或网表里有黑盒宏。

### 5. Innovus: LEF/lib 读不进
LEF 用教程包的 `csm18ic_6lm.lef`(6 层金属版,别拿 4lm/5lm 混用);
MMMC 里 `.lib` 路径写绝对路径,不依赖 search path。

### 6. Virtuoso GUI: 库列表里看不到 PDK
启动目录 `cds.lib` 缺 DEFINE → 补三行(chrt018ull_hv30v / csm18ic / csm19ic,
路径前缀 `/SM01/teaching/bs/digitalic/IC_ISO_1P6M_2K_2p0fF_B_30K/`)→ **重启 Virtuoso**。

## 通用侦查命令(以上都不命中时)

```sh
# 按 cell 名全库搜形态
for d in /SM01/teaching/bs/digitalic/IC_ISO_1P6M_2K_2p0fF_B_30K/*/; do
  [ -d "$d/XXX" ] && echo "$d/XXX: $(ls $d/XXX)"
done
# 按文件名搜共享区
find /SM01/teaching/bs/digitalic -maxdepth 3 -iname "*<关键词>*" 2>/dev/null
# 看一个 GDS 里有/缺哪些 structure(零依赖,DigitalPilot 自带)
python3 <DigitalPilot>/scripts/utils/gds_tool.py list-cells   file.gds
python3 <DigitalPilot>/scripts/utils/gds_tool.py scan-missing file.gds
```

### 7. source EDA 环境后 python3 突然坏了
症状:`symbol lookup error: _Py_LegacyLocaleDetected` 或 `No module named encodings`。
原因:bashrc_cds 等污染了 LD_LIBRARY_PATH/PYTHONHOME。
修法:`env -u LD_LIBRARY_PATH -u PYTHONPATH -u PYTHONHOME python3 ...`
(注意必须 env -u 真正 unset,`VAR=` 置空无效;config.sh 的 dp_python 已封装)。

## 纪律

- 永远先判断"工具要哪种形态",再去找文件;不要把 .lib 喂给 VCS、把 csm18ic 喂给 strmout;
- 找到后**写进对应脚本/filelist 固化**,不要只在当次 shell 里 work around;
- 任何"在库里补/换 cell"的决定都要回看 DRC/LVS 闭环(形态地图里它们是联动的)。

# Calibre LVS:源网表与电源标签的全自动化

LVS 要比对"版图"和"源"。两侧各有一个教程没讲透的坑:

- **版图侧**:GDS 没有电源网名字 → 报 `missing port VDD!/VSS!`;
- **源侧**:需要 SPICE 网表,教程让你在 Virtuoso GUI 里导 Verilog 再导 CDL——
  全程点鼠标,ECO 后还得重点一遍。

DigitalPilot 把两侧都脚本化了。完整跑法:

```sh
cd 5_LVS
# ① 源网表(ECO 后必须重跑!)
../path/to/scripts/5_lvs/gen_src_netlist.sh ../4_innovus/postlayout/${DESIGN}.v ./src
# ② 电源标签(坐标自动从 DEF 解析,不会标反)
../path/to/scripts/5_lvs/add_power_labels.py \
    --gds ../4_innovus/postlayout/${DESIGN}.gds \
    --def ../4_innovus/postlayout/${DESIGN}.def \
    --out ./${DESIGN}_with_power_labels.gds
# ③ 标准单元参考 GDS(与 DRC 共用,见 docs/06)
../path/to/scripts/5_drc/gen_stdcell_refs.sh ../4_innovus/postlayout/${DESIGN}.gds ./stdcell_ref
# ④ LVS
../path/to/scripts/5_lvs/run_lvs.sh ./${DESIGN}_with_power_labels.gds ./src/${DESIGN}.src.net ./stdcell_ref
```

判定:`CELL COMPARISON RESULTS ( TOP LEVEL ) : CORRECT`,且 Ports 两侧数目相等
(信号端口数 + 2 个电源端口)。

## 源网表:verilog2oa → conn2sch → si 三连

教程 GUI 的 `File→Import→Verilog` 的批处理等价物:

```sh
verilog2oa -lib lib_verilogin -refLibs "csm18ic" -refViews "symbol schematic" \
           -verilog ${DESIGN}.v -top ${DESIGN} -view netlist -viewType netlist \
           -blackBox -tolerate ...
conn2sch  -lib lib_verilogin -cell ${DESIGN} -view netlist -destview schematic ...
si . -batch -command netlist -cdslib cds.lib       # auCdl,产出 ${DESIGN}.src.net
```

要点:
- **refLibs 用 `csm18ic`**(有 symbol/schematic);`csm19ic` 是 layout 库,这一步用不到;
- **不要用 `-tieHigh VDD! -tieLow VSS!`**:`!` 的 shell/工具转义会失败。电源连接交给
  GDS 侧标签 + deck 的 `LVS GLOBALS ARE PORTS YES` 处理;
- `si` 的配置在 `si.env`(auCdl simulator、simViewList 等),模板随仓库分发;
- **网表与 GDS 必须同版本**:ECO 后只换 GDS 不换源网表,LVS 会以 property error /
  instance 不匹配的形式"莫名其妙"地挂。

## 电源标签:从 DEF 自动定位,杜绝标反

原理:Innovus DEF 的 `SPECIALNETS` 段完整记录了 `VDD!`/`VSS!` 电源环每段金属的
层、线宽、坐标。`add_power_labels.py` 解析出两个网各自 METAL1 环的 y 坐标,调用零依赖的
gds_tool.py 在主 GDS 顶层注入两个文字标签(**MET1 label 层 = GDS 34/10**),输出带标签
的新 GDS。因为坐标直接来自 DEF 的 net 归属,**不存在"标反"问题**——这是手工
GUI 打标签最常见的翻车点(标反的症状:LVS 报电源短路或大量 cell 不匹配)。

手工打标签(GUI 答辩演示用)的对应要领:标签文字 `VDD!`/`VSS!`、层选
**与所标金属同层的 label 层**、必须压在金属上、保存后再跑。

## INCORRECT 排查表

| 报告症状 | 原因 | 修法 |
|---|---|---|
| `missing port VDD!/VSS!` + Ports 52 vs 54 | 用了没标签的 GDS / 标签层错 / 没压到金属 | 用 add_power_labels.py 的输出 |
| 电源短路 / 几乎全部 instance 不匹配 | VDD!/VSS! 标反(手工才会) | 对调标签 |
| 个别 cell 黑盒、property error | stdcell_ref 没覆盖该 cell(常见于 ECO 新 cell) | 重跑 gen_stdcell_refs.sh |
| instance 数对但 net 大片不匹配 | 源网表与 GDS 版本不同步 | 重跑 gen_src_netlist.sh |
| 大小写引发的不匹配 | 网表与 GDS 命名大小写不一致 | deck 加 `LAYOUT CASE YES` / `SOURCE CASE YES` |

注意 DRC 与 LVS 的 `TECHDIR` 指向**不同**目录(iso vs 非 iso),两套环境不要在同一
shell 混 source——`run_drc.sh`/`run_lvs.sh` 各自 source 各自的 env,照着用即可。

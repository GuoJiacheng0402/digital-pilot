# AGENTS.md — AI 助手总入口(Claude Code 等先读这里)

你是在微电子学院服务器上协助完成**数字 IC 课程设计**的 AI。本仓库包含你需要的
全部流程脚本、方法学与踩坑知识;读完本文你应当能**独立把一个新题目从 RTL 做到
可提交的 GDS 全家桶**。原则:RTL 功能本体与学生共同完成(方法见 docs/14),
流程与验证由你用本仓库脚本驱动;**绝不伪造结果,每个"通过"都要有报告原文佐证**。

## 0. 开工三件事(统一入口 `dp`,= bin/dp,底层即 scripts/ 各脚本)

```sh
# 1) 建项目工作区(教程 0-9 目录 + 全部模板铺好)
dp new ~/my_design <设计名> [clk端口] [周期ns]
# 2) 进入项目环境(设计名注入所有脚本)
source ~/my_design/dp_env.sh
# 3) 任何时刻自查全链状态
dp status     # (PATH 里加 ~/DigitalPilot/bin;dp help 看全部子命令)
```

环境铁律:每个新终端先 source 对应 EDA 环境(见 docs/01);
`vcs: Command not found` = 没 source,不是别的问题。
**EDA shell 里调 python 一律用 `dp_python`**(config.sh 提供;EDA 环境会污染
LD_LIBRARY_PATH/PYTHONHOME 弄坏系统 python3)。

## 0.5 新题目适配清单(题目年年变,变的只有这些)

```sh
# 端口/时钟随题目给定即可,其余全部端口无关:
new_project.sh ~/proj <设计名> [时钟端口名] [周期ns]   # SDC/Innovus 自动实例化
scripts/utils/list_ports.py rtl.v --fmt tb            # 端口提取→tb 声明/例化直接贴
scripts/utils/gen_lut.py --expr "..." --scale N        # 任意定点函数打表成 Verilog
```
- SDC 用 `all_inputs/all_outputs` 写法,**任何端口集合零修改**;
- Innovus pin placement 运行时 `dbGet` 自动推导,无需手写端口表;
- 题面差异(协议/latency/饱和规则)只影响 RTL 与 tb → 按 docs/14 的
  "题面→硬规格"五步法处理;流程层(1-9 阶段)与题目完全解耦。

## 1. 状态机:做到哪一步,下一步干什么

按顺序推进;**每个 gate 不满足就不许进下一阶段**;任何上游变更(尤其 ECO)→
其下游全部重做。

| # | 阶段(目录) | 命令 | Gate(报告原文) |
|---|---|---|---|
| 0 | RTL 仿真 `0_simulation_pre` | `make run_vcs` | `PASS ... checks=N latency=L`,errors=0 |
| 1 | DC 综合 `1_dc` | `./run.sh` | timing.rpt 与 timing_min.rpt 均 `slack (MET)` |
| 2 | Formality 前端 `2_formality_postdc` | `./run.sh` | `Verification SUCCEEDED` |
| 3 | 前仿 `3_simulation_postdc` | 拷网表+SDF → `make run_vcs` | `PASS`,checks 与阶段0**同值** |
| 4 | APR `4_innovus` | `innovus -batch -file ../tcl/run_innovus.tcl` | postRoute setup/hold `Violating Paths: 0`;verifyGeometry `0 Viols` |
| 5a | DRC `5_DRC` | `gen_stdcell_refs.sh` → `run_drc.sh` | `TOTAL DRC Results Generated: 0 (0)` |
| 5b | LVS `5_LVS` | `gen_src_netlist.sh` → `add_power_labels.py` → `run_lvs.sh` | `(TOP LEVEL) CORRECT` + Ports 两侧相等 |
| 6 | Formality 后端 `6_formality_postlayout` | `./run.sh` | `SUCCEEDED` |
| 7 | StarRC `7_StarRC` | `./run_3corner.sh` | 三个 SPEF 生成,Errors 0 |
| 8 | PT 签核 `8_pt` | `./run_3corner.sh` | **三角** coverage 全 `0 ( 0%)` violated |
| 9 | 后仿 `9_simulation_postlayout` | `./run_corner.sh wst/typ/bst` | 三角 `PASS`,checks 与阶段0同值,SDF `Total errors: 0` |
| ✓ | 提交 | `make_submit_package.sh` | §1.7 清单齐(docs/12) |

时序不收敛的决策顺序:**改 RTL 架构(docs/14)> 约束策略 > 工具参数**;
BST hold 违例是单角实现的预期产物 → `eco_hold_fix.tcl`(docs/05),ECO 后 5–9 全重做。

## 2. 必须内化的七条知识(血泪浓缩)

1. **csm18ic vs csm19ic**:18=电学视图(schematic/symbol,LVS 源网表用),
   19=layout(DRC/LVS 参考 GDS 用)。搞混 = 黑盒/空壳;
2. **标准单元参考 GDS**(教程黑盒):Innovus GDS 里标准单元是空壳引用,
   `gen_stdcell_refs.sh` 自动扫缺失 + strmout 导出(`-dbuPerUU 2000` 必须与
   Innovus units 一致)。机制详解 docs/06;
3. **电源标签**:GDS 无电源网名,LVS 必报 missing port → `add_power_labels.py`
   从 DEF 自动定位注 `VDD!/VSS!`(34/10 层),杜绝标反;
4. **PRECISION 2000**:工艺 LVS deck 原值 1000 与 GDS 不一致直接报错,
   `run_lvs.sh` 已自动修 deck 副本;
5. **三角方法学**:实现优化单角 WST,签核/后仿必须三角(wst/typ/bst);
   WST 卡 setup、BST 卡 hold 是健康分布(docs/10);
6. **约束三红线**:reset 必须约束、hold uncertainty 0.3ns(教程截图 1ns 是笔误)、
   时钟只许收紧不许放松;
7. **三仿一致**:RTL/前仿/后仿的 `checks` 数必须相同——这是验收硬指标,
   也是你自检"网表/SDF/tb 版本配套"的最敏感探针。

## 3. 知识检索表(遇到 X 读哪篇)

| 场景 | 读 |
|---|---|
| 新题目,开始设计 RTL | docs/14 + 基础工具:`list_ports.py`(端口→tb)、`gen_lut.py`(函数打表)、`gds_tool.py`(GDS 检视)、`tb_template.v` |
| 任何"找不到 cell/库/模型" | skills/lib-detective(6 形态地图 + 决策树) |
| 各阶段原理与判读 | docs/02–09 对应章节 |
| DRC/LVS 黑盒细节 | docs/06、07 |
| 时序收不住 | docs/14(架构)→ docs/05(Innovus/ECO)→ docs/10(三角) |
| 报错速查 | docs/faq_pitfalls.md |
| GUI 演示(答辩) | docs/11 |
| 提交/报告 | docs/12;素材汇总 `collect_reports.sh` |
| 工作纪律(日志/备份/交接) | docs/13 |

## 4. 行为准则

- **验证优先**:声称任何阶段通过前,引用报告文件路径与判定行原文;
- **变更传播**:网表/版图一变,向下游全部重跑(最易漏:src.net 与 stdcell_ref);
- **不碰红线**:不放松时钟、不 false-path reset、不跳过任何 gate 交付;
- **写日志**:重要决策/数字记入项目主日志(docs/13 格式),为下一个接手者
  (人或 AI)留出可恢复的现场;
- **答案自有**:本仓库无题目答案;遇到与原型(function_gen)相关的具体数值,
  仅作方法学参照,你的设计要从自己的题面推导。

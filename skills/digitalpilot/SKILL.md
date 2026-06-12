---
name: digitalpilot
description: 数字 IC 课程设计全流程助手(GF180/学院服务器)。TRIGGER 当用户要跑课程设计任一阶段:RTL/VCS 仿真、DC 综合、Formality、Innovus APR/ECO、Calibre DRC/LVS、StarRC、PrimeTime 签核、后仿 GLS;或遇到 stdcell 空壳、missing port VDD!、hold 违例、三角签核等问题。
---

# DigitalPilot 流程助手

你在协助学生完成数字 IC 课程设计(GF180,微电子学院服务器)。本 skill 对应
DigitalPilot 仓库(脚本在 `scripts/`,文档在 `docs/`)。原则:**学生负责 RTL 架构,
你负责用脚本把流程跑通**;不要替学生写题目要求的 RTL 功能本体。

## 全流程地图(详见 docs/00_overview.md)

RTL仿真(0) → DC(1) → Formality(2) → 前仿(3) → Innovus(4) → DRC/LVS(5) →
Formality后端(6) → StarRC三角(7) → PT三角(8) → 后仿三角(9)

## 每阶段操作卡

| 阶段 | 命令 | 通过判定 |
|---|---|---|
| 0 | `make run_vcs`(0_simulation_pre/) | tb PASS |
| 1 | `./run.sh`(1_dc/,sdc 用 scripts/1_dc/top.sdc 模板) | setup+hold slack MET |
| 2/6 | `./run.sh`(formality 目录) | Verification SUCCEEDED |
| 3 | `make run_vcs`(3_simulation_postdc/) | PASS,checks 数与 RTL 相同 |
| 4 | `innovus -batch -file ../tcl/run_innovus.tcl`(4_innovus/work/) | postRoute 0 violating + verifyGeometry 0 |
| 5-DRC | `gen_stdcell_refs.sh 主GDS ref目录` → `run_drc.sh 主GDS ref目录` | Results Generated: 0 |
| 5-LVS | `gen_src_netlist.sh 网表 src目录` → `add_power_labels.py --gds --def --out` → `run_lvs.sh 标签GDS src.net ref目录` | TOP LEVEL CORRECT |
| 7 | `./run_3corner.sh`(7_StarRC/) | 三角 SPEF,Errors 0 |
| 8 | `./run_3corner.sh`(8_pt/) | 三角 All Checks 0 violated |
| 9 | `./run_corner.sh wst|typ|bst`(9_simulation_postlayout/) | 三角 PASS |

跑任何阶段前确认 source 了对应 EDA 环境(config.sh 的 dp_source_* 助手);
`vcs: Command not found` 一律是没 source。

## 高频问题决策树

- **Cell referenced but not defined**(Calibre)→ 标准单元空壳 → 跑
  `scripts/5_drc/gen_stdcell_refs.sh`;ECO 后必须重跑。机制见 docs/06_calibre_drc.md。
- **missing port VDD!/VSS!**(LVS)→ GDS 无电源标签 → `scripts/5_lvs/add_power_labels.py`
  (坐标自动取自 DEF,勿手工打标签)。
- **LVS 大量不匹配/property error** → 先查源网表是否过期(ECO 后重跑
  gen_src_netlist.sh),再查标签是否标反。
- **BST hold 违例** → 预期内(单角 WST 实现)→ `scripts/4_innovus/eco_hold_fix.tcl`
  (DRC-safe 框架);ECO 后 5/6/7/8/9 全部重跑,见 docs/10_three_corner.md。
- **后仿 x 态/annotate 报错** → 网表与 SDF 版本配套?+negdelay +neg_tchk 在不在?

## 纪律(替学生把关)

1. 任何网表/版图变更后,向下游全部重跑;用 `scripts/utils/collect_reports.sh` 自查;
2. 时钟约束只许收紧不许放松;reset 必须约束;hold uncertainty 0.3ns;
3. 三仿(RTL/前仿/后仿)checks 数必须一致;
4. 验收材料 = 各阶段报告原文,不要转述数字,引用文件路径。

# 验收与提交清单

## 自查(一条命令)

项目根目录跑 `scripts/utils/collect_reports.sh`,十一行判定全绿才算闭环:
RTL PASS / DC setup+hold MET / Formality×2 SUCCEEDED / 前仿 PASS /
verifyGeometry 0 / DRC 0 / LVS CORRECT / PT 三角 0 violated / 后仿三角 PASS。

## 三仿一致

RTL、前仿、后仿三处 `PASS ... checks=N latency=L` 的 **N 和 L 必须一致**。
后仿要 wst/typ/bst 各留一份 `run_<c>.log`(run_corner.sh 自动存档)。

## 提交包

教程 §1.7 只要求最小集(RTL/tb、DC 网表+三报告+sdc、fm.log×2、Innovus 网表+cmd、
lvs.report、PT 三角 coverage+sdc)。`scripts/utils/make_submit_package.sh` 一键打:

```sh
scripts/utils/make_submit_package.sh <项目目录> <输出.zip>
```

完整包(全部产物)直接 zip 项目目录,但先清 EDA 缓存(csrc/simv/svdb/fsdb)。

## 报告要点(题面 §1.8 对照)

结构图与位宽推导、latency 定义与 tb 对齐方式、三仿对比、DC PPA、Formality、
APR 各步截图(restoreDesign 还原最终库截)、DRC/LVS/StarRC/PT 结果、PPA 自评。
写作素材一键汇总:跑 collect_reports.sh + 把各报告原文节选进附录,数字引用原文。

## 答辩高频问答(供准备)

- 流水线 latency 与参数串行装载周期为什么无关(吞吐 1/拍,两个周期数是独立概念);
- 为何实现单角 WST、签核三角(docs/10);
- BST hold 违例怎么修的(ECO drcsafe 三件套,docs/05);
- stdcell_ref 哪来的(strmout 机制,docs/06——助教最感兴趣的一问)。

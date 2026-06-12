# 踩坑速查表(现象 → 原因 → 修法)

## 环境
| 现象 | 原因 | 修法 |
|---|---|---|
| `vcs/dc_shell/pt_shell: Command not found` | 没 source bashrc_synopsys | source 后重跑(每个新终端都要) |
| `virtuoso: command not found` | 没 source bashrc_cds | 同上 |
| Calibre 起不来/license 超时 | MGLS 未指 | `export MGLS_LICENSE_FILE=/SM01/eda/license/SMW5/mentor/mentor_lic.dat` |
| Virtuoso 里看不到 PDK 库 | 启动目录 cds.lib 没 DEFINE | 补三行 DEFINE(docs/01),重启 virtuoso |
| source EDA 环境后 python3 报 symbol lookup / no encodings | cds 环境污染 LD_LIBRARY_PATH/PYTHONHOME | 用 config.sh 的 dp_python(env -u 三连 unset) |
| DRC/LVS deck 互相串 | 两套 env 混 source | 一个 shell 只跑一种;用 run_drc.sh/run_lvs.sh |

## DC
| 现象 | 原因 | 修法 |
|---|---|---|
| hold 怎么都修不干净 | dont_use 把 DLY* 禁了 / hold uncertainty 抄成 1ns | remove_attribute DLY*;uncertainty 0.3 |
| DC clean 但 Innovus 爆几百条 | 单角线负载 vs 多角真实布线 | 正常;回 RTL 加流水/拆关键级,别只榨工具 |

## Innovus
| 现象 | 原因 | 修法 |
|---|---|---|
| NRDB-954 / 时钟网布线冲突 | routeTopRoutingLayer=5 但 CTS 用了 M6 | 设 6 |
| stripe 区域 DRC 报错 | stripe 层太低 | stripe 换 METAL4 或更高 |
| ECO 后 LVS 炸 | ECO 插了参考 GDS 里没有的 cell | ECO 前 setDontUse;事后重跑 gen_stdcell_refs.sh |
| pin 被布线器挪走 | editPin 没勾 fixedPin | -fixedPin 1 |

## Calibre
| 现象 | 原因 | 修法 |
|---|---|---|
| Cell referenced but not defined | 标准单元空壳 | gen_stdcell_refs.sh(docs/06,本项目核心) |
| missing port VDD!/VSS! | GDS 无电源标签 | add_power_labels.py(docs/07) |
| Rule file precision 1000 vs database 2000 | 工艺 deck PRECISION 与 Innovus GDS 不一致 | run_lvs.sh 已自动改 deck 副本为 2000 |
| 电源短路/大量不匹配 | 手工标签标反 | 对调;或改用脚本注标签 |
| LVS property error 一大片 | 源网表与 GDS 版本不同步 | ECO 后重跑 gen_src_netlist.sh |
| 只剩 density | 覆盖率不足 | M1 靠 filler;高层金属补 fill 矩形(docs/06) |

## 后仿
| 现象 | 原因 | 修法 |
|---|---|---|
| SDF annotate 报错一堆 | 网表与 SDF 不是同一次 PT 产物 | 重新配套拷贝 |
| 输出 x 态 | SDF 没盖全/负延迟被丢 | +negdelay +neg_tchk;核对版本 |
| 后仿 FAIL 但 RTL PASS | 真时序违例 or latency 没对齐 | 查 PT 对应角;核对三处 tb 的 LATENCY |

## 通用纪律
1. **变更向下游全重跑**(ECO 后:ref GDS、src.net、SPEF、PT、SDF、后仿,一个都不能省);
2. 每轮跑完 `utils/collect_reports.sh` 自查全链;
3. 备份用目录快照(backups/<tag>_<date>/),报告与脚本一起存,answer 时拿数字说话。

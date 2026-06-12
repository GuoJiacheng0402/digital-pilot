# 全流程总览

```
RTL ──0──▶ VCS仿真 ──1──▶ DC综合 ──2──▶ Formality前端 ──3──▶ 前仿
                              │
                              ▼
        4. Innovus APR(floorplan→place→CTS→route→opt→ECO)
                              │
        ┌──────────┬──────────┼──────────┐
        ▼          ▼          ▼          ▼
     5.DRC      5.LVS    6.Formality  7.StarRC三角SPEF
                              后端          │
                                            ▼
                                   8. PT三角签核 ──▶ 9. 三角后仿GLS
```

| 阶段 | 输入 | 输出 | 通过判定 |
|---|---|---|---|
| 0 RTL仿真 | rtl/ tb/ | run.log, fsdb | tb 自检 PASS |
| 1 DC | RTL + top.sdc | 网表/.sdf/.svf/报告 | timing slack MET(setup+hold) |
| 2 Formality前端 | RTL vs DC网表 + svf | fm.log | Verification SUCCEEDED |
| 3 前仿 | DC网表 + DC SDF | run.log | PASS 且与 RTL 一致 |
| 4 Innovus | DC网表 + sdc + lef | .v/.def/.gds/SDF + 报告 | postRoute setup/hold 0 violating;verifyGeometry 0 |
| 5 DRC | GDS + stdcell_ref★ | drc.summary | Results Generated: 0 |
| 5 LVS | 带标签GDS + src.net★ | lvs.report | TOP LEVEL CORRECT |
| 6 Formality后端 | DC网表 vs Innovus网表 | fm.log | SUCCEEDED |
| 7 StarRC | DEF + LEF | 三角 SPEF | Errors 0 |
| 8 PT | 网表 + SPEF + sdc | 三角覆盖率报告 + SDF | 三角全 0 violated |
| 9 后仿 | 网表 + PT SDF | run_{c}.log | 三角全 PASS,与 RTL 逐拍一致 |

★ = DigitalPilot 自动化的教程盲区,见 docs/06、07。

执行顺序上的两个要点:
1. **ECO 改变网表/版图后**,5/6/7/8/9 全部失效,必须按序重做(src.net 和 stdcell_ref 最容易被忘);
2. 三仿一致(RTL=前仿=后仿)是验收硬条件,testbench 的 latency 对齐方式三处必须相同。

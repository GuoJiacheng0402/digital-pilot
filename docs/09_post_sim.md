# 后仿 GLS(真 SDF 反标)

跑法:`cd 9_simulation_postlayout && ./run_corner.sh wst`(typ/bst 同理)。
脚本自动改 tb 的 `$sdf_annotate` 角名、跑 VCS、把日志存成 run_<corner>.log。

## VCS 选项(makefile 已配好,知其所以然)

| 选项 | 作用 |
|---|---|
| `+sdfverbose` | SDF 反标明细进日志,核对 0 errors 用 |
| `+negdelay` | 接受 PT SDF 里的负 interconnect 延迟(OCV 下常见),不加会被静默钳 0 |
| `+neg_tchk` | 允许负值时序检查窗口(配合 SDF 的负 setup/hold) |
| annotate 第4参 `"MAXIMUM"` | 取 SDF 三元组的 max 延迟 —— 慢角后仿的正确口径 |

## 判定与排查

- 判定:tb 自检 PASS,`checks` 数与 RTL 仿真**完全一致**;sdf.log `Total errors: 0`
  (少量 up-hierarchy interconnect 警告无害);
- 出 `x` 态传播:多半是 SDF 路径没盖全或网表/SDF 版本不配套;先核对两者都来自
  同一次 PT;个别 notifier 引发的 x 可在 tb 侧滤;
- 时序违例打印(Timing violation):真问题。回 PT 看对应角是不是真有违例——
  后仿是签核的"实证复核",不要靠加大时钟周期糊弄;
- **三角都要跑**,日志分别留档(run_wst/typ/bst.log),验收硬证据。

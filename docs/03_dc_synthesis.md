# DC 综合要点

教程的 dc.tcl/set_env.tcl 直接复用;需要自己维护的是 top.sdc 和 define.tcl
(模板见 scripts/1_dc/)。

SDC 模板已是**端口无关**写法(`remove_from_collection [all_inputs] [get_ports $CLK]`
+ `all_outputs`),任何题目的端口集合都无需修改;时钟名/周期由 new_project.sh 参数化。

## SDC 三个易错点(都踩过)

1. **reset 必须约束**:与 a/b/c/e 一起进 `set_input_delay`,不准 false-path/ideal——
   题面明确要求,漏了属于"漏约束路径骗 PPA";
2. **hold uncertainty = 0.3 ns**:题面 300ps;教程某截图写 1ns 是笔误,照抄会让
   hold 修复极度困难;
3. **不放松时钟**:5.0 ns 是底线。想证明裕量,可以综合 5.0 + 签核更紧(如 4.99),
   方向只能更严不能更松。

## dont_use 策略

见 scripts/1_dc/dont_use_note.md。核心:别把 DLY* 禁掉(set_fix_hold 需要它),
禁掉超大驱动和 CLK*(时钟单元留给 CTS)。

## 结果判读

- `timing.rpt`(setup)和 `timing_min.rpt`(hold)的 slack 都要 MET;
- **DC clean ≠ 后端 clean**:DC 是单角(tt)+线负载模型,Innovus 多角+真实布线后
  完全可能爆几百条违例——DC 只保证"可综合且大致可行",真正的时序收敛看 4/8 阶段;
- qor.rpt 的 Levels of Logic ≈ 20 是 5ns@此工艺的经验上限,超太多说明流水线切分不足,
  回 RTL 改架构比榨工具有效得多。

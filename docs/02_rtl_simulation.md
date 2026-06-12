# RTL 仿真与 Testbench 方法学

跑法:`make run_vcs`(编译+运行),`make vd`(Verdi 看 fsdb 波形),`make clr`(清理,注意会删 log)。

## Testbench 黄金模型三要素(验收口径)

1. **软件黄金模型**:每拍按题目公式算期望输出(`$cos` 等实数运算 + 与 RTL 相同的
   舍入/饱和规则),不要抄 RTL 结构——独立实现才有比对意义;
2. **latency 对齐**:`localparam LATENCY = L`,期望值压入 L 深移位队列,比较
   `y === exp_pipe[LATENCY-1]`。RTL/前仿/后仿三处 tb 的 L 必须一致;
3. **逐拍自检 + 计数**:`checks`/`errors` 计数,结束打印
   `PASS tb checks=N latency=L`——三仿一致性靠同一个数字 N 说话。

## 覆盖清单(对照题面逐条打勾)

reset 上电清零、reset 中途打断、参数串行写入边界(写满下一拍生效/未满用旧值)、
输入排列两分支、全 0/全 1/交错位型、正负饱和、≥1000 组随机(建议 3000)。
定向用例建议封装成宏(`RUN_CASE`),每组前 reset、打印 CASE_n_START/OUTPUT,
方便答辩时在波形里定位。

## 前仿/后仿差异

- 前仿(3):filelist 加标准单元模型 csm18ic.v;tb 加
  `$sdf_annotate("./rtl/<design>.sdf", dut, , "sdf.log", "MAXIMUM");`
- 后仿(9):SDF 换成 PT 生成的角 SDF;makefile 增加 `+sdfverbose +negdelay +neg_tchk`
  (详见 docs/09)。

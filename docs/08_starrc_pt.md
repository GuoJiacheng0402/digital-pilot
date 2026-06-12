# StarRC 寄生提取 + PrimeTime 签核(三角)

## StarRC

跑法:`cd 7_StarRC && ./run_3corner.sh`。模板 starrc_spef.tcl.tmpl 自动实例化
wst(-40°C)/typ(25°C)/bst(125°C) 三份配置,各产一个 SPEF。

要点:输入是 **DEF + LEF**(不是 GDS);nxtgrd 按角选(模板已写好学院路径);
`EXTRACTION: RC + COUPLE_TO_GROUND YES`。ECO 后 DEF 变了要重抽。

## PrimeTime

跑法:`cd 8_pt && ./run_3corner.sh`(教程版 pt_{wst,typ,bst}.tcl 放 tcl/,
改两处:NETLIST_FILES 指最终网表、PARASITIC_FILES 指 7_StarRC 输出)。

PT 用的 top.sdc 与 DC 版两处不同(模板 scripts/8_pt/top.sdc 已处理):
`set_fix_hold` 注释(综合期指令)、`clk max_fanout` 注释(CTS 后真实时钟树承担)。

每角产物:
- `<c>_report_analysis_coverage.report`:**主判定**,All Checks 行 violated 必须 0;
  out_hold 的 untested 是输出无 min 约束所致,正常;
- `<c>_summ_max/min_timing.report`:最差 setup/hold 路径(报告取数用);
- `<design>_<c>.sdf`:**后仿用的真 SDF**(write_sdf 从 PT 导出,含真实 RC 延迟)。

判读经验:WST 卡 setup(乘法器进位链类长路径)、BST 卡 hold(相邻流水寄存器短路径)、
TYP 两头宽松——这个分布是健康的;若 TYP 也紧,说明实现裕量整体不足。

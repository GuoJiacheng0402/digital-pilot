# Innovus 批处理 APR

教程是 GUI 点击流;本仓库 `scripts/4_innovus/run_innovus.tcl` 是它的批处理等价物
(经实战收敛的参数),跑法:

```sh
cd 4_innovus/work
innovus -batch -file ../tcl/run_innovus.tcl   # 全程 10-30 分钟
```

改三处即可复用:DESIGN_NAME、pin placement 的端口列表、floorplan 利用率/边距。

## 流程与实战参数

| 步骤 | 命令 | 实战要点 |
|---|---|---|
| import | init_design + mmmc.view | 单角 WST 优化视图(方法学见 docs/10) |
| floorplan | `floorPlan -site csm18site -r 0.85 0.50 20 20 20 20` | util 0.5 起步;太挤 route 失败,太松面积虚胖 |
| 电源 | globalNetConnect + addRing/addStripe | 环:横 M1/竖 M2,宽 5 间 2;stripe M4(DRC 报错可调高层) |
| pin | editPin -fixedPin 1 | 必须 fix,否则布线时 pin 漂移 |
| place | placeDesign + optDesign -preCTS | 加 addTieHiLo(TIEHI/TIELO) |
| CTS | ccopt_design -CTS | 时钟树 M3/M4 + VSS! 屏蔽;skew 50ps/trans 250ps;CLKBUF/CLKINV 白名单 |
| route | sroute + routeDesign | **routeTopRoutingLayer 必须 6**:CTS 时钟网可能上 M6,限 5 报 NRDB-954 |
| opt | optDesign -postRoute(setup/hold 交替两轮) | targetSlack setup 0.08 / hold 0.10:OCV 缓冲甜蜜点 |
| filler | addFiller -doDRC | FILL1~64 全系列 |
| 检查 | checkPlace/checkRoute/verifyGeometry | 三项全 0 才能导出 |
| 导出 | saveNetlist/write_sdf/defOut/streamOut | **streamOut -units 2000**(下游 stdcell_ref 同步此值);saveDesign 存 .dat 供 ECO/截图 restore |

## ECO 方法学(post-route hold 修复)

签核三角后若 BST hold 有违例,用 `eco_hold_fix.tcl`(DRC-safe 框架):

1. `restoreDesign` 最终库 → 建 BST hold 视图(setup 仍 WST);
2. `setDontUse` 禁掉参考 GDS 里没有 layout 的 cell(否则 LVS 必炸);
3. `deleteFiller` → `optDesign -postRoute -hold`(targetSlack 0.06→0.07 两轮渐进,
   **不要一轮推太狠**,监控 setup 不被拖负)→ `addFiller -doDRC`;
4. verifyGeometry 全 0 → 导出全套 → **下游 5/6/7/8/9 全部重做**。

原型项目数据:BST hold 434 条违例(-114ps)→ ECO 两轮 → +9.5ps,WST setup 不损。

## GUI 还要会一点

答辩演示截图用:`innovus` 起 GUI → `restoreDesign xxx.dat` 还原最终版图,
floorplan/CTS/route 各截一张。批处理与 GUI 写的是同一个库,不冲突。

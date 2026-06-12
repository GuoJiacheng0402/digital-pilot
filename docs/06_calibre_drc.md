# Calibre DRC:标准单元参考 GDS 机制全解(教程黑盒)

## 问题:为什么直接跑 DRC 会失败

Innovus `streamOut` 出来的 GDS 里,**标准单元只是"被引用的名字",没有物理几何**
(GDS 中有 `SREF BUFX2` 这样的引用,但没有 `BUFX2` 这个 STRUCTURE 的定义)。
布局工具只关心摆放和布线,单元内部版图本来就不归它管。直接喂给 Calibre 会报:

```
ERROR: Cell AOI31X2 is referenced but not defined.
ERROR: Cell NOR3X4 is referenced but not defined.
...
```

DRC 在规则计数前直接中止——这就是多数人卡死的地方。GUI 流程里 Virtuoso 的
Stream In 配 `csm19ic` 参考库能临时绕过,但批处理/命令行跑 Calibre 没有这层魔法。

## 解法:从 csm19ic 批量导出"标准单元参考 GDS"

学院 PDK 里标准单元有两个 OA 库,分工不同(**这是最容易搞混的点**):

| 库 | 含有的视图 | 用途 |
|---|---|---|
| `csm18ic` | schematic / symbol / cmos_sch | LVS 源网表(verilog2oa 引用) |
| `csm19ic` | **layout** | **DRC/LVS 的物理参考 GDS(本文主角)** |

机制三步:

1. **找出缺什么**:解析主 GDS,集合差 `被引用的 structure − 已定义的 structure`
   = 精确的缺失单元清单(原型项目是 157 个);
2. **批量导出**:用 Virtuoso 的 XStream Out 命令行工具 `strmout`,把这些 cell 的
   layout 视图从 `csm19ic` 一次导出成一个 GDS;
3. **拼合**:Calibre 控制文件的 `LAYOUT PATH` 同时挂主 GDS + 参考 GDS,
   Calibre 按 structure 名自动拼合,引用就解析了。

```
LAYOUT PATH  "function_gen.gds" "csm19ic_refs_physical.gds"
LAYOUT PRIMARY "function_gen"
```

本仓库的 [`scripts/5_drc/gen_stdcell_refs.sh`](../scripts/5_drc/gen_stdcell_refs.sh)
把三步全自动化了(零依赖 gds_tool.py 扫缺失 → strmout 导出 → 校验覆盖;纯标准库直接解析 GDSII 二进制,服务器原生 python3 可跑,无需安装任何包)。

## strmout 关键参数(踩坑实录)

```sh
strmout -library csm19ic \
        -strmFile refs.gds \
        -topCell "ADDFX1,BUFX2,..." \    # 逗号分隔的缺失 cell 清单
        -view layout \
        -dbuPerUU 2000 \                 # ★ 必须 2000
        -layerMap csm19ic_physical_stream.map \
        -case Preserve \                 # ★ 保持大小写
        -convertDot node
```

| 参数 | 为什么 |
|---|---|
| `-dbuPerUU 2000` | 必须与 Innovus `streamOut -units 2000` 一致。csm19ic 库自身 tech 是 1000,**不改会坐标错位一倍**(strmout 会打 XSTRM-283 提示,属预期) |
| `-layerMap` | OA 层名 → GDS 层号映射。标准单元只用到 MET1,7 行即可(NWELL 21 / COMP 22 / POLY2 30 / PPLUS 31 / NPLUS 32 / CNT 33 / MET1 34),文件随仓库分发 |
| `-case Preserve` | structure 名必须与主 GDS 的引用逐字符一致 |
| 运行目录 | strmout 靠 `cds.lib` 解析库名,脚本会自动生成临时 cds.lib;手跑则需在能看到 csm19ic 定义的目录启动 |

导出的 structure 数会比 cell 数多(原型:157 cell → 314 structure),因为 pcell
子结构会被一并带出,正常。

## ECO 之后必须重做

ECO(尤其 hold-fix)会插入新 cell 类型(原型项目 ECO 引入了
`DLY1X1/DLY2X1/DLY3X1/BUFXL/CLKBUFX1/CLKBUFXL` 六种),旧参考 GDS 没有它们,
DRC 又会报 referenced but not defined。**重跑 `gen_stdcell_refs.sh` 即可**——
它按"当前主 GDS 实际缺什么"导出,天然覆盖增量。
(原型项目当年是手工补了第二个 `eco2_missing.gds`,脚本化之后无需区分。)

## DRC 违例修法速查

跑法:`scripts/5_drc/run_drc.sh <主GDS> <ref目录>`。规则环境(`TECHDIR`、Rev6、
1P6M、TOPMETAL=30kA 等)由 `gb018_Source_File_drc_env` 驱动,config.sh 已指好。

| 违例类型 | 原因 | 修法 |
|---|---|---|
| `* density`(密度类) | 金属/poly 覆盖率不足 | Innovus `addFiller` 只救 poly/M1;高层金属用 stripe 加宽/加密,或脚本补 fill 矩形(原型在 M4 补了 320 个 2×2µm 矩形达标) |
| `CO.6b` 等点状规则 | 布线器在单元管脚密集区的极限操作 | 从 `.drc.results` 取 marker 坐标,在违例点旁补小块 M1 patch(可参考 gds_tool.py 的写入实现),重跑验证 |
| `MTTK/MT30/V5` 大量爆 | METAL6(顶层厚金属)被当普通布线层 | Innovus `setNanoRouteMode -routeTopRoutingLayer` 控制;若 CTS 已用 M6 则保持 6 并接受顶层规则约束(详见 docs/05) |
| 跑都跑不起来 | 参考 GDS 不全 | 重跑 gen_stdcell_refs.sh;看 drc_run.log 的 undefined cell 名 |

**判定标准**:`TOTAL DRC Results Generated: 0 (0)` 为干净;教程口径"只剩 density
也算较好情况",但原型项目证明 0 是可达的,建议以 0 为目标。

# dont_use_cell.tcl 调整要点

教程自带的 `dont_use_cell.tcl` 基本可用,但注意一个坑:

**不要把 DLY* 延迟单元禁掉。** 若模板里有 `set_dont_use ...X1`(按宽度批量禁)会连带禁掉
`DLY1X1/DLY2X1`,导致 `set_fix_hold clk` 无 delay cell 可插,hold 修不干净。修正:

```tcl
remove_attribute [get_lib_cells ${library_name}/DLY*] dont_use
```

另外建议保留禁用超大驱动(*X12/*X16/*X20)和 TBUF*/CLK*(时钟单元留给 CTS)。
ECO 阶段(eco_hold_fix.tcl)会另行 setDontUse 没有版图的 cell——两处目的不同,勿混淆。

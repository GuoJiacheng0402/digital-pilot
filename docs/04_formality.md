# Formality 形式验证(前端/后端)

配置只改 dc_setup.tcl 的引用路径,详见 scripts/2_formality/README.md。

| | reference | implementation |
|---|---|---|
| 前端(阶段2) | RTL | DC 网表(+ .svf) |
| 后端(阶段6) | DC 网表 | Innovus(或 ECO 后)网表 |

要点:
- `.svf`(综合时 DC 写出)必须给前端 Formality,否则重命名/重定时的 compare point
  匹配不上,大量 unmatched;
- 判定只认 `Verification SUCCEEDED`;
- 失败排查顺序:fm_match.rpt 的 unmatched points → 版本是否同步(最常见) →
  是否用错了库(.db 路径)。

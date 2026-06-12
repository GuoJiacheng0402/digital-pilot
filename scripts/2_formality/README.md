# Formality 前/后端形式验证

教程提供的 `run.sh + tcl/{dc_setup.tcl,fm.tcl}` 可直接用,只需改 `dc_setup.tcl`:

| 字段 | 前端(2_formality_postdc) | 后端(6_formality_postlayout) |
|---|---|---|
| reference | RTL (`../1_dc/rtl/*.v`) | DC 网表 (`../1_dc/output/*.v`) |
| implementation | DC 网表 + svf | Innovus 网表 (`../4_innovus/postlayout/*.v`) |
| 判定 | `Verification SUCCEEDED` | 同左 |

要点:
- SVF 文件(`1_dc/output/*.svf`)必须喂给前端 Formality,否则 compare point 匹配大量失败;
- ECO 之后跑后端 Formality 用 **ECO 后的网表**;
- 失败先看 `fm_match.rpt` 的 unmatched points,八成是网表/RTL 版本不同步。

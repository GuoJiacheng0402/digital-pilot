#!/bin/bash
# DigitalPilot · 一键汇总各阶段关键结论(验收前自查 / 写报告取数)
# 用法: 在项目根目录执行 path/to/collect_reports.sh
D=${DP_DESIGN:-$(ls 1_dc/output/*.qor.rpt 2>/dev/null | head -1 | xargs -n1 basename 2>/dev/null | cut -d. -f1)}
echo "== 设计: ${D:-unknown} =="
echo "-- RTL 仿真 --";     grep -hE "PASS|FAIL" 0_simulation_pre/run.log 2>/dev/null | tail -1
echo "-- DC setup/hold --"; grep -h "slack" 1_dc/output/*.timing.rpt 2>/dev/null | head -1; grep -h "slack" 1_dc/output/*.timing_min.rpt 2>/dev/null | head -1
echo "-- DC 面积 --";       grep -h "Total cell area" 1_dc/output/*.area.rpt 2>/dev/null
echo "-- Formality --";    grep -h "SUCCEEDED\|FAILED" 2_formality_postdc/fm.log 6_formality_postlayout/fm.log 2>/dev/null
echo "-- 前仿 --";          grep -hE "PASS|FAIL" 3_simulation_postdc/run.log 2>/dev/null | tail -1
echo "-- Innovus 物理检查 --"; grep -h "Verification Complete" 4_innovus/postlayout/reports/verifyGeometry.rpt 2>/dev/null
echo "-- DRC --";           grep -h "TOTAL DRC Results Generated" 5_DRC/*.summary 2>/dev/null | head -1
echo "-- LVS --";           grep -hE "^  (IN)?CORRECT" 5_LVS/*.lvs.report 2>/dev/null | head -1
echo "-- PT 三角 --";       for c in wst typ bst; do printf "  %s: " $c; grep -h "All Checks" 8_pt/reports/${c}_report_analysis_coverage.report 2>/dev/null || echo missing; done
echo "-- 后仿三角 --";      for c in wst typ bst; do printf "  %s: " $c; grep -hE "PASS|FAIL" 9_simulation_postlayout/run_${c}.log 2>/dev/null | tail -1 || echo missing; done

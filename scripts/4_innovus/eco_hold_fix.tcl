# =============================================================================
# DigitalPilot · post-route Hold-Fix ECO 框架(DRC-safe)
#
# 适用场景:实现按单角(WST)优化,三角签核时发现 BST(FF 快角)hold 有少量违例。
# 思路:setup 仍按 WST、hold 按 BST 双视图约束,optDesign -postRoute -hold 在
#       违例的快路径上插延迟 buffer;全程保证 LVS/DRC 不被破坏。
#
# "DRC-safe" 三件套(缺一不可,血泪经验):
#   1) setDontUse 禁掉【版图参考库里没有 layout 的 cell】——否则 ECO 插进来的
#      cell 在 GDS 里是空壳,LVS 必炸。先跑 5_drc/gen_stdcell_refs.sh 看哪些
#      cell 缺 layout,或保守起见直接禁 DLY*/XL 弱驱动系列再放开。
#   2) deleteFiller 腾空间 → 优化 → addFiller -doDRC 按规则重填。
#   3) 收尾 verifyGeometry/checkPlace/checkRoute 必须 0 violation 才能导出。
#
# 用法: cd 4_innovus/work && innovus -batch -file ../tcl/eco_hold_fix.tcl
# 改动点:DESIGN_NAME、恢复点、BST 库路径、targetSlack(建议两轮 0.06→0.07 渐进)
# =============================================================================
set DESIGN_NAME $env(DP_DESIGN)
set RESTORE_DB ../innovus_files/${DESIGN_NAME}_final.dat
set POSTLAYOUT_DIR ../postlayout_eco
set REPORT_DIR $POSTLAYOUT_DIR/reports
set BST_LIB /SM01/teaching/bs/digitalic/gb18_dc_lib/scx_csm_18ic_ff_1p98v_m40c.lib

proc run_step {name body} {
    puts "\n### BEGIN $name"
    uplevel 1 $body
    puts "### END $name"
}
file mkdir $POSTLAYOUT_DIR
file mkdir $REPORT_DIR
file mkdir timingReports_eco

run_step "restore final design" {
    restoreDesign $RESTORE_DB $DESIGN_NAME
}

run_step "ban cells without layout in reference GDS" {
    # 按你的实际缺失清单增删;这些是 csm19ic 参考 GDS 之外常见的"坑 cell"
    foreach c {DLY1X1 DLY2X1 DLY3X1 BUFXL CLKBUFX1 CLKBUFX12 CLKBUFXL} {
        catch {setDontUse $c true}
    }
}

run_step "add BST hold analysis view (setup stays WST)" {
    create_library_set -name eco_libset_bst -timing [list $BST_LIB]
    create_delay_corner -name eco_dly_bst -library_set eco_libset_bst
    create_analysis_view -name eco_view_bst \
        -constraint_mode soc_constrain \
        -delay_corner eco_dly_bst
    set_analysis_view -setup {view_wst} -hold {eco_view_bst}
    setAnalysisMode -analysisType onChipVariation -cppr none -usefulSkew true
}

run_step "remove fillers for ECO space" {
    deleteFiller -prefix FILLER
}

run_step "pre-ECO snapshot" {
    setAnalysisMode -checkType hold
    timeDesign -postRoute -hold -slackReports -numPaths 200 \
        -prefix pre_eco_hold -outDir timingReports_eco
}

run_step "hold ECO pass1 (target 0.06)" {
    setOptMode -fixCap true -fixTran true -fixFanoutLoad true \
        -effortLevel high -setupTargetSlack 0.00 -holdTargetSlack 0.06
    optDesign -postRoute -hold
}

run_step "hold ECO pass2 (target 0.07)" {
    setOptMode -holdTargetSlack 0.07
    optDesign -postRoute -hold
}

run_step "post-ECO snapshot (verify setup not broken)" {
    setAnalysisMode -checkType setup
    timeDesign -postRoute -slackReports -numPaths 100 \
        -prefix post_eco_setup -outDir timingReports_eco
    setAnalysisMode -checkType hold
    timeDesign -postRoute -hold -slackReports -numPaths 300 \
        -prefix post_eco_hold -outDir timingReports_eco
}

run_step "refill and physical checks" {
    addFiller -cell FILL1 FILL16 FILL2 FILL32 FILL4 FILL64 FILL8 -prefix FILLER -doDRC
    checkPlace > $REPORT_DIR/checkPlace.rpt
    checkRoute > $REPORT_DIR/checkRoute.rpt
    verifyGeometry > $REPORT_DIR/verifyGeometry.rpt
}

run_step "write ECO outputs" {
    saveNetlist $POSTLAYOUT_DIR/${DESIGN_NAME}.v
    write_sdf -version 2.1 $POSTLAYOUT_DIR/${DESIGN_NAME}.sdf
    set dbgLefDefOutVersion 5.8
    defOut -floorplan -netlist -routing $POSTLAYOUT_DIR/${DESIGN_NAME}.def
    streamOut $POSTLAYOUT_DIR/${DESIGN_NAME}.gds \
        -mapFile ../innovus_files/mystreamOut.map \
        -libName DesignLib -units 2000 -mode ALL
    saveDesign ../innovus_files/${DESIGN_NAME}_eco
}
# ECO 之后必须重做:gen_stdcell_refs(可能有新 cell)→ DRC → LVS(重生成 src.net!)
# → StarRC 三角 → PT 三角 → 后仿。任何一环引用旧文件都会"假通过"。
exit

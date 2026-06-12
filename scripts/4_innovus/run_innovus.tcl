# =============================================================================
# DigitalPilot · Innovus 批处理 APR 脚本(经实战验证的参数)
# 用法:  cd 4_innovus/work && innovus -batch -file ../tcl/run_innovus.tcl
# 改三处即可用于你的设计:
#   1) DESIGN_NAME(或 export DP_DESIGN)
#   2) (已泛化)pin placement 自动从设计端口推导,无需手改
#   3) floorPlan 利用率/边距(默认 0.50 util / 20um margin,适合 ~1.6 万 cell 设计)
# 关键经验(详见 docs/05_innovus_apr.md):
#   - routeTopRoutingLayer=6:CTS 时钟网可能走 METAL6,限 5 会报 NRDB-954
#   - addRing 横边 METAL1/竖边 METAL2;stripe 用 METAL4(出 DRC 可再调高)
#   - postRoute 优化 setup/hold 各两轮,targetSlack 0.08/0.10 是 OCV 缓冲甜蜜点
#   - 最后 streamOut -units 2000:后续 stdcell_ref 的 strmout 必须同样用 2000
# =============================================================================

set DESIGN_NAME $env(DP_DESIGN)   ;# 设计名,由 config.sh 注入(或直接改这里)
set POSTDC_DIR ../postdc
set POSTLAYOUT_DIR ../postlayout
set REPORT_DIR ../postlayout/reports

proc run_step {name body} {
    puts "\n### BEGIN $name"
    uplevel 1 $body
    puts "### END $name"
}

file mkdir $POSTLAYOUT_DIR
file mkdir $REPORT_DIR
file mkdir timingReports

run_step "import design" {
    set_global _enable_mmmc_by_default_flow $CTE::mmmc_default
    suppressMessage ENCEXT-2799

    set init_gnd_net VSS!
    set init_pwr_net VDD!
    set init_lef_file {../lef/csm18ic_6lm.lef ../lef/csm18ic_6lm_antenna.lef}
    set init_mmmc_file ../innovus_files/mmmc.view
    set init_top_cell $DESIGN_NAME
    set init_verilog $POSTDC_DIR/${DESIGN_NAME}.v

    init_design
}

run_step "floorplan" {
    getIoFlowFlag
    setIoFlowFlag 0
    floorPlan -site csm18site -r 0.85 0.50 20 20 20 20
}

run_step "global power connections" {
    clearGlobalNets
    globalNetConnect VDD! -type pgpin -pin VDD -inst *
    globalNetConnect VDD! -type tiehi -inst *
    globalNetConnect VSS! -type pgpin -pin VSS -inst *
    globalNetConnect VSS! -type tielo -inst *
}

run_step "power ring and stripes" {
    addRing -skip_via_on_wire_shape Noshape \
        -skip_via_on_pin Standardcell \
        -stacked_via_top_layer METAL6 \
        -type core_rings \
        -jog_distance 0.66 \
        -threshold 0.66 \
        -nets {VDD! VSS!} \
        -follow core \
        -stacked_via_bottom_layer METAL1 \
        -layer {bottom METAL1 top METAL1 right METAL2 left METAL2} \
        -width 5 \
        -spacing 2 \
        -offset 3

    addStripe -skip_via_on_wire_shape Noshape \
        -block_ring_top_layer_limit METAL5 \
        -max_same_layer_jog_length 0.88 \
        -padcore_ring_bottom_layer_limit METAL3 \
        -set_to_set_distance 80 \
        -skip_via_on_pin Standardcell \
        -stacked_via_top_layer METAL6 \
        -padcore_ring_top_layer_limit METAL5 \
        -spacing 1.8 \
        -xleft_offset 30 \
        -merge_stripes_value 0.66 \
        -layer METAL4 \
        -block_ring_bottom_layer_limit METAL3 \
        -width 1.8 \
        -nets {VDD! VSS!} \
        -stacked_via_bottom_layer METAL1
}

run_step "pin placement" {
    # 端口无关:运行时从设计自动推导输入/输出端口表(任何题目无需手改)。
    # 默认输入沿左边、输出沿右边、层 METAL3;按需调整 -side/-layer。
    set clk_port __CLK_PORT__
    set all_in  [dbGet [dbGet -p top.terms.direction input].name]
    set all_out [dbGet [dbGet -p top.terms.direction output].name]
    # clk 也属于 input,一并放左侧即可;如需单独安排可从列表剔除后另行 editPin
    setPinAssignMode -pinEditInBatch true
    editPin -fixedPin 1 -fixOverlap 1 -unit MICRON \
        -spreadDirection clockwise -side Left -layer 3 \
        -spreadType center -spacing 2 -pin $all_in
    editPin -fixedPin 1 -fixOverlap 1 -unit MICRON \
        -spreadDirection clockwise -side Right -layer 3 \
        -spreadType center -spacing 2 -pin $all_out
    setPinAssignMode -pinEditInBatch false
}

run_step "placement and pre-CTS optimization" {
    setMultiCpuUsage -localCpu 4 -cpuPerRemoteHost 1 -remoteHost 0 -keepLicense true
    setDistributeHost -local
    setPlaceMode -fp false
    placeDesign

    setOptMode -fixCap true -fixTran true -fixFanoutLoad true
    optDesign -preCTS

    addTieHiLo -cell {TIEHI TIELO} -prefix LTIE
}

run_step "clock tree synthesis" {
    create_route_type -name leaf_rule -top_preferred_layer METAL4 \
        -bottom_preferred_layer METAL3
    create_route_type -name trunk_rule -top_preferred_layer METAL4 \
        -bottom_preferred_layer METAL3 \
        -shield_net VSS!
    create_route_type -name top_rule -top_preferred_layer METAL4 \
        -bottom_preferred_layer METAL3 \
        -shield_net VSS!
    set_ccopt_property -net_type leaf route_type leaf_rule
    set_ccopt_property -net_type trunk route_type trunk_rule
    set_ccopt_property -net_type top route_type top_rule

    setAnalysisMode -cppr none \
        -clockGatingCheck true \
        -timeBorrowing true \
        -useOutputPinCap true \
        -sequentialConstProp false \
        -timingSelfLoopsNoSkew false \
        -enableMultipleDriveNet true \
        -clkSrcPath true \
        -warn true \
        -usefulSkew true \
        -analysisType onChipVariation \
        -log true

    set_ccopt_property buffer_cells {CLKBUFX1 CLKBUFX2 CLKBUFX3 CLKBUFX4}
    set_ccopt_property inverter_cells {CLKINVX1 CLKINVX2 CLKINVX3 CLKINVX4}
    set_ccopt_property use_inverters true
    set_ccopt_property target_max_trans 250ps
    set_ccopt_property target_skew 50ps

    create_ccopt_clock_tree_spec -file ccopt.spec
    ccopt_design -CTS
    report_ccopt_clock_trees -file $REPORT_DIR/clock_trees.rpt
    report_ccopt_skew_groups -file $REPORT_DIR/skew_groups.rpt
}

run_step "post-CTS optimization" {
    setOptMode -fixCap true -fixTran true -fixFanoutLoad true
    optDesign -postCTS
    optDesign -postCTS -hold
}

run_step "routing" {
    sroute -connect {blockPin padPin padRing corePin floatingStripe} \
        -layerChangeRange {METAL1 METAL5} \
        -blockPinTarget {nearestTarget} \
        -padPinPortConnect {allPort oneGeom} \
        -padPinTarget {nearestTarget} \
        -corePinTarget {firstAfterRowEnd} \
        -floatingStripeTarget {blockring padring ring stripe ringpin blockpin followpin} \
        -allowJogging 1 \
        -crossoverViaLayerRange {METAL1 METAL6} \
        -nets {VDD! VSS!} \
        -allowLayerChange 1 \
        -blockPin useLef \
        -targetViaLayerRange {METAL1 METAL6}

    setNanoRouteMode -quiet -routeTopRoutingLayer 6
    # ^ was 5 originally but CTS now routes clock nets on METAL6; raising the top
    # routing layer to 6 avoids NRDB-954 conflict.
    setNanoRouteMode -quiet -timingEngine {}
    setNanoRouteMode -quiet -routeWithTimingDriven true
    setNanoRouteMode -quiet -routeWithSiDriven true
    setNanoRouteMode -quiet -routeWithSiPostRouteFix 1
    setNanoRouteMode -quiet -routeBottomRoutingLayer default
    setNanoRouteMode -quiet -drouteEndIteration default
    routeDesign -globalDetail
}

run_step "post-route optimization" {
    # WST single-corner sign-off with setup/hold target slack cushion for OCV.
    # +0.05 setup target compensates WST OCV derate. +0.10 hold target gives
    # comfortable cushion since WST is the easiest hold corner.
    setOptMode -fixCap true -fixTran true -fixFanoutLoad true \
        -effortLevel high \
        -setupTargetSlack 0.08 \
        -holdTargetSlack 0.10
    optDesign -postRoute
    optDesign -postRoute -hold
    optDesign -postRoute -setup
    optDesign -postRoute -hold
}

run_step "timing reports" {
    # Single typ-corner analysis (matches teacher's tutorial line 1442 example).
    setAnalysisMode -analysisType onChipVariation
    setAnalysisMode -checkType setup
    timeDesign -postRoute -pathReports -drvReports -slackReports -numPaths 50 \
        -prefix ${DESIGN_NAME}_postRoute \
        -outDir timingReports
    report_timing -check_type setup -max_paths 10 > $REPORT_DIR/worst_setup_paths.rpt

    setAnalysisMode -checkType hold
    timeDesign -postRoute -hold -pathReports -slackReports -numPaths 50 \
        -prefix ${DESIGN_NAME}_postRoute \
        -outDir timingReports
    report_timing -early -max_paths 10 > $REPORT_DIR/worst_hold_paths.rpt
}

run_step "filler and checks" {
    addFiller -cell FILL1 FILL16 FILL2 FILL32 FILL4 FILL64 FILL8 -prefix FILLER -doDRC

    checkPlace > $REPORT_DIR/checkPlace.rpt
    checkRoute > $REPORT_DIR/checkRoute.rpt
    verifyGeometry > $REPORT_DIR/verifyGeometry.rpt
}

run_step "write outputs" {
    saveNetlist $POSTLAYOUT_DIR/${DESIGN_NAME}.v
    write_sdf -version 2.1 $POSTLAYOUT_DIR/${DESIGN_NAME}.sdf
    write_sdf -version 3.0 $POSTLAYOUT_DIR/${DESIGN_NAME}_v3.0.sdf

    set dbgLefDefOutVersion 5.8
    global dbgLefDefOutVersion
    set dbgLefDefOutVersion 5.8
    defOut -floorplan -netlist -routing $POSTLAYOUT_DIR/${DESIGN_NAME}.def

    streamOut $POSTLAYOUT_DIR/${DESIGN_NAME}.gds \
        -mapFile ../innovus_files/mystreamOut.map \
        -libName DesignLib \
        -units 2000 \
        -mode ALL

    saveDesign ../innovus_files/${DESIGN_NAME}_final
}

exit

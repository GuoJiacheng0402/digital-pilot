# DigitalPilot · Formality 主脚本(最终可行版,前后端通用)
source -echo -verbose ./tcl/dc_setup.tcl

# setup for handing undriven signals in the design
set verification_set_undriven_signals x 

# to treat simulation and synthesis mismatch messages as warning
set_app_var hdlin_error_on_mismatch_message false

#read in the SVF file
set_svf ${RESULTS_DIR}/${DCRM_SVF_OUTPUT_FILE}

# read in the SVF file
read_db -technology_library ${ADDITIONAL_LINK_LIB_FILES}

# read in the Ref design
read_verilog -r ${RTL_SOURCE_FILES} -work_library WORK
set_top r:/WORK/${DESIGN_NAME}

# read in the Impl design
read_verilog -i ${RESULTS_DIR}/${DCRM_FINAL_VERILOG_OUTPUT_FILE}
set_top i:/WORK/${DESIGN_NAME}

# match compare points and report unmatched points
match
report_unmatched_points > ./reports/unmatch_points.rpt
report_matched_points > fm_match.rpt

# Verify and report
if { ![verify] }  {  
  save_session -replace ${REPORTS_DIR}/${FMRM_FAILING_SESSION_NAME}
  report_failing_points > ${REPORTS_DIR}/${FMRM_FAILING_POINTS_REPORT}
  report_aborted > ${REPORTS_DIR}/${FMRM_ABORTED_POINTS_REPORT}
  analyze_points -all > ${REPORTS_DIR}/${FMRM_ANALYZE_POINTS_REPORT}
}

exit

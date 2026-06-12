# DigitalPilot · PT 签核约束(端口无关;与 DC 版差异:无 set_fix_hold/max_fanout,
# CTS 后由真实时钟树承担)。占位符由 new_project.sh/run_3corner.sh 替换。
set CLK __CLK_PORT__
create_clock -name $CLK -period __CLK_PERIOD__ -waveform {0 __HALF_PERIOD__} [get_ports $CLK]
set_clock_uncertainty -setup __UNCERT_SETUP__ [get_clocks $CLK]
set_clock_uncertainty -hold  __UNCERT_HOLD__  [get_clocks $CLK]
set_input_delay  -clock [get_clocks $CLK] -max [expr __CLK_PERIOD__/2.0] \
    [remove_from_collection [all_inputs] [get_ports $CLK]]
set_output_delay -clock [get_clocks $CLK] -max [expr __CLK_PERIOD__/2.0] [all_outputs]

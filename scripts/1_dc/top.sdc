#######################################################################
# DigitalPilot · DC 综合约束模板(端口无关,适配任意题目)
# new_project.sh 会替换 __CLK_PORT__/__CLK_PERIOD__/__HALF_PERIOD__/
# __UNCERT_SETUP__/__UNCERT_HOLD__;也可手改。
# 要点:reset 等所有非时钟输入都被 all_inputs 形式覆盖(题面禁止漏约束);
#      hold uncertainty 以题面为准(本课程 0.3ns;教程截图 1ns 是笔误)。
#######################################################################
set CLK __CLK_PORT__
create_clock -name $CLK -period __CLK_PERIOD__ -waveform {0 __HALF_PERIOD__} [get_ports $CLK]

set_clock_uncertainty -setup __UNCERT_SETUP__ [get_clocks $CLK]
set_clock_uncertainty -hold  __UNCERT_HOLD__  [get_clocks $CLK]

# 除时钟外全部输入(含 reset)统一约束 —— 端口无关写法,任何题目可用
set_input_delay  -clock [get_clocks $CLK] -max [expr __CLK_PERIOD__/2.0] \
    [remove_from_collection [all_inputs] [get_ports $CLK]]
set_output_delay -clock [get_clocks $CLK] -max [expr __CLK_PERIOD__/2.0] [all_outputs]

set_max_fanout 4 [get_ports $CLK]
set_fix_hold $CLK

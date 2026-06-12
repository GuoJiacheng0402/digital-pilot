# DigitalPilot · VCS RTL 行为仿真(教程 0_simulation_pre)
# 用法: make run_vcs / make vd / make clr
src_list = filelist
simv_name = simv
V = /SM01/eda/synopsys/verdi/P-2019.06-SP1/share/PLI/VCS/linux64

NOR_VCS = vcs -full64 -sverilog +v2k -timescale=1ns/1ps -debug_all \
          +neg_tchk +vcs+flush+all -o $(simv_name) -l compile.log -f $(src_list).f
VERDI_SW = -P $(V)/novas.tab $(V)/pli.a
RUN_VER = -R +fsdb+autoflush -l run.log

run_vcs:
	$(NOR_VCS) $(VERDI_SW) $(RUN_VER)

vd:
	verdi -sv -f $(src_list).f -ssf *.fsdb -nologo

clr:
	rm -rf csrc *.daidir $(simv_name) *simv* ucli* *.vpd *.vdb *.log *.fsdb *novas* *.key

# DigitalPilot · 前仿(DC 网表 + DC SDF)。filelist 需追加标准单元模型:
#   /SM01/teaching/bs/digitalic/gb18_dc_lib/csm18ic.v
# tb 中加: $sdf_annotate("./rtl/DESIGN.sdf", dut, , "sdf.log", "MAXIMUM");
src_list = filelist
simv_name = simv
V = /SM01/eda/synopsys/verdi/P-2019.06-SP1/share/PLI/VCS/linux64

NOR_VCS = vcs -full64 -sverilog +v2k -timescale=1ns/1ps -debug_all +vcs+flush+all \
          +sdfverbose +negdelay +neg_tchk -o $(simv_name) -l compile.log -f $(src_list).f
VERDI_SW = -P $(V)/novas.tab $(V)/pli.a
RUN_VER = -R +fsdb+autoflush -l run.log

run_vcs:
	$(NOR_VCS) $(VERDI_SW) $(RUN_VER)
vd:
	verdi -sv -f $(src_list).f -ssf *.fsdb -nologo
clr:
	rm -rf csrc *.daidir $(simv_name) *simv* ucli* *.vpd *.vdb *.log *.fsdb *novas* *.key sdf.log

# 环境准备与工具坑

## source 套路(每个新终端都要做)

```sh
source /SM01/eda/env_set/bashrc_synopsys   # VCS/DC/Formality/StarRC/PT
source /SM01/eda/env_set/bashrc_cds        # Virtuoso/Innovus/strmout/verilog2oa
source /SM01/eda/env_set/bashrc_mentor     # Calibre
```

按需 source,但注意:
- **DRC 与 LVS 的规则环境互斥**(TECHDIR 指不同目录),同一 shell 不要先 source DRC env
  再 source LVS env 接着跑——会拿错 deck。本仓库 run_drc.sh/run_lvs.sh 各管各的;
- GUI 工具(virtuoso/innovus 图形界面)需要 VNC 桌面;所有 DigitalPilot 脚本均为
  批处理,SSH 即可;
- `vcs: Command not found` = 忘 source bashrc_synopsys(最高频错误,没有之一);
- Calibre 偶发 license 超时:`export MGLS_LICENSE_FILE=/SM01/eda/license/SMW5/mentor/mentor_lic.dat`。

## 版本注意

- Innovus 教学环境常见 15.2 与 19.1 并存(bashrc_cds 里 PATH 决定)。本仓库脚本在
  15.2 验证;19.1 个别 setOptMode 参数名有差异,脚本头部 `puts [get_product_version]`
  可先确认;
- Virtuoso 为 IC6.1.8;strmout/verilog2oa/conn2sch/si 随 IC 安装,source bashrc_cds 后可用;
- GDS 处理(gen_stdcell_refs / add_power_labels)用仓库自带的零依赖 gds_tool.py,服务器原生 python3(3.6+)即可,**无需安装任何第三方包**;
- **EDA 环境会弄坏 python3**:source bashrc_cds 之后 python3 会报 symbol lookup error(LD_LIBRARY_PATH/PYTHONHOME 被污染)。在 EDA shell 里调 python 一律用 config.sh 的 `dp_python`(env -u 三连 unset)——各脚本已内置。

## cds.lib 概念(GUI 流程会用到)

Virtuoso 靠启动目录的 `cds.lib` 解析库名。空白目录起 virtuoso 看不到 PDK 是正常的,补:

```
DEFINE chrt018ull_hv30v /SM01/teaching/bs/digitalic/IC_ISO_1P6M_2K_2p0fF_B_30K/chrt018ull_hv30v
DEFINE csm18ic          /SM01/teaching/bs/digitalic/IC_ISO_1P6M_2K_2p0fF_B_30K/csm18ic
DEFINE csm19ic          /SM01/teaching/bs/digitalic/IC_ISO_1P6M_2K_2p0fF_B_30K/csm19ic
```

改完 cds.lib 必须**重启 Virtuoso** 才生效。批处理脚本会自动生成临时 cds.lib,无需手配。

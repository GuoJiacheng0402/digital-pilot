# Changelog

本项目的重要变更记录于此。格式参考 [Keep a Changelog](https://keepachangelog.com/)，
版本号遵循 [语义化版本](https://semver.org/lang/zh-CN/)。

## [1.0.0] - 2026-06-12

首个公开整理版本。提炼自 2026 年春季学期数字集成电路课程设计，目标是在不分发课程
题目答案、不分发 PDK/EDA 受限资产的前提下，沉淀一套可复跑的 RTL-to-GDS 全流程脚本与
方法学知识库。

### 新增

- **统一命令入口 `bin/dp`**：提供 `new`、`doctor`、`status`、`ports`、`lut`、`gds`、
  `refs`、`labels`、`srcnet`、`drc`、`lvs`、`spef`、`pt`、`postsim`、`pack` 等子命令。
- **0-9 阶段脚本模板 `scripts/`**：覆盖 RTL 仿真、DC 综合、Formality、DC 网表前仿、
  Innovus APR、Calibre DRC/LVS、StarRC 三角 SPEF、PrimeTime 三角签核、三角后仿 GLS。
- **物理验证自动化**：
  - `scripts/5_drc/gen_stdcell_refs.sh` 自动生成标准单元参考 GDS；
  - `scripts/5_lvs/gen_src_netlist.sh` 自动生成 LVS 源网表；
  - `scripts/5_lvs/add_power_labels.py` 从 DEF/GDS 自动注入 `VDD!` / `VSS!` 标签；
  - `scripts/utils/gds_tool.py` 提供零依赖 GDS 检查与标签处理能力。
- **项目脚手架 `scripts/utils/new_project.sh`**：按教程目录结构生成新设计工作区，实例化 SDC、
  Innovus、Formality、PT、StarRC、后仿等模板。
- **辅助工具**：`list_ports.py`、`gen_lut.py`、`collect_reports.sh`、
  `make_submit_package.sh`。
- **中文知识库 `docs/`**：包含全流程总览、环境、RTL 仿真、DC、Formality、Innovus、Calibre
  DRC/LVS、StarRC/PT、后仿、三角方法学、GUI 演示、验收清单、AI 协作、RTL 方法学和排错表。
- **AI 助手入口**：`AGENTS.md`、`skills/digitalpilot`、`skills/lib-detective`。
- **开源发布元文件**：README 中英文版、LICENSE、NOTICE、ACADEMIC_USE、CITATION、CONTRIBUTING、
  GitHub Actions 轻量 CI、banner 与流程图。

### 已验证的方法学结果

- 原型项目 `function_gen` 曾以该流程达成 DC setup/hold MET、Formality 前后端 SUCCEEDED、
  DRC 0、LVS CORRECT、PT wst/typ/bst 三角 0 violated、后仿三角 PASS，并保持 RTL/前仿/后仿
  逐拍一致。

### 说明

- 本仓库不包含任何课程题目的 RTL 答案。
- 本仓库不包含 PDK、标准单元库、EDA 工具、license 文件或 Calibre rule deck；所有相关资产
  均通过学校服务器路径引用。
- 公开前已整理署名、引用、贡献和学术使用说明。

[1.0.0]: https://github.com/GuoJiacheng0402/digital-pilot/releases/tag/v1.0.0

# 贡献指南

欢迎贡献 DigitalPilot。本项目的核心价值是把数字 IC 课程设计中可复现、可验证、可交接的
工程流程沉淀下来，尤其是那些教程没有写清楚但实际最容易卡住的 DRC/LVS、三角签核和后仿
细节。

## 可以贡献什么

- **新的问题与解决方案**：补充到 [`docs/faq_pitfalls.md`](docs/faq_pitfalls.md)，尽量沿用
  「现象/报错 -> 原因 -> 修法 -> 验证」的格式。
- **阶段流程改进**：补充或修正 `scripts/0_sim_rtl` 到 `scripts/9_sim_postlayout` 的脚本，
  并在对应文档中说明输入、输出和通过判定。
- **环境差异记录**：不同服务器、工具版本、库路径或 license 设置的差异，优先补到
  [`docs/01_environment.md`](docs/01_environment.md)。
- **AI 助手上下文**：若某个阶段的 gate 或决策树更清楚了，同步更新 [`AGENTS.md`](AGENTS.md)
  与 `skills/`。
- **文档订正**：错别字、失效链接、命令参数、报告判定行、路径占位符等。

## 提交前请确认

1. **不包含任何敏感信息。** 请勿提交真实服务器 IP、账号、学号、密码、license 地址、VNC
   显示号、内网主机名、私钥或未脱敏日志。真实值只应存在于本地 shell 配置、`.env` 或
   `*.local.*` 文件中。
2. **不包含课程题目的 RTL 答案。** 本仓库发布流程脚本与方法学，不分发具体课程设计答案。
   示例可以描述阶段判定行与项目形态，但不要提交可直接作为作业答案的 RTL。
3. **不包含受限 PDK/EDA 资产。** 不要提交 `.lib`、`.db`、LEF/GDS 工艺库、Calibre deck、
   license 文件或厂商模型。仓库中只保留服务器路径和占位符。
4. **每个通过结论都有报告原文。** 文档或 PR 描述中声称 DRC 0、LVS CORRECT、PT 0 violated、
   GLS PASS 时，请给出报告文件路径与判定行。
5. **ECO 后下游全重跑。** 如果改动影响网表、DEF、GDS、SDF 或 SPEF，请按 docs/00 的状态机
   更新所有受影响阶段。

## 推荐流程

1. Fork 仓库并创建分支：`git checkout -b fix/your-topic`。
2. 小步提交，commit message 说明阶段、问题和验证方式。
3. 发起 Pull Request，描述改动动机、影响范围、已跑检查和仍需真实 EDA 环境验证的部分。

## 本地轻量检查

以下检查不需要 EDA 服务器，适合提交前先跑：

```bash
bash -n bin/dp
find scripts -name '*.sh' -print0 | xargs -0 -n1 bash -n
python3 -m compileall -q scripts tools
bin/dp help
```

真实流程仍以学校服务器上的阶段报告为准。

## 许可

提交贡献即表示你同意你的贡献以本项目的 [GPL-3.0](LICENSE) 许可证发布，并保留 GPL-3.0
第 7(b) 条所允许的署名保留附加条款。

# 学术使用与署名要求 · Academic Use & Citation Policy

本项目（DigitalPilot）是一份面向数字 IC 设计全流程的开源工具与知识库，提炼自一次
完整的课程设计实践。我们欢迎你在学习、课程设计、毕业设计与科研中使用它；当你的成果使用
了本项目的代码、文档、约定或方法时，请明确署名引用。

## 1. 何时需要署名

只要你在以下任何场景中使用了本项目的**代码、文档、约定、脚本或方法论**（无论是直接使用、
修改后使用，还是借鉴其思路与流程），都应在相应成果中明确署名引用本项目：

- 课程设计、课程报告、课程作业；
- 毕业设计 / 毕业论文 / 学位论文；
- 学术论文、技术报告、公开演示；
- 任何基于本项目的二次开发或衍生作品。

## 2. 署名要求的两重依据

1. **许可条款**：本项目以 **GNU GPL v3.0** 发布，并附带 **GPL-3.0 第 7(b) 条
   「署名保留」附加条款**（见 [`LICENSE`](LICENSE) 顶部）。复用本项目内容时应保留作者署名，
   不应移除或弱化已有的署名声明。
2. **学术诚信**：在学术成果中使用他人已公开的工作而不加引用/署名，可能构成不当引用或剽窃；
   具体认定以所在院校、课程或期刊的学术诚信规范为准。

> 简而言之：**如果本项目对你的成果产生了实质性帮助，请清楚说明并给出引用。**

## 3. 如何署名（可直接复制）

**中文（报告/论文正文或致谢、参考文献中）：**

> 本工作使用了开源项目 DigitalPilot（作者 GuoJiacheng，华南理工大学微电子学院，2026）。
> 项目地址：https://github.com/GuoJiacheng0402/digital-pilot

**英文 / BibTeX 风格：**

```bibtex
@software{DigitalPilot2026,
  author  = {Guo, Jiacheng},
  title   = {DigitalPilot: An AI-agent-driven Cadence digital IC RTL-to-GDS flow},
  year    = {2026},
  url      = {https://github.com/GuoJiacheng0402/digital-pilot},
  note    = {School of Microelectronics, South China University of Technology}
}
```

GitHub 会根据仓库根目录的 [`CITATION.cff`](CITATION.cff) 自动生成 "Cite this repository"，
可直接复制其中的引用格式。

## 4. 关于本项目的实现

本项目自身源码、文档与工具均为独立整理和实现，未复制、嵌入或派生自第三方项目代码。
项目通过公开命令行接口调用学校服务器上已安装的 VCS、Design Compiler、Formality、
Innovus、Calibre、StarRC、PrimeTime 等 EDA 工具，并仅以路径方式引用工艺库、规则文件与
标准单元库。详见 [`NOTICE`](NOTICE)。

---

*若对署名方式有疑问，可在仓库提交 Issue 询问。*

# DigitalPilot

**An AI-agent-friendly Cadence digital IC course-design flow for the School of
Microelectronics EDA servers at South China University of Technology (SCUT).**

DigitalPilot turns a GUI-heavy digital IC coursework flow into a reproducible
script set:

```text
RTL -> VCS -> Design Compiler -> Formality -> Innovus -> Calibre DRC/LVS
    -> StarRC three-corner SPEF -> PrimeTime signoff -> post-layout GLS
```

> The Chinese [`README.md`](README.md), [`AGENTS.md`](AGENTS.md), and
> [`docs/`](docs/) are the primary documentation. This page is a compact English
> overview for readers evaluating or citing the project.

<p align="center">
  <img src="assets/banner.svg" alt="DigitalPilot" width="100%"/>
</p>

<p align="center">
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-GPLv3-blue.svg" alt="GPLv3"/></a>
  <img src="https://img.shields.io/badge/python-3.6%2B%20(no%20deps)-blue.svg" alt="Python 3.6+"/>
  <img src="https://img.shields.io/badge/PDK-GF180%20(csm18ic%2Fcsm19ic)-orange" alt="GF180"/>
  <img src="https://img.shields.io/badge/EDA-VCS%20%C2%B7%20DC%20%C2%B7%20Innovus%20%C2%B7%20Calibre%20%C2%B7%20PT-blueviolet" alt="EDA"/>
</p>

<p align="center">
  <a href="README.md">Chinese</a> |
  <a href="docs/00_overview.md">Docs</a> |
  <a href="AGENTS.md">AGENTS</a> |
  <a href="docs/faq_pitfalls.md">Troubleshooting</a>
</p>

## What It Provides

- **RTL-to-GDS scripts** for the 0-9 coursework stages: RTL simulation,
  synthesis, Formality, post-DC simulation, Innovus APR, Calibre DRC/LVS,
  StarRC extraction, PrimeTime signoff, and post-layout gate-level simulation.
- **Calibre DRC/LVS automation** for the hard parts omitted by the GUI tutorial:
  standard-cell reference GDS generation, LVS source netlist generation, and
  automatic `VDD!` / `VSS!` power labels.
- **Three-corner signoff discipline** covering wst/typ/bst SPEF, PrimeTime
  checks, and post-layout GLS, with ECO guidance when bst hold paths fail.
- **Topic-independent helpers** such as project scaffolding, port extraction for
  testbenches, LUT generation, GDS inspection, report collection, and submit
  package creation.
- **AI-agent context** through [`AGENTS.md`](AGENTS.md) and the `skills/`
  directory, so coding agents know the expected gates and report lines before
  claiming a stage has passed.

## Scope And Boundaries

DigitalPilot targets the SCUT School of Microelectronics teaching server
environment under `/SM01/...`. The default paths in
[`scripts/00_env/config.sh`](scripts/00_env/config.sh) are written for that
environment and must be adapted for other installations.

The repository contains flow scripts, documentation, methodology notes, and
agent skills. It does **not** contain commercial PDK files, rule decks, standard
cell libraries, EDA binaries, license files, or any coursework RTL answer. Those
assets remain the property of their respective owners and are only referenced by
server-side paths.

## Quick Start

```bash
git clone https://github.com/GuoJiacheng0402/digital-pilot.git ~/DigitalPilot
echo 'export PATH=$PATH:~/DigitalPilot/bin' >> ~/.bashrc
source ~/.bashrc

dp doctor                         # check tools, libraries, and Python
dp new ~/my_design my_top clk 5.0 # create a coursework-style workspace
source ~/my_design/dp_env.sh
cd ~/my_design/0_simulation_pre
make run_vcs
```

Useful commands:

```bash
dp ports rtl/my_top.v --fmt tb
dp status
dp refs <main.gds> <ref_dir>
dp labels --gds <main.gds> --def <design.def> --out <labeled.gds>
dp srcnet <netlist.v> <out_dir>
dp drc <main.gds> <ref_dir>
dp lvs <labeled.gds> <src.net> <ref_dir>
dp pack ~/my_design submit.zip
```

## Documentation Map

| Goal | Document |
|---|---|
| Full flow overview and stage gates | [`docs/00_overview.md`](docs/00_overview.md) |
| Environment setup and EDA shell pitfalls | [`docs/01_environment.md`](docs/01_environment.md) |
| RTL simulation and testbench alignment | [`docs/02_rtl_simulation.md`](docs/02_rtl_simulation.md) |
| Design Compiler synthesis and constraints | [`docs/03_dc_synthesis.md`](docs/03_dc_synthesis.md) |
| Formality checks | [`docs/04_formality.md`](docs/04_formality.md) |
| Innovus APR and ECO methodology | [`docs/05_innovus_apr.md`](docs/05_innovus_apr.md) |
| Calibre DRC and standard-cell reference GDS | [`docs/06_calibre_drc.md`](docs/06_calibre_drc.md) |
| Calibre LVS, source netlists, and power labels | [`docs/07_calibre_lvs.md`](docs/07_calibre_lvs.md) |
| StarRC and PrimeTime three-corner flow | [`docs/08_starrc_pt.md`](docs/08_starrc_pt.md) |
| Post-layout GLS and SDF annotation | [`docs/09_post_sim.md`](docs/09_post_sim.md) |
| Three-corner methodology | [`docs/10_three_corner.md`](docs/10_three_corner.md) |
| GUI demo runbook | [`docs/11_gui_runbook.md`](docs/11_gui_runbook.md) |
| Acceptance and submit checklist | [`docs/12_acceptance_checklist.md`](docs/12_acceptance_checklist.md) |
| AI collaboration workflow | [`docs/13_ai_workflow.md`](docs/13_ai_workflow.md) |
| RTL methodology for new topics | [`docs/14_rtl_methodology.md`](docs/14_rtl_methodology.md) |
| Troubleshooting by symptom | [`docs/faq_pitfalls.md`](docs/faq_pitfalls.md) |

## Repository Layout

```text
DigitalPilot/
|-- README.md / README.en.md / AGENTS.md
|-- LICENSE / NOTICE
|-- ACADEMIC_USE.md / CITATION.cff
|-- CONTRIBUTING.md / CHANGELOG.md
|-- bin/dp
|-- scripts/
|-- docs/
|-- skills/
|-- tools/remote/
|-- examples/
`-- assets/
```

## Originality And Citation

DigitalPilot was distilled from a complete 2026 spring digital IC course-design
run at SCUT. The repository's own scripts, documentation, agent skills, and
methodology notes are independently authored. The project uses public command
line interfaces of the installed EDA tools and references server-installed PDK
and library paths; it does not redistribute those third-party assets.

If DigitalPilot helps your coursework, thesis, report, or derivative project,
please cite it. See [`ACADEMIC_USE.md`](ACADEMIC_USE.md) and
[`CITATION.cff`](CITATION.cff).

## License

DigitalPilot is released under GNU GPL v3.0 with an additional GPL-3.0 section
7(b) attribution-preservation term. See [`LICENSE`](LICENSE) and [`NOTICE`](NOTICE).

#!/bin/bash
# =============================================================================
# DigitalPilot · 本地⇄服务器 bridge(无密码硬编码,基于 ssh key)
#
# 首次配置(本地执行一次):
#   ssh-keygen -t ed25519            # 已有 key 可跳过
#   ssh-copy-id <学号>@<服务器IP>     # 之后免密
#   export DP_SSH_HOST=<学号>@<服务器IP>   # 写进 ~/.zshrc / ~/.bashrc
#
# 用法:
#   dprun.sh push <本地目录> <远端目录>     # 同步代码上去(排除 EDA 产物)
#   dprun.sh pull <远端路径> <本地路径>     # 拉报告/日志回来
#   dprun.sh exec '<命令>'                 # 远端执行(自动 bash -lc,环境可 source)
#   dprun.sh stage <项目目录> <0|1|2|3|7|8> # 远端跑指定阶段并回显判定行
# =============================================================================
set -e
HOST=${DP_SSH_HOST:?请先 export DP_SSH_HOST=<user>@<server>}
SSH="ssh -o ServerAliveInterval=15 $HOST"
case "${1:?用法: dprun.sh push|pull|exec|stage ...}" in
  push)
    rsync -az --delete \
      --exclude '*.fsdb' --exclude 'csrc' --exclude '*.daidir' --exclude 'simv*' \
      --exclude 'svdb*' --exclude 'work/' --exclude 'timingReports*' \
      "${2:?本地目录}/" "$HOST:${3:?远端目录}/"
    echo "pushed $2 -> $HOST:$3";;
  pull)
    scp -r "$HOST:${2:?远端路径}" "${3:?本地路径}"
    echo "pulled $2 -> $3";;
  exec)
    $SSH "bash -lc '${2:?命令}'";;
  stage)
    PROJ=${2:?项目目录}; ST=${3:?阶段号}
    case $ST in
      0) CMD="cd $PROJ/0_simulation_pre && make run_vcs >/dev/null 2>&1; grep -hE 'PASS|FAIL' run.log | tail -1";;
      1) CMD="cd $PROJ/1_dc && ./run.sh >/dev/null 2>&1; grep -h 'slack' output/*.timing.rpt | head -1";;
      2) CMD="cd $PROJ/2_formality_postdc && ./run.sh >/dev/null 2>&1; grep -h 'SUCCEEDED\\|FAILED' fm.log";;
      3) CMD="cd $PROJ/3_simulation_postdc && make run_vcs >/dev/null 2>&1; grep -hE 'PASS|FAIL' run.log | tail -1";;
      7) CMD="cd $PROJ/7_StarRC && ./run_3corner.sh 2>&1 | tail -3";;
      8) CMD="cd $PROJ/8_pt && ./run_3corner.sh 2>&1 | tail -4";;
      *) echo "阶段 $ST 需登录服务器交互执行(4=innovus/5=calibre/9=后仿见 docs)"; exit 1;;
    esac
    $SSH "bash -lc 'source /SM01/eda/env_set/bashrc_synopsys; $CMD'";;
  *) echo "未知子命令: $1"; exit 1;;
esac

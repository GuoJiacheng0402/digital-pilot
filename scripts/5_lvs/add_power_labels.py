#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""DigitalPilot · 自动往 GDS 注入 VDD!/VSS! 电源标签(LVS 必需,零依赖)。

背景:Innovus 的 GDS 是纯几何,没有电源网名字,LVS 报 missing port VDD!/VSS!。
本脚本:解析 DEF 的 SPECIALNETS 找到两个电源网各自 METAL1 环的 y 坐标(net 归属
来自 DEF,从机制上杜绝"标反"),再调用 gds_tool.py 在顶层插入文字标签
(MET1 label 层 = GDS 34/10)。纯标准库实现,服务器原生 python3 可跑。

用法:
  ./add_power_labels.py --gds main.gds --def main.def --out labeled.gds \
      [--power VDD! --ground VSS!] [--layer 34 --texttype 10] [--x 50.0]
"""
import argparse
import os
import re
import subprocess
import sys

GDS_TOOL = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                        "..", "utils", "gds_tool.py")


def find_ring_y(def_path, net, layer="METAL1"):
    """在 DEF SPECIALNETS 里找 net 的 layer 层 ring/followpin/corewire 段 y(um)。"""
    dbu = 2000.0
    in_net = False
    ys = []
    pat_units = re.compile(r"UNITS\s+DISTANCE\s+MICRONS\s+(\d+)")
    pat_seg = re.compile(re.escape(layer) +
                         r"\s+(\d+)\s+\+\s+SHAPE\s+(\w+)\s*\(\s*(-?\d+)\s+(-?\d+)\s*\)")
    with open(def_path) as f:
        for line in f:
            m = pat_units.search(line)
            if m:
                dbu = float(m.group(1))
            if line.startswith("- " + net):
                in_net = True
                continue
            if in_net:
                if line.startswith("- ") or line.strip() == ";":
                    break
                m = pat_seg.search(line)
                if m and m.group(2).upper() in ("RING", "FOLLOWPIN", "COREWIRE"):
                    ys.append(int(m.group(4)) / dbu)
    if not ys:
        raise SystemExit("DEF 里没找到 net %s 的 %s ring/followpin 段" % (net, layer))
    return min(ys)  # 最下方一条环边,远离内部布线


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--gds", required=True)
    ap.add_argument("--def", dest="def_file", required=True)
    ap.add_argument("--out", required=True)
    ap.add_argument("--top", default=None)
    ap.add_argument("--power", default="VDD!")
    ap.add_argument("--ground", default="VSS!")
    ap.add_argument("--layer", type=int, default=34)
    ap.add_argument("--texttype", type=int, default=10)
    ap.add_argument("--x", type=float, default=50.0)
    a = ap.parse_args()

    y_pwr = find_ring_y(a.def_file, a.power)
    y_gnd = find_ring_y(a.def_file, a.ground)
    if abs(y_pwr - y_gnd) < 1e-6:
        sys.exit("两个电源网解析到同一 y=%.3f,DEF 异常,中止" % y_pwr)
    print("%s ring y=%.3f um, %s ring y=%.3f um (来自 DEF,net 归属可靠)"
          % (a.power, y_pwr, a.ground, y_gnd))

    cmd = [sys.executable, GDS_TOOL, "add-labels", a.gds, a.out,
           "--layer", str(a.layer), "--texttype", str(a.texttype),
           "--label", "%s:%s:%s" % (a.power, a.x, y_pwr),
           "--label", "%s:%s:%s" % (a.ground, a.x, y_gnd)]
    if a.top:
        cmd += ["--top", a.top]
    sys.exit(subprocess.call(cmd))


if __name__ == "__main__":
    main()

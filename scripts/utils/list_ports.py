#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""DigitalPilot · Verilog 端口提取器(零依赖,py3.6 兼容)。

从 RTL/网表里解析顶层模块端口(方向/位宽/名字),给 AI/脚本做三件事的输入:
testbench 骨架的信号声明、SDC 核对、Innovus pin 规划核对。

用法:
  ./list_ports.py <file.v> [--module M] [--fmt table|tb|json]
    table : 方向/位宽/名字 表格(默认)
    tb    : 直接可贴进 testbench 的 reg/wire 声明 + 例化连线
    json  : 机器可读

支持 ANSI 风格(module m(input wire [3:0] a, ...);)与
经典风格(module m(a,b); input [3:0] a; ...)。
"""
import argparse
import json
import re
import sys


def strip_comments(s):
    s = re.sub(r"/\*.*?\*/", " ", s, flags=re.S)
    s = re.sub(r"//[^\n]*", " ", s)
    return s


def parse(text, module=None):
    text = strip_comments(text)
    mods = list(re.finditer(r"\bmodule\s+(\w+)\s*(#\s*\(.*?\)\s*)?\((.*?)\)\s*;",
                            text, re.S))
    if not mods:
        sys.exit("没找到 module 定义")
    m = None
    if module:
        m = next((x for x in mods if x.group(1) == module), None)
        if m is None:
            sys.exit("没找到 module %s(文件里有: %s)"
                     % (module, [x.group(1) for x in mods]))
    else:
        m = mods[0]
    name, header = m.group(1), m.group(3)
    body = text[m.end():]
    endm = body.find("endmodule")
    body = body[:endm] if endm >= 0 else body

    KW_DIR = ("input", "output", "inout")

    def parse_chunks(chunks):
        """ANSI 解析:按逗号分块,方向/位宽向后继承,块内最后一个标识符为端口名。"""
        out = []
        cur = {"dir": None, "width": "", "signed": False}
        for ch in chunks:
            toks = ch.split()
            if not toks:
                continue
            if toks[0] in KW_DIR:
                cur = {"dir": toks[0], "signed": "signed" in toks,
                       "width": (re.search(r"\[[^\]]+\]", ch) or [None] and
                                 re.search(r"\[[^\]]+\]", ch))}
                cur["width"] = cur["width"].group(0) if cur["width"] else ""
            ids = re.findall(r"\w+", ch)
            ids = [t for t in ids if t not in KW_DIR and
                   t not in ("wire", "reg", "logic", "signed") and not t.isdigit()]
            if ids and cur["dir"]:
                pname = ids[-1]
                # 位宽里的标识符(参数名)不算端口名
                if cur["width"] and pname in re.findall(r"\w+", cur["width"]):
                    continue
                out.append({"name": pname, "dir": cur["dir"],
                            "width": cur["width"], "signed": cur["signed"]})
        return out

    ports = parse_chunks(header.split(","))
    if not ports:  # 经典风格:方向声明在 body
        for st in re.finditer(r"\b(input|output|inout)\b([^;]*);", body):
            chunk0 = st.group(1) + " " + st.group(2)
            ports.extend(parse_chunks(chunk0.split(",")))
    # 去重保序
    seen, uniq = set(), []
    for p in ports:
        if p["name"] not in seen:
            seen.add(p["name"]); uniq.append(p)
    return name, uniq


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("file")
    ap.add_argument("--module", default=None)
    ap.add_argument("--fmt", choices=["table", "tb", "json"], default="table")
    a = ap.parse_args()
    name, ports = parse(open(a.file).read(), a.module)

    if a.fmt == "json":
        print(json.dumps({"module": name, "ports": ports}, ensure_ascii=False, indent=1))
    elif a.fmt == "tb":
        print("// === 信号声明(贴进 testbench) ===")
        for p in ports:
            kw = "reg " if p["dir"] == "input" else "wire"
            sg = "signed " if p["signed"] else ""
            w = (p["width"] + " ") if p["width"] else ""
            print("    %s %s%s%s;" % (kw, sg, w, p["name"]))
        print("\n// === DUT 例化 ===")
        conns = ", ".join(".%s(%s)" % (p["name"], p["name"]) for p in ports)
        print("    %s dut (%s);" % (name, conns))
    else:
        print("module: %s  (%d ports)" % (name, len(ports)))
        for p in ports:
            print("  %-6s %-12s %s" % (p["dir"], p["width"] or "[0:0]", p["name"]))


if __name__ == "__main__":
    main()

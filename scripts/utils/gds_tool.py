#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""DigitalPilot · 零依赖 GDSII 工具(纯标准库,兼容服务器 Python 3.6)。

直接解析 GDSII 二进制流,不需要 gdstk/gdspy——学院服务器装不了第三方包,
这是它能在服务器上原生运行的原因。

子命令:
  scan-missing <gds>                 列出"被引用但未定义"的 structure(标准单元空壳清单)
  list-cells   <gds>                 列出全部已定义 structure
  top-cell     <gds>                 推断顶层 structure(已定义且未被引用)
  add-labels   <gds> <out> --top T --label NAME:X:Y ... [--layer 34 --texttype 10]
                                     在顶层插入文字标签(坐标单位 um)

GDSII 记录格式:2B 长度(含头) + 1B 记录型 + 1B 数据型 + 负载。
关键记录:STRNAME=0x06(定义) SNAME=0x12(引用) BGNSTR=0x05 ENDSTR=0x07 UNITS=0x03。
"""
import argparse
import struct
import sys

R_UNITS, R_BGNSTR, R_STRNAME, R_ENDSTR, R_SNAME = 0x03, 0x05, 0x06, 0x07, 0x12


def records(data):
    """迭代 (offset, rectype, payload)。"""
    pos, n = 0, len(data)
    while pos + 4 <= n:
        (length,) = struct.unpack(">H", data[pos:pos + 2])
        if length < 4:
            break
        rectype = data[pos + 2]
        yield pos, rectype, data[pos + 4:pos + length]
        pos += length


def _name(payload):
    return payload.rstrip(b"\x00").decode("ascii", "replace")


def scan(data):
    """返回 (defined, referenced) 两个集合。"""
    defined, referenced = set(), set()
    for _, rt, pl in records(data):
        if rt == R_STRNAME:
            defined.add(_name(pl))
        elif rt == R_SNAME:
            referenced.add(_name(pl))
    return defined, referenced


def real8(b):
    """GDSII 8 字节浮点(excess-64, base-16)。"""
    sign = -1.0 if b[0] & 0x80 else 1.0
    exp = (b[0] & 0x7F) - 64
    mant = 0
    for byte in b[1:8]:
        mant = (mant << 8) | byte
    return sign * (mant / float(1 << 56)) * (16.0 ** exp)


def dbu_per_uu(data):
    for _, rt, pl in records(data):
        if rt == R_UNITS and len(pl) >= 16:
            uu = real8(pl[0:8])           # 一个数据库单位 = uu 个用户单位
            return int(round(1.0 / uu))   # 如 0.0005 → 2000
    raise SystemExit("GDS 无 UNITS 记录")


def text_element(label, x_db, y_db, layer, texttype):
    """构造 TEXT 元素字节串。"""
    out = b""
    out += struct.pack(">HBB", 4, 0x0C, 0x00)                      # TEXT
    out += struct.pack(">HBBh", 6, 0x0D, 0x02, layer)              # LAYER
    out += struct.pack(">HBBh", 6, 0x16, 0x02, texttype)           # TEXTTYPE
    out += struct.pack(">HBBii", 12, 0x10, 0x03, x_db, y_db)       # XY
    s = label.encode("ascii")
    if len(s) % 2:
        s += b"\x00"
    out += struct.pack(">HBB", 4 + len(s), 0x19, 0x06) + s         # STRING
    out += struct.pack(">HBB", 4, 0x11, 0x00)                      # ENDEL
    return out


def endstr_offset_of(data, top):
    """返回名为 top 的 structure 的 ENDSTR 记录起始偏移。"""
    cur = None
    for off, rt, pl in records(data):
        if rt == R_STRNAME:
            cur = _name(pl)
        elif rt == R_ENDSTR and cur == top:
            return off
    raise SystemExit("找不到 structure: %s" % top)


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd")
    for c in ("scan-missing", "list-cells", "top-cell"):
        p = sub.add_parser(c)
        p.add_argument("gds")
    p = sub.add_parser("add-labels")
    p.add_argument("gds")
    p.add_argument("out")
    p.add_argument("--top", default=None)
    p.add_argument("--label", action="append", required=True,
                   help="NAME:X_um:Y_um,可多次(如 VDD!:50.0:14.66)")
    p.add_argument("--layer", type=int, default=34)
    p.add_argument("--texttype", type=int, default=10)
    a = ap.parse_args()
    if not a.cmd:
        ap.print_help()
        return

    data = open(a.gds, "rb").read()
    defined, referenced = scan(data)

    if a.cmd == "scan-missing":
        for nm in sorted(referenced - defined):
            print(nm)
        print("# defined=%d referenced=%d missing=%d"
              % (len(defined), len(referenced), len(referenced - defined)),
              file=sys.stderr)
    elif a.cmd == "list-cells":
        for nm in sorted(defined):
            print(nm)
    elif a.cmd == "top-cell":
        tops = sorted(defined - referenced)
        for nm in tops:
            print(nm)
        if len(tops) != 1:
            print("# 警告: 顶层不唯一(%d 个)" % len(tops), file=sys.stderr)
    elif a.cmd == "add-labels":
        top = a.top
        if top is None:
            tops = sorted(defined - referenced)
            if len(tops) != 1:
                sys.exit("顶层不唯一,请用 --top 指定: %s" % tops)
            top = tops[0]
        dbu = dbu_per_uu(data)
        ins = endstr_offset_of(data, top)
        blob = b""
        for spec in a.label:
            name, xs, ys = spec.split(":")
            blob += text_element(name, int(round(float(xs) * dbu)),
                                 int(round(float(ys) * dbu)), a.layer, a.texttype)
        with open(a.out, "wb") as f:
            f.write(data[:ins] + blob + data[ins:])
        print("top=%s dbuPerUU=%d labels=%d -> %s" % (top, dbu, len(a.label), a.out))


if __name__ == "__main__":
    main()

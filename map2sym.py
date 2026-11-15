#!/usr/bin/env python3
# map2sym.py  <listing.txt>  -> syms.s
import re, sys

BASE      = 0x400000
CODE_END  = 0x406000          # below this = code, above = data
rx = re.compile(r'^(\S+): 0x([0-9A-Fa-f]+), defined in (.*)$')

syms = []                      # (addr, name, file, line)
for l in open(sys.argv[1]):
    m = rx.match(l.strip())
    if not m: continue
    name, addr, where = m.group(1), int(m.group(2), 16), m.group(3)
    if addr < BASE: continue                       # constants, not addresses
    loc = re.search(r'([\w./-]+)\[(\d+)\]', where) # first = innermost real source
    f, ln = (loc.group(1), int(loc.group(2))) if loc else (None, 0)
    name = re.sub(r'[^A-Za-z0-9_.$]', '_', name)   # '?' etc. are not valid in gas
    syms.append((addr, name, f, ln))

syms.sort()
files = {}
out = ['.text']
i = 0
while i < len(syms):
    addr = syms[i][0]
    group = []
    while i < len(syms) and syms[i][0] == addr:
        group.append(syms[i]); i += 1
    out.append(f'.org 0x{addr-BASE:x}')
    is_code = addr < CODE_END
    for _, name, f, ln in group:
        out.append(f'.globl {name}')
        if is_code: out.append(f'.type {name},@function')
        out.append(f'{name}:')
    f, ln = next(((g[2], g[3]) for g in group if g[2]), (None, 0))
    if is_code and f:
        if f not in files:
            files[f] = len(files) + 1
            out.insert(1, f'.file {files[f]} "{f}"')
        out.append(f'.loc {files[f]} {ln}')
    out.append('nop')          # 1 byte so the .loc has something to attach to
open('syms.s', 'w').write('\n'.join(out) + '\n')

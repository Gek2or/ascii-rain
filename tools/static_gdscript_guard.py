#!/usr/bin/env python3
"""Lightweight pre-package guard for common GDScript parser regressions.
Not a substitute for the actual Godot parser/runtime.
"""
from pathlib import Path
import re, sys

ROOT = Path(__file__).resolve().parents[1]
RESERVED = {
    'and','as','assert','await','break','breakpoint','class','class_name','const','continue',
    'elif','else','enum','extends','false','for','func','if','in','is','match','namespace',
    'not','null','or','pass','preload','return','self','signal','static','super','true','var','void','while','yield'
}
problems=[]

def report(path, text, pos, msg):
    line=text.count('\n', 0, pos)+1
    problems.append(f'{path.relative_to(ROOT)}:{line}: {msg}')

for path in ROOT.rglob('*.gd'):
    text=path.read_text(encoding='utf-8')

    # Variables/constants and function names.
    for rx,label in [
        (re.compile(r'(?m)^\s*(?:var|const)\s+([A-Za-z_]\w*)\b'), 'identifier'),
        (re.compile(r'(?m)^\s*func\s+([A-Za-z_]\w*)\s*\('), 'function name'),
        (re.compile(r'(?m)^\s*for\s+([A-Za-z_]\w*)\s+in\b'), 'loop variable'),
    ]:
        for m in rx.finditer(text):
            if m.group(1) in RESERVED:
                report(path, text, m.start(1), f'reserved {label}: {m.group(1)}')

    # Function parameters, including multiline signatures.
    sig_rx=re.compile(r'func\s+[A-Za-z_]\w*\s*\((.*?)\)\s*(?:->\s*[^:]+)?\s*:', re.S)
    for sm in sig_rx.finditer(text):
        args=sm.group(1)
        base=sm.start(1)
        # Split on commas; current project signatures do not use nested callable defaults.
        for part in args.split(','):
            raw=part.strip()
            if not raw:
                continue
            m=re.match(r'([A-Za-z_]\w*)\b', raw)
            if m and m.group(1) in RESERVED:
                report(path, text, base + args.find(part) + part.find(m.group(1)), f'reserved parameter: {m.group(1)}')

    # Project standard: avoid inferred := declarations after prior compatibility issues.
    for i,line in enumerate(text.splitlines(),1):
        if ':=' in line:
            problems.append(f'{path.relative_to(ROOT)}:{i}: implicit := declaration is disallowed by project standard')

if problems:
    print('\n'.join(problems))
    sys.exit(1)
print('GDScript static guard: OK')

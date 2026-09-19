#!/usr/bin/env python3
"""Actual Godot import + gameplay and touch regressions, if a binary is supplied.
All saves are isolated. Headless mode does NOT test GPU shaders or device FPS.
Exit 2 means NOT RUN; never treat it as a pass.
"""
from pathlib import Path
import argparse
import os
import re
import shutil
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[1]

def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--godot', default=shutil.which('godot') or shutil.which('godot4'))
    args = parser.parse_args()
    if not args.godot:
        print('NOT RUN: Godot executable not found. Supply --godot /path/to/Godot.')
        return 2
    out = ROOT / 'build'
    out.mkdir(exist_ok=True)
    base = ['--headless', '--path', str(ROOT)]
    cases = [
        ('import', [*base, '--editor', '--import', '--quit'], None),
        ('run_state', [*base, '--script', 'res://tests/run_state_test.gd'], 'RUN_STATE_NATIVE: 73 checks / 0 failures'),
        ('run_loop', [*base, '--script', 'res://tests/run_loop_smoke.gd', '--', '--test-isolated'], 'RUN_LOOP_NATIVE: 48 checks / 0 failures'),
        ('smoke', [*base, '--script', 'res://tests/smoke_test.gd'], 'ENGINE_SMOKE_OK'),
        ('entity01', [*base, '--script', 'res://tests/entity01_smoke.gd'], 'ENTITY01_SMOKE_OK'),
        ('mobile_clarity', [*base, '--script', 'res://tests/mobile_clarity_smoke.gd', '--', '--touch-preview'], 'MOBILE_CLARITY_SMOKE_OK'),
        ('sector01_collision', [*base, '--script', 'res://tests/sector01_collision_smoke.gd'], 'SECTOR01_COLLISION_SMOKE: 19 checks / 0 failures'),
    ]
    with tempfile.TemporaryDirectory(prefix='ascii_rain_smoke_') as temp:
        env = os.environ.copy()
        env.update(XDG_DATA_HOME=temp, APPDATA=temp, GODOT_SILENCE_ROOT_WARNING='1')
        for name, flags, expected in cases:
            try:
                proc = subprocess.run([args.godot, *flags], env=env, text=True,
                    stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=180)
            except (OSError, subprocess.TimeoutExpired) as exc:
                print(f'ENGINE CHECK FAILED: {exc}')
                return 1
            (out / f'engine_{name}.log').write_text(proc.stdout, encoding='utf-8')
            print(proc.stdout)
            if proc.returncode or re.search(r'SCRIPT ERROR|Parse Error|Shader compilation failed|^ERROR:', proc.stdout, re.M):
                return 1
            if expected and expected not in proc.stdout:
                print(f'ENGINE CHECK FAILED: expected {expected} marker missing')
                return 1
    print('ENGINE CHECKS PASSED (headless; GPU / device tests are still required).')
    return 0

if __name__ == '__main__':
    sys.exit(main())

#!/usr/bin/env python3
"""This release uses actual native Godot canvas tests, not mean-only GLSL checks.
Run tools/run_debug_template_checks.py --template /path/to/trusted/template --render.
The old mean-compensation regression is retained in tests/fixtures/ for provenance.
"""
if __name__ == '__main__':
    print(__doc__)
    raise SystemExit(2)  # NOT RUN, never a misleading green check.

#!/usr/bin/env python3
"""Rebuild native-width ASCII data textures. Requires numpy and Pillow.

Works only from the included hand-authored 32-glyph atlas, not from font files.
--check regenerates into a temporary folder and compares every output byte.
"""
from __future__ import annotations
import argparse
import json
import tempfile
from pathlib import Path
import numpy as np
from PIL import Image
ROOT = Path(__file__).resolve().parents[1]


def overlap_weights(source_size: int, destination_size: int) -> np.ndarray:
    starts = np.arange(destination_size)[:, None] * source_size / destination_size
    ends = (np.arange(destination_size)[:, None] + 1) * source_size / destination_size
    source_start = np.arange(source_size)[None, :]
    source_end = source_start + 1
    return np.maximum(0, np.minimum(ends, source_end) - np.maximum(starts, source_start)) / (source_size / destination_size)


def generate_micro_code(destination: Path) -> None:
    source = np.asarray(Image.open(ROOT / 'assets/ascii_atlas.png').convert('L'), dtype=np.float64) / 255.
    meta = json.loads((ROOT / 'assets/ascii_glyphs.json').read_text())
    if source.shape != (9, 192) or len(meta['characters']) != 32:
        raise ValueError('Expected the original 32 tiles of 6x9 pixels')
    destination.mkdir(parents=True, exist_ok=True)
    manifest_path = destination / 'manifest.json'
    manifest = json.loads(manifest_path.read_text()) if manifest_path.is_file() else {
        'source': 'Original hand-authored ASCII//RAIN glyphs; exact area prefilter',
        'characters': meta['characters'], 'sizes': {}}
    for width in range(1, 4):
        height = int(width * 1.5 + .5)
        mask = np.zeros((height, width * 32), dtype=np.uint8)
        means = []
        for index in range(32):
            tile = source[:, index * 6:(index + 1) * 6]
            filtered = overlap_weights(9, height) @ tile @ overlap_weights(6, width).T
            pixels = np.rint(filtered * 255).astype(np.uint8)
            mask[:, index * width:(index + 1) * width] = pixels
            means.append(float(pixels.mean() / 255.))
        Image.fromarray(mask).convert('RGB').save(destination / f'glyphs_{width}.png')
        coverage = np.rint(np.array(means) * 65535).astype(np.uint16)
        encoded = np.zeros((1, 32, 3), np.uint8)
        encoded[0, :, 0] = coverage >> 8
        encoded[0, :, 1] = coverage & 255
        Image.fromarray(encoded).save(destination / f'coverage_{width}.png')
        manifest['sizes'][str(width)] = {'tile': [width, height], 'coverage': means}
    (destination / 'manifest.json').write_text(json.dumps(manifest, indent=2))


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check', action='store_true')
    args = parser.parse_args()
    target = ROOT / 'assets/ascii_prefiltered'
    if not args.check:
        generate_micro_code(target)
        print('Three micro-code atlases and three coverage textures regenerated.')
        return
    with tempfile.TemporaryDirectory(prefix='ascii_glyph_check_') as folder:
        generated = Path(folder)
        generate_micro_code(generated)
        for path in generated.glob('*.png'):
            if not (target / path.name).is_file() or path.read_bytes() != (target / path.name).read_bytes():
                raise AssertionError(f'Generated data differs: {path.name}')
    manifest = json.loads((target / 'manifest.json').read_text())
    if set(manifest['sizes']) != {str(width) for width in range(1, 11)}:
        raise AssertionError('Expected native atlas metadata for widths 1 through 10')
    print('Micro-code atlas regeneration: 6 / 6 outputs identical; 4-10px sources retained')


if __name__ == '__main__':
    main()

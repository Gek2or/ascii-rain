#!/usr/bin/env python3
"""Create and verify ZIP packages suitable for Godot Project Manager.

Godot's ZIP importer processes entries in order and creates a directory only
when it encounters a directory entry. Merely writing each file with ZipFile.write
can produce a valid ZIP that nevertheless fails direct Godot project import.

Usage:
    python tools/package_project.py pack PROJECT_DIR OUTPUT.zip
    python tools/package_project.py check OUTPUT.zip

This verifies packaging and extraction, NOT the Godot parser or game runtime.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import re
import stat
import tempfile
import zipfile
from pathlib import Path, PurePosixPath

EXCLUDED_DIRS = {'.godot', '.git', '__pycache__', '.pytest_cache', '.venv'}
WINDOWS_RESERVED = {'CON', 'PRN', 'AUX', 'NUL'} | {
    f'{prefix}{n}' for prefix in ('COM', 'LPT') for n in range(1, 10)
}


def safe_name(name: str) -> None:
    raw = name[:-1] if name.endswith('/') else name
    if not raw or raw.startswith('/') or '\\' in raw:
        raise ValueError(f'Unsafe/non-portable ZIP path: {name!r}')
    for part in raw.split('/'):
        if part in ('', '.', '..') or part.rstrip(' .') != part:
            raise ValueError(f'Unsafe ZIP path component: {name!r}')
        if any(ord(c) < 32 for c in part) or re.search(r'[<>:"|?*]', part):
            raise ValueError(f'Invalid Windows filename: {name!r}')
        if part.split('.')[0].upper() in WINDOWS_RESERVED:
            raise ValueError(f'Reserved Windows filename: {name!r}')


def check(archive: Path) -> dict:
    """Validate and actually extract in order without implicit mkdir calls."""
    with zipfile.ZipFile(archive) as source:
        records = source.infolist()
        if source.testzip() is not None:
            raise ValueError('ZIP CRC check failed')
        projects = [i.filename for i in records
                    if not i.is_dir() and PurePosixPath(i.filename).name == 'project.godot']
        if len(projects) != 1:
            raise ValueError('Expected exactly one project.godot')
        parent = PurePosixPath(projects[0]).parent
        prefix = '' if str(parent) == '.' else parent.as_posix() + '/'
        seen_names: set[str] = set()
        declared_dirs: set[str] = {''}
        file_count = 0
        dir_count = 0
        for entry in records:
            name = entry.filename
            safe_name(name)
            key = name.rstrip('/').casefold()
            if key in seen_names:
                raise ValueError(f'Duplicate/case-colliding path: {name}')
            seen_names.add(key)
            if entry.flag_bits & 1:
                raise ValueError('Encrypted ZIPs are not supported')
            if entry.compress_type not in (zipfile.ZIP_STORED, zipfile.ZIP_DEFLATED):
                raise ValueError(f'Unsupported compression method: {entry.compress_type}')
            if entry.create_system == 3 and stat.S_ISLNK(entry.external_attr >> 16):
                raise ValueError('Symbolic links are not supported')
            if prefix and not name.startswith(prefix):
                raise ValueError(f'Entry outside the project folder: {name}')
            p = PurePosixPath(name.rstrip('/'))
            required_parent = '' if str(p.parent) == '.' else p.parent.as_posix() + '/'
            if required_parent not in declared_dirs:
                raise ValueError(f'Missing/late directory entry {required_parent!r} before {name!r}')
            if entry.is_dir():
                declared_dirs.add(name)
                dir_count += 1
            else:
                file_count += 1

        extracted_counts: dict[str, int] = {}
        for strip_root in (False, True):
            with tempfile.TemporaryDirectory(prefix='ascii_zip_test_') as temp:
                destination = Path(temp)
                written = 0
                for entry in records:
                    name = entry.filename
                    if strip_root and prefix:
                        name = name[len(prefix):]
                    if not name:
                        continue
                    output = destination / name
                    # Deliberately NOT recursive. Only explicit directory entries
                    # are allowed to create folders, in parent-first order.
                    if entry.is_dir():
                        output.mkdir(exist_ok=True)
                    else:
                        data = source.read(entry)
                        with output.open('xb') as target:
                            target.write(data)
                        if output.read_bytes() != data:
                            raise ValueError(f'Extracted data mismatch: {name}')
                        written += 1
                config = destination / ('project.godot' if strip_root else projects[0])
                if not config.is_file():
                    raise ValueError('Extracted project.godot is missing')
                extracted_counts['root_stripped' if strip_root else 'ordinary'] = written

    return {
        'archive': archive.name,
        'bytes': archive.stat().st_size,
        'sha256': hashlib.sha256(archive.read_bytes()).hexdigest(),
        'project_root': prefix,
        'files': file_count,
        'explicit_directories': dir_count,
        'crc': 'PASS',
        'safe_paths_and_directory_order': 'PASS',
        'sequential_extraction': extracted_counts,
        'godot_engine_executed': False,
    }


def pack(project: Path, output: Path, root_name: str | None = None) -> dict:
    project = project.resolve()
    output = output.resolve()
    root = root_name or project.name
    if not (project / 'project.godot').is_file():
        raise ValueError('Source folder must contain project.godot')
    if output.exists():
        raise ValueError(f'Refusing to overwrite existing archive: {output}')
    safe_name(root)
    if '/' in root:
        raise ValueError('root_name must be one folder name')
    files = []
    dirs = {root + '/'}
    for path in sorted(project.rglob('*')):
        rel = path.relative_to(project)
        if any(part in EXCLUDED_DIRS for part in rel.parts):
            continue
        if path.is_symlink():
            raise ValueError(f'Refusing symlink: {rel}')
        if not path.is_file() or path == output or path.suffix.lower() in ('.zip', '.pyc'):
            continue
        name = root + '/' + rel.as_posix()
        safe_name(name)
        files.append((path, name))
        for parent in PurePosixPath(name).parents:
            if str(parent) != '.':
                dirs.add(parent.as_posix() + '/')
    output.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(output, 'x', compression=zipfile.ZIP_DEFLATED,
                         compresslevel=6, allowZip64=False) as target:
        for name in sorted(dirs, key=lambda n: (n.count('/'), n)):
            entry = zipfile.ZipInfo(name, (2026, 9, 17, 0, 0, 0))
            entry.create_system = 0  # portable DOS metadata, including directory bit
            entry.external_attr = 0x10
            entry.compress_type = zipfile.ZIP_STORED
            target.writestr(entry, b'')
        for path, name in files:
            entry = zipfile.ZipInfo(name, (2026, 9, 17, 0, 0, 0))
            entry.create_system = 0
            entry.external_attr = 0x20
            entry.compress_type = zipfile.ZIP_DEFLATED
            target.writestr(entry, path.read_bytes(), compresslevel=6)
    return check(output)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest='command', required=True)
    packing = commands.add_parser('pack')
    packing.add_argument('project', type=Path)
    packing.add_argument('output', type=Path)
    packing.add_argument('--root-name')
    checking = commands.add_parser('check')
    checking.add_argument('archive', type=Path)
    args = parser.parse_args()
    try:
        result = (pack(args.project, args.output, args.root_name)
                  if args.command == 'pack' else check(args.archive))
    except (OSError, ValueError, zipfile.BadZipFile) as error:
        parser.exit(1, f'ZIP VALIDATION FAILED: {error}\n')
    print(json.dumps(result, indent=2))


if __name__ == '__main__':
    main()

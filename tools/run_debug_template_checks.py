#!/usr/bin/env python3
"""Run native Godot GDScript tests with a Linux debug export template.

Fallback for QA hosts where the editor cannot initialize. NOT an editor importer:
PNG/WAV files are serialized by native ImageTexture/AudioStreamWAV APIs in a TEMP
copy, then remapped for the template. The distributed source project is untouched.
Use run_engine_checks.py with a normal editor for actual editor import validation.
No engine executable, fonts, SDK, or network download is bundled.
"""
from __future__ import annotations
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
BAD = re.compile(r'SCRIPT ERROR|Parse Error|Shader compilation failed|^ERROR:', re.M)
IMPORTER = '''extends Node
func _ready() -> void:
    var paths: Array = JSON.parse_string(FileAccess.get_file_as_string("res://qa_assets.json"))
    DirAccess.make_dir_recursive_absolute("res://qa_imported")
    for path in paths:
        var input_path: String = "res://" + str(path)
        var output_path: String = "res://qa_imported/" + str(path).replace("/", "_") + ".res"
        var resource: Resource = null
        if str(path).ends_with(".png"):
            var image: Image = Image.load_from_file(input_path)
            if image == null or image.is_empty():
                push_error("QA image load failed: " + input_path)
                get_tree().quit(1)
                return
            resource = ImageTexture.create_from_image(image)
        else:
            resource = AudioStreamWAV.load_from_file(input_path)
        if resource == null or ResourceSaver.save(resource, output_path, ResourceSaver.FLAG_COMPRESS) != OK:
            push_error("QA resource conversion failed: " + input_path)
            get_tree().quit(1)
            return
        var remap: FileAccess = FileAccess.open(input_path + ".remap", FileAccess.WRITE)
        remap.store_string("[remap]\\npath=\\\"" + output_path + "\\\"\\n")
        remap.close()
    print("QA_NATIVE_ASSET_PREP_OK: ", paths.size())
    get_tree().quit()
'''
BOOT = '''extends Node
func _ready() -> void:
    var path: String = FileAccess.get_file_as_string("res://qa_test.txt").strip_edges()
    var script: Script = load(path) as Script
    if script == null or not script.can_instantiate():
        push_error("QA_SCRIPT_LOAD_FAILED: " + path)
        get_tree().quit(1)
        return
    get_tree().set_script(script)
    get_tree().call_deferred("_initialize")
'''
SCENE = '[gd_scene load_steps=2 format=3]\n[ext_resource type="Script" path="res://{script}.gd" id="1"]\n[node name="QA" type="Node"]\nscript=ExtResource("1")\n'

def stage(project: Path, binary: Path) -> None:
    shutil.copytree(ROOT, project, dirs_exist_ok=True,
        ignore=shutil.ignore_patterns('.godot','.git','__pycache__','build','*.zip','*.pyc'))
    shutil.copy2(binary, project/'qa_binary')
    (project/'qa_binary').chmod(0o755)
    (project/'.godot').mkdir(exist_ok=True)
    records=[]
    for script in sorted(project.rglob('*.gd')):
        code=script.read_text(encoding='utf-8')
        name=re.search(r'^class_name\s+(\w+)',code,re.M)
        base=re.search(r'^extends\s+(\w+)',code,re.M)
        if name and base:
            records.append({'base':base[1],'class':name[1],'icon':'',
                'is_abstract':False,'is_tool':False,'language':'GDScript',
                'path':'res://'+script.relative_to(project).as_posix()})
    (project/'.godot/global_script_class_cache.cfg').write_text(
        'list=Array[Dictionary]('+json.dumps(records)+')\n',encoding='utf-8')
    assets=[p.relative_to(project).as_posix() for p in sorted(project.rglob('*'))
        if p.is_file() and p.suffix.lower() in ('.png','.wav')]
    (project/'qa_assets.json').write_text(json.dumps(assets))
    for name,code in [('qa_import',IMPORTER),('qa_boot',BOOT)]:
        (project/(name+'.gd')).write_text(code,encoding='utf-8')
        (project/(name+'.tscn')).write_text(SCENE.format(script=name))


def run(binary: Path, flags: list[str], output: Path, user: Path, timeout: int) -> str:
    env=dict(os.environ, XDG_DATA_HOME=str(user), APPDATA=str(user),
        GODOT_SILENCE_ROOT_WARNING='1')
    with output.open('w',encoding='utf-8') as log:
        proc=subprocess.run([str(binary),*flags],env=env,stdout=log,
            stderr=subprocess.STDOUT,text=True,timeout=timeout)
    text=output.read_text(encoding='utf-8')
    if proc.returncode or BAD.search(text):
        raise RuntimeError(f'{output.name}: engine failure, exit={proc.returncode}\n{text[-5000:]}')
    return text


def main() -> int:
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--template',type=Path,required=True)
    parser.add_argument('--render',action='store_true',help='Also capture real OpenGL frames (DISPLAY required)')
    parser.add_argument('--render-only',default='',help='Optional comma-separated capture/pixel cases')
    parser.add_argument('--timeout',type=int,default=120)
    parser.add_argument('--only',default='',help='Comma-separated native test names; empty runs all')
    args=parser.parse_args()
    binary=args.template.expanduser().resolve()
    if not binary.is_file():
        parser.error('Supply a real, trusted Linux Godot debug template executable.')
    out=ROOT/'build';out.mkdir(exist_ok=True)
    version=subprocess.run([str(binary),'--version'],capture_output=True,text=True,timeout=15)
    meta={'engine_version':version.stdout.strip(),'binary_sha256':hashlib.sha256(binary.read_bytes()).hexdigest(),
          'mode':'native debug template, temporary ImageTexture/WAV remaps; NOT editor import','tests':[]}
    try:
        with tempfile.TemporaryDirectory(prefix='ascii_native_template_') as temp:
            temp=Path(temp);project=temp/'project'
            stage(project,binary)
            executable=project/'qa_binary'
            (project/'project.godot').write_text('config_version=5\n[application]\nconfig/name="ASCII_QA"\nrun/main_scene="res://qa_import.tscn"\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n')
            text=run(executable,['--headless'],out/'native_asset_prep.log',temp/'import_user',args.timeout)
            if 'QA_NATIVE_ASSET_PREP_OK' not in text:
                raise RuntimeError('Native asset preparation marker missing')
            config=(ROOT/'project.godot').read_text().replace('res://scenes/Main.tscn','res://qa_boot.tscn')
            (project/'project.godot').write_text(config)
            cases=[('settings_v013','settings_v013_test.gd',[],'SETTINGS_013_NATIVE:'),
                   ('route_probe','route_probe.gd',[],'ROUTE_PROBE_OK'),
                   ('district_events','district_events_test.gd',[],'DISTRICT_EVENTS_NATIVE:'),
                   ('district_depths','district_depths_test.gd',[],'DISTRICT_DEPTHS_NATIVE:'),
                   ('civic_city','civic_city_test.gd',[],'CIVIC_CITY_NATIVE: 76 checks / 0 failures'),
                   ('living_city','living_city_test.gd',[],'LIVING_CITY_NATIVE: 70 checks / 0 failures'),
                   ('tactics','encounter_tactics_test.gd',[],'ENCOUNTER_TACTICS_NATIVE: 38 checks / 0 failures'),
                   ('city_navigation','city_navigation_test.gd',[],'CITY_NAV_NATIVE: 16 checks / 0 failures'),
                   ('run_state','run_state_test.gd',[],'RUN_STATE_NATIVE: 73 checks / 0 failures'),
                   ('run_loop','run_loop_smoke.gd',['--test-isolated'],'RUN_LOOP_NATIVE: 48 checks / 0 failures'),
                   ('general_smoke','smoke_test.gd',[],'ENGINE_SMOKE_OK'),
                   ('touch_smoke','mobile_clarity_smoke.gd',['--touch-preview'],'MOBILE_CLARITY_SMOKE_OK')]
            if args.only:
                selected = set(args.only.split(','))
                cases = [case for case in cases if case[0] in selected]
                if not cases:
                    raise RuntimeError('Unknown --only test selection')
            if not args.only:
                cases=[case for case in cases if case[0]!='route_probe']
            for name,script,extra,marker in cases:
                (project/'qa_test.txt').write_text('res://tests/'+script)
                text=run(executable,['--headless','--',*extra],out/('native_'+name+'.log'),temp/name,args.timeout)
                if marker not in text:
                    raise RuntimeError('Missing marker: '+marker)
                meta['tests'].append({'name':name,'result':'PASS','marker':marker})
                print(name+': PASS',flush=True)
            if args.render:
                (project/'qa_test.txt').write_text('res://tests/render_capture.gd')
                user=temp/'capture'
                text=run(executable,['--rendering-method','gl_compatibility','--audio-driver','Dummy','--','--test-isolated'],
                    out/'native_render_capture.log',user,args.timeout)
                if 'RENDER_CAPTURE_OK' not in text:
                    raise RuntimeError('Rendered capture marker missing')
                target=out/'captures';target.mkdir(exist_ok=True)
                for p in user.rglob('*.png'):
                    if p.parent.name=='captures': shutil.copy2(p,target/p.name)
                meta['tests'].append({'name':'render_capture','result':'PASS','driver':'See native_render_capture.log'})
                for name, script, marker in [
                    ('reference_glyph','reference_glyph_test.gd','REFERENCE_GLYPH_NATIVE:'),
                    ('reference_city_capture','reference_city_capture.gd','REFERENCE_CITY_CAPTURE_OK'),
                    ('civic_capture','civic_city_capture.gd','CIVIC_CAPTURE_OK'),
                    ('living_capture', 'living_city_capture.gd', 'LIVING_CAPTURE_OK'),
                    ('tactics_capture', 'tactics_capture.gd', 'TACTICS_CAPTURE_OK'),
                    ('visual_balance', 'visual_balance_test.gd', 'VISUAL_BALANCE_NATIVE: 126 checks / 0 failures'),
                    ('visual_balance_capture', 'visual_balance_capture.gd', 'VISUAL_CAPTURE_OK: native frames / paused preview: true')]:
                    if not args.render_only and name in {'visual_balance','visual_balance_capture'}:
                        # Historical v0.10.1 rendering contracts are superseded by
                        # reference_glyph_test for the intentionally new renderer.
                        continue
                    if args.render_only and name not in args.render_only.split(','):
                        continue
                    (project/'qa_test.txt').write_text('res://tests/'+script)
                    visual_user=temp/name
                    text=run(executable,['--rendering-method','gl_compatibility','--audio-driver','Dummy','--','--test-isolated'],
                        out/('native_'+name+'.log'),visual_user,args.timeout)
                    if marker not in text:
                        raise RuntimeError('Missing marker: '+marker)
                    for asset in visual_user.rglob('*'):
                        if asset.is_file() and asset.parent.name=='captures':
                            shutil.copy2(asset,target/asset.name)
                    meta['tests'].append({'name':name,'result':'PASS','marker':marker})
                    print(name+': PASS',flush=True)

    except (OSError,subprocess.TimeoutExpired,RuntimeError) as exc:
        print('NATIVE TEMPLATE CHECK FAILED:',exc)
        meta['error']=str(exc)
        (out/'native_provenance.json').write_text(json.dumps(meta,indent=2))
        return 1
    (out/'native_provenance.json').write_text(json.dumps(meta,indent=2))
    print('Native template checks passed. Editor import and physical devices are still untested.')
    return 0

if __name__=='__main__':
    raise SystemExit(main())

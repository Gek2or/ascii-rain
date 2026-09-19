from pathlib import Path
import re
import sys

root = Path(__file__).resolve().parents[1]
issues: list[str] = []
warnings: list[str] = []

main = root / "scenes" / "Main.tscn"
project_path = root / "project.godot"
if not main.exists():
    issues.append("Missing scenes/Main.tscn")
if not project_path.exists():
    issues.append("Missing project.godot")
    project = ""
else:
    project = project_path.read_text(errors="ignore")

if 'run/main_scene="res://scenes/Main.tscn"' not in project:
    issues.append("project.godot does not point to Main.tscn")

required_autoloads = {
    "SettingsManager": "res://core/settings_manager.gd",
    "GameEvents": "res://core/game_events.gd",
    "PoolManager": "res://core/pool_manager.gd",
    "RuntimeProfile": "res://core/runtime_profile.gd",
    "AudioManager": "res://core/audio_manager.gd",
}
for name, path in required_autoloads.items():
    marker = f'{name}="*{path}"'
    if marker not in project:
        issues.append(f"Missing autoload: {name} -> {path}")

project_actions = set(re.findall(r"^([A-Za-z0-9_]+)=\{$", project, re.M))
used_actions: set[str] = set()
class_names: dict[str, Path] = {}
script_files = list(root.rglob("*.gd"))
scene_files = list(root.rglob("*.tscn"))
resource_files = list(root.rglob("*.tres"))


def parse_scene_paths(scene_path: Path) -> set[str]:
    text = scene_path.read_text(errors="ignore")
    paths: set[str] = set()
    root_seen = False
    for line_no, line in enumerate(text.splitlines(), 1):
        if not line.startswith("[node "):
            continue
        name_match = re.search(r'name="([^"]+)"', line)
        if not name_match:
            continue
        name = name_match.group(1)
        parent_match = re.search(r'parent="([^"]+)"', line)
        if parent_match is None:
            if root_seen:
                issues.append(f"{scene_path.relative_to(root)}:{line_no} has a second root node")
            root_seen = True
            paths.add(".")
            continue
        parent = parent_match.group(1)
        full = name if parent == "." else f"{parent}/{name}"
        if parent != "." and parent not in paths:
            issues.append(f"{scene_path.relative_to(root)}:{line_no} declares child before missing parent: {parent}")
        if full in paths:
            issues.append(f"{scene_path.relative_to(root)}:{line_no} duplicate node path: {full}")
        paths.add(full)
    return paths

scene_paths: dict[Path, set[str]] = {scene: parse_scene_paths(scene) for scene in scene_files}

script_scene_map = {
    root / "scripts" / "game.gd": root / "scenes" / "Main.tscn",
    root / "scripts" / "player.gd": root / "scenes" / "Player.tscn",
    root / "scripts" / "enemy.gd": root / "scenes" / "Enemy.tscn",
    root / "scripts" / "boss.gd": root / "scenes" / "Boss.tscn",
    root / "scripts" / "teleporter.gd": root / "scenes" / "Teleporter.tscn",
    root / "scripts" / "chest.gd": root / "scenes" / "Chest.tscn",
    root / "scripts" / "enemy_projectile.gd": root / "scenes" / "EnemyProjectile.tscn",
}
for script_path, scene_path in script_scene_map.items():
    if not script_path.exists() or not scene_path.exists():
        continue
    valid_paths = scene_paths.get(scene_path, set())
    script_text = script_path.read_text(errors="ignore")
    for match in re.finditer(r'\$([A-Za-z0-9_/]+)', script_text):
        node_path = match.group(1).rstrip(".,;)")
        if node_path and node_path not in valid_paths:
            line_no = script_text.count("\n", 0, match.start()) + 1
            issues.append(f"{script_path.relative_to(root)}:{line_no} references missing scene node ${node_path}")

text_suffixes = {".gd", ".tscn", ".tres", ".godot", ".cfg", ".gdshader"}
for path in root.rglob("*"):
    if not path.is_file() or path.suffix not in text_suffixes:
        continue
    if any(part in {".godot", ".git", "__pycache__"} for part in path.relative_to(root).parts):
        continue
    text = path.read_text(errors="ignore")
    rel = path.relative_to(root)

    for ref in re.findall(r"res://[^\"\')\s]+", text):
        if not (root / ref[6:]).exists():
            issues.append(f"{rel} -> missing {ref}")

    if path.suffix == ".gd":
        if text.count("(") != text.count(")"):
            issues.append(f"{rel} has unbalanced parentheses")
        if text.count("[") != text.count("]"):
            issues.append(f"{rel} has unbalanced brackets")
        if text.count("{") != text.count("}"):
            issues.append(f"{rel} has unbalanced braces")
        if ":=" in text:
            issues.append(f"{rel} still contains inferred declarations (:=)")

        match = re.search(r"^class_name\s+([A-Za-z_][A-Za-z0-9_]*)", text, re.M)
        if match:
            class_name = match.group(1)
            if class_name in class_names:
                issues.append(f"Duplicate class_name {class_name}: {class_names[class_name]} and {rel}")
            else:
                class_names[class_name] = rel

        for line_no, line in enumerate(text.splitlines(), 1):
            stripped = line.strip()
            if re.match(r"^(?:@export(?:_[A-Za-z0-9_]+)?(?:\([^)]*\))?\s+)?var\s+ready\b", stripped):
                issues.append(f"{rel}:{line_no} redefines native Node.ready member")

        used_actions.update(
            re.findall(
                r'Input\.(?:is_action_(?:pressed|just_pressed|just_released)|action_(?:press|release))\("([^"]+)"',
                text,
            )
        )

        # Architecture folders use explicit field typing as a project standard.
        if rel.parts and rel.parts[0] in {"core", "components", "data"}:
            for line_no, line in enumerate(text.splitlines(), 1):
                stripped = line.strip()
                if stripped.startswith("var ") or stripped.startswith("@export var "):
                    declaration = stripped.split("=", 1)[0]
                    if ":" not in declaration:
                        issues.append(f"{rel}:{line_no} architecture field lacks explicit type: {stripped}")

    if path.suffix in {".tscn", ".tres"}:
        first_line = text.splitlines()[0] if text.splitlines() else ""
        match = re.match(r"\[(?:gd_scene|gd_resource).*load_steps=(\d+)", first_line)
        if match:
            declared = int(match.group(1))
            expected = (
                len(re.findall(r"^\[ext_resource ", text, re.M))
                + len(re.findall(r"^\[sub_resource ", text, re.M))
                + 1
            )
            if declared != expected:
                issues.append(f"{rel} load_steps={declared}, expected {expected}")

missing_actions = sorted(used_actions - project_actions)
for action in missing_actions:
    issues.append(f"Input action used but not defined: {action}")

required_classes = {"WeaponData", "EnemyData", "ItemData", "WeaponController", "InventoryComponent"}
missing_classes = sorted(required_classes - set(class_names))
for class_name in missing_classes:
    issues.append(f"Required architecture class missing: {class_name}")

player_scene = (root / "scenes" / "Player.tscn").read_text(errors="ignore")
for node_name in ("WeaponController", "InventoryComponent"):
    if f'name="{node_name}"' not in player_scene:
        issues.append(f"Player.tscn missing {node_name} node")

projectile_script = (root / "scripts" / "enemy_projectile.gd").read_text(errors="ignore")
if 'PoolManager.call_deferred("recycle", self)' not in projectile_script:
    issues.append("EnemyProjectile is not recycling through PoolManager")

player_script = (root / "scripts" / "player.gd").read_text(errors="ignore")
if 'PoolManager.spawn(TRACER_SCENE' not in player_script:
    issues.append("Player tracers are not using PoolManager")

# v0.8 world/control pass requirements.
required_v08_files = [
    root / "ui" / "settings_menu.gd",
    root / "ui" / "reticle.gd",
    root / "world" / "encounter_director.gd",
    root / "assets" / "music" / "district_signal.wav",
]
for required_file in required_v08_files:
    if not required_file.exists():
        issues.append(f"Missing v0.8 system file: {required_file.relative_to(root)}")

game_script = (root / "scripts" / "game.gd").read_text(errors="ignore")
if "_build_encounter_director" not in game_script or "spawn_requested.connect" not in game_script:
    issues.append("Game is not wired to EncounterDirector")
if "SETTINGS_MENU.new" not in game_script or "RETICLE.new" not in game_script:
    issues.append("v0.8 settings menu or reticle is not instantiated")

if issues:
    print("STATIC VALIDATION FAILED")
    for issue in issues:
        print("-", issue)
    sys.exit(1)

print("STATIC VALIDATION OK")
print("GDScript files:", len(script_files))
print("Scenes:", len(scene_files))
print("Data resources:", len(resource_files))
print("Registered class_name types:", len(class_names))
print("Input actions checked:", len(used_actions))
print("Autoloads checked:", len(required_autoloads))
print("Pooling hooks: projectile + tracer OK")
print("All res:// references and resource load_steps are valid.")
if warnings:
    print("WARNINGS")
    for warning in warnings:
        print("-", warning)

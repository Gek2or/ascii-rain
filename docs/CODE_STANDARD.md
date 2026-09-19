# ASCII//RAIN — Code Standard (v0.6+)

This file is the coding contract for future builds. New gameplay should extend these rules instead of adding one-off logic to large scene scripts.

## 1. Explicit types at system boundaries

Public fields, exported fields, resources, signals, function parameters, return values, and values that originate from dynamic scene lookups must be typed explicitly.

Preferred:

```gdscript
@export var move_speed: float = 8.0
var target: Node3D = null

func apply_damage(amount: float) -> void:
    pass
```

Avoid inferred `:=` declarations in this project. They caused repeated parser failures on dynamically resolved Godot values in earlier builds.

## 2. Data is not balance code

Weapon, enemy, and item balance belongs in `.tres` resources under `data/`.

- `WeaponData` — damage/rate/spread/pellets/stagger/intrinsic behavior
- `EnemyData` — health/speed/damage/range/rewards/core color/scale
- `ItemData` — stable id/name/description/rarity/effect tag

Scripts consume these resources. Do not add another 40-line `match` block just to change numbers.

## 3. Components own narrow responsibilities

Reusable nodes live under `components/`.

Current components:

- `WeaponController`
- `InventoryComponent`
- pooled tracer implementation

Next migrations should create health, progression, movement, status, and state-machine components instead of expanding `player.gd` and `enemy.gd` indefinitely.

## 4. Global coordination uses explicit services

Autoloads under `core/` are intentionally small:

- `GameEvents` — cross-system domain events only
- `PoolManager` — reuse high-frequency temporary nodes
- `RuntimeProfile` — one source of truth for PC/mobile performance settings

Do not turn these autoloads into general-purpose dumping grounds.

## 5. Gameplay and presentation remain separate

The game is real 3D. ASCII is a presentation layer.

Gameplay scripts must not depend on the glyph post-process to function. F1/debug rendering should be able to disable ASCII without breaking combat, AI, collision, or progression.

## 6. Pool high-frequency transient objects

Bullets, tracers, glyph particles, damage numbers, and repeated VFX should be reused rather than constantly instantiated/freed during combat.

v0.6 already pools:

- enemy projectiles
- player tracers

ASCII burst glyphs are the next pooling target.

## 7. Stable IDs, not display text

Persistence and gameplay logic use `StringName` ids such as `&"arc_carbine"` or `&"chain_arc"`.

Display names are UI only and may change/localize later.

## 8. Signals over hard references

Local parent/child communication can use node references. Cross-system communication should prefer signals or `GameEvents` so UI, story, analytics, audio, and gameplay do not become mutually dependent.

## 9. Mobile is not a second game

PC and Android use the same gameplay code. `RuntimeProfile` changes budgets such as enemy cap, glyph cell size, bloom, shadows, forward light, and maximum hit-stop.

Do not fork gameplay rules just for Android unless a mechanic is impossible to control on touch.

## 10. File-size guideline

Target size for new gameplay scripts: roughly 100–350 lines.

A file repeatedly passing ~400 lines is a refactor signal, not a reason to keep adding regions/comments. Existing legacy scripts are being migrated incrementally so the playable build stays intact.

## 11. Comments explain why

Bad:

```gdscript
# Move enemy
velocity = direction * speed
```

Useful:

```gdscript
# Important enemies keep dynamic lights, while normal hordes rely on emissive
# cores so 50+ actors do not each submit an OmniLight on Android.
```

## 12. Validation before packaging

Every packaged build must run:

```text
python3 tools/validate_project.py
```

The validator checks resource references, scene/resource load steps, input actions, autoloads, duplicate `class_name`s, architecture field typing, pooling hooks, and known compatibility regressions.

Runtime Play Mode remains a separate required test when a Godot executable is available.

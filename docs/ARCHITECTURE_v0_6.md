# v0.6 Architecture Foundation

v0.6 is deliberately an internal-quality pass. It preserves the v0.5 playable run while moving frequently changed balance/configuration out of monolithic scripts and adding infrastructure required for larger hordes and more content.

## Current runtime layers

```text
Main / run director
├─ Player (3D simulation)
│  ├─ WeaponController
│  ├─ InventoryComponent
│  └─ articulated procedural visual
├─ Enemy actors
│  └─ EnemyData resources
├─ WATCHER boss
├─ World / procedural city
├─ StoryDirector / Reality Archive
├─ PoolManager
├─ GameEvents
├─ RuntimeProfile
└─ ASCII post-process
```

## Data flow

### Weapons

```text
data/weapons/*.tres
        ↓
WeaponController
        ↓
player combat
        ↓
HUD + GameEvents
```

Changing Scatter Cannon spread, rate, damage multiplier, pellet count, tracer color, stagger, or HUD suffix now happens in its `.tres` resource rather than a hard-coded weapon match block.

### Enemies

```text
data/enemies/*.tres
        ↓
enemy setup
        ↓
difficulty scaling
        ↓
elite modifier
        ↓
runtime actor
```

Base archetype balance is externalized. Difficulty and elite scaling remain runtime modifiers so the director can continue escalating a run.

### Items

```text
data/items/*.tres
        ↓
InventoryComponent
        ↓
player effect application
        ↓
HUD + GameEvents
```

The inventory owns catalog/order/stack state. The player still applies effect behavior for now; effect execution will become its own system when more complex synergies are added.

## Runtime services

### GameEvents

Domain-level hooks are now available for:

- enemy killed
- boss killed
- weapon selected
- item collected
- reality fragment found
- run started / ended

These hooks let future audio, analytics, codex, achievements, narrative, and meta-progression listen without being hard-wired into combat actors.

### PoolManager

PoolManager now reuses enemy projectiles and player tracers. The projectile also keeps a runtime material instance instead of duplicating a new material on every reuse.

This is an architectural start, not the final optimization pass. ASCII burst,
impact, dash and melee glyphs are pooled in v0.14 through the existing
PoolManager; the remaining performance work still requires profiling.

### RuntimeProfile

PC/mobile rendering and horde budgets are centralized:

- enemy soft cap
- spawn interval
- ASCII cell size
- bloom
- edge gain
- glyph gain
- main dynamic shadow budget
- player forward light
- hit-stop cap

## Intentional legacy still present

`player.gd`, `enemy.gd`, `game.gd`, and `city_generator.gd` are still larger than the target architecture. They were not rewritten in one destructive pass because the current prototype is already playable.

Migration order:

1. player movement + dash component
2. health/progression components
3. enemy state machine + attack states
4. item effect pipeline
5. pooled ASCII glyph VFX
6. chunked city generation / encounter director

The rule is incremental replacement while preserving a runnable build after every version.

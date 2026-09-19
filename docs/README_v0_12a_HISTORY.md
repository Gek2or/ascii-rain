# ASCII//RAIN v0.12a — Living City / Market & Transit

**Полный Godot-проект. Не APK / EXE. Первая из трёх частей v0.12.**

Два новых многоуровневых района на базе v0.11: рыночный двор с U-образной
галереей и двумя подъёмами, транспортные платформы с мостом и нижним проходом.
Настоящие полы/перила/коллизии, многоуровневый AStar3D, подготовленные точки
появления противников, сервисный дрон, табло и дальний поезд. Текущий ASCII
renderer, сюжет, музыка, предметы, управление и графические настройки сохранены.

**Запуск:** извлечь архив в новую папку, импортировать `project.godot`, F5.
Не импортировать поверх старой неудачной распаковки. Сбрасывать настройки не надо.
Система: ESC / SET. Новый регулятор: CITY AMBIENCE -> Ambient motion (0 = off).

Стартовый сундук -> два района (любые) -> телепортер и WATCHER -> артефакт -> выход.
Новые районы: MARKET // 03 — юго-восток; TRANSIT // SPINE — южная часть города.
Наверх можно пройти без dash или обязательного точного прыжка.

Подробно: `docs/LIVING_CITY_v0_12a.md`. Обязательные ограничения и фактические
проверки: `build/BUILD_STATUS.txt`. В `build/captures/` — кадры из настоящего
Godot с постановочной камерой. В `reference/` — утверждённые арты, НЕ скриншоты.

**Не включено:** реконструкция остальных районов, подземелья и сеть крыш,
лифт/лазание, новый босс, новый саундтрек, раздельные габариты навигационных
агентов. Это последующие этапы. Сборка остаётся игровым прототипом.

## История проекта и базовые инструкции

# ASCII//RAIN v0.11 — Encounter Tactics

Full **Godot source project**, based on v0.10.1 Visual Balance. Not an APK/EXE.

## Open

Extract the ZIP into a **new folder**, import the extracted `project.godot`, F5.
Do not merge into an older partially imported project. No graphics reset required.
Existing sensitivity, audio, graphics preferences and Reality Archive paths are
unchanged. Ordinary Godot editor imports source PNG/WAV assets on first open.

## Play

Follow STARTER CACHE, choose one relic, explore two distinct districts, then
activate the teleporter. Charge the field and defeat WATCHER, recover the optional
physical artifact, and extract. Arrival still begins quietly. Desktop: WASD,
mouse, LMB shoot, RMB precision aim, Space jump, Shift dash, E use, Q or 1/2/3
weapons, Esc settings. Android controls and the safe TEST COURTYARD are retained.

## What changed

* **Solid city objects.** Existing district facades, monument, car body/cabin,
  storefront walls, consoles, pylons and tree trunks receive simple physics
  shapes matching their meshes. They used to be visual-only. Lamps, foliage,
  trim, ground markings and some street furniture remain decoration.
* **Shared street navigation.** Ordinary enemies use a budgeted A* graph sampled
  from real collisions. Routes account for clearance, corners, ground support
  and the existing service ramps. Spawns use the connected walkable component.
  Graph generation happens incrementally after city construction; no hidden
  teleport or direct-through-wall fallback.
* **More deliberate attacks.** Gunner/Tank seek a firing line, retreat if too
  close; Gunner sidesteps between volleys. They aim at a committed point during
  the warning, instead of tracking the player until the last instant. Boss fan
  also commits to its announced aim. Attack recovery follows release.
* **Readable melee sector.** A forward warning arc shows the actual 55-degree
  half-angle/2.25-unit hit region. Stepping out of it avoids the hit. Range,
  vertical separation and solid cover are checked before damage.
* **Cancellable warnings.** Stagger/death cancels ordinary attack cues; enemies
  turn smoothly. Bomber's warning is 0.8 seconds. Volatile death leaves an
  0.85-second warning before an actual blast instead of instant damage.
* **Cover and projectile checks.** Enemy blasts and boss slam check cover.
  A projectile checks the segment between physics positions, catching thin
  obstacles between frames. Area overlap remains for grazing sphere contacts;
  this is a centre-ray plus overlap check, not a full swept-volume CCD solver.
  A duplicate collision callback cannot deal damage twice.
* **Clean end of combat.** Securing/exiting/dying clears delayed hostile hazards
  and warnings. Pausing also pauses their timers.

## What was deliberately kept

ASCII shader, glyph atlases, lighting profile, player/controller/animation,
weapons/relic data, soundtrack, story bible and approved reference art. City mesh
positions, shapes/materials and RNG output are unchanged: only collision tags
were added to the generator. See `tests/protected_v0101.json` and the regressions.

## Known boundaries

Street navigation uses **one walkable height per XZ grid cell**, with a conservative
clearance envelope for the largest ordinary elite. It is not stacked-interior,
roof, flying or dynamic-obstacle navigation. Props do not move/rebake the graph.
WATCHER keeps its existing arena movement (it is too large for this street graph).
Enemy crowd avoidance/animation and content balance are still prototype quality.
Small curb/trim decoration does not become a solid collision step.

Physical Windows/Android performance, stable-engine import and human play balance
are not established by the automated Linux tests. Current evidence/engine version
is in `build/BUILD_REPORT.txt` and `build/native_provenance.json`.

## Reproduce tests

Python source/numerical checks: `python -m unittest discover -s tests -p 'test_*.py'`

Native Linux debug-template fallback (trusted executable supplied separately):
`python tools/run_debug_template_checks.py --template /path/to/godot_debug_template --render`

Use `xvfb-run -a` around the last command on a headless Linux host. Tests stage
resources and profiles in a temporary QA copy; they do not overwrite user saves.
This fallback executes GDScript, physics and shaders in Godot but is not the normal
editor importer. For editor validation use `tools/run_engine_checks.py`.

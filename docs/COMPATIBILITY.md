# Godot compatibility policy

The prototype targets Godot 4.3+ and the GL Compatibility renderer for desktop and Android.

To keep the project tolerant of different Godot 4.x editor builds, scripts intentionally avoid local inferred declarations (`:=`). Dynamic `=` assignments are used where scene nodes or instantiated PackedScenes are not statically class-named. Explicit types remain where they are safe and useful.

Packaging validation rejects:
- unresolved `res://` references;
- inferred `:=` declarations;
- accidental `var ready` declarations that collide with Node's native `ready` member;
- basic bracket/parenthesis mismatches.

This validator is a static compatibility check, not a substitute for opening the project in Godot.

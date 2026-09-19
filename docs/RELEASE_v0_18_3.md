# ASCII//RAIN v0.18.3-alpha — Portal Signal and Reactive Light Chaos

This cumulative update adds the supplied `Corrupted Signal.wav` to the
existing portal activation event. It does not replace or rebuild the run loop.

## Portal audio and lighting

- Portal activation selects `Corrupted Signal.wav` on the existing Music bus;
  the existing spectrum analyzer reads that track.
- The ordinary city soundtrack returns when a new run starts. The selected
  music-volume setting still controls both tracks.
- Existing district lights receive a bounded event boost, with stronger
  spectrum-driven energy and shifting cool/warm colors. One additional,
  non-shadow-casting OmniLight is created at the portal and follows the same
  audio bands.
- The extra source and color chaos fade over 18 seconds. The track continues
  and loops through the existing music-player completion callback.
- The WAV is imported using Godot Quite OK Audio (QOA) compression to reduce
  runtime audio memory while retaining better quality than IMA ADPCM; the
  original supplied WAV remains in the project for Godot import and portability.

## Verification

- Godot 4.7.2 headless editor import: PASS.
- Static GDScript guard, project/resource validation, and 37 source-contract
  tests: PASS.
- Native run-state (73), run-loop (46, including portal audio/light/fade/reset),
  general gameplay smoke, and Entity 01 smoke: PASS.
- The broader engine runner stops at `mobile_clarity`: Godot's Dummy renderer
  logs `Parameter "material" is null` despite printing that smoke's success
  marker. This is not counted as a fully passing engine suite.
- Android hardware rendering/performance and exported APK/EXE are not verified.

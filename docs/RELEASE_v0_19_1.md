# ASCII//RAIN v0.19.1-alpha - Location 01 Soundscape

## Supplied audio integration

The four WAV files from the supplied `ASCII Rain Sound Pack.zip` are copied to
`assets/location01_audio/` without altering the city soundtrack or portal music.

- `rain_loop_a.wav`: looping spatial rain at the bypass, audible through the
  bridge and exit-lift approach.
- `terminal_typing_a.wav`: looping spatial terminal texture while the player is
  within 8.5m of Scan Node.
- `digital_glitch_a.wav`: single Entry Boot cue at the tutorial threshold.
- `digital_glitch_b.wav`: single Cache Access cue at the elevated side cache.

All four sources respect the existing District ambience and SFX settings. Their
source nodes are part of `ThresholdMarketSoundscape`, which loads only with the
standalone first location.

## Verification

- Godot 4.7.2 editor imported all four WAV files successfully.
- Isolated `location01_smoke.gd`: 17 checks / 0 failures, including playback
  checks for rain, Scan Node typing, Entry Boot and Cache Access.
- Static validation and Python source-contract checks were rerun after the
  integration.

## Known limits

- This is spatial gameplay audio, not a final mix; headphones and Android
  device balance have not been tested.
- Godot can report four ObjectDB instances and one resource still in use while
  shutting down the isolated audio smoke process after all 17 assertions pass.

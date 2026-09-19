# Civic environment loops

Original procedural ambience created for ASCII//RAIN with the included
`tools/build_district_audio.py` generator. No externally sourced recordings,
voice samples, songs or sound libraries were used.

archive_ventilation.wav: low ventilation hum and relay transients.
garden_rain.wav: filtered air/water noise and isolated synthetic drops.

Each source is 16 seconds, mono PCM16, 22050 Hz. At runtime the owning
AudioStreamPlayer3D duplicates its resource and enables forward looping.
The separate District ambience slider and SFX control both affect these loops.
Distance limits and local-threat gain reduction are in civic_atmosphere.gd.
They are environmental layers, not replacement music tracks.

Source regeneration and waveform checks: build/audio_validation.json.

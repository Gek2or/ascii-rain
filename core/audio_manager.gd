extends Node

const PULSE: AudioStream = preload("res://assets/audio/pulse.wav")
const SCATTER: AudioStream = preload("res://assets/audio/scatter.wav")
const ARC: AudioStream = preload("res://assets/audio/arc.wav")
const HIT: AudioStream = preload("res://assets/audio/hit.wav")
const DASH: AudioStream = preload("res://assets/audio/dash.wav")
const DAMAGE: AudioStream = preload("res://assets/audio/damage.wav")
const BOSS_WARNING: AudioStream = preload("res://assets/audio/boss_warning.wav")
const ARTIFACT: AudioStream = preload("res://assets/audio/artifact.wav")
const DISTRICT_MUSIC: AudioStream = preload("res://assets/music/district_signal.wav")
const CITY_MUSIC: AudioStream = preload("res://assets/music/deserted_coded_city.mp3")
const PORTAL_SIGNAL_MUSIC: AudioStream = preload("res://assets/music/corrupted_signal.wav")
const MUSIC_BUS: StringName = &"Music"

var _players: Array[AudioStreamPlayer] = []
var _cursor: int = 0
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _music_player: AudioStreamPlayer = null
var _music_bus_index: int = -1
var _spectrum: AudioEffectSpectrumAnalyzerInstance = null

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    _configure_music_bus()
    _rng.randomize()
    var voice_count: int = 12 if not RuntimeProfile.is_mobile else 8
    for i in range(voice_count):
        var player: AudioStreamPlayer = AudioStreamPlayer.new()
        player.name = "Voice%02d" % i
        add_child(player)
        _players.append(player)

    _music_player = AudioStreamPlayer.new()
    _music_player.name = "DistrictMusic"
    _music_player.bus = MUSIC_BUS
    _music_player.stream = CITY_MUSIC
    _music_player.finished.connect(_restart_music)
    add_child(_music_player)
    GameEvents.run_started.connect(_on_run_started)
    SettingsManager.changed.connect(_on_settings_changed)
    _on_settings_changed()
    # The settings callback starts music; a second play() replaced its playback.

func play_weapon(weapon_index: int) -> void:
    match weapon_index:
        1:
            _play(SCATTER, -2.0, 0.96, 1.03)
        2:
            _play(ARC, -4.5, 0.97, 1.05)
        _:
            _play(PULSE, -6.0, 0.98, 1.04)

func play_hit(heavy: bool = false) -> void:
    _play(HIT, -5.0 if heavy else -8.0, 0.92 if heavy else 0.98, 1.07)

func play_dash() -> void:
    _play(DASH, -5.5, 0.96, 1.04)

func play_damage() -> void:
    _play(DAMAGE, -3.8, 0.96, 1.02)

func play_boss_warning() -> void:
    _play(BOSS_WARNING, -3.0, 0.98, 1.01)

func play_artifact() -> void:
    _play(ARTIFACT, -2.0, 0.995, 1.005)

func _play(stream: AudioStream, base_volume_db: float, pitch_min: float, pitch_max: float) -> void:
    if _players.is_empty() or stream == null:
        return
    var player: AudioStreamPlayer = _players[_cursor]
    _cursor = (_cursor + 1) % _players.size()
    player.stop()
    player.stream = stream
    player.volume_db = base_volume_db + _linear_volume_db(SettingsManager.sfx_volume)
    player.pitch_scale = _rng.randf_range(pitch_min, pitch_max)
    player.play()

func _restart_music() -> void:
    if _music_player != null and SettingsManager.music_volume > 0.001:
        _music_player.play()

func play_portal_signal() -> void:
    if _music_player == null:
        return
    _music_player.stop()
    _music_player.stream = PORTAL_SIGNAL_MUSIC
    if SettingsManager.music_volume > 0.001:
        _music_player.play()

func _on_run_started() -> void:
    if _music_player == null or _music_player.stream == CITY_MUSIC:
        return
    _music_player.stop()
    _music_player.stream = CITY_MUSIC
    if SettingsManager.music_volume > 0.001:
        _music_player.play()

func _on_settings_changed() -> void:
    if _music_player == null:
        return
    _music_player.volume_db = -8.0 + _linear_volume_db(SettingsManager.music_volume)
    if SettingsManager.music_volume <= 0.001:
        _music_player.stop()
    elif not _music_player.playing:
        _music_player.play()

func get_music_bands() -> Vector3:
    if _spectrum == null and _music_bus_index >= 0:
        _spectrum = AudioServer.get_bus_effect_instance(_music_bus_index, 0) as AudioEffectSpectrumAnalyzerInstance
    if _spectrum == null:
        return Vector3.ZERO
    return Vector3(
        _spectrum_band(35.0, 180.0, 120.0),
        _spectrum_band(180.0, 2200.0, 90.0),
        _spectrum_band(2200.0, 10000.0, 220.0))

func _spectrum_band(from_hz: float, to_hz: float, gain: float) -> float:
    var magnitude: Vector2 = _spectrum.get_magnitude_for_frequency_range(
        from_hz, to_hz, AudioEffectSpectrumAnalyzerInstance.MAGNITUDE_AVERAGE)
    var amplitude: float = maxf((magnitude.x + magnitude.y) * gain, 0.0)
    return clampf(sqrt(amplitude), 0.0, 1.0)

func _configure_music_bus() -> void:
    _music_bus_index = AudioServer.get_bus_index(MUSIC_BUS)
    if _music_bus_index < 0:
        AudioServer.add_bus()
        _music_bus_index = AudioServer.get_bus_count() - 1
        AudioServer.set_bus_name(_music_bus_index, MUSIC_BUS)
    AudioServer.set_bus_send(_music_bus_index, &"Master")
    var analyzer: AudioEffectSpectrumAnalyzer = AudioEffectSpectrumAnalyzer.new()
    analyzer.buffer_length = 0.24
    analyzer.fft_size = AudioEffectSpectrumAnalyzer.FFT_SIZE_512
    AudioServer.add_bus_effect(_music_bus_index, analyzer, 0)

func _linear_volume_db(value: float) -> float:
    if value <= 0.001:
        return -80.0
    return linear_to_db(clampf(value, 0.001, 1.0))

func stop_all() -> void:
    if is_instance_valid(_music_player):
        _music_player.stop()
    for voice in _players:
        if is_instance_valid(voice):
            voice.stop()

func _exit_tree() -> void:
    stop_all()

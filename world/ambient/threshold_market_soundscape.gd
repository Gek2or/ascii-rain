extends Node3D

const RAIN_LOOP: AudioStreamWAV = preload("res://assets/location01_audio/rain_loop_a.wav")
const TERMINAL_TYPING: AudioStreamWAV = preload("res://assets/location01_audio/terminal_typing_a.wav")
const ENTRY_GLITCH: AudioStreamWAV = preload("res://assets/location01_audio/digital_glitch_a.wav")
const CACHE_GLITCH: AudioStreamWAV = preload("res://assets/location01_audio/digital_glitch_b.wav")

const ENTRY_TRIGGER: Vector3 = Vector3(44.0, 0.5, 27.0)
const SCAN_NODE: Vector3 = Vector3(46.0, 1.0, 42.0)
const BRIDGE_RAIN: Vector3 = Vector3(59.0, 6.0, 45.0)
const SIDE_CACHE: Vector3 = Vector3(40.0, 5.9, 58.6)
const POLL_SECONDS: float = 0.16

var _player: Node3D = null
var _rain: AudioStreamPlayer3D = null
var _typing: AudioStreamPlayer3D = null
var _entry_glitch: AudioStreamPlayer3D = null
var _cache_glitch: AudioStreamPlayer3D = null
var _entry_played: bool = false
var _cache_played: bool = false
var _poll_remaining: float = 0.0

func _ready() -> void:
    _rain = _make_loop("BridgeRain", RAIN_LOOP, BRIDGE_RAIN, 30.0, -18.0)
    _typing = _make_loop("ScanNodeTyping", TERMINAL_TYPING, SCAN_NODE, 10.0, -16.0)
    _entry_glitch = _make_one_shot("EntryBootGlitch", ENTRY_GLITCH, ENTRY_TRIGGER, 9.0, -11.0)
    _cache_glitch = _make_one_shot("CacheAccessGlitch", CACHE_GLITCH, SIDE_CACHE, 11.0, -9.0)
    SettingsManager.changed.connect(_apply_volumes)
    _apply_volumes()

func _process(delta: float) -> void:
    if not is_instance_valid(_player):
        _player = get_tree().get_first_node_in_group("player") as Node3D
        return
    _poll_remaining -= delta
    if _poll_remaining > 0.0:
        return
    _poll_remaining = POLL_SECONDS
    var ambient_enabled: bool = _ambient_gain() > 0.001
    _set_loop_active(_rain, ambient_enabled)
    _set_loop_active(_typing, ambient_enabled and _player.global_position.distance_to(SCAN_NODE) <= 8.5)
    if not _entry_played and _player.global_position.distance_to(ENTRY_TRIGGER) <= 3.0:
        _entry_played = true
        _play_one_shot(_entry_glitch)
    if not _cache_played and _player.global_position.distance_to(SIDE_CACHE) <= 3.5:
        _cache_played = true
        _play_one_shot(_cache_glitch)

func _make_loop(label: String, source: AudioStreamWAV, at: Vector3, distance: float, volume: float) -> AudioStreamPlayer3D:
    var player: AudioStreamPlayer3D = AudioStreamPlayer3D.new()
    player.name = label
    player.position = at
    var loop: AudioStreamWAV = source.duplicate() as AudioStreamWAV
    loop.loop_mode = AudioStreamWAV.LOOP_FORWARD
    loop.loop_begin = 0
    loop.loop_end = int(round(loop.get_length() * float(loop.mix_rate)))
    player.stream = loop
    player.max_distance = distance
    player.unit_size = 8.0
    player.volume_db = volume
    add_child(player)
    return player

func _make_one_shot(label: String, source: AudioStreamWAV, at: Vector3, distance: float, volume: float) -> AudioStreamPlayer3D:
    var player: AudioStreamPlayer3D = AudioStreamPlayer3D.new()
    player.name = label
    player.position = at
    player.stream = source
    player.max_distance = distance
    player.unit_size = 8.0
    player.volume_db = volume
    add_child(player)
    return player

func _set_loop_active(player: AudioStreamPlayer3D, enabled: bool) -> void:
    if enabled and not player.playing:
        player.play()
    elif not enabled and player.playing:
        player.stop()

func _play_one_shot(player: AudioStreamPlayer3D) -> void:
    if _ambient_gain() > 0.001:
        player.play()

func _apply_volumes() -> void:
    var gain_db: float = linear_to_db(maxf(0.0001, _ambient_gain()))
    _rain.volume_db = -18.0 + gain_db
    _typing.volume_db = -16.0 + gain_db
    _entry_glitch.volume_db = -11.0 + gain_db
    _cache_glitch.volume_db = -9.0 + gain_db

func _ambient_gain() -> float:
    return SettingsManager.ambient_volume * SettingsManager.sfx_volume

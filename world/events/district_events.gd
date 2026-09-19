extends Node3D
const RULES = preload("res://data/district_rules.gd")
const TERMINAL = preload("res://world/events/district_terminal.gd")
var consoles: Array[Node3D] = []
var _time: float = 0.0
var _utility: Node = null
var _roofs: Node = null
var _voices: Array[AudioStreamPlayer3D] = []
var _poll: float = 0.0

func _ready() -> void:
    add_to_group("district_event_manager")
    var living: Node=get_parent()
    _utility=living.get_node("utility_depths")
    _roofs=living.get_node("rooftop_relay")
    for id in RULES.RULES:
        var spec: Dictionary=RULES.get_spec(id)
        var console: Node3D=TERMINAL.new() as Node3D
        console.name="Terminal_"+String(id)
        console.set("district_id",id)
        console.set("spec",spec)
        console.position=spec["terminal"]
        add_child(console)
        consoles.append(console)
    _sound(Vector3(-55,-4,-18),preload("res://assets/ambient/archive_ventilation.wav"))
    _sound(Vector3(0,12,-76),preload("res://assets/ambient/garden_rain.wav"))

func _sound(at: Vector3, stream: AudioStreamWAV) -> void:
    var voice: AudioStreamPlayer3D=AudioStreamPlayer3D.new()
    # Reuse the project's quiet non-musical loops, not a new score.
    var sound: AudioStreamWAV=stream.duplicate() as AudioStreamWAV
    sound.loop_mode=AudioStreamWAV.LOOP_FORWARD
    sound.loop_begin=0
    sound.loop_end=int(sound.get_length()*sound.mix_rate)
    voice.stream=sound
    voice.position=at
    voice.max_distance=28.0
    voice.unit_size=8.0
    voice.volume_db=-80.0
    add_child(voice)
    _voices.append(voice)

func _process(delta: float) -> void:
    var player: Node3D=get_tree().get_first_node_in_group("player") as Node3D
    if player==null: return
    _time+=delta*SettingsManager.ambient_motion
    if player.global_position.distance_to(Vector3(-55,0,-18))<60.0:
        var rotor: Node3D=_utility.get("turbine") as Node3D
        rotor.rotation.z=_time*0.6
    if player.global_position.distance_to(Vector3(0,10,-76))<80.0:
        var dish: Node3D=_roofs.get("dish") as Node3D
        dish.rotation.y=sin(_time*0.10)*0.9
    _poll-=delta
    if _poll>0.0: return
    _poll=0.3
    var busy: bool=not get_tree().get_nodes_in_group("active_district_event").is_empty()
    for voice in _voices:
        var near: bool=voice.global_position.distance_to(player.global_position)<28.0
        # Underground sound is not broadcast through the city roof.
        near=near and ((voice.position.y<0)==(player.global_position.y<-0.6))
        var level: float=SettingsManager.ambient_volume*SettingsManager.sfx_volume*(0.22 if busy else 0.38)
        voice.volume_db=linear_to_db(maxf(0.0001,level))
        if near and level>0.005 and not voice.playing: voice.play()
        elif (not near or level<=0.005) and voice.playing: voice.stop()

func completed_count() -> int:
    var count: int=0
    for console in consoles:
        if int(console.get("status"))==5: count+=1
    return count

extends "res://world/districts/civic_modules.gd"

# Infrastructure only: no RNG use, damage, actors, rewards or mission progression.
const ARCHIVE_SOUND: AudioStreamWAV = preload("res://assets/ambient/archive_ventilation.wav")
const GARDEN_SOUND: AudioStreamWAV = preload("res://assets/ambient/garden_rain.wav")
var carrier: Node3D = null
var board: Label3D = null
var irrigation: Node3D = null
var voices: Array[AudioStreamPlayer3D] = []
var _actor: Node3D = null
var _clock: float = 0.0
var _poll: float = 0.0
var _near_archive: bool = false
var _near_garden: bool = false
var _alert_archive: bool = false
var _alert_garden: bool = false
var _duck_archive: float = 1.0
var _duck_garden: float = 1.0
var _repair_time: float = 0.0

func _ready() -> void:
    physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
    init_palette()
    carrier=Node3D.new()
    carrier.name="IndexCourier"
    add_child(carrier)
    for entry in [[Vector3.ZERO,Vector3(1.1,0.6,0.8),0], [Vector3(0,0.37,0),Vector3(1.4,0.12,1.0),2], [Vector3(0,0,-0.41),Vector3(0.48,0.12,0.03),4]]:
        var part: Node3D=box("CourierPart",entry[0],entry[1],entry[2],false)
        remove_child(part)
        carrier.add_child(part)
    box("CourierRail",Vector3(51,11.0,-40),Vector3(17,0.18,0.20),1,false)
    board=sign_label("INDEX // STANDBY",Vector3(56.5,2.65,-3.82),27)
    irrigation=get_parent().get_node("memory_gardens/IrrigationArm") as Node3D
    _voice("ArchiveAir",ARCHIVE_SOUND,Vector3(51,5,-26),52.0)
    _voice("GardenAir",GARDEN_SOUND,Vector3(-52,3,48),48.0)
    SettingsManager.changed.connect(_apply_settings)
    _apply_settings()

func _voice(label: String, source: AudioStreamWAV, at: Vector3, distance: float) -> void:
    var voice: AudioStreamPlayer3D=AudioStreamPlayer3D.new()
    voice.name=label
    voice.position=at
    var stream: AudioStreamWAV=source.duplicate() as AudioStreamWAV
    stream.loop_mode=AudioStreamWAV.LOOP_FORWARD
    stream.loop_begin=0
    stream.loop_end=int(round(stream.get_length()*float(stream.mix_rate)))
    voice.stream=stream
    voice.max_distance=distance
    voice.unit_size=12.0
    voice.max_db=-12.0
    voice.volume_db=-30.0
    add_child(voice)
    voices.append(voice)

func _process(delta: float) -> void:
    if not is_instance_valid(_actor):
        _actor=get_tree().get_first_node_in_group("player") as Node3D
        return
    _poll-=delta
    if _poll<=0.0:
        _poll=0.20
        _update_proximity()
    _clock+=delta*SettingsManager.ambient_motion
    _repair_time=maxf(0.0,_repair_time-delta)
    _duck_archive=move_toward(_duck_archive,0.40 if _alert_archive else 1.0,delta*1.5)
    _duck_garden=move_toward(_duck_garden,0.40 if _alert_garden else 1.0,delta*1.5)
    _update_volumes()
    if carrier.visible:
        # Hold at the endpoints, then traverse a visible fixed overhead rail.
        var phase: float=fmod(_clock,20.0)
        var ratio: float=clampf((phase-2.0)/7.0,0.0,1.0) if phase<10.0 else 1.0-clampf((phase-12.0)/7.0,0.0,1.0)
        ratio=ratio*ratio*(3.0-2.0*ratio)
        carrier.position=Vector3(44+14*ratio,10.55,-40)
    if _near_garden and SettingsManager.ambient_motion>0.0:
        irrigation.rotation.y=_clock*0.22

func _update_proximity() -> void:
    _near_archive=_actor.global_position.distance_to(Vector3(51,3,-22))<58.0
    _near_garden=_actor.global_position.distance_to(Vector3(-50,3,45))<53.0
    var previous: bool=_alert_archive
    _alert_archive=false
    _alert_garden=false
    for entry in get_tree().get_nodes_in_group("enemies"):
        var enemy: Node3D=entry as Node3D
        if enemy==null:
            continue
        if enemy.global_position.distance_squared_to(Vector3(51,3,-22))<29.0*29.0:
            _alert_archive=true
        if enemy.global_position.distance_squared_to(Vector3(-50,3,45))<29.0*29.0:
            _alert_garden=true
        if _alert_archive and _alert_garden:
            break
    if previous and not _alert_archive:
        _repair_time=5.0
    if _alert_archive:
        board.text="INDEX // ACCESS SUSPENDED"
    elif _repair_time>0.0:
        board.text="INDEX // VERIFYING RECORDS"
    else:
        board.text="INDEX // RETRIEVING %04d" % (2800+int(_clock/5.0)%100)
    _apply_settings()

func _apply_settings() -> void:
    if carrier==null:
        return
    carrier.visible=_near_archive and SettingsManager.ambient_motion>0.0 and SettingsManager.quality_preset>0
    var enabled: bool=SettingsManager.ambient_volume*SettingsManager.sfx_volume>0.001
    for i in range(voices.size()):
        var near: bool=_near_archive if i==0 else _near_garden
        if enabled and near:
            if not voices[i].playing:
                voices[i].play()
        elif voices[i].playing:
            voices[i].stop()
    _update_volumes()

func _update_volumes() -> void:
    var gain: float=SettingsManager.ambient_volume*SettingsManager.sfx_volume
    for i in range(voices.size()):
        var duck: float=_duck_archive if i==0 else _duck_garden
        voices[i].volume_db=-18.0+linear_to_db(maxf(0.0001,gain*duck))

func _exit_tree() -> void:
    for voice in voices:
        if is_instance_valid(voice):
            voice.stop()

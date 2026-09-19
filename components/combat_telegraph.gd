extends RefCounted
class_name CombatTelegraph

# Cheap world-space telegraphs built from emissive primitive geometry.
# They deliberately avoid particles, textures and dynamic shadows so the same
# warning language stays readable through the ASCII post-process on Android.

static func ring(host: Node, center: Vector3, radius: float, duration: float, color: Color, segments: int = 24) -> Node3D:
    if host == null or not is_instance_valid(host):
        return null
    var safe_segments: int = clampi(segments, 10, 36)
    if RuntimeProfile.is_mobile:
        safe_segments = mini(safe_segments, 16)
    var root: Node3D = Node3D.new()
    root.name = "TelegraphRing"
    root.add_to_group("hostile_cues")
    host.add_child(root)
    root.global_position = center + Vector3.UP * 0.035

    var material: StandardMaterial3D = _make_material(color)
    var circumference: float = TAU * maxf(0.25, radius)
    var segment_length: float = maxf(0.20, (circumference / float(safe_segments)) * 0.64)
    for i in range(safe_segments):
        var angle: float = TAU * float(i) / float(safe_segments)
        var segment: MeshInstance3D = MeshInstance3D.new()
        var mesh: BoxMesh = BoxMesh.new()
        mesh.size = Vector3(segment_length, 0.035, 0.075)
        segment.mesh = mesh
        segment.material_override = material
        segment.position = Vector3(cos(angle) * radius, 0.0, sin(angle) * radius)
        segment.rotation.y = -angle
        root.add_child(segment)

    root.scale = Vector3.ONE * 0.92
    var tween: Tween = root.create_tween()
    tween.set_trans(Tween.TRANS_SINE)
    tween.set_ease(Tween.EASE_IN_OUT)
    tween.tween_property(root, "scale", Vector3.ONE * 1.035, maxf(0.03, duration * 0.55))
    tween.tween_property(root, "scale", Vector3.ONE, maxf(0.03, duration * 0.45))
    tween.tween_callback(root.queue_free)
    return root

static func line(host: Node, start: Vector3, end: Vector3, duration: float, color: Color, width: float = 0.10) -> Node3D:
    if host == null or not is_instance_valid(host):
        return null
    var flat_start: Vector3 = start
    var flat_end: Vector3 = end
    flat_start.y = flat_start.y + 0.04 # Also valid on floors below street level.
    flat_end.y = flat_start.y
    var delta: Vector3 = flat_end - flat_start
    var length: float = delta.length()
    if length < 0.25:
        return null

    var root: Node3D = Node3D.new()
    root.name = "TelegraphLine"
    root.add_to_group("hostile_cues")
    host.add_child(root)
    var segment: MeshInstance3D = MeshInstance3D.new()
    var mesh: BoxMesh = BoxMesh.new()
    mesh.size = Vector3(maxf(0.05, width), 0.035, length)
    segment.mesh = mesh
    segment.material_override = _make_material(color)
    root.add_child(segment)
    root.global_position = (flat_start + flat_end) * 0.5 + Vector3.UP * 0.02
    root.look_at(flat_end + Vector3.UP * 0.02, Vector3.UP)
    root.scale = Vector3(0.45, 1.0, 0.98)

    var tween: Tween = root.create_tween()
    tween.set_trans(Tween.TRANS_QUAD)
    tween.set_ease(Tween.EASE_OUT)
    tween.tween_property(root, "scale", Vector3(1.0, 1.0, 1.0), maxf(0.03, duration))
    tween.tween_callback(root.queue_free)
    return root

static func marker(host: Node, world_position: Vector3, text: String, duration: float, color: Color) -> void:
    if host == null or not is_instance_valid(host):
        return
    var label: Label3D = Label3D.new()
    label.add_to_group("hostile_cues")
    label.text = text
    label.font_size = 32
    label.modulate = color
    label.outline_size = 3
    label.outline_modulate = Color(0.0, 0.0, 0.0, 0.75)
    label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    host.add_child(label)
    label.global_position = world_position + Vector3.UP * 2.0
    label.scale = Vector3.ONE * 0.78
    var tween: Tween = label.create_tween()
    tween.set_parallel(true)
    tween.tween_property(label, "global_position", label.global_position + Vector3.UP * 0.28, maxf(0.05, duration))
    tween.tween_property(label, "scale", Vector3.ONE, maxf(0.05, duration))
    tween.set_parallel(false)
    tween.tween_callback(label.queue_free)

static func _make_material(color: Color) -> StandardMaterial3D:
    var material: StandardMaterial3D = StandardMaterial3D.new()
    material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    material.albedo_color = color
    material.emission_enabled = true
    material.emission = color
    material.emission_energy_multiplier = 5.0
    material.no_depth_test = false
    return material


static func beam(host: Node, start: Vector3, end: Vector3, duration: float, color: Color) -> Node3D:
    if not is_instance_valid(host) or start.distance_to(end) < 0.05:
        return null
    var root: Node3D = Node3D.new()
    root.name = "LockedAimCue"
    root.add_to_group("hostile_cues")
    host.add_child(root)
    root.global_position = (start + end) * 0.5
    root.look_at(end, Vector3.FORWARD if absf((end - start).normalized().y) > 0.98 else Vector3.UP)
    var mesh: BoxMesh = BoxMesh.new()
    mesh.size = Vector3(0.075, 0.075, start.distance_to(end))
    var line_mesh: MeshInstance3D = MeshInstance3D.new()
    line_mesh.mesh = mesh
    line_mesh.material_override = _make_material(color)
    line_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    root.add_child(line_mesh)
    var tween: Tween = root.create_tween()
    tween.tween_interval(maxf(0.05, duration))
    tween.tween_callback(root.queue_free)
    return root

static func sector(host: Node, feet: Vector3, facing: Vector3, reach: float,
        duration: float, color: Color, half_angle: float = 55.0) -> Node3D:
    if not is_instance_valid(host):
        return null
    var root: Node3D = Node3D.new()
    root.name = "MeleeSectorCue"
    root.add_to_group("hostile_cues")
    host.add_child(root)
    root.global_position = feet + Vector3.UP * 0.06
    var forward: Vector3 = Vector3(facing.x, 0.0, facing.z).normalized()
    var material: StandardMaterial3D = _make_material(color)
    for i in range(13):
        var angle: float = deg_to_rad(lerpf(-half_angle, half_angle, float(i) / 12.0))
        var ray: Vector3 = forward.rotated(Vector3.UP, angle)
        var mesh: BoxMesh = BoxMesh.new()
        mesh.size = Vector3(0.13, 0.06, 0.23)
        var stroke: MeshInstance3D = MeshInstance3D.new()
        stroke.mesh = mesh
        stroke.material_override = material
        stroke.position = ray * reach
        root.add_child(stroke)
        stroke.rotation.y = atan2(ray.x, ray.z)
    var tween: Tween = root.create_tween()
    tween.tween_interval(maxf(0.05, duration))
    tween.tween_callback(root.queue_free)
    return root

extends Node3D

# Static gameplay modules keep their collision at every graphics quality.
# Small trim is spatially batched; it never enters physics or navigation.
var mats: Array[StandardMaterial3D] = []
var _trim: Dictionary = {}
var _cube: BoxMesh = BoxMesh.new()
var solid_count: int = 0
var district_id: StringName = &""
const RAMP_SEAM_OVERLAP: float = 0.12

func init_palette() -> void:
    _cube.size = Vector3.ONE
    for tint in [Color(0.29, 0.28, 0.26), Color(0.15, 0.17, 0.19), Color(0.47, 0.44, 0.35), Color(0.74, 0.64, 0.42), Color(0.38, 0.48, 0.51)]:
        var mat: StandardMaterial3D = StandardMaterial3D.new()
        mat.albedo_color = tint
        mat.roughness = 0.76
        mat.metallic = 0.12
        mats.append(mat)
    # Accent is restrained and unshaded, not a new light on every prop.
    mats[3].shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    mats[4].shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

func box(label: String, at: Vector3, size_value: Vector3, material: int = 0, solid: bool = true, surface: StringName = &"") -> Node3D:
    var host: Node3D = StaticBody3D.new() if solid else Node3D.new()
    host.name = label
    host.position = at
    if solid:
        var body: StaticBody3D = host as StaticBody3D
        body.collision_layer = 1
        body.collision_mask = 0
        var shape: BoxShape3D = BoxShape3D.new()
        shape.size = size_value
        var collider: CollisionShape3D = CollisionShape3D.new()
        collider.shape = shape
        host.add_child(collider)
        solid_count += 1
    if not surface.is_empty():
        host.set_meta("nav_surface_id", surface)
        host.set_meta("district_id", district_id)
        host.add_to_group("walkable_surfaces")
    else:
        host.set_meta("nav_decoration", true)
    var mesh: MeshInstance3D = MeshInstance3D.new()
    var geometry: BoxMesh = BoxMesh.new()
    geometry.size = size_value
    mesh.mesh = geometry
    mesh.material_override = mats[material]
    host.add_child(mesh)
    add_child(host)
    return host

func deck(label: String, at: Vector3, footprint: Vector2, surface: StringName) -> void:
    box(label, at - Vector3.UP * 0.225, Vector3(footprint.x, 0.45, footprint.y), 0, true, surface)
    # A coherent edge and large seams survive glyph rendering better than bolts.
    trim(at + Vector3(0, 0.015, 0), Vector3(footprint.x - 0.2, 0.03, 0.08), 2)

func ramp(label: String, start: Vector3, finish: Vector3, width: float, surface: StringName) -> void:
    # A solid convex wedge, not a tilted slab whose underside blocks a landing.
    # The visible top and collision share the same points; no invisible stair wall.
    var travel: Vector3 = Vector3(finish.x - start.x, 0.0, finish.z - start.z).normalized()
    var sealed_start: Vector3 = start - travel * RAMP_SEAM_OVERLAP
    var sealed_finish: Vector3 = finish + travel * RAMP_SEAM_OVERLAP
    var across: Vector3 = Vector3(finish.z - start.z, 0.0, start.x - finish.x).normalized() * width * 0.5
    var floor_y: float = minf(start.y, finish.y) - 0.25
    var points: PackedVector3Array = PackedVector3Array([
        sealed_start - across, sealed_start + across, sealed_finish - across, sealed_finish + across,
        Vector3(sealed_start.x - across.x, floor_y, sealed_start.z - across.z),
        Vector3(sealed_start.x + across.x, floor_y, sealed_start.z + across.z),
        Vector3(sealed_finish.x - across.x, floor_y, sealed_finish.z - across.z),
        Vector3(sealed_finish.x + across.x, floor_y, sealed_finish.z + across.z)])
    var body: StaticBody3D = StaticBody3D.new()
    body.name = label
    body.collision_layer = 1
    body.collision_mask = 0
    body.set_meta("nav_surface_id", surface)
    body.set_meta("district_id", district_id)
    body.add_to_group("walkable_surfaces")
    var shape: ConvexPolygonShape3D = ConvexPolygonShape3D.new()
    shape.points = points
    var collision: CollisionShape3D = CollisionShape3D.new()
    collision.shape = shape
    body.add_child(collision)
    var tool: SurfaceTool = SurfaceTool.new()
    tool.begin(Mesh.PRIMITIVE_TRIANGLES)
    var indices: Array[int] = [0,2,1,1,2,3,0,1,4,1,5,4,2,6,3,3,6,7,0,4,2,2,4,6,1,3,5,3,7,5,4,5,6,5,7,6]
    for index in indices:
        tool.add_vertex(points[index])
    tool.generate_normals()
    var mesh: MeshInstance3D = MeshInstance3D.new()
    mesh.mesh = tool.commit()
    mesh.material_override = mats[0]
    body.add_child(mesh)
    add_child(body)
    solid_count += 1
    for side in [-0.93, 0.93]:
        rail(label + "Rail", start + across * side, finish + across * side)
    var segments: int = int(sealed_start.distance_to(sealed_finish) / 1.0)
    var slope: float = atan2(finish.y - start.y, Vector2(finish.x - start.x, finish.z - start.z).length())
    var yaw: float = atan2(finish.x - start.x, finish.z - start.z)
    for i in range(1, segments):
        var p: Vector3 = sealed_start.lerp(sealed_finish, float(i) / float(segments)) + Vector3.UP * 0.015
        trim(p, Vector3(width - 0.4, 0.026, 0.10), 2, Basis.from_euler(Vector3(-slope, yaw, 0)))

func rail(label: String, start: Vector3, finish: Vector3) -> void:
    var offset: Vector3 = finish - start
    var midpoint: Vector3 = start.lerp(finish, 0.5)
    var basis_value: Basis = Basis.looking_at(offset.normalized(), Vector3.UP)
    # Upper rail is real cover/collision; posts/curb never disappear with detail LOD.
    var host: Node3D = box(label, midpoint + Vector3.UP, Vector3(0.14, 0.18, offset.length()), 2)
    host.basis = basis_value
    var count: int = maxi(1, int(ceil(offset.length() / 3.0)))
    for i in range(count + 1):
        var p: Vector3 = start.lerp(finish, float(i) / float(count))
        box(label + "Post", p + Vector3.UP * 0.5, Vector3(0.12, 1.0, 0.12), 1, false)
    var curb: Node3D = box(label + "Curb", midpoint + Vector3.UP * 0.14, Vector3(0.20, 0.28, offset.length()), 0)
    curb.basis = basis_value

func sign_label(text: String, at: Vector3, size_value: int = 64, yaw: float = 0.0) -> Label3D:
    var label: Label3D = Label3D.new()
    label.text = text
    label.font_size = size_value
    label.pixel_size = 0.012
    label.modulate = Color(0.83, 0.76, 0.58)
    label.outline_modulate = Color(0.03, 0.025, 0.02)
    label.outline_size = 8
    label.position = at
    label.rotation.y = yaw
    add_child(label)
    return label

func trim(at: Vector3, dimensions: Vector3, material: int = 0, orientation: Basis = Basis.IDENTITY) -> void:
    var chunk: Vector2i = Vector2i(floori(at.x / 24.0), floori(at.z / 24.0))
    var key: Vector3i = Vector3i(chunk.x, material, chunk.y)
    var list: Array = _trim.get(key, [])
    var origin: Vector3 = Vector3(chunk.x * 24.0, 0, chunk.y * 24.0)
    list.append(Transform3D(orientation.scaled(dimensions), at - origin))
    _trim[key] = list

func commit_trim() -> void:
    for key in _trim:
        var list: Array = _trim[key]
        var multi: MultiMesh = MultiMesh.new()
        multi.transform_format = MultiMesh.TRANSFORM_3D
        multi.mesh = _cube
        multi.instance_count = list.size()
        for i in range(list.size()):
            multi.set_instance_transform(i, list[i])
        var node: MultiMeshInstance3D = MultiMeshInstance3D.new()
        node.multimesh = multi
        node.position = Vector3(key.x * 24.0, 0, key.z * 24.0)
        node.material_override = mats[key.y]
        node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
        node.visibility_range_end = 65.0 if RuntimeProfile.is_mobile else 105.0
        node.visibility_range_end_margin = 10.0
        add_child(node)
    _trim.clear()

func lamp(at: Vector3, warm: bool = true) -> void:
    box("Fixture", at, Vector3(1.2, 0.16, 0.65), 3 if warm else 4, false)
    var light: OmniLight3D = OmniLight3D.new()
    light.position = at - Vector3.UP * 0.20
    light.omni_range = 10.0
    light.light_color = Color(1.0, 0.80, 0.53) if warm else Color(0.72, 0.81, 0.86)
    light.light_energy = 1.4
    light.shadow_enabled = false
    light.distance_fade_enabled = true
    light.distance_fade_begin = 36.0
    light.distance_fade_length = 10.0
    light.add_to_group("audio_reactive_lights")
    light.set_meta("audio_band", 0 if warm else 2)
    add_child(light)

extends Node3D

const GROUND_CUTS = preload("res://world/districts/ground_cutouts.gd")
const LIVING_CITY = preload("res://world/districts/living_city_pass.gd")
const GROUND_SEAM_OVERLAP: float = 0.04

@export var seed = 7319
@export var arena_half_size: float = 82.0
@export_enum("test_arena", "threshold_market") var build_profile: String = "test_arena"

var rng = RandomNumberGenerator.new()
var dark_mat: StandardMaterial3D
var ground_mat: StandardMaterial3D
var window_mat: StandardMaterial3D
var red_mat: StandardMaterial3D
var cool_mat: StandardMaterial3D
var wet_mat: StandardMaterial3D

func _ready() -> void:
    rng.seed = seed
    _create_materials()
    if build_profile == "threshold_market":
        _create_threshold_market_location()
        return
    _create_ground()
    _create_boundaries()
    _create_city_ring()
    _create_monumental_facade()
    _create_street_lights()
    _create_trees()
    _create_cover()
    _create_plaza_lines()
    _create_sidewalks()
    _create_abandoned_vehicles()
    _create_street_props()
    _create_neon_signs()
    _create_data_beacons()
    _create_overhead_cables()
    _create_wet_patches()
    _create_shopfronts()
    _create_transit_arch()
    _create_micro_details()
    _create_large_road_network()
    _create_districts()
    _create_extended_lighting()
    _create_outer_skyline()
    var living: Node3D = preload("res://world/districts/living_city_pass.gd").new()
    living.name = "LivingDistricts"
    add_child(living)

func _create_threshold_market_location() -> void:
    # The authored sector owns its decks, walls and collision. It deliberately
    # does not inherit the old city-wide ground or its other five districts.
    _create_threshold_market_lighting()
    var living: Node3D = LIVING_CITY.new() as Node3D
    living.name = "LivingDistricts"
    living.set("first_location_only", true)
    add_child(living)

func _create_threshold_market_lighting() -> void:
    var sky_fill: SpotLight3D = SpotLight3D.new()
    sky_fill.name = "ThresholdMarketSkyFill"
    sky_fill.position = Vector3(52.0, 34.0, 47.0)
    sky_fill.spot_range = 100.0
    sky_fill.spot_angle = 58.0
    sky_fill.light_color = Color(0.34, 0.50, 0.82)
    sky_fill.light_energy = 2.6
    sky_fill.shadow_enabled = false
    sky_fill.add_to_group("audio_reactive_lights")
    sky_fill.set_meta("audio_band", 2)
    add_child(sky_fill)
    sky_fill.look_at(Vector3(52.0, 0.0, 47.0), Vector3.FORWARD)
    var fixture_data: Array[Dictionary] = [
        {"position": Vector3(44.0, 6.6, 29.0), "color": Color(0.28, 0.84, 1.0), "band": 2},
        {"position": Vector3(35.0, 7.0, 40.0), "color": Color(1.0, 0.42, 0.18), "band": 0},
        {"position": Vector3(70.0, 6.6, 58.0), "color": Color(0.96, 0.72, 0.34), "band": 1},
        {"position": Vector3(57.5, 8.2, 62.0), "color": Color(1.0, 0.18, 0.13), "band": 0}
    ]
    for fixture: Dictionary in fixture_data:
        var light: OmniLight3D = OmniLight3D.new()
        light.name = "ThresholdMarketRouteLight"
        light.position = fixture["position"] as Vector3
        light.light_color = fixture["color"] as Color
        light.light_energy = 2.1
        light.omni_range = 18.0
        light.shadow_enabled = false
        light.distance_fade_enabled = true
        light.distance_fade_begin = 30.0
        light.distance_fade_length = 8.0
        light.add_to_group("audio_reactive_lights")
        light.set_meta("audio_band", int(fixture["band"]))
        add_child(light)

func _create_materials() -> void:
    dark_mat = StandardMaterial3D.new()
    dark_mat.albedo_color = Color(0.21, 0.21, 0.23)
    dark_mat.metallic = 0.15
    dark_mat.roughness = 0.78

    ground_mat = StandardMaterial3D.new()
    ground_mat.albedo_color = Color(0.23, 0.235, 0.25)
    ground_mat.metallic = 0.12
    ground_mat.roughness = 0.66

    window_mat = StandardMaterial3D.new()
    window_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    window_mat.albedo_color = Color(1.0, 0.78, 0.38)
    window_mat.emission_enabled = true
    window_mat.emission = Color(1.0, 0.55, 0.14)
    window_mat.emission_energy_multiplier = 1.15

    red_mat = StandardMaterial3D.new()
    red_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    red_mat.albedo_color = Color(1.0, 0.03, 0.02)
    red_mat.emission_enabled = true
    red_mat.emission = Color(1.0, 0.01, 0.0)
    red_mat.emission_energy_multiplier = 1.25

    cool_mat = StandardMaterial3D.new()
    cool_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    cool_mat.albedo_color = Color(0.28, 0.62, 1.0)
    cool_mat.emission_enabled = true
    cool_mat.emission = Color(0.08, 0.35, 1.0)
    cool_mat.emission_energy_multiplier = 0.85

    wet_mat = StandardMaterial3D.new()
    wet_mat.albedo_color = Color(0.14, 0.15, 0.17)
    wet_mat.metallic = 0.24
    wet_mat.roughness = 0.09

func _create_ground() -> void:
    var half: float = arena_half_size + 10.0
    _cut_flat_surface(Rect2(-half,-half,half*2.0,half*2.0),-0.25,0.5,ground_mat,true)

func _cut_flat_surface(rect: Rect2, y: float, thickness: float, mat: StandardMaterial3D, solid: bool) -> void:
    for piece in GROUND_CUTS.pieces(rect):
        var body: Node3D = StaticBody3D.new() if solid else Node3D.new()
        body.name = "Ground" if solid else "Road"
        var center: Vector2 = piece.get_center()
        body.position = Vector3(center.x,y,center.y)
        # Ground pieces share edges after the opening cut. A small, matching
        # visual/physics overlap prevents renderer and capsule cracks at seams.
        var size_value: Vector3 = Vector3(piece.size.x + GROUND_SEAM_OVERLAP,thickness,piece.size.y + GROUND_SEAM_OVERLAP)
        var mesh: MeshInstance3D = MeshInstance3D.new()
        var geometry: BoxMesh = BoxMesh.new()
        geometry.size = size_value
        mesh.mesh = geometry
        mesh.material_override = mat
        body.add_child(mesh)
        if solid:
            var shape: BoxShape3D = BoxShape3D.new()
            shape.size = size_value
            var collider: CollisionShape3D = CollisionShape3D.new()
            collider.shape = shape
            (body as StaticBody3D).collision_layer = 1
            (body as StaticBody3D).collision_mask = 0
            body.add_child(collider)
        add_child(body)

func _create_boundaries() -> void:
    var thickness = 1.0
    var height = 5.0
    var span = arena_half_size * 2.0 + 6.0
    var walls = [
        [Vector3(0, height * 0.5, -arena_half_size - 1.5), Vector3(span, height, thickness)],
        [Vector3(0, height * 0.5, arena_half_size + 1.5), Vector3(span, height, thickness)],
        [Vector3(-arena_half_size - 1.5, height * 0.5, 0), Vector3(thickness, height, span)],
        [Vector3(arena_half_size + 1.5, height * 0.5, 0), Vector3(thickness, height, span)]
    ]
    for data in walls:
        var body = StaticBody3D.new()
        body.collision_layer = 1
        body.position = data[0]
        add_child(body)
        var shape = CollisionShape3D.new()
        var box = BoxShape3D.new()
        box.size = data[1]
        shape.shape = box
        body.add_child(shape)

func _create_city_ring() -> void:
    for side in 4:
        for i in range(-9, 10):
            var width = rng.randf_range(6.0, 11.5)
            var depth = rng.randf_range(6.0, 12.0)
            var height = rng.randf_range(12.0, 38.0)
            var offset = float(i) * 9.2 + rng.randf_range(-1.2, 1.2)
            var pos = Vector3.ZERO
            match side:
                0: pos = Vector3(offset, height * 0.5, -arena_half_size - 8.0 - depth * 0.5)
                1: pos = Vector3(offset, height * 0.5, arena_half_size + 8.0 + depth * 0.5)
                2: pos = Vector3(-arena_half_size - 8.0 - depth * 0.5, height * 0.5, offset)
                3: pos = Vector3(arena_half_size + 8.0 + depth * 0.5, height * 0.5, offset)
            _create_building(pos, Vector3(width, height, depth), side)

func _create_building(pos: Vector3, size: Vector3, side: int) -> void:
    var building = MeshInstance3D.new()
    var mesh = BoxMesh.new()
    mesh.size = size
    building.mesh = mesh
    building.material_override = dark_mat
    building.position = pos
    building.add_to_group("city_buildings")
    building.set_meta("facade_side", side)
    add_child(building)

    var bands = clampi(int(size.y / 2.8), 4, 13)
    for b in range(bands):
        if rng.randf() < 0.15:
            continue
        var strip = MeshInstance3D.new()
        var strip_mesh = BoxMesh.new()
        if side <= 1:
            strip_mesh.size = Vector3(size.x * rng.randf_range(0.50, 0.92), 0.16, 0.08)
            strip.position = pos + Vector3(0.0, -size.y * 0.5 + 1.8 + b * 2.55, (-size.z * 0.5 - 0.05) if side == 1 else (size.z * 0.5 + 0.05))
        else:
            strip_mesh.size = Vector3(0.08, 0.16, size.z * rng.randf_range(0.50, 0.92))
            strip.position = pos + Vector3((size.x * 0.5 + 0.05) if side == 2 else (-size.x * 0.5 - 0.05), -size.y * 0.5 + 1.8 + b * 2.55, 0.0)
        strip.mesh = strip_mesh
        strip.material_override = window_mat
        add_child(strip)

    if rng.randf() < 0.35:
        var antenna = MeshInstance3D.new()
        var antenna_mesh = BoxMesh.new()
        antenna_mesh.size = Vector3(0.12, rng.randf_range(2.0, 5.0), 0.12)
        antenna.mesh = antenna_mesh
        antenna.material_override = red_mat
        antenna.position = pos + Vector3(0.0, size.y * 0.5 + antenna_mesh.size.y * 0.5, 0.0)
        add_child(antenna)

func _create_monumental_facade() -> void:
    var facade = MeshInstance3D.new()
    var facade_mesh = BoxMesh.new()
    facade_mesh.size = Vector3(32.0, 13.0, 4.0)
    facade.mesh = facade_mesh
    facade.material_override = dark_mat
    facade.add_to_group("city_solid")
    facade.position = Vector3(0, 6.5, -67.0)
    add_child(facade)

    for row in range(4):
        for col in range(9):
            if (row + col) % 7 == 0:
                continue
            var window = MeshInstance3D.new()
            var wm = BoxMesh.new()
            wm.size = Vector3(2.1, 0.75, 0.08)
            window.mesh = wm
            window.material_override = window_mat
            window.position = Vector3(-10.8 + col * 2.7, 3.0 + row * 2.15, -64.94)
            add_child(window)

    var emblem = MeshInstance3D.new()
    var emblem_mesh = BoxMesh.new()
    emblem_mesh.size = Vector3(0.45, 5.5, 0.10)
    emblem.mesh = emblem_mesh
    emblem.material_override = cool_mat
    emblem.position = Vector3(0, 7.0, -64.88)
    add_child(emblem)

func _create_street_lights() -> void:
    var positions = [
        Vector3(-14, 0, -24), Vector3(14, 0, -24),
        Vector3(-14, 0, -16), Vector3(14, 0, -16),
        Vector3(-14, 0, -8), Vector3(14, 0, -8),
        Vector3(-14, 0, 0), Vector3(14, 0, 0),
        Vector3(-14, 0, 8), Vector3(14, 0, 8),
        Vector3(-14, 0, 16), Vector3(14, 0, 16),
        Vector3(-14, 0, 24), Vector3(14, 0, 24),
        Vector3(-27, 0, -21), Vector3(27, 0, -21),
        Vector3(-27, 0, 20), Vector3(27, 0, 20)
    ]
    for p in positions:
        _create_lamp(p)

func _create_lamp(pos: Vector3) -> void:
    var pole = MeshInstance3D.new()
    var cylinder = CylinderMesh.new()
    cylinder.top_radius = 0.08
    cylinder.bottom_radius = 0.11
    cylinder.height = 4.8
    pole.mesh = cylinder
    pole.material_override = dark_mat
    pole.position = pos + Vector3(0, 2.4, 0)
    add_child(pole)

    var bulb = MeshInstance3D.new()
    var sphere = SphereMesh.new()
    sphere.radius = 0.18
    sphere.height = 0.36
    bulb.mesh = sphere
    bulb.material_override = window_mat
    bulb.position = pos + Vector3(0, 4.75, 0)
    add_child(bulb)

    var light = OmniLight3D.new()
    light.light_color = Color(1.0, 0.62, 0.28)
    light.light_energy = 3.6
    light.omni_range = 14.0
    light.shadow_enabled = false
    light.position = pos + Vector3(0, 4.6, 0)
    light.add_to_group("audio_reactive_lights")
    light.set_meta("audio_band", 0 if pos.z < 0.0 else 1)
    if not _is_mobile_runtime() or int(absf(pos.x + pos.z)) % 3 == 0:
        add_child(light)

func _create_trees() -> void:
    var positions = [
        Vector3(-26, 0, -12), Vector3(26, 0, -12),
        Vector3(-25, 0, 7), Vector3(25, 0, 7),
        Vector3(-18, 0, 25), Vector3(18, 0, 25)
    ]
    for p in positions:
        var trunk = MeshInstance3D.new()
        var trunk_mesh = CylinderMesh.new()
        trunk_mesh.top_radius = 0.16
        trunk_mesh.bottom_radius = 0.22
        trunk_mesh.height = 2.2
        trunk.add_to_group("city_solid")
        trunk.mesh = trunk_mesh
        trunk.material_override = dark_mat
        trunk.position = p + Vector3(0, 1.1, 0)
        add_child(trunk)

        for layer in range(3):
            var crown = MeshInstance3D.new()
            var cone = CylinderMesh.new()
            cone.top_radius = 0.05
            cone.bottom_radius = 2.0 - layer * 0.38
            cone.height = 2.9
            crown.mesh = cone
            crown.material_override = dark_mat
            crown.position = p + Vector3(0, 2.4 + layer * 1.55, 0)
            add_child(crown)

        var spark = MeshInstance3D.new()
        var sm = SphereMesh.new()
        sm.radius = 0.11
        sm.height = 0.22
        spark.mesh = sm
        spark.material_override = window_mat
        spark.position = p + Vector3(0, 6.4, 0)
        add_child(spark)

func _create_cover() -> void:
    var points = [
        Vector3(-8, 0.8, -8), Vector3(10, 0.7, -2), Vector3(-12, 0.9, 10),
        Vector3(7, 0.8, 14), Vector3(18, 0.75, 5), Vector3(-20, 0.75, -3)
    ]
    for p in points:
        var body = StaticBody3D.new()
        body.collision_layer = 1
        body.position = p
        add_child(body)
        var mi = MeshInstance3D.new()
        var bm = BoxMesh.new()
        bm.size = Vector3(rng.randf_range(2.2, 4.5), rng.randf_range(1.1, 1.8), rng.randf_range(1.8, 3.6))
        mi.mesh = bm
        mi.material_override = dark_mat
        body.add_child(mi)
        var cs = CollisionShape3D.new()
        var bs = BoxShape3D.new()
        bs.size = bm.size
        cs.shape = bs
        body.add_child(cs)

func _create_plaza_lines() -> void:
    for z in range(-28, 29, 7):
        var line = MeshInstance3D.new()
        var lm = BoxMesh.new()
        lm.size = Vector3(26.0, 0.018, 0.055)
        line.mesh = lm
        line.material_override = window_mat if z % 14 == 0 else cool_mat
        line.position = Vector3(0.0, 0.018, float(z))
        add_child(line)


func _create_sidewalks() -> void:
    var strips: Array = [
        [Vector3(-29.5, 0.055, 0), Vector3(4.2, 0.11, 64.0)],
        [Vector3(29.5, 0.055, 0), Vector3(4.2, 0.11, 64.0)],
        [Vector3(0, 0.055, -29.5), Vector3(55.0, 0.11, 3.5)],
        [Vector3(0, 0.055, 29.5), Vector3(55.0, 0.11, 3.5)]
    ]
    for data in strips:
        var sidewalk: MeshInstance3D = MeshInstance3D.new()
        var mesh: BoxMesh = BoxMesh.new()
        mesh.size = data[1]
        sidewalk.mesh = mesh
        sidewalk.material_override = dark_mat
        sidewalk.position = data[0]
        add_child(sidewalk)

    for i in range(-4, 5):
        var curb_light: MeshInstance3D = MeshInstance3D.new()
        var curb_mesh: BoxMesh = BoxMesh.new()
        curb_mesh.size = Vector3(0.06, 0.035, 4.2)
        curb_light.mesh = curb_mesh
        curb_light.material_override = cool_mat if i % 3 == 0 else window_mat
        curb_light.position = Vector3(-27.25, 0.12, float(i) * 6.0)
        add_child(curb_light)
        var curb_light_r: MeshInstance3D = MeshInstance3D.new()
        curb_light_r.mesh = curb_mesh
        curb_light_r.material_override = curb_light.material_override
        curb_light_r.position = Vector3(27.25, 0.12, float(i) * 6.0)
        add_child(curb_light_r)

func _create_abandoned_vehicles() -> void:
    var positions: Array = [
        [Vector3(-21, 0.42, -15), 0.12], [Vector3(20, 0.42, -4), -0.20],
        [Vector3(-17, 0.42, 17), 0.32], [Vector3(22, 0.42, 20), -0.12],
        [Vector3(4, 0.42, -27), 1.52], [Vector3(-7, 0.42, 27), 1.62]
    ]
    for data in positions:
        _create_vehicle(data[0], float(data[1]))

func _create_vehicle(pos: Vector3, yaw: float) -> void:
    var root: Node3D = Node3D.new()
    root.position = pos
    root.rotation.y = yaw
    add_child(root)

    var body: MeshInstance3D = MeshInstance3D.new()
    var body_mesh: BoxMesh = BoxMesh.new()
    body_mesh.size = Vector3(1.75, 0.52, 3.7)
    body.add_to_group("city_solid")
    body.mesh = body_mesh
    body.material_override = dark_mat
    root.add_child(body)

    var cabin: MeshInstance3D = MeshInstance3D.new()
    var cabin_mesh: BoxMesh = BoxMesh.new()
    cabin_mesh.size = Vector3(1.52, 0.58, 1.75)
    cabin.add_to_group("city_solid")
    cabin.mesh = cabin_mesh
    cabin.material_override = dark_mat
    cabin.position = Vector3(0, 0.47, 0.18)
    root.add_child(cabin)

    for side in [-1.0, 1.0]:
        for z in [-1.18, 1.18]:
            var wheel: MeshInstance3D = MeshInstance3D.new()
            var wheel_mesh: CylinderMesh = CylinderMesh.new()
            wheel_mesh.top_radius = 0.28
            wheel_mesh.bottom_radius = 0.28
            wheel_mesh.height = 0.20
            wheel.mesh = wheel_mesh
            wheel.material_override = dark_mat
            wheel.rotation_degrees = Vector3(0, 0, 90)
            wheel.position = Vector3(side * 0.90, -0.20, z)
            root.add_child(wheel)

    for x in [-0.52, 0.52]:
        var tail: MeshInstance3D = MeshInstance3D.new()
        var tail_mesh: BoxMesh = BoxMesh.new()
        tail_mesh.size = Vector3(0.30, 0.16, 0.05)
        tail.mesh = tail_mesh
        tail.material_override = red_mat
        tail.position = Vector3(x, 0.05, 1.88)
        root.add_child(tail)

func _create_street_props() -> void:
    var bench_positions: Array[Vector3] = [
        Vector3(-25.0, 0.35, -8.0), Vector3(-25.0, 0.35, 11.0),
        Vector3(25.0, 0.35, -13.0), Vector3(25.0, 0.35, 7.0)
    ]
    for p in bench_positions:
        var seat: MeshInstance3D = MeshInstance3D.new()
        var seat_mesh: BoxMesh = BoxMesh.new()
        seat_mesh.size = Vector3(2.5, 0.18, 0.62)
        seat.mesh = seat_mesh
        seat.material_override = dark_mat
        seat.position = p
        add_child(seat)
        var back: MeshInstance3D = MeshInstance3D.new()
        var back_mesh: BoxMesh = BoxMesh.new()
        back_mesh.size = Vector3(2.5, 0.72, 0.14)
        back.mesh = back_mesh
        back.material_override = dark_mat
        back.position = p + Vector3(0, 0.45, 0.28)
        add_child(back)

    for i in range(-5, 6):
        if i == 0:
            continue
        var bollard: MeshInstance3D = MeshInstance3D.new()
        var mesh: CylinderMesh = CylinderMesh.new()
        mesh.top_radius = 0.09
        mesh.bottom_radius = 0.13
        mesh.height = 0.82
        bollard.mesh = mesh
        bollard.material_override = dark_mat
        bollard.position = Vector3(float(i) * 4.4, 0.41, -31.0)
        add_child(bollard)
        if i % 2 == 0:
            var cap: MeshInstance3D = MeshInstance3D.new()
            var cap_mesh: SphereMesh = SphereMesh.new()
            cap_mesh.radius = 0.10
            cap_mesh.height = 0.20
            cap.mesh = cap_mesh
            cap.material_override = cool_mat
            cap.position = bollard.position + Vector3.UP * 0.45
            add_child(cap)

func _create_neon_signs() -> void:
    var signs: Array = [
        [Vector3(-31.2, 5.0, -12.0), Vector3(0, 90, 0), "INDEX // 01", Color(0.38, 0.72, 1.0)],
        [Vector3(31.2, 7.0, 4.0), Vector3(0, -90, 0), "MEMORY IS ORDER", Color(1.0, 0.42, 0.10)],
        [Vector3(-10.0, 6.0, -38.7), Vector3(0, 0, 0), "SECTOR ONLINE", Color(0.52, 0.82, 1.0)]
    ]
    for data in signs:
        var panel: MeshInstance3D = MeshInstance3D.new()
        var pm: BoxMesh = BoxMesh.new()
        pm.size = Vector3(5.6, 1.5, 0.12)
        panel.mesh = pm
        panel.material_override = dark_mat
        panel.position = data[0]
        panel.rotation_degrees = data[1]
        add_child(panel)

        var label: Label3D = Label3D.new()
        label.text = String(data[2])
        label.font_size = 52
        label.modulate = data[3]
        label.outline_size = 5
        label.outline_modulate = Color(0.0, 0.0, 0.0, 0.82)
        label.position = data[0]
        label.rotation_degrees = data[1]
        var sign_rotation: Vector3 = data[1]
        var yaw: float = deg_to_rad(sign_rotation.y)
        var face_offset: Vector3 = Vector3(sin(yaw), 0.0, cos(yaw)) * -0.10
        label.position += face_offset
        add_child(label)

func _create_data_beacons() -> void:
    var points: Array[Vector3] = [
        Vector3(-4, 0, -14), Vector3(5, 0, -6), Vector3(-6, 0, 5), Vector3(4, 0, 15)
    ]
    for i in range(points.size()):
        var p: Vector3 = points[i]
        var pillar: MeshInstance3D = MeshInstance3D.new()
        var pm: BoxMesh = BoxMesh.new()
        pm.size = Vector3(0.32, 2.2, 0.32)
        pillar.mesh = pm
        pillar.material_override = dark_mat
        pillar.position = p + Vector3.UP * 1.1
        add_child(pillar)

        var core_strip: MeshInstance3D = MeshInstance3D.new()
        var sm: BoxMesh = BoxMesh.new()
        sm.size = Vector3(0.08, 1.55, 0.36)
        core_strip.mesh = sm
        core_strip.material_override = cool_mat if i % 2 == 0 else window_mat
        core_strip.position = p + Vector3(0, 1.2, -0.18)
        add_child(core_strip)

        if not _is_mobile_runtime():
            var light: OmniLight3D = OmniLight3D.new()
            light.light_color = Color(0.30, 0.64, 1.0) if i % 2 == 0 else Color(1.0, 0.52, 0.16)
            light.light_energy = 1.8
            light.omni_range = 6.0
            light.shadow_enabled = false
            light.position = p + Vector3.UP * 1.35
            add_child(light)

func _create_overhead_cables() -> void:
    var cable_data: Array = [
        [Vector3(0, 8.5, -34), Vector3(54, 0.055, 0.055)],
        [Vector3(0, 11.0, 34), Vector3(50, 0.055, 0.055)],
        [Vector3(-34, 9.5, 0), Vector3(0.055, 0.055, 50)],
        [Vector3(34, 12.0, 0), Vector3(0.055, 0.055, 54)]
    ]
    for data in cable_data:
        var cable: MeshInstance3D = MeshInstance3D.new()
        var mesh: BoxMesh = BoxMesh.new()
        mesh.size = data[1]
        cable.mesh = mesh
        cable.material_override = dark_mat
        cable.position = data[0]
        add_child(cable)

func _create_wet_patches() -> void:
    # Thin low-roughness surfaces catch the existing emissive city lighting.
    # They are deliberately meshes rather than a screen-space reflection effect,
    # which keeps the Android path inexpensive and still reads well through ASCII.
    for i in range(14):
        var patch: MeshInstance3D = MeshInstance3D.new()
        var mesh: BoxMesh = BoxMesh.new()
        mesh.size = Vector3(rng.randf_range(2.4, 7.2), 0.012, rng.randf_range(0.8, 2.6))
        patch.mesh = mesh
        patch.material_override = wet_mat
        patch.position = Vector3(rng.randf_range(-24.0, 24.0), 0.018, rng.randf_range(-27.0, 27.0))
        patch.rotation.y = rng.randf_range(-0.35, 0.35)
        add_child(patch)

func _create_shopfronts() -> void:
    var storefronts: Array = [
        [Vector3(-32.0, 1.55, -20.0), Vector3(0, 90, 0), Color(0.30, 0.72, 1.0)],
        [Vector3(-32.0, 1.55, 2.0), Vector3(0, 90, 0), Color(1.0, 0.48, 0.12)],
        [Vector3(-32.0, 1.55, 21.0), Vector3(0, 90, 0), Color(0.70, 0.30, 1.0)],
        [Vector3(32.0, 1.55, -17.0), Vector3(0, -90, 0), Color(1.0, 0.30, 0.18)],
        [Vector3(32.0, 1.55, 5.0), Vector3(0, -90, 0), Color(0.32, 0.78, 1.0)],
        [Vector3(32.0, 1.55, 23.0), Vector3(0, -90, 0), Color(1.0, 0.68, 0.22)]
    ]
    for index in range(storefronts.size()):
        var data: Array = storefronts[index]
        var root: Node3D = Node3D.new()
        root.position = data[0]
        root.rotation_degrees = data[1]
        add_child(root)

        var shell: MeshInstance3D = MeshInstance3D.new()
        var shell_mesh: BoxMesh = BoxMesh.new()
        shell_mesh.size = Vector3(5.8, 3.1, 0.35)
        shell.add_to_group("city_solid")
        shell.mesh = shell_mesh
        shell.material_override = dark_mat
        root.add_child(shell)

        var glow_mat: StandardMaterial3D = StandardMaterial3D.new()
        glow_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
        glow_mat.albedo_color = data[2]
        glow_mat.emission_enabled = true
        glow_mat.emission = data[2]
        glow_mat.emission_energy_multiplier = 5.4

        for col in range(3):
            var window: MeshInstance3D = MeshInstance3D.new()
            var window_mesh: BoxMesh = BoxMesh.new()
            window_mesh.size = Vector3(1.45, 1.55, 0.045)
            window.mesh = window_mesh
            window.material_override = glow_mat
            window.position = Vector3(-1.75 + float(col) * 1.75, -0.15, -0.205)
            root.add_child(window)

        var canopy: MeshInstance3D = MeshInstance3D.new()
        var canopy_mesh: BoxMesh = BoxMesh.new()
        canopy_mesh.size = Vector3(5.5, 0.10, 1.0)
        canopy.mesh = canopy_mesh
        canopy.material_override = dark_mat
        canopy.position = Vector3(0.0, 1.05, -0.58)
        root.add_child(canopy)

        var strip: MeshInstance3D = MeshInstance3D.new()
        var strip_mesh: BoxMesh = BoxMesh.new()
        strip_mesh.size = Vector3(4.8, 0.08, 0.08)
        strip.mesh = strip_mesh
        strip.material_override = glow_mat
        strip.position = Vector3(0.0, 1.12, -1.04)
        root.add_child(strip)

        if not _is_mobile_runtime() and index % 2 == 0:
            var light: OmniLight3D = OmniLight3D.new()
            light.light_color = data[2]
            light.light_energy = 1.55
            light.omni_range = 7.0
            light.shadow_enabled = false
            light.position = Vector3(0.0, 0.6, -1.35)
            root.add_child(light)

func _create_transit_arch() -> void:
    var z: float = -31.0
    for x in [-9.5, 9.5]:
        var pillar: MeshInstance3D = MeshInstance3D.new()
        var pillar_mesh: BoxMesh = BoxMesh.new()
        pillar_mesh.size = Vector3(1.2, 7.2, 1.2)
        pillar.mesh = pillar_mesh
        pillar.material_override = dark_mat
        pillar.position = Vector3(x, 3.6, z)
        add_child(pillar)

    var beam: MeshInstance3D = MeshInstance3D.new()
    var beam_mesh: BoxMesh = BoxMesh.new()
    beam_mesh.size = Vector3(20.2, 1.0, 1.25)
    beam.mesh = beam_mesh
    beam.material_override = dark_mat
    beam.position = Vector3(0.0, 7.0, z)
    add_child(beam)

    var gate_signal: MeshInstance3D = MeshInstance3D.new()
    var signal_mesh: BoxMesh = BoxMesh.new()
    signal_mesh.size = Vector3(16.0, 0.10, 0.12)
    gate_signal.mesh = signal_mesh
    gate_signal.material_override = cool_mat
    gate_signal.position = Vector3(0.0, 6.75, z - 0.68)
    add_child(gate_signal)

    var label: Label3D = Label3D.new()
    label.text = "TRANSIT // MEMORY GATE 01"
    label.font_size = 48
    label.modulate = Color(0.55, 0.82, 1.0)
    label.outline_size = 5
    label.outline_modulate = Color(0.0, 0.0, 0.0, 0.8)
    label.position = Vector3(0.0, 7.15, z - 0.76)
    add_child(label)

func _create_micro_details() -> void:
    for lane in [-5.0, 5.0]:
        for z in range(-25, 26, 5):
            var mark: MeshInstance3D = MeshInstance3D.new()
            var mark_mesh: BoxMesh = BoxMesh.new()
            mark_mesh.size = Vector3(0.14, 0.018, 2.0)
            mark.mesh = mark_mesh
            mark.material_override = window_mat if int(z / 5) % 4 == 0 else dark_mat
            mark.position = Vector3(lane, 0.024, float(z))
            add_child(mark)

    var cabinet_points: Array[Vector3] = [
        Vector3(-24.5, 0.7, -19.0), Vector3(-24.5, 0.7, 2.0), Vector3(-24.5, 0.7, 20.0),
        Vector3(24.5, 0.7, -15.0), Vector3(24.5, 0.7, 9.0), Vector3(24.5, 0.7, 23.0)
    ]
    for i in range(cabinet_points.size()):
        var cabinet: MeshInstance3D = MeshInstance3D.new()
        var cabinet_mesh: BoxMesh = BoxMesh.new()
        cabinet_mesh.size = Vector3(0.85, 1.4, 0.62)
        cabinet.mesh = cabinet_mesh
        cabinet.material_override = dark_mat
        cabinet.position = cabinet_points[i]
        add_child(cabinet)

        var indicator: MeshInstance3D = MeshInstance3D.new()
        var indicator_mesh: BoxMesh = BoxMesh.new()
        indicator_mesh.size = Vector3(0.10, 0.32, 0.04)
        indicator.mesh = indicator_mesh
        indicator.material_override = cool_mat if i % 2 == 0 else red_mat
        indicator.position = cabinet_points[i] + Vector3(0.0, 0.18, -0.34)
        add_child(indicator)

func _is_mobile_runtime() -> bool:
    return OS.has_feature("mobile") or OS.get_name() == "Android" or OS.get_name() == "iOS"

# v0.8 expands the playable footprint from ~72x72 to ~164x164. That is a little
# over five times the previous playable area, while keeping expensive real lights sparse.
func _create_large_road_network() -> void:
    var road_axes: Array[float] = [-54.0, 0.0, 54.0]
    for axis in road_axes:
        var span: float = arena_half_size*2.0-8.0
        _cut_flat_surface(Rect2(-span*0.5,axis-7.5,span,15.0),0.012,0.025,wet_mat,false)
        _cut_flat_surface(Rect2(axis-7.5,-span*0.5,15.0,span),0.013,0.025,wet_mat,false)

    for x in [-60.0, -48.0, -6.0, 6.0, 48.0, 60.0]:
        for z in range(-72, 73, 12):
            var marker: MeshInstance3D = MeshInstance3D.new()
            var marker_mesh: BoxMesh = BoxMesh.new()
            marker_mesh.size = Vector3(0.10, 0.02, 4.0)
            marker.mesh = marker_mesh
            marker.material_override = cool_mat if int(z / 12) % 3 == 0 else window_mat
            marker.position = Vector3(x, 0.03, float(z))
            if not GROUND_CUTS.overlaps(marker.position,marker_mesh.size):
                add_child(marker)
            else:
                marker.free()

    for z in [-60.0, -48.0, -6.0, 6.0, 48.0, 60.0]:
        for x in range(-72, 73, 12):
            var marker: MeshInstance3D = MeshInstance3D.new()
            var marker_mesh: BoxMesh = BoxMesh.new()
            marker_mesh.size = Vector3(4.0, 0.02, 0.10)
            marker.mesh = marker_mesh
            marker.material_override = cool_mat if int(x / 12) % 3 == 0 else window_mat
            marker.position = Vector3(float(x), 0.032, z)
            if not GROUND_CUTS.overlaps(marker.position,marker_mesh.size):
                add_child(marker)
            else:
                marker.free()

func _create_districts() -> void:
    var districts: Array = [
        [Vector3(50, 0, -20), "ARCHIVE ROW", Color(0.26, 0.66, 1.0)],
        [Vector3(-52, 0, -18), "UTILITY SPINE", Color(1.0, 0.42, 0.14)],
        [Vector3(45, 0, 43), "MARKET RUINS", Color(1.0, 0.74, 0.28)],
        [Vector3(-45, 0, 44), "MEMORY GARDENS", Color(0.35, 0.86, 0.62)],
        [Vector3(0, 0, -64), "NULL TERMINAL", Color(0.88, 0.18, 0.16)],
        [Vector3(0, 0, 65), "SIGNAL CONCOURSE", Color(0.42, 0.72, 1.0)]
    ]
    for entry_value in districts:
        var entry: Array = entry_value
        var center: Vector3 = entry[0]
        var district_name: String = String(entry[1])
        var accent: Color = entry[2]
        # Consume the legacy RNG sequence, then replace only the authored districts.
        # Other districts and skyline retain their established procedural layout.
        var first_child: int = get_child_count()
        _create_district_cluster(center, district_name, accent)
        if district_name in ["MARKET RUINS", "SIGNAL CONCOURSE", "ARCHIVE ROW", "MEMORY GARDENS", "UTILITY SPINE", "NULL TERMINAL"]:
            while get_child_count() > first_child:
                var old: Node = get_child(first_child)
                remove_child(old)
                old.free()

func _create_district_cluster(center: Vector3, district_name: String, accent: Color) -> void:
    var accent_mat: StandardMaterial3D = StandardMaterial3D.new()
    accent_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    accent_mat.albedo_color = accent
    accent_mat.emission_enabled = true
    accent_mat.emission = accent
    accent_mat.emission_energy_multiplier = 1.25

    var pad: MeshInstance3D = MeshInstance3D.new()
    var pad_mesh: BoxMesh = BoxMesh.new()
    pad_mesh.size = Vector3(34.0, 0.035, 30.0)
    pad.mesh = pad_mesh
    pad.material_override = ground_mat
    pad.position = center + Vector3(0, 0.02, 0)
    add_child(pad)

    var facade_offsets: Array[Vector3] = [
        Vector3(-14, 0, -12), Vector3(14, 0, -12),
        Vector3(-14, 0, 12), Vector3(14, 0, 12)
    ]
    for i in range(facade_offsets.size()):
        var height: float = rng.randf_range(7.0, 14.0)
        var facade: MeshInstance3D = MeshInstance3D.new()
        var facade_mesh: BoxMesh = BoxMesh.new()
        facade_mesh.size = Vector3(rng.randf_range(8.0, 12.0), height, 2.4)
        facade.mesh = facade_mesh
        facade.material_override = dark_mat
        facade.position = center + facade_offsets[i] + Vector3(0, height * 0.5, 0)
        facade.rotation.y = PI if i >= 2 else 0.0
        facade.add_to_group("city_buildings")
        facade.set_meta("facade_side", 0 if i >= 2 else 1)
        add_child(facade)
        for band in range(3):
            var light_band: MeshInstance3D = MeshInstance3D.new()
            var band_mesh: BoxMesh = BoxMesh.new()
            band_mesh.size = Vector3(facade_mesh.size.x * 0.72, 0.12, 0.08)
            light_band.mesh = band_mesh
            light_band.material_override = accent_mat if band == 1 else window_mat
            light_band.position = facade.position + Vector3(0, -height * 0.28 + band * height * 0.25, -1.24 if i < 2 else 1.24)
            add_child(light_band)

    for corner in [Vector3(-12, 0, -9), Vector3(12, 0, -9), Vector3(-12, 0, 9), Vector3(12, 0, 9)]:
        var pylon: MeshInstance3D = MeshInstance3D.new()
        var pylon_mesh: CylinderMesh = CylinderMesh.new()
        pylon_mesh.top_radius = 0.16
        pylon_mesh.bottom_radius = 0.34
        pylon_mesh.height = 4.6
        pylon.add_to_group("city_solid")
        pylon.mesh = pylon_mesh
        pylon.material_override = dark_mat
        pylon.position = center + corner + Vector3(0, 2.3, 0)
        add_child(pylon)

        var cap: MeshInstance3D = MeshInstance3D.new()
        var cap_mesh: SphereMesh = SphereMesh.new()
        cap_mesh.radius = 0.20
        cap_mesh.height = 0.40
        cap.mesh = cap_mesh
        cap.material_override = accent_mat
        cap.position = center + corner + Vector3(0, 4.6, 0)
        add_child(cap)

    var label: Label3D = Label3D.new()
    label.text = district_name + " // ONLINE"
    label.font_size = 42
    label.modulate = accent
    label.outline_size = 5
    label.outline_modulate = Color(0, 0, 0, 0.85)
    label.position = center + Vector3(0, 5.0, -13.4)
    add_child(label)

    for detail_index in range(8):
        var angle: float = float(detail_index) / 8.0 * TAU
        var radius: float = 7.0 + float(detail_index % 3) * 1.3
        var console: MeshInstance3D = MeshInstance3D.new()
        var console_mesh: BoxMesh = BoxMesh.new()
        console_mesh.size = Vector3(0.8, 1.1, 0.55)
        console.add_to_group("city_solid")
        console.mesh = console_mesh
        console.material_override = dark_mat
        console.position = center + Vector3(cos(angle) * radius, 0.55, sin(angle) * radius)
        console.rotation.y = -angle
        add_child(console)
        var console_light: MeshInstance3D = MeshInstance3D.new()
        var console_light_mesh: BoxMesh = BoxMesh.new()
        console_light_mesh.size = Vector3(0.42, 0.26, 0.04)
        console_light.mesh = console_light_mesh
        console_light.material_override = accent_mat
        console_light.position = console.position + Vector3(0, 0.17, -0.30)
        console_light.rotation = console.rotation
        add_child(console_light)

func _create_extended_lighting() -> void:
    var points: Array[Vector3] = [
        Vector3(38,0,-34), Vector3(60,0,-34), Vector3(38,0,-8), Vector3(60,0,-8),
        Vector3(-40,0,-32), Vector3(-62,0,-32), Vector3(-40,0,-6), Vector3(-62,0,-6),
        Vector3(34,0,31), Vector3(58,0,31), Vector3(34,0,55), Vector3(58,0,55),
        Vector3(-34,0,32), Vector3(-58,0,32), Vector3(-34,0,56), Vector3(-58,0,56),
        Vector3(-14,0,-66), Vector3(14,0,-66), Vector3(-14,0,64), Vector3(14,0,64)
    ]
    for point in points:
        # Authored modules provide four lights; avoid poles through gallery floors.
        if (point.x > 25.0 and point.z > 25.0) or (absf(point.x) < 20.0 and point.z > 55.0):
            continue
        if (point.x > 29.0 and point.z < 7.0 and point.z > -44.0) or (point.x < -25.0 and point.z > 18.0):
            continue
        _create_lamp(point)

func _create_outer_skyline() -> void:
    for side in range(4):
        for index in range(-7, 8):
            if index % 2 == 0:
                continue
            var height: float = rng.randf_range(28.0, 58.0)
            var width: float = rng.randf_range(5.0, 9.0)
            var depth: float = rng.randf_range(5.0, 10.0)
            var offset: float = float(index) * 11.0
            var pos: Vector3 = Vector3.ZERO
            var edge: float = arena_half_size + 18.0
            match side:
                0:
                    pos = Vector3(offset, height * 0.5, -edge)
                1:
                    pos = Vector3(offset, height * 0.5, edge)
                2:
                    pos = Vector3(-edge, height * 0.5, offset)
                3:
                    pos = Vector3(edge, height * 0.5, offset)
            _create_building(pos, Vector3(width, height, depth), side)

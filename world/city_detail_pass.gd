extends Node3D

# New small geometry is batched by material and 24 m cell, not one node per bolt.
# The walkable deck/ramps retain visible geometry and collision at every quality level.
const CHUNK_SIZE: float = 24.0
var _materials: Array[Material] = []
var _batches: Dictionary = {}
var _batch_origins: Dictionary = {}
var _batch_materials: Dictionary = {}
var _instances: Array[MultiMeshInstance3D] = []
var _cube: BoxMesh = null

func _ready() -> void:
    _cube = BoxMesh.new()
    _cube.size = Vector3.ONE
    _make_materials()
    _decorate_facades()
    _street_shelter(Vector3(-23.0, 0.0, 30.0), 0.0)
    _street_shelter(Vector3(23.0, 0.0, -28.0), PI)
    _drains_and_service_boxes()
    _service_walkway(Vector3(-28.0, 0.0, -42.0))
    _commit_batches()
    SettingsManager.changed.connect(_apply_quality)
    _apply_quality()

func _make_materials() -> void:
    for tint in [Color(0.28, 0.31, 0.35), Color(0.12, 0.15, 0.18), Color(0.52, 0.47, 0.34), Color(0.28, 0.43, 0.48)]:
        var material: StandardMaterial3D = StandardMaterial3D.new()
        material.albedo_color = tint
        material.roughness = 0.76
        material.metallic = 0.08
        _materials.append(material)

func _box(position_value: Vector3, dimensions: Vector3, material_index: int,
        rotation_value: Vector3 = Vector3.ZERO) -> void:
    var chunk_x: int = int(floor(position_value.x / CHUNK_SIZE))
    var chunk_z: int = int(floor(position_value.z / CHUNK_SIZE))
    var key: String = "%d:%d:%d" % [material_index, chunk_x, chunk_z]
    var origin: Vector3 = Vector3((float(chunk_x) + 0.5) * CHUNK_SIZE, 0.0, (float(chunk_z) + 0.5) * CHUNK_SIZE)
    var transforms: Array = _batches.get(key, [])
    var basis_value: Basis = Basis.from_euler(rotation_value).scaled(dimensions)
    transforms.append(Transform3D(basis_value, position_value - origin))
    _batches[key] = transforms
    _batch_origins[key] = origin
    _batch_materials[key] = material_index

func _facade_part(origin: Vector3, yaw: float, point: Vector3, dimensions: Vector3, mat_index: int) -> void:
    _box(origin + Basis(Vector3.UP, yaw) * point, dimensions, mat_index, Vector3(0.0, yaw, 0.0))

func _decorate_facades() -> void:
    for entry in get_tree().get_nodes_in_group("city_buildings"):
        var building: MeshInstance3D = entry as MeshInstance3D
        if building == null or not (building.mesh is BoxMesh):
            continue
        if absf(building.position.x) > 96.0 or absf(building.position.z) > 96.0:
            continue
        var dimensions: Vector3 = (building.mesh as BoxMesh).size
        var side: int = int(building.get_meta("facade_side", 0))
        var yaw: float = 0.0
        if side == 1:
            yaw = PI
        elif side == 2:
            yaw = PI * 0.5
        elif side == 3:
            yaw = -PI * 0.5
        var half_depth: float = dimensions.z * 0.5 if side < 2 else dimensions.x * 0.5
        var origin: Vector3 = Vector3(building.position.x, 0.0, building.position.z)
        origin += Basis(Vector3.UP, yaw) * Vector3(0.0, 0.0, half_depth + 0.06)
        # Recessed dark door, frame, canopy, segmented service panel, conduit.
        _facade_part(origin, yaw, Vector3(0.0, 1.25, 0.03), Vector3(1.8, 2.5, 0.08), 1)
        for x in [-1.05, 1.05]:
            _facade_part(origin, yaw, Vector3(x, 1.35, 0.14), Vector3(0.16, 2.7, 0.22), 0)
        _facade_part(origin, yaw, Vector3(0.0, 2.7, 0.17), Vector3(2.25, 0.16, 0.30), 2)
        _facade_part(origin, yaw, Vector3(0.0, 3.0, 0.55), Vector3(2.8, 0.18, 1.15), 0)
        _facade_part(origin, yaw, Vector3(0.0, 1.3, 0.12), Vector3(0.055, 2.5, 0.05), 2)
        _facade_part(origin, yaw, Vector3(2.6, 1.5, 0.14), Vector3(1.25, 1.2, 0.24), 1)
        for j in range(6):
            _facade_part(origin, yaw, Vector3(2.6, 1.03 + j * 0.18, 0.29), Vector3(1.1, 0.065, 0.06), 0)
        _facade_part(origin, yaw, Vector3(-2.8, 2.6, 0.18), Vector3(0.13, 5.2, 0.17), 0)
        for height in [0.7, 2.4, 4.1]:
            _facade_part(origin, yaw, Vector3(-2.8, height, 0.24), Vector3(0.30, 0.12, 0.20), 2)
        # Break up the large flat wall with a cornice and pilasters, not extra lights.
        var width: float = minf(9.5, dimensions.x * 0.90)
        _facade_part(origin, yaw, Vector3(0.0, 4.9, 0.18), Vector3(width, 0.14, 0.32), 0)
        for x in [-3.7, 3.7]:
            _facade_part(origin, yaw, Vector3(x, 3.5, 0.08), Vector3(0.18, 7.0, 0.16), 0)

func _street_shelter(origin: Vector3, yaw: float) -> void:
    for x in [-2.5, 2.5]:
        for z in [-0.8, 0.8]:
            _facade_part(origin, yaw, Vector3(x, 1.35, z), Vector3(0.13, 2.7, 0.13), 0)
    _facade_part(origin, yaw, Vector3(0.0, 2.75, 0.0), Vector3(5.5, 0.20, 2.1), 0)
    _facade_part(origin, yaw, Vector3(0.0, 1.30, 0.85), Vector3(5.1, 2.3, 0.10), 1)
    _facade_part(origin, yaw, Vector3(0.0, 0.53, 0.35), Vector3(3.8, 0.15, 0.48), 2)
    for x in [-1.55, 1.55]:
        _facade_part(origin, yaw, Vector3(x, 0.24, 0.35), Vector3(0.12, 0.48, 0.30), 0)
    for x in [-2.2, -1.1, 0.0, 1.1, 2.2]:
        _facade_part(origin, yaw, Vector3(x, 2.65, -0.88), Vector3(0.45, 0.08, 0.08), 3)

func _drains_and_service_boxes() -> void:
    for side in [-1.0, 1.0]:
        for index in range(-5, 6):
            var point: Vector3 = Vector3(side * 9.0, 0.04, float(index) * 12.0)
            _box(point, Vector3(0.8, 0.025, 1.0), 1)
            for bar in range(5):
                _box(point + Vector3(0.0, 0.02, -0.4 + bar * 0.20), Vector3(0.74, 0.025, 0.055), 0)
        for index in range(-2, 3):
            var origin: Vector3 = Vector3(side * 18.0, 0.0, float(index) * 19.0)
            _box(origin + Vector3.UP * 0.65, Vector3(0.9, 1.3, 0.7), 0)
            _box(origin + Vector3(0.0, 1.38, 0.0), Vector3(1.0, 0.10, 0.8), 1)
            _box(origin + Vector3(-0.18, 0.94, -0.37), Vector3(0.28, 0.15, 0.035), 3)
            for slot in range(5):
                _box(origin + Vector3(0.0, 0.25 + slot * 0.10, -0.36), Vector3(0.63, 0.035, 0.04), 1)

func _solid_box(label: String, position_value: Vector3, dimensions: Vector3, tilt: float = 0.0) -> void:
    var body: StaticBody3D = StaticBody3D.new()
    body.name = label
    body.position = position_value
    body.rotation.x = tilt
    body.collision_layer = 1
    add_child(body)
    var visual: MeshInstance3D = MeshInstance3D.new()
    var shape_mesh: BoxMesh = BoxMesh.new()
    shape_mesh.size = dimensions
    visual.mesh = shape_mesh
    visual.material_override = _materials[0]
    body.add_child(visual)
    var collider: CollisionShape3D = CollisionShape3D.new()
    var box_shape: BoxShape3D = BoxShape3D.new()
    box_shape.size = dimensions
    collider.shape = box_shape
    body.add_child(collider)

func _service_walkway(origin: Vector3) -> void:
    _solid_box("ServiceDeck", origin + Vector3(0.0, 2.0, 0.0), Vector3(4.0, 0.25, 10.0))
    var slope: float = atan2(2.0, 6.0)
    _solid_box("SouthRamp", origin + Vector3(0.0, 1.0, 8.0), Vector3(4.0, 0.25, sqrt(40.0)), slope)
    _solid_box("NorthRamp", origin + Vector3(0.0, 1.0, -8.0), Vector3(4.0, 0.25, sqrt(40.0)), -slope)
    for side in [-1.0, 1.0]:
        _box(origin + Vector3(side * 1.9, 3.1, 0.0), Vector3(0.10, 0.10, 10.0), 2)
        for z in range(-4, 5, 2):
            _box(origin + Vector3(side * 1.9, 2.6, float(z)), Vector3(0.10, 1.1, 0.10), 0)
            _box(origin + Vector3(side * 1.7, 0.9, float(z)), Vector3(0.18, 1.8, 0.18), 1)
    for z in range(-4, 5):
        _box(origin + Vector3(0.0, 2.135, float(z)), Vector3(3.8, 0.018, 0.055), 2)

func _commit_batches() -> void:
    for key in _batches:
        var transforms: Array = _batches[key]
        var multimesh: MultiMesh = MultiMesh.new()
        multimesh.transform_format = MultiMesh.TRANSFORM_3D
        multimesh.mesh = _cube
        multimesh.instance_count = transforms.size()
        for index in range(transforms.size()):
            var transform_value: Transform3D = transforms[index]
            multimesh.set_instance_transform(index, transform_value)
        var instance: MultiMeshInstance3D = MultiMeshInstance3D.new()
        instance.multimesh = multimesh
        instance.position = _batch_origins[key]
        instance.material_override = _materials[int(_batch_materials[key])]
        instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
        add_child(instance)
        _instances.append(instance)
    _batches.clear()

func _apply_quality() -> void:
    var distance: float = 52.0 if SettingsManager.quality_preset <= 1 else 100.0
    for instance in _instances:
        instance.visibility_range_end = distance
        instance.visibility_range_end_margin = 8.0

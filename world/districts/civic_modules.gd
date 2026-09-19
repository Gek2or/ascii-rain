extends "res://world/districts/city_modules.gd"

# Curved civic silhouettes share the same simple physics and spatial trim batches.
# Only authored decks/ramp tops are navigation surfaces. Roofs are not walkways.
func column(label: String, at: Vector3, height: float, radius: float, material: int = 0, solid: bool = true) -> Node3D:
    var host: Node3D = StaticBody3D.new() if solid else Node3D.new()
    host.name = label
    host.position = at
    host.set_meta("nav_decoration", true)
    if solid:
        var body: StaticBody3D = host as StaticBody3D
        body.collision_layer = 1
        body.collision_mask = 0
        var shape: CylinderShape3D = CylinderShape3D.new()
        shape.height = height
        shape.radius = radius
        var collision: CollisionShape3D = CollisionShape3D.new()
        collision.shape = shape
        body.add_child(collision)
        solid_count += 1
    var geometry: CylinderMesh = CylinderMesh.new()
    geometry.height = height
    geometry.top_radius = radius * 0.85
    geometry.bottom_radius = radius
    geometry.radial_segments = 12
    geometry.rings = 1
    var visual: MeshInstance3D = MeshInstance3D.new()
    visual.mesh = geometry
    visual.material_override = mats[material]
    host.add_child(visual)
    add_child(host)
    return host

func arch(label: String, center: Vector3, radius: float, thickness: float, depth: float, material: int = 0) -> void:
    # Upper semicircle. At the lowest point it must already clear the largest mob.
    var tool: SurfaceTool = SurfaceTool.new()
    tool.begin(Mesh.PRIMITIVE_TRIANGLES)
    var segments: int = 16
    for i in range(segments):
        var a: float = PI * float(i) / float(segments)
        var b: float = PI * float(i + 1) / float(segments)
        var points: PackedVector3Array = PackedVector3Array()
        for z in [-depth * 0.5, depth * 0.5]:
            for data in [[a, radius], [b, radius], [a, radius + thickness], [b, radius + thickness]]:
                points.append(center + Vector3(cos(data[0]) * data[1], sin(data[0]) * data[1], z))
        for index in [0,1,2,1,3,2,4,6,5,5,6,7,0,4,1,1,4,5,2,3,6,3,7,6,0,2,4,2,6,4,1,5,3,3,5,7]:
            tool.add_vertex(points[index])
    tool.generate_normals()
    var mesh: ArrayMesh = tool.commit()
    var host: StaticBody3D = StaticBody3D.new()
    host.name = label
    host.collision_layer = 1
    host.collision_mask = 0
    host.set_meta("nav_decoration", true)
    var collision: CollisionShape3D = CollisionShape3D.new()
    collision.shape = mesh.create_trimesh_shape()
    host.add_child(collision)
    var visual: MeshInstance3D = MeshInstance3D.new()
    visual.mesh = mesh
    var double_sided: StandardMaterial3D = mats[material].duplicate() as StandardMaterial3D
    double_sided.cull_mode = BaseMaterial3D.CULL_DISABLED
    visual.material_override = double_sided
    host.add_child(visual)
    add_child(host)
    solid_count += 1

func branch(at: Vector3, end: Vector3, radius: float, material: int = 1) -> void:
    var offset: Vector3 = end - at
    var host: Node3D = column("ArtificialBranch", at.lerp(end, 0.5), offset.length(), radius, material, false)
    var up: Vector3 = offset.normalized()
    var axis: Vector3 = Vector3.UP.cross(up)
    if axis.length_squared() > 0.0001:
        host.basis = Basis(axis.normalized(), acos(clampf(Vector3.UP.dot(up), -1.0, 1.0)))

func floor_insets(at: Vector3, count: int, step: Vector3) -> void:
    for i in range(count):
        trim(at + step * float(i), Vector3(0.5, 0.026, 0.24), 3)

extends Node3D

# Add primitive physics shapes to existing visible architecture. No new visible
# meshes/materials, no concave triangle soup, no per-frame rebuild. Small trim,
# lamps, leaves and purely decorative flat markings remain non-solid.
var collider_count: int = 0
func _ready() -> void:
    var sources: Array[Node] = get_tree().get_nodes_in_group("city_buildings")
    for tagged in get_tree().get_nodes_in_group("city_solid"):
        if not sources.has(tagged):
            sources.append(tagged)
    for source in sources:
        var mesh_node: MeshInstance3D = source as MeshInstance3D
        if mesh_node == null or mesh_node.has_node("PhysicsSolid"):
            continue
        if absf(mesh_node.global_position.x) > 83.0 or absf(mesh_node.global_position.z) > 83.0:
            continue
        var shape: Shape3D = null
        if mesh_node.mesh is BoxMesh:
            var box: BoxShape3D = BoxShape3D.new()
            box.size = (mesh_node.mesh as BoxMesh).size
            shape = box
        elif mesh_node.mesh is CylinderMesh:
            var cylinder: CylinderShape3D = CylinderShape3D.new()
            var mesh: CylinderMesh = mesh_node.mesh as CylinderMesh
            cylinder.height = mesh.height
            cylinder.radius = maxf(mesh.top_radius, mesh.bottom_radius)
            shape = cylinder
        if shape == null:
            continue
        var body: StaticBody3D = StaticBody3D.new()
        body.name = "PhysicsSolid"
        body.collision_layer = 1
        body.collision_mask = 0
        var collision: CollisionShape3D = CollisionShape3D.new()
        collision.shape = shape
        body.add_child(collision)
        # Parenting preserves all yaw/scale/position values of the visible mesh.
        mesh_node.add_child(body)
        collider_count += 1

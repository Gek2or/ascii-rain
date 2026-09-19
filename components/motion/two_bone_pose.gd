extends RefCounted

# Analytic two-bone pose. Articulated meshes point along local -Y.
static func solve(upper: Node3D, lower: Node3D, target: Vector3,
        pole: Vector3, upper_length: float, lower_length: float) -> void:
    var origin: Vector3 = upper.global_position
    var difference: Vector3 = target - origin
    var distance: float = clampf(difference.length(), absf(upper_length - lower_length) + 0.001,
        upper_length + lower_length - 0.001)
    var direction: Vector3 = difference.normalized()
    if direction.length_squared() < 0.1:
        direction = Vector3.DOWN
    var bend: Vector3 = pole - origin
    bend -= direction * bend.dot(direction)
    if bend.length_squared() < 0.001:
        bend = direction.cross(Vector3.RIGHT)
        if bend.length_squared() < 0.001:
            bend = direction.cross(Vector3.FORWARD)
    bend = bend.normalized()
    var along: float = (upper_length * upper_length - lower_length * lower_length + distance * distance) / (2.0 * distance)
    var height: float = sqrt(maxf(0.0, upper_length * upper_length - along * along))
    var knee: Vector3 = origin + direction * along + bend * height
    var end: Vector3 = origin + direction * distance
    var plane_normal: Vector3 = direction.cross(bend).normalized()
    _orient(upper, origin, knee, plane_normal)
    _orient(lower, knee, end, plane_normal)

static func _orient(bone: Node3D, origin: Vector3, end: Vector3, normal: Vector3) -> void:
    var y_axis: Vector3 = (origin - end).normalized()
    var z_axis: Vector3 = normal.cross(y_axis).normalized()
    var x_axis: Vector3 = y_axis.cross(z_axis).normalized()
    bone.global_transform = Transform3D(Basis(x_axis, y_axis, z_axis).orthonormalized(), origin)

extends RefCounted
class_name AsciiFX

const GLYPHS = ["#", "%", "@", "*", "+", "=", "0", "1", ":", ".", "/", "\\", "|", "<", ">"]
const GLYPH_SCENE: PackedScene = preload("res://scenes/AsciiGlyph.tscn")

static func _emit(host: Node, text: String, world_position: Vector3, color: Color,
        font_size: int, start_scale: float, end_position: Vector3, duration: float,
        outline_size: int, outline_alpha: float) -> void:
    var glyph: Node = PoolManager.spawn(GLYPH_SCENE, host)
    if glyph == null or not glyph.has_method("configure"):
        return
    glyph.call("configure", text, world_position, color, font_size, start_scale,
        end_position, duration, outline_size, outline_alpha)

static func burst(host: Node, world_position: Vector3, color: Color, count: int = 12, radius: float = 3.2) -> void:
    if host == null or not is_instance_valid(host):
        return
    var rng: RandomNumberGenerator = RandomNumberGenerator.new()
    rng.randomize()
    for i in range(count):
        var start_position: Vector3 = world_position + Vector3(
            rng.randf_range(-0.45, 0.45),
            rng.randf_range(0.15, 1.6),
            rng.randf_range(-0.45, 0.45)
        )
        var direction: Vector3 = Vector3(
            rng.randf_range(-1.0, 1.0),
            rng.randf_range(0.2, 1.25),
            rng.randf_range(-1.0, 1.0)
        ).normalized()
        var end_position: Vector3 = start_position + direction * rng.randf_range(radius * 0.45, radius)
        _emit(host, GLYPHS[rng.randi_range(0, GLYPHS.size() - 1)], start_position, color,
            rng.randi_range(24, 42), 1.0, end_position, rng.randf_range(0.34, 0.62), 2, 0.42)

static func impact(host: Node, world_position: Vector3, color: Color, heavy: bool = false) -> void:
    burst(host, world_position, color, 14 if heavy else 7, 2.8 if heavy else 1.5)
    if host == null or not is_instance_valid(host):
        return
    var ring_position: Vector3 = world_position + Vector3.UP * 0.18
    _emit(host, "<  +  >" if heavy else "<+>", ring_position, color,
        40 if heavy else 28, 0.35, ring_position + Vector3.UP * 0.08,
        0.16, 3, 0.32)

static func dash_echo(host: Node, world_position: Vector3, color: Color) -> void:
    if host == null or not is_instance_valid(host):
        return
    var echo_position: Vector3 = world_position + Vector3.UP * 1.1
    _emit(host, "// @ //", echo_position, Color(color.r, color.g, color.b, 0.76),
        34, 0.68, echo_position + Vector3.UP * 0.18, 0.18, 2, 0.22)

static func melee_slash(host: Node, world_position: Vector3, color: Color, facing: Vector3) -> void:
    if host == null or not is_instance_valid(host):
        return
    var right: Vector3 = facing.cross(Vector3.UP).normalized()
    if right.length_squared() < 0.01:
        right = Vector3.RIGHT
    for i in range(5):
        var t: float = float(i) / 4.0
        var slash_position: Vector3 = world_position + Vector3.UP * (0.55 + t * 1.1) + right * ((t - 0.5) * 1.4)
        _emit(host, "/" if i % 2 == 0 else "\\", slash_position,
            Color(color.r, color.g, color.b, 0.88), 38, 1.0,
            slash_position + facing * 0.7, 0.16, 0, 0.0)

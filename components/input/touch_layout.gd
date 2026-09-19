extends RefCounted

# Pure geometry is shared by the touch router, its drawn UI and regression tests.
static func build(viewport_size: Vector2, user_scale: float) -> Dictionary:
    var scale_factor: float = clampf(minf(viewport_size.x / 1280.0, viewport_size.y / 720.0), 0.55, 1.3)
    scale_factor *= clampf(user_scale, 0.8, 1.25)
    var right: float = viewport_size.x - 22.0 * scale_factor
    var bottom: float = viewport_size.y - 22.0 * scale_factor
    var buttons: Dictionary = {}
    buttons[&"shoot"] = Rect2(Vector2(right - 122.0 * scale_factor, bottom - 194.0 * scale_factor), Vector2(116.0, 110.0) * scale_factor)
    buttons[&"aim"] = Rect2(Vector2(right - 122.0 * scale_factor, bottom - 276.0 * scale_factor), Vector2(116.0, 64.0) * scale_factor)
    buttons[&"dash"] = Rect2(Vector2(right - 254.0 * scale_factor, bottom - 80.0 * scale_factor), Vector2(112.0, 70.0) * scale_factor)
    buttons[&"jump"] = Rect2(Vector2(right - 384.0 * scale_factor, bottom - 80.0 * scale_factor), Vector2(112.0, 70.0) * scale_factor)
    buttons[&"interact"] = Rect2(Vector2(right - 254.0 * scale_factor, bottom - 174.0 * scale_factor), Vector2(112.0, 70.0) * scale_factor)
    buttons[&"weapon_next"] = Rect2(Vector2(right - 384.0 * scale_factor, bottom - 174.0 * scale_factor), Vector2(112.0, 70.0) * scale_factor)
    return {
        "scale": scale_factor,
        "center": Vector2(111.0 * scale_factor, bottom - 93.0 * scale_factor),
        "radius": 75.0 * scale_factor,
        "buttons": buttons,
        "look": Rect2(Vector2(viewport_size.x * 0.34, viewport_size.y * 0.28), Vector2(viewport_size.x * 0.66, viewport_size.y * 0.72))
    }

static func stick_axis(position: Vector2, center: Vector2, radius: float) -> Vector2:
    return ((position - center) / maxf(radius, 1.0)).limit_length(1.0)

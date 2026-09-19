extends SceneTree
const LEGACY_BINDING = preload("res://tests/legacy_glyph_binding.gd")
# Real native CanvasItem execution, not a translated GLSL test.
# Run with a display and an isolated user profile via the native QA helper.
const BINDING = preload("res://rendering/ascii_atlas_binding.gd")
const POST: Shader = preload("res://shaders/ascii_post.gdshader")
const LEVELS: Array[float] = [0.0, 0.005, 0.02, 0.05, 0.10, 0.15, 0.20, 0.30, 0.50, 0.80, 1.0]
var checks: int = 0
var failures: int = 0
var results: Array = []

func _initialize() -> void:
    call_deferred("_run")

func _check(condition: bool, message: String) -> void:
    checks += 1
    if not condition:
        failures += 1
        push_error("VISUAL_BALANCE: " + message)

func _draw_image(view: SubViewport) -> Image:
    for frame in range(3):
        await process_frame
    await RenderingServer.frame_post_draw
    return view.get_texture().get_image()

func _statistics(image: Image, cell: Vector2i, band: int) -> Dictionary:
    var total: float = 0.0
    var squares: float = 0.0
    var maximum: float = 0.0
    var minimum: float = 1.0
    for y in range(cell.y):
        for x in range(cell.x):
            var pixel: Color = image.get_pixel((band * 6 + 2) * cell.x + x, cell.y * 2 + y)
            var value: float = (pixel.r + pixel.g + pixel.b) / 3.0
            total += value
            squares += value * value
            maximum = maxf(maximum, value)
            minimum = minf(minimum, value)
    var count: float = float(cell.x * cell.y)
    var average: float = total / count
    return {"mean": average, "std": sqrt(maxf(0.0, squares / count - average * average)), "max": maximum, "min": minimum}

func _run() -> void:
    var legacy: Shader = Shader.new()
    legacy.code = FileAccess.get_file_as_string("res://tests/fixtures/ascii_post_v0_10.gdshader.txt")
    for width in range(4, 11):
        var cell: Vector2i = Vector2i(width, int(floor(float(width) * 1.5 + 0.5)))
        var viewport: SubViewport = SubViewport.new()
        viewport.size = Vector2i(width * 6 * LEVELS.size(), cell.y * 6)
        viewport.disable_3d = true
        viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
        root.add_child(viewport)
        for band in range(LEVELS.size()):
            var patch: ColorRect = ColorRect.new()
            patch.position = Vector2(band * width * 6, 0)
            patch.size = Vector2(width * 6, cell.y * 6)
            var value: float = LEVELS[band]
            patch.color = Color(value, value, value, 1.0)
            viewport.add_child(patch)
        var effect: ColorRect = ColorRect.new()
        effect.size = Vector2(viewport.size)
        var material: ShaderMaterial = ShaderMaterial.new()
        material.shader = POST
        BINDING.apply(material, float(width))
        material.set_shader_parameter("bloom_strength", 0.0)
        effect.material = material
        viewport.add_child(effect)
        var current: Image = await _draw_image(viewport)
        var previous: float = -1.0
        var rows: Array = []
        for band in range(LEVELS.size()):
            var row: Dictionary = _statistics(current, cell, band)
            _check(float(row["mean"]) >= previous - 0.004, "non-monotone tone at width %d band %d" % [width, band])
            previous = float(row["mean"])
            row["input"] = LEVELS[band]
            rows.append(row)
        _check(float(rows[0]["max"]) < 0.004, "black input must remain black")
        _check(float(rows[5]["min"]) > 0.025, "midtone surface bed must not disappear")
        _check(float(rows[6]["max"]) < 0.50, "dim 0.20 must not create white letters")
        _check(float(rows[8]["std"]) > 0.012, "midtones must retain real glyph strokes")
        var repeated: Image = await _draw_image(viewport)
        _check(current.get_data() == repeated.get_data(), "static input must not flicker")
        material.shader = legacy
        BINDING.apply(material, float(width))
        LEGACY_BINDING.apply(material, width)
        material.set_shader_parameter("bloom_strength", 0.0)
        var old_image: Image = await _draw_image(viewport)
        var old_dim: Dictionary = _statistics(old_image, cell, 6)
        _check(float(rows[6]["std"]) < float(old_dim["std"]) * 0.50, "flat-background glyph noise must drop at least 50 percent")
        _check(float(rows[6]["max"]) < float(old_dim["max"]) * 0.80, "dim stroke peak must decrease")
        results.append({"width": width, "balanced": rows, "legacy_020": old_dim})
        viewport.queue_free()
        await process_frame
    DirAccess.make_dir_recursive_absolute("user://captures")
    var report: FileAccess = FileAccess.open("user://captures/visual_balance_native.json", FileAccess.WRITE)
    report.store_string(JSON.stringify({"checks": checks, "failures": failures, "engine": Engine.get_version_info(), "results": results}, "  "))
    report.close()
    root.get_node("AudioManager").call("stop_all")
    # Allow the asynchronous Dummy audio backend to release playback before exit.
    root.get_node("AudioManager/DistrictMusic").stream = null
    await create_timer(0.35, true, false, true).timeout
    root.get_node("AudioManager").queue_free()
    legacy = null
    for cleanup_frame in range(12):
        await physics_frame
    print("VISUAL_BALANCE_NATIVE: ", checks, " checks / ", failures, " failures")
    quit(0 if failures == 0 else 1)

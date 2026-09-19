extends RefCounted

const SURFACE_SHADER: Shader = preload("res://shaders/actor_readability.gdshader")
static var _cache: Dictionary = {}

# Share armor materials. Cores, muzzle flashes and telegraphs keep their original shaders.
static func apply(root: Node, is_player: bool) -> void:
    for child in root.get_children():
        if child is MeshInstance3D:
            var mesh: MeshInstance3D = child as MeshInstance3D
            var source: StandardMaterial3D = mesh.material_override as StandardMaterial3D
            if mesh.has_meta("readability_original"):
                source = mesh.get_meta("readability_original") as StandardMaterial3D
            if source != null and source.shading_mode != BaseMaterial3D.SHADING_MODE_UNSHADED:
                mesh.set_meta("readability_original", source)
                var key: String = "%d:%s" % [source.get_instance_id(), str(is_player)]
                var material: ShaderMaterial = _cache.get(key) as ShaderMaterial
                if material == null:
                    material = ShaderMaterial.new()
                    material.shader = SURFACE_SHADER
                    material.set_meta("readability_player",is_player)
                    var tint: Color = source.albedo_color
                    # Preserve material differences; the old per-channel floor made
                    # boots, weapon and armor the same emissive white silhouette.
                    if is_player:
                        tint = Color(clampf(tint.r*0.58,0.04,0.26),clampf(tint.g*0.58,0.045,0.28),clampf(tint.b*0.58,0.05,0.32))
                    else:
                        tint = Color(maxf(tint.r,0.16),maxf(tint.g,0.12),maxf(tint.b,0.10))
                    material.set_shader_parameter("surface_color", tint)
                    material.set_shader_parameter("edge_color", Color(0.70, 0.78, 0.81) if is_player else Color(0.82, 0.49, 0.28))
                    material.set_shader_parameter("actor_fill", 0.085 if is_player else 0.055)
                    _cache[key] = material
                material.set_shader_parameter("edge_strength", minf(1.0,SettingsManager.actor_edge_strength*(1.5 if bool(material.get_meta("readability_player",false)) else 1.0)))
                mesh.material_override = material
        apply(child, is_player)

static func refresh_strength() -> void:
    for value in _cache.values():
        var material: ShaderMaterial = value as ShaderMaterial
        if material != null:
            material.set_shader_parameter("edge_strength", minf(1.0,SettingsManager.actor_edge_strength*(1.5 if bool(material.get_meta("readability_player",false)) else 1.0)))

"""v0.14 source contracts that do not require a Godot runtime."""
from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[1]


def read(relative: str) -> str:
    return (ROOT / relative).read_text(encoding="utf-8")


class V014Contracts(unittest.TestCase):
    def test_version_and_pooled_glyph_scene(self) -> None:
        self.assertIn('config/version="0.19.1-alpha"', read("project.godot"))
        scene = read("scenes/AsciiGlyph.tscn")
        self.assertIn('type="Label3D"', scene)
        self.assertIn('path="res://components/pooling/ascii_glyph.gd"', scene)

    def test_ascii_fx_uses_pool_instead_of_per_glyph_allocation(self) -> None:
        source = read("scripts/ascii_fx.gd")
        self.assertIn("PoolManager.spawn(GLYPH_SCENE, host)", source)
        self.assertNotIn("Label3D.new()", source)
        self.assertNotRegex(source, r"queue_free\s*\)")

    def test_pooled_glyph_has_recycle_lifecycle(self) -> None:
        source = read("components/pooling/ascii_glyph.gd")
        self.assertIn("func on_pool_spawned()", source)
        self.assertIn("func on_pool_recycled()", source)
        self.assertIn('PoolManager.call_deferred("recycle", self)', source)

    def test_renderer_method_uses_4_3_compatible_project_setting(self) -> None:
        controller = read("rendering/readability_controller.gd")
        overlay = read("ui/performance_overlay.gd")
        self.assertIn('ProjectSettings.get_setting("rendering/renderer/rendering_method"', controller)
        self.assertIn('ProjectSettings.get_setting("rendering/renderer/rendering_method"', overlay)
        self.assertNotIn("get_current_rendering_method", controller + overlay)

    def test_validator_ignores_generated_editor_cache(self) -> None:
        source = read("tools/validate_project.py")
        self.assertIn('".godot", ".git", "__pycache__"', source)

    def test_weapon_feedback_is_data_driven(self) -> None:
        data = read("data/weapon_data.gd")
        player = read("scripts/player.gd")
        animator = read("scripts/player_animator.gd")
        self.assertIn("var shot_recoil: float = 1.0", data)
        self.assertIn("var muzzle_flash_duration: float = 0.072", data)
        self.assertIn("var muzzle_light_energy: float = 6.8", data)
        self.assertIn('animator.call("trigger_shot", tracer_color, recoil, flash_duration, light_energy)', player)
        self.assertIn("_flash_energy * flash_alpha", animator)



if __name__ == "__main__":
    unittest.main()

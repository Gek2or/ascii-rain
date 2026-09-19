"""v0.15 source contracts for data-driven enemy silhouettes."""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]


def read(relative: str) -> str:
    return (ROOT / relative).read_text(encoding="utf-8")


class V015Contracts(unittest.TestCase):
    def test_enemy_visual_profile_is_data_driven(self) -> None:
        data = read("data/enemy_data.gd")
        enemy = read("scripts/enemy.gd")
        self.assertIn('var visual_profile: int = 0', data)
        self.assertIn('var accent_color: Color', data)
        self.assertIn('visual_profile = clampi(data.visual_profile', enemy)
        self.assertIn('match visual_profile:', enemy)
        self.assertIn('func _set_accent_color(color: Color)', enemy)

    def test_enemy_motion_feedback_is_data_driven(self) -> None:
        data = read("data/enemy_data.gd")
        enemy = read("scripts/enemy.gd")
        self.assertIn("var stride_scale: float", data)
        self.assertIn("var bob_amount: float", data)
        self.assertIn("var attack_pose_scale: float", data)
        self.assertIn("bob_amount * speed_ratio", enemy)
        self.assertIn("core_tween.tween_property(core_material, \"emission\"", enemy)

    def test_city_surfaces_seal_visual_and_physics_edges(self) -> None:
        generator = read("scripts/city_generator.gd")
        modules = read("world/districts/city_modules.gd")
        self.assertIn("const GROUND_SEAM_OVERLAP: float = 0.04", generator)
        self.assertIn("piece.size.x + GROUND_SEAM_OVERLAP", generator)
        self.assertIn("const RAMP_SEAM_OVERLAP: float = 0.12", modules)
        self.assertIn("var sealed_start: Vector3", modules)
        self.assertIn("shape.points = points", modules)

    def test_supplied_music_drives_bounded_lighting(self) -> None:
        audio = read("core/audio_manager.gd")
        lighting = read("scripts/audio_reactive_lighting.gd")
        generator = read("scripts/city_generator.gd")
        self.assertIn('preload("res://assets/music/deserted_coded_city.mp3")', audio)
        self.assertIn("AudioEffectSpectrumAnalyzer", audio)
        self.assertIn("func get_music_bands() -> Vector3", audio)
        self.assertIn("AudioManager.get_music_bands()", lighting)
        self.assertIn('light.add_to_group("audio_reactive_lights")', generator)
        self.assertIn("pulse * 1.15", lighting)
        self.assertIn("func _tone_for_tension(tension: float) -> Color", lighting)

    def test_threshold_market_builds_the_ten_node_route(self) -> None:
        living = read("world/districts/living_city_pass.gd")
        sector = read("world/districts/threshold_market_sector.gd")
        self.assertIn("ThresholdMarketSector", living)
        self.assertIn('"id": 1', sector)
        self.assertIn('"id": 10', sector)
        self.assertIn('ramp("ArchiveDescent"', sector)
        self.assertIn('deck("DistortionArenaFloor"', sector)
        self.assertIn('box("PrepRoomNorthWall"', sector)

    def test_first_location_isolated_from_test_arena(self) -> None:
        generator = read("scripts/city_generator.gd")
        game = read("scripts/game.gd")
        location = read("scenes/Location01_ThresholdMarket.tscn")
        arena = read("scenes/TestArena.tscn")
        self.assertIn('@export_enum("test_arena", "threshold_market") var build_profile', generator)
        self.assertIn("_create_threshold_market_location()", generator)
        self.assertIn('location_profile = "threshold_market"', location)
        self.assertIn('build_profile = "threshold_market"', location)
        self.assertIn('location_profile = "test_arena"', arena)
        self.assertIn('Vector3(57.5, 0.15, 62.0)', game)

    def test_first_location_soundscape_uses_all_supplied_wavs(self) -> None:
        soundscape = read("world/ambient/threshold_market_soundscape.gd")
        living = read("world/districts/living_city_pass.gd")
        for filename in ("rain_loop_a.wav", "terminal_typing_a.wav", "digital_glitch_a.wav", "digital_glitch_b.wav"):
            self.assertIn(filename, soundscape)
        self.assertIn('ThresholdMarketSoundscape', living)
        self.assertIn('AudioStreamWAV.LOOP_FORWARD', soundscape)
        self.assertIn('SettingsManager.ambient_volume * SettingsManager.sfx_volume', soundscape)

    def test_all_enemy_resources_declare_distinct_profiles(self) -> None:
        profiles = []
        for name in ("grunt", "skitter", "gunner", "bomber", "tank"):
            source = read(f"data/enemies/{name}.tres")
            self.assertIn("visual_profile = ", source)
            self.assertIn("accent_color = Color(", source)
            profiles.append(source.split("visual_profile = ", 1)[1].split("\n", 1)[0])
        self.assertEqual(len(set(profiles)), 5)


if __name__ == "__main__":
    unittest.main()

"""New source/asset contracts; actual physics and audio-node tests are native."""
import unittest, wave, hashlib, json, re
from pathlib import Path
P=Path(__file__).resolve().parents[1]
def text(name):return (P/name).read_text()
class CivicContracts(unittest.TestCase):
    def test_source_protection_against_v012a(self):
        for name,digest in json.loads(text('tests/protected_v012a_civic.json')).items():
            with self.subTest(file=name):self.assertEqual(hashlib.sha256((P/name).read_bytes()).hexdigest(),digest)
    def test_new_district_ids_preserve_progress(self):
        self.assertIn('district_id = &"archive_row"',text('world/districts/archive_stacks.gd'))
        self.assertIn('district_id = &"memory_gardens"',text('world/districts/memory_gardens.gd'))
    def test_three_garden_height_bands(self):
        s=text('world/districts/living_city_pass.gd')
        for token in ['gardens_ground','gardens_terrace','gardens_pavilion','archive_gallery','archive_ground']:self.assertIn(token,s)
    def test_both_new_districts_are_packed_scenes(self):
        for name in ['archive_stacks','memory_gardens']:
            self.assertIn(name+'.tscn',text('world/districts/living_city_pass.gd'))
            self.assertTrue((P/f'world/districts/{name}.tscn').is_file())
    def test_garden_two_ground_ascents_and_upper_loop(self):
        s=text('world/districts/memory_gardens.gd')
        for name in ['GardenEastAscent','GardenNorthAscent','TerraceLink','PavilionEastAscent']:self.assertIn('ramp("'+name,s)
    def test_archive_two_ascents(self):
        self.assertIn('for x in [40.0, 62.0]',text('world/districts/archive_stacks.gd'))
        self.assertIn('ramp("ArchiveAscent"',text('world/districts/archive_stacks.gd'))
    def test_elevated_floor_spawns_do_not_fall_back(self):
        self.assertIn('living.call("is_elevated_zone", zone)',text('scripts/game.gd'))
        self.assertIn('if placement.is_empty() and not on_upper:',text('scripts/game.gd'))
    def test_authored_and_final_filters_use_same_distance(self):
        self.assertIn('rng,12.0 if on_upper else 18.0)',text('scripts/game.gd'))
        self.assertIn('nav.spawn_anchor(candidate,target,minimum_distance)',text('world/spawn_placement.gd'))
    def test_floor_queries_happen_in_physics(self):
        s=text('world/encounter_director.gd')
        self.assertIn('func _physics_process(delta: float)',s)
        self.assertIn('_floor_service.support_below(player.global_position)',s)
        self.assertIn('zone_at",_zone_position()',s)
    def test_ambience_is_optional_and_separate(self):
        s=text('core/settings_manager.gd')
        self.assertIn('"ambient", "volume", ambient_volume',s)
        self.assertIn('District ambience',text('ui/settings_menu.gd'))
        self.assertIn('const RENDER_SCHEMA: int = 4',s)
    def test_original_bounded_ambient_loops(self):
        for name in ['archive_ventilation.wav','garden_rain.wav']:
            with wave.open(str(P/'assets/ambient'/name)) as wav:
                self.assertEqual(wav.getnchannels(),1)
                self.assertEqual(wav.getsampwidth(),2)
                self.assertEqual(wav.getframerate(),22050)
                self.assertEqual(wav.getnframes(),16*22050)
    def test_ambient_is_not_combat_or_global_rng(self):
        s=text('world/ambient/civic_atmosphere.gd')
        for bad in ['take_damage','randf','randi','add_to_group("enemies")','PROCESS_MODE_ALWAYS']:self.assertNotIn(bad,s)
        self.assertIn('SettingsManager.ambient_volume*SettingsManager.sfx_volume',s)
        self.assertIn('voice.max_distance=distance',s)
    def test_native_probes_cover_actual_player_and_enemy(self):
        s=text('tests/civic_city_test.gd')
        for token in ['Input.action_press("move_forward")','enemy.call("setup"','airborne under pavilion','same fourteen caches','volume zero stops']:self.assertIn(token,s)
    def test_new_geometry_no_screen_filling_effect(self):
        for name in ['archive_stacks.gd','memory_gardens.gd','civic_modules.gd']:
            s=text('world/districts/'+name)
            self.assertNotIn('hint_screen_texture',s)
            self.assertNotIn('WorldEnvironment.new()',s)
    def test_scenes_are_same_existing_main_run(self):
        self.assertIn('run/main_scene="res://scenes/Main.tscn"',text('project.godot'))
        self.assertIn('user://ascii_rain_settings.cfg',text('core/settings_manager.gd'))
if __name__=='__main__': unittest.main()

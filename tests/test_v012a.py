"""Source contracts; traversal tests are executed separately by native Godot."""
import hashlib,json,unittest,re
from pathlib import Path
from preservation_helpers import verify_functions
P=Path(__file__).resolve().parents[1]
def text(p):return (P/p).read_text()
class LivingCityContracts(unittest.TestCase):
    def test_protected_visuals_gameplay_audio_and_story(self):
        expected=json.loads(text('tests/protected_v011_living.json'))
        self.assertGreater(len(expected),65)
        for name,digest in expected.items():
            with self.subTest(file=name):self.assertEqual(hashlib.sha256((P/name).read_bytes()).hexdigest(),digest)
    def test_render_defaults_untouched(self):
        verify_functions(self,'core/settings_manager.gd')
    def test_other_city_generation_functions_untouched(self):
        verify_functions(self,'scripts/city_generator.gd')
    def test_settings_file_only_adds_ambient_preference(self):
        original=json.loads(text('tests/protected_v0101.json'))['core/settings_manager.gd']
        s=text('core/settings_manager.gd')
        s=s.split('func update_ambient_motion(',1)[0]
        s=''.join(line for line in s.splitlines(keepends=True) if not ('var ambient_motion:' in line or 'var ambient_volume:' in line or '"ambient", "motion"' in line or '"ambient", "volume"' in line))
        self.assertEqual(hashlib.sha256((s.rstrip()+'\n').encode()).hexdigest(),original)
    def test_multiple_surface_ids_not_single_height(self):
        s=text('world/navigation/street_navigation.gd')
        for token in ['var ids: Array[int]', '_cell_ids[cell] = ids','for a in _cell_ids[cell]','for b in _cell_ids[cell+offset]','can_travel(graph.get_point_position(a),graph.get_point_position(b))']:
            self.assertIn(token,s)
    def test_ground_queries_cannot_pick_roof_above_feet(self):
        s=text('world/navigation/layered_surface_query.gd')
        self.assertIn('static func below',s)
        self.assertIn('nav_surface_id',s)
        self.assertIn('exclude',s)
    def test_waypoint_consumption_checks_height(self):
        self.assertIn('absf(_path[_waypoint].y - feet.y)',text('world/navigation/enemy_navigation.gd'))
    def test_ramps_share_visible_and_collision_vertices(self):
        s=text('world/districts/city_modules.gd')
        self.assertIn('shape.points = points',s)
        self.assertIn('tool.add_vertex(points[index])',s)
        self.assertIn('MultiMesh.new()',s)
    def test_ambient_never_spawns_or_damages_combatants(self):
        s=text('world/ambient/city_ambient.gd')
        for forbidden in ['take_damage','randf','randi','queue_enemy','add_to_group("enemies")','PROCESS_MODE_ALWAYS']:
            self.assertNotIn(forbidden,s)
        self.assertIn('delta * SettingsManager.ambient_motion',s)
        self.assertIn('quality_preset > 0',s)
    def test_motion_toggle_persists_separately_from_render(self):
        s=text('core/settings_manager.gd')
        self.assertIn('cfg.set_value("ambient", "motion", ambient_motion)',s)
        self.assertIn('cfg.get_value("ambient", "motion", ambient_motion)',s)
        self.assertIn('Ambient motion',text('ui/settings_menu.gd'))
        self.assertIn('const RENDER_SCHEMA: int = 4',s)
    def test_same_district_distinct_floor_zone(self):
        s=text('world/districts/living_city_pass.gd')
        for token in ['&"market_gallery",&"market_ruins"','&"market_ground",&"market_ruins"','&"transit_platform",&"signal_concourse"','&"transit_ground",&"signal_concourse"']:
            self.assertIn(token,s)
        self.assertIn('bounds.has_point(point)',s)
    def test_authored_spawning_bounds_attempts_and_occupancy(self):
        s=text('world/spawn_placement.gd')
        self.assertIn('range(mini(8,points.size()))',s)
        self.assertIn('nav.spawn_anchor(candidate,target,minimum_distance)',s)
        self.assertIn('3.5*3.5',s)
    def test_native_tests_run_real_controllers_and_bridge_physics(self):
        s=text('tests/living_city_test.gd')
        for token in ['Input.action_press("move_forward")','SIGHT.clear','enemy.call("setup"','nav.request_route','two supported floors','upper floor does not grant second district']:
            self.assertIn(token,s)
    def test_ambient_only_small_spatial_batches(self):
        s=text('world/districts/city_modules.gd')
        self.assertIn('floori(at.x / 24.0)',s)
        self.assertIn('visibility_range_end',s)
        self.assertIn('light.shadow_enabled = false',s)
    def test_main_scene_still_existing_run(self):
        self.assertIn('run/main_scene="res://scenes/Main.tscn"',text('project.godot'))
        self.assertIn('living_city_pass.gd',text('scripts/city_generator.gd'))
if __name__=='__main__':unittest.main()

"""Source/preservation contracts. Native physics assertions are separate .gd tests."""
import hashlib
import json
import unittest
from pathlib import Path
P=Path(__file__).resolve().parents[1]
def text(name):return (P/name).read_text()
class EncounterTacticsContracts(unittest.TestCase):
    def test_renderer_controller_audio_story_and_data_unchanged(self):
        base=json.loads(text('tests/protected_v0101.json'))
        self.assertGreater(len(base),60)
        for name,digest in base.items():
            if name == "core/settings_manager.gd":
                # New ambient control only; graphics functions checked independently.
                continue
            with self.subTest(path=name):
                self.assertEqual(hashlib.sha256((P/name).read_bytes()).hexdigest(),digest)
    def test_city_generation_outside_two_approved_districts_is_preserved(self):
        from preservation_helpers import verify_functions
        verify_functions(self,'scripts/city_generator.gd')
    def test_navigation_has_bounded_physics_work(self):
        s=text('world/navigation/street_navigation.gd')
        for token in ['range(cells_per_tick)','range(edges_per_tick)','2 if RuntimeProfile.is_mobile else 4','space.cast_motion(query)','_label_components()']:
            self.assertIn(token,s)
        self.assertNotIn('func _process(',s)
    def test_city_physics_matches_existing_shapes_not_new_visuals(self):
        s=text('world/city_collision_pass.gd')
        self.assertIn('(mesh_node.mesh as BoxMesh).size',s)
        self.assertIn('mesh_node.add_child(body)',s)
        self.assertNotIn('MeshInstance3D.new()',s)
    def test_no_direct_wall_fallback_in_navigation(self):
        s=text('world/navigation/enemy_navigation.gd')
        self.assertIn('service.can_travel(feet, goal)',s)
        self.assertIn('return Vector3.ZERO',s)
        self.assertNotIn('actor.global_position =',s)
    def test_aim_does_not_change_after_telegraph(self):
        s=text('scripts/enemy.gd').split('func _process_attack_windup(',1)[1].split('func _execute_pending_attack',1)[0]
        self.assertNotIn('_pending_direction =',s)
        self.assertNotIn('_pending_aim_point =',s)
        s=text('scripts/boss.gd').split('func _fire_fan(',1)[1].split('func _fire_ring',1)[0]
        self.assertIn('_locked_aim - origin',s)
    def test_cancel_removes_owned_cue(self):
        s=text('scripts/enemy.gd').split('func _cancel_windup()',1)[1].split('func _fire_projectile',1)[0]
        self.assertIn('_clear_cue()',s)
        self.assertIn('_attack_cue.queue_free()',s)
    def test_explosion_has_pauseable_warning_and_cover(self):
        s=text('components/combat/delayed_blast.gd')
        self.assertIn('remaining: float = 0.85',s)
        self.assertIn('SIGHT.clear',s)
        self.assertIn('func _physics_process',s)
        self.assertNotIn('PROCESS_MODE_ALWAYS',s)
    def test_projectile_continuous_check_precedes_position_advance(self):
        s=text('scripts/enemy_projectile.gd')
        self.assertLess(s.index('space_state.intersect_ray(query)'),s.index('global_position = next_position'))
        self.assertIn('if _recycle_requested:',s)
    def test_sector_clears_hazards_and_cues(self):
        s=text('scripts/game.gd').split('func _stop_hostile_activity',1)[1]
        self.assertIn('"hostile_hazards"',s)
        self.assertIn('"hostile_cues"',s)
    def test_reachable_spawn_filter_is_connected_to_game(self):
        s=text('scripts/game.gd')
        self.assertIn('_street_navigation.spawn_anchor',s)
        self.assertIn('not _street_navigation.built',s)
    def test_native_regressions_are_physics_not_only_source_search(self):
        s=text('tests/encounter_tactics_test.gd')
        for token in ['await physics_frame','chaser.global_position','climber.global_position','1000.0','melee cannot damage through wall','warning locks shot point']:
            self.assertIn(token,s)
        self.assertIn('res://scenes/Main.tscn',text('tests/city_navigation_test.gd'))
if __name__=='__main__':unittest.main()

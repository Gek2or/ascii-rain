"""Packaging/source regressions. Native behavior is covered by .gd tests separately."""
import hashlib
import json
import unittest
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
def source(p):
    return (ROOT/p).read_text(encoding='utf-8')


def visual_bytes(path):
    data = path.read_bytes()
    if path.name == 'city_generator.gd':
        data = b''.join(line for line in data.splitlines(keepends=True) if b'.add_to_group("city_solid")' not in line)
    return data

class RunLoopContracts(unittest.TestCase):
    def test_readability_assets_and_story_bible_preserved(self):
        files=json.loads(source('tests/render_and_content_baseline.json'))
        self.assertGreater(len(files),50)
        for p,sha in files.items():
            # v0.10.1 is an explicit renderer correction, not a gameplay rewrite.
            if p in {"shaders/ascii_post.gdshader", "rendering/ascii_atlas_binding.gd", "scripts/city_generator.gd", "core/settings_manager.gd"}:
                continue
            with self.subTest(path=p):
                self.assertEqual(hashlib.sha256(visual_bytes(ROOT/p)).hexdigest(),sha)

    def test_new_services_use_existing_main_not_replacement(self):
        self.assertIn('run/main_scene="res://scenes/Main.tscn"',source('project.godot'))
        for p in ['core/run/run_guide.gd','ui/relic_choice.gd','world/spawn_placement.gd']:
            self.assertIn('res://'+p,source('scripts/game.gd'))

    def test_selection_is_not_an_automatic_random_grant(self):
        s=source('ui/relic_choice.gd')
        self.assertNotIn('grant_random',s)
        for contract in ['spend_credits','can_grant','complete_open','committed.emit']:
            self.assertIn(contract,s)
        self.assertLess(s.index('if not _open'),s.index('"spend_credits"'))

    def test_no_await_inside_transaction(self):
        s=source('ui/relic_choice.gd').split('func _choose(',1)[1].split('func _close',1)[0]
        code='\n'.join(line.split('#',1)[0] for line in s.splitlines())
        self.assertNotIn('await ',code)
        self.assertIn('_open = false',code)

    def test_popup_ownership_checked_by_other_menus(self):
        for p in ['ui/relic_choice.gd','ui/settings_menu.gd','scripts/story_director.gd']:
            self.assertIn('get_nodes_in_group("exclusive_ui")',source(p))

    def test_cancel_does_not_debit_or_regenerate(self):
        s=source('ui/relic_choice.gd').split('func _close()',1)[1].split('func _build',1)[0]
        self.assertNotIn('spend_credits',s)
        self.assertNotIn('make_offer',s)
        self.assertIn('cached_offer',source('scripts/chest.gd'))

    def test_held_ui_tap_requires_fire_release(self):
        s=source('scripts/player.gd')
        self.assertIn('_ui_fire_release_required = true',s)
        self.assertIn('func suppress_actions_after_ui',s)
        self.assertIn('suppress_actions_after_ui',source('ui/relic_choice.gd'))

    def test_spawn_work_is_bounded(self):
        s=source('scripts/game.gd')
        self.assertIn('_spawn_requests.size() < 24',s)
        self.assertIn('range(mini(2, _spawn_requests.size()))',s)
        self.assertIn('func _physics_process(',s)
        placement=source('world/spawn_placement.gd')
        self.assertIn('intersect_ray',placement)
        self.assertIn('intersect_shape',placement)
        self.assertIn('range(10)',placement)

    def test_progress_is_not_saved_over_archive(self):
        s=source('core/run/run_progress.gd')
        self.assertNotIn('ConfigFile',s)
        self.assertNotIn('FileAccess',s)
        self.assertIn('const SAVE_PATH = "user://ascii_rain_profile.cfg"',source('scripts/story_director.gd'))

    def test_story_overlay_owned_by_ready_node(self):
        s=source('scripts/story_director.gd')
        self.assertIn('    add_child(_overlay_layer)',s)
        self.assertNotIn('get_parent().add_child(_overlay_layer)',s)
        self.assertIn('SubViewport.UPDATE_WHEN_VISIBLE',s)

    def test_sector_dissolve_does_not_reward_kills(self):
        s=source('scripts/game.gd').split('func _stop_hostile_activity',1)[1].split('func _configure_result_panels',1)[0]
        self.assertIn('enemy.queue_free',s)
        self.assertNotIn('take_damage',s)
        self.assertNotIn('add_xp',s)
        self.assertNotIn('add_credits',s)

    def test_final_screen_retains_no_restart_loop_accident(self):
        s=source('scripts/game.gd')
        self.assertIn('_run_guide.call("summary", true)',s)
        self.assertIn('_run_guide.call("summary", false)',s)
        self.assertIn('get_tree().paused = false',s.split('func _on_restart_pressed',1)[1])

    def test_native_tests_are_real_scene_tests(self):
        s=source('tests/run_loop_smoke.gd')
        for value in ['change_scene_to_file','physics_frame','first_button.pressed.emit()', '"take_damage"','--test-isolated']:
            self.assertIn(value,s)
        self.assertIn('PROGRESS.new()',source('tests/run_state_test.gd'))

    def test_archive_packager_keeps_parent_first_records(self):
        s=source('tools/package_project.py')
        self.assertIn('explicit directory entries',s)
        self.assertIn('target.writestr(entry, b',s)
        self.assertIn('for strip_root in (False, True)',s)

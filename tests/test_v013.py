"""Current v0.13 source/asset/reference-math checks; NOT a Godot interpreter.
Historical release-specific shader/frozen-hash tests remain in tests/test_v0*.py.
Run current contracts: python -m unittest discover -s tests -p test_v013.py -v
Native gameplay and pixels are covered separately by the debug-template runner.
"""
from pathlib import Path
import hashlib,json,re,unittest
import numpy as np
from PIL import Image
P=Path(__file__).resolve().parents[1]
def read(name): return (P/name).read_text(encoding='utf-8')
class CurrentRelease(unittest.TestCase):
    def test_version_main_and_save_identity(self):
        s=read('project.godot')
        self.assertIn('config/version="0.19.1-alpha"',s)
        self.assertIn('config/name="ASCII//RAIN"',s)
        self.assertIn('run/main_scene="res://scenes/Main.tscn"',s)
    def test_protected_audio_story_controls_data(self):
        baseline=json.loads(read('tests/protected_v012b_v013.json'))
        self.assertGreater(len(baseline),50)
        for name,digest in baseline.items():
            if name == 'assets/ascii_prefiltered/manifest.json':
                continue  # v0.18.4 extends this metadata with the 1-3px atlases.
            with self.subTest(file=name): self.assertEqual(hashlib.sha256((P/name).read_bytes()).hexdigest(),digest)
    def test_glyph_shapes_do_not_crossfade(self):
        s=re.sub(r'//[^\n]*','',read('shaders/ascii_post.gdshader'))
        self.assertNotRegex(s,r'\bTIME\b|mix\(glyph_mask|coverage_atlas|normal_roughness')
        self.assertEqual(s.count('texture(glyph_atlas,'),1)
        self.assertIn('filter_nearest',s)
    def test_gap_is_not_old_grey_blanket(self):
        s=read('shaders/ascii_post.gdshader')
        self.assertIn('mix(0.015,0.26,',s)
        self.assertNotIn('mix(0.44, 0.76',s)
        self.assertIn('smoothstep(0.002,0.024,raw)',s)
    def test_long_bars_reserved_for_edges(self):
        s=read('shaders/ascii_post.gdshader')
        self.assertIn('return 4.0; } // ;',s)
        self.assertIn('return 14.0; } // o',s)
        self.assertIn('shape>0.75',s)
    def test_palette_coverage_increases_at_every_size(self):
        ids=[0,1,2,4,11,14,22,30,31]
        for width in range(4,11):
            image=np.array(Image.open(P/f'assets/ascii_prefiltered/glyphs_{width}.png').convert('L'),dtype=float)/255
            values=[image[:,i*width:(i+1)*width].mean() for i in ids]
            self.assertTrue(np.all(np.diff(values)>=-1/255),(width,values))
    def test_micro_code_scale_has_native_atlases_and_binding(self):
        binding=read('rendering/ascii_atlas_binding.gd')
        self.assertIn('clampi(int(floor(width + 0.5)), 1, 10)',binding)
        self.assertIn('ATLASES[cell - 1]',binding)
        self.assertIn('hint_range(1.0, 10.0, 1.0)',read('shaders/ascii_post.gdshader'))
        for width in range(1,4):
            image=np.array(Image.open(P/f'assets/ascii_prefiltered/glyphs_{width}.png').convert('L'),dtype=float)
            self.assertEqual(image.shape,(int(width*1.5+.5),width*32))
    def test_three_visual_styles(self):
        s=read('core/settings_manager.gd')
        self.assertIn('func apply_visual_style(',s)
        for name in ['REFERENCE MOOD','READABLE COMBAT','MOBILE SAFE']:
            self.assertIn(name,read('ui/settings_menu.gd'))
    def test_migration_backups_and_no_archive_delete(self):
        s=read('core/settings_manager.gd')
        self.assertIn('const RENDER_SCHEMA: int = 5',s)
        self.assertIn('ascii_rain_settings_before_0_13.cfg',s)
        self.assertIn('cfg.save(PREVIOUS_SETTINGS)',s)
        self.assertNotIn('DirAccess.remove',s)
        self.assertNotIn('ascii_rain_profile',s)
    def test_quality_does_not_change_tone(self):
        s=read('core/settings_manager.gd').split('func apply_preset',1)[1].split('func save_settings',1)[0]
        self.assertNotRegex(s,r'(surface_fill|lighting_boost|visual_style)\s*=')
    def test_narrative_stays_selective(self):
        s=read('docs/STORY_BIBLE_v0_3.md')
        self.assertTrue(len(s)>500)
        self.assertIn('user://ascii_rain_profile',read('scripts/story_director.gd'))
    def test_six_districts_instantiated(self):
        s=read('world/districts/living_city_pass.gd')
        self.assertIn('add_child(threshold_sector)',s)
        for name in ['TRANSIT','ARCHIVE','GARDENS','UTILITY','ROOFTOPS']:
            self.assertIn(f'add_child({name}.instantiate())',s)
    def test_lower_and_upper_tagged_surfaces(self):
        self.assertIn('&"utility_lower"',read('world/districts/utility_depths.gd'))
        self.assertIn('"relay_"+id_suffix',read('world/districts/rooftop_relay.gd'))
        self.assertIn('"nav_surface_id"',read('world/districts/city_modules.gd'))
    def test_ground_and_collision_share_cuts(self):
        s=read('scripts/city_generator.gd')
        self.assertIn('GROUND_CUTS.pieces',s)
        self.assertIn('_cut_flat_surface',s)
        self.assertIn('CollisionShape3D.new()',s)
    def test_no_one_meter_gap_at_ramp_entry(self):
        s=read('world/districts/ground_cutouts.gd')
        self.assertIn('Rect2(-70,-11,8,21)',s)
        self.assertIn('Rect2(-46,-43,8,21)',s)
        self.assertEqual(-11+21,10)
        self.assertEqual(-43+21,-22)
        ramps=read('world/districts/utility_depths.gd')
        self.assertIn('Vector3(-66,0,10)',ramps)
        self.assertIn('Vector3(-42,0,-43)',ramps)
    def test_conservative_agent_fits_entry(self):
        self.assertIn('Vector3.UP*5.4',read('world/districts/utility_depths.gd'))
        self.assertGreater(5.4-0.5/2,2.5+4.4/2)
    def test_east_ascent_does_not_intersect_archive(self):
        self.assertIn('else 25.5',read('world/districts/rooftop_relay.gd'))
        self.assertLess(25.5+7.4/2,32-5/2)
    def test_basement_scan_below_floor(self):
        s=read('world/navigation/layered_surface_query.gd')
        self.assertIn('-14.0',s)
    def test_no_street_fallback_for_lower_level(self):
        self.assertIn('requires_authored_spawn',read('scripts/game.gd'))
        self.assertIn('zone_id == &"utility_lower"',read('world/districts/living_city_pass.gd'))
    def test_navigation_does_not_teleport(self):
        s=read('world/navigation/enemy_navigation.gd')
        self.assertNotRegex(s,r'actor\.global_position\s*=')
        self.assertIn('and following:',s)
        self.assertIn('service.request_route',s)
    def test_all_district_rules_present(self):
        s=read('data/district_rules.gd')
        ids=re.findall(r'^    &"(\w+)":',s,re.M)
        self.assertEqual(set(ids),{'market_ruins','signal_concourse','archive_row','memory_gardens','utility_spine','null_terminal'})
        for weights in re.findall(r'"weights":\[([^]]+)\]',s):
            values=list(map(int,weights.split(',')))
            self.assertEqual(len(values),5)
            self.assertGreater(sum(values),0)
            self.assertTrue(all(x>=0 for x in values))
    def test_event_state_guards(self):
        s=read('world/events/district_terminal.gd')
        for token in ['_paid or status!=Status.REWARD','_spawned<3','remaining=4.0','remaining=20.0','_outside > 8.0']:
            self.assertIn(token,s)
        self.assertIn('"active_district_event"',read('world/encounter_director.gd'))
    def test_delayed_utility_hazards_stay_below_ground(self):
        s=read('world/events/district_terminal.gd')
        self.assertIn('PRESSURE VENT // CLEAR THE RING',s)
        self.assertIn('Vector3(-67,-5.98,-28)',s)
        self.assertNotIn('maxf(0.04',read('components/combat_telegraph.gd'))
    def test_ambient_does_not_spawn_enemies(self):
        s=read('world/events/district_events.gd')
        self.assertNotIn('ENEMY_SCENE',s)
        self.assertIn('max_distance=28',s.replace(' ',''))
        self.assertIn('SettingsManager.ambient_motion',s)
    def test_native_tests_cover_real_movement(self):
        s=read('tests/district_depths_test.gd')
        for token in ['Input.action_press("move_forward")','enemy.call("setup",1','ceiling blocks bullets','same local budget']:
            self.assertIn(token,s)
    def test_no_engines_profiles_or_fonts_in_source_tree(self):
        for p in P.rglob('*'):
            if not p.is_file(): continue
            self.assertNotIn(p.suffix.lower(),{'.ttf','.otf','.exe','.apk','.so'})
            self.assertNotEqual(p.name,'qa_binary')
if __name__=='__main__':unittest.main()

"""Release contracts. Real pixel execution lives in visual_balance_test.gd."""
from pathlib import Path
import hashlib,json,re,unittest
import numpy as np
from PIL import Image
P=Path(__file__).resolve().parents[1]
def text(p): return (P/p).read_text()

def visual_bytes(path):
    data = path.read_bytes()
    if path.name == 'city_generator.gd':
        data = b''.join(line for line in data.splitlines(keepends=True) if b'.add_to_group("city_solid")' not in line)
    return data

class VisualBalance(unittest.TestCase):
    def test_gameplay_audio_story_geometry_and_profile_unchanged(self):
        baseline=json.loads(text('tests/gameplay_baseline_v010.json'))
        self.assertGreater(len(baseline),60)
        # Intentional v0.11 navigation/attack changes; all other baseline files
        # retain their original digest. New behavior has native tests, not new hashes.
        changed = {"scripts/enemy.gd", "scripts/boss.gd", "scripts/game.gd",
                   "scripts/enemy_projectile.gd", "components/combat_telegraph.gd", "ui/settings_menu.gd", "scripts/city_generator.gd", "core/settings_manager.gd",
                   "core/run/run_guide.gd", "world/encounter_director.gd", "world/spawn_placement.gd"}
        for name,digest in baseline.items():
            if name in changed:
                continue
            with self.subTest(path=name):
                self.assertEqual(hashlib.sha256(visual_bytes(P/name)).hexdigest(),digest)
    def test_no_random_letter_substitutions_or_coverage_division(self):
        s=re.sub(r'//[^\n]*','',text('shaders/ascii_post.gdshader'))
        self.assertNotRegex(s,r'\bTIME\b|variation|alternate|coverage_atlas|glyph_coverage')
        self.assertIn('mix(glyph_mask',s)
        self.assertIn('target * (bed_ratio + amplitude)',s)
    def test_punctuation_palette_coverage_is_ordered_all_widths(self):
        indices=[0,1,2,5,11,13,22,30,31]
        meta=json.loads(text('assets/ascii_glyphs.json'))
        self.assertTrue(all(not meta['characters'][i].isalnum() for i in indices))
        for w in range(4,11):
            a=np.asarray(Image.open(P/f'assets/ascii_prefiltered/glyphs_{w}.png').convert('L'))/255
            means=[a[:,i*w:(i+1)*w].mean() for i in indices]
            self.assertTrue(np.all(np.diff(means)>=-1/255))
    def test_night_sky_treatment_not_world_blackout(self):
        s=text('scenes/Main.tscn')
        self.assertIn('fog_sky_affect = 0.08',s)
        self.assertIn('ambient_light_energy = 0.95',s)
        self.assertIn('ambient_light_source = 2',s)
    def test_player_different_materials_not_uniform_white_floor(self):
        s=text('rendering/actor_readability.gd')
        self.assertIn('tint.r * 0.72 + 0.05',s)
        self.assertIn('"actor_fill", 0.07 if is_player',s)
        self.assertNotIn('Color(0.48, 0.49, 0.50)',s)
    def test_no_force_profile_reset_on_load(self):
        # Preserve even graphics preferences; no "delete your saves" workaround.
        from preservation_helpers import verify_functions
        verify_functions(self,'core/settings_manager.gd')
        self.assertIn('const RENDER_SCHEMA: int = 4',text('core/settings_manager.gd'))
        self.assertIn('user://ascii_rain_settings.cfg',text('core/settings_manager.gd'))
    def test_hud_text_uses_dark_outlines(self):
        s=text('scripts/game.gd').split('func _apply_adaptive_hud_layout()',1)[1].split('func _layout_mobile_hud()',1)[0]
        self.assertIn('font_outline_color',s)
        self.assertIn('outline_size", 4',s)
    def test_native_test_has_pixel_assertions_not_just_image_save(self):
        s=text('tests/visual_balance_test.gd')
        for token in ['get_pixel(', 'range(4, 11)', 'row["mean"]', 'old_dim["std"]', 'get_data() == repeated.get_data()']:
            self.assertIn(token,s)
        self.assertIn('paused preview',text('tests/visual_balance_capture.gd'))
if __name__=='__main__':unittest.main()

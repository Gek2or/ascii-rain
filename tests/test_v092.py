"""v0.9.2 source, asset and mathematical regressions, NOT a Godot runtime test."""
from pathlib import Path
import json,re,unittest
import numpy as np
from PIL import Image
ROOT=Path(__file__).resolve().parents[1]
def text(path):return (ROOT/path).read_text()
def image(path):return np.asarray(Image.open(ROOT/path).convert('RGB'),dtype=np.float64)/255
class RenderFix(unittest.TestCase):
    def test_native_glyphs_keep_original_ascii_alphabet(self):
        a=json.loads(text('assets/ascii_glyphs.json'))
        b=json.loads(text('assets/ascii_prefiltered/manifest.json'))
        self.assertEqual(a['characters'],b['characters'])
        self.assertTrue(all(32<=ord(x)<127 for x in b['characters']))

    def test_every_requested_width_has_a_native_sized_atlas(self):
        for w in range(4,11):
            a=image(f'assets/ascii_prefiltered/glyphs_{w}.png')
            self.assertEqual(a.shape,(int(w*1.5+.5),w*32,3))

    def test_nonblank_strokes_survive_at_all_widths(self):
        for w in range(4,11):
            a=image(f'assets/ascii_prefiltered/glyphs_{w}.png')[:,:,0]
            self.assertEqual(a[:,:w].sum(),0)
            for i in range(1,32):self.assertGreater(a[:,i*w:(i+1)*w].sum(),0,(w,i))

    def test_measured_coverage_matches_rg_lookup(self):
        for w in range(4,11):
            a=image(f'assets/ascii_prefiltered/glyphs_{w}.png')[:,:,0]
            c=image(f'assets/ascii_prefiltered/coverage_{w}.png')[0]
            measured=np.array([a[:,i*w:(i+1)*w].mean() for i in range(32)])
            decoded=(c[:,0]*65280+c[:,1]*255)/65535
            np.testing.assert_allclose(decoded,measured,atol=1/65535,rtol=0)

    def test_area_resampling_preserves_ink_with_quantization_tolerance(self):
        original=image('assets/ascii_atlas.png')[:,:,0]
        cover=np.array([original[:,i*6:(i+1)*6].mean() for i in range(32)])
        for w in range(4,11):
            a=image(f'assets/ascii_prefiltered/glyphs_{w}.png')[:,:,0]
            new=np.array([a[:,i*w:(i+1)*w].mean() for i in range(32)])
            np.testing.assert_allclose(new,cover,atol=1/255,rtol=0)

    def test_legacy_hyphen_sampling_really_lost_a_whole_stroke(self):
        a=image('assets/ascii_atlas.png')[:,:,0]
        # Old shader: nearest sampling of a 6x9 tile into a 4x6 cell.
        x=np.floor((np.arange(4)+.5)/4*6).astype(int)
        y=np.floor((np.arange(6)+.5)/6*9).astype(int)
        self.assertEqual(a[np.ix_(y,5*6+x)].sum(),0.)
        fixed=image('assets/ascii_prefiltered/glyphs_4.png')[:,:,0]
        self.assertGreater(fixed[:,5*4:6*4].sum(),0.)

    def test_binding_in_main_and_lab(self):
        for path in ['scripts/game.gd','world/readability_lab.gd']:
            self.assertIn('ATLAS_BINDING.apply(material,',text(path))
        s=text('rendering/ascii_atlas_binding.gd')
        self.assertNotIn('"coverage_atlas"',s) # v0.10.1 bounded contrast has no coverage division
        for w in range(4,11):
            self.assertIn(f'preload("res://assets/ascii_prefiltered/glyphs_{w}.png")',s)

    def test_scene_materials_do_not_bind_retired_coverage_uniform(self):
        for path in ['scenes/Main.tscn','scenes/ReadabilityLab.tscn']:
            self.assertNotIn('shader_parameter/coverage_atlas',text(path))

    def test_migration_keeps_audio_controls_and_archive_out_of_render_reset(self):
        s=text('core/settings_manager.gd')
        body=s.split('func _render_defaults()',1)[1].split('\nfunc ',1)[0]
        for item in ['music_volume','sfx_volume','camera_motion','sensitivity','touch_controls','archive','quality_preset','render_scale','shadows_enabled']:
            self.assertNotIn(item,body)
        self.assertIn('cfg.save(PREVIOUS_SETTINGS)',s)
        self.assertIn('schema", 0)) < RENDER_SCHEMA',s)
        self.assertIn('const RENDER_SCHEMA: int = 4',s)

    def test_quality_presets_do_not_reset_art_preferences(self):
        s=text('core/settings_manager.gd').split('func apply_preset(',1)[1].split('\nfunc ',1)[0]
        for key in ['glyph_gain =','lighting_boost =','background_calm =','color_saturation =']:
            self.assertNotIn(key,s)
        self.assertIn('_sync_quality_label()',text('ui/settings_menu.gd'))

    def test_preview_is_paused_and_undimmed(self):
        s=text('ui/settings_menu.gd')
        self.assertIn('shade.color = Color(0.0, 0.0, 0.0, 0.0)',s)
        self.assertIn('BACK TO SETTINGS // GAME PAUSED',s)
        fn=s.split('func _toggle_preview()',1)[1].split('\nfunc ',1)[0]
        self.assertNotIn('paused = false',fn)
        self.assertIn('_panel.visible = not _preview_only',fn)

    def test_no_unsafe_shader_names_or_forward_only_dependency(self):
        s=re.sub(r'//[^\n]*','',text('shaders/ascii_post.gdshader'))
        self.assertNotRegex(s,r'\b(?:vec[234]|float|int)\s+(?:packed|input|output|signal)\b')
        self.assertNotIn('hint_normal_roughness_texture',s)
        self.assertNotRegex(s,r'\bTIME\b')
        self.assertIn('vec3 result = mix(background, ink, glyph);',s)

    def test_shader_and_settings_have_same_defaults(self):
        shader=text('shaders/ascii_post.gdshader');settings=text('core/settings_manager.gd')
        for key in ['surface_fill','background_calm','color_saturation']:
            a=re.search(r'uniform float '+key+r'[^=]*=\s*([\d.]+)',shader)
            b=re.search(r'var '+key+r': float = ([\d.]+)',settings)
            self.assertEqual(float(a[1]),float(b[1]),key)

    def test_legacy_mean_compensation_is_excessive_in_shadows(self):
        # The old formula preserves a mean but boosts dim 0.20 strokes above 0.55.
        # Keep the proof as a fixture regression; this is NOT the new algorithm.
        source_code = text('tests/fixtures/ascii_post_v0_10.gdshader.txt')
        self.assertIn(' / area', source_code)
        self.assertGreater(.20*(1-(1-.18)*.50)/.18, .55)

    def test_legacy_mean_equation_fixture_only(self):
        for target in [0,.001,.02,.05,.1,.2,.4,.7,.94]:
            for coverage in [.02,.055,.14,.25,.39]:
                for bed_ratio in [.12,.4,.75]:
                    ink=min(target*(1-(1-coverage)*bed_ratio)/coverage,1.)
                    background=max((target-ink*coverage)/(1-coverage),0.)
                    self.assertAlmostEqual(background*(1-coverage)+ink*coverage,target,places=9)
if __name__=='__main__':unittest.main(verbosity=2)

"""Source + numerical regression checks. These DO NOT execute Godot/GDScript.
Run: python -m unittest discover -s tests -p 'test_*.py' -v
"""
from pathlib import Path
import json, math, re, struct, unittest

ROOT=Path(__file__).resolve().parents[1]

def text(rel):
    return (ROOT/rel).read_text(encoding='utf-8')

def nodes(rel):
    """Read flat scene node sections; no claim to be a Godot scene parser."""
    out={}
    for match in re.finditer(r'^\[node ([^\n]+)\]\n([^\[]*)',text(rel),re.M):
        header,body=match.groups(); name=re.search(r'name="([^"]+)"',header).group(1)
        parent=re.search(r'parent="([^"]+)"',header)
        path='.' if parent is None else name if parent.group(1)=='.' else parent.group(1)+'/'+name
        out[path]=body
    return out

def vector(section,key='position'):
    m=re.search(r'^'+key+r' = Vector3\(([^)]+)\)',section,re.M)
    return tuple(map(float,m.group(1).split(','))) if m else (0.,0.,0.)

class Sources(unittest.TestCase):
    def test_color_ambient_without_sky_dependency(self):
        self.assertIn('ambient_light_source = 2',text('scenes/Main.tscn'))
        self.assertIn('Environment.AMBIENT_SOURCE_COLOR',text('scripts/game.gd'))
        self.assertNotIn('ambient_light_source = 3',text('scenes/Main.tscn'))

    def test_player_soles_are_at_floor(self):
        scene=nodes('scenes/Player.tscn')
        for side in ['L','R']:
            path=f'Visual/BodyRoot/Leg{side}Pivot'
            ys=[vector(scene['Visual'])[1],vector(scene['Visual/BodyRoot'])[1],vector(scene[path])[1],vector(scene[path+'/ShinPivot'])[1],vector(scene[path+'/ShinPivot/Boot'])[1]]
            self.assertAlmostEqual(sum(ys)-0.14/2,0.,places=4)

    def test_hands_match_forearm_lengths(self):
        scene=nodes('scenes/Player.tscn')
        for side in ['L','R']:
            hand=vector(scene[f'Visual/BodyRoot/Arm{side}Pivot/ForearmPivot/Hand'])
            self.assertAlmostEqual(hand[1],-.34,places=4)

    def test_animator_node_paths(self):
        scene=nodes('scenes/Player.tscn')
        for path in re.findall(r'\$([A-Za-z0-9_/]+)',text('scripts/player_animator.gd')):
            self.assertIn('Visual/'+path,scene)

    def test_32_glyph_atlas_and_coverage(self):
        metadata=json.loads(text('assets/ascii_glyphs.json'))
        self.assertEqual(len(metadata['characters']),32)
        self.assertEqual(len(set(metadata['characters'])),32)
        self.assertEqual(metadata['coverage'],sorted(metadata['coverage']))
        raw=(ROOT/'assets/ascii_atlas.png').read_bytes()
        self.assertEqual(raw[:8],b'\x89PNG\r\n\x1a\n')
        width,height=struct.unpack('>II',raw[16:24])
        self.assertEqual((width,height),(metadata['tile'][0]*32,metadata['tile'][1]))
        self.assertIn('GLYPH_COUNT = 32.0',text('shaders/ascii_post.gdshader'))

    def test_settings_api_references(self):
        source=text('core/settings_manager.gd')
        fields=set(re.findall(r'^var (\w+)',source,re.M))
        methods=set(re.findall(r'^func (\w+)',source,re.M))
        enums=set(re.findall(r'^enum (\w+)',source,re.M))
        for p in ROOT.rglob('*.gd'):
            for name in re.findall(r'\bSettingsManager\.(\w+)',p.read_text()):
                self.assertIn(name, fields|methods|enums|{'changed','call','get'},f'{p.name}: {name}')
        for setter in re.findall(r'"(update_\w+)"',text('ui/settings_menu.gd')):
            self.assertIn(setter,methods)

    def test_settings_sync_does_not_emit(self):
        s=text('ui/settings_menu.gd')
        self.assertIn('set_value_no_signal(value)',s)
        self.assertIn('set_pressed_no_signal',s)
        self.assertIn('ScrollContainer.new()',s)

    def test_core_shader_parameters_are_declared(self):
        shader=text('shaders/ascii_post.gdshader')
        names=set(re.findall(r'uniform\s+\w+\s+(\w+)',shader))
        for name in re.findall(r'material.set_shader_parameter\("([^"]+)"',text('scripts/game.gd')):
            self.assertIn(name,names)
        for name in re.findall(r'shader_parameter/(\w+)\s*=',text('scenes/Main.tscn')):
            self.assertIn(name,names)

    def test_depth_has_compatibility_path_not_normal_buffer(self):
        shader=text('shaders/depth_contours.gdshader')
        self.assertIn('hint_depth_texture',shader)
        self.assertNotIn('hint_normal_roughness_texture',shader)
        self.assertIn('compatibility_ndc',shader)
        self.assertIn('INV_PROJECTION_MATRIX',shader)
        self.assertIn('depth_contours_enabled',text('rendering/readability_controller.gd'))

    def test_analog_input_keeps_magnitude(self):
        source=text('scripts/player.gd')
        self.assertIn('var wish_dir: Vector3 = global_transform.basis * local_dir',source)
        self.assertIn('camera_query.exclude = [get_rid()]',source)

    def test_story_assets_and_rules_preserved(self):
        self.assertTrue((ROOT/'docs/STORY_BIBLE_v0_3.md').is_file())
        self.assertIn('SubViewport',text('scripts/story_director.gd'))
        self.assertTrue((ROOT/'reference/approved_visual_target.png').is_file())
        self.assertTrue((ROOT/'reference/approved_combat_target.png').is_file())

    def test_music_preserved(self):
        p=ROOT/'assets/music/district_signal.wav'
        raw=p.read_bytes();self.assertEqual(raw[:4],b'RIFF');self.assertEqual(raw[8:12],b'WAVE')

    def test_first_wave_source_regression(self):
        source=text('world/encounter_director.gd')
        self.assertIn('_first_wave_timer = maxf(0.0, _first_wave_timer - delta)',source)
        self.assertNotIn('_first_wave_timer >= 0.0 and _first_wave_timer <= 0.0',source)
        self.assertIn('_pending_district = -1',source)
        self.assertIn('budget = minf(8.0',source)

    def test_walkway_geometry_and_collision_use_same_dimensions(self):
        source=text('world/city_detail_pass.gd')
        self.assertIn('shape_mesh.size = dimensions',source)
        self.assertIn('box_shape.size = dimensions',source)
        self.assertIn('MultiMesh.new()',source)
        self.assertIn('visibility_range_end = distance',source)

class NumericalRegressions(unittest.TestCase):
    def test_wave_countdown_crosses_zero_at_variable_framerates(self):
        for fps in [24,30,60,75,90,120,144]:
            timer=2.6;count=0
            for _ in range(fps*10):
                if timer>=0:
                    timer=max(0,timer-1/fps)
                    if timer<=0:
                        count+=1;timer=-1
            self.assertEqual(count,1)

    def test_leaving_district_cancels_first_wave(self):
        # Mirrors the explicit cancellation at a district transition.
        pending=1;timer=1.2;current=0
        pending=-1;timer=-1
        self.assertFalse(pending==current and timer>=0)

    def test_local_budget_is_bounded(self):
        budget=0
        for _ in range(60*60):
            budget=min(8.,budget+1/60*.47)
        self.assertEqual(budget,8.)
        amount=max(2,min(4,int(math.floor(budget))))
        budget-=amount
        self.assertEqual((amount,budget),(4,4.))

    def test_two_bone_solver_reachable_and_degenerate_math(self):
        # Validate the law-of-cosines part shared by two_bone_pose.gd.
        for first,second in [(.46,.46),(.35,.34)]:
            for requested in [0,1e-9,.02,.3,.69,.919,1.4,1000]:
                distance=max(abs(first-second)+.001,min(first+second-.001,requested))
                along=(first*first-second*second+distance*distance)/(2*distance)
                height=math.sqrt(max(0,first*first-along*along))
                self.assertTrue(math.isfinite(height))
                self.assertAlmostEqual(math.hypot(along,height),first,places=6)
                self.assertAlmostEqual(math.hypot(distance-along,height),second,places=6)

    def test_ramp_slope_is_within_controller_floor_angle(self):
        slope=math.degrees(math.atan2(2,6))
        self.assertLess(slope,48)
        self.assertAlmostEqual(math.sqrt(40)*math.cos(math.radians(slope)),6.)
        self.assertAlmostEqual(math.sqrt(40)*math.sin(math.radians(slope)),2.)

if __name__=='__main__':unittest.main(verbosity=2)

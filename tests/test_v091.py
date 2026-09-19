"""Source contracts and Python reference calculations; NOT Godot execution.
The optional .gd engine test checks the actual helper and input router separately.
"""
from pathlib import Path
import itertools
import math
import re
import unittest

ROOT = Path(__file__).resolve().parents[1]

def source(path):
    return (ROOT / path).read_text(encoding="utf-8")

def smooth(a, b, x):
    v = max(0.0, min(1.0, (x-a)/(b-a)))
    return v*v*(3-2*v)

def layout_reference(width, height, user_scale):
    """Read button constants from the shipped helper, mirror its rectangle math."""
    code = source("components/input/touch_layout.gd")
    pattern = r'buttons\[&"(\w+)"\] = Rect2\(Vector2\(right - ([\d.]+) \* scale_factor, bottom - ([\d.]+) \* scale_factor\), Vector2\(([\d.]+), ([\d.]+)\) \* scale_factor\)'
    raw = re.findall(pattern, code)
    assert len(raw) == 6, "Touch helper geometry schema changed: update test"
    scale = max(.55, min(1.3, min(width/1280, height/720))) * max(.8, min(1.25, user_scale))
    right, bottom = width-22*scale, height-22*scale
    buttons = {a: (right-float(x)*scale, bottom-float(y)*scale, float(w)*scale, float(h)*scale)
               for a,x,y,w,h in raw}
    return buttons, (111*scale, bottom-93*scale), 75*scale

def overlap(a, b):
    return a[0] < b[0]+b[2] and a[0]+a[2] > b[0] and a[1] < b[1]+b[3] and a[1]+a[3] > b[1]

class MobileClaritySourceContracts(unittest.TestCase):
    def test_separate_background_controls_wired_in_both_scenes(self):
        shader = source("shaders/ascii_post.gdshader")
        for key in ["background_calm", "color_saturation"]:
            self.assertIn("uniform float " + key, shader)
            for script in ["scripts/game.gd", "world/readability_lab.gd"]:
                self.assertIn('set_shader_parameter("'+key+'", SettingsManager.'+key+')', source(script))
            self.assertIn('cfg.set_value("readability", "'+key+'", '+key+')', source("core/settings_manager.gd"))

    def test_shader_has_no_time_driven_flicker(self):
        shader = re.sub(r'//[^\n]*', '', source("shaders/ascii_post.gdshader"))
        self.assertNotRegex(shader, r'\bTIME\b|\bFRAGCOORD\b|\brand\(')
        # v0.10.1 keeps the time-independent palette, removes low-coverage gain.
        self.assertIn("float glyph = mix(glyph_mask", shader)
        self.assertNotIn("glyph_coverage(", shader)
        self.assertIn("float importance = max(local_shape, highlight)", shader)

    def test_readability_still_uses_glyph_atlas_not_plain_3d(self):
        s = source("shaders/ascii_post.gdshader")
        self.assertIn("texture(glyph_atlas, vec2(", s)
        self.assertIn("vec3 result = mix(background, ink, glyph)", s)
        self.assertNotIn("hint_normal_roughness_texture", s)

    def test_damage_uses_edge_shader_and_wall_time(self):
        s = source("components/damage_feedback.gd")
        self.assertIn('preload("res://shaders/damage_vignette.gdshader")', s)
        self.assertIn("Time.get_ticks_msec() - _flash_start_msec", s)
        self.assertIn("/ 220.0", s)
        self.assertIn("impact * edge", source("shaders/damage_vignette.gdshader"))
        self.assertNotIn("color.a", s)

    def test_actor_depth_testing_not_bypassed(self):
        s = source("shaders/actor_readability.gdshader")
        self.assertNotIn("depth_test_disabled", s)
        self.assertIn("actor_fill", s)
        self.assertIn("SHADING_MODE_UNSHADED", source("rendering/actor_readability.gd"))

    def test_shared_router_and_visual_geometry(self):
        for script in ["scripts/mobile_controls.gd", "ui/touch_controls_view.gd"]:
            self.assertIn('preload("res://components/input/touch_layout.gd")', source(script))
        self.assertIn('layout = LAYOUT.build', source("ui/touch_controls_view.gd"))

    def test_fire_finger_can_rotate_camera(self):
        s = source("scripts/mobile_controls.gd")
        self.assertIn('if action == &"shoot" and _look_finger == -1:', s)
        self.assertIn('_look_finger = index', s)
        self.assertIn('elif index == _look_finger and is_instance_valid(_player):', s)
        self.assertIn('"apply_look_delta", normalized_delta', s)

    def test_touch_reset_on_pause_focus_loss_settings_and_death(self):
        s = source("scripts/mobile_controls.gd")
        self.assertIn('NOTIFICATION_APPLICATION_FOCUS_OUT', s)
        self.assertIn('SettingsManager.changed.connect(_reset_controls)', s)
        self.assertIn('not get_tree().paused', s)
        self.assertIn('"control_enabled"', s)
        self.assertIn('func _exit_tree() -> void:\n    _reset_controls()', s)
        for action in ['shoot', 'dash', 'jump', 'interact', 'weapon_next', 'aim']:
            self.assertIn('&"'+action+'"', s.split('func _reset_controls()', 1)[1].split('func _refresh_view()', 1)[0])

    def test_emulated_mouse_does_not_share_combat_binding(self):
        s = source("scripts/mobile_controls.gd")
        self.assertIn("InputEventMouseButton.new().device", s)
        self.assertIn("physical.device = native_device", s)
        self.assertIn("InputMap.action_erase_event(action, binding)", s)
        self.assertIn("_restore_mouse_bindings()", s)
        self.assertIn("InputEvent.DEVICE_ID_EMULATION", source("tests/mobile_clarity_smoke.gd"))

    def test_touch_styles_cached_not_allocated_in_draw(self):
        s = source("ui/touch_controls_view.gd")
        draw = s.split('func _draw()', 1)[1]
        self.assertNotIn('.new()', draw)
        self.assertIn('draw_style_box(_pressed_style if selected else _idle_style', draw)

    def test_mobile_hud_leaves_relics_in_menu(self):
        main = source("scripts/game.gd")
        self.assertIn('if mobile_profile:\n        _layout_mobile_hud()', main)
        self.assertIn('_top_left_box(health_bar, Rect2(26, 70, 240, 18))', main)
        self.assertIn('items_panel.visible = false', main)
        self.assertIn('CURRENT RELICS', source("ui/settings_menu.gd"))
        self.assertIn('inventory.summary()', source("ui/settings_menu.gd"))

    def test_camera_shoulder_offset_on_collision_arm(self):
        scene = source("scenes/Player.tscn")
        arm = scene.split('[node name="SpringArm3D"', 1)[1].split('[node ', 1)[0]
        camera = scene.split('[node name="Camera3D"', 1)[1].split('[node ', 1)[0]
        self.assertIn('position = Vector3(0.48, 0.08, 0)', arm)
        self.assertNotIn('position = Vector3(0.48', camera)
        self.assertIn('spring.add_excluded_object(get_rid())', source("scripts/player.gd"))

    def test_aim_barrel_occlusion_stops_damage_path(self):
        probe = source("components/weapon/aim_probe.gd")
        self.assertIn('PhysicsRayQueryParameters3D.create(shoulder, origin, 1)', probe)
        self.assertIn('barrel_query.hit_from_inside = true', probe)
        self.assertIn('barrel_query.exclude = [actor.get_rid()]', probe)
        self.assertIn('"barrel_blocked": true', probe)
        shoot = source("scripts/player.gd").split('func _shoot()', 1)[1].split('func _resolve_camera_aim_point()', 1)[0]
        self.assertIn('return\n\n    for i in range(shot_count)', shoot)
        self.assertIn('safe_origin, obstruction, tracer_color', shoot)

    def test_lab_has_no_story_or_director_instance(self):
        combined = source("scenes/ReadabilityLab.tscn") + source("world/readability_lab.gd")
        self.assertNotIn('story_director.gd', combined)
        self.assertNotIn('encounter_director.gd', combined)
        self.assertNotIn('cfg.save(', combined)
        self.assertIn('target.set_physics_process(false)', combined)
        self.assertIn('KEY_F6', combined)
        self.assertIn('target.connect("died", _on_target_down.bind(at, archetype))', combined)

    def test_scene_switch_explicitly_ends_run(self):
        menu = source("ui/settings_menu.gd")
        self.assertIn('TEST COURTYARD (ends current run)', menu)
        self.assertIn('RETURN TO CITY (new run)', menu)
        self.assertIn('get_tree().paused = false', menu)
        self.assertIn('Engine.time_scale = 1.0', menu)

    def test_performance_overlay_not_gpu_benchmark(self):
        s = source("ui/performance_overlay.gd")
        self.assertIn('Time.get_ticks_usec()', s)
        self.assertIn('_samples.size() > 120', s)
        self.assertIn('SettingsManager.performance_hud_enabled', s)
        self.assertIn('P95', s)
        self.assertNotIn('Performance.TIME_FPS', s)

    def test_build_versions_match(self):
        self.assertIn('config/version="0.12.1-alpha"', source("project.godot"))
        self.assertIn('version/name="0.12.1-alpha"', source("export_presets.cfg"))
        self.assertIn('version/code=16', source("export_presets.cfg"))

class MobileClarityReferenceMath(unittest.TestCase):
    def test_buttons_are_disjoint_and_inside_landscape_viewports(self):
        for width,height in [(640,360), (960,540), (1280,720), (1536,720), (1920,1080), (2560,1440)]:
            for scale in [.8, 1., 1.25]:
                with self.subTest(viewport=(width,height),scale=scale):
                    buttons, _, _ = layout_reference(width,height,scale)
                    for name,(x,y,w,h) in buttons.items():
                        self.assertGreaterEqual(x,0,name); self.assertGreaterEqual(y,0,name)
                        self.assertLessEqual(x+w,width,name); self.assertLessEqual(y+h,height,name)
                    for (an,a),(bn,b) in itertools.combinations(buttons.items(),2):
                        self.assertFalse(overlap(a,b), (an,bn))

    def test_buttons_do_not_overlap_thumb_stick(self):
        for width,height in [(640,360),(1280,720),(1920,1080)]:
            for scale in [.8,1.,1.25]:
                buttons,center,radius = layout_reference(width,height,scale)
                joystick = (center[0]-radius,center[1]-radius,2*radius,2*radius)
                for name,rect in buttons.items():
                    self.assertFalse(overlap(joystick,rect), name)

    def test_background_contrast_changes_do_not_darken_average(self):
        # v0.9.2 replaces the old "calm = fewer lit pixels" formula.
        for target in [.02, .05, .1, .2, .4, .7, .9]:
            for coverage in [.05, .10, .25, .39]:
                for bed_ratio in [.15, .35, .70]:
                    ink = min(target * (1-(1-coverage)*bed_ratio)/coverage, 1.)
                    bed = max((target-ink*coverage)/(1-coverage),0.)
                    actual = bed*(1-coverage)+ink*coverage
                    self.assertAlmostEqual(actual,target,places=8)

    def test_hit_mask_leaves_center_clear_and_edges_visible(self):
        for u,v in [(.5,.5),(.45,.5),(.5,.60),(.6,.55)]:
            d=math.hypot((u-.5)*2*.9,(v-.5)*2)
            self.assertEqual(smooth(.46,1.1,d),0)
        for u,v in [(0,.5),(1,.5),(.5,0),(.5,1)]:
            d=math.hypot((u-.5)*2*.9,(v-.5)*2)
            self.assertGreater(smooth(.46,1.1,d),.75)

    def test_hit_fade_has_wall_time_cutoff(self):
        alpha=[]
        for millis in [0,55,110,165,220,1000]:
            t=max(0,min(1,1-millis/220))
            alpha.append(.3*t*t)
        self.assertEqual(alpha,sorted(alpha,reverse=True))
        self.assertEqual(alpha[-2:], [0,0])

    def test_ramp_high_end_meets_landing(self):
        self.assertIn('ramp.rotation.x = atan2(2.0, 8.0)', source('world/readability_lab.gd'))
        angle=math.atan2(2,8)
        length=math.sqrt(68)
        high_y=.95+math.sin(angle)*length/2 + .1*math.cos(angle)
        low_y=.95-math.sin(angle)*length/2 + .1*math.cos(angle)
        high_z=4.9-math.cos(angle)*length/2
        self.assertLess(abs(high_y-2),.08)
        self.assertGreaterEqual(low_y,-.06)
        self.assertLessEqual(high_z,1)
        self.assertLess(math.degrees(angle),48)

if __name__ == '__main__':
    unittest.main(verbosity=2)

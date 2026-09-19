extends SceneTree
var checks: int=0
var failures: int=0
func _initialize() -> void: call_deferred("_run")
func expect(ok: bool, label: String) -> void:
    checks+=1
    if not ok:
        failures+=1
        print("SETTINGS_013_FAIL: ",label)
func _run() -> void:
    # Isolated QA user directory supplied by runner, never the player's profile.
    var old: ConfigFile=ConfigFile.new()
    old.set_value("meta","schema",4)
    old.set_value("graphics","render_scale",0.92)
    old.set_value("graphics","ascii_cell_px",4.0)
    old.set_value("readability","surface_fill",0.64)
    old.set_value("audio","music_volume",0.27)
    old.set_value("audio","sfx_volume",0.44)
    old.set_value("controls","mouse_sensitivity_scale",1.37)
    old.set_value("controls","touch_look_sensitivity",1.62)
    old.set_value("ambient","volume",0.41)
    old.save(SettingsManager.SAVE_PATH)
    var archive: FileAccess=FileAccess.open("user://ascii_rain_profile.cfg",FileAccess.WRITE)
    archive.store_string("[archive]\nfixture_marker=123\n")
    archive.close()
    var archive_before: String=FileAccess.get_sha256("user://ascii_rain_profile.cfg")
    SettingsManager.load_settings()
    for i in range(3): await process_frame
    expect(FileAccess.file_exists(SettingsManager.PREVIOUS_SETTINGS),"backup exists")
    var backup: ConfigFile=ConfigFile.new()
    expect(backup.load(SettingsManager.PREVIOUS_SETTINGS)==OK,"backup readable")
    expect(float(backup.get_value("readability","surface_fill"))==0.64,"original graphics backed up")
    expect(SettingsManager.ascii_cell_px==6.0,"new desktop cell default")
    expect(SettingsManager.surface_fill==0.22,"new mood gap default")
    expect(SettingsManager.visual_style==0,"reference style active")
    expect(SettingsManager.music_volume==0.27,"music retained")
    expect(SettingsManager.sfx_volume==0.44,"SFX retained")
    expect(SettingsManager.mouse_sensitivity_scale==1.37,"mouse retained")
    expect(SettingsManager.touch_look_sensitivity==1.62,"touch retained")
    expect(SettingsManager.ambient_volume==0.41,"ambience retained")
    expect(FileAccess.get_sha256("user://ascii_rain_profile.cfg")==archive_before,"archive untouched")
    SettingsManager.update_surface_fill(0.17)
    SettingsManager.update_ascii_cell(5.0)
    for i in range(3): await process_frame
    SettingsManager.load_settings()
    expect(SettingsManager.surface_fill==0.17,"new-schema custom gap survives reload")
    expect(SettingsManager.ascii_cell_px==5.0,"new-schema custom cell survives reload")
    SettingsManager.apply_preset(0)
    expect(SettingsManager.surface_fill==0.17,"quality does not replace tone")
    SettingsManager.apply_visual_style(1)
    expect(SettingsManager.surface_fill==0.46,"readable style applied")
    expect(SettingsManager.music_volume==0.27,"style does not reset music")
    SettingsManager.apply_visual_style(2)
    expect(SettingsManager.ascii_cell_px==8.0,"mobile native glyph atlas size")
    expect(not SettingsManager.shadows_enabled,"mobile preset disables expensive shadows")
    expect(SettingsManager.render_scale==0.78,"mobile render scale")
    expect(SettingsManager.mouse_sensitivity_scale==1.37,"style does not reset controls")
    root.get_node("AudioManager").call("stop_all")
    root.get_node("AudioManager/DistrictMusic").stream=null
    for i in range(5): await physics_frame
    print("SETTINGS_013_NATIVE: ",checks," checks / ",failures," failures")
    quit(0 if failures==0 else 1)

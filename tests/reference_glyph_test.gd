extends SceneTree
const BINDING=preload("res://rendering/ascii_atlas_binding.gd")
const POST: Shader=preload("res://shaders/ascii_post.gdshader")
const LEVELS: Array[float]=[0.0,0.005,0.02,0.05,0.1,0.15,0.2,0.3,0.5,0.8,1.0]
var checks: int=0
var failures: int=0
var results: Array=[]
func _initialize() -> void: call_deferred("_run")
func check(ok: bool,message: String) -> void:
    checks+=1
    if not ok:
        failures+=1
        print("REFERENCE_GLYPH_FAIL: ",message)
func draw_image(view: SubViewport) -> Image:
    for i in range(3): await process_frame
    await RenderingServer.frame_post_draw
    return view.get_texture().get_image()
func stats(image: Image,cell: Vector2i,band: int) -> Dictionary:
    var total: float=0.0
    var max_value: float=0.0
    var min_value: float=1.0
    var distinct: Dictionary={}
    for y in range(cell.y):
        for x in range(cell.x):
            var pixel: Color=image.get_pixel((band*6+2)*cell.x+x,cell.y*2+y)
            var v: float=(pixel.r+pixel.g+pixel.b)/3.0
            max_value=maxf(v,max_value)
            min_value=minf(v,min_value)
            total+=v
            distinct[roundi(v*255.0)]=true
    return {"mean":total/float(cell.x*cell.y),"max":max_value,"min":min_value,"values":distinct.size()}
func _run() -> void:
    SettingsManager.apply_visual_style(0)
    for width in range(4,11):
        var cell: Vector2i=Vector2i(width,int(floor(width*1.5+0.5)))
        var view: SubViewport=SubViewport.new()
        view.size=Vector2i(width*6*LEVELS.size(),cell.y*6)
        view.disable_3d=true
        view.render_target_update_mode=SubViewport.UPDATE_ALWAYS
        root.add_child(view)
        for band in range(LEVELS.size()):
            var patch: ColorRect=ColorRect.new()
            patch.position=Vector2(band*width*6,0)
            patch.size=Vector2(width*6,cell.y*6)
            patch.color=Color(LEVELS[band],LEVELS[band],LEVELS[band],1)
            view.add_child(patch)
        var effect: ColorRect=ColorRect.new()
        effect.size=Vector2(view.size)
        var mat: ShaderMaterial=ShaderMaterial.new()
        mat.shader=POST
        BINDING.apply(mat,float(width))
        mat.set_shader_parameter("bloom_strength",0.0)
        effect.material=mat
        view.add_child(effect)
        var image: Image=await draw_image(view)
        var rows: Array=[]
        var previous: float=-1.0
        for band in range(LEVELS.size()):
            var row: Dictionary=stats(image,cell,band)
            check(float(row["mean"])>=previous-0.004,"ordered luminance / %d / %d" % [width,band])
            previous=float(row["mean"])
            rows.append(row)
        check(float(rows[0]["max"])<0.004,"true black stays black")
        check(float(rows[6]["max"])<0.55,"dim wall is not white lettering")
        check(float(rows[8]["max"])-float(rows[8]["min"])>0.2,"distinct strokes at medium input")
        check(float(rows[8]["min"])<float(rows[8]["max"])*0.3,"dark gaps rather than grey bed")
        check(float(rows[6]["mean"])>0.01,"visible dim-tone glyphs")
        var second: Image=await draw_image(view)
        check(image.get_data()==second.get_data(),"static input does not flicker")
        mat.set_shader_parameter("surface_fill",0.6)
        var filled: Image=await draw_image(view)
        var filled_row: Dictionary=stats(filled,cell,8)
        check(float(filled_row["min"])>float(rows[8]["min"]),"readability control lifts gap only when requested")
        check(absf(float(filled_row["max"])-float(rows[8]["max"]))<0.04,"gap slider does not wash out ink peak")
        results.append({"width":width,"rows":rows})
        view.queue_free()
        await process_frame
    DirAccess.make_dir_recursive_absolute("user://captures")
    var file: FileAccess=FileAccess.open("user://captures/reference_glyph_pixels.json",FileAccess.WRITE)
    file.store_string(JSON.stringify({"checks":checks,"failures":failures,"rows":results},"  "))
    file.close()
    root.get_node("AudioManager").call("stop_all")
    root.get_node("AudioManager/DistrictMusic").stream=null
    await create_timer(0.12,true,false,true).timeout
    print("REFERENCE_GLYPH_NATIVE: ",checks," checks / ",failures," failures")
    quit(0 if failures==0 else 1)

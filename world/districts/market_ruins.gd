extends "res://world/districts/city_modules.gd"

func _ready() -> void:
    district_id = &"market_ruins"
    init_palette()
    # A U-shaped gallery. The centre of the courtyard remains at street level.
    deck("NorthGallery", Vector3(44,5.5,30), Vector2(36,8), &"market_north")
    deck("SouthGallery", Vector3(44,5.5,56), Vector2(36,8), &"market_south")
    deck("EastGallery", Vector3(58,5.5,43), Vector2(8,18), &"market_east")
    ramp("NorthAscent", Vector3(32,0,48), Vector3(32,5.5,34), 7.0, &"market_north_ramp")
    ramp("SouthAscent", Vector3(50,0,38), Vector3(50,5.5,52), 6.0, &"market_south_ramp")
    for at in [Vector3(27,0,27),Vector3(61,0,27),Vector3(61,0,59),Vector3(27,0,59),Vector3(58,0,36),Vector3(58,0,50)]:
        box("GalleryPier", at + Vector3.UP * 2.525, Vector3(0.8,5.05,0.8), 1)
        trim(at + Vector3.UP * 0.5, Vector3(1.12,1.0,1.12), 0)
    rail("NorthEdge", Vector3(26.2,5.5,26.2), Vector3(61.8,5.5,26.2))
    rail("SouthEdge", Vector3(26.2,5.5,59.8), Vector3(61.8,5.5,59.8))
    rail("EastEdge", Vector3(61.8,5.5,26.2), Vector3(61.8,5.5,59.8))
    rail("InnerEast", Vector3(54.2,5.5,34.2), Vector3(54.2,5.5,51.8))
    # Real landing openings: rail segments stop short of each ramp.
    rail("NorthInnerA", Vector3(26.2,5.5,33.8), Vector3(28.3,5.5,33.8))
    rail("NorthInnerB", Vector3(35.7,5.5,33.8), Vector3(53.8,5.5,33.8))
    rail("SouthInnerA", Vector3(26.2,5.5,52.2), Vector3(46.8,5.5,52.2))
    rail("SouthInnerB", Vector3(53.2,5.5,52.2), Vector3(53.8,5.5,52.2))
    for z in [30.0,56.0]:
        rail("WestEdge", Vector3(26.2,5.5,z-3.8), Vector3(26.2,5.5,z+3.8))
    # Ground-floor stalls: open fronts face the courtyard, no fake doors in solids.
    _stall(Vector3(39,0,28), "08 // MEMORY REPAIR")
    _stall(Vector3(49,0,58), "12 // EXCHANGE CLOSED", PI)
    _stall(Vector3(65,0,43), "SERVICE // 04", -PI*0.5)
    # Recognisable outer wall with deep piers, a broken canopy and vents.
    for x in [29.0,39.0,49.0,59.0]:
        box("BackWall", Vector3(x,9.0,24), Vector3(4.0 if x==39.0 or x==49.0 else 8.5,18.0,1.5), 1)
        for y in [3.2,8.5,13.0]:
            trim(Vector3(x,y,24.80),Vector3(3.4 if x==39.0 or x==49.0 else 6.5,0.16,0.12),3)
        trim(Vector3(x-(1.6 if x==39.0 or x==49.0 else 3.4),8.0,24.95),Vector3(0.3,16.0,0.4),0)
    box("BrokenCanopyA",Vector3(37,10.5,29),Vector3(15,0.45,7),0)
    box("BrokenCanopyB",Vector3(57,10.5,29),Vector3(8,0.45,7),0)
    # Visible posts support the overhead canopy; leave >4.8m headroom upstairs.
    for x in [28.0,44.0,61.0]:
        box("CanopyPost",Vector3(x,8,27),Vector3(0.32,5,0.32),1)
    box("MarketEntryHeader",Vector3(44,7.4,21),Vector3(23,1.2,0.65),1)
    for x in [32.5,55.5]:
        box("EntryPier",Vector3(x,3.4,21),Vector3(0.6,6.8,0.6),0)
    sign_label("MARKET // 03",Vector3(44,7.35,20.62),76,PI)
    sign_label("GALLERY  /  UP",Vector3(32,1.7,49.8),38,0)
    sign_label("GALLERY  /  UP",Vector3(50,1.7,36.2),38,PI)
    lamp(Vector3(39,4.65,30))
    lamp(Vector3(50,4.65,56))
    # Quiet warm insets on the upper route, not continuous neon on every edge.
    for x in [30.0,40.0,50.0,60.0]:
        trim(Vector3(x,5.52,27.0),Vector3(0.8,0.025,0.25),3)
        trim(Vector3(x,5.52,59.0),Vector3(0.8,0.025,0.25),3)
    commit_trim()

func _stall(at: Vector3, text: String, yaw: float = 0.0) -> void:
    var orient: Basis = Basis(Vector3.UP, yaw)
    for data in [[Vector3(0,1.5,-1.7),Vector3(5.0,3.0,0.24)],[Vector3(-2.5,1.5,0),Vector3(0.24,3.0,3.6)],[Vector3(2.5,1.5,0),Vector3(0.24,3.0,3.6)],[Vector3(0,3.1,0),Vector3(5.5,0.3,4.0)],[Vector3(0,0.8,0.8),Vector3(4.5,1.6,0.6)]]:
        var part: Node3D = box("MarketStall",at+orient*data[0],data[1],0)
        part.basis = orient
    sign_label(text,at+orient*Vector3(0,2.6,1.88),27,yaw)
    for x in [-1.5,-0.5,0.5,1.5]:
        trim(at+orient*Vector3(x,1.72,0.7),Vector3(0.58,0.20,0.6),2,orient)

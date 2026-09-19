extends "res://world/districts/civic_modules.gd"

var dish: Node3D = null
var relay_board: Label3D = null

func _ready() -> void:
    district_id = &"null_terminal"
    init_palette()
    mats[0].albedo_color=Color(0.16,0.18,0.21)
    mats[1].albedo_color=Color(0.09,0.11,0.14)
    # U-shaped roof network around (not over) the existing WATCHER courtyard.
    for side in [-1.0,1.0]:
        var x: float=29.0*side
        var id_suffix: String="west" if side<0 else "east"
        deck("RelayRoof",Vector3(x,10,-66),Vector2(16,20),StringName("relay_"+id_suffix))
        var ramp_x: float=x if side<0 else 25.5
        ramp("RelayAscent",Vector3(ramp_x,0,-23),Vector3(ramp_x,10,-56),7.4,StringName("relay_ramp_"+id_suffix))
        # Supports and a setback equipment store give an actual roof silhouette.
        for z in [-74.0,-59.0]:
            column("RoofStructuralPier",Vector3(x+side*6.7,4.7,z),9.4,0.55,1)
        rail("OuterRoofRail",Vector3(x+side*7.8,10,-56.2),Vector3(x+side*7.8,10,-75.8))
        rail("FrontRoofL",Vector3(x-7.8,10,-56.2),Vector3(ramp_x-4.0,10,-56.2))
        rail("FrontRoofR",Vector3(ramp_x+4.0,10,-56.2),Vector3(x+7.8,10,-56.2))
        # Opaque acoustic screens prevent trivial shooting down into the boss arena.
        box("ArenaSightScreen",Vector3(x-side*7.7,12.5,-63.8),Vector3(0.5,5.0,15.6),1)
        trim(Vector3(x-side*7.4,14.8,-63.8),Vector3(0.15,0.10,15.0),2)
        box("RoofEquipmentBase",Vector3(x+side*4.9,10.9,-69),Vector3(2.4,1.8,3.2),0)
        trim(Vector3(x+side*4.9,11.85,-69),Vector3(2.6,0.12,3.4),2)
        for z in [-74.0,-63.0]: lamp(Vector3(x,13.8,z),true)
        sign_label("ROOFTOP / RELAY  +10m",Vector3(ramp_x,2.2,-20.8),36)
        floor_insets(Vector3(x+side*6.0,10.03,-57.5),5,Vector3(0,0,-3.4))
    # Third roof physically joins both end decks; no jump needed at any seam.
    deck("NorthRelayRoof",Vector3(0,10,-76),Vector2(42,8),&"relay_north")
    rail("NorthSkyRail",Vector3(-36.8,10,-79.8),Vector3(36.8,10,-79.8))
    # The end decks extend to z=-76, so bridge joins use z=-76..-72.
    deck("WestRearLink",Vector3(-29,10,-78),Vector2(16,4),&"relay_west_link")
    deck("EastRearLink",Vector3(29,10,-78),Vector2(16,4),&"relay_east_link")
    box("NorthArenaScreen",Vector3(0,12.5,-71.8),Vector3(42,5,0.4),1)
    # Small shelter opens toward the north walkway, not a fake solid door.
    for x in [-4.5,4.5]: box("RelayShelterPost",Vector3(x,12.6,-74.5),Vector3(0.32,5.2,0.32),2)
    box("RelayShelterCanopy",Vector3(0,15.3,-75.5),Vector3(10,0.35,6.2),0)
    box("RelayConsoleBacking",Vector3(0,11,-72.5),Vector3(3.2,2.0,0.6),0)
    relay_board=sign_label("RELAY // NO CARRIER",Vector3(0,12.6,-72.84),28,PI)
    column("RelayMast",Vector3(0,18.0,-72.1),11,0.23,2,false)
    dish=Node3D.new()
    dish.name="CalibrationDish"
    dish.position=Vector3(0,20.0,-72.1)
    add_child(dish)
    for i in range(5):
        var fin: Node3D=box("AntennaFin",Vector3(0,0,float(i)*0.45-0.9),Vector3(4.0-absf(float(i)-2.0)*0.6,0.18,0.12),2,false)
        remove_child(fin)
        dish.add_child(fin)
    lamp(Vector3(0,14.7,-76.0),true)
    sign_label("SIGNAL / ABOVE THE INDEX",Vector3(0,15.8,-76),32,PI)
    commit_trim()

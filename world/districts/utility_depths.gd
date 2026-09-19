extends "res://world/districts/civic_modules.gd"

var turbine: Node3D = null
var pressure_board: Label3D = null

func _ready() -> void:
    district_id = &"utility_spine"
    init_palette()
    mats[0].albedo_color=Color(0.28,0.29,0.27)
    mats[1].albedo_color=Color(0.14,0.16,0.18)
    mats[2].albedo_color=Color(0.37,0.32,0.23)
    deck("MaintenanceLowerFloor",Vector3(-55.5,-6,-18),Vector2(41,58),&"utility_lower")
    # Existing street slab remains as the roof. Only ramp openings are cut out.
    box("WestRetainingWall",Vector3(-76.2,-3,-18),Vector3(0.4,6,58),1)
    box("EastRetainingWall",Vector3(-34.8,-3,-18),Vector3(0.4,6,58),1)
    box("NorthRetainingWall",Vector3(-55.5,-3,-47.2),Vector3(41,6,0.4),1)
    box("SouthRetainingWall",Vector3(-55.5,-3,11.2),Vector3(41,6,0.4),1)
    ramp("SouthServiceRamp",Vector3(-66,0,10),Vector3(-66,-6,-10),7.4,&"utility_south_ramp")
    ramp("NorthServiceRamp",Vector3(-42,-6,-23),Vector3(-42,0,-43),7.4,&"utility_north_ramp")
    # Rim guards at street level. The two entrance ends are deliberately open.
    for x in [-70.0,-62.0]:
        rail("SouthStreetGuard",Vector3(x,0,-11),Vector3(x,0,10))
    rail("SouthOpeningEnd",Vector3(-70,0,-11),Vector3(-62,0,-11))
    for x in [-46.0,-38.0]:
        rail("NorthStreetGuard",Vector3(x,0,-43),Vector3(x,0,-22))
    rail("NorthOpeningEnd",Vector3(-46,0,-22),Vector3(-38,0,-22))
    for at in [Vector3(-66,0,12),Vector3(-42,0,-45)]:
        var face: float = 0.0 if at.z > 0 else PI
        sign_label("UTILITY // DEPTHS  -6m",at+Vector3.UP*3.4,39,face)
        for side in [-1.0,1.0]:
            column("ServiceEntrancePier",at+Vector3(side*4.3,1.6,0),3.2,0.2,2)
        box("ServiceEntryHeader",at+Vector3.UP*5.4,Vector3(9,0.5,0.4),1)
        lamp(at+Vector3.UP*3.55,true)
    # Wide engine room: all cover is away from ramp landings and circulation paths.
    for at in [Vector3(-54,-6,-30),Vector3(-54,-6,-10)]:
        column("PressureTank",at+Vector3.UP*1.55,3.1,1.65,1)
        column("TankCollar",at+Vector3.UP*2.2,0.18,1.78,2,false)
        trim(at+Vector3(0,1.4,1.62),Vector3(0.32,1.1,0.08),3)
        for angle in [0.0,PI*0.5,PI,PI*1.5]:
            var base: Vector3=at+Vector3(cos(angle)*2.1,0,sin(angle)*2.1)
            column("TankFoot",base+Vector3.UP*0.3,0.6,0.25,0)
    for x in [-72.5,-38.0]:
        for z in [-35.0,-20.0,-5.0]:
            if x > -40.0 and z < -22.0: continue
            box("PowerCabinet",Vector3(x,-4.9,z),Vector3(1.5,2.2,2.1),0)
            trim(Vector3(x,-4.3,z+1.07),Vector3(0.6,0.13,0.05),3)
    # Pipes lie above conservative horde head clearance, not across walk lanes.
    for x in [-73.0,-56.0,-37.0]:
        branch(Vector3(x,-0.85,-40),Vector3(x,-0.85,4),0.19,2)
        for z in [-37.0,-24.0,-11.0,2.0]:
            trim(Vector3(x,-0.53,z),Vector3(0.6,0.12,0.34),0)
    for at in [Vector3(-66,-0.85,-17),Vector3(-43,-0.85,-12),Vector3(-63,-0.85,-37),Vector3(-55,-0.85,4)]:
        lamp(at,true)
    # Actual terminal and mechanism provide a landmark, not an unfiltered artifact.
    box("PressureControl",Vector3(-54,-4.8,-43),Vector3(4,2.4,1.1),0)
    pressure_board=sign_label("PRESSURE // STABLE",Vector3(-54,-3.2,-42.35),30)
    turbine=Node3D.new()
    turbine.name="PressureRotor"
    turbine.position=Vector3(-54,-2,-43)
    add_child(turbine)
    for i in range(6):
        var blade: Node3D=box("RotorBlade",Vector3.ZERO,Vector3(0.15,1.5,0.15),2,false)
        remove_child(blade)
        turbine.add_child(blade)
        blade.rotation.z=float(i)*TAU/6.0
    floor_insets(Vector3(-66,-5.975,-12),7,Vector3(0,0,-4.4))
    sign_label("RETURN / NORTH SERVICE",Vector3(-42,-3.8,-21.0),27)
    sign_label("RETURN / SOUTH SERVICE",Vector3(-66,-3.8,-12.0),27,PI)
    for fixture in get_children():
        if fixture is OmniLight3D:
            (fixture as OmniLight3D).light_energy=3.8
            (fixture as OmniLight3D).omni_range=12.0
    commit_trim()

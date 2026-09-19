extends "res://world/districts/civic_modules.gd"

var irrigation_arm: Node3D = null

func _ready() -> void:
    district_id = &"memory_gardens"
    init_palette()
    mats[0].albedo_color = Color(0.26,0.30,0.26)
    mats[1].albedo_color = Color(0.14,0.19,0.17)
    mats[2].albedo_color = Color(0.47,0.48,0.37)
    mats[4].albedo_color = Color(0.40,0.59,0.47)
    box("GardenPaving",Vector3(-50,0.037,45),Vector3(49,0.035,55),1,false)
    _terraces()
    _pavilion()
    _garden_floor()
    _trees()
    commit_trim()

func _terraces() -> void:
    # Filled lower terrace cannot be mistaken for a traversable low ceiling.
    box("GardenTerraceFill",Vector3(-61,1.375,46),Vector3(18,2.75,20),0,true,&"gardens_terrace")
    ramp("GardenEastAscent",Vector3(-36,0,40),Vector3(-52,2.75,40),7.0,&"gardens_ramp_e")
    ramp("GardenNorthAscent",Vector3(-64,0,20),Vector3(-64,2.75,36),7.0,&"gardens_ramp_n")
    # The raised pavilion has a genuine walkable street underneath it.
    deck("PavilionDeck",Vector3(-35,5.5,59),Vector2(18,22),&"gardens_pavilion")
    ramp("TerraceLink",Vector3(-60,2.75,52),Vector3(-44,5.5,52),7.0,&"gardens_ramp_link")
    ramp("PavilionEastAscent",Vector3(-31,0,29),Vector3(-31,5.5,48),7.0,&"gardens_ramp_pavilion")
    rail("TerraceWest",Vector3(-69.8,2.75,36.2),Vector3(-69.8,2.75,55.8))
    rail("TerraceSouthA",Vector3(-69.8,2.75,55.8),Vector3(-63.8,2.75,55.8))
    rail("TerraceNorthA",Vector3(-69.8,2.75,36.2),Vector3(-67.8,2.75,36.2))
    rail("TerraceNorthB",Vector3(-60.2,2.75,36.2),Vector3(-52.2,2.75,36.2))
    rail("TerraceEastA",Vector3(-52.2,2.75,36.2),Vector3(-52.2,2.75,36.4))
    rail("TerraceEastB",Vector3(-52.2,2.75,43.7),Vector3(-52.2,2.75,48.1))
    rail("PavilionWestA",Vector3(-43.8,5.5,55.8),Vector3(-43.8,5.5,69.8))
    rail("PavilionEast",Vector3(-26.2,5.5,48.2),Vector3(-26.2,5.5,69.8))
    rail("PavilionSouth",Vector3(-43.8,5.5,69.8),Vector3(-26.2,5.5,69.8))
    rail("PavilionNorth",Vector3(-43.8,5.5,48.2),Vector3(-35.0,5.5,48.2))
    for x in [-43.0,-27.0]:
        for z in [49.0,69.0]:
            column("PavilionFooting",Vector3(x,2.52,z),5.05,0.32,1)
    floor_insets(Vector3(-68,2.79,38),5,Vector3(0,0,3.5))
    floor_insets(Vector3(-27.0,5.53,50),6,Vector3(0,0,3.4))
    sign_label("TERRACES / UP",Vector3(-34.5,1.8,40),35,PI*0.5)
    sign_label("PAVILION / UP",Vector3(-31,1.8,27.4),32,PI)

func _pavilion() -> void:
    var center: Vector3 = Vector3(-35,5.5,61)
    for i in range(8):
        var a: float = TAU*float(i)/8.0
        var p: Vector3 = center+Vector3(cos(a)*6.8,0,sin(a)*6.8)
        column("PavilionColumn",p+Vector3.UP*3.0,6.0,0.16,2)
        branch(p+Vector3.UP*6.1,center+Vector3.UP*7.2,0.13,2)
    # Faceted conical canopy, open sides, roof is never a spawn/walkable floor.
    var roof: Node3D = column("PavilionCanopy",center+Vector3.UP*7.0,1.3,7.8,0,false)
    var visual: MeshInstance3D = roof.get_child(0) as MeshInstance3D
    var mesh: CylinderMesh = visual.mesh as CylinderMesh
    mesh.radial_segments=8
    mesh.top_radius=2.7
    mesh.bottom_radius=7.8
    # Real roof collision follows the faceted visible canopy rather than its box.
    var body: StaticBody3D=StaticBody3D.new()
    body.collision_layer=1
    body.collision_mask=0
    body.set_meta("nav_decoration",true)
    body.position=roof.position
    var collision: CollisionShape3D=CollisionShape3D.new()
    collision.shape=mesh.create_convex_shape()
    body.add_child(collision)
    add_child(body)
    column("PavilionOculus",center+Vector3.UP*7.7,0.15,2.9,2,false)
    lamp(center+Vector3.UP*5.8,false)
    for x in [-49.0,-37.0]:
        column("GardenEntryPier",Vector3(x,2.4,23),4.8,0.20,2)
    box("GardenEntryHeader",Vector3(-43,5.2,23.3),Vector3(12.5,0.65,0.4),1)
    sign_label("MEMORY // GARDENS",Vector3(-43,5.2,23.04),56,PI)
    # Upper benches face outward; centre stays clear for movement and aiming.
    for x in [-41.5,-28.5]:
        box("PavilionBench",Vector3(x,6.0,61),Vector3(0.9,1.0,3.0),2)
    box("ClimateConsole",Vector3(-38,6.1,68.5),Vector3(2.0,1.2,0.7),1)
    trim(Vector3(-38,6.73,68.5),Vector3(1.7,0.05,0.5),4)

func _garden_floor() -> void:
    # Shallow catch basin shares ground support; no invisible water/fall hazard.
    var basin: Node3D=column("CatchBasin",Vector3(-58,0.10,65),0.16,6.5,1,false)
    var water_mat: StandardMaterial3D=mats[1].duplicate() as StandardMaterial3D
    water_mat.albedo_color=Color(0.16,0.24,0.21)
    water_mat.roughness=0.16
    (basin.get_child(0) as MeshInstance3D).material_override=water_mat
    for i in range(12):
        var a: float=TAU*float(i)/12.0
        trim(Vector3(-58+cos(a)*6.7,0.13,65+sin(a)*6.7),Vector3(0.24,0.22,3.2),2,Basis(Vector3.UP,-a))
    for x in [-67.0,-56.0]:
        box("GardenPlanter",Vector3(x,0.48,27),Vector3(4.0,0.96,3.0),0)
        trim(Vector3(x,0.99,27),Vector3(3.6,0.06,2.6),1)
    for x in [-52.0,-41.0]:
        box("EntrySeat",Vector3(x,0.50,23),Vector3(3.2,1.0,0.8),2)
    for i in range(6):
        trim(Vector3(-46,0.05,25+i*3),Vector3(1.8,0.025,0.45),2)
    lamp(Vector3(-48,5.5,28),true)
    lamp(Vector3(-64,7.4,47),false)

func _trees() -> void:
    for at in [Vector3(-67,0,26),Vector3(-45,0,27),Vector3(-71,0,64),Vector3(-56,0,70),Vector3(-67,2.75,50),Vector3(-57,2.75,45),Vector3(-28,5.5,68)]:
        column("SyntheticTrunk",at+Vector3.UP*2.0,4.0,0.24,1)
        for i in range(5):
            var a: float=TAU*float(i)/5.0
            var end: Vector3=at+Vector3(cos(a)*2.3,4.7+0.35*float(i%2),sin(a)*2.3)
            branch(at+Vector3.UP*2.7,end,0.13,2)
            for j in range(3):
                var leaf: Vector3=end+Vector3(cos(a+0.65*j)*0.7,0.32*float(j),sin(a+0.65*j)*0.7)
                trim(leaf,Vector3(1.8,0.13,0.48),0,Basis.from_euler(Vector3(0.20,a+0.65*j,0.20)))
            trim(end+Vector3.UP*0.12,Vector3(0.14,0.12,0.14),4)
    # Quiet rotating irrigation head, not an attack or a gameplay light.
    irrigation_arm=Node3D.new()
    irrigation_arm.name="IrrigationArm"
    irrigation_arm.position=Vector3(-58,2.0,65)
    add_child(irrigation_arm)
    for x in [-1.5,1.5]:
        var part: Node3D=box("IrrigationNozzle",Vector3(x,0,0),Vector3(2.8,0.12,0.20),2,false)
        remove_child(part)
        irrigation_arm.add_child(part)
    column("IrrigationSupport",Vector3(-58,1.0,65),2.0,0.13,1)

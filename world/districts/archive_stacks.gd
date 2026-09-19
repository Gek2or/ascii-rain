extends "res://world/districts/civic_modules.gd"

func _ready() -> void:
    district_id = &"archive_row"
    init_palette()
    mats[0].albedo_color = Color(0.29, 0.28, 0.26)
    mats[2].albedo_color = Color(0.48, 0.43, 0.31)
    box("ArchiveCourtPaving",Vector3(51,0.037,-18),Vector3(44,0.035,47),1,false)
    _galleries()
    _vaults()
    _civic_details()
    commit_trim()

func _galleries() -> void:
    for x in [40.0, 62.0]:
        var suffix: String = "west" if x < 51.0 else "east"
        deck("ReadingGallery", Vector3(x,5.5,-25), Vector2(8,26), StringName("archive_" + suffix))
        ramp("ArchiveAscent", Vector3(x,0,4), Vector3(x,5.5,-12), 7.0, StringName("archive_ramp_" + suffix))
        var edge: float = x - 3.8 if x < 51.0 else x + 3.8
        rail("OuterBalustrade", Vector3(edge,5.5,-37.8), Vector3(edge,5.5,-12.2))
        rail("RearBalustrade", Vector3(x-3.8,5.5,-37.8), Vector3(x+3.8,5.5,-37.8))
        var inner: float = x + 3.8 if x < 51.0 else x - 3.8
        rail("GalleryInnerA", Vector3(inner,5.5,-37.8), Vector3(inner,5.5,-34.0))
        rail("GalleryInnerB", Vector3(inner,5.5,-26.0), Vector3(inner,5.5,-20.0))
        for z in [-36.5,-22.5,-13.0]:
            column("ArchivePier", Vector3(edge,2.52,z), 5.05, 0.30, 1)
        floor_insets(Vector3(edge + (0.45 if x < 51.0 else -0.45),5.53,-35),5,Vector3(0,0,5))
        sign_label("READING GALLERY / UP",Vector3(x,1.8,5.6),32)
    for z in [-30.0,-16.0]:
        deck("ReadingBridge",Vector3(51,5.5,z),Vector2(14,8),StringName("archive_bridge_"+str(int(absf(z)))))
        rail("BridgeNorth",Vector3(44,5.5,z-3.8),Vector3(58,5.5,z-3.8))
        rail("BridgeSouth",Vector3(44,5.5,z+3.8),Vector3(58,5.5,z+3.8))
        lamp(Vector3(51,4.75,z),true)
    # Two arched upper ribs frame open sky; no opaque false ceiling in the court.
    for z in [-33.5,-26.5]:
        arch("ArchiveVaultRib",Vector3(51,11.0,z),14.0,0.55,0.6)
        for x in [37.0,65.0]:
            column("VaultRibPier",Vector3(x,8.25,z),5.5,0.22,2)

func _vaults() -> void:
    # Deep stepped masses, buttresses and recessed apertures replace flat boxes.
    box("ArchiveRearWall",Vector3(51,9.0,-43),Vector3(43,18,1.3),1)
    for side in [-1.0,1.0]:
        var x: float = 51.0 + side * 19.0
        box("ArchiveTowerBase",Vector3(x,6.5,-30),Vector3(5,13,22),0)
        box("ArchiveTowerSetback",Vector3(x,17,-33),Vector3(3.6,8,15),0)
        box("ArchiveTowerCrown",Vector3(x,21.35,-33),Vector3(4.8,0.5,16),2)
        for z in [-39.0,-33.0,-27.0,-21.0]:
            trim(Vector3(x-side*2.6,7,z),Vector3(0.24,12.5,0.55),2)
            for y in [2.0,8.0,12.0,17.0]:
                trim(Vector3(x-side*2.68,y,z+0.9),Vector3(0.04,0.65,1.1),4)
    for x in [38.0,51.0,64.0]:
        box("ArchiveIndexCabinet",Vector3(x,5.8,-41.9),Vector3(7.6,11.6,0.8),1)
        for row in range(7):
            for col in range(4):
                var p: Vector3 = Vector3(x-2.7+col*1.8,1.0+row*1.5,-41.35)
                trim(p,Vector3(1.45,1.16,0.22),0)
                trim(p+Vector3(0,0,0.13),Vector3(0.38,0.065,0.025),3)
        trim(Vector3(x,12.1,-41.0),Vector3(8.0,0.32,0.6),2)
    # A freestanding arch is a real entrance, not a labelled wall.
    arch("ArchiveEntryArch",Vector3(51,5.4,0),7.4,0.65,0.8,0)
    for x in [43.3,58.7]:
        column("EntryPillar",Vector3(x,2.7,0),5.4,0.36,0)
    sign_label("ARCHIVE // STACKS",Vector3(51,6.3,0.55),53)
    sign_label("RECORDS REMAIN / READERS ABSENT",Vector3(51,12.3,-41.0),35)

func _civic_details() -> void:
    # Ground cover sits off the through route. Upper caches occupy edge alcoves.
    for x in [46.0,56.0]:
        box("ReadingDesk",Vector3(x,0.75,-24),Vector3(2.0,1.5,1.4),0)
        trim(Vector3(x,1.53,-24),Vector3(1.6,0.05,0.9),2)
        trim(Vector3(x,1.57,-24.35),Vector3(0.9,0.05,0.24),4)
    for z in [-35.0,-22.0]:
        box("ReturnSlot",Vector3(34.0,1.3,z),Vector3(1.0,2.6,1.4),1)
        trim(Vector3(34.55,1.65,z),Vector3(0.04,0.16,0.95),3)
    box("CatalogueScreenBacking",Vector3(56.5,2.65,-4.0),Vector3(4.6,1.1,0.25),1)
    sign_label("CATALOGUE // 2800",Vector3(56.5,3.5,-3.82),29)
    lamp(Vector3(51,10.8,-36),false)
    floor_insets(Vector3(51,0.045,-4),7,Vector3(0,0,-4.5))
    for x in [31.0,71.0]:
        for z in [-38.0,-30.0,-22.0]:
            trim(Vector3(x,1.7,z),Vector3(0.85,1.8,0.25),1)
            for row in range(6):
                trim(Vector3(x,1.0+row*0.23,z+0.16),Vector3(0.72,0.065,0.05),2)

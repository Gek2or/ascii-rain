extends "res://world/districts/city_modules.gd"

func _ready() -> void:
    district_id = &"signal_concourse"
    init_palette()
    for side in [-1.0,1.0]:
        var x: float = side * 12.0
        deck("PassengerPlatform",Vector3(x,5.5,64),Vector2(12,16), &"transit_west" if side < 0 else &"transit_east")
        ramp("ConcourseAscent",Vector3(x,0,40),Vector3(x,5.5,56),7.0,&"transit_ramp_w" if side < 0 else &"transit_ramp_e")
        box("PlatformRoof",Vector3(x,10.75,64),Vector3(12.5,0.45,17),0)
        for z in [57.0,71.0]:
            for edge in [-1.0,1.0]:
                box("PlatformColumn",Vector3(x+edge*5.4,5.1,z),Vector3(0.5,10.2,0.5),1)
        rail("PlatformOuterRail",Vector3(x+side*5.8,5.5,56.2),Vector3(x+side*5.8,5.5,71.8))
        rail("PlatformRearRail",Vector3(x-5.8,5.5,71.8),Vector3(x+5.8,5.5,71.8))
        # Inner edge is interrupted by the 8m bridge, no invisible fence at its ends.
        rail("PlatformInnerA",Vector3(x-side*5.8,5.5,56.2),Vector3(x-side*5.8,5.5,60.0))
        rail("PlatformInnerB",Vector3(x-side*5.8,5.5,68.0),Vector3(x-side*5.8,5.5,71.8))
        for z in [58.0,61.0,64.0,67.0,70.0]:
            trim(Vector3(x+side*4.0,5.53,z),Vector3(0.25,0.025,0.8),3)
        lamp(Vector3(x,10.3,61),false)
        sign_label("PLATFORM  /  UP",Vector3(x,1.7,38.0),40,PI)
        # Strong structural beams, not window-texture boxes.
        trim(Vector3(x,5.0,64),Vector3(11.6,0.18,15.6),1)
    deck("ConcourseBridge",Vector3(0,5.5,64),Vector2(12,8),&"transit_bridge")
    rail("BridgeNorth",Vector3(-6,5.5,60.2),Vector3(6,5.5,60.2))
    rail("BridgeSouth",Vector3(-6,5.5,67.8),Vector3(6,5.5,67.8))
    # Public concourse at grade remains passable directly below the bridge.
    for z in [45.0,53.0,61.0,69.0]:
        trim(Vector3(0,0.045,z),Vector3(5.4,0.018,0.16),2)
    _abandoned_pod(Vector3(-12,5.5,66))
    box("DispatchBoothRear",Vector3(12,7.1,71),Vector3(4.6,3.2,0.2),1)
    box("DispatchDesk",Vector3(12,6.2,69.2),Vector3(4.2,1.4,0.8),0)
    trim(Vector3(12,7.0,69.0),Vector3(3.0,0.13,0.45),4)
    sign_label("CONTROL // NO OPERATOR",Vector3(12,8.3,70.8),32,PI)
    box("TransitTitleFrame",Vector3(0,9.7,59.8),Vector3(13.5,2,0.4),1,false)
    sign_label("TRANSIT // SPINE",Vector3(0,9.7,59.56),68,PI)
    # Separate inaccessible line for ambient transit. No links/spawns or damage.
    box("DistantTransitTrack",Vector3(0,13.1,77.5),Vector3(155,0.5,3.8),1,false)
    for x in range(-72,73,18):
        box("TrackSupport",Vector3(float(x),6.3,77.5),Vector3(1.0,12.6,1.2),1)
        trim(Vector3(float(x),13.43,75.75),Vector3(1.8,0.08,0.14),4)
    commit_trim()

func _abandoned_pod(at: Vector3) -> void:
    box("BrokenPodLower",at+Vector3(0,0.5,0),Vector3(3.4,1.0,7.2),1)
    box("BrokenPodRoof",at+Vector3(0,2.5,0),Vector3(3.4,0.22,7.2),0)
    for x in [-1.65,1.65]:
        for z in [-3.35,0.0,3.35]:
            box("PodRib",at+Vector3(x,1.6,z),Vector3(0.18,2.0,0.20),2)
        for z in [-2.1,1.5]:
            trim(at+Vector3(x,1.8,z),Vector3(0.05,0.6,1.3),4)
    sign_label("OUT OF SERVICE",at+Vector3(0,1.6,-3.65),28,PI)

extends "res://world/districts/civic_modules.gd"
# Art-direction sample on the existing MARKET wall footprints, not new terrain.
# High masses frame the court; repeated facade trim is spatially batched.
func _ready() -> void:
    district_id=&"market_ruins"
    init_palette()
    for record in [[29.0,8.5,34.0],[39.0,4.0,27.0],[49.0,4.0,29.0],[59.0,8.5,38.0]]:
        var x: float=record[0]
        var width: float=record[1]
        var top: float=record[2]
        box("SetbackTower",Vector3(x,(18.0+top)*0.5,24),Vector3(width,top-18.0,1.5),1)
        box("TowerCrown",Vector3(x,top+1.5,24),Vector3(width*0.76,3,1.3),1)
        for y in range(3,int(top),4):
            # Recesses are darker than jambs. Selected warm windows, not neon walls.
            trim(Vector3(x,y+1.3,24.91),Vector3(width+0.38,0.26,0.40),0)
            var columns: int=4 if width>5 else 2
            for col in range(columns):
                var local_x: float=(float(col)-float(columns-1)*0.5)*1.45
                trim(Vector3(x+local_x,y+0.1,24.82),Vector3(0.95,1.70,0.13),1)
                if (y+col+int(x))%4 != 0:
                    trim(Vector3(x+local_x,y+0.1,24.93),Vector3(0.52,1.32,0.04),3)
                trim(Vector3(x+local_x-0.57,y+0.1,25.04),Vector3(0.16,2.0,0.23),0)
        for side in [-1.0,1.0]:
            trim(Vector3(x+side*(width*0.5-0.18),top*0.5,25),Vector3(0.42,top,0.40),0)
        trim(Vector3(x,top,24.9),Vector3(width+0.9,0.6,0.85),0)
    # Warm frontage lamps contrast with neutral/cool fill; no crowd light spam.
    for x in [36.0,53.0]:
        lamp(Vector3(x,4.3,24.8))
        trim(Vector3(x,5.0,25.4),Vector3(1.1,0.22,1.0),0)
    sign_label("INDEX // MARKET ARCHIVES",Vector3(44,16.2,25.15),43,0)
    commit_trim()

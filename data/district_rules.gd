extends RefCounted

# Numeric IDs deliberately match EnemyType (grunt/skitter/gunner/bomber/tank).
# No new enemy classes: location alters composition and optional event waves.
const RULES: Dictionary = {
    &"market_ruins":{"title":"MARKET RUINS","event":"RECLAIM THE LEDGER","terminal":Vector3(46,0.03,42),"radius":29.0,"reward":45,"weights":[42,25,25,8,0],"waves":[[0,1],[0,2,1]],"message":"THE STALLS REMEMBER THEIR OWNERS."},
    &"signal_concourse":{"title":"TRANSIT SPINE","event":"RESTORE PLATFORM SIGNAL","terminal":Vector3(4,5.53,64),"radius":32.0,"reward":55,"weights":[22,12,48,0,18],"waves":[[2,0],[2,0,4]],"message":"NEXT DEPARTURE / DESTINATION UNKNOWN."},
    &"archive_row":{"title":"ARCHIVE STACKS","event":"RECOVER THE MISSING INDEX","terminal":Vector3(53,0.03,-5),"radius":40.0,"reward":50,"weights":[44,24,32,0,0],"waves":[[0,2],[1,0,2]],"message":"RECORD 2800 / PHYSICAL MEDIA: UNVERIFIED."},
    &"memory_gardens":{"title":"MEMORY GARDENS","event":"RESTART THE CLIMATE CYCLE","terminal":Vector3(-43,0.03,26),"radius":37.0,"reward":50,"weights":[20,52,16,12,0],"waves":[[1,1],[1,2,1]],"message":"SUNLIGHT WAS ONCE MORE THAN A VALUE."},
    &"utility_spine":{"title":"UTILITY DEPTHS","event":"PURGE PRESSURE LOCK","terminal":Vector3(-49,-5.97,-38),"radius":42.0,"reward":60,"weights":[52,28,20,0,0],"waves":[[0,1],[0,2,0]],"message":"MAINTENANCE LOG / SOMEONE WAS HERE."},
    &"null_terminal":{"title":"ROOFTOP RELAY","event":"CALIBRATE THE LOST CARRIER","terminal":Vector3(8,10.03,-77),"radius":55.0,"reward":65,"weights":[18,22,60,0,0],"waves":[[2,1],[2,2,0]],"message":"CARRIER FOUND / NOT PART OF THE INDEX."}
}

static func select_enemy(district: StringName, zone: StringName, elapsed: float, rng: RandomNumberGenerator) -> int:
    var data: Dictionary = RULES.get(district,{})
    var weights: Array = (data.get("weights",[45,25,30,0,0]) as Array).duplicate()
    # Early encounters are still gentle even when entering a distant district.
    if elapsed < 18.0:
        weights[2] = 0
    if elapsed < 48.0:
        weights[3] = 0
    if elapsed < 80.0:
        weights[4] = 0
    if String(zone).contains("gallery") or String(zone).contains("roof"):
        weights[3] = 0
        weights[4] = 0
    var total: float = 0.0
    for weight in weights: total += float(weight)
    var value: float = rng.randf()*maxf(total,1.0)
    for i in range(weights.size()):
        value -= float(weights[i])
        if value < 0.0: return i
    return 0

static func get_spec(id: StringName) -> Dictionary:
    return (RULES.get(id,{}) as Dictionary).duplicate(true)

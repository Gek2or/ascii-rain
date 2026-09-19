class_name WeaponController
extends Node

signal weapon_changed(index: int, data: WeaponData)

const PULSE_DATA: Resource = preload("res://data/weapons/pulse_rifle.tres")
const SCATTER_DATA: Resource = preload("res://data/weapons/scatter_cannon.tres")
const ARC_DATA: Resource = preload("res://data/weapons/arc_carbine.tres")

var current_index: int = 0
var _weapons: Array[WeaponData] = []

func _ready() -> void:
    _weapons.clear()
    _weapons.append(PULSE_DATA as WeaponData)
    _weapons.append(SCATTER_DATA as WeaponData)
    _weapons.append(ARC_DATA as WeaponData)

func count() -> int:
    return _weapons.size()

func current() -> WeaponData:
    if _weapons.is_empty():
        return null
    return _weapons[clampi(current_index, 0, _weapons.size() - 1)]

func select(index: int) -> bool:
    if _weapons.is_empty():
        return false
    var clamped_index: int = clampi(index, 0, _weapons.size() - 1)
    if clamped_index == current_index:
        return false
    current_index = clamped_index
    weapon_changed.emit(current_index, current())
    return true

func cycle() -> bool:
    if _weapons.is_empty():
        return false
    return select((current_index + 1) % _weapons.size())

func force_emit() -> void:
    if not _weapons.is_empty():
        weapon_changed.emit(current_index, current())

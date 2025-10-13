# res://weapons/Weapon.gd
extends Node2D
class_name Weapon

@export var weapon_name: String = "Unnamed Weapon"
@export var fire_rate: float = 0.2
@export var projectile_scene: PackedScene
@export var projectile_speed: float = 800.0
@export var damage: int = 10
@export var ammo: int = 10
@export var max_ammo: int = 10

var _can_fire := true

func can_fire() -> bool:
	return _can_fire and ammo > 0

func fire(_player: Node2D) -> void:
	# Implemented by child classes (Gun, Bow, etc.)
	pass

func reload() -> void:
	ammo = max_ammo

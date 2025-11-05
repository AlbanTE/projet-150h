# res://weapons/Weapon.gd
extends Node2D
class_name Weapon

@export var weapon_name: String = "Unnamed Weapon"
@export var fire_rate: float = 0.2
@export var projectile_scene: PackedScene
@export var projectile_speed: float = 800.0
@export var damage: int = 10
@export var projectile_count: int = 1

var _can_fire := true

func can_fire() -> bool:
	return _can_fire

func spawn_projectile(_player: Node2D) -> void:
	pass

func fire(player: Node2D) -> void:
	if not can_fire():
		return
	
	_can_fire = false
	
	for i in projectile_count + PlayerStats.additional_projectiles:
		spawn_projectile(player)
		await get_tree().create_timer(0.05).timeout
	
	await get_tree().create_timer(fire_rate / PlayerStats.attack_speed).timeout
	_can_fire = true

# res://weapons/Weapon.gd
extends Node2D
class_name Weapon

@export var weapon_name: String = "Unnamed Weapon"
@export var projectile_scene: PackedScene
@export var projectile_count: int = 1
@export var cooldown: float = 0.2


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
	
	await get_tree().create_timer(cooldown / PlayerStats.attack_speed).timeout
	_can_fire = true

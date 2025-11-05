# res://player/WeaponComponent.gd
extends Node2D
class_name WeaponComponent

@export var starting_weapon_scene: PackedScene
@export var weapon_scenes: Array[PackedScene] = []
var current_weapon: Weapon
var current_weapon_index: int = 0
var weapon_scale: float = 1

func _ready():
	# Initialize weapon array with starting weapon if available
	if starting_weapon_scene and starting_weapon_scene not in weapon_scenes:
		weapon_scenes.insert(0, starting_weapon_scene)
	
	if weapon_scenes.size() > 0:
		call_deferred("equip_weapon", weapon_scenes[current_weapon_index])

func equip_weapon(weapon_scene: PackedScene):
	if current_weapon:
		current_weapon.queue_free()

	current_weapon = weapon_scene.instantiate()
	weapon_scale = current_weapon.scale.y
	get_parent().add_child(current_weapon)
	

func switch_to_next_weapon():
	if weapon_scenes.size() <= 1:
		print("Only one weapon available")
		return
		
	current_weapon_index = (current_weapon_index + 1) % weapon_scenes.size()
	equip_weapon(weapon_scenes[current_weapon_index])

func add_weapon(weapon_scene: PackedScene):
	if weapon_scene not in weapon_scenes:
		weapon_scenes.append(weapon_scene)
		print("Added new weapon to inventory")

func get_current_weapon_name() -> String:
	if current_weapon and "weapon_name" in current_weapon:
		return current_weapon.weapon_name
	return "Unknown Weapon"

func handle_input(event):
	if not current_weapon:
		return
	if event.is_action_pressed("trigger_weapon"):
		current_weapon.fire(get_parent())
		
	elif event.is_action_pressed("switch_weapon"):
		switch_to_next_weapon()
		
func _process(_delta):
	if current_weapon:
		aim_weapon_toward_cursor()

func aim_weapon_toward_cursor():
	if not current_weapon:
		return

	var mouse_pos = get_global_mouse_position()
	var direction = (mouse_pos - current_weapon.global_position).normalized()
	current_weapon.rotation = direction.angle()

	if abs(rad_to_deg(current_weapon.rotation)) > 90:
		current_weapon.scale.y = -weapon_scale
	else:
		current_weapon.scale.y = weapon_scale

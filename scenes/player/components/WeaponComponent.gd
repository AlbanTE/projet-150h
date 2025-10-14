# res://player/WeaponComponent.gd
extends Node2D
class_name WeaponComponent

@export var starting_weapon_scene: PackedScene
var current_weapon: Node2D
var weapon_scale: float = 1

func _ready():
	if starting_weapon_scene:
		call_deferred("equip_weapon", starting_weapon_scene)

func equip_weapon(weapon_scene: PackedScene):
	if current_weapon:
		current_weapon.queue_free()

	current_weapon = weapon_scene.instantiate()
	weapon_scale = current_weapon.scale.y
	get_parent().add_child(current_weapon)

func handle_input(event):
	if not current_weapon:
		return
	if event.is_action_pressed("trigger_weapon"):
		# print("Shooting !")
		current_weapon.fire(get_parent())
	#if event.is_action_pressed("reload"):
		#current_weapon.reload()
		
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

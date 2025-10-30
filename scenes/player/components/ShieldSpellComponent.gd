extends Node
class_name ShieldSpellComponent

@export var shield_material: ShaderMaterial  
var is_active: bool = false
var sprite: AnimatedSprite2D
var original_material: Material

func _ready() -> void:
	var parent = get_parent()
	sprite = parent.get_node_or_null("AnimatedSprite2D")
	if not sprite:
		return
	original_material = sprite.material
	if not shield_material:
		shield_material = load("res://materials/shield_material.tres")

func handle_input(event: InputEvent) -> void:
	if not sprite:
		return
	
	if event is InputEventKey and event.pressed and event.keycode == KEY_E:
		toggle_shield()

func toggle_shield() -> void:
	is_active = !is_active
	
	if is_active:
		activate_shield()
	else:
		deactivate_shield()

func activate_shield() -> void:
	if sprite and shield_material:
		sprite.material = shield_material

func deactivate_shield() -> void:
	if sprite:
		sprite.material = original_material

func is_shield_active() -> bool:
	return is_active

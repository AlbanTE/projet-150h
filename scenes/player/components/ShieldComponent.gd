extends Node2D
class_name ShieldComponent

@onready var shield_visual: ColorRect = $Shield

var is_active := false:
	set(value):
		is_active = value
		if shield_visual:
			shield_visual.visible = value

func _ready() -> void:
	if shield_visual:
		shield_visual.visible = false

func handle_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_E:
				is_active = !is_active

func set_active(active: bool) -> void:
	is_active = active

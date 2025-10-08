extends ColorRect
class_name Shield

@export var shield_radius: float = 40.0
@export var shield_inner_radius: float = 0.1
@export var shield_outer_radius: float = 0.25

@export var shield_color: Color = Color.DARK_ORCHID
@export var shield_opacity: float = 0.3
@export var shield_step: float = 0.7

@export var animation_speed: Vector3 = Vector3(0, -0.1, 0)
@export var is_active: bool = false

func _ready():
	# Apply initial settings
	update_all_properties()

func _input(event):
	# Handle shield controls
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_E:
				# Toggle shield activation
				if is_active:
					deactivate_shield()
				else:
					activate_shield()

# Apply all properties at once
func update_all_properties():
	# Set physical size
	offset_left = -shield_radius
	offset_top = -shield_radius
	offset_right = shield_radius
	offset_bottom = shield_radius
	
	# Set shader parameters
	if material:
		material.set_shader_parameter("Size_Inner", shield_inner_radius)
		material.set_shader_parameter("Size_Outer", shield_outer_radius)
		material.set_shader_parameter("Color_Shield", shield_color)
		material.set_shader_parameter("Opaticy", shield_opacity)
		material.set_shader_parameter("Step", shield_step)
		material.set_shader_parameter("Speed", animation_speed)
	
	# Set visibility
	visible = is_active

# Public methods for external control
func activate_shield():
	is_active = true
	visible = true

func deactivate_shield():
	is_active = false
	visible = false

# Helper function for tween animation
func _set_radius_for_tween(radius: float):
	offset_left = -radius
	offset_top = -radius
	offset_right = radius
	offset_bottom = radius

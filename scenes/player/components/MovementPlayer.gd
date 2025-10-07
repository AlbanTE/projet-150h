extends Node
class_name MovementComponent

# Movement variables
@export var vitesse: float = 250.0
@export var acceleration: float = 70.0

# Input directions
var vect_direction: Vector2 = Vector2.ZERO

func _ready():
	pass

func handle_input():
	vect_direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	if Input.is_action_just_released("trigger_weapon"):
		print("Shooting !")

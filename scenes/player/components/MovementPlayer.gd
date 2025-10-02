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

	vect_direction = Vector2.ZERO
	
	if Input.is_action_pressed("move_right"):
		vect_direction.x += 1
	if Input.is_action_pressed("move_left"):
		vect_direction.x -= 1
	
	if Input.is_action_pressed("move_down"):
		vect_direction.y += 1
	if Input.is_action_pressed("move_up"):
		vect_direction.y -= 1

	# Normalize diagonal movement 
	if vect_direction.length() > 0:
		vect_direction = vect_direction.normalized()

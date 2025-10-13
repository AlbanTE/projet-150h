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

func update_movement(player: CharacterBody2D, _delta):
	handle_input()
	player.velocity = player.velocity.move_toward(vect_direction * vitesse, acceleration)
	player.move_and_slide()

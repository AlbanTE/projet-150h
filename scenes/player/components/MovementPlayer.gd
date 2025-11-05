extends Node
class_name MovementComponent

# Input directions
var vect_direction: Vector2 = Vector2.ZERO

func _ready():
	pass

func handle_input():
	vect_direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")

func update_movement(player: CharacterBody2D, _delta):
	handle_input()
	player.velocity = player.velocity.move_toward(vect_direction * PlayerStats.vitesse, PlayerStats.acceleration)
	player.move_and_slide()

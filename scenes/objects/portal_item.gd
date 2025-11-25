extends CharacterBody2D


var player: Player = null
var following: bool = false


var pickup_kill_range: int = 30
var pickup_speed: int = 200

func pickup() -> void:
	var dist = self.global_position.distance_to(player.global_position)
	
	if (dist > pickup_kill_range):
		velocity = (player.global_position - global_position).normalized() * pickup_speed
	else:
		apply_effects()

func apply_effects() -> void:
	var mod = PlayerStats.add_modifier_to(
		PlayerStats.damage_multiplier,
		Stat.OperationTypes.ADD,
		10,
		self
	)
	var mod2 = PlayerStats.add_modifier_to(
		PlayerStats.damage_multiplier,
		Stat.OperationTypes.MULT,
		0.25,
		self
	)
	queue_free()

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is Player:
		player = body
		following = true

func _process(_delta: float) -> void:
	if following:
		pickup()
		move_and_slide()

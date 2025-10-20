extends Enemy
class_name EnemyType1

# ────────────────
# Visuals
# ────────────────
@onready var anim_player: AnimationPlayer = $Visual/FlashEffectAnim
@onready var blood_particles: AnimatedSprite2D = $Visual/BloodSprite


func _apply_damage_effects(_amount: int) -> void:
	print("Supposed to play hit effect")
	if anim_player and anim_player.has_animation("hit"):
		anim_player.play("hit")
		
	blood_particles.show()
	blood_particles.play()
	get_tree().create_timer(1).timeout.connect(func(): 
		blood_particles.stop()
		blood_particles.hide()
	)
	

func _apply_death_effects() -> void:
	print("Slime mort — trucs a faire.")


func attack() -> void:
	print(" Slime attacks !")
	player.take_damage(10)
	super()

func aim_slime_towards_player():
	var player_pos = player.global_position
	var direction = (player_pos - global_position).normalized()

	if abs(rad_to_deg(direction.angle())) > 90:
		$Visual/AnimatedSprite2D.flip_h = true
	else:
		$Visual/AnimatedSprite2D.flip_h = false

func _process(_delta: float):
	aim_slime_towards_player()
	super(_delta)

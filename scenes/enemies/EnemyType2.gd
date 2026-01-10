extends Enemy
class_name EnemyType2

# ────────────────
# Visuals
# ────────────────
@onready var anim_player: AnimationPlayer = $Visual/FlashEffectAnim
@onready var blood_particles: AnimatedSprite2D = $Visual/BloodSprite

func _ready() -> void:
	$HealthBar.max_value = health_component.max_health
	$HealthBar/Label.text = str(health_component.current_health) + " / " + str(health_component.max_health)
	super()

func _on_health_changed(prev_health: int, current_health: int, max_health: int) -> void:
	$HealthBar.value = current_health
	$HealthBar.max_value = health_component.max_health
	$HealthBar/Label.text = str(current_health) + " / " + str(max_health)
	super(prev_health, current_health, max_health)

func _apply_damage_effects(_amount: int) -> void:
	#print("Supposed to play hit effect")
	if anim_player and anim_player.has_animation("hit"):
		anim_player.play("hit")
		
	blood_particles.show()
	blood_particles.play()
	get_tree().create_timer(1).timeout.connect(func(): 
		blood_particles.stop()
		blood_particles.hide()
	)
	

func _apply_death_effects() -> void:
	#print("Slime mort — trucs a faire.")
	super()


func attack() -> void:
	player.take_damage(damage)
	super()
	
func follow_player(player_position: Vector2, _delta: float) -> float:
	var distance_to_player = super(player_position, _delta)
	
	if distance_to_player > 4 * $AttackArea/CollisionShape2D.shape.radius:
		_play_move_animation()
	else:
		_play_attack_animation()
		
	return distance_to_player

func aim_slime_towards_player():
	var player_pos = player.global_position
	var direction = (player_pos - global_position).normalized()

	if abs(rad_to_deg(direction.angle())) > 90:
		$Visual/AnimatedSprite2D.flip_h = true
	else:
		$Visual/AnimatedSprite2D.flip_h = false

func _process(_delta: float):
	if not activated:
		return
	aim_slime_towards_player()
	super(_delta)


func _on_visible_on_screen_enabler_2d_screen_entered() -> void:
	activated = true

extends CharacterBody2D

enum State { IDLE, MELEE, LASER_BEAM, MOVING, TELEPORTING, ENTRANCE }
var state_label: Array[String] = ["IDLE", "MELEE", "LASER", "MOVING", "TELEPORTING", "ENTRANCE"]

# ────────────────
# Components
# ────────────────
@onready var health_component: HealthComponent = $HealthComponent
@onready var hurtbox_component: HurtboxComponent = $HurtboxComponent

@onready var animated_sprite := $AnimatedSprite2D
@onready var animation_player := $AnimationPlayer
@onready var left_arm_collision := $LeftArmCollision
@onready var right_arm_collision := $RightArmCollision
@onready var body_collision := $BodyCollision
@onready var visible_notifier := $VisibleOnScreenEnabler2D

# Combat variables
var player: Node2D = null
var camera: Camera2D = null

var activated := false
var current_state = State.IDLE
var is_flipped := false
var can_deal_damage := true
var is_alive: bool = true
var should_teleport_after_melee := true

# Configuration
var attack_range := 100.0
var teleport_range := 300.0
var move_speed := 300
var melee_damage := 50
var melee_cooldown := 1.0
var laser_cooldown := 2.0
var cooldown_timer := 0.0

# Phase management
var attack_cycles_completed := 0
var cycles_before_pause := 3
var is_in_pause := false
var pause_timer := 0.0

# Screen shake
var shake_strength := 0.0
var shake_duration := 0.0

@onready var laser: PackedScene = preload("res://scenes/enemies/lightning.tscn")

func _ready():
	_setup_connections()
	_setup_collisions()
	_find_player_and_camera()
	_configure_boss()

func _setup_connections():
	animation_player.animation_finished.connect(_on_animation_finished)
	
	if health_component:
		health_component.health_changed.connect(_on_health_changed)
		health_component.health_depleted.connect(_on_health_depleted)
	
	if hurtbox_component:
		hurtbox_component.hit_by_bullet.connect(_on_hit_by_bullet)

func _setup_collisions():
	if left_arm_collision is Area2D:
		left_arm_collision.body_entered.connect(_on_left_arm_hit)
	if right_arm_collision is Area2D:
		right_arm_collision.body_entered.connect(_on_right_arm_hit)

func _find_player_and_camera():
	player = get_tree().get_first_node_in_group("player")
	if player:
		camera = player.get_node("Camera2D")

func _configure_boss():
	if visible_notifier:
		visible_notifier.enable_mode = VisibleOnScreenEnabler2D.ENABLE_MODE_ALWAYS
	
	print("Boss health: ", health_component.max_health)

func _process(delta):
	if not activated:
		return
	
	_handle_screen_shake(delta)
	
	if player:
		update_flip_direction()
	
	# Gestion du cooldown
	if cooldown_timer > 0:
		cooldown_timer -= delta
	
	# Gestion de la pause
	if is_in_pause:
		pause_timer -= delta
		if pause_timer <= 0:
			is_in_pause = false
			attack_cycles_completed = 0
			cycles_before_pause = randi_range(3, 5)  # Prochaine pause dans 3-5 cycles
		return
	
	# Logique d'état
	match current_state:
		State.IDLE:
			idle_behavior(delta)
		State.MOVING:
			pass  # Le tween gère le mouvement
		State.MELEE, State.LASER_BEAM, State.TELEPORTING, State.ENTRANCE:
			pass  # Animations en cours

func _handle_screen_shake(delta):
	if shake_duration > 0 and camera:
		shake_duration -= delta
		
		camera.offset = Vector2(
			randf_range(-shake_strength, shake_strength),
			randf_range(-shake_strength, shake_strength)
		)
		
		if shake_duration <= 0:
			camera.offset = Vector2.ZERO

func screen_shake(strength: float = 10.0, duration: float = 5.0):
	shake_strength = strength
	shake_duration = duration

func idle_behavior(_delta):
	if not player or cooldown_timer > 0:
		return
	
	# Après un certain nombre de cycles, on fait une pause
	if attack_cycles_completed >= cycles_before_pause:
		start_pause()
		return
	
	# Deux comportements possibles en idle
	if randf() < 0.5:  # 50% de chance pour chaque
		# Comportement 1 : TP proche -> attaque mélée -> TP loin
		perform_melee_cycle()
	else:
		# Comportement 2 : TP loin -> attaque laser
		perform_laser_cycle()
	
	attack_cycles_completed += 1

func start_pause():
	is_in_pause = true
	pause_timer = 1.0  # Pause de 1 seconde
	print("Boss en pause pour ", pause_timer, " secondes")

func perform_melee_cycle():
	# Téléportation proche
	teleport_closer_to_player()
	await get_tree().create_timer(0.6).timeout  # Attend la fin de la téléportation
	
	# Attaque mélée
	change_state(State.MELEE)
	enable_damage()
	cooldown_timer = melee_cooldown
	
	# Attendre la fin de l'attaque mélée
	await get_tree().create_timer(0.8).timeout
	
	# Téléportation loin
	perform_teleport()

func perform_laser_cycle():
	# Téléportation loin
	perform_teleport()
	await get_tree().create_timer(0.6).timeout  # Attend la fin de la téléportation
	
	# Attaque laser
	perform_laser_attack()

func change_state(new_state: State):
	if current_state == State.MELEE and new_state != State.MELEE:
		disable_damage()
	
	current_state = new_state
	
	if has_node("Label"):
		$Label.text = state_label[new_state] + "\n" + str(health_component.current_health) + " / " + str(health_component.max_health)
	
	animation_player.play("RESET")
	await animation_player.animation_finished
	
	match new_state:
		State.IDLE:
			animated_sprite.play("idle")
		State.MELEE:
			animation_player.play("melee")
		State.LASER_BEAM:
			animation_player.play("laser_beam")
		State.MOVING:
			animated_sprite.play("idle")
		State.TELEPORTING:
			animation_player.play("teleport")
		State.ENTRANCE:
			animation_player.play("entrance")

func spawn_laser_at_relative(position: Vector2):
	var laser_inst: Lightning = laser.instantiate()
	add_child(laser_inst)
	laser_inst.damageable = false
	laser_inst.global_position = global_position + position * 5

func perform_laser_attack():
	change_state(State.LASER_BEAM)
	cooldown_timer = laser_cooldown
	
	for i in 3:
		var laser_inst: Lightning = laser.instantiate()
		add_child(laser_inst)
		
		var random_offset: Vector2 = 64 * Vector2(2 * randf() - 1, 2 * randf() - 1)
		laser_inst.global_position = player.global_position - Vector2(0, 32) + random_offset
		
		await get_tree().create_timer(0.2).timeout

func perform_teleport():
	if not player:
		change_state(State.IDLE)
		return
	
	change_state(State.TELEPORTING)
	
	# Calcule une position aléatoire autour du joueur
	var angle = randf() * TAU
	var distance = randf_range(teleport_range * 0.8, teleport_range * 1.2)
	var offset = Vector2(cos(angle), sin(angle)) * distance
	var target_pos = player.global_position + offset
	
	await get_tree().create_timer(0.5).timeout
	global_position = target_pos

func teleport_closer_to_player():
	if not player:
		return
	
	change_state(State.TELEPORTING)
	
	# Calcule une position proche du joueur
	var angle = randf() * TAU
	var distance = randf_range(attack_range * 0.7, attack_range * 1.2)
	var offset = Vector2(cos(angle), sin(angle)) * distance
	var target_pos = player.global_position + offset
	
	await get_tree().create_timer(0.5).timeout
	global_position = target_pos

func update_flip_direction():
	if not player or current_state == State.TELEPORTING:
		return
	
	var direction = (player.global_position - global_position).normalized()
	flip_boss(abs(rad_to_deg(direction.angle())) <= 90)

func flip_boss(flip: bool):
	is_flipped = flip
	scale.x = -3 if flip else 3
	if has_node("Label"):
		$Label.scale.x = -1 if flip else 1

func _on_animation_finished(anim_name: String):
	match anim_name:
		"teleport":
			change_state(State.IDLE)
		"melee":
			# Pour le cycle mélée, on retourne à l'IDLE (le TP loin est géré dans perform_melee_cycle)
			change_state(State.IDLE)
		"laser_beam":
			change_state(State.IDLE)
		"entrance":
			if player and player.has_method("enable_input"):
				player.enable_input()
			cooldown_timer = 1
			change_state(State.IDLE)
			# Initialiser le compteur de cycles
			attack_cycles_completed = 0
			cycles_before_pause = randi_range(3, 5)

# Fonctions d'animation
func play_sprite_animation(anim_name: String):
	animated_sprite.play(anim_name)

func stop_sprite_animation():
	animated_sprite.stop()

# Gestion des collisions
func _on_left_arm_hit(body):
	print("Arm hit")
	if body is Player and can_deal_damage and current_state == State.MELEE:
		deal_damage_to_player(body)

func _on_right_arm_hit(body):
	if body is Player and can_deal_damage and current_state == State.MELEE:
		deal_damage_to_player(body)

func deal_damage_to_player(body):
	if body.has_method("take_damage"):
		body.take_damage(melee_damage)
		can_deal_damage = false

# Gestion des dégâts
func enable_damage():
	can_deal_damage = true

func disable_damage():
	can_deal_damage = false

func activate():
	activated = true
	$VisibleOnScreenEnabler2D.queue_free()
	play_entrance()

func play_entrance():
	if player and player.has_method("disable_input"):
		player.disable_input()
	
	change_state(State.ENTRANCE)

# ────────────────
# Callbacks
# ────────────────
func _apply_damage_effects(_amount: int) -> void:
	pass

func _apply_death_effects() -> void:
	pass

func _on_hit_by_bullet(_bullet: Node2D, bullet_damage: int, bullet_knockback: float) -> void:
	if not is_alive:
		return
	_apply_damage_effects(bullet_damage)

func _on_health_changed(prev_health: int, current_health: int, _max_health: int) -> void:
	if current_health > prev_health:
		pass  # Play heal effect
	elif current_health == prev_health:
		pass  # Play block effect
	else:
		_apply_damage_effects(current_health)

func _on_health_depleted() -> void:
	print("Enemy: Die signal received")
	die()

func die() -> void:
	is_alive = false
	velocity = Vector2.ZERO
	_apply_death_effects()
	queue_free()

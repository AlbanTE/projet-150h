extends CharacterBody2D

enum State { IDLE, MELEE, LASER_BEAM, MOVING, TELEPORTING, ENTRANCE }
var stateLabel: Array[String] = ["IDLE", "MELEE", "LASER", "MOVING", "TELEPORTING", "ENTRANCE"]

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
@onready var player: Node2D = null  # Référence au joueur

var activated := false
var current_state = State.IDLE
var is_flipped := false
var attack_range := 100.0  # Distance pour attaque melee
var teleport_range := 300.0  # Distance de téléportation
var move_speed := 300
var melee_cooldown := 1.0
var melee_damage := 50
var laser_cooldown := 2.0
var cooldown_timer := 0.0
var can_deal_damage := true  # Pour éviter les dégâts multiples
var should_teleport_after_melee := true  # Active la téléportation après melee
var is_alive: bool = true

@onready var laser: PackedScene = preload("res://scenes/enemies/lightning.tscn")

# Screen shake
var shake_strength := 0.0
var shake_duration := 0.0

@onready var camera: Camera2D = null

func _ready():
	animation_player.animation_finished.connect(_on_animation_finished)
	#animated_sprite.animation_finished.connect(_on_sprite_animation_finished)
	
	# Configure le VisibleOnScreenEnabler2D pour qu'il ne désactive jamais le boss
	if visible_notifier:
		visible_notifier.enable_mode = VisibleOnScreenEnabler2D.ENABLE_MODE_ALWAYS
	
	# Configure les collisions des bras
	if left_arm_collision is Area2D:
		left_arm_collision.body_entered.connect(_on_left_arm_hit)
	if right_arm_collision is Area2D:
		right_arm_collision.body_entered.connect(_on_right_arm_hit)
	
	# Trouve le joueur dans la scène
	player = get_tree().get_first_node_in_group("player")
	
	camera = player.get_node("Camera2D")
	
	print("Boss health: ", health_component.max_health)
	
	if health_component:
		health_component.health_changed.connect(_on_health_changed)
		health_component.health_depleted.connect(_on_health_depleted)

	if hurtbox_component:
		hurtbox_component.hit_by_bullet.connect(_on_hit_by_bullet)

func _process(delta):
	if not activated:
		return
		
	# Applique le screen shake si actif
	if shake_duration > 0 and camera:
		shake_duration -= delta
		
		camera.offset = Vector2(
			randf_range(-shake_strength, shake_strength),
			randf_range(-shake_strength, shake_strength)
		)
		
		# Réinitialise l'offset quand le shake est terminé
		if shake_duration <= 0:
			camera.offset = Vector2.ZERO
		
	if player:
		update_flip_direction()
	
	# Gestion du cooldown
	if cooldown_timer > 0:
		cooldown_timer -= delta
	
	# Logique d'état
	match current_state:
		State.IDLE:
			idle_behavior(delta)
		State.MOVING:
			pass  # Le tween gère le mouvement
		State.MELEE, State.LASER_BEAM, State.TELEPORTING, State.ENTRANCE:
			pass  # Animations en cours

func screen_shake(strength: float = 10.0, duration: float = 5.0):
	shake_strength = strength
	shake_duration = duration

func idle_behavior(_delta):
	if not player or cooldown_timer > 0:
		return
	
	var distance = global_position.distance_to(player.global_position)
	
	# Décide quelle attaque utiliser
	if distance <= attack_range:
		perform_melee_attack()
	else:
		# 66% chance entre se déplacer vers le joueur ou laser
		if randf() < 0.66:
			move_or_teleport()
		else:
			perform_laser_attack()

func change_state(new_state: State):
	if current_state == State.MELEE and new_state != State.MELEE:
		disable_damage()
	current_state = new_state
	
	if has_node("Label"):
		$Label.text = stateLabel[new_state] + "\n" + str(health_component.current_health) + " / " + str(health_component.max_health)
	
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
			animated_sprite.play("idle")  # Utilise idle pendant les déplacements
		State.TELEPORTING:
			animation_player.play("teleport")
		State.ENTRANCE:
			animation_player.play("entrance")  # Ou une animation d'entrée spécifique

func perform_melee_attack():
	change_state(State.MELEE)
	enable_damage()
	cooldown_timer = melee_cooldown

func spawn_laser_at_relative(position: Vector2):
	var laser_inst: Lightning = laser.instantiate()
	add_child(laser_inst)
	laser_inst.damageable = false
	laser_inst.global_position = global_position + position * 5

func perform_laser_attack():
	change_state(State.LASER_BEAM)
	cooldown_timer = laser_cooldown
	
	var laser_inst: Lightning = laser.instantiate()
	add_child(laser_inst)
	laser_inst.global_position = player.global_position - Vector2(0, 32)

func perform_teleport():
	if not player:
		change_state(State.IDLE)
		return
	
	change_state(State.TELEPORTING)
	
	# Calcule une position aléatoire autour du joueur
	var angle = randf() * TAU  # Angle aléatoire en radians
	var distance = randf_range(teleport_range * 0.8, teleport_range * 1.2)
	var offset = Vector2(cos(angle), sin(angle)) * distance
	var target_pos = player.global_position + offset
	
	# Attend la moitié de l'animation de téléportation pour changer de position
	await get_tree().create_timer(0.5).timeout
	global_position = target_pos

func teleport_closer_to_player():
	if not player:
		return
	
	change_state(State.TELEPORTING)
	
	# Calcule une position proche du joueur (à portée d'attaque)
	var angle = randf() * TAU
	var distance = randf_range(attack_range * 0.7, attack_range * 1.2)
	var offset = Vector2(cos(angle), sin(angle)) * distance
	var target_pos = player.global_position + offset
	
	# Attend la moitié de l'animation de téléportation pour changer de position
	await get_tree().create_timer(0.5).timeout
	global_position = target_pos

func move_or_teleport():
	# 50% chance de se déplacer normalement ou de se téléporter
	if randf() < 0.5:
		move_to_player()
	else:
		teleport_closer_to_player()

func move_to_player():
	if not player:
		return
	
	change_state(State.MOVING)
	
	# Calcule la position cible à côté du joueur
	var direction = (global_position - player.global_position).normalized()
	var target_pos = player.global_position + direction * attack_range * 0.8
	
	# Calcule la durée basée sur la distance
	var distance = global_position.distance_to(target_pos)
	var duration = distance / move_speed
	
	# Crée le tween
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "global_position", target_pos, duration)
	tween.finished.connect(_on_move_finished)

func _on_move_finished():
	# Après le déplacement, attaque ou retourne en idle
	if player and global_position.distance_to(player.global_position) <= attack_range:
		change_state(State.MELEE)
	else:
		change_state(State.IDLE)

func update_flip_direction():
	if not player or current_state == State.TELEPORTING:
		return
	
	var player_pos = player.global_position
	var direction = (player_pos - global_position).normalized()

	if abs(rad_to_deg(direction.angle())) > 90:
		flip_boss(false)
	else:
		flip_boss(true)

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
			# Vérifie si le joueur est toujours à portée
			var distance = global_position.distance_to(player.global_position)
			if distance <= attack_range:
				# Continue en mêlée
				perform_melee_attack()
			else:
				# Se téléporte loin
				perform_teleport()
		"laser_beam":
			move_or_teleport()
		"entrance":
			if player and player.has_method("enable_input"):
				player.enable_input()
			cooldown_timer = 1
			change_state(State.IDLE)
		"RESET":
			pass

# Fonctions appelées par l'AnimationPlayer
func play_sprite_animation(anim_name: String):
	animated_sprite.play(anim_name)

func stop_sprite_animation():
	animated_sprite.stop()

# Gestion des collisions des bras
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
		can_deal_damage = false  # Évite les dégâts multiples

# Appelé depuis l'AnimationPlayer au début de l'attaque
func enable_damage():
	can_deal_damage = true

# Appelé depuis l'AnimationPlayer à la fin de l'attaque
func disable_damage():
	can_deal_damage = false

func activate():
	activated = true
	$VisibleOnScreenEnabler2D.queue_free()
	play_entrance()

func play_entrance():
	# Bloque les inputs du joueur
	if player and player.has_method("disable_input"):
		player.disable_input()
	
	# Lance l'animation d'entrée
	change_state(State.ENTRANCE)
	
# ────────────────
# Hurtbox callback
# ────────────────
func _apply_damage_effects(_amount: int) -> void:
	pass

func _apply_death_effects() -> void:
	pass

func _on_hit_by_bullet(_bullet: Node2D, bullet_damage: int, bullet_knockback: float) -> void:
	if not is_alive:
		return
	#print("Enemy: Hit by bullet signal received")
	_apply_damage_effects(bullet_damage)


# ────────────────
# Health callback
# ────────────────
func _on_health_changed(prev_health: int, current_health: int, _max_health: int) -> void:
	#print("Enemy: health changed signal received")
	if (current_health > prev_health):
		# Play heal effect
		pass
	elif (current_health == prev_health):
		# Play block effect or something...
		pass
	else:
		_apply_damage_effects(current_health)
	

func _on_health_depleted() -> void:
	print("Enemy: Die signal received")
	die()

func die() -> void:
	is_alive = false
	#is_following = false
	velocity = Vector2.ZERO
	_apply_death_effects()
	queue_free()

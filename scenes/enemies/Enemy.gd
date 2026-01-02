extends CharacterBody2D
class_name Enemy

# ────────────────
# Components
# ────────────────
@onready var health_component: HealthComponent = $HealthComponent
@onready var hurtbox_component: HurtboxComponent = $HurtboxComponent

# ────────────────
# ⚙️ Enemy Stats
# ────────────────
@export_group("Stats")
@export var speed: float = 80.0
@export var damage: int = 20
@export var attack_cooldown: float = 0.75
var can_attack: bool = false

@export_group("AI Behavior")
@export var path_update_interval: float = 0.2

@export_group("Debug")
@export var debug_navigation: bool = false
@export var debug_attack: bool = false

# ────────────────
# 🧠 State
# ────────────────
var player: Player = null
var is_alive: bool = true
# var is_following: bool = false
var path_update_timer: float = 0.0

var detection_radius: float = 200.0
var attack_range: float = 50.0

# ────────────────
# Node References
# ────────────────
var navigation_agent: NavigationAgent2D
# var detection_area: Area2D
var attack_area: Area2D
var animated_sprite: AnimatedSprite2D

const PortalDrop = preload("res://scenes/objects/portal_item.tscn")


# ────────────────
# Setup
# ────────────────
func _ready() -> void:
	collision_layer = 2  # Enemies on layer 2
	collision_mask = 1 | 2  # Walls (1) + Enemies (2)

	_get_references()
	_connect_signals()
	find_player()

	if health_component:
		health_component.health_changed.connect(_on_health_changed)
		health_component.health_depleted.connect(_on_health_depleted)

	if hurtbox_component:
		hurtbox_component.hit_by_bullet.connect(_on_hit_by_bullet)
		
func _get_references() -> void:
	navigation_agent = $NavigationAgent2D
	# detection_area = $DetectionArea
	attack_area = $AttackArea
	
	# detection_radius = (detection_area.get_child(0) as CollisionShape2D).shape.radius
	attack_range = (attack_area.get_child(0) as CollisionShape2D).shape.radius

	if has_node("Visual/AnimatedSprite2D"):
		animated_sprite = $Visual/AnimatedSprite2D


func _connect_signals() -> void:
	#if detection_area:
		#detection_area.body_entered.connect(_on_detection_area_entered)

	if attack_area:
		attack_area.body_entered.connect(_on_attack_area_entered)
		attack_area.body_exited.connect(_on_attack_area_exited)


# ────────────────
# Physics
# ────────────────
func _physics_process(delta: float) -> void:
	if not is_alive or not player:
		return

	path_update_timer += delta
	handle_movement(delta)
	move_and_slide()


# ────────────────
# Target
# ────────────────
func find_player() -> void:
	var main_scene = get_tree().current_scene
	if main_scene:
		player = main_scene.find_child("CharacterBody2D", true, false) as Player
		if not player:
			var players = get_tree().get_nodes_in_group("player")
			if players.size() > 0:
				player = players[0] as Player


# ────────────────
# Movement
# ────────────────
func handle_movement(delta: float) -> void:
	if not player:
		return

	#var distance_to_player = global_position.distance_to(player.global_position)

	#if not is_following and distance_to_player <= detection_radius:
		#is_following = true

	# if is_following:
		#follow_player(player.global_position, delta)
	#else:
		#velocity = Vector2.ZERO
		#_stop_animation()
	follow_player(player.global_position, delta)


func follow_player(player_position: Vector2, _delta: float) -> float:
	var distance_to_player = global_position.distance_to(player_position)

	if path_update_timer >= path_update_interval:
		navigation_agent.target_position = player_position
		path_update_timer = 0.0

	#var min_dist_to_player: float = 300

	if distance_to_player > attack_range and not navigation_agent.is_navigation_finished():
		var next_pos = navigation_agent.get_next_path_position()
		var direction = global_position.direction_to(next_pos)
		
		#if distance_to_player < min_dist_to_player:
			#direction *= -1
		
		velocity = direction * speed
		# _play_move_animation()
	else:
		velocity = Vector2.ZERO
		# _stop_animation()
	return distance_to_player


# ────────────────
# Animation
# ────────────────
func _play_move_animation() -> void:
	if animated_sprite and animated_sprite.sprite_frames.has_animation("move"):
		if not animated_sprite.is_playing():
			animated_sprite.play("move")

func _play_attack_animation() -> void:
	if animated_sprite and animated_sprite.sprite_frames.has_animation("attack"):
		animated_sprite.play("attack")

func _stop_animation() -> void:
	if animated_sprite and animated_sprite.is_playing():
		animated_sprite.stop()


# ────────────────
# Combat
# ────────────────
#func _on_detection_area_entered(body: Node2D) -> void:
	#if body is Player:
		#is_following = true

func _on_attack_area_entered(body: Node2D) -> void:
	if body is Player:
		can_attack = true
		#print("Start attacking...")
		attack()
		
func _on_attack_area_exited(body: Node2D) -> void:
	if body is Player:
		can_attack = false
		#print("Stop attacking.")

# ────────────────
# Hurtbox callback
# ────────────────
func _on_hit_by_bullet(_bullet: Node2D, bullet_damage: int, bullet_knockback: float) -> void:
	if not is_alive:
		return
	#print("Enemy: Hit by bullet signal received")
	_apply_damage_effects(bullet_damage)
	
	# Test de la distance avec le joueur
	# Permet d'éviter les knockbacks bizarres quand l'ennemi est trop proche du joueur, et que le bullet hit "par derrière"
	var knockback_dir: Vector2
	var player_dist: float = (global_position - player.global_position).length()
	#print("Knockback dist from player: ", player_dist)
	if player_dist < 50:
		knockback_dir = global_position - player.global_position
	else:
		knockback_dir = global_position - _bullet.global_position
	_apply_knockback(knockback_dir, bullet_knockback)


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
	#print("Enemy: Die signal received")
	die()

func die() -> void:
	is_alive = false
	#is_following = false
	velocity = Vector2.ZERO
	_apply_death_effects()
	queue_free()


# ────────────────
# Effects 
# ────────────────
func _apply_damage_effects(_amount: int) -> void:
	pass

func _apply_knockback(direction: Vector2, amount: float) -> void:
	#print("Knockback for ", amount, " in direction: ", direction)
	velocity = direction.normalized() * amount * 1000
	move_and_slide()
	

func _apply_death_effects() -> void:
	if randf() < 0.2 and PlayerStats.UPGRADES_COUNT < PlayerStats.UPGRADES_MAX:
		var portal: Portal = PortalDrop.instantiate()
		portal.global_position = self.global_position
		get_parent().call_deferred("add_child", portal)
		portal.portal_pickup.connect(get_parent().upgrade)
		
		PlayerStats.UPGRADES_COUNT += 1


func attack() -> void:
	get_tree().create_timer(attack_cooldown).timeout.connect(func(): if can_attack: attack())
	pass


# ────────────────
# Debug
# ────────────────
func _draw() -> void:
	if not is_alive:
		return

	#if not is_following:
		#draw_arc(Vector2.ZERO, detection_radius, 0, TAU, 64, Color.BLUE, 2.0, true)

	if debug_attack:
		draw_arc(Vector2.ZERO, attack_range, 0, TAU, 64, Color.RED, 2.0, true)

	if debug_navigation and navigation_agent: #and is_following:
		var path = navigation_agent.get_current_navigation_path()
		if path.size() > 1:
			for i in range(path.size() - 1):
				var from = to_local(path[i])
				var to = to_local(path[i + 1])
				draw_line(from, to, Color.GREEN, 3.0)

			if not navigation_agent.is_navigation_finished():
				var next_pos = navigation_agent.get_next_path_position()
				var local_next = to_local(next_pos)
				draw_circle(local_next, 8.0, Color.YELLOW)

func _process(_delta: float) -> void:
	queue_redraw()

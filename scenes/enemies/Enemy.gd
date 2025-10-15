extends CharacterBody2D
class_name Enemy

# ────────────────
# Components
# ────────────────
@onready var health_component: HealthComponent = $HealthComponent

# ────────────────
# ⚙️ Enemy Stats 
# ────────────────
@export_group("Stats")
@export var speed: float = 80.0
@export var damage: int = 20

@export_group("AI Behavior")
@export var path_update_interval: float = 0.2

@export_group("Debug")
@export var debug_navigation: bool = true

# ────────────────
# state
# ────────────────
var player: Player = null
var is_alive: bool = true
var is_following: bool = false
var path_update_timer: float = 0.0

# ranges 
var detection_radius: float = 200.0
var attack_range: float = 50.0

# Node references
var navigation_agent: NavigationAgent2D
var detection_area: Area2D
var attack_area: Area2D
var hitbox_area: Area2D
var animated_sprite: AnimatedSprite2D


# ────────────────
# Main Logic
# ────────────────
func _ready():
	collision_layer = 2  # Enemies on layer 2
	collision_mask = 1 | 2  # Walls (1) + Enemies (2)
	
	_get_references()
	_connect_signals()
	find_player()
	_on_enemy_ready()

	# connect health component
	if health_component:
		health_component.health_changed.connect(_on_health_changed)
		health_component.health_depleted.connect(_on_health_depleted)

# ────────────────
#  setup
# ────────────────
func _get_references():
	navigation_agent = $NavigationAgent2D
	detection_area = $DetectionArea
	attack_area = $AttackArea
	hitbox_area = $HitboxArea
	
	detection_radius = (detection_area.get_child(0) as CollisionShape2D).shape.radius
	attack_range = (attack_area.get_child(0) as CollisionShape2D).shape.radius
	
	if has_node("Visual/AnimatedSprite2D"):
		animated_sprite = $Visual/AnimatedSprite2D


func _connect_signals():
	if detection_area:
		detection_area.body_entered.connect(_on_detection_area_entered)
		detection_area.body_exited.connect(_on_detection_area_exited)
	
	if attack_area:
		attack_area.body_entered.connect(_on_attack_area_entered)
		attack_area.body_exited.connect(_on_attack_area_exited)
	
	if hitbox_area:
		hitbox_area.area_entered.connect(_on_hitbox_area_entered)
		hitbox_area.area_exited.connect(_on_hitbox_area_exited)


# ────────────────
# Physics Loop
# ────────────────
func _physics_process(delta):
	if not is_alive or not player:
		return
	
	path_update_timer += delta
	handle_movement(delta)
	move_and_slide()


# ────────────────
# Logic player
# ────────────────
func find_player():
	var main_scene = get_tree().current_scene
	if main_scene:
		player = main_scene.find_child("CharacterBody2D", true, false) as Player
		if not player:
			var players = get_tree().get_nodes_in_group("player")
			if players.size() > 0:
				player = players[0] as Player


func handle_movement(delta):
	if not player:
		return
	
	var distance_to_player = global_position.distance_to(player.global_position)
	
	if not is_following and distance_to_player <= detection_radius:
		is_following = true
	
	if is_following:
		follow_player(player.global_position, delta)
	else:
		velocity = Vector2.ZERO
		_stop_animation()


func follow_player(player_position: Vector2, _delta):
	var distance_to_player = global_position.distance_to(player_position)
	
	if path_update_timer >= path_update_interval:
		navigation_agent.target_position = player_position
		path_update_timer = 0.0
	
	if distance_to_player > attack_range and not navigation_agent.is_navigation_finished():
		var next_pos = navigation_agent.get_next_path_position()
		var direction = global_position.direction_to(next_pos)
		velocity = direction * speed
		_play_move_animation()
	else:
		velocity = Vector2.ZERO
		_stop_animation()


# ────────────────
# Animation
# ────────────────
func _play_move_animation():
	if animated_sprite and animated_sprite.sprite_frames.has_animation("move"):
		if animated_sprite.animation != "move" or not animated_sprite.is_playing():
			animated_sprite.play("move")

func _stop_animation():
	if animated_sprite and animated_sprite.is_playing():
		animated_sprite.stop()



func _on_enemy_ready() -> void:
	pass


# ────────────────
# Combat / Detection
# ────────────────
func _on_detection_area_entered(body: Node2D) -> void:
	if body is Player:
		is_following = true

func _on_detection_area_exited(_body: Node2D) -> void:
	pass

func _on_attack_area_entered(body: Node2D) -> void:
	if body is Player:
		attack()

func _on_attack_area_exited(_body: Node2D) -> void:
	pass


# ────────────────
# Hitbox 
# ────────────────
func _on_hitbox_area_entered(area: Area2D) -> void:
	if not is_alive:
		return
	if area is Bullet:
		var bullet = area as Bullet
		var damage_amount = bullet.get_damage()
		print("Enemy hit by projectile: ", damage_amount, " damage")
		take_damage(damage_amount)
		bullet.queue_free()


func _on_hitbox_area_exited(_area: Area2D) -> void:
	pass


# ────────────────
# ❤️ Health Integration
# ────────────────
func take_damage(amount: int) -> void:
	if health_component:
		health_component.damage(amount)
		_apply_damage_effects(amount)


func heal(amount: int) -> void:
	if health_component:
		health_component.heal(amount)


func _on_health_changed(current_health: int, max_health: int) -> void:
	print("Enemy HP: %d/%d" % [current_health, max_health])


func _on_health_depleted() -> void:
	print("Enemy died.")
	die()

func die() -> void:
	is_alive = false
	is_following = false
	velocity = Vector2.ZERO
	_apply_death_effects()
	queue_free()


func _apply_damage_effects(_amount: int) -> void:
	pass

func _apply_death_effects() -> void:
	pass

func attack() ->void :
	pass

# ────────────────
# Debug Drawing
# ────────────────
func _draw():
	if not is_alive:
		return
	
	if not is_following:
		draw_arc(Vector2.ZERO, detection_radius, 0, TAU, 64, Color.BLUE, 2.0, true)
	
	draw_arc(Vector2.ZERO, attack_range, 0, TAU, 64, Color.RED, 2.0, true)
	
	if debug_navigation and navigation_agent and is_following:
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

func _process(_delta):
	queue_redraw()

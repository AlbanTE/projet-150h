extends Enemy
class_name Skeleton

const ArrowScene: PackedScene = preload("res://scenes/projectiles/enemy_projectile/skeleton_arrow.tscn")
# ────────────────
# Visuals
# ────────────────
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var hit_anim: AnimationPlayer = $HitAnimPlayer
var base_scale: float

@export var min_dist_to_player: float = 500

var arrows: Array[SkeletonArrow] = []

func _ready() -> void:
	$HealthBar.max_value = health_component.max_health
	$HealthBar/Label.text = str(health_component.current_health) + " / " + str(health_component.max_health)
	base_scale = scale.x
	super()
	
func _on_health_changed(prev_health: int, current_health: int, max_health: int) -> void:
	$HealthBar.value = current_health
	$HealthBar.max_value = health_component.max_health
	$HealthBar/Label.text = str(current_health) + " / " + str(max_health)
	super(prev_health, current_health, max_health)

func _apply_damage_effects(_amount: int) -> void:
	print("HIT")
	hit_anim.play("hit")
	

func _apply_death_effects() -> void:
	#print("Slime mort — trucs a faire.")
	super()

func _play_move_animation() -> void:
	anim_player.play("move")

func _play_attack_animation() -> void:
	anim_player.play("attack")

func spawn_arrow() -> void:
	var arrow: SkeletonArrow = ArrowScene.instantiate()
	get_parent().add_child(arrow)
	arrow.scale *= Vector2(base_scale, base_scale)
	arrow.global_position = $Visual/RightArm/RightHand.global_position
	arrow.damage = damage
	arrow.direction = (player.global_position - global_position).normalized()
	arrow.rotation = arrow.direction.angle()
	
	arrows.append(arrow)
	
func follow_player(player_position: Vector2, _delta: float) -> float:
	var distance_to_player = global_position.distance_to(player_position)

	if path_update_timer >= path_update_interval:
		navigation_agent.target_position = player_position
		path_update_timer = 0.0

	if distance_to_player < min_dist_to_player:
		navigation_agent.target_position = global_position + (global_position - player_position) # Opposite direction of the player
		var next_pos = navigation_agent.get_next_path_position()
		var direction = global_position.direction_to(next_pos)
		
		velocity = direction * speed # Flee the player
		_play_move_animation()
		
		navigation_agent.target_position = player_position
		return distance_to_player


	if distance_to_player > attack_range and not navigation_agent.is_navigation_finished():
		var next_pos = navigation_agent.get_next_path_position()
		var direction = global_position.direction_to(next_pos)
		
		velocity = direction * speed
		_play_move_animation()
	else:
		velocity = Vector2.ZERO
		_play_attack_animation()
		
	return distance_to_player

func aim_skeleton_towards_player():
	var player_pos = player.global_position
	var direction = (player_pos - global_position).normalized()

	if abs(rad_to_deg(direction.angle())) > 90:
		$Visual.scale.x = -base_scale
		$Visual.scale.y = base_scale
	else:
		$Visual.scale.x = base_scale
		$Visual.scale.y = base_scale

func _process(_delta: float):
	if not activated:
		return
	aim_skeleton_towards_player()
	super(_delta)


func _on_visible_on_screen_enabler_2d_screen_entered() -> void:
	activated = true

func _exit_tree():
	for a in arrows:
		if is_instance_valid(a):
			print("Freeing arrow")
			a.queue_free()

extends Enemy
class_name EnemyType3

func _ready():
	enemy_color = Color.PURPLE
	health = 80
	speed = 60
	attack_type = AttackType.RANGED
	damage = 25
	detection_radius = 250.0
	follow_range = 200.0
	attack_range = 120.0
	super._ready()

func follow_player(player_position: Vector2, _delta):
	var distance_to_player = global_position.distance_to(player_position)
	
	if path_update_timer >= path_update_interval:
		if distance_to_player > attack_range * 1.2:
			navigation_agent.target_position = player_position
		elif distance_to_player < attack_range * 0.8:
			var direction_away = global_position.direction_to(player_position) * -1
			navigation_agent.target_position = player_position + direction_away * attack_range
		path_update_timer = 0.0
	
	var in_optimal_range = distance_to_player >= attack_range * 0.8 and distance_to_player <= attack_range * 1.2
	if not in_optimal_range and not navigation_agent.is_navigation_finished():
		var next_pos = navigation_agent.get_next_path_position()
		var direction = global_position.direction_to(next_pos)
		velocity = direction * speed
	else:
		velocity = Vector2.ZERO
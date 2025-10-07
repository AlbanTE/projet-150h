extends Enemy
class_name EnemyType3

@export var health_override: int = 80
@export var speed_override: float = 60.0
@export var attack_type_override: AttackType = AttackType.RANGED
@export var damage_override: int = 25
@export var detection_radius_override: float = 500
@export var attack_range_override: float = 200

func _ready():
	enemy_color = Color.PURPLE
	health = health_override
	speed = speed_override
	attack_type = attack_type_override
	damage = damage_override
	detection_radius = detection_radius_override
	attack_range = attack_range_override
	super._ready()

func follow_player(player_position: Vector2, _delta):
	var distance_to_player = global_position.distance_to(player_position)
	
	if path_update_timer >= path_update_interval:
		if distance_to_player > attack_range:
			# Trop loin : se rapprocher du joueur
			navigation_agent.target_position = player_position
		elif distance_to_player < attack_range:
			# Le joueur est dans la range : reculer pour le mettre exactement à la limite
			var direction_away = global_position.direction_to(player_position) * -1
			var target_position = player_position + direction_away * attack_range
			navigation_agent.target_position = target_position
		path_update_timer = 0.0
	
	# Toujours bouger sauf si on est exactement à la distance d'attaque
	if abs(distance_to_player - attack_range) > 5.0 and not navigation_agent.is_navigation_finished():
		var next_pos = navigation_agent.get_next_path_position()
		var direction = global_position.direction_to(next_pos)
		velocity = direction * speed
	else:
		velocity = Vector2.ZERO
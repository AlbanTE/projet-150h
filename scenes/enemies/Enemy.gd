extends CharacterBody2D
class_name Enemy

enum AttackType { MELEE, RANGED }

@export var health: int = 100
@export var speed: float = 80.0
@export var attack_type: AttackType = AttackType.MELEE
@export var damage: int = 20
@export var detection_radius: float = 200.0
@export var attack_range: float = 50.0
@export var navigation_tilemap: TileMapLayer

var player: Player = null
var is_alive: bool = true
var is_following: bool = false

var navigation_agent: NavigationAgent2D
var path_update_timer: float = 0.0
var path_update_interval: float = 0.2
@export var debug_navigation: bool = true

var sprite: ColorRect
var enemy_color: Color = Color.RED

func _ready():
	setup_collision()
	setup_navigation()
	create_visual_representation()
	find_player()

func setup_collision():
	collision_layer = 2
	collision_mask = 1
	
	if not has_node("CollisionShape2D"):
		var collision_shape = CollisionShape2D.new()
		var rect_shape = RectangleShape2D.new()
		rect_shape.size = Vector2(32, 32)
		collision_shape.shape = rect_shape
		collision_shape.name = "CollisionShape2D"
		add_child(collision_shape)

func setup_navigation():
	navigation_agent = NavigationAgent2D.new()
	navigation_agent.target_desired_distance = 8.0
	navigation_agent.radius = 16.0
	add_child(navigation_agent)
	
	if not navigation_tilemap:
		auto_assign_navigation()

func auto_assign_navigation():
	var main_scene = get_tree().current_scene
	if main_scene and main_scene.has_method("get") and main_scene.ground_layer:
		navigation_tilemap = main_scene.ground_layer

func create_visual_representation():
	sprite = ColorRect.new()
	sprite.size = Vector2(32, 32)
	sprite.position = Vector2(-16, -16)
	sprite.color = enemy_color
	add_child(sprite)

func _physics_process(delta):
	if not is_alive or not player:
		return
	
	path_update_timer += delta
	handle_movement(delta)
	move_and_slide()

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

func follow_player(player_position: Vector2, _delta):
	var distance_to_player = global_position.distance_to(player_position)
	
	if path_update_timer >= path_update_interval:
		navigation_agent.target_position = player_position
		path_update_timer = 0.0
	
	if distance_to_player > attack_range and not navigation_agent.is_navigation_finished():
		var next_pos = navigation_agent.get_next_path_position()
		var direction = global_position.direction_to(next_pos)
		velocity = direction * speed
	else:
		velocity = Vector2.ZERO

func take_damage(_amount: int):
	pass

func die():
	is_alive = false
	is_following = false
	velocity = Vector2.ZERO
	queue_free()

func attack():
	pass


# DEBUG VISUEL - paramètre debug_navigation 


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

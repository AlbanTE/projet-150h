extends Node2D

const TileManager = preload("res://scenes/Grid/TileManager.gd")
const DungeonGenerator = preload("res://scenes/dungeon_generators/DungeonGenerator.gd")

@onready var player = $CharacterBody2D
@export var ground_layer: TileMapLayer
@export var wall_layer: TileMapLayer
var tile_builder: TileManager
@export var dungeon_generator: DungeonGenerator
@export var _seed: int = -1

func _ready():
	tile_builder = TileManager.new()

func _input(event):
	if not event is InputEventKey or not event.pressed:
		return
	
	match event.keycode:
		KEY_G:
			test_enemies()
		KEY_H:
			kill_nearest_enemy()
		KEY_K:
			build_dungeon_area()

func build_dungeon_area():
	print("Building dungeon...")
	ground_layer.clear()
	wall_layer.clear()
	
	var dungeon: Array = dungeon_generator.generate_dungeon(_seed)
	
	dungeon_generator._print_ascii_map()

	# Find half dimensions to center dungeon at (0,0)
	var half_w: int = int(dungeon[0].size() / 2.)
	var half_h: int = int(dungeon.size() / 2.)
	var offset = Vector2i(-half_w, -half_h)

	# Build dungeon tiles
	tile_builder.build_from_grid(ground_layer, wall_layer, dungeon, offset)

	var player_spawn: Vector2i = Vector2i(0, 0)
	for y in dungeon.size():
		for x in dungeon[y].size():
			if dungeon[y][x] == DungeonGenerator.Tile.PLAYER:
				player_spawn = Vector2i(x, y)
				break

	# Move player to spawn
	teleport_player_to_spawn(player_spawn, offset)
	
func teleport_player_to_spawn(spawn_tile: Vector2i, offset: Vector2i) -> void:
	if not player:
		push_error("Player node not found!")
		return

	# Tile coordinate in grid space
	var tile_coord: Vector2i = spawn_tile + offset

	# Convert to world position manually
	var tile_size: Vector2 = ground_layer.tile_set.tile_size
	var world_pos: Vector2 = Vector2(tile_coord.x, tile_coord.y) * tile_size * ground_layer.scale
	world_pos += (tile_size * ground_layer.scale) / 2  # center of tile

	player.global_position = world_pos

func test_enemies():
	# Clear existing enemies
	for child in get_children():
		if child.has_method("take_damage") and child != player:
			child.queue_free()
	
	
	# Layer 1: Walls/Environment 
	# Layer 2: Enemies   
	# Layer 4: Player 
	
	# Load enemy scripts
	var enemy_type1_script = preload("res://scenes/enemies/EnemyType1.gd")
	var enemy_type2_script = preload("res://scenes/enemies/EnemyType2.gd")
	var enemy_type3_script = preload("res://scenes/enemies/EnemyType3.gd")
	
	# Create enemy instances (positions will be set relative to player)
	var enemy1 = CharacterBody2D.new()
	enemy1.set_script(enemy_type1_script)
	enemy1.name = "Orange"
	
	var enemy2 = CharacterBody2D.new()
	enemy2.set_script(enemy_type2_script)
	enemy2.name = "Red"
	
	var enemy3 = CharacterBody2D.new()
	enemy3.set_script(enemy_type3_script)
	enemy3.name = "Purple"
	
	var player_pos = Vector2.ZERO
	if player:
		player_pos = player.global_position
	
	enemy1.position = player_pos + Vector2(150, 100)  
	enemy2.position = player_pos + Vector2(-180, 180)
	enemy3.position = player_pos + Vector2(250, -200)  
	
	
	for enemy in [enemy1, enemy2, enemy3]:
		var collision_shape = CollisionShape2D.new()
		var rect_shape = RectangleShape2D.new()
		rect_shape.size = Vector2(32, 32)
		collision_shape.shape = rect_shape
		enemy.add_child(collision_shape)
		
		enemy.collision_layer = 2  
		enemy.collision_mask = 1   
		
		add_child(enemy)
	
	
func kill_nearest_enemy():
	if not player:
		return
	
	var nearest_enemy = null
	var nearest_distance = INF
	
	for child in get_children():
		if child.has_method("take_damage") and child != player and child.is_alive:
			var distance = player.global_position.distance_to(child.global_position)
			if distance < nearest_distance:
				nearest_distance = distance
				nearest_enemy = child
	
	if nearest_enemy:
		nearest_enemy.die()

extends Node2D

const TileManager = preload("res://scenes/Grid/TileManager.gd")
const DungeonGeneratorScript = preload("res://scenes/dungeon_generators/DungeonGenerator.gd")

# Préchargement des scripts d'ennemis
const EnemyType1Script = preload("res://scenes/enemies/EnemyType1.gd")
const EnemyType2Script = preload("res://scenes/enemies/EnemyType2.gd")
const EnemyType3Script = preload("res://scenes/enemies/EnemyType3.gd")

const ENEMY_TYPE_COUNT = 3

@onready var player = $CharacterBody2D
@export var ground_layer: TileMapLayer
@export var wall_layer: TileMapLayer
var tile_builder: CustomTileManager
@export var dungeon_generator: DungeonGeneratorScript
@export var _seed: int = -1

func _ready():
	tile_builder = CustomTileManager.new()
	build_dungeon_area()

func SpawnEnnemi(world_position: Vector2, enemy_type: int) -> Enemy:
	var enemy = CharacterBody2D.new()
	
	match enemy_type:
		0:
			enemy.set_script(EnemyType1Script)
			enemy.name = "EnemyType1_" + str(randi())
		1:
			enemy.set_script(EnemyType2Script)
			enemy.name = "EnemyType2_" + str(randi())
		2:
			enemy.set_script(EnemyType3Script)
			enemy.name = "EnemyType3_" + str(randi())
		_:
			push_error("Type d'ennemi non reconnu: " + str(enemy_type))
			enemy.queue_free()
			return null
	
	enemy.global_position = world_position
	add_child(enemy)
	return enemy

func spawn_enemy_batch(count: int = 25):
	var used_cells = ground_layer.get_used_cells()
	if used_cells.is_empty():
		return
	
	for i in count:
		var random_cell = used_cells[randi() % used_cells.size()]
		var world_pos = cell_to_world_position(random_cell)
		var random_type = randi() % ENEMY_TYPE_COUNT
		SpawnEnnemi(world_pos, random_type)

func cell_to_world_position(cell_coord: Vector2i) -> Vector2:
	var tile_size = Vector2(ground_layer.tile_set.tile_size)
	var world_pos = Vector2(cell_coord) * tile_size * ground_layer.scale
	return world_pos + (tile_size * ground_layer.scale) / 2

func _input(event):
	if not event is InputEventKey or not event.pressed:
		return
	
	match event.keycode:
		KEY_G:
			spawn_enemy_batch()
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

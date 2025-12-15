extends Node2D

const TileManager = preload("res://scenes/Grid/TileManager.gd")
const DungeonGeneratorScript = preload("res://scenes/dungeon_generators/DungeonGenerator.gd")

# Préchargement des scènes d'ennemis
const EnemyType1Scene = preload("res://scenes/enemies/EnemyType1.tscn")
const EnemyType2Scene = preload("res://scenes/enemies/EnemyType2.tscn")


const ENEMY_TYPE_COUNT = 2

@onready var player = $Character
@export var ground_layer: TileMapLayer
@export var wall_layer: TileMapLayer
var tile_builder: CustomTileManager
@export var dungeon_generator: DungeonGeneratorScript
@export var _seed: int = -1

func advance_level() -> void:
	AudioGlobal.current_level = (AudioGlobal.current_level % 4) + 1
	
func upgrade():
	$CanvasLayer/GameUI.openRewardMenu()
	
func _ready():
	seed(_seed)
	tile_builder = CustomTileManager.new()
	build_dungeon_area()
	
	# Audio init
	AudioGlobal.current_level = 1

func SpawnEnnemi(world_position: Vector2, enemy_type: int) -> Enemy:
	var enemy: Enemy = null
	
	match enemy_type:
		0:
			enemy = EnemyType1Scene.instantiate()
			enemy.name = "EnemyType1_" + str(randi())
		1:
			enemy = EnemyType2Scene.instantiate()
			enemy.name = "EnemyType2_" + str(randi())
		_:
			push_error("Type d'ennemi non reconnu: " + str(enemy_type))
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
		KEY_K:
			build_dungeon_area()
		KEY_M:
			advance_level() 

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

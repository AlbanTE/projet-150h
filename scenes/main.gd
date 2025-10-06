extends Node2D

const TileManager = preload("res://scenes/Grid/TileManager.gd")
const DungeonGenerator = preload("res://scenes/dungeon_generators/tinykeep.gd")

@onready var player = $CharacterBody2D
@export var map_layer: TileMapLayer
var tile_builder: TileManager
var dungeon_generator: DungeonGenerator

func _ready():
	tile_builder = TileManager.new()
	dungeon_generator = DungeonGenerator.new()

func _input(event):
	if not event is InputEventKey or not event.pressed:
		return
	
	match event.keycode:
		KEY_G:
			build_small_test_area()
		KEY_H:
			build_medium_test_area()
		KEY_J:
			build_large_test_area()
		KEY_K:
			build_dungeon_area()

func build_small_test_area():
	print("Building small test area (10x10)")
	map_layer.clear()
	tile_builder.test_small_grid(map_layer)

func build_medium_test_area():
	print("Building medium test area (50x50)")
	map_layer.clear()
	tile_builder.test_medium_grid(map_layer)

func build_large_test_area():
	print("Building large test area (100x100)")
	map_layer.clear()
	tile_builder.test_large_grid(map_layer)
	
func build_dungeon_area():
	print("Building dungeon...")
	map_layer.clear()
	
	dungeon_generator = DungeonGenerator.new()
	var dungeon: Array = dungeon_generator.generate_dungeon(-1)
	
	dungeon_generator._print_ascii_map()

	# Find half dimensions to center dungeon at (0,0)
	var half_w = dungeon[0].size() / 2
	var half_h = dungeon.size() / 2
	var offset = Vector2i(-half_w, -half_h)

	# Build dungeon tiles
	tile_builder.build_from_grid(map_layer, dungeon, offset)

	var player_spawn: Vector2i = Vector2i(0, 0)
	for y in dungeon.size():
		for x in dungeon[y].size():
			if dungeon[y][x] == DungeonGenerator.Tile.PLAYER:
				player_spawn = Vector2i(x, y)
				print("Found player spawn !")

	# Move player to spawn
	teleport_player_to_spawn(player_spawn, offset)
	
func teleport_player_to_spawn(spawn_tile: Vector2i, offset: Vector2i) -> void:
	if not player:
		push_error("Player node not found!")
		return

	# Tile coordinate in grid space
	var tile_coord: Vector2i = spawn_tile + offset

	# Convert to world position manually
	var tile_size: Vector2 = map_layer.tile_set.tile_size
	var world_pos: Vector2 = Vector2(tile_coord.x, tile_coord.y) * tile_size * map_layer.scale
	world_pos += (tile_size * map_layer.scale) / 2  # center of tile

	player.global_position = world_pos

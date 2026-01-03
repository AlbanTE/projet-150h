extends Node2D

const TileManager = preload("res://scenes/Grid/TileManager.gd")
const DungeonGeneratorScript = preload("res://scenes/dungeon_generators/DungeonGenerator.gd")

# Préchargement des scènes d'ennemis
const EnemyType1Scene = preload("res://scenes/enemies/EnemyType1.tscn")
const EnemyType2Scene = preload("res://scenes/enemies/EnemyType2.tscn")

const ENEMY_TYPE_COUNT = 2

var enemies_loaded: Array[Enemy] = []

# Scène des objets etc...
var exit: PackedScene = preload("res://scenes/objects/exit_stairs.tscn")

@onready var player: Player = $Character
@export var ground_layer: TileMapLayer
@export var wall_layer: TileMapLayer
var tile_builder: CustomTileManager
@export var dungeon_generator: DungeonGeneratorScript
@export var _seed: int = -1
@export var current_level: int = 0

@onready var UI: GameUI = $CanvasLayer/GameUI

func upgrade():
	UI.openRewardMenu()
	
func update_weapon_ui():
	UI.update_weapon()

func update_items_ui():
	UI.update_items()

func choosing_item_ui(item: Item):
	UI.openChooseMenu(item)

func item_chosen_ui():
	UI.closeChooseMenu()

func _ready():
	seed(_seed)
	tile_builder = CustomTileManager.new()
	build_dungeon_area()
	
	player.weapon_component.connect("weapon_equiped", update_weapon_ui)
	player.inventory_manager.connect("update_inventory", update_items_ui)
	player.inventory_manager.connect("choosing_item", choosing_item_ui)
	player.inventory_manager.connect("item_chosen", item_chosen_ui)
	
	# Replace item signals connect
	for i in range(3):
		var item_box = UI.get_node("GridContainer/Item" + str(i+1))
		item_box.connect("replaced", player.inventory_manager.replace_item)
	UI.get_node("InGameMenu/ChooseItem/ItemBox").connect("replaced", player.inventory_manager.replace_item)

func next_level() -> void:
	print("Go to next level")
	current_level += 1
	PlayerStats.UPGRADES_COUNT = 0
	build_dungeon_area()
	

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
	
	# To remove ennemies when exiting level
	enemies_loaded.append(enemy)
	
	# Modifiers based on current level
	enemy.health_component.set_max_health((current_level+1)*enemy.health_component.max_health)
	enemy.health_component.set_current_health((current_level+1)*enemy.health_component.current_health)
	enemy.damage = enemy.damage * (current_level + 1)
	
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
	for child in ground_layer.get_children():
		child.queue_free()
		print("ground child freed !") # Exit, items etc...
	for child in wall_layer.get_children():
		child.queue_free()
		print("wall child freed !") # Torches etc...
		
	for enemy in enemies_loaded:
		if enemy:
			enemies_loaded.erase(enemy)
			enemy.queue_free()
			print("Removed leftover enemy")
	
	var dungeon: Array = dungeon_generator.generate_dungeon(_seed + current_level)
	
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
	
	place_exit(dungeon, offset)
	
func place_exit(grid_data: Array, offset: Vector2i = Vector2i.ZERO) -> void:
	var exit_coords: Vector2i = Vector2i(0, 0)
	for y in grid_data.size():
		for x in grid_data[y].size():
			if grid_data[y][x] == DungeonGenerator.Tile.EXIT:
				exit_coords = Vector2i(x, y)
				break
				
	# Tile coordinate in grid space
	var tile_coord: Vector2i = exit_coords + offset

	# Convert to world position manually
	var tile_size: Vector2 = ground_layer.tile_set.tile_size
	var exit_position: Vector2 = Vector2(tile_coord.x, tile_coord.y) * tile_size #* ground_layer.scale
	exit_position += tile_size / 2  # center of tile
	
	var exit_instance: Node2D = exit.instantiate()
	exit_instance.global_position = exit_position
	ground_layer.add_child(exit_instance)
	exit_instance.connect("exit_reached", next_level)
	
	print("Added exit at: ", exit_coords)

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

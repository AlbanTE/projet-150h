extends Node2D

const TileManager = preload("res://scenes/Grid/TileManager.gd")
const DungeonGeneratorScript = preload("res://scenes/dungeon_generators/DungeonGenerator.gd")

# Préchargement des scènes d'ennemis
const EnemyType1Scene = preload("res://scenes/enemies/EnemyType1.tscn")
const EnemyType2Scene = preload("res://scenes/enemies/EnemyType2.tscn")
const EnemyType3Scene = preload("res://scenes/enemies/EnemyType3.tscn")
const SkeletonScene = preload("res://scenes/enemies/skeleton.tscn")
const BossScene = preload("res://scenes/enemies/boss.tscn")


const ENEMY_TYPE_COUNT = 4

var enemies_loaded: Array[Enemy] = []

# Scène des objets etc...
var exit: PackedScene = preload("res://scenes/objects/exit_stairs.tscn")

@onready var player: Player = $Character
@export var ground_layer: TileMapLayer
@export var wall_layer: TileMapLayer
var tile_builder: CustomTileManager
@export var dungeon_generator: DungeonGeneratorScript
@export var _seed: int = -1

@onready var UI: GameUI = $CanvasLayer/GameUI
@onready var time_label: Label = $CanvasLayer/TimeRemaining
@onready var timer: Timer = $Timer
var next_enemy_spawn: int = 0
var next_wave_spawn: int = 0

var dungeon: Array

func advance_level() -> void:
	AudioGlobal.current_level = (AudioGlobal.current_level % 4) + 1
	
	if AudioGlobal.current_level == 4:
		$AudioManager.pause_music()
	else:
		$AudioManager.update_music()
	
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

func init():
	seed(_seed)
	tile_builder = CustomTileManager.new()
	
	#advance_level()
	#advance_level()
	#advance_level()
	#build_boss_arena()
	
	build_dungeon_area()
	
	# Audio init
	AudioGlobal.current_level = 1
	
	player.weapon_component.connect("weapon_equiped", update_weapon_ui)
	player.inventory_manager.connect("update_inventory", update_items_ui)
	player.inventory_manager.connect("choosing_item", choosing_item_ui)
	player.inventory_manager.connect("item_chosen", item_chosen_ui)
	player.player_died.connect(game_over)
	
	# Replace item signals connect
	for i in range(3):
		var item_box = UI.get_node("GridContainer/Item" + str(i+1))
		item_box.connect("replaced", player.inventory_manager.replace_item)
	UI.get_node("InGameMenu/ChooseItem/ItemBox").connect("replaced", player.inventory_manager.replace_item)
	
	timer.process_mode = Node.PROCESS_MODE_PAUSABLE
	timer.timeout.connect(game_over)
	timer.autostart = false
	timer.one_shot = true

func _ready():
	UI.start_game.connect(init)

func next_level() -> void:
	print("Go to next level")
	if AudioGlobal.current_level == 4:
		print("You beat the game !")
		get_tree().quit()
		return
	
	advance_level()
	PlayerStats.UPGRADES_COUNT = 0
	
	if AudioGlobal.current_level == 4:
		build_boss_arena()
	else:
		build_dungeon_area()

func game_over() -> void:
	print("Game over !")
	get_tree().paused = true
	await get_tree().create_timer(3).timeout
	get_tree().quit()

func SpawnEnnemi(world_position: Vector2, enemy_type: int) -> Enemy:
	var enemy: Enemy = null
	
	match enemy_type:
		0:
			enemy = EnemyType1Scene.instantiate()
			enemy.name = "EnemyType1_" + str(randi())
		1:
			enemy = EnemyType2Scene.instantiate()
			enemy.name = "EnemyType2_" + str(randi())
		2:
			enemy = EnemyType3Scene.instantiate()
			enemy.name = "EnemyType3_" + str(randi())
		3:
			enemy = SkeletonScene.instantiate()
			enemy.name = "Skeleton_" + str(randi())
		_:
			push_error("Type d'ennemi non reconnu: " + str(enemy_type))
			return null
	
	add_child(enemy)
	enemy.global_position = world_position
	
	# To remove ennemies when exiting level
	enemies_loaded.append(enemy)
	
	# Modifiers based on current level
	var current_level = AudioGlobal.current_level
	var modifier: float = 1 + (current_level-1) * 0.5
	enemy.health_component.set_max_health(int(modifier*enemy.health_component.max_health))
	enemy.health_component.set_current_health(int(modifier*enemy.health_component.current_health))
	enemy.damage = int(enemy.damage * modifier)
	
	return enemy

func spawn_enemy_batch(count: int = 25, skeleton_count: int = 0):
	print("Spawning ", count, " enemies and ", skeleton_count, " skeletons!")
	
	var used_cells = ground_layer.get_used_cells()
	if used_cells.is_empty():
		return
	
	# Remove cells too close to the player
	var to_remove = []
	for cell in used_cells:
		var cell_pos: Vector2 = cell_to_world_position(cell)
		if cell_pos.distance_to(player.global_position) < get_viewport_rect().size[1] / 2 or cell_pos.distance_to(player.global_position) > 3 * (get_viewport_rect().size[1] / 2):
			to_remove.append(cell)
	
	if to_remove.size() < used_cells.size():
		for c in to_remove:
			used_cells.erase(c)
	
	# Spawn ennemis normaux (types 0, 1, 2)
	for i in count:
		var random_cell = used_cells[randi() % used_cells.size()]
		var world_pos = cell_to_world_position(random_cell)
		var random_type = randi() % (ENEMY_TYPE_COUNT - 1) # Pas de squelettes (0, 1, 2)
		
		var random_offset: Vector2 = Vector2(randf(), randf()) * (Vector2(ground_layer.tile_set.tile_size) * ground_layer.scale) / 2
		SpawnEnnemi(world_pos + random_offset, random_type)
	
	# Spawn squelettes (type 3)
	for i in skeleton_count:
		var random_cell = used_cells[randi() % used_cells.size()]
		var world_pos = cell_to_world_position(random_cell)
		
		var random_offset: Vector2 = Vector2(randf(), randf()) * (Vector2(ground_layer.tile_set.tile_size) * ground_layer.scale) / 2
		SpawnEnnemi(world_pos + random_offset, 3) # Type 3 = Skeleton


func cell_to_world_position(cell_coord: Vector2i) -> Vector2:
	var tile_size = Vector2(ground_layer.tile_set.tile_size)
	var world_pos = Vector2(cell_coord) * tile_size * ground_layer.scale
	return world_pos + (tile_size * ground_layer.scale) / 2

func _input(event):
	if not event is InputEventKey or not event.pressed:
		return
	
	match event.keycode:
		KEY_G:
			spawn_enemy_batch(8, 1)
		KEY_K:
			build_dungeon_area()
		KEY_M:
			next_level() 

func build_dungeon_area():
	UI.openLoadingMenu()
	# Attendre un court instant pour refresh l'UI
	await get_tree().create_timer(0.1).timeout
	
	ground_layer.clear()
	wall_layer.clear()
	for child in ground_layer.get_children():
		child.queue_free()
		# print("ground child freed !") # Exit, items etc...
	for child in wall_layer.get_children():
		child.queue_free()
		# print("wall child freed !") # Torches etc...
		
	for enemy in enemies_loaded:
		if is_instance_valid(enemy):
			enemy.queue_free()
	enemies_loaded.clear()
	
	dungeon = dungeon_generator.generate_dungeon(_seed + AudioGlobal.current_level - 1)
	
	var level_time: int = 60 * (4 + AudioGlobal.current_level)
	timer.start(level_time)
	next_enemy_spawn = level_time - randi_range(7, 20)
	next_wave_spawn = level_time - 30
	
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
	
	place_exit()
	
	UI.closeLoadingMenu()
	
func build_boss_arena():
	print("Building arena...")
	ground_layer.clear()
	wall_layer.clear()
	for child in ground_layer.get_children():
		child.queue_free()
		# print("ground child freed !") # Exit, items etc...
	for child in wall_layer.get_children():
		child.queue_free()
		# print("wall child freed !") # Torches etc...
		
	for enemy in enemies_loaded:
		if is_instance_valid(enemy):
			enemy.queue_free()
	enemies_loaded.clear()
	
	dungeon = dungeon_generator.generate_boss_arena()
	
	timer.stop()
	next_enemy_spawn = -1
	next_wave_spawn = -1
	
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
	
	var boss_inst: Boss = BossScene.instantiate()
	add_child(boss_inst)
	boss_inst.global_position = Vector2(0, 0)
	boss_inst.connect("boss_dead", place_exit_at)
	
func place_exit_at(position: Vector2) -> void:
	print("Boss died at :", position)

	var exit_instance: Node2D = exit.instantiate()
	exit_instance.global_position = position
	exit_instance.scale = Vector2(4, 4)
	add_child(exit_instance)
	exit_instance.connect("exit_reached", next_level)
	
	print("Added exit at: ", position)
	
		
func place_exit() -> void:
	var half_w: int = int(dungeon[0].size() / 2.)
	var half_h: int = int(dungeon.size() / 2.)
	var offset = Vector2i(-half_w, -half_h)
	
	var exit_found: bool = false
	var exit_coords: Vector2i = Vector2i(0, 0)
	for y in dungeon.size():
		for x in dungeon[y].size():
			if dungeon[y][x] == DungeonGenerator.Tile.EXIT:
				exit_coords = Vector2i(x, y)
				exit_found = true
				break
	
	if not exit_found:
		return
	
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
		
func _process(_delta: float) -> void:
	if timer.is_stopped():
		time_label.text = "???"
	else:
		time_label.text = "%d:%02d" % [floor(timer.time_left / 60), int(timer.time_left) % 60]
		
	if int(timer.time_left) == next_enemy_spawn and abs(int(timer.time_left) - next_wave_spawn) > 3:
		# Spawn entre 4 et 8 ennemis normaux
		var enemy_count = randi_range(4, 8)
		# 1 chance sur 3 d'avoir un squelette en plus
		var skeleton_bonus = 1 if randi() % 3 == 0 else 0
		
		spawn_enemy_batch(enemy_count, skeleton_bonus)
		next_enemy_spawn = int(timer.time_left) - randi_range(7, 20)
		
	if int(timer.time_left) == next_wave_spawn:
		# Spawn entre 8 et 13 ennemis normaux + entre 1 et 2 squelettes
		var enemy_count = randi_range(8, 13)
		var skeleton_count = randi_range(1, 2)
		
		spawn_enemy_batch(enemy_count, skeleton_count)
		next_wave_spawn = int(timer.time_left) - 30
	

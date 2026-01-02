extends Node
class_name CustomTileManager

const DungeonGenerator = preload("res://scenes/dungeon_generators/DungeonGenerator.gd")

var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var torch: PackedScene = preload("res://scenes/objects/torch.tscn")
var chest: PackedScene = preload("res://scenes/objects/Chest.tscn")

func build_from_grid(ground_layer: TileMapLayer, wall_layer: TileMapLayer, grid_data: Array, offset: Vector2i = Vector2i.ZERO) -> void:
	if not _is_valid_map_layer(ground_layer) or not _is_valid_map_layer(wall_layer) or grid_data.is_empty():
		return
	
	var all_positions = _collect_tile_positions(grid_data, offset)
	var tile_positions = all_positions[0]
	var wall_positions = all_positions[1]
	
	if tile_positions.size() > 0:
		ground_layer.set_cells_terrain_connect(tile_positions, 0, 0)
	if wall_positions.size() > 0:
		wall_layer.set_cells_terrain_connect(wall_positions, 0, 0)
		add_light_sources(wall_layer, 10)
		
	add_chests(ground_layer, grid_data, offset)

func add_chests(ground_layer: TileMapLayer, grid_data: Array, offset: Vector2i = Vector2i.ZERO) -> void:
	for y in grid_data.size():
		for x in grid_data[y].size():
			if grid_data[y][x] == DungeonGenerator.Tile.OBJECT:
				# print("Chest !")
				var chest_inst = chest.instantiate()
				var ipos = Vector2i(x, y) + offset
				
				var tile_size: Vector2 = ground_layer.tile_set.tile_size
				var position: Vector2 = Vector2(ipos.x, ipos.y) * tile_size #* ground_layer.scale
				position += tile_size / 2  # center of tile
				
				chest_inst.global_position = position
				ground_layer.add_child(chest_inst)
	

func add_light_sources(wall_layer: TileMapLayer, min_dist: float) -> void:
	
	var torches = wall_layer.get_tree().get_nodes_in_group("Torches")
	print("Removed ", torches.size(), " torches.")
	for t in torches:
		t.queue_free()
	
	var candidates = wall_layer.get_used_cells_by_id(0, Vector2i(2,2))
	var half_tile_size = wall_layer.tile_set.tile_size / 2
	
	var added: Array[Vector2i] = []
	
	for i in range(candidates.size()):
		var cell: Vector2i = candidates.pick_random()
		var too_close: bool = false
		for other in added:
			if cell.distance_to(other) < min_dist:
				too_close = true
				
		if too_close: continue
		
		
		var world_position = wall_layer.tile_set.tile_size * cell + half_tile_size
		var torch_instance: Node2D = torch.instantiate()
		torch_instance.add_to_group("Torches")
		torch_instance.global_position = world_position
		wall_layer.add_child(torch_instance)
		added.append(cell)
		candidates.erase(cell)
	
	print("Added ", added.size(), " torches.")

func _collect_tile_positions(grid_data: Array, offset: Vector2i):
	var positions: Array[Vector2i] = []
	var others: Array[Vector2i] = []
	
	for row_index in grid_data.size():
		var row = grid_data[row_index]
		
		if not row is Array:
			continue
		
		for col_index in row.size():
			var cell_value = row[col_index]
			var world_position = offset + Vector2i(col_index, row_index)
			if cell_value != DungeonGenerator.Tile.EMPTY:
				positions.append(world_position)
			else:
				others.append(world_position)
	
	return [positions, others]

func _is_valid_map_layer(map_layer: TileMapLayer) -> bool:
	if not map_layer:
		push_error("Map layer is missing")
		return false
	
	if not map_layer.tile_set:
		push_error("Tile set is missing")
		return false
	
	return true


func create_test_grid(width: int, height: int) -> Array:
	var grid_data: Array = []
	grid_data.resize(height)
	
	for row_index in height:
		var row: Array = []
		row.resize(width)
		
		for col_index in width:
			row[col_index] = 1
		
		grid_data[row_index] = row
	
	return grid_data

func test_small_grid(map_layer: TileMapLayer, wall_layer: TileMapLayer) -> void:
	var small_grid = create_test_grid(10, 10)
	build_from_grid(map_layer, wall_layer, small_grid, Vector2i(-5, -5))

func test_medium_grid(map_layer: TileMapLayer, wall_layer: TileMapLayer) -> void:
	var medium_grid = create_test_grid(50, 50)
	build_from_grid(map_layer, wall_layer, medium_grid, Vector2i(-25, -25))

func test_large_grid(map_layer: TileMapLayer, wall_layer: TileMapLayer) -> void:
	var large_grid = create_test_grid(100, 100)
	build_from_grid(map_layer, wall_layer, large_grid, Vector2i(-50, -50))

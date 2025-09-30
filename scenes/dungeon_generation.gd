extends Node2D
# Godot 4 GDScript — simple dungeon generator (drunkard walk)
# Drop onto a Node2D and run the scene.

@export var map_width: int = 11
@export var map_height: int = 11
@export var tile_size: int = 12
@export var target_floor_percent: float = 0.40  # how much of the map should be floor (0.0 - 1.0)
@export var max_walkers: int = 3                # number of simultaneous walkers (1 = single drunkard)
@export var chance_to_turn: float = 0.20
@export var chance_to_spawn_walker: float = 0.05
@export var chance_to_die: float = 0.03
@export var dungeon_seed: int = -1                      # -1 -> randomized

enum GROUND_TYPES {EMPTY, FLOOR, WALL}

var rng: RandomNumberGenerator
var grid: Array = []

class Walker:
	var pos: Vector2
	var dir: Vector2

	func _init(p: Vector2, d: Vector2):
		pos = p
		dir = d

var walkers: Array[Walker] = []

func get_random_dir() -> Vector2:
	var dirs : Array[Vector2] = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
	var n : int = rng.randi_range(0, 3)
	return dirs[n]

func get_random_new_dir(d: Vector2) -> Vector2:
	var dirs : Array[Vector2] = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
	dirs.erase(d)
	var n : int = rng.randi_range(0, 2)
	return dirs[n]

func _ready():
	rng = RandomNumberGenerator.new()
	if dungeon_seed == -1:
		rng.randomize()
	else:
		rng.seed = dungeon_seed

	_init_grid()
	_generate_drunkard_map()
	_print_ascii_map()
	# update()  # force redraw
	
func _init_grid():
	grid.clear()
	for y in map_height:
		var row: Array = []
		for x in map_width:
			row.append(GROUND_TYPES.EMPTY)
		grid.append(row)

func _generate_drunkard_map():
	walkers.clear()
	
	var origin: Vector2 = Vector2(map_width / 2, map_height / 2)
	walkers.append(Walker.new(origin, get_random_dir()))
	
	var floor_count: int = 0
	var target_floor := int(round(target_floor_percent * map_width * map_height))
	if target_floor < 1:
		target_floor = 1
		
	print("Starting, target_floor = ", str(target_floor))
	
	for iter in range(1000):
		for walker in walkers:
			grid[int(walker.pos.x)][int(walker.pos.y)] = GROUND_TYPES.FLOOR
			floor_count += 1
			
			walker.pos.x = clamp(walker.pos.x + walker.dir.x, 1, map_width-2)
			walker.pos.y = clamp(walker.pos.y + walker.dir.y, 1, map_height-2)
			
			if rng.randf() < chance_to_turn:
				walker.dir = get_random_new_dir(walker.dir)
				
			if walkers.size() < max_walkers and rng.randf() < chance_to_spawn_walker:
				walkers.append(Walker.new(walker.pos, get_random_new_dir(walker.dir)))
			
			if walkers.size() > 1 and rng.randf() < chance_to_die:
				walkers.erase(walker)
				
		if floor_count >= target_floor:
			break


func _print_ascii_map():
	var output := ""
	for y in map_height:
		output = ""
		for x in map_width:
			match grid[y][x]:
				GROUND_TYPES.FLOOR:
					output += "."
				GROUND_TYPES.WALL:
					output += "#"
				GROUND_TYPES.EMPTY:
					output += " "
		print(output)

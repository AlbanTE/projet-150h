# TinyKeep-style dungeon pipeline (Delaunay + spawns/objects)
# Drop on a Node2D in Godot 4.x
extends DungeonGenerator
class_name TinyKeepDungeon


# --- Tunables (export for quick iteration) ---
@export var cell_count: int = 50
@export var map_tiles_w: int = 96
@export var map_tiles_h: int = 96
@export var tile_size: int = 6
@export var min_room_size: int = 2
@export var max_room_size: int = 8
@export var normal_bias: float = 0.8
@export var separation_iters: int = 100
@export var extra_edge_chance: float = 0.25
@export var room_area_threshold: int = 6
@export var carve_width: int = 1
@export var draw_grid_offset: Vector2 = Vector2.ZERO
@export var min_room_count: int = 8

# --- Spawn/Object Parameters ---
@export var chest_number_chance: Array = [0.2, 0.5, 0.9, 1] # 1, 2, 3 et 4 objets
@export var safe_EMPTY_margin: int = 1   # min distance from EMPTY for objects/spawns

class Cell:
	var rect: Rect2
	var id: int = -1
	func _init(r: Rect2, id_=-1):
		rect = r
		id = id_

var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var cells: Array = []
var rooms: Array = []
var edges: Array = []
var final_edges: Array = []

# Spawns/Objects
var player_room_idx: int
var exit_room_idx: int
var object_positions: Array = []
var player_pos: Vector2
var exit_pos: Vector2

func generate_dungeon(_seed) -> Array:
	if _seed == -1:
		rng.randomize()
	else:
		rng.seed = _seed
		seed(_seed)

	_generate_cells()
	_separate_cells()
	_fill_tile_map_from_cells()
	_select_rooms()
	_build_graph_delaunay()
	_build_mst_and_add_loops()
	_carve_corridors()
	_clean_lone_walls()
	_place_spawns_and_objects()
	
	return map_tiles

# --- Dungeon Generation Steps ---------------------------------------------
func _generate_cells():
	cells.clear()
	var padding = max_room_size * 2
	var area_w = map_tiles_w - padding * 2
	var area_h = map_tiles_h - padding * 2
	if area_w < 10: area_w = map_tiles_w
	if area_h < 10: area_h = map_tiles_h

	for i in range(cell_count):
		var w = _biased_random_size(min_room_size, max_room_size)
		var h = _biased_random_size(min_room_size, max_room_size)
		var x = rng.randi_range(padding, padding + area_w - w)
		var y = rng.randi_range(padding, padding + area_h - h)
		cells.append(Cell.new(Rect2(x, y, w, h), i))

func _biased_random_size(min_val:int, max_val:int) -> int:
	var u1 = rng.randf()
	var u2 = rng.randf()
	var z = sqrt(-2.0 * log(max(u1, 1e-9))) * cos(2.0 * PI * u2)
	var z01 = 0.5 * (1.0 + (erf_approx(z/2.0)))
	var biased = pow(z01, normal_bias)
	return clamp(int(round(lerp(min_val, max_val, biased))), min_val, max_val)

func erf_approx(x:float) -> float:
	var t = 1.0 / (1.0 + 0.5 * abs(x))
	var tau = t * exp(-x*x -1.26551223 + 1.00002368*t +0.37409196*t*t +0.09678418*pow(t,3) -0.18628806*pow(t,4)+0.27886807*pow(t,5)-1.13520398*pow(t,6)+1.48851587*pow(t,7)-0.82215223*pow(t,8)+0.17087277*pow(t,9))
	var _sign = 1 if x>=0 else -1
	return _sign*(1.0 - tau)

func _separate_cells():
	for iter in range(separation_iters):
		var moved = false
		for i in range(cells.size()):
			for j in range(i+1, cells.size()):
				var a = cells[i]
				var b = cells[j]
				if a.rect.intersects(b.rect):
					var overlap = _rect_overlap(a.rect, b.rect)
					var push = Vector2.ZERO
					if abs(overlap.x) < abs(overlap.y):
						push.x = overlap.x/2.0
					else:
						push.y = overlap.y/2.0
					push += Vector2(rng.randf_range(-0.2,0.2), rng.randf_range(-0.2,0.2))
					a.rect.position -= push
					b.rect.position += push
					moved = true
		for c in cells:
			c.rect.position.x = clamp(c.rect.position.x, 1, map_tiles_w - c.rect.size.x -2)
			c.rect.position.y = clamp(c.rect.position.y, 1, map_tiles_h - c.rect.size.y -2)
		if not moved: break

func _rect_overlap(a:Rect2, b:Rect2) -> Vector2:
	var ox = 0.0
	var oy = 0.0
	if a.position.x+a.size.x > b.position.x and b.position.x+b.size.x > a.position.x:
		var overlap_x = min(a.position.x+a.size.x, b.position.x+b.size.x) - max(a.position.x, b.position.x)
		var signx = 1 if (a.position.x + a.size.x*0.5 - (b.position.x + b.size.x*0.5)) >=0 else -1
		ox = overlap_x * signx
	if a.position.y+a.size.y > b.position.y and b.position.y+b.size.y > a.position.y:
		var overlap_y = min(a.position.y+a.size.y, b.position.y+b.size.y) - max(a.position.y, b.position.y)
		var signy = 1 if (a.position.y + a.size.y*0.5 - (b.position.y + b.size.y*0.5)) >=0 else -1
		oy = overlap_y * signy
	return Vector2(ox, oy)

func _fill_tile_map_from_cells():
	map_tiles.clear()
	for y in range(map_tiles_h):
		var row:Array=[]
		for x in range(map_tiles_w):
			row.append(Tile.EMPTY)
		map_tiles.append(row)
	for c in cells:
		var x0 = int(round(c.rect.position.x))
		var y0 = int(round(c.rect.position.y))
		var w = int(round(c.rect.size.x))
		var h = int(round(c.rect.size.y))
		x0 = clamp(x0,1,map_tiles_w-2)
		y0 = clamp(y0,1,map_tiles_h-2)
		w = clamp(w,1,map_tiles_w-x0-1)
		h = clamp(h,1,map_tiles_h-y0-1)
		for yy in range(y0, y0+h):
			for xx in range(x0, x0+w):
				map_tiles[yy][xx]=Tile.ROOM

func _select_rooms():
	rooms.clear()
	for c in cells:
		if int(round(c.rect.size.x * c.rect.size.y)) >= room_area_threshold:
			rooms.append(c)
	if rooms.size() < min_room_count:
		cells.sort_custom(Callable(self,"_cell_area_sort"))
		var idx = 0
		while rooms.size() < min_room_count and idx<cells.size():
			if not rooms.has(cells[idx]):
				rooms.append(cells[idx])
			idx += 1

func _cell_area_sort(a:Cell,b:Cell) -> bool:
	return (a.rect.size.x*a.rect.size.y) > (b.rect.size.x*b.rect.size.y)

# --- Delaunay Graph ---
func _build_graph_delaunay():
	edges.clear()
	if rooms.size()<2: return

	var centers:Array=[]
	var center_to_idx:Dictionary={}
	for i in range(rooms.size()):
		var cpos = rooms[i].rect.position + rooms[i].rect.size*0.5
		centers.append(cpos)
		center_to_idx["%f_%f" % [cpos.x,cpos.y]] = i

	var points:PackedVector2Array=PackedVector2Array()
	for p in centers: points.append(p)

	var delaunay=Delaunay.new()
	delaunay.set_rectangle(Rect2(Vector2.ZERO, Vector2(map_tiles_w,map_tiles_h)))
	delaunay.points=points
	var triangulation:Array=delaunay.triangulate()
	delaunay.remove_border_triangles(triangulation)

	var seen:Dictionary={}
	for tri in triangulation:
		var verts=[tri.a, tri.b, tri.c]
		for i in range(3):
			var pa=verts[i]
			var pb=verts[(i+1)%3]
			var ka="%f_%f" % [pa.x,pa.y]
			var kb="%f_%f" % [pb.x,pb.y]
			if not center_to_idx.has(ka) or not center_to_idx.has(kb):
				continue
			var a_idx=int(center_to_idx[ka])
			var b_idx=int(center_to_idx[kb])
			var key = str(min(a_idx,b_idx))+"_"+str(max(a_idx,b_idx))
			if not seen.has(key):
				seen[key]=true
				var dist=centers[a_idx].distance_to(centers[b_idx])
				edges.append({"a":a_idx,"b":b_idx,"dist":dist})

func _dict_dist_sort(a,b) -> bool:
	return a["dist"]<b["dist"]

# --- MST + loops ---
func _build_mst_and_add_loops():
	final_edges.clear()
	edges.sort_custom(Callable(self,"_edge_dist_sort"))
	var uf=_UnionFind.new(rooms.size())
	for e in edges:
		if uf.find(e["a"])!=uf.find(e["b"]):
			uf.union(e["a"],e["b"])
			final_edges.append(e)
	var remaining:Array=[]
	for e in edges:
		var found=false
		for fe in final_edges:
			if fe["a"]==e["a"] and fe["b"]==e["b"]:
				found=true
				break
		if not found: remaining.append(e)
	for e in remaining:
		if rng.randf()<extra_edge_chance:
			final_edges.append(e)

func _edge_dist_sort(a,b) -> bool:
	return a["dist"]<b["dist"]

# --- Corridors ---
func _carve_corridors():
	var centers:Array=[]
	for r in rooms:
		centers.append(Vector2(int(round(r.rect.position.x+r.rect.size.x*0.5)), int(round(r.rect.position.y+r.rect.size.y*0.5))))

	for r in rooms:
		var x0=int(round(r.rect.position.x))
		var y0=int(round(r.rect.position.y))
		var w=int(round(r.rect.size.x))
		var h=int(round(r.rect.size.y))
		for yy in range(y0,y0+h):
			for xx in range(x0,x0+w):
				if xx>=0 and xx<map_tiles_w and yy>=0 and yy<map_tiles_h:
					map_tiles[yy][xx]=Tile.ROOM

	for e in final_edges:
		var pa=centers[e["a"]]
		var pb=centers[e["b"]]
		if rng.randf()<0.5:
			_carve_h_then_v(pa,pb)
		else:
			_carve_v_then_h(pa,pb)

func _carve_h_then_v(a,b): _carve_line(Vector2(a.x,a.y),Vector2(b.x,a.y));_carve_line(Vector2(b.x,a.y),Vector2(b.x,b.y))
func _carve_v_then_h(a,b): _carve_line(Vector2(a.x,a.y),Vector2(a.x,b.y));_carve_line(Vector2(a.x,b.y),Vector2(b.x,b.y))
func _carve_line(a,b):
	var x0=int(a.x); var y0=int(a.y)
	var x1=int(b.x); var y1=int(b.y)
	var dx=abs(x1-x0); var dy=abs(y1-y0)
	var sx=1 if x0<x1 else -1
	var sy=1 if y0<y1 else -1
	var err=dx-dy
	while true:
		_carve_wide_at(x0,y0)
		if x0==x1 and y0==y1: break
		var e2=2*err
		if e2>-dy: err-=dy; x0+=sx
		if e2<dx: err+=dx; y0+=sy

func _carve_wide_at(cx:int,cy:int):
	for oy in range(-carve_width,carve_width+1):
		for ox in range(-carve_width,carve_width+1):
			var tx=cx+ox
			var ty=cy+oy
			if tx>=0 and tx<map_tiles_w and ty>=0 and ty<map_tiles_h:
				if map_tiles[ty][tx]==Tile.EMPTY:
					map_tiles[ty][tx]=Tile.CORRIDOR

func _place_spawns_and_objects():
	# Player room near center
	var center=Vector2(map_tiles_w/2.,map_tiles_h/2.)
	var best_idx=0
	var best_dist=INF
	for i in range(rooms.size()):
		var rc=rooms[i].rect.position + rooms[i].rect.size*0.5
		var d=center.distance_to(rc)
		if d<best_dist:
			best_dist=d
			best_idx=i
	player_room_idx=best_idx
	player_pos=_pick_room_tile(rooms[player_room_idx])
	map_tiles[player_pos.y][player_pos.x] = Tile.PLAYER

	# Exit room farthest from player
	var player_room_center: Vector2 = rooms[player_room_idx].rect.position + rooms[player_room_idx].rect.size*0.5
	exit_room_idx=player_room_idx
	var max_d=-1
	for i in range(rooms.size()):
		var rc=rooms[i].rect.position + rooms[i].rect.size*0.5
		var d=player_room_center.distance_to(rc)
		if d>max_d:
			max_d=d
			exit_room_idx=i
	exit_pos=_pick_room_tile(rooms[exit_room_idx])
	map_tiles[exit_pos.y][exit_pos.x] = Tile.EXIT

	# Object/chest spawns
	var number_of_chest: int = 0
	var r = rng.randf()
	for i in range(chest_number_chance.size()):
		if r <= chest_number_chance[i]:
			number_of_chest = i+1
			break
			
	print("Number of objects: ", number_of_chest)
	
	# Place objects in rooms
	var available_rooms: Array = range(rooms.size())
	available_rooms.erase(player_room_idx)
	available_rooms.erase(exit_room_idx)
	for obj in number_of_chest:
		var obj_room = available_rooms.pick_random()
		available_rooms.erase(obj_room)
		var object_pos = _pick_room_tile(rooms[obj_room])
		map_tiles[object_pos.y][object_pos.x] = Tile.OBJECT
		print("Object in room: ", obj_room)


func _pick_room_tile(room:Cell) -> Vector2:
	var candidates:Array=[]
	var x0=int(room.rect.position.x)
	var y0=int(room.rect.position.y)
	var w=int(room.rect.size.x)
	var h=int(room.rect.size.y)
	for yy in range(y0+safe_EMPTY_margin,y0+h-safe_EMPTY_margin):
		for xx in range(x0+safe_EMPTY_margin,x0+w-safe_EMPTY_margin):
			if xx>=0 and xx<map_tiles_w and yy>=0 and yy<map_tiles_h:
				if map_tiles[yy][xx]==Tile.ROOM:
					candidates.append(Vector2(xx,yy))

	if candidates.size()>0:
		return candidates[rng.randi_range(0,candidates.size()-1)]

	print("Pick room fallback")
	# fallback: search brute-force for ANY valid ROOM tile in this room
	for yy in range(y0,y0+h):
		for xx in range(x0,x0+w):
			if xx>=0 and xx<map_tiles_w and yy>=0 and yy<map_tiles_h:
				if map_tiles[yy][xx]==Tile.ROOM:
					return Vector2(xx,yy)

	# final fallback: center
	return Vector2(clamp(x0+w/2.,0,map_tiles_w-1), clamp(y0+h/2.,0,map_tiles_h-1))

func _clean_lone_walls():
	for y in range(1, map_tiles.size() - 1):
		for x in range(1, map_tiles[y].size() - 1):
			if map_tiles[y][x] != Tile.EMPTY:
				continue
			
			# Get all neighbors
			var up         = map_tiles[y - 1][x]
			var down       = map_tiles[y + 1][x]
			var left       = map_tiles[y][x - 1]
			var right      = map_tiles[y][x + 1]
			var up_left    = map_tiles[y - 1][x - 1]
			var up_right   = map_tiles[y - 1][x + 1]
			var down_left  = map_tiles[y + 1][x - 1]
			var down_right = map_tiles[y + 1][x + 1]
			
			var empty_voisins: int = 0 
			for dir in [left, right, up, down, up_left, up_right, down_left, down_right]: 
				if dir == Tile.EMPTY: 
					empty_voisins += 1
			
			if right == Tile.EMPTY and down_right == Tile.EMPTY and empty_voisins == 2:
				map_tiles[y][x] = Tile.ROOM
			if right == Tile.EMPTY and up_right == Tile.EMPTY and empty_voisins == 2:
				map_tiles[y][x] = Tile.ROOM
			if right == Tile.EMPTY and up_right == Tile.EMPTY and left == Tile.EMPTY and empty_voisins == 3:
				map_tiles[y][x] = Tile.ROOM
			if right == Tile.EMPTY and down_right == Tile.EMPTY and left == Tile.EMPTY and empty_voisins == 3:
				map_tiles[y][x] = Tile.ROOM
			if left == Tile.EMPTY and up_left == Tile.EMPTY and empty_voisins == 2:
				map_tiles[y][x] = Tile.ROOM
			if left == Tile.EMPTY and down_left == Tile.EMPTY and empty_voisins == 2:
				map_tiles[y][x] = Tile.ROOM
			if left == Tile.EMPTY and down_left == Tile.EMPTY and right == Tile.EMPTY and empty_voisins == 3:
				map_tiles[y][x] = Tile.ROOM
			if left == Tile.EMPTY and up_left == Tile.EMPTY and right == Tile.EMPTY and empty_voisins == 3:
				map_tiles[y][x] = Tile.ROOM
				
	for y in range(1, map_tiles.size() - 1):
		for x in range(1, map_tiles[y].size() - 1):
			if map_tiles[y][x] != Tile.EMPTY:
				continue
			
			# Get all neighbors
			var up         = map_tiles[y - 1][x]
			var down       = map_tiles[y + 1][x]
			var left       = map_tiles[y][x - 1]
			var right      = map_tiles[y][x + 1]
			var up_left    = map_tiles[y - 1][x - 1]
			var up_right   = map_tiles[y - 1][x + 1]
			var down_left  = map_tiles[y + 1][x - 1]
			var down_right = map_tiles[y + 1][x + 1]
			
			var empty_voisins: int = 0 
			for dir in [left, right, up, down, up_left, up_right, down_left, down_right]: 
				if dir == Tile.EMPTY: 
					empty_voisins += 1
			if empty_voisins == 0:
				map_tiles[y][x] = Tile.ROOM


# --- Union-Find ---
class _UnionFind:
	var parent:Array
	func _init(n:int):
		parent=[]
		for i in range(n): parent.append(i)
	func find(a:int) -> int:
		if parent[a]!=a: parent[a]=find(parent[a])
		return parent[a]
	func union(a:int,b:int) -> void:
		var pa=find(a)
		var pb=find(b)
		if pa==pb: return
		parent[pa]=pb

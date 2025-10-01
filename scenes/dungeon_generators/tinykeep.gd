# TinyKeep-style dungeon pipeline (Delaunay)
# Drop on a Node2D in Godot 4.x
extends Node2D

# --- Tunables (export for quick iteration) ---
@export var _seed: int = -1
@export var cell_count: int = 150            # more cells → more complexity, tighter grid
@export var map_tiles_w: int = 96
@export var map_tiles_h: int = 96
@export var tile_size: int = 6
@export var min_room_size: int = 2           # allow tiny rooms
@export var max_room_size: int = 8           # keep rooms small-ish
@export var normal_bias: float = 0.8         # skew heavily toward small rooms
@export var separation_iters: int = 100      # push cells apart for denser packing
@export var extra_edge_chance: float = 0.25  # add back more edges for loops
@export var room_area_threshold: int = 6     # classify more small cells as "rooms"
@export var carve_width: int = 1             # corridor half-width in tiles
@export var draw_grid_offset: Vector2 = Vector2.ZERO

# --- Internal stuff ---
enum Tile { EMPTY, ROOM, CORRIDOR }

class Cell:
	var rect: Rect2       # position & size in tile coordinates (floats during separation)
	var id: int = -1
	func _init(r: Rect2, id_ = -1):
		rect = r
		id = id_

var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var cells: Array = []
var rooms: Array = []      # subset of cells considered rooms
var map_tiles: Array = []  # 2D array of Tile
var edges: Array = []      # Array[Dictionary{a:int,b:int,dist:float}]
var final_edges: Array = [] # edges used for corridors

# --- Startup ---------------------------------------------------------------
func _ready():
	# seed RNG properly
	if _seed == -1:
		rng.randomize()
	else:
		rng.seed = _seed

	_generate_cells()
	_separate_cells()
	_fill_tile_map_from_cells()  # we need this to pick rooms based on tile area
	_select_rooms()
	_build_graph_delaunay()     # use Delaunay triangulation here
	_build_mst_and_add_loops()
	# (no need for extra connectivity patch; Delaunay->MST should connect all)
	_carve_corridors()
	_print_ascii_map()
	queue_redraw()

func _draw():
	# draw tiles
	for y in range(map_tiles.size()):
		for x in range(map_tiles[y].size()):
			var t = map_tiles[y][x]
			var px = (x * tile_size) + draw_grid_offset.x
			var py = (y * tile_size) + draw_grid_offset.y
			var r = Rect2(px, py, tile_size - 1, tile_size - 1)
			if t == Tile.ROOM:
				draw_rect(r, Color(0.85, 0.85, 0.8))
			elif t == Tile.CORRIDOR:
				draw_rect(r, Color(0.9, 0.75, 0.6))
	# draw map border (optional)
	draw_rect(Rect2(draw_grid_offset, Vector2(map_tiles_w * tile_size, map_tiles_h * tile_size)), Color(1,1,1,0), false)


# --- Step 1: generate rectangle cells with biased size distribution -----------
func _generate_cells():
	cells.clear()
	# pick a center area inside the tile map so rectangles remain inside after separation
	var padding = max_room_size * 2
	var area_w = map_tiles_w - padding * 2
	var area_h = map_tiles_h - padding * 2
	if area_w < 10:
		area_w = map_tiles_w
	if area_h < 10:
		area_h = map_tiles_h

	for i in range(cell_count):
		var w = _biased_random_size(min_room_size, max_room_size)
		var h = _biased_random_size(min_room_size, max_room_size)
		# place randomly inside area
		var x = rng.randi_range(padding, padding + area_w - w)
		var y = rng.randi_range(padding, padding + area_h - h)
		var r = Rect2(x, y, w, h)
		var c = Cell.new(r, i)
		cells.append(c)


# Box-Muller normal-ish biased distribution, then clamp
func _biased_random_size(min_val: int, max_val: int) -> int:
	# produce a gaussian-like sample centered near lower values, then bias
	# Box-Muller
	var u1 = rng.randf()
	var u2 = rng.randf()
	var z = sqrt(-2.0 * log(max(u1, 1e-9))) * cos(2.0 * PI * u2)
	# normalize z to 0..1 via erf-ish mapping (approx)
	var z01 = 0.5 * (1.0 + (erf_approx(z / 2.0))) # rough map
	# apply bias (exponent) to skew toward smaller sizes
	var biased = pow(z01, normal_bias)
	var size = int(round(lerp(min_val, max_val, biased)))
	return clamp(size, min_val, max_val)


# tiny erf approximation used to map gaussian to 0..1
func erf_approx(x: float) -> float:
	# Abramowitz & Stegun approximation (short)
	var t = 1.0 / (1.0 + 0.5 * abs(x))
	var tau = t * exp(-x*x - 1.26551223 + 1.00002368 * t + 0.37409196 * t*t + 0.09678418 * pow(t,3) - 0.18628806 * pow(t,4) + 0.27886807 * pow(t,5) - 1.13520398 * pow(t,6) + 1.48851587 * pow(t,7) - 0.82215223 * pow(t,8) + 0.17087277 * pow(t,9))
	var _sign = 1 if (x >= 0) else -1
	return _sign * (1.0 - tau)


# --- Step 2/3 separation: push overlapping rects apart -----------------------
func _separate_cells():
	# iterative separation: for many iterations, for each pair with overlap push them away
	for iter in range(separation_iters):
		var moved = false
		for i in range(cells.size()):
			for j in range(i + 1, cells.size()):
				var a = cells[i]
				var b = cells[j]
				if a.rect.intersects(b.rect):
					# compute smallest push vector
					var overlap = _rect_overlap(a.rect, b.rect)
					# push along the larger overlap axis
					var push = Vector2.ZERO
					if abs(overlap.x) < abs(overlap.y):
						# push on x
						push.x = overlap.x / 2.0
					else:
						push.y = overlap.y / 2.0
					# random jitter so things don't get stuck
					push += Vector2(rng.randf_range(-0.2, 0.2), rng.randf_range(-0.2, 0.2))
					a.rect.position += -push
					b.rect.position += push
					moved = true
		# clamp to map bounds
		for c in cells:
			c.rect.position.x = clamp(c.rect.position.x, 1, map_tiles_w - c.rect.size.x - 2)
			c.rect.position.y = clamp(c.rect.position.y, 1, map_tiles_h - c.rect.size.y - 2)
		# optional early break if nothing moved much
		if not moved:
			break


# calculates signed overlap vector, positive means a is left/top of b and overlap amount (signed)
func _rect_overlap(a: Rect2, b: Rect2) -> Vector2:
	var ax1 = a.position.x
	var ay1 = a.position.y
	var ax2 = a.position.x + a.size.x
	var ay2 = a.position.y + a.size.y
	var bx1 = b.position.x
	var by1 = b.position.y
	var bx2 = b.position.x + b.size.x
	var by2 = b.position.y + b.size.y
	var ox = 0.0
	if ax2 > bx1 and bx2 > ax1:
		# overlap amount in x; positive means push right for a
		var overlap_x = min(ax2, bx2) - max(ax1, bx1)
		var _signx = 1 if ((a.position.x + a.size.x * 0.5) - (b.position.x + b.size.x * 0.5)) >= 0 else -1
		ox = overlap_x * _signx
	var oy = 0.0
	if ay2 > by1 and by2 > ay1:
		var overlap_y = min(ay2, by2) - max(ay1, by1)
		var _signy = 1 if ((a.position.y + a.size.y * 0.5) - (b.position.y + b.size.y * 0.5)) >= 0 else -1
		oy = overlap_y * _signy
	return Vector2(ox, oy)


# --- Step 4: convert cells to tile map -------------------------------------
func _fill_tile_map_from_cells():
	# init empty map
	map_tiles.clear()
	for y in range(map_tiles_h):
		var row: Array = []
		for x in range(map_tiles_w):
			row.append(Tile.EMPTY)
		map_tiles.append(row)
	# paint every cell as ROOM candidate in tile map
	for c in cells:
		# round positions to ints
		var x0 = int(round(c.rect.position.x))
		var y0 = int(round(c.rect.position.y))
		var w = int(round(c.rect.size.x))
		var h = int(round(c.rect.size.y))
		# clamp
		x0 = clamp(x0, 1, map_tiles_w - 2)
		y0 = clamp(y0, 1, map_tiles_h - 2)
		w = clamp(w, 1, map_tiles_w - x0 - 1)
		h = clamp(h, 1, map_tiles_h - y0 - 1)
		for yy in range(y0, y0 + h):
			for xx in range(x0, x0 + w):
				map_tiles[yy][xx] = Tile.ROOM


# --- Step 5: pick rooms from larger cells ----------------------------------
@export var min_room_count: int = 8

func _select_rooms():
	rooms.clear()
	for c in cells:
		var w = int(round(c.rect.size.x))
		var h = int(round(c.rect.size.y))
		if w * h >= room_area_threshold:
			rooms.append(c)
	# fallback: if too few rooms, pick largest ones to reach minimum
	if rooms.size() < min_room_count:
		cells.sort_custom(Callable(self, "_cell_area_sort"))
		var idx = 0
		while rooms.size() < min_room_count and idx < cells.size():
			if not rooms.has(cells[idx]):
				rooms.append(cells[idx])
			idx += 1

func _cell_area_sort(a: Cell, b: Cell) -> bool:
	var aa = a.rect.size.x * a.rect.size.y
	var bb = b.rect.size.x * b.rect.size.y
	# return true if a should come before b (descending)
	return aa > bb


# --- Step 6: graph from room centers using Delaunay triangulation ----------
func _build_graph_delaunay():
	edges.clear()
	if rooms.size() < 2:
		return

	# build centers and map center->room index (use string key for safety)
	var centers: Array = []
	var center_to_idx: Dictionary = {}
	for i in range(rooms.size()):
		var cpos: Vector2 = rooms[i].rect.position + rooms[i].rect.size * 0.5
		centers.append(cpos)
		center_to_idx["%f_%f" % [cpos.x, cpos.y]] = i

	# prepare PackedVector2Array for Delaunay
	var points: PackedVector2Array = PackedVector2Array()
	for p in centers:
		points.append(p)

	# create Delaunay, set rectangle and points
	var delaunay = Delaunay.new()
	# set a working rectangle slightly larger than map
	var work_rect: Rect2 = Rect2(Vector2.ZERO, Vector2(map_tiles_w, map_tiles_h))
	delaunay.set_rectangle(work_rect)
	delaunay.points = points

	var triangulation: Array = delaunay.triangulate()
	# remove border triangles that use super-rect corners
	delaunay.remove_border_triangles(triangulation)

	# collect edges from triangles (deduplicated)
	var seen: Dictionary = {}
	for tri in triangulation:
		var va: Vector2 = tri.a
		var vb: Vector2 = tri.b
		var vc: Vector2 = tri.c
		var pairs = [ [va, vb], [vb, vc], [vc, va] ]
		for pair in pairs:
			var pa: Vector2 = pair[0]
			var pb: Vector2 = pair[1]
			var ka = "%f_%f" % [pa.x, pa.y]
			var kb = "%f_%f" % [pb.x, pb.y]
			if not center_to_idx.has(ka) or not center_to_idx.has(kb):
				continue
			var a_idx: int = int(center_to_idx[ka])
			var b_idx: int = int(center_to_idx[kb])
			var a_i = min(a_idx, b_idx)
			var b_i = max(a_idx, b_idx)
			var key = str(a_i) + "_" + str(b_i)
			if not seen.has(key):
				seen[key] = true
				var dist = centers[a_i].distance_to(centers[b_i])
				edges.append({"a": a_i, "b": b_i, "dist": dist})


# comparator for sorting dists (returns bool a before b)
func _dict_dist_sort(a, b) -> bool:
	return a["dist"] < b["dist"]


# --- Step 7+8: MST (Kruskal) + add some extra edges -------------------------
func _build_mst_and_add_loops():
	final_edges.clear()
	# Kruskal (sort edges ascending)
	edges.sort_custom(Callable(self, "_edge_dist_sort"))
	var uf = _UnionFind.new(rooms.size())
	for e in edges:
		if uf.find(e["a"]) != uf.find(e["b"]):
			uf.union(e["a"], e["b"])
			final_edges.append(e)
	# keep the remaining edges as potential extras
	var remaining: Array = []
	for e in edges:
		# if not already in final_edges
		var found = false
		for fe in final_edges:
			if fe["a"] == e["a"] and fe["b"] == e["b"]:
				found = true
				break
		if not found:
			remaining.append(e)
	# randomly re-add some remaining edges
	for e in remaining:
		if rng.randf() < extra_edge_chance:
			final_edges.append(e)

func _edge_dist_sort(a, b) -> bool:
	return a["dist"] < b["dist"]


# --- Step 9: convert edges to corridors (L-shaped) -------------------------
func _carve_corridors():
	# carve corridors on map_tiles between room centers
	# Recompute centers (rounded ints)
	var centers: Array = []
	for r in rooms:
		centers.append(Vector2(int(round(r.rect.position.x + r.rect.size.x * 0.5)), int(round(r.rect.position.y + r.rect.size.y * 0.5))))

	# carve rooms again (ensure rooms remain)
	for r in rooms:
		var x0 = int(round(r.rect.position.x))
		var y0 = int(round(r.rect.position.y))
		var w = int(round(r.rect.size.x))
		var h = int(round(r.rect.size.y))
		for yy in range(y0, y0 + h):
			for xx in range(x0, x0 + w):
				# guard map bounds
				if yy >= 0 and yy < map_tiles_h and xx >= 0 and xx < map_tiles_w:
					map_tiles[yy][xx] = Tile.ROOM

	# carve corridors for each final edge
	for e in final_edges:
		var a = int(e["a"])
		var b = int(e["b"])
		var pa = centers[a]
		var pb = centers[b]
		# randomize L direction sometimes
		if rng.randf() < 0.5:
			_carve_h_then_v(pa, pb)
		else:
			_carve_v_then_h(pa, pb)


# carve horizontal then vertical
func _carve_h_then_v(a: Vector2, b: Vector2):
	_carve_line(Vector2(a.x, a.y), Vector2(b.x, a.y))
	_carve_line(Vector2(b.x, a.y), Vector2(b.x, b.y))


# carve vertical then horizontal
func _carve_v_then_h(a: Vector2, b: Vector2):
	_carve_line(Vector2(a.x, a.y), Vector2(a.x, b.y))
	_carve_line(Vector2(a.x, b.y), Vector2(b.x, b.y))


# carve a Bresenham-like line and optionally widen it
func _carve_line(a: Vector2, b: Vector2):
	var x0 = int(a.x); var y0 = int(a.y)
	var x1 = int(b.x); var y1 = int(b.y)
	var dx = abs(x1 - x0)
	var dy = abs(y1 - y0)
	var sx = 1 if (x0 < x1) else -1
	var sy = 1 if (y0 < y1) else -1
	var err = dx - dy
	while true:
		_carve_wide_at(x0, y0)
		if x0 == x1 and y0 == y1:
			break
		var e2 = 2 * err
		if e2 > -dy:
			err -= dy
			x0 += sx
		if e2 < dx:
			err += dx
			y0 += sy


# carve around tile with width
func _carve_wide_at(cx: int, cy: int):
	for oy in range(-carve_width, carve_width + 1):
		for ox in range(-carve_width, carve_width + 1):
			var tx = cx + ox
			var ty = cy + oy
			if tx >= 0 and tx < map_tiles_w and ty >= 0 and ty < map_tiles_h:
				# don't overwrite existing ROOM tiles
				if map_tiles[ty][tx] == Tile.EMPTY:
					map_tiles[ty][tx] = Tile.CORRIDOR


# --- ASCII output for debugging --------------------------------------------
func _print_ascii_map():
	var s = ""
	for y in range(map_tiles.size()):
		for x in range(map_tiles[y].size()):
			match map_tiles[y][x]:
				Tile.ROOM:
					s += "."
				Tile.CORRIDOR:
					s += "+"
				Tile.EMPTY:
					s += "#"
		s += "\n"
	print(s)


# --- Helper: Union-Find for Kruskal ----------------------------------------
class _UnionFind:
	var parent: Array
	func _init(n: int):
		parent = []
		for i in range(n):
			parent.append(i)
	func find(a: int) -> int:
		if parent[a] != a:
			parent[a] = find(parent[a])
		return parent[a]
	func union(a: int, b: int) -> void:
		var pa = find(a)
		var pb = find(b)
		if pa == pb: return
		parent[pa] = pb

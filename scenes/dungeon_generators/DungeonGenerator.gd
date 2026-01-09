# res://scenes/dungeon_generators/DungeonGenerator.gd
extends Resource
class_name DungeonGenerator

enum Tile { EMPTY, ROOM, CORRIDOR, PLAYER, EXIT, OBJECT }

var map_tiles: Array = []


func generate_dungeon(_seed: int) -> Array:
	push_error("generate_dungeon() not implemented in %s" % self)
	return []
	
func generate_boss_arena() -> Array:
	map_tiles.clear()
	var arena_width: int = 50
	var arena_height: int = 50
	var arena_radius: int = 20
	
	var center: Vector2 = Vector2(arena_height, arena_width) / 2
	
	for y in arena_height:
		var row: Array = []
		for x in arena_width:
			if Vector2(y, x) == (center - Vector2(arena_radius / 2, 0)):
				row.append(Tile.EXIT)
			elif Vector2(y, x) == (center + Vector2(arena_radius / 2, 0)):
				row.append(Tile.PLAYER)
			elif Vector2(y, x).distance_to(center) < arena_radius:
				row.append(Tile.ROOM)
			else:
				row.append(Tile.EMPTY)
		map_tiles.append(row)
	
	return map_tiles

# --- ASCII Debug ---
func _print_ascii_map():
	var s=""
	for y in range(map_tiles.size()):
		for x in range(map_tiles[y].size()):
			match map_tiles[y][x]:
				Tile.ROOM: s+="."
				Tile.CORRIDOR: s+="+"
				Tile.EMPTY: s+="#"
				Tile.PLAYER: s+="P"
				Tile.EXIT: s+="E"
				Tile.OBJECT: s+="O"
		s+="\n"
	print(s)

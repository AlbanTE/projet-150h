# res://scenes/dungeon_generators/DungeonGenerator.gd
extends Resource
class_name DungeonGenerator

enum Tile { EMPTY, ROOM, CORRIDOR, PLAYER, EXIT, OBJECT }

var map_tiles: Array = []


func generate_dungeon(_seed: int) -> Array:
	push_error("generate_dungeon() not implemented in %s" % self)
	return []

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

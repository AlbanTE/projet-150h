extends Node

@export var music_player : AudioStreamPlayer

# Etat actuel du jeu
# 1 -> Level 1
# 2 -> Level 1 Boss
# 3 -> Level 2
# 4 -> Level 2 Boss
var current_level : int

func _ready():
	current_level = AudioGlobal.current_level
	print("Init Music : " , current_level)
	
func _process(_delta: float) -> void:
	if current_level != AudioGlobal.current_level :
		current_level = AudioGlobal.current_level
		print("CALL SWITCH")
		update_music()

# Récupérer la track par le nom de l'audio stream Player
func update_music():
	if not music_player:
		push_error("Erreur Audio Player")
		return
	var current_level_music = str(current_level)
	print("Update Music : " , current_level_music)	
	music_player["parameters/switch_to_clip"] = current_level_music

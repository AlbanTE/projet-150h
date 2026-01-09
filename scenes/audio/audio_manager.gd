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
	
# Récupérer la track par le nom de l'audio stream Player
func update_music():
	print("Call Main -> Level changed -> UPDATE MUSIC")
	current_level = AudioGlobal.current_level
	# Récupérer le string associé au Stream Interactive
	var current_level_music = str(current_level)
	music_player["parameters/switch_to_clip"] = current_level_music
	
func pause_music():
	music_player.stream_paused = true

func resume_music():
	music_player.stream_paused = false

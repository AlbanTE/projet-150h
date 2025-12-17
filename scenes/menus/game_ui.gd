extends Control

var isRewardMenuOpen: bool = false
var isPauseMenuOpen: bool = false

var player: Player

func update_items():
	var inv_size: int = player.inventory_manager.inventory.size()
	for i in range(3):
		var item = player.inventory_manager.inventory[i] if i < inv_size else null
		var tex = get_node("GridContainer/Item" + str(i+1))
		tex.set_item(item)
			

func update_weapon():
	$ActiveWeapon/TextureRect.texture = player.weapon_component.current_weapon.sprite

func resume():
	$BlurAnimationPlayer.play_backwards("blur")
	get_tree().paused = false

func pause():
	get_tree().paused = true
	$BlurAnimationPlayer.play("blur")

func openPauseMenu():
	$MenuAnimationPlayer.play("pause")
	isPauseMenuOpen = true

func closePauseMenu():
	$MenuAnimationPlayer.play_backwards("pause")
	isPauseMenuOpen = false

func openRewardMenu():
	pause()
	isRewardMenuOpen = true
	$InGameMenu/Reward.generate_upgrade()
	$MenuAnimationPlayer.play("reward")

func closeRewardMenu():
	$MenuAnimationPlayer.play_backwards("reward")
	isRewardMenuOpen = false
	if not isPauseMenuOpen:
		resume()

func _ready() -> void:
	$InGameMenu/Reward.connect("close_reward_menu", closeRewardMenu)
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0] as Player
	else:
		push_error("No player found")
	
	update_items()

func process_input():
	if Input.is_action_just_pressed("escape"):
		if isRewardMenuOpen and isPauseMenuOpen:
			closePauseMenu()
		elif isPauseMenuOpen:
			closePauseMenu()
			resume()
		elif isRewardMenuOpen:
			openPauseMenu()
		else:
			pause()
			openPauseMenu()

func _process(_delta: float) -> void:
	process_input()


func _on_resume_button_pressed() -> void:
	closePauseMenu()
	if not isRewardMenuOpen:
		resume()


func _on_restart_button_pressed() -> void:
	closePauseMenu()
	resume()
	PlayerStats.reset()
	get_tree().reload_current_scene()


func _on_options_button_pressed() -> void:
	pass # Replace with function body.


func _on_quit_button_pressed() -> void:
	get_tree().quit()

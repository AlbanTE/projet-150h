extends Control
class_name GameUI

var isRewardMenuOpen: bool = false
var isPauseMenuOpen: bool = false
var isChooseMenuOpen: bool = false

var player: Player

func update_items():
	var inv_size: int = player.inventory_manager.inventory.size()
	for i in range(3):
		var item = player.inventory_manager.inventory[i] if i < inv_size else null
		var tex = get_node("GridContainer/Item" + str(i+1))
		tex.set_item(item, i+1)
			

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

func openChooseMenu(item: Item):
	pause()
	isChooseMenuOpen = true
	print("New item: ", item.item_name)
	$MenuAnimationPlayer.play("choosing_item")
	$InGameMenu/ChooseItem/ItemBox.set_item(item, 0)
	$InGameMenu/ChooseItem/ItemBox.replacing = true
	for i in range(3):
		var item_box = get_node("GridContainer/Item" + str(i+1))
		item_box.replacing = true

func closeChooseMenu():
	update_items()
	$InGameMenu/ChooseItem/ItemBox.replacing = false
	for i in range(3):
		var item_box = get_node("GridContainer/Item" + str(i+1))
		item_box.replacing = false
	$MenuAnimationPlayer.play_backwards("choosing_item")
	
	isChooseMenuOpen = false
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

	# Totalement statique
	if player and player.get("shield_instance"):
		var shield = player.shield_instance
		$SpellContainer/SpellBox1.set_spell(shield)
		$SpellContainer/Label1.text = '"' + str(get_action_key_string(shield.input_action)) + '"'
	
	if player and player.get("heal_instance"):
		var heal = player.heal_instance
		$SpellContainer/SpellBox2.set_spell(heal)
		$SpellContainer/Label2.text = '"' + str(get_action_key_string(heal.input_action)) + '"'
		
	if player and player.get("zoomies_instance"):
		var zoomies = player.zoomies_instance
		$SpellContainer/SpellBox3.set_spell(zoomies)
		$SpellContainer/Label3.text = '"' + str(get_action_key_string(zoomies.input_action)) + '"'


func get_action_key_string(action_name: String) -> String:
	var events = InputMap.action_get_events(action_name)
	if events.size() > 0:
		for event in events:
			if event is InputEventKey:
				return OS.get_keycode_string(event.physical_keycode if event.physical_keycode != 0 else event.keycode)
	return ""

func process_input():
	if Input.is_action_just_pressed("escape"):
		if (isRewardMenuOpen and isPauseMenuOpen) or (isChooseMenuOpen and isPauseMenuOpen):
			closePauseMenu()
		elif isPauseMenuOpen:
			closePauseMenu()
			resume()
		elif isRewardMenuOpen or isChooseMenuOpen:
			openPauseMenu()
		else:
			pause()
			openPauseMenu()

func _process(_delta: float) -> void:
	process_input()


func _on_resume_button_pressed() -> void:
	closePauseMenu()
	if not (isRewardMenuOpen or isChooseMenuOpen):
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

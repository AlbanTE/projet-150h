extends Control

var isRewardMenuOpen: bool = false
var isPauseMenuOpen: bool = false

func resume():
	get_tree().paused = false

func pause():
	get_tree().paused = true

func openPauseMenu():
	$AnimationPlayer.play("blurPause")
	isPauseMenuOpen = true

func closePauseMenu():
	$AnimationPlayer.play_backwards("blurPause")
	isPauseMenuOpen = false

func openRewardMenu():
	isRewardMenuOpen = true
	$InGameMenu/Reward.generate_upgrade()
	$AnimationPlayer.play("blurReward")

func closeRewardMenu():
	$AnimationPlayer.play_backwards("blurReward")
	isRewardMenuOpen = false

func _ready() -> void:
	$InGameMenu/Reward.connect("close_reward_menu", closeRewardMenu)

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

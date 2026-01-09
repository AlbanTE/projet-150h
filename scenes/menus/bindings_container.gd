extends VBoxContainer

# Map actions to their label nodes
@onready var action_labels := {
	"move_up": $MoveUPBinding/MoveUpButton/InputMoveUp,
	"move_down": $MoveDownBinding/MoveDownButton/InputMoveDown,
	"move_left": $MoveLeftBinding/MoveLeftButton/InputMoveLeft,
	"move_right": $MoveRightBinding/MoveRightButton/InputMoveRight,
	"trigger_weapon": $TriggerWeaponBinding/TriggerWeaponButton/InputTriggerWeapon,
	"switch_weapon": $SwitchWeaponBinding/SwitchWeaponButton/InputSwitchWeapon,
	"Shield_Key": $ShieldBinding/ShieldButton/InputShield,
	"Heal_Key": $HealBinding/HealButton/InputHeal,
	"Zoomies_Key": $ZoomiesBinding/ZoomiesButton/InputZoomies
}

var waiting_for_rebind := false
var action_to_rebind := ""

func _ready() -> void:
	update_all_labels()

# ---------- REBIND LOGIC ----------

func start_rebind(action_name: String) -> void:
	waiting_for_rebind = true
	action_to_rebind = action_name

	# Optional UI feedback
	action_labels[action_name].text = "Press a key..."

func _input(event: InputEvent) -> void:
	if not waiting_for_rebind:
		return

	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			cancel_rebind()
			return
		rebind_action(action_to_rebind, event)

	elif event is InputEventMouseButton and event.pressed:
		rebind_action(action_to_rebind, event)

	elif event is InputEventJoypadButton and event.pressed:
		rebind_action(action_to_rebind, event)

func cancel_rebind() -> void:
	update_label(action_to_rebind)
	waiting_for_rebind = false
	action_to_rebind = ""

func rebind_action(action_name: String, event: InputEvent) -> void:
	InputMap.action_erase_events(action_name)
	InputMap.action_add_event(action_name, event)

	waiting_for_rebind = false
	action_to_rebind = ""

	update_label(action_name)

# ---------- LABEL UPDATES ----------

func update_all_labels() -> void:
	for action in action_labels.keys():
		update_label(action)

func update_label(action_name: String) -> void:
	var events := InputMap.action_get_events(action_name)

	if events.is_empty():
		action_labels[action_name].text = "Unbound"
	else:
		action_labels[action_name].text = events[0].as_text()

# ---------- BUTTON SIGNALS ----------

func _on_move_up_button_pressed() -> void:
	start_rebind("move_up")

func _on_move_down_button_pressed() -> void:
	start_rebind("move_down")

func _on_move_left_button_pressed() -> void:
	start_rebind("move_left")

func _on_move_right_button_pressed() -> void:
	start_rebind("move_right")

func _on_trigger_weapon_button_pressed() -> void:
	start_rebind("trigger_weapon")

func _on_switch_weapon_button_pressed() -> void:
	start_rebind("switch_weapon")

func _on_shield_button_pressed() -> void:
	start_rebind("Shield_Key")

func _on_heal_button_pressed() -> void:
	start_rebind("Heal_Key")

func _on_zoomies_button_pressed() -> void:
	start_rebind("Zoomies_Key")

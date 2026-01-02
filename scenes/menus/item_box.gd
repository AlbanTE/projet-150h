extends Button

var item: Item
var item_slot: int = 0

var hover_cross: StyleBoxTexture
@export var paused: bool = false

var replacing: bool = false
signal replaced(slot)

func _ready() -> void:
	hover_cross = StyleBoxTexture.new()
	hover_cross.texture = preload("res://assets/UI/red_cross.png")
	

func _process(_delta: float) -> void:
	pass
	
func _draw():
	var normal_style = get_theme_stylebox("normal")
	if normal_style:
		normal_style.draw(get_canvas_item(), Rect2(Vector2.ZERO, size))
		
	if is_hovered() and item and replacing and not paused:
		hover_cross.draw(get_canvas_item(), Rect2(Vector2(16, 16), size - Vector2(32, 32)))

func set_item(it: Item, slot: int):
	item = it
	item_slot = slot
	if item:
		$TextureRect.texture = it.item_sprite
	else:
		$TextureRect.texture = null

func _make_custom_tooltip(_text: String) -> Control:
	if not item:
		return
	
	var panel = PanelContainer.new()
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	panel.add_child(margin)
	
	var label = RichTextLabel.new()
	label.custom_minimum_size.x = 300
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	label.fit_content = true
	label.bbcode_enabled = true
	label.add_theme_font_size_override("normal_font_size", 32)
	label.add_theme_font_size_override("bold_font_size", 48)
	label.text = "[color=magenta]" + item.item_name + "[/color]\n\n" + item.item_desc
	label.scroll_active = false
	margin.add_child(label)
	
	return panel


func _on_pressed() -> void:
	if item and replacing and not paused:
		replaced.emit(item_slot)

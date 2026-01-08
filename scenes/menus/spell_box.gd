extends Button

@export var spell: Spell

func _ready() -> void:
	set_spell(spell)
	
func _process(_delta: float) -> void:
	if spell:
		queue_redraw()
	
func _draw():
	var normal_style = get_theme_stylebox("normal")
	if normal_style:
		normal_style.draw(get_canvas_item(), Rect2(Vector2.ZERO, size))

	# Cooldown visualization
	if spell and spell.cooldown > 0 and spell.current_cooldown > 0:
		var ratio = spell.current_cooldown / spell.cooldown
		var color = Color(0.1, 0.1, 0.2, 0.8) 
		var height = size.y * ratio
		draw_rect(Rect2(0, size.y - height, size.x, height), color)

func set_spell(s: Spell):
	spell = s
	if spell:
		$TextureRect.texture = spell.item_sprite
	else:
		$TextureRect.texture = null

func _make_custom_tooltip(_text: String) -> Control:
	if not spell:
		return null
	
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
	label.text = "[color=magenta]" + spell.spell_name + "[/color]\n\n" + spell.spell_desc
	label.scroll_active = false
	margin.add_child(label)
	
	return panel

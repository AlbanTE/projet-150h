extends PanelContainer

var item: Item

func _ready() -> void:
	pass


func _process(_delta: float) -> void:
	pass

func set_item(it: Item):
	item = it
	$TextureRect.texture = it.item_sprite
	tooltip_text = it.item_name + "\n\n" + it.item_desc

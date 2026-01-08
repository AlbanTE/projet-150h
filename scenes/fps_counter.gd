extends CanvasLayer

func _process(_delta: float) -> void:
	$FPS.text = str(Engine.get_frames_per_second())

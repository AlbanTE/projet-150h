extends ProgressBar


func _ready() -> void:
	self.max_value = $"../HealthComponent".max_health
	self.value = self.max_value

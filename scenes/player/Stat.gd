class_name Stat

enum OperationTypes { ADD, MULT }

class Modifier:
	var operation: OperationTypes
	var value: float
	var source       # optional: what object applied this modifier

	func _init(op, val, src=null):
		operation = op
		value = val
		source = src

var name: String
var base_value: float
var modifiers := []

var _final_value: float
var _dirty := true   # indicates the value must be recalculated

func _init(_base=0.0, _name="Undefined"):
	base_value = _base
	name = _name
	
func get_name() -> String:
	return name

func add_modifier(modifier: Modifier):
	modifiers.append(modifier)
	_dirty = true

func remove_modifier(modifier: Modifier):
	modifiers.erase(modifier)
	_dirty = true

func remove_modifiers_from_source(source):
	for m in modifiers.filter(func(x): return x.source == source):
		modifiers.erase(m)
	_dirty = true

func get_value() -> float:
	# Lazy calculation
	if not _dirty:
		return _final_value

	var add_total := 0.0
	var mult_total := 1.0

	for m in modifiers:
		match m.operation:
			OperationTypes.ADD:
				add_total += m.value
			OperationTypes.MULT:
				mult_total += m.value

	_final_value = (base_value + add_total) * mult_total
	_dirty = false
	return _final_value

func apply_modifiers(value: float) -> float:
	var add_total := 0.0
	var mult_total := 1.0

	for m in modifiers:
		match m.operation:
			OperationTypes.ADD:
				add_total += m.value
			OperationTypes.MULT:
				mult_total += m.value
	
	return (value + add_total) * mult_total

func reset() -> void:
	modifiers.clear()
	_final_value = base_value
	_dirty = true

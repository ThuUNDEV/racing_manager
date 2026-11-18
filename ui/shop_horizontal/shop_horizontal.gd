extends Control

const DESIGN_WIDTH := 886.0

@onready var _stage: Control = $Stage


func _ready() -> void:
	resized.connect(_fit)
	_fit()


func _fit() -> void:
	var k := size.x / DESIGN_WIDTH
	_stage.scale = Vector2(k, k)
	_stage.size = size / k

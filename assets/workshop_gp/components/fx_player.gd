extends AnimatedSprite2D
## One-shot effects release themselves; looping effects remain until caller frees them.
@export var free_after_finish := true


func _ready() -> void:
	animation_finished.connect(func():
		if free_after_finish and not sprite_frames.get_animation_loop(animation):
			queue_free()
	)

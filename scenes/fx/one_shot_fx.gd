extends Sprite2D
## Effet animé joué une seule fois, puis retiré.

var _fps := 20.0
var _time := 0.0


func setup(sheet: Texture2D, frames: int, fps: float) -> void:
	texture = sheet
	hframes = frames
	_fps = fps


func _process(delta: float) -> void:
	_time += delta
	var f := int(_time * _fps)
	if f >= hframes:
		queue_free()
	else:
		frame = f

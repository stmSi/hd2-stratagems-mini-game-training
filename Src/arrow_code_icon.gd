extends TextureRect
class_name ArrowCodeIcon

const STRATAGEM_ARROW_DOWN = preload("uid://b4sgli4cp266i")
const STRATAGEM_ARROW_LEFT = preload("uid://cdcdfdbvxyd")
const STRATAGEM_ARROW_RIGHT = preload("uid://4qd5kbllk47s")
const STRATAGEM_ARROW_UP = preload("uid://b6kj2fqvf63gp")

@export var current_arrow: Global.ARROW

func set_arrow(a: Global.ARROW):
	current_arrow = a
	if a == Global.ARROW.LEFT:
		texture = STRATAGEM_ARROW_LEFT
	elif a == Global.ARROW.RIGHT:
		texture = STRATAGEM_ARROW_RIGHT
	elif a == Global.ARROW.UP:
		texture = STRATAGEM_ARROW_UP
	else:
		texture = STRATAGEM_ARROW_DOWN



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	set_arrow(current_arrow)

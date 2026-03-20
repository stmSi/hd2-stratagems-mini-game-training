extends HBoxContainer
class_name StrategemBox

@onready var strategem_icon: TextureRect = %StrategemIcon
@onready var strategem_name: Label = %StrategemName
@onready var strategem_codes: HBoxContainer = %StrategemCodes

const ARROW_CODE_ICON = preload("uid://bs2ww5vda85fw")
@export var strat_id := ""
@export var preview_mode := false
@export var show_sequence := true
var strat_data: Dictionary = {}
var arrow_icons: Array[ArrowCodeIcon] = []
var base_scale := Vector2.ONE

func _ready() -> void:
	base_scale = scale
	_clear_codes()
	if strat_data.is_empty() and not strat_id.is_empty() and Global.STRATAGEMS.has(strat_id):
		strat_data = Global.STRATAGEMS[strat_id]
	if not strat_data.is_empty():
		_apply_strategem()
	else:
		strategem_icon.texture = null
		strategem_name.text = ""
		strategem_codes.visible = show_sequence


func set_strategem(next_strat_id: String, strat: Dictionary) -> void:
	strat_id = next_strat_id
	strat_data = strat
	if is_node_ready():
		_apply_strategem()


func set_preview_mode(value: bool) -> void:
	preview_mode = value
	if is_node_ready() and not strat_data.is_empty():
		_apply_strategem()


func set_show_sequence(value: bool) -> void:
	show_sequence = value
	if is_node_ready():
		strategem_codes.visible = show_sequence


func _apply_strategem() -> void:
	strategem_icon.texture = strat_data["icon"]
	strategem_name.text = strat_data["name"]
	_clear_codes()

	var sequence: Array = strat_data["sequence"]
	for code in sequence:
		var arrow: ArrowCodeIcon = ARROW_CODE_ICON.instantiate()
		arrow.set_arrow(code)
		strategem_codes.add_child(arrow)
		arrow_icons.append(arrow)

	strategem_codes.visible = show_sequence
	if preview_mode:
		show_preview_sequence()
	else:
		set_input_progress(0)


func show_preview_sequence() -> void:
	for arrow in arrow_icons:
		arrow.scale = Vector2.ONE
		arrow.self_modulate = Color.WHITE


func set_input_progress(progress: int, failed_index: int = -1) -> void:
	for index in range(arrow_icons.size()):
		var arrow := arrow_icons[index]
		arrow.scale = Vector2.ONE
		if failed_index == index:
			arrow.self_modulate = Color(1.0, 0.4, 0.4, 1.0)
		elif index < progress:
			arrow.self_modulate = Color(0.58, 1.0, 0.72, 1.0)
		elif index == progress:
			arrow.self_modulate = Color(1.0, 0.93, 0.66, 1.0)
		else:
			arrow.self_modulate = Color(1.0, 1.0, 1.0, 0.35)


func pulse_arrow(index: int, highlight := Color(1.0, 0.93, 0.66, 1.0)) -> void:
	if index < 0 or index >= arrow_icons.size():
		return

	var arrow := arrow_icons[index]
	arrow.self_modulate = highlight
	var tween := create_tween()
	tween.set_parallel(false)
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(arrow, "scale", Vector2(1.24, 1.24), 0.07)
	tween.set_trans(Tween.TRANS_SINE)
	tween.tween_property(arrow, "scale", Vector2(0.94, 0.94), 0.05)
	tween.tween_property(arrow, "scale", Vector2.ONE, 0.09)


func flash_failure() -> void:
	self_modulate = Color(1.0, 0.78, 0.78, 1.0)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "self_modulate", Color.WHITE, 0.2)
	tween.tween_property(self, "scale", base_scale * 1.04, 0.08)
	tween.chain().tween_property(self, "scale", base_scale * 0.98, 0.05)
	tween.tween_property(self, "scale", base_scale, 0.1)


func pulse_success() -> void:
	self_modulate = Color(0.82, 1.0, 0.86, 1.0)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "self_modulate", Color.WHITE, 0.28)
	tween.tween_property(self, "scale", base_scale * 1.05, 0.08)
	tween.chain().tween_property(self, "scale", base_scale * 0.98, 0.06)
	tween.tween_property(self, "scale", base_scale, 0.12)


func _clear_codes() -> void:
	arrow_icons.clear()
	for child in strategem_codes.get_children():
		child.queue_free()

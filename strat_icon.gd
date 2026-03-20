extends TextureButton

const STRATEGEM_TOOLTIP = preload("res://strategem_tooltip.tscn")
const TOOLTIP_OFFSET := Vector2(18, 18)

@export var strat_id := ""
var tooltip_instance: Control

func _ready() -> void:
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	set_process(false)
	_apply_stratagem_data()


func set_stratagem(next_strat_id: String) -> void:
	strat_id = next_strat_id
	_apply_stratagem_data()
	if tooltip_instance and Global.STRATAGEMS.has(strat_id):
		tooltip_instance.set_strategem(strat_id, Global.STRATAGEMS[strat_id])
		_update_tooltip_position()


func _apply_stratagem_data() -> void:
	if strat_id.is_empty():
		texture_normal = null
		tooltip_text = ""
		return

	if not Global.STRATAGEMS.has(strat_id):
		push_warning("Unknown stratagem id: %s" % strat_id)
		texture_normal = null
		tooltip_text = ""
		return

	var strat: Dictionary = Global.STRATAGEMS[strat_id]
	texture_normal = strat["icon"]
	tooltip_text = ""


func _process(_delta: float) -> void:
	_update_tooltip_position()


func _on_mouse_entered() -> void:
	if not Global.STRATAGEMS.has(strat_id):
		return

	if not tooltip_instance:
		tooltip_instance = STRATEGEM_TOOLTIP.instantiate()
	
	
	tooltip_instance.set_strategem(strat_id, Global.STRATAGEMS[strat_id])
	tooltip_instance.top_level = true
	get_tree().root.add_child(tooltip_instance)
	tooltip_instance.reset_size()
	_update_tooltip_position()
	set_process(true)


func _on_mouse_exited() -> void:
	_hide_tooltip()


func _hide_tooltip() -> void:
	set_process(false)
	if not tooltip_instance:
		return

	tooltip_instance.queue_free()
	tooltip_instance = null


func _update_tooltip_position() -> void:
	if not tooltip_instance:
		return

	var tooltip_size := tooltip_instance.size
	if tooltip_size == Vector2.ZERO:
		tooltip_size = tooltip_instance.get_combined_minimum_size()

	var viewport_size := get_viewport_rect().size
	var mouse_pos := get_viewport().get_mouse_position()
	var next_position := mouse_pos + TOOLTIP_OFFSET

	if next_position.x + tooltip_size.x > viewport_size.x:
		next_position.x = mouse_pos.x - tooltip_size.x - TOOLTIP_OFFSET.x
	if next_position.y + tooltip_size.y > viewport_size.y:
		next_position.y = mouse_pos.y - tooltip_size.y - TOOLTIP_OFFSET.y

	next_position.x = clampf(next_position.x, 0.0, maxf(0.0, viewport_size.x - tooltip_size.x))
	next_position.y = clampf(next_position.y, 0.0, maxf(0.0, viewport_size.y - tooltip_size.y))
	tooltip_instance.position = next_position


func _exit_tree() -> void:
	_hide_tooltip()


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed():
		if event.button_index == MOUSE_BUTTON_LEFT:
			print('hello')

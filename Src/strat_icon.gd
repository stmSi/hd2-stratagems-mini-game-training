extends TextureButton

const STRATEGEM_TOOLTIP = preload("res://Src/strategem_tooltip.tscn")
const TOOLTIP_OFFSET := Vector2(18, 18)

@export var strat_id := ""
var tooltip_instance: Control
var is_selected := false
var show_stratagem_arrows := Global.DEFAULT_SHOW_STRATAGEM_ARROWS

func _ready() -> void:
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	set_process(false)
	_apply_stratagem_data()
	_apply_selected_state()


func set_stratagem(next_strat_id: String) -> void:
	strat_id = next_strat_id
	_apply_stratagem_data()
	if tooltip_instance and Global.STRATAGEMS.has(strat_id):
		tooltip_instance.set_strategem(strat_id, Global.STRATAGEMS[strat_id])
		_update_tooltip_position()


func set_selected(value: bool) -> void:
	is_selected = value
	_apply_selected_state()


func set_show_stratagem_arrows(value: bool) -> void:
	show_stratagem_arrows = value
	if tooltip_instance:
		tooltip_instance.set_show_sequence(show_stratagem_arrows)
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


func _apply_selected_state() -> void:
	if is_selected:
		self_modulate = Color(1.0, 0.92, 0.65, 1.0)
	else:
		self_modulate = Color(1.0, 1.0, 1.0, 1.0)


func _process(_delta: float) -> void:
	_update_tooltip_position()


func _on_mouse_entered() -> void:
	if not Global.STRATAGEMS.has(strat_id):
		return

	if not tooltip_instance:
		tooltip_instance = STRATEGEM_TOOLTIP.instantiate()
	
	
	tooltip_instance.set_strategem(strat_id, Global.STRATAGEMS[strat_id])
	tooltip_instance.set_show_sequence(show_stratagem_arrows)
	tooltip_instance.top_level = true
	get_window().add_child(tooltip_instance)
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
	tooltip_size *= tooltip_instance.scale.abs()

	var window_rect := get_window().get_visible_rect()
	var viewport_size := window_rect.size
	var mouse_pos := get_window().get_mouse_position()
	var next_position := mouse_pos + TOOLTIP_OFFSET

	if next_position.x + tooltip_size.x > viewport_size.x:
		next_position.x = mouse_pos.x - tooltip_size.x - TOOLTIP_OFFSET.x
	if next_position.y + tooltip_size.y > viewport_size.y:
		next_position.y = mouse_pos.y - tooltip_size.y - TOOLTIP_OFFSET.y

	next_position.x = clampf(next_position.x, 0.0, maxf(0.0, viewport_size.x - tooltip_size.x))
	next_position.y = clampf(next_position.y, 0.0, maxf(0.0, viewport_size.y - tooltip_size.y))
	tooltip_instance.global_position = window_rect.position + next_position


func _exit_tree() -> void:
	_hide_tooltip()


func _on_gui_input(event: InputEvent) -> void:
	pass

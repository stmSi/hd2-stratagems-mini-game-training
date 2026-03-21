extends TextureButton

const STRATEGEM_TOOLTIP = preload("res://Src/strategem_tooltip.tscn")
const TOOLTIP_OFFSET := Vector2(18, 18)
const BASE_SCALE := Vector2.ONE
const HOVER_SCALE := Vector2(1.08, 1.08)
const PRESSED_SCALE := Vector2(0.93, 0.93)
const IDLE_ICON_MODULATE := Color(0.76, 0.8, 0.88, 0.88)
const HOVER_ICON_MODULATE := Color(0.96, 0.98, 1.0, 1.0)
const SELECTED_ICON_MODULATE := Color(1.0, 0.97, 0.87, 1.0)
const SELECTED_HOVER_ICON_MODULATE := Color(1.0, 0.99, 0.92, 1.0)
const IDLE_FRAME_BG := Color(0.0, 0.0, 0.0, 0.0)
const HOVER_FRAME_BG := Color(0.27, 0.47, 0.72, 0.24)
const SELECTED_FRAME_BG := Color(0.94, 0.71, 0.28, 0.46)
const SELECTED_HOVER_FRAME_BG := Color(0.98, 0.76, 0.34, 0.58)
const HOVER_FRAME_BORDER := Color(0.56, 0.79, 1.0, 0.82)
const SELECTED_FRAME_BORDER := Color(1.0, 0.9, 0.62, 1.0)
const SELECTED_HOVER_FRAME_BORDER := Color(1.0, 0.95, 0.72, 1.0)

@export var strat_id := ""
@onready var highlight_frame: Panel = $HighlightFrame

var tooltip_instance: Control
var is_selected := false
var is_hovered := false
var is_pressing := false
var show_stratagem_arrows := Global.DEFAULT_SHOW_STRATAGEM_ARROWS
var interaction_tween: Tween

func _ready() -> void:
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	button_down.connect(_on_button_down)
	button_up.connect(_on_button_up)
	set_process(false)
	_update_pivot_offset()
	_apply_stratagem_data()
	_refresh_visual_state(true)


func set_stratagem(next_strat_id: String) -> void:
	strat_id = next_strat_id
	_apply_stratagem_data()
	if tooltip_instance and Global.STRATAGEMS.has(strat_id):
		tooltip_instance.set_strategem(strat_id, Global.STRATAGEMS[strat_id])
		_update_tooltip_position()


func set_selected(value: bool) -> void:
	is_selected = value
	if is_node_ready():
		_refresh_visual_state()


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


func _refresh_visual_state(force_scale := false) -> void:
	if not is_node_ready():
		return

	_apply_frame_state()
	_apply_icon_state()
	if force_scale:
		scale = _get_target_scale()
	else:
		_animate_to_scale(_get_target_scale())


func _apply_frame_state() -> void:
	var bg_color := IDLE_FRAME_BG
	var border_color := Color(1.0, 1.0, 1.0, 0.0)
	var border_width := 0
	var shadow_size := 0
	var shadow_color := Color(0.0, 0.0, 0.0, 0.0)

	if is_selected and is_hovered:
		bg_color = SELECTED_HOVER_FRAME_BG
		border_color = SELECTED_HOVER_FRAME_BORDER
		border_width = 3
		shadow_size = 14
		shadow_color = Color(1.0, 0.77, 0.31, 0.26)
	elif is_selected:
		bg_color = SELECTED_FRAME_BG
		border_color = SELECTED_FRAME_BORDER
		border_width = 3
		shadow_size = 12
		shadow_color = Color(1.0, 0.74, 0.27, 0.22)
	elif is_hovered:
		bg_color = HOVER_FRAME_BG
		border_color = HOVER_FRAME_BORDER
		border_width = 2
		shadow_size = 8
		shadow_color = Color(0.41, 0.66, 1.0, 0.16)

	var style := StyleBoxFlat.new()
	style.content_margin_left = 6.0
	style.content_margin_top = 6.0
	style.content_margin_right = 6.0
	style.content_margin_bottom = 6.0
	style.corner_radius_top_left = 16
	style.corner_radius_top_right = 16
	style.corner_radius_bottom_right = 16
	style.corner_radius_bottom_left = 16
	style.bg_color = bg_color
	style.border_color = border_color
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.shadow_size = shadow_size
	style.shadow_color = shadow_color
	highlight_frame.add_theme_stylebox_override("panel", style)
	highlight_frame.visible = is_selected or is_hovered


func _apply_icon_state() -> void:
	if is_selected and is_hovered:
		self_modulate = SELECTED_HOVER_ICON_MODULATE
	elif is_selected:
		self_modulate = SELECTED_ICON_MODULATE
	elif is_hovered:
		self_modulate = HOVER_ICON_MODULATE
	else:
		self_modulate = IDLE_ICON_MODULATE

	if is_pressing:
		self_modulate = self_modulate.darkened(0.08)

	z_index = 3 if is_hovered or is_pressing else 0


func _get_target_scale() -> Vector2:
	if is_pressing:
		return PRESSED_SCALE
	if is_hovered:
		return HOVER_SCALE
	return BASE_SCALE


func _animate_to_scale(target_scale: Vector2) -> void:
	if interaction_tween:
		interaction_tween.kill()

	if scale.is_equal_approx(target_scale):
		return

	interaction_tween = create_tween()
	if is_pressing:
		interaction_tween.set_trans(Tween.TRANS_QUAD)
		interaction_tween.set_ease(Tween.EASE_OUT)
		interaction_tween.tween_property(self, "scale", target_scale, 0.06)
	else:
		interaction_tween.set_trans(Tween.TRANS_BACK)
		interaction_tween.set_ease(Tween.EASE_OUT)
		interaction_tween.tween_property(self, "scale", target_scale, 0.12)


func _update_pivot_offset() -> void:
	pivot_offset = size * 0.5


func _process(_delta: float) -> void:
	_update_tooltip_position()


func _on_mouse_entered() -> void:
	is_hovered = true
	_refresh_visual_state()

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
	is_hovered = false
	is_pressing = false
	_refresh_visual_state()
	_hide_tooltip()


func _on_button_down() -> void:
	is_pressing = true
	_refresh_visual_state()


func _on_button_up() -> void:
	is_pressing = false
	_refresh_visual_state()


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
	if interaction_tween:
		interaction_tween.kill()
	_hide_tooltip()


func _on_gui_input(event: InputEvent) -> void:
	pass


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_update_pivot_offset()

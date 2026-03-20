extends Node

const GLOBAL_DATA = preload("res://Src/Global.gd")
const STRAT_ICON_SCENE = preload("uid://cw23thcgkm5wx")
const PRACTICE_STRAT_ITEM_SCENE = preload("res://Src/practice_strat_item.tscn")

@onready var list_of_strats: VBoxContainer = %ListOfStrats
@onready var player_strats: VBoxContainer = %PlayerStrats
@onready var search_input: LineEdit = %SearchInput
@onready var search_clear_btn: Button = %SearchClearBtn
@onready var settings_toggle_btn: Button = %SettingsToggleBtn
@onready var settings_body: VBoxContainer = %SettingsBody
@onready var randomize_toggle: CheckButton = %RandomizeToggle
@onready var show_arrows_toggle: CheckButton = %ShowArrowsToggle
@onready var require_holding_toggle: CheckButton = %RequireHoldingToggle
@onready var hold_binding_btn: Button = %HoldBindingBtn
@onready var bindings_help_label: Label = %BindingsHelpLabel
@onready var up_primary_btn: Button = %UpPrimaryBtn
@onready var up_secondary_btn: Button = %UpSecondaryBtn
@onready var left_primary_btn: Button = %LeftPrimaryBtn
@onready var left_secondary_btn: Button = %LeftSecondaryBtn
@onready var down_primary_btn: Button = %DownPrimaryBtn
@onready var down_secondary_btn: Button = %DownSecondaryBtn
@onready var right_primary_btn: Button = %RightPrimaryBtn
@onready var right_secondary_btn: Button = %RightSecondaryBtn
@onready var audio_volume_slider: HSlider = %AudioVolumeSlider
@onready var audio_volume_value_label: Label = %AudioVolumeValueLabel
@onready var reset_defaults_btn: Button = %ResetDefaultsBtn
@onready var close_settings_btn: Button = %CloseSettingsBtn
@onready var clear_reset_btn: Button = %ClearResetBtn
@onready var train_btn: Button = %TrainBtn

var user_strat_list: Array[String] = []
var search_query := ""
var randomize_mode := false
var audio_volume := GLOBAL_DATA.DEFAULT_AUDIO_VOLUME
var show_stratagem_arrows := GLOBAL_DATA.DEFAULT_SHOW_STRATAGEM_ARROWS
var require_holding := GLOBAL_DATA.DEFAULT_REQUIRE_HOLD
var hold_binding: Dictionary = GLOBAL_DATA.get_default_hold_binding()
var direction_bindings: Dictionary = GLOBAL_DATA.get_default_direction_bindings()
var binding_buttons := {}
var pending_binding_slot := ""
var binding_capture_ready_frame := -1

func _ready() -> void:
	binding_buttons = {
		"hold": hold_binding_btn,
		"up_primary": up_primary_btn,
		"up_secondary": up_secondary_btn,
		"left_primary": left_primary_btn,
		"left_secondary": left_secondary_btn,
		"down_primary": down_primary_btn,
		"down_secondary": down_secondary_btn,
		"right_primary": right_primary_btn,
		"right_secondary": right_secondary_btn,
	}
	_load_user_config()
	search_input.text = search_query
	settings_toggle_btn.button_pressed = false
	randomize_toggle.button_pressed = randomize_mode
	show_arrows_toggle.button_pressed = show_stratagem_arrows
	require_holding_toggle.button_pressed = require_holding
	audio_volume_slider.value = audio_volume * 100.0
	_update_search_controls()
	_update_settings_visibility()
	_update_volume_controls()
	_update_binding_controls()
	search_input.text_changed.connect(_on_search_text_changed)
	search_clear_btn.pressed.connect(_on_search_clear_pressed)
	settings_toggle_btn.toggled.connect(_on_settings_toggled)
	randomize_toggle.toggled.connect(_on_randomize_toggled)
	show_arrows_toggle.toggled.connect(_on_show_arrows_toggled)
	require_holding_toggle.toggled.connect(_on_require_holding_toggled)
	for slot_id in binding_buttons.keys():
		var button: Button = binding_buttons[slot_id]
		button.pressed.connect(_on_binding_capture_requested.bind(slot_id))
	audio_volume_slider.value_changed.connect(_on_audio_volume_changed)
	reset_defaults_btn.pressed.connect(_on_reset_defaults_pressed)
	close_settings_btn.pressed.connect(_on_close_settings_pressed)
	clear_reset_btn.pressed.connect(_on_clear_saved_pressed)
	train_btn.pressed.connect(_on_train_pressed)
	_populate_stratagem_list()
	_refresh_saved_stratagems()
	_update_action_buttons()


func _input(event: InputEvent) -> void:
	if pending_binding_slot.is_empty():
		return

	if Engine.get_process_frames() <= binding_capture_ready_frame:
		return

	if event is InputEventKey:
		var key_event := event as InputEventKey
		if not key_event.pressed or key_event.echo:
			return

		get_viewport().set_input_as_handled()
		if key_event.keycode == KEY_ESCAPE:
			_cancel_binding_capture()
			return

		_apply_captured_binding(pending_binding_slot, GLOBAL_DATA.binding_from_key_event(key_event))
		return

	if pending_binding_slot != "hold" or event is not InputEventMouseButton:
		return

	var mouse_event := event as InputEventMouseButton
	if not mouse_event.pressed or not GLOBAL_DATA.is_supported_mouse_button(mouse_event.button_index):
		return

	get_viewport().set_input_as_handled()
	_apply_captured_binding(pending_binding_slot, GLOBAL_DATA.binding_from_mouse_button_event(mouse_event))


func _populate_stratagem_list() -> void:
	_clear_container(list_of_strats)

	var grouped_stratagems := {}
	for category in GLOBAL_DATA.STRATAGEM_CATEGORY_ORDER:
		grouped_stratagems[category] = []

	for strat_id in GLOBAL_DATA.STRATAGEMS.keys():
		if _matches_search(strat_id):
			grouped_stratagems[GLOBAL_DATA.get_stratagem_category(strat_id)].append(strat_id)

	for category in GLOBAL_DATA.STRATAGEM_CATEGORY_ORDER:
		var strat_ids: Array = grouped_stratagems[category]
		strat_ids.sort_custom(_sort_stratagems_by_name)
		_add_category_section(category, strat_ids)


func _sort_stratagems_by_name(a: String, b: String) -> bool:
	return GLOBAL_DATA.STRATAGEMS[a]["name"] < GLOBAL_DATA.STRATAGEMS[b]["name"]


func _add_category_section(category: String, strat_ids: Array) -> void:
	if strat_ids.is_empty():
		return

	var label := Label.new()
	label.text = GLOBAL_DATA.STRATAGEM_CATEGORY_LABELS[category]
	label.add_theme_font_size_override("font_size", 28)
	label.add_theme_color_override("font_color", GLOBAL_DATA.STRATAGEM_CATEGORY_COLORS[category])
	list_of_strats.add_child(label)

	var grid := GridContainer.new()
	grid.columns = 7
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 15)
	grid.add_theme_constant_override("v_separation", 15)
	list_of_strats.add_child(grid)

	for strat_id in strat_ids:
		var icon = STRAT_ICON_SCENE.instantiate()
		icon.set_stratagem(strat_id)
		icon.set_selected(user_strat_list.has(strat_id))
		icon.set_show_stratagem_arrows(show_stratagem_arrows)
		icon.pressed.connect(_on_strat_icon_pressed.bind(strat_id))
		grid.add_child(icon)


func _refresh_saved_stratagems() -> void:
	_clear_container(player_strats)

	if user_strat_list.is_empty():
		var empty_label := Label.new()
		empty_label.text = "Click stratagem icons to add them here."
		empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.7))
		player_strats.add_child(empty_label)
		return

	for strat_id in user_strat_list:
		var item = PRACTICE_STRAT_ITEM_SCENE.instantiate()
		item.set_stratagem(strat_id)
		item.set_show_sequence(show_stratagem_arrows)
		item.remove_requested.connect(_on_saved_stratagem_remove_requested)
		player_strats.add_child(item)


func _matches_search(strat_id: String) -> bool:
	if search_query.is_empty():
		return true

	var lowered_query := search_query.to_lower()
	var strat: Dictionary = GLOBAL_DATA.STRATAGEMS[strat_id]
	var category := GLOBAL_DATA.get_stratagem_category(strat_id)

	return (
		strat["name"].to_lower().contains(lowered_query)
		or strat_id.to_lower().contains(lowered_query)
		or GLOBAL_DATA.STRATAGEM_CATEGORY_LABELS[category].to_lower().contains(lowered_query)
	)


func _on_search_text_changed(next_text: String) -> void:
	search_query = next_text.strip_edges()
	_update_search_controls()
	_populate_stratagem_list()


func _on_search_clear_pressed() -> void:
	if search_input.text.is_empty():
		return

	search_input.clear()
	search_input.grab_focus()


func _on_strat_icon_pressed(strat_id: String) -> void:
	if user_strat_list.has(strat_id):
		user_strat_list.erase(strat_id)
	else:
		user_strat_list.append(strat_id)

	_save_user_config()
	_refresh_saved_stratagems()
	_populate_stratagem_list()
	_update_action_buttons()


func _on_saved_stratagem_remove_requested(strat_id: String) -> void:
	if not user_strat_list.has(strat_id):
		return

	user_strat_list.erase(strat_id)
	_save_user_config()
	_refresh_saved_stratagems()
	_populate_stratagem_list()
	_update_action_buttons()


func _on_clear_saved_pressed() -> void:
	if user_strat_list.is_empty():
		return

	user_strat_list.clear()
	_save_user_config()
	_refresh_saved_stratagems()
	_populate_stratagem_list()
	_update_action_buttons()


func _on_randomize_toggled(toggled_on: bool) -> void:
	randomize_mode = toggled_on
	_save_user_config()


func _on_settings_toggled(toggled_on: bool) -> void:
	if not toggled_on:
		_cancel_binding_capture()
	settings_body.visible = toggled_on
	_update_settings_visibility()


func _on_show_arrows_toggled(toggled_on: bool) -> void:
	show_stratagem_arrows = toggled_on
	_save_user_config()
	_refresh_saved_stratagems()
	_populate_stratagem_list()


func _on_require_holding_toggled(toggled_on: bool) -> void:
	require_holding = toggled_on
	_save_user_config()
	_update_binding_controls()


func _on_audio_volume_changed(value: float) -> void:
	audio_volume = clampf(value / 100.0, 0.0, 1.0)
	_update_volume_controls()
	_save_user_config()


func _on_reset_defaults_pressed() -> void:
	_cancel_binding_capture(false)
	randomize_mode = false
	show_stratagem_arrows = GLOBAL_DATA.DEFAULT_SHOW_STRATAGEM_ARROWS
	require_holding = GLOBAL_DATA.DEFAULT_REQUIRE_HOLD
	audio_volume = GLOBAL_DATA.DEFAULT_AUDIO_VOLUME
	hold_binding = GLOBAL_DATA.get_default_hold_binding()
	direction_bindings = GLOBAL_DATA.get_default_direction_bindings()

	randomize_toggle.set_pressed_no_signal(randomize_mode)
	show_arrows_toggle.set_pressed_no_signal(show_stratagem_arrows)
	require_holding_toggle.set_pressed_no_signal(require_holding)
	audio_volume_slider.set_value_no_signal(audio_volume * 100.0)

	_update_volume_controls()
	_update_binding_controls()
	_refresh_saved_stratagems()
	_populate_stratagem_list()
	_save_user_config()


func _on_train_pressed() -> void:
	if train_btn.disabled:
		return

	_save_user_config()
	var err := get_tree().change_scene_to_file(GLOBAL_DATA.TRAIN_SCENE_PATH)
	if err != OK:
		push_warning("Failed to open train scene: %s" % err)


func _on_close_settings_pressed() -> void:
	_cancel_binding_capture(false)
	settings_toggle_btn.set_pressed_no_signal(false)
	_update_settings_visibility()


func _update_search_controls() -> void:
	search_clear_btn.disabled = search_query.is_empty()


func _update_settings_visibility() -> void:
	settings_body.visible = settings_toggle_btn.button_pressed
	if settings_toggle_btn.button_pressed:
		settings_toggle_btn.text = "Settings -"
	else:
		settings_toggle_btn.text = "Settings +"


func _update_volume_controls() -> void:
	audio_volume_value_label.text = "%d%%" % int(round(audio_volume * 100.0))


func _update_binding_controls() -> void:
	require_holding_toggle.text = "Require Holding"
	hold_binding_btn.text = _get_binding_button_text("hold")
	up_primary_btn.text = _get_binding_button_text("up_primary")
	up_secondary_btn.text = _get_binding_button_text("up_secondary")
	left_primary_btn.text = _get_binding_button_text("left_primary")
	left_secondary_btn.text = _get_binding_button_text("left_secondary")
	down_primary_btn.text = _get_binding_button_text("down_primary")
	down_secondary_btn.text = _get_binding_button_text("down_secondary")
	right_primary_btn.text = _get_binding_button_text("right_primary")
	right_secondary_btn.text = _get_binding_button_text("right_secondary")

	if pending_binding_slot.is_empty():
		bindings_help_label.text = "Click a binding button, then press a key. Hold binding also accepts mouse buttons."
	elif pending_binding_slot == "hold":
		bindings_help_label.text = "Press a key or mouse button for hold input. Press Esc to cancel."
	else:
		bindings_help_label.text = "Press a key for %s. Press Esc to cancel." % _get_binding_slot_label(pending_binding_slot)


func _update_action_buttons() -> void:
	clear_reset_btn.disabled = user_strat_list.is_empty()
	train_btn.disabled = GLOBAL_DATA.get_trainable_strat_ids(user_strat_list).is_empty()


func _clear_container(container: Node) -> void:
	for child in container.get_children():
		child.queue_free()


func _load_user_config() -> void:
	var config := GLOBAL_DATA.load_practice_config()
	user_strat_list = config["selected_strat_ids"]
	randomize_mode = config["randomize_mode"]
	audio_volume = config["audio_volume"]
	show_stratagem_arrows = config["show_stratagem_arrows"]
	require_holding = config["require_holding"]
	hold_binding = config["hold_binding"]
	direction_bindings = config["direction_bindings"]


func _save_user_config() -> void:
	var err := GLOBAL_DATA.save_practice_config(
		user_strat_list,
		randomize_mode,
		audio_volume,
		show_stratagem_arrows,
		require_holding,
		hold_binding,
		direction_bindings
	)
	if err != OK:
		push_warning("Failed to save user config: %s" % err)


func _on_binding_capture_requested(slot_id: String) -> void:
	if pending_binding_slot == slot_id:
		_cancel_binding_capture()
		return

	pending_binding_slot = slot_id
	binding_capture_ready_frame = Engine.get_process_frames()
	_update_binding_controls()


func _apply_captured_binding(slot_id: String, binding: Dictionary) -> void:
	if slot_id == "hold":
		hold_binding = GLOBAL_DATA.sanitize_input_binding(binding, hold_binding, true)
	else:
		var fallback: Dictionary = direction_bindings.get(slot_id, GLOBAL_DATA.DEFAULT_DIRECTION_BINDINGS[slot_id])
		direction_bindings[slot_id] = GLOBAL_DATA.sanitize_input_binding(binding, fallback, false)

	_cancel_binding_capture(false)
	_save_user_config()
	_update_binding_controls()


func _cancel_binding_capture(refresh_ui := true) -> void:
	pending_binding_slot = ""
	binding_capture_ready_frame = -1
	if refresh_ui:
		_update_binding_controls()


func _get_binding_button_text(slot_id: String) -> String:
	if pending_binding_slot == slot_id:
		if slot_id == "hold":
			return "Press key / mouse..."
		return "Press key..."

	if slot_id == "hold":
		return GLOBAL_DATA.get_binding_label(hold_binding)

	return GLOBAL_DATA.get_binding_label(direction_bindings.get(slot_id, GLOBAL_DATA.DEFAULT_DIRECTION_BINDINGS[slot_id]))


func _get_binding_slot_label(slot_id: String) -> String:
	match slot_id:
		"up_primary":
			return "Primary Up"
		"up_secondary":
			return "Alternate Up"
		"left_primary":
			return "Primary Left"
		"left_secondary":
			return "Alternate Left"
		"down_primary":
			return "Primary Down"
		"down_secondary":
			return "Alternate Down"
		"right_primary":
			return "Primary Right"
		"right_secondary":
			return "Alternate Right"
		"hold":
			return "Hold Input"
		_:
			return "Binding"

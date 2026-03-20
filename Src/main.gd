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
@onready var audio_volume_slider: HSlider = %AudioVolumeSlider
@onready var audio_volume_value_label: Label = %AudioVolumeValueLabel
@onready var clear_reset_btn: Button = %ClearResetBtn
@onready var train_btn: Button = %TrainBtn

var user_strat_list: Array[String] = []
var search_query := ""
var randomize_mode := false
var audio_volume := GLOBAL_DATA.DEFAULT_AUDIO_VOLUME
var show_stratagem_arrows := GLOBAL_DATA.DEFAULT_SHOW_STRATAGEM_ARROWS

func _ready() -> void:
	_load_user_config()
	search_input.text = search_query
	settings_toggle_btn.button_pressed = false
	randomize_toggle.button_pressed = randomize_mode
	show_arrows_toggle.button_pressed = show_stratagem_arrows
	audio_volume_slider.value = audio_volume * 100.0
	_update_search_controls()
	_update_settings_visibility()
	_update_volume_controls()
	search_input.text_changed.connect(_on_search_text_changed)
	search_clear_btn.pressed.connect(_on_search_clear_pressed)
	settings_toggle_btn.toggled.connect(_on_settings_toggled)
	randomize_toggle.toggled.connect(_on_randomize_toggled)
	show_arrows_toggle.toggled.connect(_on_show_arrows_toggled)
	audio_volume_slider.value_changed.connect(_on_audio_volume_changed)
	clear_reset_btn.pressed.connect(_on_clear_saved_pressed)
	train_btn.pressed.connect(_on_train_pressed)
	_populate_stratagem_list()
	_refresh_saved_stratagems()
	_update_action_buttons()


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
	settings_body.visible = toggled_on
	_update_settings_visibility()


func _on_show_arrows_toggled(toggled_on: bool) -> void:
	show_stratagem_arrows = toggled_on
	_save_user_config()
	_refresh_saved_stratagems()
	_populate_stratagem_list()


func _on_audio_volume_changed(value: float) -> void:
	audio_volume = clampf(value / 100.0, 0.0, 1.0)
	_update_volume_controls()
	_save_user_config()


func _on_train_pressed() -> void:
	if train_btn.disabled:
		return

	_save_user_config()
	var err := get_tree().change_scene_to_file(GLOBAL_DATA.TRAIN_SCENE_PATH)
	if err != OK:
		push_warning("Failed to open train scene: %s" % err)


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


func _save_user_config() -> void:
	var err := GLOBAL_DATA.save_practice_config(
		user_strat_list,
		randomize_mode,
		audio_volume,
		show_stratagem_arrows
	)
	if err != OK:
		push_warning("Failed to save user config: %s" % err)

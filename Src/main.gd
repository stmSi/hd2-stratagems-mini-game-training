extends Node

const GLOBAL_DATA = preload("res://Src/Global.gd")
const STRAT_ICON_SCENE = preload("uid://cw23thcgkm5wx")
const PRACTICE_STRAT_ITEM_SCENE = preload("res://Src/practice_strat_item.tscn")
const SETTINGS_POPUP_SCENE = preload("res://Src/settings_popup.tscn")

@onready var list_of_strats: VBoxContainer = %ListOfStrats
@onready var player_strats: VBoxContainer = %PlayerStrats
@onready var search_input: LineEdit = %SearchInput
@onready var search_clear_btn: Button = %SearchClearBtn
@onready var github_link_btn: LinkButton = %GithubLinkBtn
@onready var settings_toggle_btn: Button = %SettingsToggleBtn
@onready var clear_reset_btn: Button = %ClearResetBtn
@onready var train_btn: Button = %TrainBtn

var settings_popup: Control
var user_strat_list: Array[String] = []
var search_query := ""
var randomize_mode := false
var audio_volume := GLOBAL_DATA.DEFAULT_AUDIO_VOLUME
var show_stratagem_arrows := GLOBAL_DATA.DEFAULT_SHOW_STRATAGEM_ARROWS
var require_holding := GLOBAL_DATA.DEFAULT_REQUIRE_HOLD
var hold_binding: Dictionary = GLOBAL_DATA.get_default_hold_binding()
var direction_bindings: Dictionary = GLOBAL_DATA.get_default_direction_bindings()
var controller_hold_binding: Dictionary = GLOBAL_DATA.get_default_controller_hold_binding()
var controller_direction_bindings: Dictionary = GLOBAL_DATA.get_default_controller_direction_bindings()
var practice_stats: Dictionary = {}


func _ready() -> void:
	_load_user_config()
	_setup_settings_popup()
	search_input.text = search_query
	_update_search_controls()
	search_input.text_changed.connect(_on_search_text_changed)
	search_clear_btn.pressed.connect(_on_search_clear_pressed)
	github_link_btn.pressed.connect(_on_github_link_pressed)
	settings_toggle_btn.pressed.connect(_on_settings_pressed)
	clear_reset_btn.pressed.connect(_on_clear_saved_pressed)
	train_btn.pressed.connect(_on_train_pressed)
	_populate_stratagem_list()
	_refresh_saved_stratagems()
	_update_action_buttons()


func _setup_settings_popup() -> void:
	settings_popup = SETTINGS_POPUP_SCENE.instantiate()
	add_child(settings_popup)
	settings_popup.config_changed.connect(_on_settings_popup_config_changed)
	settings_popup.popup_closed.connect(_on_settings_popup_closed)


func _build_settings_config() -> Dictionary:
	return {
		"randomize_mode": randomize_mode,
		"audio_volume": audio_volume,
		"show_stratagem_arrows": show_stratagem_arrows,
		"require_holding": require_holding,
		"hold_binding": hold_binding.duplicate(true),
		"direction_bindings": direction_bindings.duplicate(true),
		"controller_hold_binding": controller_hold_binding.duplicate(true),
		"controller_direction_bindings": controller_direction_bindings.duplicate(true),
	}


func _apply_settings_config(config: Dictionary) -> void:
	var previous_show_arrows := show_stratagem_arrows
	randomize_mode = bool(config.get("randomize_mode", randomize_mode))
	audio_volume = clampf(float(config.get("audio_volume", audio_volume)), 0.0, 1.0)
	show_stratagem_arrows = bool(config.get("show_stratagem_arrows", show_stratagem_arrows))
	require_holding = bool(config.get("require_holding", require_holding))
	hold_binding = GLOBAL_DATA.sanitize_input_binding(
		config.get("hold_binding", hold_binding),
		GLOBAL_DATA.get_default_hold_binding(),
		true,
		false
	)
	direction_bindings = GLOBAL_DATA.sanitize_direction_bindings(
		config.get("direction_bindings", direction_bindings)
	)
	controller_hold_binding = GLOBAL_DATA.sanitize_input_binding(
		config.get("controller_hold_binding", controller_hold_binding),
		GLOBAL_DATA.get_default_controller_hold_binding(),
		false,
		true
	)
	controller_direction_bindings = GLOBAL_DATA.sanitize_controller_direction_bindings(
		config.get("controller_direction_bindings", controller_direction_bindings)
	)

	if previous_show_arrows != show_stratagem_arrows:
		_refresh_saved_stratagems()
		_populate_stratagem_list()


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
	grid.columns = 8
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 22)
	grid.add_theme_constant_override("v_separation", 22)
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


func _on_github_link_pressed() -> void:
	var err := OS.shell_open(GLOBAL_DATA.GITHUB_REPO_URL)
	if err != OK:
		push_warning("Failed to open GitHub link: %s" % err)


func _on_settings_pressed() -> void:
	if not settings_popup:
		return
	settings_popup.open_with_config(_build_settings_config())


func _on_settings_popup_config_changed(config: Dictionary) -> void:
	_apply_settings_config(config)
	_save_user_config()


func _on_settings_popup_closed() -> void:
	pass


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


func _on_train_pressed() -> void:
	if train_btn.disabled:
		return

	_save_user_config()
	var err := get_tree().change_scene_to_file(GLOBAL_DATA.TRAIN_SCENE_PATH)
	if err != OK:
		push_warning("Failed to open train scene: %s" % err)


func _update_search_controls() -> void:
	search_clear_btn.disabled = search_query.is_empty()


func _update_action_buttons() -> void:
	clear_reset_btn.disabled = user_strat_list.is_empty()
	train_btn.disabled = GLOBAL_DATA.get_trainable_strat_ids(user_strat_list).is_empty()


func _clear_container(container: Node) -> void:
	for child in container.get_children():
		child.queue_free()


func _load_user_config() -> void:
	var config := GLOBAL_DATA.load_practice_config()
	user_strat_list.clear()
	var loaded_strat_ids: Array = config["selected_strat_ids"]
	for strat_id in loaded_strat_ids:
		user_strat_list.append(str(strat_id))
	randomize_mode = config["randomize_mode"]
	audio_volume = config["audio_volume"]
	show_stratagem_arrows = config["show_stratagem_arrows"]
	require_holding = config["require_holding"]
	hold_binding = config["hold_binding"]
	direction_bindings = config["direction_bindings"]
	controller_hold_binding = config["controller_hold_binding"]
	controller_direction_bindings = config["controller_direction_bindings"]
	practice_stats = config["practice_stats"]


func _save_user_config() -> void:
	var err := GLOBAL_DATA.save_practice_config(
		user_strat_list,
		randomize_mode,
		audio_volume,
		show_stratagem_arrows,
		require_holding,
		hold_binding,
		direction_bindings,
		controller_hold_binding,
		controller_direction_bindings,
		practice_stats
	)
	if err != OK:
		push_warning("Failed to save user config: %s" % err)

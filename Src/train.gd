extends Control

const GLOBAL_DATA = preload("res://Src/Global.gd")
const SETTINGS_POPUP_SCENE = preload("res://Src/settings_popup.tscn")
const CORRECT_SFX_BASE_DB := -8.0
const FAIL_SFX_BASE_DB := -4.5
const SUCCESS_SFX_BASE_DB := -3.0

@onready var back_btn: Button = %BackBtn
@onready var github_link_btn: LinkButton = %GithubLinkBtn
@onready var settings_btn: Button = %SettingsBtn
@onready var mode_label: Label = %ModeLabel
@onready var status_label: Label = %StatusLabel
@onready var hint_label: Label = %HintLabel
@onready var hold_state_label: Label = %HoldStateLabel
@onready var next_up_panel: PanelContainer = %NextUpPanel
@onready var next_strategem_icon: TextureRect = %NextStrategemIcon
@onready var next_strategem_name: Label = %NextStrategemName
@onready var strategem_box = %StrategemBox
@onready var stats_panel: PanelContainer = %StatsPanel
@onready var stats_label: Label = %StatsLabel
@onready var correct_sfx: AudioStreamPlayer = %CorrectSfx
@onready var fail_sfx: AudioStreamPlayer = %FailSfx
@onready var success_sfx: AudioStreamPlayer = %SuccessSfx

var settings_popup: Control
var selected_strat_ids: Array[String] = []
var trainable_strat_ids: Array[String] = []
var next_strat_id := ""
var current_strat_id := ""
var current_sequence: Array = []
var randomize_mode := false
var audio_volume := GLOBAL_DATA.DEFAULT_AUDIO_VOLUME
var show_stratagem_arrows := GLOBAL_DATA.DEFAULT_SHOW_STRATAGEM_ARROWS
var require_holding := GLOBAL_DATA.DEFAULT_REQUIRE_HOLD
var hold_binding: Dictionary = GLOBAL_DATA.get_default_hold_binding()
var direction_bindings: Dictionary = GLOBAL_DATA.get_default_direction_bindings()
var controller_hold_binding: Dictionary = GLOBAL_DATA.get_default_controller_hold_binding()
var controller_direction_bindings: Dictionary = GLOBAL_DATA.get_default_controller_direction_bindings()
var practice_stats: Dictionary = {}
var sequence_index := 0
var queue_index := 0
var input_locked := false
var hold_feedback_active := false
var hold_state_base_scale := Vector2.ONE
var attempt_started_at_msec := 0
var rng := RandomNumberGenerator.new()


func _ready() -> void:
	rng.randomize()
	hold_state_base_scale = hold_state_label.scale
	stats_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	back_btn.focus_mode = Control.FOCUS_NONE
	back_btn.pressed.connect(_on_back_pressed)
	github_link_btn.pressed.connect(_on_github_link_pressed)
	settings_btn.pressed.connect(_on_settings_pressed)
	_load_config()
	_setup_settings_popup()
	_configure_audio_players()
	_update_mode_label()
	_apply_show_arrows_setting()
	_update_controls_hint()
	_refresh_hold_feedback(true)
	_refresh_stats_display()
	if trainable_strat_ids.is_empty():
		strategem_box.visible = false
		next_up_panel.visible = false
		hold_state_label.visible = false
		stats_panel.visible = false
		status_label.text = "No trainable stratagems selected."
		hint_label.text = "Return to the main screen and add at least one stratagem."
		return

	strategem_box.visible = true
	next_up_panel.visible = true
	stats_panel.visible = true
	_prime_training_rotation()


func _process(_delta: float) -> void:
	_refresh_hold_feedback()


func _input(event: InputEvent) -> void:
	if settings_popup and settings_popup.visible:
		return

	var joypad_device := -1
	if event is InputEventKey:
		var key_event := event as InputEventKey
		if not key_event.pressed or key_event.echo:
			return

		if key_event.keycode == KEY_ESCAPE:
			get_viewport().set_input_as_handled()
			_on_back_pressed()
			return
	elif event is InputEventJoypadButton:
		var joypad_event := event as InputEventJoypadButton
		if not joypad_event.pressed:
			return
		joypad_device = joypad_event.device
	else:
		return

	if input_locked or current_sequence.is_empty():
		return

	var input_arrow := -1
	if event is InputEventJoypadButton:
		input_arrow = GLOBAL_DATA.get_arrow_for_controller_event(event, controller_direction_bindings)
		if input_arrow == -1:
			return
		if require_holding and not GLOBAL_DATA.is_binding_pressed(controller_hold_binding, joypad_device):
			return
	else:
		input_arrow = GLOBAL_DATA.get_arrow_for_direction_event(event, direction_bindings)
		if input_arrow == -1:
			return
		if require_holding and not GLOBAL_DATA.is_binding_pressed(hold_binding):
			return

	get_viewport().set_input_as_handled()
	_handle_input_arrow(input_arrow)


func _setup_settings_popup() -> void:
	settings_popup = SETTINGS_POPUP_SCENE.instantiate()
	add_child(settings_popup)
	settings_popup.config_changed.connect(_on_settings_popup_config_changed)


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
	var previous_randomize_mode := randomize_mode
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
	_configure_audio_players()
	_update_mode_label()
	_apply_show_arrows_setting()
	_update_controls_hint()
	_refresh_hold_feedback(true)
	if previous_randomize_mode != randomize_mode:
		_refresh_rotation_preview()


func _refresh_rotation_preview() -> void:
	if trainable_strat_ids.is_empty():
		next_strat_id = ""
		_refresh_next_preview()
		return

	if current_strat_id.is_empty():
		current_strat_id = _draw_next_stratagem_id()

	if randomize_mode:
		next_strat_id = _draw_next_stratagem_id(current_strat_id)
	else:
		var current_index := trainable_strat_ids.find(current_strat_id)
		if current_index == -1:
			queue_index = 0
		else:
			queue_index = (current_index + 1) % trainable_strat_ids.size()
		next_strat_id = _draw_next_stratagem_id(current_strat_id)
	_refresh_next_preview()


func _load_config() -> void:
	var config := GLOBAL_DATA.load_practice_config()
	selected_strat_ids.clear()
	var loaded_strat_ids: Array = config["selected_strat_ids"]
	for strat_id in loaded_strat_ids:
		selected_strat_ids.append(str(strat_id))
	randomize_mode = config["randomize_mode"]
	audio_volume = config["audio_volume"]
	show_stratagem_arrows = config["show_stratagem_arrows"]
	require_holding = config["require_holding"]
	hold_binding = config["hold_binding"]
	direction_bindings = config["direction_bindings"]
	controller_hold_binding = config["controller_hold_binding"]
	controller_direction_bindings = config["controller_direction_bindings"]
	practice_stats = config["practice_stats"]
	trainable_strat_ids = GLOBAL_DATA.get_trainable_strat_ids(selected_strat_ids)


func _configure_audio_players() -> void:
	correct_sfx.max_polyphony = 4
	fail_sfx.max_polyphony = 2
	success_sfx.max_polyphony = 2
	correct_sfx.volume_db = GLOBAL_DATA.scale_volume_db(CORRECT_SFX_BASE_DB, audio_volume)
	fail_sfx.volume_db = GLOBAL_DATA.scale_volume_db(FAIL_SFX_BASE_DB, audio_volume)
	success_sfx.volume_db = GLOBAL_DATA.scale_volume_db(SUCCESS_SFX_BASE_DB, audio_volume)


func _update_mode_label() -> void:
	if randomize_mode:
		mode_label.text = "Mode: Randomized"
	else:
		mode_label.text = "Mode: Queue Order"


func _handle_input_arrow(input_arrow: int) -> void:
	var expected_arrow = current_sequence[sequence_index]
	if input_arrow == expected_arrow:
		_play_correct_sfx()
		strategem_box.pulse_arrow(sequence_index)
		sequence_index += 1
		strategem_box.set_input_progress(sequence_index)

		if sequence_index >= current_sequence.size():
			_complete_current_sequence()
		else:
			_update_progress_status()
	else:
		_fail_current_sequence()


func _complete_current_sequence() -> void:
	input_locked = true
	_record_attempt(true)
	_play_success_sfx()
	status_label.text = "Sequence complete. Loading next stratagem..."
	strategem_box.pulse_success()
	await get_tree().create_timer(0.45).timeout
	input_locked = false
	_advance_to_next_stratagem()


func _fail_current_sequence() -> void:
	input_locked = true
	_record_attempt(false)
	_play_fail_sfx()
	status_label.text = "Incorrect input. Sequence reset."
	strategem_box.set_input_progress(sequence_index, sequence_index)
	strategem_box.pulse_arrow(sequence_index, Color(1.0, 0.45, 0.45, 1.0))
	strategem_box.flash_failure()
	await get_tree().create_timer(0.24).timeout
	sequence_index = 0
	attempt_started_at_msec = Time.get_ticks_msec()
	strategem_box.set_input_progress(sequence_index)
	_refresh_stats_display()
	input_locked = false


func _prime_training_rotation() -> void:
	current_strat_id = _draw_next_stratagem_id()
	next_strat_id = _draw_next_stratagem_id(current_strat_id)
	_apply_current_stratagem()


func _advance_to_next_stratagem() -> void:
	current_strat_id = next_strat_id
	if current_strat_id.is_empty():
		current_strat_id = _draw_next_stratagem_id()
	next_strat_id = _draw_next_stratagem_id(current_strat_id)
	_apply_current_stratagem()


func _apply_current_stratagem() -> void:
	if current_strat_id.is_empty():
		next_up_panel.visible = false
		status_label.text = "No trainable stratagems selected."
		return

	var strat: Dictionary = GLOBAL_DATA.STRATAGEMS[current_strat_id]
	current_sequence = strat["sequence"]
	sequence_index = 0
	strategem_box.set_strategem(current_strat_id, strat)
	strategem_box.set_input_progress(sequence_index)
	attempt_started_at_msec = Time.get_ticks_msec()
	_refresh_next_preview()
	_update_progress_status()
	_refresh_stats_display()


func _draw_next_stratagem_id(excluded_strat_id := "") -> String:
	if trainable_strat_ids.is_empty():
		return ""

	if randomize_mode:
		var candidates: Array[String] = trainable_strat_ids.duplicate()
		if candidates.size() > 1 and not excluded_strat_id.is_empty():
			candidates.erase(excluded_strat_id)
		return candidates[rng.randi_range(0, candidates.size() - 1)]

	var strat_id := trainable_strat_ids[queue_index % trainable_strat_ids.size()]
	queue_index += 1
	return strat_id


func _on_back_pressed() -> void:
	var err := get_tree().change_scene_to_file(GLOBAL_DATA.MAIN_SCENE_PATH)
	if err != OK:
		push_warning("Failed to return to main scene: %s" % err)


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


func _update_progress_status() -> void:
	status_label.text = "Progress: %d / %d" % [sequence_index, current_sequence.size()]


func _play_correct_sfx() -> void:
	correct_sfx.pitch_scale = rng.randf_range(0.98, 1.06)
	correct_sfx.play()


func _play_fail_sfx() -> void:
	fail_sfx.pitch_scale = rng.randf_range(0.96, 1.01)
	fail_sfx.play()


func _play_success_sfx() -> void:
	success_sfx.pitch_scale = rng.randf_range(0.99, 1.04)
	success_sfx.play()


func _apply_show_arrows_setting() -> void:
	strategem_box.set_show_sequence(show_stratagem_arrows)


func _update_controls_hint() -> void:
	var hint_text := "Keyboard: %s  |  Controller: %s" % [
		GLOBAL_DATA.get_direction_binding_summary(direction_bindings),
		GLOBAL_DATA.get_controller_direction_binding_summary(controller_direction_bindings),
	]
	if require_holding:
		hint_text += "  |  Hold %s to input" % GLOBAL_DATA.get_hold_binding_summary(hold_binding, controller_hold_binding)
	hint_text += "  |  Press Esc to go back"
	hint_label.text = hint_text


func _refresh_hold_feedback(force := false) -> void:
	var should_show_feedback := require_holding and not trainable_strat_ids.is_empty()
	if not should_show_feedback:
		if force or hold_state_label.visible or hold_feedback_active:
			hold_feedback_active = false
			hold_state_label.visible = false
			hold_state_label.scale = hold_state_base_scale
			hold_state_label.self_modulate = Color.WHITE
		return

	var next_active := GLOBAL_DATA.is_hold_input_active(hold_binding, controller_hold_binding)
	if not force and next_active == hold_feedback_active:
		return

	hold_feedback_active = next_active
	hold_state_label.visible = true
	hold_state_label.scale = hold_state_base_scale
	if hold_feedback_active:
		hold_state_label.text = "Hold Active  |  Input Ready"
		hold_state_label.self_modulate = Color(0.72, 1.0, 0.8, 1.0)
		if not force:
			_pulse_hold_feedback()
	else:
		hold_state_label.text = "Hold %s to input" % GLOBAL_DATA.get_hold_binding_summary(hold_binding, controller_hold_binding)
		hold_state_label.self_modulate = Color(1.0, 0.88, 0.62, 0.92)


func _pulse_hold_feedback() -> void:
	strategem_box.pulse_hold_ready()
	var tween := create_tween()
	tween.set_parallel(false)
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(hold_state_label, "scale", hold_state_base_scale * 1.06, 0.08)
	tween.set_trans(Tween.TRANS_SINE)
	tween.tween_property(hold_state_label, "scale", hold_state_base_scale, 0.12)


func _save_user_config() -> void:
	var err := GLOBAL_DATA.save_practice_config(
		selected_strat_ids,
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


func _refresh_next_preview() -> void:
	if next_strat_id.is_empty() or not GLOBAL_DATA.STRATAGEMS.has(next_strat_id):
		next_up_panel.visible = false
		return

	var next_strat: Dictionary = GLOBAL_DATA.STRATAGEMS[next_strat_id]
	next_up_panel.visible = true
	next_strategem_icon.texture = next_strat["icon"]
	if trainable_strat_ids.size() == 1:
		next_strategem_name.text = "%s (Repeat)" % next_strat["name"]
	else:
		next_strategem_name.text = next_strat["name"]


func _record_attempt(success: bool) -> void:
	if current_strat_id.is_empty():
		return

	var entry := _get_practice_stat_entry(current_strat_id)
	if success:
		entry["successful"] = int(entry.get("successful", 0)) + 1
		entry["total_success_time"] = float(entry.get("total_success_time", 0.0)) + _get_current_attempt_elapsed_seconds()
	else:
		entry["unsuccessful"] = int(entry.get("unsuccessful", 0)) + 1

	practice_stats[current_strat_id] = entry
	_save_user_config()
	_refresh_stats_display()


func _get_practice_stat_entry(strat_id: String) -> Dictionary:
	if practice_stats.has(strat_id) and practice_stats[strat_id] is Dictionary:
		return (practice_stats[strat_id] as Dictionary).duplicate(true)

	return {
		"successful": 0,
		"unsuccessful": 0,
		"total_success_time": 0.0,
	}


func _get_current_attempt_elapsed_seconds() -> float:
	if attempt_started_at_msec <= 0:
		return 0.0
	return maxf(0.0, (Time.get_ticks_msec() - attempt_started_at_msec) / 1000.0)


func _refresh_stats_display() -> void:
	if not is_node_ready():
		return

	var stat_ids := _get_recorded_stat_ids()
	if stat_ids.is_empty():
		stats_label.text = "No runs recorded yet. Start training to build performance data."
		return

	var total_successful := 0
	var total_unsuccessful := 0
	var total_success_time := 0.0
	var lines: Array[String] = []
	for strat_id in stat_ids:
		var entry := _get_practice_stat_entry(strat_id)
		var successful := int(entry.get("successful", 0))
		var unsuccessful := int(entry.get("unsuccessful", 0))
		var total_attempts := successful + unsuccessful
		var average_time_text := "n/a"
		if successful > 0:
			var average_time := float(entry.get("total_success_time", 0.0)) / float(successful)
			average_time_text = _format_seconds(average_time)
			total_successful += successful
			total_success_time += float(entry.get("total_success_time", 0.0))
		total_unsuccessful += unsuccessful

		lines.append(
			"%s: %s | %s | %s success | Avg clear %s"
			% [
				GLOBAL_DATA.STRATAGEMS[strat_id]["name"],
				_format_count(successful, "clear", "clears"),
				_format_count(unsuccessful, "reset", "resets"),
				_format_success_rate(total_attempts, successful),
				average_time_text,
			]
		)

	var total_average_text := "n/a"
	var total_attempts := total_successful + total_unsuccessful
	if total_successful > 0:
		total_average_text = _format_seconds(total_success_time / float(total_successful))

	stats_label.text = "Overall: %s | %s | %s success | Avg clear %s\n\n%s" % [
		_format_count(total_successful, "clear", "clears"),
		_format_count(total_unsuccessful, "reset", "resets"),
		_format_success_rate(total_attempts, total_successful),
		total_average_text,
		"\n".join(lines),
	]


func _get_recorded_stat_ids() -> Array[String]:
	var stat_ids: Array[String] = []
	for strat_id in trainable_strat_ids:
		if not practice_stats.has(strat_id):
			continue

		var entry := _get_practice_stat_entry(strat_id)
		var successful := int(entry.get("successful", 0))
		var unsuccessful := int(entry.get("unsuccessful", 0))
		if successful <= 0 and unsuccessful <= 0:
			continue
		stat_ids.append(strat_id)

	return stat_ids


func _format_success_rate(total_attempts: int, successful: int) -> String:
	if total_attempts <= 0:
		return "0%%"
	return "%.0f%%" % ((float(successful) / float(total_attempts)) * 100.0)


func _format_seconds(value: float) -> String:
	return "%.2fs" % value


func _format_count(value: int, singular: String, plural: String) -> String:
	if value == 1:
		return "1 %s" % singular
	return "%d %s" % [value, plural]

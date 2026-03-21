extends Control

const GLOBAL_DATA = preload("res://Src/Global.gd")
const CORRECT_SFX_BASE_DB := -8.0
const FAIL_SFX_BASE_DB := -4.5
const SUCCESS_SFX_BASE_DB := -3.0

@onready var back_btn: Button = %BackBtn
@onready var github_link_btn: LinkButton = %GithubLinkBtn
@onready var show_arrows_toggle: CheckButton = %ShowArrowsToggle
@onready var require_holding_toggle: CheckButton = %RequireHoldingToggle
@onready var mode_label: Label = %ModeLabel
@onready var status_label: Label = %StatusLabel
@onready var hint_label: Label = %HintLabel
@onready var hold_state_label: Label = %HoldStateLabel
@onready var strategem_box = %StrategemBox
@onready var correct_sfx: AudioStreamPlayer = %CorrectSfx
@onready var fail_sfx: AudioStreamPlayer = %FailSfx
@onready var success_sfx: AudioStreamPlayer = %SuccessSfx

var selected_strat_ids: Array[String] = []
var trainable_strat_ids: Array[String] = []
var current_strat_id := ""
var current_sequence: Array = []
var randomize_mode := false
var audio_volume := GLOBAL_DATA.DEFAULT_AUDIO_VOLUME
var show_stratagem_arrows := GLOBAL_DATA.DEFAULT_SHOW_STRATAGEM_ARROWS
var require_holding := GLOBAL_DATA.DEFAULT_REQUIRE_HOLD
var hold_binding: Dictionary = GLOBAL_DATA.get_default_hold_binding()
var direction_bindings: Dictionary = GLOBAL_DATA.get_default_direction_bindings()
var sequence_index := 0
var queue_index := 0
var input_locked := false
var hold_feedback_active := false
var hold_state_base_scale := Vector2.ONE
var rng := RandomNumberGenerator.new()


func _ready() -> void:
	rng.randomize()
	hold_state_base_scale = hold_state_label.scale
	back_btn.focus_mode = Control.FOCUS_NONE
	back_btn.pressed.connect(_on_back_pressed)
	github_link_btn.pressed.connect(_on_github_link_pressed)
	_load_config()
	show_arrows_toggle.button_pressed = show_stratagem_arrows
	require_holding_toggle.button_pressed = require_holding
	show_arrows_toggle.toggled.connect(_on_show_arrows_toggled)
	require_holding_toggle.toggled.connect(_on_require_holding_toggled)
	_configure_audio_players()
	_update_mode_label()
	_apply_show_arrows_setting()
	_update_controls_hint()
	_refresh_hold_feedback(true)
	if trainable_strat_ids.is_empty():
		strategem_box.visible = false
		hold_state_label.visible = false
		status_label.text = "No trainable stratagems selected."
		hint_label.text = "Return to the main screen and add at least one stratagem."
		return

	strategem_box.visible = true
	_load_next_stratagem()


func _process(_delta: float) -> void:
	_refresh_hold_feedback()


func _input(event: InputEvent) -> void:
	if event is not InputEventKey:
		return

	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return

	if key_event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		_on_back_pressed()
		return

	if input_locked or current_sequence.is_empty():
		return

	var input_arrow := GLOBAL_DATA.get_arrow_for_direction_event(key_event, direction_bindings)
	if input_arrow == -1:
		return

	if require_holding and not GLOBAL_DATA.is_binding_pressed(hold_binding):
		return

	get_viewport().set_input_as_handled()
	_handle_input_arrow(input_arrow)


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
	_play_success_sfx()
	status_label.text = "Sequence complete. Loading next stratagem..."
	strategem_box.pulse_success()
	await get_tree().create_timer(0.45).timeout
	input_locked = false
	_load_next_stratagem()


func _fail_current_sequence() -> void:
	input_locked = true
	_play_fail_sfx()
	status_label.text = "Incorrect input. Sequence reset."
	strategem_box.set_input_progress(sequence_index, sequence_index)
	strategem_box.pulse_arrow(sequence_index, Color(1.0, 0.45, 0.45, 1.0))
	strategem_box.flash_failure()
	await get_tree().create_timer(0.24).timeout
	sequence_index = 0
	strategem_box.set_input_progress(sequence_index)
	input_locked = false


func _load_next_stratagem() -> void:
	current_strat_id = _pick_next_stratagem_id()
	if current_strat_id.is_empty():
		status_label.text = "No trainable stratagems selected."
		return

	var strat: Dictionary = Global.STRATAGEMS[current_strat_id]
	current_sequence = strat["sequence"]
	sequence_index = 0
	strategem_box.set_strategem(current_strat_id, strat)
	strategem_box.set_input_progress(sequence_index)
	_update_progress_status()


func _pick_next_stratagem_id() -> String:
	if trainable_strat_ids.is_empty():
		return ""

	if randomize_mode:
		if trainable_strat_ids.size() == 1:
			return trainable_strat_ids[0]

		var candidates := trainable_strat_ids.duplicate()
		candidates.erase(current_strat_id)
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


func _on_show_arrows_toggled(toggled_on: bool) -> void:
	show_stratagem_arrows = toggled_on
	_apply_show_arrows_setting()
	_save_user_config()


func _on_require_holding_toggled(toggled_on: bool) -> void:
	require_holding = toggled_on
	_update_controls_hint()
	_refresh_hold_feedback(true)
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
	var hint_text := "Use %s" % GLOBAL_DATA.get_direction_binding_summary(direction_bindings)
	if require_holding:
		hint_text += "  |  Hold %s to input" % GLOBAL_DATA.get_binding_label(hold_binding)
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

	var next_active := GLOBAL_DATA.is_binding_pressed(hold_binding)
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
		hold_state_label.text = "Hold %s to input" % GLOBAL_DATA.get_binding_label(hold_binding)
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
		direction_bindings
	)
	if err != OK:
		push_warning("Failed to save user config: %s" % err)

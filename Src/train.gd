extends Control

const GLOBAL_DATA = preload("res://Src/Global.gd")
const CORRECT_SFX_BASE_DB := -8.0
const FAIL_SFX_BASE_DB := -4.5
const SUCCESS_SFX_BASE_DB := -3.0

@onready var back_btn: Button = %BackBtn
@onready var show_arrows_toggle: CheckButton = %ShowArrowsToggle
@onready var mode_label: Label = %ModeLabel
@onready var status_label: Label = %StatusLabel
@onready var hint_label: Label = %HintLabel
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
var sequence_index := 0
var queue_index := 0
var input_locked := false
var rng := RandomNumberGenerator.new()


func _ready() -> void:
	rng.randomize()
	back_btn.focus_mode = Control.FOCUS_NONE
	back_btn.pressed.connect(_on_back_pressed)
	_load_config()
	show_arrows_toggle.button_pressed = show_stratagem_arrows
	show_arrows_toggle.toggled.connect(_on_show_arrows_toggled)
	_configure_audio_players()
	_update_mode_label()
	_apply_show_arrows_setting()

	hint_label.text = "Use WASD or Arrow Keys  |  Press Esc to go back"
	if trainable_strat_ids.is_empty():
		strategem_box.visible = false
		status_label.text = "No trainable stratagems selected."
		hint_label.text = "Return to the main screen and add at least one stratagem."
		return

	strategem_box.visible = true
	_load_next_stratagem()


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

	var input_arrow := _map_key_to_arrow(key_event)
	if input_arrow == -1:
		return

	get_viewport().set_input_as_handled()
	_handle_input_arrow(input_arrow)


func _load_config() -> void:
	var config := GLOBAL_DATA.load_practice_config()
	selected_strat_ids = config["selected_strat_ids"]
	randomize_mode = config["randomize_mode"]
	audio_volume = config["audio_volume"]
	show_stratagem_arrows = config["show_stratagem_arrows"]
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


func _map_key_to_arrow(event: InputEventKey) -> int:
	if event.physical_keycode == KEY_W or event.keycode == KEY_UP:
		return Global.ARROW.UP
	if event.physical_keycode == KEY_A or event.keycode == KEY_LEFT:
		return Global.ARROW.LEFT
	if event.physical_keycode == KEY_S or event.keycode == KEY_DOWN:
		return Global.ARROW.DOWN
	if event.physical_keycode == KEY_D or event.keycode == KEY_RIGHT:
		return Global.ARROW.RIGHT
	return -1


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


func _on_show_arrows_toggled(toggled_on: bool) -> void:
	show_stratagem_arrows = toggled_on
	_apply_show_arrows_setting()
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


func _save_user_config() -> void:
	var err := GLOBAL_DATA.save_practice_config(
		selected_strat_ids,
		randomize_mode,
		audio_volume,
		show_stratagem_arrows
	)
	if err != OK:
		push_warning("Failed to save user config: %s" % err)

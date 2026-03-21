extends Control

signal config_changed(config: Dictionary)
signal popup_closed

const GLOBAL_DATA = preload("res://Src/Global.gd")

@onready var dismiss_btn: Button = %DismissBtn
@onready var close_btn: Button = %CloseBtn
@onready var settings_tabs: TabContainer = %SettingsTabs
@onready var general_tab: VBoxContainer = %GeneralTab
@onready var keyboard_tab: VBoxContainer = %KeyboardTab
@onready var controller_tab: VBoxContainer = %ControllerTab
@onready var randomize_toggle: CheckButton = %RandomizeToggle
@onready var show_arrows_toggle: CheckButton = %ShowArrowsToggle
@onready var require_holding_toggle: CheckButton = %RequireHoldingToggle
@onready var audio_volume_slider: HSlider = %AudioVolumeSlider
@onready var audio_volume_value_label: Label = %AudioVolumeValueLabel
@onready var reset_defaults_btn: Button = %ResetDefaultsBtn
@onready var hold_binding_btn: Button = %HoldBindingBtn
@onready var bindings_help_label: Label = %BindingsHelpLabel
@onready var web_hold_warning_label: RichTextLabel = %WebHoldWarningLabel
@onready var up_primary_btn: Button = %UpPrimaryBtn
@onready var up_secondary_btn: Button = %UpSecondaryBtn
@onready var left_primary_btn: Button = %LeftPrimaryBtn
@onready var left_secondary_btn: Button = %LeftSecondaryBtn
@onready var down_primary_btn: Button = %DownPrimaryBtn
@onready var down_secondary_btn: Button = %DownSecondaryBtn
@onready var right_primary_btn: Button = %RightPrimaryBtn
@onready var right_secondary_btn: Button = %RightSecondaryBtn
@onready var controller_hold_binding_btn: Button = %ControllerHoldBindingBtn
@onready var controller_up_btn: Button = %ControllerUpBtn
@onready var controller_left_btn: Button = %ControllerLeftBtn
@onready var controller_down_btn: Button = %ControllerDownBtn
@onready var controller_right_btn: Button = %ControllerRightBtn

var randomize_mode := false
var audio_volume := GLOBAL_DATA.DEFAULT_AUDIO_VOLUME
var show_stratagem_arrows := GLOBAL_DATA.DEFAULT_SHOW_STRATAGEM_ARROWS
var require_holding := GLOBAL_DATA.DEFAULT_REQUIRE_HOLD
var hold_binding: Dictionary = GLOBAL_DATA.get_default_hold_binding()
var direction_bindings: Dictionary = GLOBAL_DATA.get_default_direction_bindings()
var controller_hold_binding: Dictionary = GLOBAL_DATA.get_default_controller_hold_binding()
var controller_direction_bindings: Dictionary = GLOBAL_DATA.get_default_controller_direction_bindings()
var binding_buttons := {}
var pending_binding_slot := ""
var binding_capture_ready_frame := -1


func _ready() -> void:
	visible = false
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
		"controller_hold": controller_hold_binding_btn,
		"controller_up": controller_up_btn,
		"controller_left": controller_left_btn,
		"controller_down": controller_down_btn,
		"controller_right": controller_right_btn,
	}
	dismiss_btn.pressed.connect(_on_close_pressed)
	close_btn.pressed.connect(_on_close_pressed)
	randomize_toggle.toggled.connect(_on_randomize_toggled)
	show_arrows_toggle.toggled.connect(_on_show_arrows_toggled)
	require_holding_toggle.toggled.connect(_on_require_holding_toggled)
	audio_volume_slider.value_changed.connect(_on_audio_volume_changed)
	reset_defaults_btn.pressed.connect(_on_reset_defaults_pressed)
	web_hold_warning_label.meta_clicked.connect(_on_web_hold_warning_meta_clicked)
	for slot_id in binding_buttons.keys():
		var button: Button = binding_buttons[slot_id]
		button.pressed.connect(_on_binding_capture_requested.bind(slot_id))
	settings_tabs.set_tab_title(settings_tabs.get_tab_idx_from_control(general_tab), "General")
	settings_tabs.set_tab_title(settings_tabs.get_tab_idx_from_control(keyboard_tab), "Keyboard")
	settings_tabs.set_tab_title(settings_tabs.get_tab_idx_from_control(controller_tab), "Controller")
	_sync_controls_from_state()


func _input(event: InputEvent) -> void:
	if not visible:
		return

	if event is InputEventKey:
		var key_event := event as InputEventKey
		if key_event.pressed and not key_event.echo and key_event.keycode == KEY_ESCAPE:
			get_viewport().set_input_as_handled()
			if not pending_binding_slot.is_empty():
				_cancel_binding_capture()
			else:
				_close_popup()
			return

	if pending_binding_slot.is_empty():
		return

	if Engine.get_process_frames() <= binding_capture_ready_frame:
		return

	if event is InputEventKey:
		if _is_controller_binding_slot(pending_binding_slot):
			return

		var capture_key_event := event as InputEventKey
		if not capture_key_event.pressed or capture_key_event.echo:
			return

		get_viewport().set_input_as_handled()
		_apply_captured_binding(pending_binding_slot, GLOBAL_DATA.binding_from_key_event(capture_key_event))
		return

	if event is InputEventJoypadButton:
		if not _is_controller_binding_slot(pending_binding_slot):
			return

		var joypad_event := event as InputEventJoypadButton
		if not joypad_event.pressed:
			return

		get_viewport().set_input_as_handled()
		_apply_captured_binding(pending_binding_slot, GLOBAL_DATA.binding_from_joypad_button_event(joypad_event))
		return

	if pending_binding_slot != "hold" or event is not InputEventMouseButton:
		return

	var mouse_event := event as InputEventMouseButton
	if not mouse_event.pressed or not GLOBAL_DATA.is_supported_mouse_button(mouse_event.button_index):
		return

	get_viewport().set_input_as_handled()
	_apply_captured_binding(pending_binding_slot, GLOBAL_DATA.binding_from_mouse_button_event(mouse_event))


func open_with_config(config: Dictionary) -> void:
	_apply_config(config)
	_cancel_binding_capture(false)
	settings_tabs.current_tab = 0
	visible = true
	close_btn.grab_focus()


func _close_popup() -> void:
	_cancel_binding_capture(false)
	visible = false
	popup_closed.emit()


func _apply_config(config: Dictionary) -> void:
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
	_sync_controls_from_state()


func _sync_controls_from_state() -> void:
	randomize_toggle.set_pressed_no_signal(randomize_mode)
	show_arrows_toggle.set_pressed_no_signal(show_stratagem_arrows)
	require_holding_toggle.set_pressed_no_signal(require_holding)
	audio_volume_slider.set_value_no_signal(audio_volume * 100.0)
	_update_volume_controls()
	_update_binding_controls()


func _build_config() -> Dictionary:
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


func _emit_config_changed() -> void:
	config_changed.emit(_build_config())


func _on_close_pressed() -> void:
	_close_popup()


func _on_randomize_toggled(toggled_on: bool) -> void:
	randomize_mode = toggled_on
	_emit_config_changed()


func _on_show_arrows_toggled(toggled_on: bool) -> void:
	show_stratagem_arrows = toggled_on
	_emit_config_changed()


func _on_require_holding_toggled(toggled_on: bool) -> void:
	require_holding = toggled_on
	_emit_config_changed()


func _on_audio_volume_changed(value: float) -> void:
	audio_volume = clampf(value / 100.0, 0.0, 1.0)
	_update_volume_controls()
	_emit_config_changed()


func _on_reset_defaults_pressed() -> void:
	_cancel_binding_capture(false)
	randomize_mode = false
	show_stratagem_arrows = GLOBAL_DATA.DEFAULT_SHOW_STRATAGEM_ARROWS
	require_holding = GLOBAL_DATA.DEFAULT_REQUIRE_HOLD
	audio_volume = GLOBAL_DATA.DEFAULT_AUDIO_VOLUME
	hold_binding = GLOBAL_DATA.get_default_hold_binding()
	direction_bindings = GLOBAL_DATA.get_default_direction_bindings()
	controller_hold_binding = GLOBAL_DATA.get_default_controller_hold_binding()
	controller_direction_bindings = GLOBAL_DATA.get_default_controller_direction_bindings()
	_sync_controls_from_state()
	_emit_config_changed()


func _update_volume_controls() -> void:
	audio_volume_value_label.text = "%d%%" % int(round(audio_volume * 100.0))


func _update_binding_controls() -> void:
	hold_binding_btn.text = _get_binding_button_text("hold")
	up_primary_btn.text = _get_binding_button_text("up_primary")
	up_secondary_btn.text = _get_binding_button_text("up_secondary")
	left_primary_btn.text = _get_binding_button_text("left_primary")
	left_secondary_btn.text = _get_binding_button_text("left_secondary")
	down_primary_btn.text = _get_binding_button_text("down_primary")
	down_secondary_btn.text = _get_binding_button_text("down_secondary")
	right_primary_btn.text = _get_binding_button_text("right_primary")
	right_secondary_btn.text = _get_binding_button_text("right_secondary")
	controller_hold_binding_btn.text = _get_binding_button_text("controller_hold")
	controller_up_btn.text = _get_binding_button_text("controller_up")
	controller_left_btn.text = _get_binding_button_text("controller_left")
	controller_down_btn.text = _get_binding_button_text("controller_down")
	controller_right_btn.text = _get_binding_button_text("controller_right")

	if pending_binding_slot.is_empty():
		bindings_help_label.text = "Keyboard and controller bindings stay active together. Controller defaults to D-Pad with L1 / LB hold."
	elif pending_binding_slot == "controller_hold":
		bindings_help_label.text = "Press a controller button for Controller Hold. Press Esc to cancel."
	elif _is_controller_binding_slot(pending_binding_slot):
		bindings_help_label.text = "Press a controller button for %s. Press Esc to cancel." % _get_binding_slot_label(pending_binding_slot)
	elif pending_binding_slot == "hold":
		bindings_help_label.text = "Press a key or mouse button for hold input. Press Esc to cancel."
	else:
		bindings_help_label.text = "Press a key for %s. Press Esc to cancel." % _get_binding_slot_label(pending_binding_slot)

	_update_web_hold_warning()


func _on_binding_capture_requested(slot_id: String) -> void:
	if pending_binding_slot == slot_id:
		_cancel_binding_capture()
		return

	pending_binding_slot = slot_id
	binding_capture_ready_frame = Engine.get_process_frames()
	_update_binding_controls()


func _apply_captured_binding(slot_id: String, binding: Dictionary) -> void:
	if slot_id == "hold":
		hold_binding = GLOBAL_DATA.sanitize_input_binding(binding, hold_binding, true, false)
	elif slot_id == "controller_hold":
		controller_hold_binding = GLOBAL_DATA.sanitize_input_binding(binding, controller_hold_binding, false, true)
	elif _is_controller_binding_slot(slot_id):
		var controller_slot_id := _get_controller_slot_id(slot_id)
		var controller_fallback: Dictionary = controller_direction_bindings.get(
			controller_slot_id,
			GLOBAL_DATA.DEFAULT_CONTROLLER_DIRECTION_BINDINGS[controller_slot_id]
		)
		controller_direction_bindings[controller_slot_id] = GLOBAL_DATA.sanitize_input_binding(
			binding,
			controller_fallback,
			false,
			true
		)
	else:
		var fallback: Dictionary = direction_bindings.get(slot_id, GLOBAL_DATA.DEFAULT_DIRECTION_BINDINGS[slot_id])
		direction_bindings[slot_id] = GLOBAL_DATA.sanitize_input_binding(binding, fallback, false, false)

	_cancel_binding_capture(false)
	_update_binding_controls()
	_emit_config_changed()


func _cancel_binding_capture(refresh_ui := true) -> void:
	pending_binding_slot = ""
	binding_capture_ready_frame = -1
	if refresh_ui:
		_update_binding_controls()


func _get_binding_button_text(slot_id: String) -> String:
	if pending_binding_slot == slot_id:
		if slot_id == "hold":
			return "Press input..."
		if _is_controller_binding_slot(slot_id):
			return "Press pad..."
		return "Press key..."

	if slot_id == "hold":
		return GLOBAL_DATA.get_binding_label(hold_binding)
	if slot_id == "controller_hold":
		return GLOBAL_DATA.get_binding_label(controller_hold_binding)
	if _is_controller_binding_slot(slot_id):
		var controller_slot_id := _get_controller_slot_id(slot_id)
		return GLOBAL_DATA.get_binding_label(
			controller_direction_bindings.get(
				controller_slot_id,
				GLOBAL_DATA.DEFAULT_CONTROLLER_DIRECTION_BINDINGS[controller_slot_id]
			)
		)

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
		"controller_hold":
			return "Controller Hold"
		"controller_up":
			return "Controller Up"
		"controller_left":
			return "Controller Left"
		"controller_down":
			return "Controller Down"
		"controller_right":
			return "Controller Right"
		"hold":
			return "Hold Input"
		_:
			return "Binding"


func _is_controller_binding_slot(slot_id: String) -> bool:
	return slot_id.begins_with("controller_")


func _get_controller_slot_id(slot_id: String) -> String:
	match slot_id:
		"controller_up":
			return "up"
		"controller_left":
			return "left"
		"controller_down":
			return "down"
		"controller_right":
			return "right"
		_:
			return ""


func _update_web_hold_warning() -> void:
	if not OS.has_feature("web"):
		web_hold_warning_label.visible = false
		return

	var is_ctrl_hold := (
		require_holding
		and str(hold_binding.get("type", "")) == "key"
		and int(hold_binding.get("keycode", KEY_NONE)) == KEY_CTRL
	)
	web_hold_warning_label.visible = is_ctrl_hold


func _on_web_hold_warning_meta_clicked(meta: Variant) -> void:
	if str(meta) != "releases":
		return

	var err := OS.shell_open(GLOBAL_DATA.GITHUB_RELEASES_URL)
	if err != OK:
		push_warning("Failed to open GitHub releases link: %s" % err)

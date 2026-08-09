extends Window

signal catalogue_changed
signal stratagem_deleted(strat_id: String)

const GLOBAL_DATA = preload("res://Src/Global.gd")
const ARROW_CODE_ICON = preload("res://Src/arrow_code_icon.tscn")
const DIALOG_SIZE := Vector2i(680, 720)

var selector: OptionButton
var name_input: LineEdit
var category_input: OptionButton
var code_input: LineEdit
var code_preview: HFlowContainer
var icon_preview: TextureRect
var icon_file_label: Label
var delete_btn: Button
var save_btn: Button
var status_label: Label
var file_dialog: FileDialog
var delete_confirmation: ConfirmationDialog

var editing_strat_id := ""
var pending_icon_bytes := PackedByteArray()
var pending_icon_file_name := ""
var _web_upload_callback: Variant


func _ready() -> void:
	title = "Player-created Stratagems"
	min_size = Vector2i(560, 620)
	size = DIALOG_SIZE
	transient = true
	exclusive = false
	close_requested.connect(hide)
	_build_ui()
	_build_file_dialog()
	_build_delete_confirmation()
	if OS.has_feature("web"):
		_web_upload_callback = JavaScriptBridge.create_callback(_on_web_icon_selected)
		var browser_window = JavaScriptBridge.get_interface("window")
		browser_window.hd2CustomIconSelected = _web_upload_callback


func open_for(strat_id := "") -> void:
	_refresh_selector(strat_id)
	if strat_id.is_empty() or not GLOBAL_DATA.is_custom_stratagem(strat_id):
		_start_new_stratagem()
	else:
		_load_stratagem(strat_id)
	popup_centered(DIALOG_SIZE)


func _build_ui() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_bottom", 20)
	add_child(margin)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	margin.add_child(content)

	var heading := Label.new()
	heading.text = "PLAYER-CREATED STRATAGEMS"
	heading.add_theme_font_size_override("font_size", 26)
	heading.add_theme_color_override("font_color", Color("ffd27e"))
	content.add_child(heading)

	var persistence_note := Label.new()
	persistence_note.text = "Saved only on this PC, or in this browser profile's local storage. Nothing is uploaded."
	persistence_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	persistence_note.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.68))
	content.add_child(persistence_note)

	selector = OptionButton.new()
	selector.custom_minimum_size = Vector2(0, 42)
	selector.item_selected.connect(_on_selector_selected)
	content.add_child(selector)

	content.add_child(HSeparator.new())

	var form := GridContainer.new()
	form.columns = 2
	form.add_theme_constant_override("h_separation", 16)
	form.add_theme_constant_override("v_separation", 12)
	content.add_child(form)

	form.add_child(_make_form_label("Name"))
	name_input = LineEdit.new()
	name_input.max_length = 48
	name_input.placeholder_text = "My custom stratagem"
	name_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	form.add_child(name_input)

	form.add_child(_make_form_label("Category"))
	category_input = OptionButton.new()
	for category in GLOBAL_DATA.STRATAGEM_CATEGORY_ORDER:
		category_input.add_item(GLOBAL_DATA.STRATAGEM_CATEGORY_LABELS[category])
		category_input.set_item_metadata(category_input.item_count - 1, category)
	form.add_child(category_input)

	form.add_child(_make_form_label("Input code"))
	code_input = LineEdit.new()
	code_input.placeholder_text = "U R D L  (spaces optional)"
	code_input.text_changed.connect(_on_code_changed)
	form.add_child(code_input)

	form.add_child(_make_form_label("Code preview"))
	code_preview = HFlowContainer.new()
	code_preview.custom_minimum_size = Vector2(0, 34)
	code_preview.add_theme_constant_override("h_separation", 4)
	code_preview.add_theme_constant_override("v_separation", 4)
	form.add_child(code_preview)

	var icon_label := _make_form_label("Icon")
	icon_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	form.add_child(icon_label)

	var icon_row := HBoxContainer.new()
	icon_row.add_theme_constant_override("separation", 14)
	form.add_child(icon_row)

	icon_preview = TextureRect.new()
	icon_preview.custom_minimum_size = Vector2(108, 108)
	icon_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_row.add_child(icon_preview)

	var icon_controls := VBoxContainer.new()
	icon_controls.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	icon_controls.add_theme_constant_override("separation", 8)
	icon_row.add_child(icon_controls)

	var choose_icon_btn := Button.new()
	choose_icon_btn.text = "Choose SVG / Image"
	choose_icon_btn.custom_minimum_size = Vector2(0, 40)
	choose_icon_btn.pressed.connect(_on_choose_icon_pressed)
	icon_controls.add_child(choose_icon_btn)

	icon_file_label = Label.new()
	icon_file_label.text = "No icon selected"
	icon_file_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	icon_file_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.66))
	icon_controls.add_child(icon_file_label)

	var icon_help := Label.new()
	icon_help.text = "PNG, JPG, WebP, or SVG • up to 3 MB • 2048 px max"
	icon_help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	icon_help.add_theme_font_size_override("font_size", 13)
	icon_help.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.5))
	icon_controls.add_child(icon_help)

	status_label = Label.new()
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.custom_minimum_size = Vector2(0, 30)
	content.add_child(status_label)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(spacer)

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 10)
	content.add_child(actions)

	delete_btn = Button.new()
	delete_btn.text = "Delete"
	delete_btn.pressed.connect(_on_delete_pressed)
	actions.add_child(delete_btn)

	var action_spacer := Control.new()
	action_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_child(action_spacer)

	var cancel_btn := Button.new()
	cancel_btn.text = "Close"
	cancel_btn.custom_minimum_size = Vector2(100, 42)
	cancel_btn.pressed.connect(hide)
	actions.add_child(cancel_btn)

	save_btn = Button.new()
	save_btn.text = "Save Stratagem"
	save_btn.custom_minimum_size = Vector2(160, 42)
	save_btn.pressed.connect(_on_save_pressed)
	actions.add_child(save_btn)


func _make_form_label(text_value: String) -> Label:
	var label := Label.new()
	label.text = text_value
	label.custom_minimum_size = Vector2(112, 36)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return label


func _build_file_dialog() -> void:
	file_dialog = FileDialog.new()
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	file_dialog.use_native_dialog = true
	file_dialog.filters = PackedStringArray([
		"*.png,*.jpg,*.jpeg,*.webp,*.svg;Icon images;image/png,image/jpeg,image/webp,image/svg+xml",
	])
	file_dialog.file_selected.connect(_on_native_icon_selected)
	add_child(file_dialog)


func _build_delete_confirmation() -> void:
	delete_confirmation = ConfirmationDialog.new()
	delete_confirmation.title = "Delete custom stratagem?"
	delete_confirmation.dialog_text = "This permanently removes the player-created stratagem and its locally saved icon."
	delete_confirmation.confirmed.connect(_delete_current_stratagem)
	add_child(delete_confirmation)


func _refresh_selector(selected_id := "") -> void:
	selector.clear()
	selector.add_item("+ Create a new stratagem")
	selector.set_item_metadata(0, "")
	var custom_stratagems := GLOBAL_DATA.get_custom_stratagems()
	var strat_ids := custom_stratagems.keys()
	strat_ids.sort_custom(_sort_custom_ids_by_name)
	for strat_id in strat_ids:
		selector.add_item(str(custom_stratagems[strat_id]["name"]))
		selector.set_item_metadata(selector.item_count - 1, strat_id)
		if strat_id == selected_id:
			selector.select(selector.item_count - 1)


func _sort_custom_ids_by_name(a: String, b: String) -> bool:
	return str(GLOBAL_DATA.get_stratagem(a)["name"]) < str(GLOBAL_DATA.get_stratagem(b)["name"])


func _on_selector_selected(index: int) -> void:
	var strat_id := str(selector.get_item_metadata(index))
	if strat_id.is_empty():
		_start_new_stratagem()
	else:
		_load_stratagem(strat_id)


func _start_new_stratagem() -> void:
	editing_strat_id = ""
	selector.select(0)
	name_input.clear()
	category_input.select(GLOBAL_DATA.STRATAGEM_CATEGORY_ORDER.find("support"))
	code_input.clear()
	icon_preview.texture = null
	icon_file_label.text = "No icon selected"
	pending_icon_bytes.clear()
	pending_icon_file_name = ""
	delete_btn.visible = false
	save_btn.text = "Add Stratagem"
	_set_status("")
	_update_code_preview()


func _load_stratagem(strat_id: String) -> void:
	var strat := GLOBAL_DATA.get_stratagem(strat_id)
	if strat.is_empty() or not GLOBAL_DATA.is_custom_stratagem(strat_id):
		_start_new_stratagem()
		return
	editing_strat_id = strat_id
	name_input.text = strat["name"]
	_select_category(str(strat["category"]))
	code_input.text = _format_sequence(strat["sequence"])
	icon_preview.texture = strat["icon"]
	icon_file_label.text = "Current locally saved icon"
	pending_icon_bytes.clear()
	pending_icon_file_name = ""
	delete_btn.visible = true
	save_btn.text = "Save Changes"
	_set_status("")
	_update_code_preview()


func _select_category(category: String) -> void:
	for index in category_input.item_count:
		if str(category_input.get_item_metadata(index)) == category:
			category_input.select(index)
			return


func _on_code_changed(_value: String) -> void:
	_update_code_preview()


func _update_code_preview() -> void:
	for child in code_preview.get_children():
		child.queue_free()

	var parsed := _parse_sequence(code_input.text)
	if bool(parsed.get("ok", false)):
		for direction in parsed["sequence"]:
			var arrow: ArrowCodeIcon = ARROW_CODE_ICON.instantiate()
			arrow.custom_minimum_size = Vector2(30, 30)
			arrow.set_arrow(direction)
			code_preview.add_child(arrow)
	else:
		var message := Label.new()
		message.text = "—" if code_input.text.strip_edges().is_empty() else str(parsed.get("error", "Invalid code"))
		message.add_theme_color_override("font_color", Color("ff8b7a"))
		code_preview.add_child(message)


func _parse_sequence(raw_code: String) -> Dictionary:
	var normalized := raw_code.to_upper().strip_edges()
	if normalized.is_empty():
		return {"ok": false, "error": "Enter a code"}
	for prefix in ["ARROW_", "ARROW.", "ARROW"]:
		normalized = normalized.replace(prefix, "")
	normalized = normalized.replace("RIGHT", "R")
	normalized = normalized.replace("LEFT", "L")
	normalized = normalized.replace("DOWN", "D")
	normalized = normalized.replace("UP", "U")
	normalized = normalized.replace("→", "R")
	normalized = normalized.replace("←", "L")
	normalized = normalized.replace("↓", "D")
	normalized = normalized.replace("↑", "U")
	for separator in [" ", "\t", "\n", ",", ">", "-", "/", "|", ";", ":"]:
		normalized = normalized.replace(separator, "")

	var sequence: Array = []
	for character in normalized:
		match character:
			"D":
				sequence.append(GLOBAL_DATA.ARROW.DOWN)
			"L":
				sequence.append(GLOBAL_DATA.ARROW.LEFT)
			"U":
				sequence.append(GLOBAL_DATA.ARROW.UP)
			"R":
				sequence.append(GLOBAL_DATA.ARROW.RIGHT)
			_:
				return {"ok": false, "error": "Use only U, D, L, R or arrows"}
	if sequence.is_empty() or sequence.size() > 20:
		return {"ok": false, "error": "Use 1–20 directions"}
	return {"ok": true, "sequence": sequence}


func _format_sequence(sequence: Array) -> String:
	var symbols: Array[String] = []
	for arrow in sequence:
		match int(arrow):
			GLOBAL_DATA.ARROW.DOWN:
				symbols.append("D")
			GLOBAL_DATA.ARROW.LEFT:
				symbols.append("L")
			GLOBAL_DATA.ARROW.UP:
				symbols.append("U")
			GLOBAL_DATA.ARROW.RIGHT:
				symbols.append("R")
	return " ".join(symbols)


func _on_choose_icon_pressed() -> void:
	_set_status("")
	if OS.has_feature("web"):
		JavaScriptBridge.eval("""
			(() => {
				const input = document.createElement('input');
				input.type = 'file';
				input.accept = 'image/png,image/jpeg,image/webp,image/svg+xml,.svg';
				input.onchange = async () => {
					const file = input.files && input.files[0];
					if (file) {
						const buffer = await file.arrayBuffer();
						window.hd2CustomIconSelected(buffer, file.name);
					}
					input.remove();
				};
				input.oncancel = () => input.remove();
				input.click();
			})();
		""", true)
	else:
		file_dialog.popup_file_dialog()


func _on_native_icon_selected(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		_set_status("Could not read the selected icon.", true)
		return
	if file.get_length() > GLOBAL_DATA.CUSTOM_ICON_MAX_BYTES:
		_set_status("Icons must be smaller than 3 MB.", true)
		return
	_accept_icon_bytes(file.get_buffer(file.get_length()), path.get_file())


func _on_web_icon_selected(arguments: Array) -> void:
	if arguments.size() < 2:
		_set_status("The browser did not return an icon.", true)
		return
	var bytes := PackedByteArray()
	if arguments[0] is PackedByteArray:
		bytes = arguments[0]
	elif JavaScriptBridge.is_js_buffer(arguments[0]):
		bytes = JavaScriptBridge.js_buffer_to_packed_byte_array(arguments[0])
	else:
		_set_status("The browser returned an unsupported icon.", true)
		return
	_accept_icon_bytes(bytes, str(arguments[1]))


func _accept_icon_bytes(bytes: PackedByteArray, file_name: String) -> void:
	var preview_result := GLOBAL_DATA.create_custom_icon_preview(bytes, file_name)
	if not bool(preview_result.get("ok", false)):
		_set_status(str(preview_result.get("error", "Invalid icon.")), true)
		return
	pending_icon_bytes = bytes
	pending_icon_file_name = file_name
	icon_preview.texture = preview_result["texture"]
	icon_file_label.text = file_name
	_set_status("Icon ready. Save to persist it locally.")


func _on_save_pressed() -> void:
	var parsed := _parse_sequence(code_input.text)
	if not bool(parsed.get("ok", false)):
		_set_status(str(parsed.get("error", "Enter a valid input code.")), true)
		return
	var category := str(category_input.get_item_metadata(category_input.selected))
	var result := GLOBAL_DATA.save_custom_stratagem(
		editing_strat_id,
		name_input.text,
		category,
		parsed["sequence"],
		pending_icon_bytes,
		pending_icon_file_name
	)
	if not bool(result.get("ok", false)):
		_set_status(str(result.get("error", "Could not save the stratagem.")), true)
		return

	editing_strat_id = str(result["id"])
	pending_icon_bytes.clear()
	pending_icon_file_name = ""
	_refresh_selector(editing_strat_id)
	_load_stratagem(editing_strat_id)
	_set_status("Saved locally.")
	catalogue_changed.emit()


func _on_delete_pressed() -> void:
	if editing_strat_id.is_empty():
		return
	delete_confirmation.popup_centered()


func _delete_current_stratagem() -> void:
	if editing_strat_id.is_empty():
		return
	var deleted_id := editing_strat_id
	var delete_error := GLOBAL_DATA.delete_custom_stratagem(deleted_id)
	if delete_error != OK:
		_set_status("Could not delete the locally saved stratagem.", true)
		return
	stratagem_deleted.emit(deleted_id)
	catalogue_changed.emit()
	_refresh_selector()
	_start_new_stratagem()
	_set_status("Custom stratagem deleted.")


func _set_status(message: String, is_error := false) -> void:
	status_label.text = message
	status_label.add_theme_color_override(
		"font_color",
		Color("ff8b7a") if is_error else Color("85e2a5")
	)


func _exit_tree() -> void:
	if OS.has_feature("web"):
		var browser_window = JavaScriptBridge.get_interface("window")
		browser_window.hd2CustomIconSelected = null

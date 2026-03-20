extends PanelContainer

signal remove_requested(strat_id: String)

const GLOBAL_DATA = preload("res://Src/Global.gd")
const ARROW_CODE_ICON = preload("uid://bs2ww5vda85fw")

@onready var strat_icon: TextureRect = %StratIcon
@onready var strat_name: Label = %StratName
@onready var strat_codes: HBoxContainer = %StratCodes
@onready var remove_btn: Button = %RemoveBtn

@export var strat_id := ""
var show_sequence := GLOBAL_DATA.DEFAULT_SHOW_STRATAGEM_ARROWS


func _ready() -> void:
	remove_btn.pressed.connect(_on_remove_pressed)
	_clear_codes()
	if not strat_id.is_empty() and GLOBAL_DATA.STRATAGEMS.has(strat_id):
		_apply_stratagem(GLOBAL_DATA.STRATAGEMS[strat_id])


func set_stratagem(next_strat_id: String) -> void:
	strat_id = next_strat_id
	if is_node_ready() and GLOBAL_DATA.STRATAGEMS.has(strat_id):
		_apply_stratagem(GLOBAL_DATA.STRATAGEMS[strat_id])


func set_show_sequence(value: bool) -> void:
	show_sequence = value
	if is_node_ready():
		strat_codes.visible = show_sequence


func _apply_stratagem(strat: Dictionary) -> void:
	strat_icon.texture = strat["icon"]
	strat_name.text = strat["name"]
	_clear_codes()

	var sequence: Array = strat["sequence"]
	for code in sequence:
		var arrow: ArrowCodeIcon = ARROW_CODE_ICON.instantiate()
		arrow.custom_minimum_size = Vector2(18, 18)
		arrow.set_arrow(code)
		strat_codes.add_child(arrow)

	strat_codes.visible = show_sequence


func _clear_codes() -> void:
	for child in strat_codes.get_children():
		child.free()


func _on_remove_pressed() -> void:
	remove_requested.emit(strat_id)

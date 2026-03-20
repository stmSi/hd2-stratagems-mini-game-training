extends HBoxContainer
@onready var strategem_icon: TextureRect = %StrategemIcon
@onready var strategem_name: Label = %StrategemName
@onready var strategem_codes: HBoxContainer = %StrategemCodes

const ARROW_CODE_ICON = preload("uid://bs2ww5vda85fw")
@export var strat_id := ""
var strat_data: Dictionary = {}

func _ready() -> void:
	_clear_codes()
	if strat_data.is_empty() and not strat_id.is_empty() and Global.STRATAGEMS.has(strat_id):
		strat_data = Global.STRATAGEMS[strat_id]
	if not strat_data.is_empty():
		_apply_strategem()


func set_strategem(next_strat_id: String, strat: Dictionary) -> void:
	strat_id = next_strat_id
	strat_data = strat
	if is_node_ready():
		_apply_strategem()


func _apply_strategem() -> void:
	strategem_icon.texture = strat_data["icon"]
	strategem_name.text = strat_data["name"]
	_clear_codes()

	var sequence: Array = strat_data["sequence"]
	for code in sequence:
		var arrow: ArrowCodeIcon = ARROW_CODE_ICON.instantiate()
		arrow.set_arrow(code)
		strategem_codes.add_child(arrow)


func _clear_codes() -> void:
	for child in strategem_codes.get_children():
		child.free()

extends PanelContainer
class_name StrategemTooltip
@onready var strategem_box: HBoxContainer = %StrategemBox

var strat_id := ""
var strat_data: Dictionary = {}


func _ready() -> void:
	if not strat_data.is_empty():
		strategem_box.set_strategem(strat_id, strat_data)


func set_strategem(next_strat_id: String, strat: Dictionary) -> void:
	strat_id = next_strat_id
	strat_data = strat
	if is_node_ready():
		strategem_box.set_strategem(strat_id, strat_data)

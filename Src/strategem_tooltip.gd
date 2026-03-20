extends PanelContainer
class_name StrategemTooltip
@onready var strategem_box = %StrategemBox

var strat_id := ""
var strat_data: Dictionary = {}
var show_sequence := true


func _ready() -> void:
	strategem_box.set_show_sequence(show_sequence)
	if not strat_data.is_empty():
		strategem_box.set_strategem(strat_id, strat_data)


func set_strategem(next_strat_id: String, strat: Dictionary) -> void:
	strat_id = next_strat_id
	strat_data = strat
	if is_node_ready():
		strategem_box.set_strategem(strat_id, strat_data)


func set_show_sequence(value: bool) -> void:
	show_sequence = value
	if is_node_ready():
		strategem_box.set_show_sequence(show_sequence)

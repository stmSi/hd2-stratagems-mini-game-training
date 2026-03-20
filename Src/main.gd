extends Node

const GLOBAL_DATA = preload("res://Src/Global.gd")
const STRAT_ICON_SCENE = preload("uid://cw23thcgkm5wx")

@onready var list_of_strats: VBoxContainer = %ListOfStrats

var user_strat_list = []

func _ready() -> void:
	_populate_stratagem_list()


func _populate_stratagem_list() -> void:
	for child in list_of_strats.get_children():
		child.free()

	var grouped_stratagems := {}
	for category in GLOBAL_DATA.STRATAGEM_CATEGORY_ORDER:
		grouped_stratagems[category] = []

	for strat_id in GLOBAL_DATA.STRATAGEMS.keys():
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
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	list_of_strats.add_child(grid)

	for strat_id in strat_ids:
		var icon = STRAT_ICON_SCENE.instantiate()
		icon.set_stratagem(strat_id)
		grid.add_child(icon)

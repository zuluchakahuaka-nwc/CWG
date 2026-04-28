extends Control

var _selected_year: int = 1861

var _year_buttons: Dictionary = {}
var _year_scenarios: Dictionary = {
	1861: "civil_war",
	1862: "campaign_1862",
	1863: "campaign_1863",
	1864: "campaign_1864",
	1865: "campaign_1865",
	9999: "full_campaign"
}

@onready var _title: Label = $TitleLabel
@onready var _side_label: Label = $SideLabel
@onready var _back_btn: Button = $BackButton
@onready var _union_btn: Button = $SideHBox/UnionButton
@onready var _conf_btn: Button = $SideHBox/ConfederateButton
@onready var _vbox: VBoxContainer = $ScrollContainer/VBoxContainer

func _ready() -> void:
	_localize()
	_back_btn.pressed.connect(_on_back)
	_union_btn.pressed.connect(_on_union)
	_conf_btn.pressed.connect(_on_confederate)
	_build_year_buttons()
	_update_locks()

func _build_year_buttons() -> void:
	var keys: Array = [1861, 1862, 1863, 1864, 1865, 9999]
	var nodes: Array = [
		_vbox.get_node("Scenario1861"),
		_vbox.get_node("Scenario1862"),
		_vbox.get_node("Scenario1863"),
		_vbox.get_node("Scenario1864"),
		_vbox.get_node("Scenario1865"),
		_vbox.get_node("ScenarioFull"),
	]
	for i in range(keys.size()):
		var key: int = keys[i]
		var btn: Button = nodes[i]
		_year_buttons[key] = btn
		btn.pressed.connect(_on_year_selected.bind(key))

func _on_year_selected(year: int) -> void:
	if _year_buttons[year].disabled:
		return
	_selected_year = year
	_update_side_highlight()

func _update_locks() -> void:
	var completed: Array = GameManager.get_completed_campaigns()
	var prev_year: int = 1861
	for key in [1861, 1862, 1863, 1864, 1865, 9999]:
		var btn: Button = _year_buttons[key]
		if key == 1861:
			btn.disabled = false
		elif key == 9999:
			btn.disabled = not (1861 in completed and 1862 in completed and 1863 in completed and 1864 in completed and 1865 in completed)
		else:
			btn.disabled = not (prev_year in completed)
		if btn.disabled:
			btn.modulate = Color(0.4, 0.4, 0.4, 0.6)
		else:
			btn.modulate = Color(1.0, 1.0, 1.0, 1.0)
		prev_year = key

func _on_union() -> void:
	_start_game("union")

func _on_confederate() -> void:
	_start_game("confederate")

func _start_game(side: String) -> void:
	var scenario_id: String = _year_scenarios.get(_selected_year, "civil_war")
	GameManager.start_game(scenario_id, side)
	get_tree().change_scene_to_file("res://scenes/game_map.tscn")

func _update_side_highlight() -> void:
	_union_btn.modulate = Color(0.4, 0.6, 1.0)
	_conf_btn.modulate = Color(1.0, 0.4, 0.4)

func _localize() -> void:
	_title.text = "Гражданская война" if Localization.get_language() == "ru" else "Civil War"
	_side_label.text = Localization.t("game.choose_side")
	_union_btn.text = Localization.t("side.union")
	_conf_btn.text = Localization.t("side.confederate")
	_back_btn.text = Localization.t("game.back")

func _on_back() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

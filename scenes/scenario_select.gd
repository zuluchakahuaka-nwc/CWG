extends Control

var _selected_side: String = "union"

@onready var _title: Label = $TitleLabel
@onready var _side_label: Label = $SideLabel
@onready var _back_btn: Button = $BackButton
@onready var _start_btn: Button = $StartButton
@onready var _union_btn: Button = $SideHBox/UnionButton
@onready var _conf_btn: Button = $SideHBox/ConfederateButton

func _ready() -> void:
	_localize()
	_back_btn.pressed.connect(_on_back)
	_start_btn.pressed.connect(_on_start)
	_union_btn.pressed.connect(_on_union)
	_conf_btn.pressed.connect(_on_confederate)
	_update_side_highlight()

func _localize() -> void:
	_title.text = Localization.t("game.title")
	_side_label.text = "Choose your side:"
	_union_btn.text = Localization.t("side.union")
	_conf_btn.text = Localization.t("side.confederate")
	_back_btn.text = Localization.t("game.back")
	_start_btn.text = Localization.t("game.new_game")

func _on_union() -> void:
	_selected_side = "union"
	_update_side_highlight()

func _on_confederate() -> void:
	_selected_side = "confederate"
	_update_side_highlight()

func _update_side_highlight() -> void:
	_union_btn.modulate = Color(0.4, 0.6, 1.0) if _selected_side == "union" else Color(0.6, 0.6, 0.6)
	_conf_btn.modulate = Color(1.0, 0.4, 0.4) if _selected_side == "confederate" else Color(0.6, 0.6, 0.6)

func _on_start() -> void:
	GameManager.start_game("civil_war", _selected_side)
	get_tree().change_scene_to_file("res://scenes/game_map.tscn")

func _on_back() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

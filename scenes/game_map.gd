extends Control

var _map_controller: MapController

@onready var _turn_label: Label = $TopBar/TurnInfo
@onready var _phase_label: Label = $TopBar/PhaseLabel
@onready var _phonograph_btn: Button = $TopBar/PhonographButton
@onready var _menu_btn: Button = $TopBar/MenuButton
@onready var _end_turn_btn: Button = $BottomPanel/ActionButtons/EndTurnButton
@onready var _auto_turn_btn: Button = $BottomPanel/ActionButtons/AutoTurnButton
@onready var _map_area: Control = $MapArea

func _ready() -> void:
	_map_controller = MapController.new()
	_map_area.add_child(_map_controller)
	_end_turn_btn.pressed.connect(_on_end_turn)
	_auto_turn_btn.pressed.connect(_on_auto_turn)
	_phonograph_btn.pressed.connect(_on_phonograph)
	_menu_btn.pressed.connect(_on_menu)
	GameManager.turn_changed.connect(_on_turn_changed)
	GameManager.phase_changed.connect(_on_phase_changed)
	_update_ui()

func _update_ui() -> void:
	_turn_label.text = Localization.t("game.turn") + " " + str(GameManager.get_current_turn()) + " — " + GameManager.get_current_month()
	_end_turn_btn.text = Localization.t("game.end_turn")
	_auto_turn_btn.text = Localization.t("game.auto_turn")
	_map_controller.update_territory_display()

func _on_turn_changed(_turn: int, _month: String) -> void:
	_update_ui()

func _on_phase_changed(_phase: GameManager.Phase) -> void:
	_update_ui()

func _on_end_turn() -> void:
	GameManager.advance_phase()

func _on_auto_turn() -> void:
	var auto: AutoTurn = AutoTurn.new()
	add_child(auto)
	auto.execute()
	await auto.execute
	auto.queue_free()
	_update_ui()

func _on_phonograph() -> void:
	get_tree().change_scene_to_file("res://scenes/phonograph.tscn")

func _on_menu() -> void:
	_save_game()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _save_game() -> void:
	var data: Dictionary = GameManager.serialize()
	var file: FileAccess = FileAccess.open("user://save_game.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()

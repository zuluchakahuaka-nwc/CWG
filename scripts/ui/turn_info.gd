extends Control

@onready var _turn_label: Label = $TurnLabel
@onready var _month_label: Label = $MonthLabel
@onready var _phase_label: Label = $PhaseLabel

func _ready() -> void:
	GameManager.turn_changed.connect(_on_turn_changed)
	GameManager.phase_changed.connect(_on_phase_changed)

func _on_turn_changed(turn_number: int, month: String) -> void:
	if _turn_label:
		_turn_label.text = Localization.t("game.turn") + " " + str(turn_number)
	if _month_label:
		_month_label.text = month

func _on_phase_changed(phase: GameManager.Phase) -> void:
	if _phase_label:
		var phase_names: PackedStringArray = [
			"phase.resources", "phase.draw", "phase.movement",
			"phase.combat", "phase.events", "phase.end"
		]
		_phase_label.text = Localization.t(phase_names[phase])

func update_display() -> void:
	_on_turn_changed(GameManager.get_current_turn(), GameManager.get_current_month())
	_on_phase_changed(GameManager.get_current_phase())

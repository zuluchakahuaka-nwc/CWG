extends Control

var _side: String = "union"

@onready var _morale_bar: ProgressBar = $MoraleBar
@onready var _morale_value: Label = $MoraleValue
@onready var _morale_status: Label = $MoraleStatus

func _ready() -> void:
	pass

func set_side(side: String) -> void:
	_side = side
	update_display()

func update_display() -> void:
	var morale: int = GameManager.get_morale(_side)
	var status_key: String = GameManager.get_morale_status(_side)
	if _morale_bar:
		_morale_bar.min_value = -20
		_morale_bar.max_value = 20
		_morale_bar.value = morale
		_morale_bar.modulate = _morale_color(morale)
	if _morale_value:
		_morale_value.text = str(morale)
	if _morale_status:
		 morale_status.text = Localization.t(status_key)

func _morale_color(morale: int) -> Color:
	if morale >= 15:
		return Color(1.0, 0.84, 0.0)
	elif morale >= 10:
		return Color(0.2, 0.8, 0.2)
	elif morale >= 1:
		return Color(0.3, 0.6, 0.3)
	elif morale == 0:
		return Color(0.5, 0.5, 0.5)
	elif morale >= -9:
		return Color(0.8, 0.5, 0.2)
	elif morale >= -14:
		return Color(0.9, 0.3, 0.1)
	else:
		return Color(1.0, 0.0, 0.0)

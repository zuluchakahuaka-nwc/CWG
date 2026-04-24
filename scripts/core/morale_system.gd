extends Node

signal morale_changed(side: String, new_value: int, status_key: String)
signal morale_cascade(side: String, event_type: String)

var _morale_modifiers: Dictionary = {
	"conscription": -1,
	"battle_loss_major": -3,
	"capital_loss": -5,
	"commander_death": -2,
	"desertion": -1,
	"blockade_per_turn": -1,
	"lincoln_assassination": -3,
	"sherman_march": -4,
	"typhus": -2,
	"pickett_failure": -4,
	"revolt_suppression": -2,
	"battle_win_major": 3,
	"territory_gain": 2,
	"emancipation": 3,
	"european_recognition": 4,
	"fort_wagner_sacrifice": 5,
	"capital_capture": 5,
	"foreign_volunteers": 1
}

func apply_modifier(side: String, modifier_key: String) -> void:
	if not _morale_modifiers.has(modifier_key):
		push_warning("MoraleSystem: unknown modifier: " + modifier_key)
		return
	var amount: int = _morale_modifiers[modifier_key]
	GameManager.change_morale(side, amount)
	morale_changed.emit(side, GameManager.get_morale(side), GameManager.get_morale_status(side))

func apply_custom(side: String, amount: int) -> void:
	GameManager.change_morale(side, amount)
	morale_changed.emit(side, GameManager.get_morale(side), GameManager.get_morale_status(side))

func check_morale_effects(side: String) -> void:
	var m: int = GameManager.get_morale(side)
	if m >= 15:
		morale_cascade.emit(side, "sacred_fervor")
	elif m >= 10:
		morale_cascade.emit(side, "uplift")
	elif m <= -10:
		morale_cascade.emit(side, "unrest")
		if m <= -14:
			_roll_desertion(side)
	if m <= -19:
		morale_cascade.emit(side, "rebellion")
		_roll_territory_loss(side)

func _roll_desertion(side: String) -> void:
	var roll: int = randi_range(1, 10)
	if roll == 1:
		morale_cascade.emit(side, "desertion_event")

func _roll_territory_loss(side: String) -> void:
	var roll: int = randi_range(1, 5)
	if roll == 1:
		morale_cascade.emit(side, "territory_loss_event")

func get_morale_info(side: String) -> Dictionary:
	var m: int = GameManager.get_morale(side)
	return {
		"value": m,
		"status_key": GameManager.get_morale_status(side),
		"bonus_cards": GameManager.get_morale_bonus_cards(side),
		"attack_bonus": GameManager.get_morale_attack_bonus(side),
		"enemy_sees_card": m <= -9,
		"desertion_risk": m <= -14,
		"territory_loss_risk": m <= -19,
		"is_collapsed": m <= -20
	}

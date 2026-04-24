extends Node

var _strategy: AIStrategy
var _side: String = ""

signal ai_action(action_type: String, data: Dictionary)

func _ready() -> void:
	pass

func initialize(side: String, strategy: AIStrategy.Strategy = AIStrategy.Strategy.BALANCED) -> void:
	_side = side
	_strategy = AIStrategy.new(side, strategy)

func execute_turn() -> void:
	_execute_resource_phase()
	await get_tree().create_timer(0.2).timeout
	_execute_draw_phase()
	await get_tree().create_timer(0.2).timeout
	_execute_play_phase()
	await get_tree().create_timer(0.2).timeout
	_execute_movement_phase()
	await get_tree().create_timer(0.2).timeout
	_execute_combat_phase()
	await get_tree().create_timer(0.2).timeout

func _execute_resource_phase() -> void:
	ai_action.emit("resource_phase", {"side": _side})

func _execute_draw_phase() -> void:
	ai_action.emit("draw_phase", {"side": _side})

func _execute_play_phase() -> void:
	var money: int = GameManager.get_resources(_side).get("money", 0)
	var cards_played: int = 0
	while cards_played < 3:
		var card: Dictionary = _strategy.choose_card_to_play([], money)
		if card.is_empty():
			break
		money -= card.get("cost", 0)
		cards_played += 1
		ai_action.emit("play_card", {"card": card, "side": _side})

func _execute_movement_phase() -> void:
	var available: Array = _get_movable_units()
	if available.is_empty():
		return
	var target: String = _strategy.choose_territory_to_attack(available)
	if target == "":
		return
	ai_action.emit("move_units", {"target": target, "units": available, "side": _side})

func _execute_combat_phase() -> void:
	var contested: Array = UnitMatcher.new().find_all_contested_territories()
	for t_id in contested:
		ai_action.emit("resolve_battle", {"territory": t_id, "side": _side})

func _get_movable_units() -> Array:
	var units: Array = []
	for t_id in GameManager._units_on_map:
		if GameManager.get_territory_owner(t_id) == _side:
			for unit in GameManager._units_on_map[t_id]:
				if unit is CardInstance and unit.side == _side and not unit.is_exhausted:
					units.append(unit)
	return units

class_name AutoTurnExecutor
extends Node

var _strategy: AIStrategy.Strategy = AIStrategy.Strategy.BALANCED
var _ai_controller: AIController

signal auto_turn_complete()

func _ready() -> void:
	pass

func set_strategy(strategy: AIStrategy.Strategy) -> void:
	_strategy = strategy

func execute_auto_turn() -> void:
	var side: String = GameManager.get_player_side()
	_ai_controller = AIController.new()
	add_child(_ai_controller)
	_ai_controller.set_side(side)
	_ai_controller.set_hands({"union": [], "confederate": []})
	_ai_controller.execute_turn()
	await _ai_controller.ai_turn_complete
	auto_turn_complete.emit()
	remove_child(_ai_controller)
	_ai_controller.queue_free()

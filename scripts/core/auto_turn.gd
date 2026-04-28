class_name AutoTurn
extends Node

enum Strategy { CONSERVATIVE, AGGRESSIVE, BALANCED }

var _current_strategy: Strategy = Strategy.BALANCED

func _ready() -> void:
	pass

func set_strategy(strategy: Strategy) -> void:
	_current_strategy = strategy

func get_strategy() -> Strategy:
	return _current_strategy

func get_strategy_name() -> String:
	match _current_strategy:
		Strategy.CONSERVATIVE: return "strategy.conservative"
		Strategy.AGGRESSIVE: return "strategy.aggressive"
		Strategy.BALANCED: return "strategy.balanced"
		_: return "strategy.balanced"

func execute() -> void:
	var side: String = GameManager.get_player_side()
	var executor: AutoTurnExecutor = AutoTurnExecutor.new()
	executor.set_strategy(_current_strategy)
	add_child(executor)
	executor.execute_auto_turn()
	await executor.auto_turn_complete
	remove_child(executor)
	executor.queue_free()

class_name AutoTurn
extends Node

# Strategy lives on AIStrategy: a local duplicate enum is a distinct type
# and never type-checks against AutoTurnExecutor.set_strategy().
var _current_strategy: AIStrategy.Strategy = AIStrategy.Strategy.BALANCED

func _ready() -> void:
	pass

func set_strategy(strategy: AIStrategy.Strategy) -> void:
	_current_strategy = strategy

func get_strategy() -> AIStrategy.Strategy:
	return _current_strategy

func get_strategy_name() -> String:
	match _current_strategy:
		AIStrategy.Strategy.CONSERVATIVE: return "strategy.conservative"
		AIStrategy.Strategy.AGGRESSIVE: return "strategy.aggressive"
		AIStrategy.Strategy.BALANCED: return "strategy.balanced"
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

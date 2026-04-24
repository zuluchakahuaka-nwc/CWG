extends Control

var _side: String = "union"

@onready var _manpower_label: Label = $ManpowerLabel
@onready var _money_label: Label = $MoneyLabel
@onready var _supply_label: Label = $SupplyLabel
@onready var _manpower_income: Label = $ManpowerIncome
@onready var _money_income: Label = $MoneyIncome
@onready var _supply_income: Label = $SupplyIncome

func _ready() -> void:
	pass

func set_side(side: String) -> void:
	_side = side
	update_display()

func update_display() -> void:
	var res: Dictionary = GameManager.get_resources(_side)
	if _manpower_label:
		_manpower_label.text = str(res.get("manpower", 0))
	if _money_label:
		_money_label.text = str(res.get("money", 0))
	if _supply_label:
		_supply_label.text = str(res.get("supply", 0))
	var income: Dictionary = {}
	if not ResourceManager:
		var rm: Node = Node.new()
		rm.set_script(load("res://scripts/core/resource_manager.gd"))
		income = rm.calculate_income(_side)
		rm.queue_free()
	else:
		income = ResourceManager.calculate_income(_side)
	if _manpower_income:
		_manpower_income.text = "+" + str(income.get("manpower", 0))
	if _money_income:
		_money_income.text = "+" + str(income.get("money", 0))
	if _supply_income:
		_supply_income.text = "+" + str(income.get("supply", 0))

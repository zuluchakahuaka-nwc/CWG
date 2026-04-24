extends Node

signal resource_changed(side: String, resource: String, new_value: int)
signal income_calculated(side: String, income: Dictionary)

func _ready() -> void:
	pass

func calculate_income(side: String) -> Dictionary:
	var income: Dictionary = {"manpower": 0, "money": 0, "supply": 0}
	for t_id in GameManager._territory_owners:
		if GameManager._territory_owners[t_id] == side:
			var t: Dictionary = CardDatabase.get_territory(t_id)
			income["manpower"] += t.get("resource_manpower", 0)
			income["money"] += t.get("resource_money", 0)
			income["supply"] += t.get("resource_supply", 0)
	income_calculated.emit(side, income)
	return income

func apply_income(side: String) -> void:
	var income: Dictionary = calculate_income(side)
	for res in income:
		GameManager.change_resource(side, res, income[res])
		resource_changed.emit(side, res, GameManager.get_resources(side).get(res, 0))

func can_afford(side: String, cost: int) -> bool:
	return GameManager.get_resources(side).get("money", 0) >= cost

func spend(side: String, resource: String, amount: int) -> bool:
	var current: int = GameManager.get_resources(side).get(resource, 0)
	if current < amount:
		return false
	GameManager.change_resource(side, resource, -amount)
	resource_changed.emit(side, resource, GameManager.get_resources(side).get(resource, 0))
	return true

func get_resource_display(side: String) -> Dictionary:
	var res: Dictionary = GameManager.get_resources(side)
	var income: Dictionary = calculate_income(side)
	return {
		"manpower": res.get("manpower", 0),
		"manpower_income": income.get("manpower", 0),
		"money": res.get("money", 0),
		"money_income": income.get("money", 0),
		"supply": res.get("supply", 0),
		"supply_income": income.get("supply", 0)
	}

func apply_blockade_penalty() -> void:
	GameManager.change_resource("confederate", "money", -1)
	GameManager.change_resource("confederate", "supply", -1)
	resource_changed.emit("confederate", "money", GameManager.get_resources("confederate").get("money", 0))
	resource_changed.emit("confederate", "supply", GameManager.get_resources("confederate").get("supply", 0))

extends Resource

@export var territory_id: String = ""
@export var territory_name: String = ""
@export var owner: String = "neutral"
@export var terrain: String = "plains"
@export var is_capital: bool = false
@export var is_port: bool = false
@export var is_railroad: bool = false
@export var map_position: Vector2 = Vector2.ZERO
@export var resource_manpower: int = 0
@export var resource_money: int = 0
@export var resource_supply: int = 0
@export var special_bonus: String = ""

var _data: Dictionary = {}
var _units: Array = []

func initialize(data: Dictionary) -> void:
	_data = data
	territory_id = data.get("id", "")
	territory_name = Localization.get_card_name(data)
	owner = data.get("initial_owner", "neutral")
	terrain = data.get("terrain", "plains")
	is_capital = data.get("is_capital", false)
	is_port = data.get("is_port", false)
	is_railroad = data.get("is_railroad", false)
	map_position = Vector2(data.get("map_x", 0), data.get("map_y", 0))
	resource_manpower = data.get("resource_manpower", 0)
	resource_money = data.get("resource_money", 0)
	resource_supply = data.get("resource_supply", 0)
	special_bonus = data.get("special_bonus", "")

func get_data() -> Dictionary:
	return _data

func get_units_for_side(side: String) -> Array:
	var result: Array = []
	for unit in _units:
		if unit is CardInstance and unit.side == side:
			result.append(unit)
	return result

func get_all_units() -> Array:
	return _units

func add_unit(unit: CardInstance) -> void:
	_units.append(unit)
	unit.territory_id = territory_id

func remove_unit(unit: CardInstance) -> void:
	_units.erase(unit)
	unit.territory_id = ""

func get_unit_count() -> int:
	return _units.size()

func is_contested() -> bool:
	var sides_present: Dictionary = {}
	for unit in _units:
		if unit is CardInstance:
			sides_present[unit.side] = true
	return sides_present.size() > 1

func get_owner_display() -> String:
	return Localization.t("side." + owner) if owner != "neutral" else Localization.t("territory." + territory_id)

func get_terrain_display() -> String:
	return Localization.t("terrain." + terrain)

func get_income() -> Dictionary:
	return {
		"manpower": resource_manpower,
		"money": resource_money,
		"supply": resource_supply
	}

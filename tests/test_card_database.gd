extends "res://tests/test_base.gd"

var _db: Node

func before_all() -> void:
	_db = Node.new()
	_db.set_script(load("res://scripts/cards/card_database.gd"))
	add_child(_db)

func after_all() -> void:
	remove_child(_db)
	_db.queue_free()

func test_units_loaded() -> void:
	var all_ids: Dictionary = _db.get_all_card_ids()
	assert(all_ids.has("units"), "Should have units key")
	assert(all_ids["units"].size() > 0, "Should have unit cards loaded")

func test_union_units() -> void:
	var units: Array = _db.get_all_units_for_side("union")
	assert(units.size() >= 60, "Union should have 70 units, got " + str(units.size()))
	for u in units:
		assert(u.has("id"), "Each unit should have an id")
		assert(u.has("attack"), "Each unit should have attack")
		assert(u.has("side"), "Each unit should have side")
		assert(u["side"] == "union", "Union units should have side=union")

func test_confederate_units() -> void:
	var units: Array = _db.get_all_units_for_side("confederate")
	assert(units.size() >= 70, "Confederate should have 76 units, got " + str(units.size()))

func test_commanders_loaded() -> void:
	var union_cmd: Array = _db.get_all_commanders_for_side("union")
	var conf_cmd: Array = _db.get_all_commanders_for_side("confederate")
	assert(union_cmd.size() == 12, "Union should have 12 commanders, got " + str(union_cmd.size()))
	assert(conf_cmd.size() == 12, "Confederate should have 12 commanders, got " + str(conf_cmd.size()))

func test_specific_card() -> void:
	var maine: Dictionary = _db.get_unit("u_inf_20me")
	assert(not maine.is_empty(), "20th Maine should exist")
	assert(maine.get("attack", 0) == 3, "20th Maine attack should be 3")
	assert(maine.get("defense", 0) == 5, "20th Maine defense should be 5")
	assert(maine.get("rarity", "") == "legendary", "20th Maine should be legendary")
	assert(maine.get("linked_events", []).has("EVENT_BAYONET_CHARGE"), "Should have bayonet charge event")

func test_card_stats_range() -> void:
	for side in ["union", "confederate"]:
		var units: Array = _db.get_all_units_for_side(side)
		for u in units:
			assert(u["attack"] >= 1 and u["attack"] <= 8, u["id"] + " attack out of range: " + str(u["attack"]))
			assert(u["defense"] >= 1 and u["defense"] <= 8, u["id"] + " defense out of range: " + str(u["defense"]))
			assert(u["hp"] >= 1 and u["hp"] <= 10, u["id"] + " hp out of range: " + str(u["hp"]))
			assert(u["cost"] >= 0 and u["cost"] <= 7, u["id"] + " cost out of range: " + str(u["cost"]))

extends "res://tests/test_base.gd"

func test_resolve_basic() -> void:
	var resolver: BattleResolver = BattleResolver.new()
	var attacker: CardInstance = CardInstance.new({
		"id": "test_atk", "attack": 5, "defense": 2, "hp": 4,
		"side": "union", "type": "infantry", "rarity": "common", "cost": 2
	})
	var defender: CardInstance = CardInstance.new({
		"id": "test_def", "attack": 3, "defense": 4, "hp": 5,
		"side": "confederate", "type": "infantry", "rarity": "common", "cost": 2
	})
	var territory: Dictionary = {"id": "test_terr", "terrain": "plains"}
	var result: Dictionary = resolver.resolve_combat(attacker, defender, territory)
	assert(result.has("rounds"), "Should have rounds")
	assert(result["rounds"].size() >= 1, "Should have at least 1 round")
	assert(result.has("attacker_id"), "Should have attacker_id")
	assert(result["attacker_id"] == "test_atk", "Attacker id should match")

func test_type_advantage() -> void:
	var resolver: BattleResolver = BattleResolver.new()
	var cavalry: CardInstance = CardInstance.new({
		"id": "cav", "attack": 3, "defense": 2, "hp": 4,
		"side": "union", "type": "cavalry", "rarity": "common", "cost": 2
	})
	var artillery: CardInstance = CardInstance.new({
		"id": "art", "attack": 4, "defense": 2, "hp": 3,
		"side": "confederate", "type": "artillery", "rarity": "common", "cost": 3
	})
	var territory: Dictionary = {"id": "test_terr", "terrain": "plains"}
	var result: Dictionary = resolver.resolve_combat(cavalry, artillery, territory)
	assert(result.has("rounds"), "Cavalry vs artillery should resolve")

func test_terrain_defense() -> void:
	var resolver: BattleResolver = BattleResolver.new()
	var attacker: CardInstance = CardInstance.new({
		"id": "atk", "attack": 5, "defense": 2, "hp": 4,
		"side": "union", "type": "infantry", "rarity": "common", "cost": 2
	})
	var defender: CardInstance = CardInstance.new({
		"id": "def", "attack": 2, "defense": 3, "hp": 5,
		"side": "confederate", "type": "infantry", "rarity": "common", "cost": 2
	})
	var city: Dictionary = {"id": "city", "terrain": "city"}
	var result: Dictionary = resolver.resolve_combat(attacker, defender, city)
	assert(result.has("rounds"), "City combat should resolve")

func test_damage_not_negative() -> void:
	var resolver: BattleResolver = BattleResolver.new()
	var weak: CardInstance = CardInstance.new({
		"id": "weak", "attack": 1, "defense": 1, "hp": 3,
		"side": "union", "type": "infantry", "rarity": "common", "cost": 1
	})
	var strong: CardInstance = CardInstance.new({
		"id": "strong", "attack": 8, "defense": 8, "hp": 8,
		"side": "confederate", "type": "infantry", "rarity": "legendary", "cost": 7
	})
	var territory: Dictionary = {"id": "test", "terrain": "plains"}
	var result: Dictionary = resolver.resolve_combat(weak, strong, territory)
	for round in result.get("rounds", []):
		assert(round["damage_to_defender"] >= 0, "Damage should never be negative")

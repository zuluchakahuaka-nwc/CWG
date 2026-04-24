extends RefCounted

var id: String = ""
var card_data: Dictionary = {}
var current_hp: int = 0
var max_hp: int = 0
var attack: int = 0
var defense: int = 0
var cost: int = 0
var side: String = ""
var type: String = ""
var rarity: String = ""
var tags: Array = []
var territory_id: String = ""
var is_exhausted: bool = false
var temporary_buffs: Array = []

func _init(data: Dictionary = {}) -> void:
	if data.is_empty():
		return
	card_data = data
	id = data.get("id", "")
	attack = data.get("attack", 0)
	defense = data.get("defense", 0)
	max_hp = data.get("hp", 1)
	current_hp = max_hp
	cost = data.get("cost", 0)
	side = data.get("side", "union")
	type = data.get("type", "infantry")
	rarity = data.get("rarity", "common")
	tags = data.get("tags", [])

func get_name() -> String:
	return Localization.get_card_name(card_data)

func get_description() -> String:
	return Localization.get_card_description(card_data)

func get_flavor() -> String:
	return Localization.get_card_flavor(card_data)

func take_damage(amount: int) -> int:
	var actual: int = maxi(amount, 0)
	current_hp -= actual
	return actual

func heal(amount: int) -> void:
	current_hp = mini(current_hp + amount, max_hp)

func is_alive() -> bool:
	return current_hp > 0

func get_effective_attack() -> int:
	var val: int = attack
	val += GameManager.get_morale_attack_bonus(side)
	for buff in temporary_buffs:
		if buff.has("attack"):
			val += buff["attack"]
	return val

func get_effective_defense() -> int:
	var val: int = defense
	for buff in temporary_buffs:
		if buff.has("defense"):
			val += buff["defense"]
	return val

func add_buff(buff: Dictionary, duration: int = 1) -> void:
	buff["duration"] = duration
	temporary_buffs.append(buff)

func tick_buffs() -> void:
	var to_remove: Array = []
	for i in range(temporary_buffs.size()):
		temporary_buffs[i]["duration"] -= 1
		if temporary_buffs[i]["duration"] <= 0:
			to_remove.append(i)
	for i in to_remove:
		temporary_buffs.remove_at(i)

func serialize() -> Dictionary:
	return {
		"id": id,
		"current_hp": current_hp,
		"territory_id": territory_id,
		"is_exhausted": is_exhausted,
		"temporary_buffs": temporary_buffs.duplicate(true)
	}

func deserialize(data: Dictionary) -> void:
	current_hp = data.get("current_hp", max_hp)
	territory_id = data.get("territory_id", "")
	is_exhausted = data.get("is_exhausted", false)
	temporary_buffs = data.get("temporary_buffs", [])

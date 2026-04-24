extends RefCounted

var _cards: Array = []

func _init() -> void:
	_cards.clear()

func build_deck(side: String) -> void:
	_cards.clear()
	var units: Array = CardDatabase.get_all_units_for_side(side)
	var situations: Array = CardDatabase.get_all_situations_for_side(side)
	var commanders: Array = CardDatabase.get_all_commanders_for_side(side)
	for unit_data in units:
		var copies: int = _get_copies_by_rarity(unit_data.get("rarity", "common"))
		for i in copies:
			_cards.append(unit_data.duplicate(true))
	for sit_data in situations:
		var copies: int = _get_copies_by_rarity(sit_data.get("subtype", "universal"))
		if sit_data.get("one_time_use", false):
			copies = 1
		for i in copies:
			_cards.append(sit_data.duplicate(true))
	for cmd_data in commanders:
		_cards.append(cmd_data.duplicate(true))
	shuffle()

func _get_copies_by_rarity(rarity: String) -> int:
	match rarity:
		"common": return 3
		"uncommon": return 2
		"rare": return 2
		"legendary": return 1
		_: return 2

func shuffle() -> void:
	_cards.shuffle()

func draw_card() -> Dictionary:
	if _cards.is_empty():
		return {}
	return _cards.pop_front()

func draw_cards(count: int) -> Array:
	var drawn: Array = []
	for i in mini(count, _cards.size()):
		drawn.append(_cards.pop_front())
	return drawn

func size() -> int:
	return _cards.size()

func is_empty() -> bool:
	return _cards.is_empty()

func peek_top() -> Dictionary:
	if _cards.is_empty():
		return {}
	return _cards[0]

func add_to_bottom(card_data: Dictionary) -> void:
	_cards.append(card_data)

func serialize() -> Dictionary:
	return {"cards": _cards.duplicate(true)}

func deserialize(data: Dictionary) -> void:
	_cards = data.get("cards", [])

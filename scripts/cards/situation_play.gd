class_name SituationPlay
extends RefCounted
## Generalized play of situation & commander cards from the hand.
##
## Owner feedback 21.11: "no situation cards" - they never reached the
## draw pool. Full per-card combat mechanics are a combat-layer project;
## this layer maps EVERY playable card onto its honest general category
## so a drawn card is never dead. Cards whose mechanics only make sense
## inside a battle (auto-victory, Pickett's charge, ...) are excluded
## from the deck entirely (is_playable=false) - a card in the hand that
## does nothing is a P1 bug by the hub law.

## Category kinds:
##   morale_self / morale_enemy      - morale change
##   draw_cards                      - hand refill
##   resource_self / resource_enemy  - money/supply change
##   buff_atk / buff_def / debuff    - unit stat changes on a territory
##   heal                            - restore HP of own unit
##   destroy                         - remove an enemy unit (chance rolls kept)
##   reveal_hand / reveal_map        - information
##   none                            - not playable from the hand (battle-wired)

const TABLE: Dictionary = {
	# mechanic -> {kind, ...params}
	"INSTANT_DESTROY": {"kind": "destroy"},
	"DESTROY_TARGET_SELF_DAMAGE_1": {"kind": "destroy"},
	"INSTANT_DESTROY_MINE": {"kind": "destroy"},
	"DISABLE_1_RIVER_IRONCLAD": {"kind": "destroy", "type": "ship"},
	"INSTANT_ELIMINATE_COMMANDER": {"kind": "destroy"},
	"ELIMINATE_1_COMMANDER_NO_BATTLE": {"kind": "destroy"},
	"ELIMINATE_COMMANDER": {"kind": "destroy"},
	"MUTUAL_DESTROY": {"kind": "destroy", "mutual": true},
	"ENEMY_LOSE_1_UNIT_D6_1_2": {"kind": "destroy", "chance": 0.34},
	"DESTROY_1_SHIP_D6_1_3": {"kind": "destroy", "chance": 0.5, "type": "ship"},

	"PLUS_3_MORALE_FREE_USCT": {"kind": "morale_self", "amount": 3},
	"PLUS_5_MORALE_UNION": {"kind": "morale_side", "target": "union", "amount": 5},
	"SELF_DESTROY_PLUS_5_MORALE": {"kind": "morale_self", "amount": 5},
	"MINUS_3_MORALE_UNION": {"kind": "morale_side", "target": "union", "amount": -3},
	"MINUS_3_MORALE_CONFEDERATE": {"kind": "morale_side", "target": "confederate", "amount": -3},
	"PLUS_2_DIPLOMACY_BLOCK_EUROPEAN_RECOGNITION": {"kind": "morale_self", "amount": 2},
	"DRAW_2_CARDS_PLUS_1_MORALE": {"kind": "draw_cards", "count": 2, "morale": 1},
	"DRAW_1_CARD_MINUS_1_MORALE_CASCADE": {"kind": "draw_cards", "count": 1, "morale": -1},
	"PLUS_1_NAVAL_CARD_PER_TURN": {"kind": "draw_cards", "count": 1},

	"STEAL_SUPPLY_CARD": {"kind": "resource_self", "supply": 2},
	"STEAL_RESOURCES": {"kind": "resource_steal", "money": 3},
	"PLUS_1_RESOURCE_PER_RUN": {"kind": "resource_self", "supply": 1},
	"CONFEDERATE_MINUS_1_TRADE_RESOURCE": {"kind": "resource_side", "target": "confederate", "money": -1},
	"CANCEL_BLOCKADE_PLUS_1_RESOURCE": {"kind": "resource_self", "supply": 1},
	"ENEMY_MINUS_1_RESOURCE_MERCHANT_SHIP": {"kind": "resource_enemy", "money": -1},
	"DESTROY_RAILROAD_2_TURNS": {"kind": "resource_enemy", "money": -2},
	"AUTO_LOSE_2_RESOURCES_1_MORALE_IF_LOW_MORALE": {"kind": "riot", "morale_min": -8},
	"AUTO_LOSE_2_TURNS_1_UNIT_IF_LOW_MORALE": {"kind": "draft_riot", "morale_min": -5},

	"PLUS_5_ATK_EXPEND_ALL_AMMO": {"kind": "buff_atk", "amount": 5, "one": true},
	"PLUS_2_ATK_IF_3_IRON_BRIGADE": {"kind": "buff_atk", "amount": 2, "need_units": 3},
	"PLUS_1_ATK_3_INFANTRY": {"kind": "buff_atk", "amount": 1},
	"PLUS_1_ATK_3_INFANTRY_REGIMENTS": {"kind": "buff_atk", "amount": 1},
	"SEVEN_SHOTS_NO_RELOAD": {"kind": "buff_atk", "amount": 1},
	"DOUBLE_FIRST_VOLLEY_DAMAGE": {"kind": "buff_atk", "amount": 1},
	"DOUBLE_STRENGTH_WHEN_OUTNUMBERED": {"kind": "buff_atk", "amount": 1},
	"MOVE_UNDETECTED_PLUS_1_ATK_SURPRISE": {"kind": "buff_atk", "amount": 1},
	"PLUS_2_ATK_ALL_ARTILLERY_1_TURN": {"kind": "buff_atk", "amount": 2, "unit_type": "artillery"},
	"PLUS_4_ATK_ARTILLERY_CITY_SIEGE": {"kind": "buff_atk", "amount": 4, "unit_type": "artillery", "terrain": "city"},
	"PLUS_4_ATK_FIRST_STRIKE_FOREST_HILLS": {"kind": "buff_atk", "amount": 2, "terrain_any": ["forest", "hills"]},
	"PLUS_4_DEF_UNBREAKABLE": {"kind": "buff_def", "amount": 4},
	"PLUS_3_DEF_CHOSEN_REGIMENT": {"kind": "buff_def", "amount": 3},
	"BLOCK_INFANTRY_ADVANCE_FLANK": {"kind": "buff_def", "amount": 2},
	"CROSS_RIVER_NO_PENALTY": {"kind": "buff_def", "amount": 1},
	"IGNORE_MINES_ALL_SHIPS": {"kind": "buff_def", "amount": 2, "unit_type": "ship"},
	"MINUS_2_CHOSEN_REGIMENT": {"kind": "debuff_def", "amount": -2},
	"MINUS_1_ATK_ALL_FIREARMS_1_TURN": {"kind": "debuff_atk", "amount": -1},

	"RESTORE_1_HP_CHOSEN_REGIMENT": {"kind": "heal", "amount": 1},
	"REVEAL_1_ENEMY_CARD": {"kind": "reveal_hand"},
	"REVEAL_ALL_ENEMY_UNITS_1_TERRITORY": {"kind": "reveal_map"},

	# Battle-wired: only meaningful inside a live battle / global turn
	# machinery. They stay OUT of the draw deck until their triggers land.
	"CANCEL_BATTLE_BOTH_SURVIVE": {"kind": "none"},
	"CAPTURE_TARGET": {"kind": "none"},
	"SURRENDER_IF_OUTNUMBERED": {"kind": "none"},
	"DOUBLE_COMMERCE_DAMAGE": {"kind": "none"},
	"FREE_SHIP_TRANSFORM": {"kind": "none"},
	"SELF_DESTROY_STOPS_ANY_ATTACK": {"kind": "none"},
	"MASS_ASSAULT_SUCCESS_OR_LOSE_ALL": {"kind": "none"},
	"DESTROY_INFRASTRUCTURE_PLUS_2_TERRITORIES": {"kind": "none"},
	"LOSE_COMMANDER": {"kind": "none"},
	"AUTO_VICTORY_UNION": {"kind": "none"},
	"LOSE_TRANS_MISSISSIPPI": {"kind": "none"},
	"RECRUIT_LEE_1_IN_20": {"kind": "none"},
	"ALL_MOVEMENT_MINUS_50_PERCENT_1_TURN": {"kind": "none"},
	"MOVE_1_UNIT_ANY_TERRITORY": {"kind": "none"},
	"PLUS_1_EXTRA_ACTION": {"kind": "none"},
	"CANCEL_ESPIONAGE_OR_MOSBY_RAID": {"kind": "none"},
	"STOP_RIOT_MUTINY_MINUS_2_MORALE": {"kind": "none"},
}

## Commander cards carry no "type" field in the data files - detect them
## by id prefix / effect_type instead.
static func is_commander_card(card_data: Dictionary) -> bool:
	if String(card_data.get("type", "")) == "commander":
		return true
	if String(card_data.get("id", "")).begins_with("cmd_"):
		return true
	return card_data.has("effect_type") and not card_data.has("effect_mechanic")

static func is_playable(card_data: Dictionary) -> bool:
	if is_commander_card(card_data):
		return true
	var rule: Dictionary = TABLE.get(String(card_data.get("effect_mechanic", "")), {})
	return not rule.is_empty() and rule.get("kind", "none") != "none"

## Which territories accept this card: most effects target the player's
## own land; destroy/debuff need ENEMY land (their units stand there).
static func needs_enemy_land(card_data: Dictionary) -> bool:
	if is_commander_card(card_data):
		return false
	var rule: Dictionary = TABLE.get(String(card_data.get("effect_mechanic", "")), {})
	var k: String = rule.get("kind", "")
	return k == "destroy" or k == "debuff_def" or k == "debuff_atk" or k == "reveal_map"

## Play the card. Returns {ok: bool, key: String, args: Array,
## telemetry: String, keep: bool} - key/args build the localized player
## message, telemetry is English Logger noise. keep=true means the play
## was refused (conditions unmet): the card stays in the hand.
static func play(card_data: Dictionary, side: String, territory_id: String, hands: Dictionary) -> Dictionary:
	var foe: String = "confederate" if side == "union" else "union"
	var rule: Dictionary = {}
	var is_commander: bool = is_commander_card(card_data)
	if is_commander:
		rule = {"kind": "command"}
	else:
		rule = TABLE.get(String(card_data.get("effect_mechanic", "")), {})
	if rule.is_empty():
		return {"ok": false, "key": "sit.err.conditions", "args": [], "telemetry": "unknown card", "keep": true}
	var kind: String = rule.get("kind", "")
	var telemetry: String = ""
	var key: String = ""
	var args: Array = []
	var need_units_min: int = int(rule.get("need_units", 0))
	var own_units: Array = _own_units(side, territory_id)
	if need_units_min > 0 and own_units.size() < need_units_min:
		return _refused("needs %d units on the territory" % need_units_min)
	var terrain: String = String(CardDatabase.get_territory(territory_id).get("terrain", "plains"))
	if rule.has("terrain") and terrain != String(rule["terrain"]):
		return _refused("needs %s terrain" % String(rule["terrain"]))
	if rule.has("terrain_any") and not terrain in rule["terrain_any"]:
		return _refused("needs %s terrain" % str(rule["terrain_any"]))

	match kind:
		"command":
			# Generalized command effect: the commander takes charge of the
			# troops on the chosen territory (+1/+1). Morale-type presidents
			# rally the home front instead.
			if String(card_data.get("effect_type", "")).begins_with("morale_boost"):
				GameManager.change_morale(side, 2)
				key = "sit.ok.rally"
				args = [Localization.get_card_name(card_data), 2]
				telemetry = "%s rallied the home front: morale +2" % card_data.get("id", "")
			else:
				if own_units.is_empty():
					return _refused("no troops to command")
				for u in own_units:
					u.attack += 1
					u.defense += 1
				key = "sit.ok.command"
				args = [Localization.get_card_name(card_data), own_units.size()]
				telemetry = "%s takes command of %s: %d units +1/+1" % [card_data.get("id", ""), territory_id, own_units.size()]
		"morale_self":
			var m_amount: int = int(rule.get("amount", 1))
			GameManager.change_morale(side, m_amount)
			key = "sit.ok.morale"
			args = [m_amount]
			telemetry = "morale %d" % m_amount
		"morale_side":
			var t_side: String = String(rule.get("target", side))
			if t_side != side and t_side != foe:
				t_side = side
			var ms_amount: int = int(rule.get("amount", 1))
			GameManager.change_morale(t_side, ms_amount)
			key = "sit.ok.morale_side"
			args = [Localization.t("side." + t_side), ms_amount]
			telemetry = "morale of %s %d" % [t_side, ms_amount]
		"draw_cards":
			var drawn: int = _draw_into_hand(side, int(rule.get("count", 1)), hands)
			if rule.has("morale"):
				GameManager.change_morale(side, int(rule["morale"]))
				key = "sit.ok.draw_morale"
				args = [drawn, int(rule["morale"])]
			else:
				key = "sit.ok.draw"
				args = [drawn]
			telemetry = "drew %d cards" % drawn
		"resource_self":
			GameManager.change_resource(side, "supply", int(rule.get("supply", 0)))
			GameManager.change_resource(side, "money", int(rule.get("money", 0)))
			key = "sit.ok.resources"
			args = [int(rule.get("money", 0)), int(rule.get("supply", 0))]
			telemetry = "supply %d money %d" % [int(rule.get("supply", 0)), int(rule.get("money", 0))]
		"resource_enemy":
			GameManager.change_resource(foe, "money", int(rule.get("money", 0)))
			key = "sit.ok.resources_enemy"
			args = [int(rule.get("money", 0))]
			telemetry = "enemy money %d" % int(rule.get("money", 0))
		"resource_side":
			var rs_side: String = String(rule.get("target", foe))
			GameManager.change_resource(rs_side, "money", int(rule.get("money", 0)))
			key = "sit.ok.resources_enemy"
			args = [int(rule.get("money", 0))]
			telemetry = "%s money %d" % [rs_side, int(rule.get("money", 0))]
		"resource_steal":
			GameManager.change_resource(foe, "money", -int(rule.get("money", 0)))
			GameManager.change_resource(side, "money", int(rule.get("money", 0)))
			key = "sit.ok.steal"
			args = [int(rule.get("money", 0))]
			telemetry = "stole %d money" % int(rule.get("money", 0))
		"riot", "draft_riot":
			# Bread/draft riots: only fire when the enemy home front is
			# actually brittle - otherwise the card honestly refuses.
			if GameManager.get_morale(foe) > int(rule.get("morale_min", -8)):
				return _refused("enemy morale too high")
			GameManager.change_resource(foe, "money", -2)
			if kind == "riot":
				GameManager.change_morale(foe, -1)
				key = "sit.ok.riot"
				args = []
				telemetry = "bread riot: enemy -2 money, -1 morale"
			else:
				_remove_random_enemy_unit(foe)
				key = "sit.ok.draft_riot"
				args = []
				telemetry = "draft riot: enemy -2 money, -1 unit"
		"buff_atk":
			var b_atk: int = int(rule.get("amount", 1))
			var b_log: String = _buff_units(side, territory_id, b_atk, 0, String(rule.get("unit_type", "")), bool(rule.get("one", false)))
			if b_log == "":
				return _refused("no valid units on %s" % territory_id)
			key = "sit.ok.buff"
			args = [b_atk, 0, b_log.split(" ")[0].to_int()]
			telemetry = b_log
		"buff_def":
			var b_def: int = int(rule.get("amount", 1))
			var bd_log: String = _buff_units(side, territory_id, 0, b_def, String(rule.get("unit_type", "")), false)
			if bd_log == "":
				return _refused("no valid units on %s" % territory_id)
			key = "sit.ok.buff"
			args = [0, b_def, bd_log.split(" ")[0].to_int()]
			telemetry = bd_log
		"debuff_def":
			var dd_log: String = _buff_units(foe, territory_id, 0, int(rule.get("amount", -1)), "", true)
			if dd_log == "":
				return _refused("no enemy units on %s" % territory_id)
			key = "sit.ok.buff"
			args = [0, int(rule.get("amount", -1)), dd_log.split(" ")[0].to_int()]
			telemetry = dd_log
		"debuff_atk":
			var da_log: String = _buff_units(foe, territory_id, int(rule.get("amount", -1)), 0, "", true)
			if da_log == "":
				return _refused("no enemy units on %s" % territory_id)
			key = "sit.ok.buff"
			args = [int(rule.get("amount", -1)), 0, da_log.split(" ")[0].to_int()]
			telemetry = da_log
		"heal":
			if own_units.is_empty():
				return _refused("no units to heal")
			var healed: bool = false
			for u in own_units:
				if u.has_method("is_alive") and u.is_alive() and u.current_hp < u.max_hp:
					u.current_hp = mini(u.current_hp + int(rule.get("amount", 1)), u.max_hp)
					healed = true
					break
			if not healed:
				return _refused("units already at full health")
			key = "sit.ok.heal"
			args = [int(rule.get("amount", 1))]
			telemetry = "healed +%d HP" % int(rule.get("amount", 1))
		"destroy":
			if rule.has("chance") and randf() > float(rule["chance"]):
				return {"ok": true, "key": "sit.ok.destroy_missed", "args": [], "telemetry": "roll missed", "keep": false}
			var victim = _first_enemy_unit(foe, territory_id, String(rule.get("type", "")))
			if victim == null:
				return _refused("no enemy target on %s" % territory_id)
			var victim_name: String = Localization.get_card_name(victim.card_data)
			GameManager._units_on_map[territory_id].erase(victim)
			if GameManager._units_on_map[territory_id].is_empty():
				GameManager._units_on_map.erase(territory_id)
			if rule.get("mutual", false) and not own_units.is_empty():
				var lost = own_units[own_units.size() - 1]
				GameManager._units_on_map[territory_id].erase(lost)
				key = "sit.ok.destroy_mutual"
				args = [victim_name]
				telemetry = "mutual destroy at %s (%s, own %s lost)" % [territory_id, victim.id, lost.id]
			else:
				key = "sit.ok.destroy"
				args = [victim_name]
				telemetry = "destroyed %s at %s" % [victim.id, territory_id]
		"reveal_hand":
			var enemy_hand: Array = hands.get(foe, [])
			var names: Array = []
			for c in enemy_hand:
				names.append(Localization.get_card_name(c.card_data))
			key = "sit.ok.reveal_hand"
			args = [", ".join(names) if names.size() > 0 else Localization.t("ui.no_units")]
			telemetry = "revealed enemy hand (%d cards)" % enemy_hand.size()
		"reveal_map":
			var seen: Array = []
			for u in GameManager._units_on_map.get(territory_id, []):
				if u.has_method("is_alive") and u.is_alive() and u.side == foe:
					seen.append(Localization.get_card_name(u.card_data))
			key = "sit.ok.reveal_map"
			args = [", ".join(seen) if seen.size() > 0 else Localization.t("ui.no_units")]
			telemetry = "revealed %d enemy units on %s" % [seen.size(), territory_id]
		_:
			return _refused("not playable")
	return {"ok": true, "key": key, "args": args, "telemetry": telemetry, "keep": false}

static func _refused(telemetry: String) -> Dictionary:
	return {"ok": false, "key": "sit.err.conditions", "args": [], "telemetry": telemetry, "keep": true}

static func _own_units(side: String, territory_id: String) -> Array:
	var result: Array = []
	for u in GameManager._units_on_map.get(territory_id, []):
		if u.has_method("is_alive") and u.is_alive() and u.side == side:
			result.append(u)
	return result

static func _first_enemy_unit(foe: String, territory_id: String, unit_type: String):
	for u in GameManager._units_on_map.get(territory_id, []):
		if u.has_method("is_alive") and u.is_alive() and u.side == foe:
			if unit_type == "" or String(u.card_data.get("type", "")) == unit_type:
				return u
	return null

static func _remove_random_enemy_unit(foe: String) -> void:
	var pool: Array = []
	for t_id in GameManager._units_on_map:
		for u in GameManager._units_on_map[t_id]:
			if u.has_method("is_alive") and u.is_alive() and u.side == foe:
				pool.append({"t": t_id, "u": u})
	if pool.is_empty():
		return
	var pick: Dictionary = pool[randi() % pool.size()]
	GameManager._units_on_map[pick["t"]].erase(pick["u"])
	if GameManager._units_on_map[pick["t"]].is_empty():
		GameManager._units_on_map.erase(pick["t"])

static func _buff_units(side: String, territory_id: String, atk: int, def: int, unit_type: String, one_only: bool) -> String:
	var affected: int = 0
	for u in GameManager._units_on_map.get(territory_id, []):
		if not (u.has_method("is_alive") and u.is_alive()) or u.side != side:
			continue
		if unit_type != "" and String(u.card_data.get("type", "")) != unit_type:
			continue
		u.attack += atk
		u.defense += def
		affected += 1
		if one_only:
			break
	if affected == 0:
		return ""
	return "%d units ATK %d DEF %d on %s" % [affected, atk, def, territory_id]

static func _draw_into_hand(side: String, count: int, hands: Dictionary) -> int:
	var pool: Array = CardDatabase.get_all_units_for_side(side)
	if pool.is_empty():
		return 0
	var drawn: int = 0
	for i in range(count):
		var card_data: Dictionary = pool[randi() % pool.size()]
		var card = load("res://scripts/cards/card_instance.gd").new(card_data)
		hands[side].append(card)
		drawn += 1
	return drawn

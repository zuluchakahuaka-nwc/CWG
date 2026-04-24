extends Node

signal turn_phase_started(phase_name: String)
signal turn_phase_ended(phase_name: String)

var _phase_names: PackedStringArray = [
	"phase.resources", "phase.draw", "phase.movement",
	"phase.combat", "phase.events", "phase.end"
]

func _ready() -> void:
	GameManager.phase_changed.connect(_on_phase_changed)

func _on_phase_changed(phase: GameManager.Phase) -> void:
	var phase_name: String = Localization.t(_phase_names[phase])
	turn_phase_started.emit(phase_name)
	match phase:
		GameManager.Phase.RESOURCES:
			_process_resources()
		GameManager.Phase.DRAW:
			_process_draw()
		GameManager.Phase.MOVEMENT:
			pass
		GameManager.Phase.COMBAT:
			pass
		GameManager.Phase.EVENTS:
			_process_events()
		GameManager.Phase.END:
			_process_end()
	turn_phase_ended.emit(phase_name)

func _process_resources() -> void:
	for side in ["union", "confederate"]:
		var income: Dictionary = {"manpower": 0, "money": 0, "supply": 0}
		for t_id in GameManager._territory_owners:
			if GameManager._territory_owners[t_id] == side:
				var t: Dictionary = CardDatabase.get_territory(t_id)
				income["manpower"] += t.get("resource_manpower", 0)
				income["money"] += t.get("resource_money", 0)
				income["supply"] += t.get("resource_supply", 0)
		for res in income:
			GameManager.change_resource(side, res, income[res])

func _process_draw() -> void:
	var base_draw: int = 3
	for side in ["union", "confederate"]:
		var bonus: int = GameManager.get_morale_bonus_cards(side)
		var draw_count: int = base_draw + bonus
		pass

func _process_events() -> void:
	for side in ["union", "confederate"]:
		var m: int = GameManager.get_morale(side)
		if m <= -14:
			var roll: int = randi_range(1, 10)
			if roll <= 1:
				pass
		if m <= -10:
			var roll: int = randi_range(1, 10)
			if roll <= 1:
				pass
		if m <= -19:
			var roll: int = randi_range(1, 5)
			if roll <= 1:
				pass
		var streak: int = GameManager.get_conscription_streak(side)
		if streak >= 3:
			pass

func _process_end() -> void:
	for side in ["union", "confederate"]:
		GameManager.reset_conscription(side)
	GameManager.advance_phase()

func get_phase_name(phase: int) -> String:
	if phase >= 0 and phase < _phase_names.size():
		return Localization.t(_phase_names[phase])
	return ""

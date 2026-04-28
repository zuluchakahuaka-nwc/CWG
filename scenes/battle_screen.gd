extends Control

var _territory_id: String = ""
var _attacker_units: Array = []
var _defender_units: Array = []
var _resolver: RefCounted = load("res://scripts/combat/battle_resolver.gd").new()

@onready var _title: Label = $TitleLabel
@onready var _territory_label: Label = $TerritoryLabel
@onready var _resolve_btn: Button = $ResolveButton
@onready var _back_btn: Button = $BackButton
@onready var _combat_log: RichTextLabel = $CombatLog

func _ready() -> void:
	_resolve_btn.pressed.connect(_on_resolve)
	_back_btn.pressed.connect(_on_back)
	_localize()

func setup(territory_id: String, attacker_units: Array, defender_units: Array) -> void:
	_territory_id = territory_id
	_attacker_units = attacker_units
	_defender_units = defender_units
	var t: Dictionary = CardDatabase.get_territory(territory_id)
	_territory_label.text = Localization.get_card_name(t)
	_display_units()

func _display_units() -> void:
	var atk_panel: VBoxContainer = $AttackerPanel/AttackerUnits
	var def_panel: VBoxContainer = $DefenderPanel/DefenderUnits
	for child in atk_panel.get_children():
		child.queue_free()
	for child in def_panel.get_children():
		child.queue_free()
	for unit in _attacker_units:
		var label: Label = Label.new()
		label.text = unit.get_name() + " ATK:" + str(unit.get_effective_attack()) + " DEF:" + str(unit.get_effective_defense()) + " HP:" + str(unit.current_hp)
		atk_panel.add_child(label)
	for unit in _defender_units:
		var label: Label = Label.new()
		label.text = unit.get_name() + " ATK:" + str(unit.get_effective_attack()) + " DEF:" + str(unit.get_effective_defense()) + " HP:" + str(unit.current_hp)
		def_panel.add_child(label)

func _on_resolve() -> void:
	var t: Dictionary = CardDatabase.get_territory(_territory_id)
	var result: Dictionary = _resolver.resolve_territory_battle(_attacker_units, _defender_units, t)
	_display_result(result)
	if result.get("territory_captured", false):
		var new_owner: String = result.get("attacker_side", "")
		GameManager.set_territory_owner(_territory_id, new_owner)
	_resolve_btn.disabled = true

func _display_result(result: Dictionary) -> void:
	var log_text: String = ""
	log_text += "[b]Battle for " + _territory_label.text + "[/b]\n"
	for combat in result.get("individual_results", []):
		log_text += combat.get("attacker_id", "?") + " vs " + combat.get("defender_id", "?") + ": "
		if combat.get("defender_destroyed", false):
			log_text += "[color=red]Defender destroyed![/color]\n"
		elif combat.get("attacker_destroyed", false):
			log_text += "[color=red]Attacker destroyed![/color]\n"
		else:
			log_text += "Both survived\n"
	if result.get("territory_captured", false):
		log_text += "[color=gold]TERRITORY CAPTURED by " + result.get("attacker_side", "") + "![/color]"
	_combat_log.text = log_text

func _on_back() -> void:
	get_tree().change_scene_to_file("res://scenes/game_map.tscn")

func _localize() -> void:
	_title.text = Localization.t("phase.combat")
	_resolve_btn.text = "Resolve"
	_back_btn.text = Localization.t("game.back")

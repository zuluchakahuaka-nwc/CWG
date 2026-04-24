@tool
extends Control

var _card_data: Dictionary = {}
var _card_instance: CardInstance = null

signal card_selected(data: Dictionary)
signal card_played(data: Dictionary)

const CARD_W: int = 160
const CARD_H: int = 240
const STAT_SIZE: int = 22
const FONT_SIZE_NAME: int = 11
const FONT_SIZE_STAT: int = 14
const FONT_SIZE_TYPE: int = 9

var _side_color: Color = Color(0.3, 0.5, 0.9)
var _enemy_color: Color = Color(0.9, 0.3, 0.3)

func _ready() -> void:
	custom_minimum_size = Vector2(CARD_W, CARD_H)
	size = Vector2(CARD_W, CARD_H)

func setup(data: Dictionary) -> void:
	_card_data = data
	queue_redraw()

func setup_with_instance(instance: CardInstance) -> void:
	_card_instance = instance
	_card_data = instance.card_data
	queue_redraw()

func _draw() -> void:
	if _card_data.is_empty():
		return
	var rect: Rect2 = Rect2(0, 0, CARD_W, CARD_H)
	var side: String = _card_data.get("side", "union")
	var rarity: String = _card_data.get("rarity", "common")
	var card_type: String = _card_data.get("type", "infantry")

	var bg_color: Color = Color(0.15, 0.2, 0.35) if side == "union" else Color(0.35, 0.15, 0.12)
	var border_color: Color = _get_rarity_color(rarity)
	var side_accent: Color = Color(0.3, 0.5, 0.9) if side == "union" else Color(0.9, 0.3, 0.3)

	draw_rect(rect, bg_color, true)
	draw_rect(rect, border_color, false, 3.0)
	draw_line(Vector2(0, 50), Vector2(CARD_W, 50), side_accent, 2.0)
	draw_line(Vector2(0, CARD_H - 55), Vector2(CARD_W, CARD_H - 55), side_accent, 1.0)
	draw_line(Vector2(0, 0), Vector2(0, CARD_H), side_accent, 4.0)
	draw_line(Vector2(CARD_W, 0), Vector2(CARD_W, CARD_H), side_accent, 4.0)

	var name_str: String = Localization.get_card_name(_card_data)
	var name_font: Font = ThemeDB.fallback_font
	var name_color: Color = Color.WHITE
	draw_string(name_font, Vector2(8, 20), name_str, HORIZONTAL_ALIGNMENT_LEFT, CARD_W - 16, FONT_SIZE_NAME, name_color)

	var type_str: String = _get_type_icon(card_type) + " " + Localization.t("card_type." + card_type)
	draw_string(name_font, Vector2(8, 42), type_str, HORIZONTAL_ALIGNMENT_LEFT, CARD_W - 16, FONT_SIZE_TYPE, Color(0.7, 0.7, 0.7))

	var portrait_path: String = _get_portrait_path()
	if portrait_path != "" and ResourceLoader.exists(portrait_path):
		var tex: Texture2D = load(portrait_path)
		if tex:
			var tex_rect: Rect2 = Rect2(5, 53, CARD_W - 10, CARD_H - 110)
			draw_texture_rect(tex, tex_rect, false)

	draw_rect(Rect2(0, CARD_H - 55, CARD_W, 55), Color(0.05, 0.05, 0.05, 0.85), true)

	var atk: int = _get_stat("attack")
	var def: int = _get_stat("defense")
	var hp: int = _get_stat("hp")
	var cost: int = _card_data.get("cost", 0)

	draw_string(name_font, Vector2(8, CARD_H - 35), "ATK", HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE_TYPE, Color(0.7, 0.7, 0.7))
	draw_string(name_font, Vector2(45, CARD_H - 35), "DEF", HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE_TYPE, Color(0.7, 0.7, 0.7))
	draw_string(name_font, Vector2(82, CARD_H - 35), "HP", HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE_TYPE, Color(0.7, 0.7, 0.7))
	draw_string(name_font, Vector2(118, CARD_H - 35), "COST", HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE_TYPE, Color(0.9, 0.8, 0.2))

	draw_string(name_font, Vector2(8, CARD_H - 12), str(atk), HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE_STAT, Color(1.0, 0.4, 0.3))
	draw_string(name_font, Vector2(45, CARD_H - 12), str(def), HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE_STAT, Color(0.3, 0.6, 1.0))
	draw_string(name_font, Vector2(82, CARD_H - 12), str(hp), HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE_STAT, Color(0.3, 0.9, 0.3))
	draw_string(name_font, Vector2(118, CARD_H - 12), str(cost), HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE_STAT, Color(1.0, 0.9, 0.2))

	if _card_instance and _card_instance.current_hp < _card_instance.max_hp:
		var hp_ratio: float = float(_card_instance.current_hp) / float(_card_instance.max_hp)
		var bar_color: Color = Color(0.3, 0.9, 0.3) if hp_ratio > 0.5 else Color(0.9, 0.3, 0.1)
		draw_rect(Rect2(82, CARD_H - 8, 30 * hp_ratio, 4), bar_color, true)
		draw_rect(Rect2(82, CARD_H - 8, 30, 4), Color(0.3, 0.3, 0.3), false, 1.0)

	if card_type == "commander":
		draw_string(name_font, Vector2(CARD_W - 20, 42), "★", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.GOLD)

	if _card_data.get("linked_events", []).size() > 0:
		draw_string(name_font, Vector2(CARD_W - 14, 18), "⚡", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.YELLOW)

func _get_stat(stat: String) -> int:
	if _card_instance:
		match stat:
			"attack": return _card_instance.get_effective_attack()
			"defense": return _card_instance.get_effective_defense()
			"hp": return _card_instance.current_hp
	return _card_data.get(stat, 0)

func _get_rarity_color(rarity: String) -> Color:
	match rarity:
		"common": return Color(0.5, 0.5, 0.5)
		"uncommon": return Color(0.2, 0.7, 0.2)
		"rare": return Color(0.2, 0.4, 0.9)
		"legendary": return Color(1.0, 0.84, 0.0)
		_: return Color(0.5, 0.5, 0.5)

func _get_type_icon(type: String) -> String:
	match type:
		"infantry": return "🔫"
		"cavalry": return "🐎"
		"artillery": return "💣"
		"ship": return "⚓"
		"special": return "🎯"
		"situation": return "📜"
		"commander": return "⭐"
		_: return ""

func _get_portrait_path() -> String:
	var card_id: String = _card_data.get("id", "")
	var side: String = _card_data.get("side", "union")
	var type: String = _card_data.get("type", "infantry")
	var base: String = "res://assets/sprites/cards/"
	if type == "situation":
		return base + "situations/" + card_id + ".png"
	if side == "union":
		return base + "units_union/" + card_id + ".png"
	else:
		return base + "units_confederate/" + card_id + ".png"

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			card_selected.emit(_card_data)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			card_played.emit(_card_data)

func get_card_data() -> Dictionary:
	return _card_data

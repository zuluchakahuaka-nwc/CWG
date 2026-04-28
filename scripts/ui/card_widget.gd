@tool
class_name CardWidget
extends Control

var _card_data: Dictionary = {}
var _card_instance: CardInstance = null

signal card_selected(data: Dictionary)
signal card_played(data: Dictionary)

var _side_color: Color = Color(0.3, 0.5, 0.9)
var _enemy_color: Color = Color(0.9, 0.3, 0.3)

func _ready() -> void:
	if custom_minimum_size.x < 10:
		custom_minimum_size = Vector2(120, 170)

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
	var w: float = size.x
	var h: float = size.y
	if w < 10 or h < 10:
		w = custom_minimum_size.x
		h = custom_minimum_size.y
	var rect: Rect2 = Rect2(0, 0, w, h)
	var side: String = _card_data.get("side", "union")
	var rarity: String = _card_data.get("rarity", "common")
	var card_type: String = _card_data.get("type", "infantry")

	var bg_color: Color = Color(0.15, 0.2, 0.35) if side == "union" else Color(0.35, 0.15, 0.12)
	var border_color: Color = _get_rarity_color(rarity)
	var side_accent: Color = Color(0.3, 0.5, 0.9) if side == "union" else Color(0.9, 0.3, 0.3)

	draw_rect(rect, bg_color, true)
	draw_rect(rect, border_color, false, 2.0)

	var name_h: float = h * 0.14
	var stat_h: float = h * 0.22
	var portrait_y: float = name_h
	var portrait_h: float = h - name_h - stat_h

	draw_line(Vector2(0, name_h), Vector2(w, name_h), side_accent, 2.0)
	draw_line(Vector2(0, h - stat_h), Vector2(w, h - stat_h), side_accent, 1.0)

	var name_font: Font = FontLoader.get_font("display") if FontLoader else ThemeDB.fallback_font
	var body_font: Font = FontLoader.get_font("body") if FontLoader else ThemeDB.fallback_font
	var stat_font: Font = FontLoader.get_font("caption") if FontLoader else ThemeDB.fallback_font
	var name_str: String = Localization.get_card_name(_card_data) if Localization else _card_data.get("name_en", _card_data.get("id", ""))
	var font_name_size: int = maxi(8, int(name_h * 0.65))
	draw_string(name_font, Vector2(4, name_h * 0.75), name_str, HORIZONTAL_ALIGNMENT_LEFT, w - 8, font_name_size, Color.WHITE)

	var type_str: String = _get_type_icon(card_type)
	var font_type_size: int = maxi(7, int(name_h * 0.5))
	draw_string(body_font, Vector2(w - 20, name_h * 0.75), type_str, HORIZONTAL_ALIGNMENT_LEFT, -1, font_type_size, Color(0.7, 0.7, 0.7))

	var portrait_rect: Rect2 = Rect2(3, portrait_y + 2, w - 6, portrait_h - 4)
	var portrait_path: String = _get_portrait_path()
	var portrait_tex: Texture2D = _load_image(portrait_path)
	if portrait_tex:
		draw_texture_rect(portrait_tex, portrait_rect, false)
	else:
		_draw_placeholder(portrait_rect, name_str, side)

	draw_rect(Rect2(0, h - stat_h, w, stat_h), Color(0.05, 0.05, 0.05, 0.88), true)

	var atk: int = _get_stat("attack")
	var def: int = _get_stat("defense")
	var hp: int = _get_stat("hp")
	var cost: int = _card_data.get("cost", 0)

	var font_stat_size: int = maxi(8, int(stat_h * 0.35))
	var font_label_size: int = maxi(6, int(stat_h * 0.25))
	var col_w: float = w / 4.0
	var sy_labels: float = h - stat_h + stat_h * 0.4
	var sy_values: float = h - stat_h * 0.2

	draw_string(stat_font, Vector2(col_w * 0.0 + 4, sy_labels), Localization.t("stat.attack"), HORIZONTAL_ALIGNMENT_LEFT, -1, font_label_size, Color(0.7, 0.7, 0.7))
	draw_string(stat_font, Vector2(col_w * 1.0 + 4, sy_labels), Localization.t("stat.defense"), HORIZONTAL_ALIGNMENT_LEFT, -1, font_label_size, Color(0.7, 0.7, 0.7))
	draw_string(stat_font, Vector2(col_w * 2.0 + 4, sy_labels), Localization.t("stat.hp"), HORIZONTAL_ALIGNMENT_LEFT, -1, font_label_size, Color(0.7, 0.7, 0.7))
	draw_string(stat_font, Vector2(col_w * 3.0 + 4, sy_labels), Localization.t("stat.cost"), HORIZONTAL_ALIGNMENT_LEFT, -1, font_label_size, Color(0.9, 0.8, 0.2))

	draw_string(stat_font, Vector2(col_w * 0.0 + 4, sy_values), str(atk), HORIZONTAL_ALIGNMENT_LEFT, -1, font_stat_size, Color(1.0, 0.4, 0.3))
	draw_string(stat_font, Vector2(col_w * 1.0 + 4, sy_values), str(def), HORIZONTAL_ALIGNMENT_LEFT, -1, font_stat_size, Color(0.3, 0.6, 1.0))
	draw_string(stat_font, Vector2(col_w * 2.0 + 4, sy_values), str(hp), HORIZONTAL_ALIGNMENT_LEFT, -1, font_stat_size, Color(0.3, 0.9, 0.3))
	draw_string(stat_font, Vector2(col_w * 3.0 + 4, sy_values), str(cost), HORIZONTAL_ALIGNMENT_LEFT, -1, font_stat_size, Color(1.0, 0.9, 0.2))

	if _card_instance and _card_instance.current_hp < _card_instance.max_hp:
		var hp_ratio: float = float(_card_instance.current_hp) / float(_card_instance.max_hp)
		var bar_color: Color = Color(0.3, 0.9, 0.3) if hp_ratio > 0.5 else Color(0.9, 0.3, 0.1)
		var bar_w: float = col_w * 0.8
		draw_rect(Rect2(col_w * 2.0 + 4, sy_values + 4, bar_w * hp_ratio, 3), bar_color, true)
		draw_rect(Rect2(col_w * 2.0 + 4, sy_values + 4, bar_w, 3), Color(0.3, 0.3, 0.3), false, 1.0)

	if _card_data.get("linked_events", []).size() > 0:
		draw_string(body_font, Vector2(w - 16, name_h * 0.4), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, font_name_size, Color.YELLOW)

func _draw_placeholder(rect: Rect2, card_name: String, side: String) -> void:
	var placeholder_color: Color = Color(0.1, 0.15, 0.25, 0.9) if side == "union" else Color(0.25, 0.1, 0.1, 0.9)
	draw_rect(rect, placeholder_color, true)
	draw_rect(rect, Color(0.4, 0.4, 0.4, 0.5), false, 1.0)
	var icon: String = _get_type_icon(_card_data.get("type", ""))
	var font: Font = FontLoader.get_font("display") if FontLoader else ThemeDB.fallback_font
	var icon_size: int = maxi(16, int(rect.size.y * 0.25))
	draw_string(font, rect.position + Vector2(rect.size.x * 0.35, rect.size.y * 0.45), icon, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x * 0.3, icon_size, Color(0.6, 0.6, 0.6))
	var short: String = card_name.left(10)
	var name_size: int = maxi(7, int(rect.size.y * 0.08))
	draw_string(font, rect.position + Vector2(4, rect.size.y * 0.7), short, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 8, name_size, Color(0.5, 0.5, 0.5))

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
	var key: String = "card_type." + type
	return Localization.t(key)

func _get_portrait_path() -> String:
	var card_id: String = _card_data.get("id", "")
	var side: String = _card_data.get("side", "union")
	var type: String = _card_data.get("type", "infantry")
	var base: String = "res://assets/sprites/cards/"
	var sub: String = ""
	if type == "situation":
		sub = "situations/"
	elif side == "union":
		sub = "units_union/"
	else:
		sub = "units_confederate/"
	var jpg_path: String = base + sub + card_id + ".jpg"
	if FileAccess.file_exists(jpg_path):
		return jpg_path
	var png_path: String = base + sub + card_id + ".png"
	if FileAccess.file_exists(png_path):
		return png_path
	return ""

func _load_image(path: String) -> Texture2D:
	if path == "":
		return null
	if ResourceLoader.exists(path):
		var res = load(path)
		if res is Texture2D:
			return res
	var img: Image = Image.new()
	if img.load(path) == OK:
		return ImageTexture.create_from_image(img)
	return null

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			card_selected.emit(_card_data)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			card_played.emit(_card_data)

func get_card_data() -> Dictionary:
	return _card_data

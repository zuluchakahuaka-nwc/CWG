extends Node2D

var _territories: Dictionary = {}
var _unit_markers: Dictionary = {}
var _selected_territory: String = ""
var _highlighted_territories: Array = []

signal territory_clicked(territory_id: String)
signal territory_hovered(territory_id: String)

const COLOR_UNION: Color = Color(0.2, 0.4, 0.8, 0.85)
const COLOR_CONFEDERATE: Color = Color(0.8, 0.2, 0.2, 0.85)
const COLOR_NEUTRAL: Color = Color(0.5, 0.5, 0.5, 0.7)
const COLOR_HIGHLIGHT: Color = Color(1.0, 1.0, 0.3, 0.9)
const COLOR_UNION_BORDER: Color = Color(0.3, 0.5, 0.9)
const COLOR_CONFEDERATE_BORDER: Color = Color(0.9, 0.3, 0.3)

func _ready() -> void:
	_build_map()

func _build_map() -> void:
	for t_id in CardDatabase._territories:
		var t_data: Dictionary = CardDatabase.get_territory(t_id)
		var pos: Vector2 = Vector2(t_data.get("map_x", 0), t_data.get("map_y", 0))
		var owner: String = t_data.get("initial_owner", "neutral")
		var panel: PanelContainer = PanelContainer.new()
		panel.name = t_id
		panel.position = pos - Vector2(35, 20)
		panel.size = Vector2(70, 44)
		panel.tooltip_text = _build_tooltip(t_data, owner)
		var style: StyleBoxFlat = StyleBoxFlat.new()
		style.bg_color = _owner_color(owner)
		style.border_color = _owner_border_color(owner)
		style.set_border_width_all(2)
		style.set_corner_radius_all(4)
		panel.add_theme_stylebox_override("panel", style)
		var label: Label = Label.new()
		label.text = _short_name(t_data, t_id)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_color_override("font_color", Color.WHITE)
		label.add_theme_font_size_override("font_size", 10)
		panel.add_child(label)
		panel.gui_input.connect(_on_territory_input.bind(t_id))
		add_child(panel)
		_territories[t_id] = {"node": panel, "style": style}

func _short_name(t_data: Dictionary, t_id: String) -> String:
	var is_cap: bool = t_data.get("is_capital", false)
	var prefix: String = "★" if is_cap else ""
	var name: String = Localization.get_card_name(t_data)
	if name.length() > 12:
		var parts: PackedStringArray = name.split(" ")
		if parts.size() >= 2:
			name = parts[0].left(4) + ". " + parts[1].left(6)
	return prefix + name

func _build_tooltip(t_data: Dictionary, owner: String) -> String:
	var tip: String = Localization.get_card_name(t_data) + "\n"
	tip += Localization.t("terrain." + t_data.get("terrain", "plains"))
	if owner != "neutral":
		tip += " | " + Localization.t("side." + owner)
	if t_data.get("is_capital", false):
		tip += " ★"
	if t_data.get("is_port", false):
		tip += " ⚓"
	if t_data.get("is_railroad", false):
		tip += " 🚂"
	var bonus: String = t_data.get("special_bonus", "")
	if bonus != "":
		tip += "\n" + bonus
	return tip

func _owner_color(owner: String) -> Color:
	match owner:
		"union": return COLOR_UNION
		"confederate": return COLOR_CONFEDERATE
		"neutral": return COLOR_NEUTRAL
		_: return Color(0.4, 0.4, 0.4, 0.7)

func _owner_border_color(owner: String) -> Color:
	match owner:
		"union": return COLOR_UNION_BORDER
		"confederate": return COLOR_CONFEDERATE_BORDER
		"neutral": return Color(0.6, 0.6, 0.6)
		_: return Color(0.5, 0.5, 0.5)

func _on_territory_input(event: InputEvent, territory_id: String) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_selected_territory = territory_id
			territory_clicked.emit(territory_id)
	elif event is InputEventMouseMotion:
		territory_hovered.emit(territory_id)

func update_territory_display() -> void:
	for t_id in _territories:
		var info: Dictionary = _territories[t_id]
		var owner: String = GameManager.get_territory_owner(t_id)
		info["style"].bg_color = _owner_color(owner)
		info["style"].border_color = _owner_border_color(owner)
		var t_data: Dictionary = CardDatabase.get_territory(t_id)
		info["node"].tooltip_text = _build_tooltip(t_data, owner)
	update_unit_markers()

func update_unit_markers() -> void:
	for marker_id in _unit_markers:
		if is_instance_valid(_unit_markers[marker_id]):
			_unit_markers[marker_id].queue_free()
	_unit_markers.clear()
	for t_id in GameManager._units_on_map:
		var units: Array = GameManager._units_on_map[t_id]
		if units.is_empty():
			continue
		var t_data: Dictionary = CardDatabase.get_territory(t_id)
		var base_pos: Vector2 = Vector2(t_data.get("map_x", 0), t_data.get("map_y", 0))
		var counts: Dictionary = {}
		for unit in units:
			if unit is CardInstance:
				counts[unit.side] = counts.get(unit.side, 0) + 1
		var offset_idx: int = 0
		for side in counts:
			var marker: Label = Label.new()
			marker.text = str(counts[side]) + ("⚔" if side == "confederate" else "⚔")
			marker.position = base_pos + Vector2(-25 + offset_idx * 35, -30)
			marker.add_theme_color_override("font_color", _owner_color(side))
			marker.add_theme_font_size_override("font_size", 14)
			add_child(marker)
			_unit_markers[t_id + "_" + side] = marker
			offset_idx += 1

func highlight_territories(territory_ids: Array) -> void:
	clear_highlights()
	for t_id in territory_ids:
		if _territories.has(t_id):
			_territories[t_id]["style"].bg_color = COLOR_HIGHLIGHT
			_territories[t_id]["style"].border_color = Color(1.0, 0.9, 0.0)
			_highlighted_territories.append(t_id)

func clear_highlights() -> void:
	for t_id in _highlighted_territories:
		if _territories.has(t_id):
			var owner: String = GameManager.get_territory_owner(t_id)
			_territories[t_id]["style"].bg_color = _owner_color(owner)
			_territories[t_id]["style"].border_color = _owner_border_color(owner)
	_highlighted_territories.clear()

func get_selected_territory() -> String:
	return _selected_territory

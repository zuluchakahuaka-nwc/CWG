extends Control

var _map_controller: Control
var _selected_territory_id: String = ""
var _move_source: String = ""
var _active_side: String = "union"
var _hands: Dictionary = {"union": [], "confederate": []}
func _get_phase_names() -> PackedStringArray:
	return PackedStringArray([
		Localization.t("phase.resources"),
		Localization.t("phase.draw"),
		Localization.t("phase.movement"),
		Localization.t("phase.combat"),
		Localization.t("phase.events"),
		Localization.t("phase.end"),
	])
var _battle_log: String = ""
var _card_nodes: Array = []
var _bg_music = null
var _PhonographPlayerScript = load("res://scripts/ui/phonograph_player.gd")

var _zoom_level: float = 2.0
var _min_zoom: float = 2.0
var _max_zoom: float = 6.0
var _zoom_step: float = 0.2
var _is_panning: bool = false
var _pan_start: Vector2 = Vector2.ZERO
var _pan_offset: Vector2 = Vector2.ZERO

@onready var _turn_label: Label = $TopBar/HBox/TurnInfo
@onready var _phase_label: Label = $TopBar/HBox/PhaseLabel
@onready var _side_label: Label = $TopBar/HBox/SideLabel
@onready var _settings_btn: Button = $TopBar/HBox/SettingsButton
@onready var _phonograph_btn: Button = $TopBar/HBox/PhonographButton
@onready var _menu_btn: Button = $TopBar/HBox/MenuButton
@onready var _edit_map_btn: Button = $TopBar/HBox/EditMapButton
@onready var _save_map_btn: Button = $TopBar/HBox/SaveMapButton
@onready var _end_turn_btn: Button = $StatusBar/EndTurnButton
@onready var _auto_turn_btn: Button = $StatusBar/AutoTurnButton
@onready var _map_area: Control = $MapArea
@onready var _manpower_label: Label = $StatusBar/ManpowerLabel
@onready var _money_label: Label = $StatusBar/MoneyLabel
@onready var _supply_label: Label = $StatusBar/SupplyLabel
@onready var _morale_label: Label = $StatusBar/MoraleLabel
@onready var _morale_status: Label = $StatusBar/MoraleStatus
@onready var _info_label: Label = $StatusBar/InfoLabel
@onready var _detail_popup: PanelContainer = $CardDetailPopup
@onready var _detail_image: TextureRect = $CardDetailPopup/DetailVBox/DetailImage
@onready var _detail_name: Label = $CardDetailPopup/DetailVBox/DetailName
@onready var _detail_stats: Label = $CardDetailPopup/DetailVBox/DetailStats
@onready var _detail_desc: Label = $CardDetailPopup/DetailVBox/DetailDesc
@onready var _detail_close: Button = $CardDetailPopup/DetailVBox/DetailClose
@onready var _terr_info: PanelContainer = $TerritoryInfoPanel
@onready var _terr_name: Label = $TerritoryInfoPanel/TVBox/TName
@onready var _terr_owner: Label = $TerritoryInfoPanel/TVBox/TOwner
@onready var _terr_terrain: Label = $TerritoryInfoPanel/TVBox/TTerrain
@onready var _terr_units_label: Label = $TerritoryInfoPanel/TVBox/TUnitsLabel
@onready var _terr_units_list: VBoxContainer = $TerritoryInfoPanel/TVBox/TUnitsList

var _hand_container: HBoxContainer = null
var _hand_label: Label = null
var _drag_card_idx: int = -1
var _drag_preview: Control = null
var _dragging: bool = false
var _selected_card_idx: int = -1

func _build_hand_panel() -> void:
	_hand_label = Label.new()
	_hand_label.name = "HandLabel"
	_hand_label.text = "HAND: 0 cards"
	_hand_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_hand_label.offset_left = 8.0
	_hand_label.offset_top = -42.0
	_hand_label.offset_right = -8.0
	_hand_label.offset_bottom = -24.0
	_hand_label.z_index = 12
	add_child(_hand_label)
	var hand_panel: Control = Control.new()
	hand_panel.name = "HandPanel"
	hand_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	hand_panel.offset_left = 4.0
	hand_panel.offset_top = -500.0
	hand_panel.offset_right = -4.0
	hand_panel.offset_bottom = -44.0
	hand_panel.z_index = 12
	hand_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hand_panel.clip_contents = false
	_hand_container = HBoxContainer.new()
	_hand_container.name = "HandCards"
	_hand_container.add_theme_constant_override("separation", -160)
	_hand_container.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_hand_container.offset_top = -170.0
	_hand_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hand_panel.add_child(_hand_container)
	add_child(hand_panel)

func _ready() -> void:
	var map_ctrl_script = load("res://scripts/map/map_controller.gd")
	_map_controller = Control.new()
	_map_controller.set_script(map_ctrl_script)
	_map_controller.set_anchors_preset(Control.PRESET_FULL_RECT)
	_map_area.add_child(_map_controller)
	await get_tree().process_frame
	_apply_map_transform()
	_build_hand_panel()
	_end_turn_btn.pressed.connect(_on_end_turn)
	_auto_turn_btn.pressed.connect(_on_auto_turn)
	_phonograph_btn.pressed.connect(_on_phonograph)
	_menu_btn.pressed.connect(_on_menu)
	_settings_btn.pressed.connect(_on_settings)
	_detail_close.pressed.connect(_on_close_detail)
	$TerritoryInfoPanel/TVBox/TClose.pressed.connect(_on_close_terr_info)
	_edit_map_btn.toggled.connect(_on_edit_map_toggle)
	_save_map_btn.pressed.connect(_on_save_map)
	GameManager.turn_changed.connect(_on_turn_changed)
	GameManager.phase_changed.connect(_on_phase_changed)
	_map_controller.territory_clicked.connect(_on_territory_clicked)
	_active_side = "union"
	_process_phase()
	Localization.language_changed.connect(_localize)
	_localize()
	_setup_bg_music()
	Logger.info("GameMap", "Hotseat game ready. Turn=%d" % GameManager.get_current_turn())

func _input(event: InputEvent) -> void:
	if _detail_popup.visible:
		if event is InputEventMouseButton and event.pressed:
			if not _detail_popup.get_global_rect().has_point(event.global_position):
				_on_close_detail()
		return
	if _dragging:
		if event is InputEventMouseMotion and _drag_preview:
			_drag_preview.position = event.global_position - _drag_preview.size * 0.5
			accept_event()
			return
		if event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			if _drag_preview:
				_drag_preview.queue_free()
				_drag_preview = null
			_finish_drop(event.global_position)
			_dragging = false
			_drag_card_idx = -1
			accept_event()
			return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom_map(_zoom_level + _zoom_step)
			accept_event()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom_map(_zoom_level - _zoom_step)
			accept_event()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			if event.pressed:
				_is_panning = true
				_pan_start = event.position - _pan_offset
			else:
				_is_panning = false
	elif event is InputEventMouseMotion and _is_panning:
		_pan_offset = event.position - _pan_start
		_apply_map_transform()

func _zoom_map(new_zoom: float) -> void:
	new_zoom = clampf(new_zoom, _min_zoom, _max_zoom)
	if new_zoom == _zoom_level:
		return
	_zoom_level = new_zoom
	_apply_map_transform()

func _apply_map_transform() -> void:
	if _map_controller and _map_controller.has_method("set_view_transform"):
		_map_controller.set_view_transform(_zoom_level, _pan_offset)

func _process_phase() -> void:
	var phase: int = GameManager.get_current_phase()
	match phase:
		GameManager.Phase.RESOURCES:
			_phase_resources()
		GameManager.Phase.DRAW:
			_phase_draw()
		GameManager.Phase.MOVEMENT:
			_move_source = ""
		GameManager.Phase.COMBAT:
			_phase_combat()
		GameManager.Phase.EVENTS:
			_phase_events()
		GameManager.Phase.END:
			_phase_end()
	_update_ui()
	_refresh_hand()
	if _map_controller and _map_controller.has_method("update_unit_markers"):
		_map_controller.update_unit_markers()

func _phase_resources() -> void:
	for side in ["union", "confederate"]:
		for t_id in GameManager._territory_owners:
			if GameManager._territory_owners[t_id] == side:
				var t: Dictionary = CardDatabase.get_territory(t_id)
				GameManager.change_resource(side, "manpower", t.get("resource_manpower", 0))
				GameManager.change_resource(side, "money", t.get("resource_money", 0))
				GameManager.change_resource(side, "supply", t.get("resource_supply", 0))
	Logger.info("Phase", "Resources collected for both sides")

func _phase_draw() -> void:
	for side in ["union", "confederate"]:
		var count: int = 3 + GameManager.get_morale_bonus_cards(side)
		var all_units: Array = CardDatabase.get_all_units_for_side(side)
		if all_units.is_empty():
			continue
		for i in range(count):
			var card_data: Dictionary = all_units[randi() % all_units.size()]
			var ci_script = load("res://scripts/cards/card_instance.gd")
			var card = ci_script.new(card_data)
			_hands[side].append(card)
		Logger.info("Phase", "Drew %d cards for %s (hand: %d)" % [count, side, _hands[side].size()])

func _phase_combat() -> void:
	_battle_log = ""
	var contested: Array = []
	for t_id in GameManager._units_on_map:
		var units: Array = GameManager._units_on_map[t_id]
		if units.size() < 2:
			continue
		var sides: Dictionary = {}
		for u in units:
			if u.has_method("is_alive") and u.is_alive():
				sides[u.side] = sides.get(u.side, 0) + 1
		if sides.keys().size() >= 2:
			contested.append(t_id)
	for t_id in contested:
		var units: Array = GameManager._units_on_map[t_id]
		var attackers: Array = []
		var defenders: Array = []
		var defender_side: String = GameManager.get_territory_owner(t_id)
		for u in units:
			if u.has_method("is_alive") and u.is_alive():
				if u.side == defender_side:
					defenders.append(u)
				else:
					attackers.append(u)
		if attackers.is_empty() or defenders.is_empty():
			continue
		var t_data: Dictionary = CardDatabase.get_territory(t_id)
		var resolver_script = load("res://scripts/combat/battle_resolver.gd")
		var resolver = resolver_script.new()
		var result: Dictionary = resolver.resolve_territory_battle(attackers, defenders, t_data)
		var t_name: String = t_data.get("name_en", t_id)
		_battle_log += "%s: %d vs %d -> ATK lost %d DEF lost %d" % [t_name, attackers.size(), defenders.size(), result["attacker_losses"], result["defender_losses"]]
		if result["territory_captured"]:
			var new_owner: String = attackers[0].side
			GameManager.set_territory_owner(t_id, new_owner)
			_battle_log += " CAPTURED by %s!" % new_owner
			if t_data.get("is_capital", false):
				GameManager.change_morale(new_owner, 5)
		_battle_log += "\n"
	var alive: Array = []
	for t_id in GameManager._units_on_map:
		var units: Array = GameManager._units_on_map[t_id]
		var still_alive: Array = []
		for u in units:
			if u.has_method("is_alive") and u.is_alive():
				still_alive.append(u)
		if not still_alive.is_empty():
			alive.append({"t_id": t_id, "units": still_alive})
	GameManager._units_on_map.clear()
	for entry in alive:
		GameManager._units_on_map[entry["t_id"]] = entry["units"]
	if _battle_log != "":
		Logger.info("Phase", "Combat results:\n" + _battle_log)

func _phase_events() -> void:
	for side in ["union", "confederate"]:
		var m: int = GameManager.get_morale(side)
		if m <= -10:
			if randi_range(1, 10) == 1:
				var units: Array = GameManager._units_on_map.values().filter(func(u): return u.size() > 0)
				if not units.is_empty():
					var t_units: Array = units[randi() % units.size()]
					if t_units.size() > 0:
						t_units.pop_at(0)
						GameManager.change_morale(side, -1)
		if m <= -15:
			if randi_range(1, 5) == 1:
				var owned: Array = []
				for t_id in GameManager._territory_owners:
					if GameManager._territory_owners[t_id] == side:
						owned.append(t_id)
				if owned.size() > 3:
					GameManager.set_territory_owner(owned[randi() % owned.size()], "neutral")

func _phase_end() -> void:
	for side in ["union", "confederate"]:
		for t_id in GameManager._units_on_map:
			for unit in GameManager._units_on_map[t_id]:
				if unit.has_method("tick_buffs"):
					unit.tick_buffs()
	Logger.info("Phase", "Turn end processed.")

func _load_image_texture(path: String) -> Texture2D:
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

func _find_card_image(card_id: String, side: String, card_type: String) -> String:
	var base: String = "res://assets/sprites/cards/"
	var sub: String = ""
	if card_type == "situation":
		sub = "situations/"
	elif side == "union":
		sub = "units_union/"
	else:
		sub = "units_confederate/"
	for ext in [".jpg", ".png"]:
		var p: String = base + sub + card_id + ext
		if FileAccess.file_exists(p):
			return p
	return ""

func _refresh_hand() -> void:
	for w in _card_nodes:
		if is_instance_valid(w):
			w.queue_free()
	_card_nodes.clear()
	var hand: Array = _hands[_active_side]
	for i in range(hand.size()):
		var card = hand[i]
		var side: String = card.side
		var bg: PanelContainer = PanelContainer.new()
		var bg_style: StyleBoxFlat = StyleBoxFlat.new()
		bg_style.bg_color = Color(0, 0, 0, 0)
		bg_style.set_border_width_all(0)
		if i == _selected_card_idx:
			bg_style.bg_color = Color(1.0, 0.9, 0.3, 0.35)
			bg_style.set_border_width_all(2)
			bg_style.border_color = Color(1.0, 0.85, 0.0)
		bg.add_theme_stylebox_override("panel", bg_style)
		bg.custom_minimum_size = Vector2(220, 340)
		var vbox: VBoxContainer = VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 2)
		var portrait: TextureRect = TextureRect.new()
		var img_path: String = _find_card_image(card.id, side, card.type)
		var tex: Texture2D = _load_image_texture(img_path)
		if tex:
			portrait.texture = tex
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		portrait.custom_minimum_size = Vector2(200, 160)
		vbox.add_child(portrait)
		var name_lbl: Label = Label.new()
		name_lbl.text = Localization.get_card_name(card.card_data)
		name_lbl.add_theme_font_size_override("font_size", 12)
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_WORD_ELLIPSIS
		name_lbl.max_lines_visible = 3
		name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		name_lbl.add_theme_color_override("font_color", Color(0, 0, 0))
		vbox.add_child(name_lbl)
		var stats_lbl: Label = Label.new()
		stats_lbl.text = "ATK:%d DEF:%d HP:%d Cost:%d" % [card.attack, card.defense, card.max_hp, card.cost]
		stats_lbl.add_theme_font_size_override("font_size", 14)
		stats_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		stats_lbl.add_theme_color_override("font_color", Color(0, 0, 0))
		vbox.add_child(stats_lbl)
		var type_lbl: Label = Label.new()
		type_lbl.text = card.type.to_upper() + " | " + card.rarity.to_upper()
		type_lbl.add_theme_font_size_override("font_size", 12)
		type_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		type_lbl.add_theme_color_override("font_color", Color(0.15, 0.15, 0.15))
		vbox.add_child(type_lbl)
		bg.add_child(vbox)
		bg.gui_input.connect(_on_card_gui_input.bind(i))
		_hand_container.add_child(bg)
		_card_nodes.append(bg)

func _on_card_gui_input(event: InputEvent, idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_drag_card_idx = idx
		_dragging = true
		_start_drag(idx)
		accept_event()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		_selected_card_idx = idx
		_refresh_hand()
		accept_event()

func _start_drag(idx: int) -> void:
	var hand: Array = _hands[_active_side]
	if idx < 0 or idx >= hand.size():
		return
	var card = hand[idx]
	_drag_preview = PanelContainer.new()
	var s: StyleBoxFlat = StyleBoxFlat.new()
	s.bg_color = Color(0.15, 0.2, 0.35, 0.9) if card.side == "union" else Color(0.35, 0.15, 0.12, 0.9)
	s.set_border_width_all(2)
	s.border_color = _rarity_color(card.rarity)
	s.set_corner_radius_all(6)
	_drag_preview.add_theme_stylebox_override("panel", s)
	_drag_preview.custom_minimum_size = Vector2(100, 60)
	_drag_preview.z_index = 200
	var lbl: Label = Label.new()
	lbl.text = Localization.get_card_name(card.card_data).left(15)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_drag_preview.add_child(lbl)
	add_child(_drag_preview)

func _finish_drop(drop_pos: Vector2) -> void:
	if _drag_card_idx < 0:
		return
	if _map_controller and _map_controller.has_method("get_territory_at_point"):
		var t_id: String = _map_controller.get_territory_at_point(drop_pos)
		if t_id != "":
			_try_place_card_at(t_id, _drag_card_idx)
			return
	var hand: Array = _hands[_active_side]
	if _drag_card_idx >= 0 and _drag_card_idx < hand.size() and _selected_territory_id != "":
		_try_place_card_at(_selected_territory_id, _drag_card_idx)

func _on_close_terr_info() -> void:
	_terr_info.visible = false

func _rarity_color(rarity: String) -> Color:
	match rarity:
		"common": return Color(0.5, 0.5, 0.5)
		"uncommon": return Color(0.2, 0.7, 0.2)
		"rare": return Color(0.2, 0.4, 0.9)
		"legendary": return Color(1.0, 0.84, 0.0)
		_: return Color(0.5, 0.5, 0.5)

func _show_card_detail(data: Dictionary) -> void:
	var card_id: String = data.get("id", "")
	var side: String = data.get("side", "union")
	var card_type: String = data.get("type", "infantry")
	var path: String = _find_card_image(card_id, side, card_type)
	var tex: Texture2D = _load_image_texture(path)
	_detail_image.texture = tex
	_detail_name.text = Localization.get_card_name(data)
	var atk: int = data.get("attack", 0)
	var dfn: int = data.get("defense", 0)
	var hp: int = data.get("hp", 0)
	var cost: int = data.get("cost", 0)
	_detail_stats.text = "ATK:%d  DEF:%d  HP:%d  Cost:%d" % [atk, dfn, hp, cost]
	var desc: String = Localization.get_card_description(data)
	if desc == "":
		desc = data.get("description_en", "")
	_detail_desc.text = desc
	_detail_popup.visible = true
	_detail_popup.size = Vector2(240, 440)
	var vp: Vector2 = get_viewport().get_visible_rect().size
	_detail_popup.position = (vp - _detail_popup.size) / 2.0

func _on_close_detail() -> void:
	_detail_popup.visible = false

func _update_ui() -> void:
	_turn_label.text = Localization.t("ui.turn") % [GameManager.get_current_turn(), GameManager.get_current_month()]
	var phase_idx: int = GameManager.get_current_phase()
	_phase_label.text = _get_phase_names()[phase_idx] if phase_idx >= 0 and phase_idx < _get_phase_names().size() else ""
	if _side_label:
		_side_label.text = Localization.t("ui.side_union_blue") if _active_side == "union" else Localization.t("ui.side_confed_red")
		_side_label.add_theme_color_override("font_color", Color(0.4, 0.6, 1.0) if _active_side == "union" else Color(1.0, 0.35, 0.35))
	_end_turn_btn.text = Localization.t("ui.end_phase")
	_auto_turn_btn.text = Localization.t("ui.skip_turn")
	if _map_controller and _map_controller.has_method("update_territory_display"):
		_map_controller.update_territory_display()
	var hand: Array = _hands[_active_side]
	_hand_label.text = "%s: %d" % [Localization.t("ui.hand"), hand.size()]
	var res: Dictionary = GameManager.get_resources(_active_side)
	if _manpower_label:
		_manpower_label.text = Localization.t("ui.men_label") % int(res.get("manpower", 0))
		_money_label.text = Localization.t("ui.gold_label") % int(res.get("money", 0))
		_supply_label.text = Localization.t("ui.supply_label") % int(res.get("supply", 0))
		_morale_label.text = Localization.t("ui.morale_label") % int(GameManager.get_morale(_active_side))
		_morale_status.text = GameManager.get_morale_status(_active_side)
	var info: String = ""
	var phase: int = GameManager.get_current_phase()
	if phase == GameManager.Phase.DRAW:
		info = Localization.t("ui.info.draw")
	elif phase == GameManager.Phase.MOVEMENT:
		if _move_source == "":
			info = Localization.t("ui.info.movement")
		else:
			info = Localization.t("ui.info.move_target") % _move_source
	elif phase == GameManager.Phase.COMBAT:
		info = Localization.t("ui.info.combat") % (_battle_log if _battle_log != "" else Localization.t("ui.info.no_battles"))
	elif phase == GameManager.Phase.RESOURCES:
		info = Localization.t("ui.info.resources_collected")
	elif phase == GameManager.Phase.EVENTS:
		info = Localization.t("ui.info.events_processed")
	elif phase == GameManager.Phase.END:
		info = Localization.t("ui.info.end_turn")
	if _info_label:
		_info_label.text = info

func _on_territory_clicked(territory_id: String) -> void:
	if _map_controller and _map_controller.has_method("clear_highlights"):
		_map_controller.clear_highlights()
	if _selected_territory_id == territory_id:
		_selected_territory_id = ""
		_terr_info.visible = false
		_update_ui()
		return
	_selected_territory_id = territory_id
	_map_controller.highlight_territories([territory_id])
	_show_territory_info(territory_id)
	var phase: int = GameManager.get_current_phase()
	if phase == GameManager.Phase.DRAW or phase == GameManager.Phase.RESOURCES:
		if _selected_card_idx >= 0:
			_try_place_card_at(territory_id, _selected_card_idx)
			_selected_card_idx = -1
	if phase == GameManager.Phase.MOVEMENT:
		_handle_movement(territory_id)
	_update_ui()

func _show_territory_info(t_id: String) -> void:
	var t: Dictionary = CardDatabase.get_territory(t_id)
	var owner: String = GameManager.get_territory_owner(t_id)
	var t_name: String = Localization.t("territory." + t_id) if Localization.has_key("territory." + t_id) else t.get("name_en", t_id)
	_terr_name.text = t_name
	if t.get("is_capital", false):
		_terr_name.text += " ★"
	_terr_owner.text = Localization.t("ui.owner") + ": " + Localization.t("side." + owner)
	_terr_terrain.text = Localization.t("ui.terrain") + ": " + Localization.t("terrain." + t.get("terrain", "plains"))
	if t.get("is_port", false):
		_terr_terrain.text += " ⚓"
	if t.get("is_railroad", false):
		_terr_terrain.text += " ═"
	for c in _terr_units_list.get_children():
		c.queue_free()
	var units: Array = GameManager._units_on_map.get(t_id, [])
	var alive_units: Array = []
	for u in units:
		if u.has_method("is_alive") and u.is_alive():
			alive_units.append(u)
	if alive_units.is_empty():
		_terr_units_label.text = Localization.t("ui.no_units")
	else:
		_terr_units_label.text = Localization.t("ui.units_count") % alive_units.size()
		for u in alive_units:
			var ulbl: Label = Label.new()
			var u_name: String = Localization.get_card_name(u.card_data)
			ulbl.text = "  %s  HP:%d/%d  A:%d D:%d" % [u_name.left(22), u.current_hp, u.max_hp, u.attack, u.defense]
			ulbl.add_theme_font_size_override("font_size", 11)
			var side_col: Color = Color(0.5, 0.7, 1.0) if u.side == "union" else Color(1.0, 0.5, 0.5)
			ulbl.add_theme_color_override("font_color", side_col)
			_terr_units_list.add_child(ulbl)
	_terr_info.visible = true

func _try_place_card_at(territory_id: String, idx: int) -> void:
	var owner: String = GameManager.get_territory_owner(territory_id)
	if owner != _active_side:
		return
	var hand: Array = _hands[_active_side]
	if hand.is_empty() or idx >= hand.size():
		return
	var card = hand[idx]
	var cost: int = card.cost
	var res: Dictionary = GameManager.get_resources(_active_side)
	if res.get("money", 0) < cost:
		return
	GameManager.change_resource(_active_side, "money", -cost)
	hand.pop_at(idx)
	card.territory_id = territory_id
	if not GameManager._units_on_map.has(territory_id):
		GameManager._units_on_map[territory_id] = []
	GameManager._units_on_map[territory_id].append(card)
	Logger.info("GameMap", "Placed %s at %s (cost %d)" % [card.id, territory_id, cost])
	_update_ui()
	_refresh_hand()
	_show_territory_info(territory_id)
	if _map_controller and _map_controller.has_method("update_unit_markers"):
		_map_controller.update_unit_markers()

func _handle_movement(territory_id: String) -> void:
	if _move_source == "":
		var units: Array = GameManager._units_on_map.get(territory_id, [])
		var has_ours: bool = false
		for u in units:
			if u.has_method("is_alive") and u.side == _active_side and not u.is_exhausted:
				has_ours = true
				break
		if has_ours:
			_move_source = territory_id
			var adj: Array = CardDatabase.get_adjacent_territories(territory_id)
			_map_controller.highlight_territories([territory_id] + adj)
	else:
		if territory_id == _move_source:
			_move_source = ""
			_map_controller.highlight_territories([territory_id])
			_update_ui()
			return
		var adj: Array = CardDatabase.get_adjacent_territories(_move_source)
		if territory_id in adj:
			_do_move(_move_source, territory_id)
		_move_source = ""

func _do_move(from_id: String, to_id: String) -> void:
	var units: Array = GameManager._units_on_map.get(from_id, [])
	var to_move: Array = []
	var to_stay: Array = []
	for u in units:
		if u.side == _active_side and not u.is_exhausted and u.has_method("is_alive") and u.is_alive():
			to_move.append(u)
		else:
			to_stay.append(u)
	if to_move.is_empty():
		return
	if to_stay.is_empty():
		GameManager._units_on_map.erase(from_id)
	else:
		GameManager._units_on_map[from_id] = to_stay
	if not GameManager._units_on_map.has(to_id):
		GameManager._units_on_map[to_id] = []
	for u in to_move:
		u.is_exhausted = true
		u.territory_id = to_id
		GameManager._units_on_map[to_id].append(u)
	Logger.info("GameMap", "Moved %d units: %s -> %s" % [to_move.size(), from_id, to_id])
	_update_ui()
	_show_territory_info(to_id)
	if _map_controller and _map_controller.has_method("update_unit_markers"):
		_map_controller.update_unit_markers()

func _on_end_turn() -> void:
	_selected_territory_id = ""
	_move_source = ""
	_terr_info.visible = false
	if _map_controller and _map_controller.has_method("clear_highlights"):
		_map_controller.clear_highlights()
	var phase: int = GameManager.get_current_phase()
	if phase == GameManager.Phase.MOVEMENT:
		for t_id in GameManager._units_on_map:
			for u in GameManager._units_on_map[t_id]:
				if u.has_method("is_alive"):
					u.is_exhausted = false
	if phase == GameManager.Phase.END:
		GameManager.advance_phase()
		_active_side = "confederate" if _active_side == "union" else "union"
		_play_music_for_side(_active_side)
	else:
		GameManager.advance_phase()
	_process_phase()

func _on_turn_changed(_turn: int, _month: String) -> void:
	_process_phase()

func _on_phase_changed(_phase: GameManager.Phase) -> void:
	_process_phase()

func _on_auto_turn() -> void:
	for i in range(6):
		GameManager.advance_phase()
	_active_side = "union"
	_process_phase()

func _on_phonograph() -> void:
	_save_game()
	get_tree().change_scene_to_file("res://scenes/phonograph.tscn")

func _on_menu() -> void:
	_save_game()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _on_settings() -> void:
	_save_game()
	get_tree().change_scene_to_file("res://scenes/settings.tscn")

func _localize() -> void:
	_update_ui()

func _save_game() -> void:
	var data: Dictionary = GameManager.serialize()
	var file: FileAccess = FileAccess.open("user://save_game.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()

func _setup_bg_music() -> void:
	_bg_music = _PhonographPlayerScript.new()
	add_child(_bg_music)
	_bg_music.set_volume(0.5)
	_bg_music.set_side(_active_side)
	if GameManager._last_phonograph_track and not GameManager._last_phonograph_track.is_empty():
		_bg_music.play_track(GameManager._last_phonograph_track)
		GameManager._last_phonograph_track = {}
	else:
		_play_music_for_side(_active_side)

func _play_music_for_side(side: String) -> void:
	if _bg_music == null:
		return
	_bg_music.play_for_side(side)

func _on_side_switched(new_side: String) -> void:
	_play_music_for_side(new_side)

func _on_edit_map_toggle(enabled: bool) -> void:
	if _map_controller and _map_controller.has_method("set_edit_mode"):
		_map_controller.set_edit_mode(enabled)
	_edit_map_btn.text = "DONE" if enabled else "Edit Map"
	_save_map_btn.visible = enabled

func _on_save_map() -> void:
	if _map_controller and _map_controller.has_method("export_map_data"):
		_map_controller.export_map_data()

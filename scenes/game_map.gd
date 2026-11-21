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

var _zoom_level: float = 2.0
var _min_zoom: float = 2.0
var _max_zoom: float = 6.0
var _zoom_step: float = 0.2
var _is_panning: bool = false
var _pan_start: Vector2 = Vector2.ZERO
var _pan_offset: Vector2 = Vector2.ZERO
# Keyboard panning speed, screen px per second (hub request: arrows move
# the map view; mouse: hold RMB and drag, wheel zooms).
const KEY_PAN_SPEED: float = 900.0

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
var _advisor_panel: PanelContainer = null
var _advisor_phase: Label = null
var _advisor_tip: Label = null
var _advisor_hint: Label = null
var _ai: Node = null
var _ai_turn_pending: bool = false
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
	# Cards dock to the screen bottom edge: status bar (38px) + hand
	# label row below, full card height above - nothing cropped.
	hand_panel.offset_top = -415.0
	hand_panel.offset_right = -4.0
	hand_panel.offset_bottom = -64.0
	hand_panel.z_index = 12
	hand_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hand_panel.clip_contents = false
	_hand_container = HBoxContainer.new()
	_hand_container.name = "HandCards"
	_hand_container.add_theme_constant_override("separation", -160)
	_hand_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	_hand_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hand_panel.add_child(_hand_container)
	add_child(hand_panel)
	_build_advisor()

## Parchment corner card: what THIS phase means and what to press
## (owner request - the turn order must be readable from the screen).
func _build_advisor() -> void:
	_advisor_panel = PanelContainer.new()
	_advisor_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_advisor_panel.offset_left = 12.0
	_advisor_panel.offset_top = 50.0
	_advisor_panel.offset_right = 392.0
	_advisor_panel.z_index = 40
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.93, 0.87, 0.72, 0.92)
	style.border_color = Color(0.24, 0.17, 0.09)
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.content_margin_left = 10.0
	style.content_margin_right = 10.0
	style.content_margin_top = 6.0
	style.content_margin_bottom = 6.0
	_advisor_panel.add_theme_stylebox_override("panel", style)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	_advisor_panel.add_child(box)
	_advisor_phase = Label.new()
	_advisor_phase.add_theme_font_override("font", FontLoader.get_font("caption"))
	_advisor_phase.add_theme_font_size_override("font_size", 18)
	_advisor_phase.add_theme_color_override("font_color", Color(0.20, 0.14, 0.07))
	box.add_child(_advisor_phase)
	_advisor_tip = Label.new()
	_advisor_tip.add_theme_font_override("font", FontLoader.get_font("body"))
	_advisor_tip.add_theme_font_size_override("font_size", 14)
	_advisor_tip.add_theme_color_override("font_color", Color(0.25, 0.20, 0.12))
	_advisor_tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_advisor_tip.custom_minimum_size = Vector2(350, 0)
	box.add_child(_advisor_tip)
	_advisor_hint = Label.new()
	_advisor_hint.add_theme_font_size_override("font_size", 12)
	_advisor_hint.add_theme_color_override("font_color", Color(0.45, 0.38, 0.26))
	box.add_child(_advisor_hint)
	add_child(_advisor_panel)

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
	GameManager.game_over.connect(_on_game_over)
	_map_controller.territory_clicked.connect(_on_territory_clicked)
	_active_side = "union"
	_restore_hands_if_any()
	_process_phase()
	Localization.language_changed.connect(_localize)
	_localize()
	_setup_bg_music()
	AudioManager.attach_button_sounds(self)
	_debug_hand_fill()
	if OS.get_environment("CWG_DEBUG_HAND") != "":
		_dump_hand_geometry()
	Logger.info("GameMap", "Hotseat game ready. Turn=%d" % GameManager.get_current_turn())

func _dump_hand_geometry() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	var lines: Array = ["vp=%s" % str(get_viewport_rect().size)]
	if _hand_container:
		lines.append("container=%s" % str(_hand_container.get_global_rect()))
	if not _card_nodes.is_empty():
		var first: Control = _card_nodes[0]
		lines.append("card0=%s" % str(first.get_global_rect()))
		for child in first.get_child(0).get_children():
			if child is Label:
				lines.append("  lbl(%s)=%s visible=%s" % [child.text.left(10), str(child.get_global_rect()), child.is_visible_in_tree()])
	var f: FileAccess = FileAccess.open("user://hand_debug.txt", FileAccess.WRITE)
	if f:
		for line in lines:
			f.store_line(line)
		f.close()

## QA/vision helper: CWG_DEBUG_HAND=n fills the active hand with n random
## units so screenshots can show the hand cards deterministically.
func _debug_hand_fill() -> void:
	var want: String = OS.get_environment("CWG_DEBUG_HAND")
	if want == "":
		return
	var n: int = int(want)
	var pool: Array = CardDatabase.get_all_units_for_side(_active_side)
	if pool.is_empty():
		return
	for i in range(n):
		var card = load("res://scripts/cards/card_instance.gd").new(pool[i % pool.size()])
		_hands[_active_side].append(card)
	_refresh_hand()
	Logger.info("GameMap", "CWG_DEBUG_HAND filled %d cards" % n)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F9:
		# Preview toggle: old map <-> engraved v2 (branch map-v2).
		_save_game()
		get_tree().change_scene_to_file("res://scenes/map_v2.tscn")
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F1:
		_save_game()
		get_tree().change_scene_to_file("res://scenes/help.tscn")
		return
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

func _process(delta: float) -> void:
	var dir: Vector2 = Vector2.ZERO
	if Input.is_key_pressed(KEY_LEFT):
		dir.x -= 1.0
	if Input.is_key_pressed(KEY_RIGHT):
		dir.x += 1.0
	if Input.is_key_pressed(KEY_UP):
		dir.y -= 1.0
	if Input.is_key_pressed(KEY_DOWN):
		dir.y += 1.0
	if dir != Vector2.ZERO:
		# Arrows move the VIEW (arrow-right looks right); the offset is a
		# grab-style content translation (mouse drag moves the map itself),
		# so arrows subtract from it.
		_pan_offset -= dir.normalized() * KEY_PAN_SPEED * delta
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
	# The marker lives in GameManager so it survives scene round-trips.
	# It deduplicates double fires (signals + explicit calls) and stops
	# scene re-entry from re-running side effects (income, draws).
	var marker: String = "%d:%d" % [GameManager.get_current_turn(), GameManager.get_current_phase()]
	if marker == GameManager.phase_execution_marker:
		_update_ui()
		return
	GameManager.phase_execution_marker = marker
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
		# Snowball doctrine: card draw scales with territory count.
		# A player sitting on their starting lands gets ~2-3 cards; a
		# conquering side feeds its own expansion (6+ by mid-war).
		var owned: int = 0
		for t_id in GameManager._territory_owners:
			if GameManager._territory_owners[t_id] == side:
				owned += 1
		var count: int = 2 + int(owned / 5.0) + GameManager.get_morale_bonus_cards(side)
		var all_units: Array = CardDatabase.get_all_units_for_side(side)
		if all_units.is_empty():
			continue
		for i in range(count):
			var card_data: Dictionary = all_units[randi() % all_units.size()]
			var ci_script = load("res://scripts/cards/card_instance.gd")
			var card = ci_script.new(card_data)
			_hands[side].append(card)
		Logger.info("Phase", "Drew %d cards for %s (territories: %d, hand: %d)" % [count, side, owned, _hands[side].size()])
		AudioManager.play("card_draw")

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
		_battle_log += Localization.t("ui.info.battle_line") % [t_name, attackers.size(), defenders.size(), result["attacker_losses"], result["defender_losses"]]
		if result["territory_captured"]:
			var new_owner: String = attackers[0].side
			GameManager.set_territory_owner(t_id, new_owner)
			_battle_log += " " + Localization.t("ui.info.battle_captured") % new_owner
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
		# ResourceLoader understands imported resources - works in exported
		# builds too, unlike FileAccess on source files.
		if ResourceLoader.exists(p):
			return p
	return ""

func _refresh_hand() -> void:
	for w in _card_nodes:
		if is_instance_valid(w):
			w.queue_free()
	_card_nodes.clear()
	var hand: Array = _hands[_active_side]
	# Dynamic fan: no overlap at all while the row fits the screen width,
	# minimal overlap beyond that - so every card's stats stay readable.
	if not hand.is_empty() and _hand_container:
		var n: int = hand.size()
		var sep: float = 0.0
		if n > 1:
			sep = minf(0.0, (size.x - 16.0 - n * 225.0) / float(n - 1))
		_hand_container.add_theme_constant_override("separation", int(sep))
	for i in range(hand.size()):
		var card = hand[i]
		var side: String = card.side
		var bg: PanelContainer = PanelContainer.new()
		var bg_style: StyleBoxFlat = StyleBoxFlat.new()
		bg_style.bg_color = Color(0.93, 0.87, 0.72, 0.96)
		bg_style.set_border_width_all(1)
		bg_style.border_color = Color(0.24, 0.17, 0.09, 0.8)
		bg_style.set_corner_radius_all(4)
		if i == _selected_card_idx:
			bg_style.bg_color = Color(1.0, 0.9, 0.3, 0.35)
			bg_style.set_border_width_all(2)
			bg_style.border_color = Color(1.0, 0.85, 0.0)
		bg.add_theme_stylebox_override("panel", bg_style)
		bg.custom_minimum_size = Vector2(225, 345)
		var vbox: VBoxContainer = VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 2)
		var portrait: TextureRect = TextureRect.new()
		var img_path: String = _find_card_image(card.id, side, card.type)
		var tex: Texture2D = _load_image_texture(img_path)
		if tex:
			portrait.texture = tex
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		portrait.custom_minimum_size = Vector2(207, 172)
		portrait.size_flags_vertical = Control.SIZE_EXPAND_FILL
		vbox.add_child(portrait)
		var name_lbl: Label = Label.new()
		name_lbl.text = Localization.get_card_name(card.card_data)
		name_lbl.add_theme_font_size_override("font_size", 13)
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_WORD_ELLIPSIS
		name_lbl.max_lines_visible = 3
		name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		name_lbl.custom_minimum_size = Vector2(0, 56)
		name_lbl.add_theme_color_override("font_color", Color(0, 0, 0))
		vbox.add_child(name_lbl)
		var stats_lbl: Label = Label.new()
		stats_lbl.text = Localization.t("ui.card_stats") % [card.attack, card.defense, card.max_hp, card.cost]
		stats_lbl.add_theme_font_size_override("font_size", 14)
		stats_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		stats_lbl.add_theme_color_override("font_color", Color(0, 0, 0))
		vbox.add_child(stats_lbl)
		var type_lbl: Label = Label.new()
		type_lbl.text = card.type.to_upper() + " | " + card.rarity.to_upper()
		type_lbl.add_theme_font_size_override("font_size", 11)
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
	_detail_stats.text = Localization.t("ui.card_stats") % [atk, dfn, hp, cost]
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
		_morale_status.text = Localization.t(GameManager.get_morale_status(_active_side))
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
		if GameManager.get_current_turn() == 1:
			info = Localization.t("ui.info.resources_first")
		else:
			info = Localization.t("ui.info.resources_collected")
	elif phase == GameManager.Phase.EVENTS:
		info = Localization.t("ui.info.events_processed")
	elif phase == GameManager.Phase.END:
		info = Localization.t("ui.info.end_turn")
	if _info_label:
		_info_label.text = info
	_update_advisor(phase_idx)
	_apply_resource_tooltips()

func _update_advisor(phase_idx: int) -> void:
	if _advisor_panel == null:
		return
	var names := _get_phase_names()
	if phase_idx < 0 or phase_idx >= names.size():
		_advisor_panel.visible = false
		return
	_advisor_panel.visible = true
	_advisor_phase.text = names[phase_idx]
	var tip_key := ""
	match phase_idx:
		GameManager.Phase.RESOURCES: tip_key = "ui.tip.resources"
		GameManager.Phase.DRAW: tip_key = "ui.tip.draw"
		GameManager.Phase.MOVEMENT: tip_key = "ui.tip.movement"
		GameManager.Phase.COMBAT: tip_key = "ui.tip.combat"
		GameManager.Phase.EVENTS: tip_key = "ui.tip.events"
		GameManager.Phase.END: tip_key = "ui.tip.end"
	_advisor_tip.text = Localization.t(tip_key)
	_advisor_hint.text = Localization.t("ui.tip.help_hint")
	Logger.info("Advisor", "turn=%d phase_idx=%d marker='%s' owners=%d" % [
		GameManager.get_current_turn(), phase_idx, GameManager.phase_execution_marker, GameManager._territory_owners.size()])

func _apply_resource_tooltips() -> void:
	if _manpower_label:
		_manpower_label.tooltip_text = Localization.t("ui.res.manpower.tip")
		_money_label.tooltip_text = Localization.t("ui.res.money.tip")
		_supply_label.tooltip_text = Localization.t("ui.res.supply.tip")
		_morale_label.tooltip_text = Localization.t("ui.res.morale.tip")

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
			# Clickable unit row: opens the unit card (owner note - troops
			# on the map must be inspectable, not just listed as text).
			var ubtn := Button.new()
			var u_name2: String = Localization.get_card_name(u.card_data)
			ubtn.text = "  %s  HP:%d/%d  A:%d D:%d" % [u_name2.left(22), u.current_hp, u.max_hp, u.attack, u.defense]
			ubtn.alignment = HORIZONTAL_ALIGNMENT_LEFT
			ubtn.add_theme_font_size_override("font_size", 11)
			ubtn.modulate = Color(0.8, 0.9, 1.15) if u.side == "union" else Color(1.15, 0.85, 0.8)
			ubtn.pressed.connect(_show_card_detail.bind(u.card_data))
			_terr_units_list.add_child(ubtn)
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
	AudioManager.play("card_play")
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
	AudioManager.play("march")
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
		if _active_side == GameManager.get_ai_side():
			_ai_turn_pending = true
			_run_ai_side_turn()
	else:
		GameManager.advance_phase()
	# _process_phase() runs via the phase_changed/turn_changed signals;
	# calling it here as well is safe - the marker guard deduplicates.

func _on_game_over(winner: String, reason: String) -> void:
	Logger.info("GameMap", "Game over: winner=%s reason=%s" % [winner, reason])
	# Hotseat: a decisive outcome is a fanfare; a draw gets the somber cue.
	AudioManager.play("victory" if winner != "draw" else "defeat")
	MusicPlayer.play_slot("victory" if winner != "draw" else "defeat")
	_show_game_over_overlay(winner, reason)

func _show_game_over_overlay(winner: String, reason: String) -> void:
	var layer: CanvasLayer = CanvasLayer.new()
	layer.layer = 100
	add_child(layer)
	var dim: ColorRect = ColorRect.new()
	dim.color = Color(0, 0, 0, 0.85)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(dim)
	var box: VBoxContainer = VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	box.grow_vertical = Control.GROW_DIRECTION_BOTH
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	layer.add_child(box)
	var title: Label = Label.new()
	var winner_name: String = Localization.t("side." + ("union" if winner == "union" else "confederate"))
	title.text = Localization.t("game.over.title") + "\n" + Localization.t("game.over.winner") + " " + winner_name
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 42)
	box.add_child(title)
	var ok_btn: Button = Button.new()
	ok_btn.text = Localization.t("game.over.back_to_menu")
	ok_btn.pressed.connect(func() -> void:
		var save: FileAccess = FileAccess.open("user://save_game.json", FileAccess.WRITE)
		if save:
			save.store_string("")
			save.close()
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
	)
	box.add_child(ok_btn)
	AudioManager.attach_button_sounds(box)

func _on_turn_changed(_turn: int, _month: String) -> void:
	_process_phase()

func _on_phase_changed(_phase: GameManager.Phase) -> void:
	_process_phase()

func _on_auto_turn() -> void:
	# Fast-forward whole turns through the SAME flow as END PHASE clicks
	# - the exhausted reset, the side flip and the AI opponent hook all
	# live in _on_end_turn. (The old version advanced phases directly
	# and the AI never got to play - the "armies grow, nobody fights"
	# owner report.)
	for i in range(14):
		_on_end_turn()
		if _active_side == GameManager.get_player_side() \
				and GameManager.get_current_phase() == GameManager.Phase.RESOURCES:
			break
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
	# Hub law "one language per screen": every visible text node of the
	# scene gets its text here - scene-file placeholders never survive.
	_settings_btn.text = Localization.t("game.settings")
	_phonograph_btn.text = Localization.t("phonograph.title")
	_menu_btn.text = Localization.t("ui.menu")
	_edit_map_btn.text = Localization.t("ui.done") if _edit_map_btn.button_pressed else Localization.t("ui.edit_map")
	_save_map_btn.text = Localization.t("ui.save_map")
	_detail_close.text = Localization.t("ui.close")
	$TerritoryInfoPanel/TVBox/TClose.text = Localization.t("ui.close")

func _save_game() -> void:
	var data: Dictionary = GameManager.serialize()
	# Hands live in the scene - persist them through the save payload.
	# (Plain loops: GDScript has no comprehensions - the previous one-liner
	# never parsed and silently broke script loading in exported builds.)
	var hands: Dictionary = {"union": [], "confederate": []}
	for side in ["union", "confederate"]:
		for card in _hands[side]:
			hands[side].append(card.serialize())
	data["hands"] = hands
	var file: FileAccess = FileAccess.open("user://save_game.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()

func _restore_hands_if_any() -> void:
	var restored: Dictionary = GameManager.take_restored_hands()
	if restored.is_empty():
		return
	for side in ["union", "confederate"]:
		var rebuilt: Array = []
		for card_state in restored.get(side, []):
			var card_data: Dictionary = CardDatabase.get_unit(str(card_state.get("id", "")))
			if card_data.is_empty():
				continue
			var card = load("res://scripts/cards/card_instance.gd").new(card_data)
			card.deserialize(card_state)
			rebuilt.append(card)
		_hands[side] = rebuilt
	Logger.info("GameMap", "Restored hands from save: U=%d C=%d" % [_hands["union"].size(), _hands["confederate"].size()])

func _setup_bg_music() -> void:
	# MusicPlayer is an autoload: whatever the phonograph was playing
	# keeps playing across scenes - never restart a track on return.
	MusicPlayer.set_volume(0.5)
	if not MusicPlayer.is_playing():
		MusicPlayer.play_slot(MusicSlots.side_slot(_active_side))

func _play_music_for_side(side: String) -> void:
	MusicPlayer.play_slot(MusicSlots.side_slot(side))

## The AI side plays its whole month on its own (owner request: a real
## opponent that conquers while the player stalls). Cards are placed in
## the DRAW phase, armies move and invade in MOVEMENT, then the turn
## returns to the player.
func _run_ai_side_turn() -> void:
	if _ai == null:
		_ai = load("res://scripts/ai/ai_controller.gd").new()
		add_child(_ai)
	_ai.set_side(GameManager.get_ai_side())
	_ai.set_hands(_hands)
	_on_end_turn()          # RESOURCES -> DRAW (cards arrive for both)
	_ai.play_cards()        # AI recruits onto border territories
	_on_end_turn()          # -> MOVEMENT
	_ai.play_movement()     # AI advances and invades
	_on_end_turn()          # -> COMBAT (contested resolve)
	_on_end_turn()          # -> EVENTS
	_on_end_turn()          # -> END, side flips back to the player
	_ai_turn_pending = false
	Logger.info("GameMap", "AI turn complete: %s" % GameManager.get_ai_side())
	_check_stall()

## Per-turn state check (owner request): if the game stalls, log both
## sides' standings so the cause is diagnosable immediately.
var _stall_turns: int = 0
var _captures_last_turn: int = 0

func _check_stall() -> void:
	var turn: int = GameManager.get_current_turn()
	var counts: Dictionary = {"union": 0, "confederate": 0, "neutral": 0}
	var units: Dictionary = {"union": 0, "confederate": 0}
	for t_id in GameManager._territory_owners:
		var o: String = GameManager._territory_owners[t_id]
		counts[o] = counts.get(o, 0) + 1
	for t_id in GameManager._units_on_map:
		for u in GameManager._units_on_map[t_id]:
			if u.has_method("is_alive") and u.is_alive():
				units[u.side] = units.get(u.side, 0) + 1
	var total_captures: int = 0
	for t_id in GameManager._territory_owners:
		var td: Dictionary = CardDatabase.get_territory(t_id)
		var initial: String = str(td.get("initial_owner", "neutral"))
		var current: String = GameManager._territory_owners[t_id]
		if initial != "neutral" and current != initial:
			total_captures += 1
	var captures_this_turn: int = total_captures - _captures_last_turn
	_captures_last_turn = total_captures
	var armies_alive: bool = units["union"] >= 2 and units["confederate"] >= 2
	if captures_this_turn == 0 and armies_alive:
		_stall_turns += 1
	else:
		_stall_turns = 0
	var stall_note := ""
	if _stall_turns >= 3:
		stall_note = " *** STALL DETECTED (%d turns no captures) ***" % _stall_turns
	Logger.info("GameState", "TURN %d | U: ter %d units %d | C: ter %d units %d | hand U:%d C:%d | captures total %d (+%d)%s" % [
		turn, counts["union"], units["union"], counts["confederate"], units["confederate"],
		_hands["union"].size(), _hands["confederate"].size(),
		total_captures, captures_this_turn, stall_note])

func _on_side_switched(new_side: String) -> void:
	_play_music_for_side(new_side)

func _on_edit_map_toggle(enabled: bool) -> void:
	if _map_controller and _map_controller.has_method("set_edit_mode"):
		_map_controller.set_edit_mode(enabled)
	_edit_map_btn.text = Localization.t("ui.done") if enabled else Localization.t("ui.edit_map")
	_save_map_btn.visible = enabled

func _on_save_map() -> void:
	if _map_controller and _map_controller.has_method("export_map_data"):
		_map_controller.export_map_data()

extends Control
## Map v2 - procedurally drawn period-engraving map (owner-approved
## experiment, branch map-v2). Replaces the flat look with:
## - parchment wash + double ink borders with hand-drawn wobble
## - ownership fill: Union steel blue / Confederate crimson / neutral
##   hatched with a procedural stripe texture ("disputed land", never
##   reads as "unpainted")
## - hover highlight, click-to-select territory, clickable unit chips
## - zoom (wheel), pan (RMB drag + arrow keys move the view)
## Same territory_clicked API as map_controller so scenes can swap later.

signal territory_clicked(territory_id: String)
signal unit_marker_clicked(territory_id: String)

const DESIGN: Vector2i = Vector2i(1920, 1080)
const MAP_MARGIN: float = 24.0

const PARCHMENT: Color = Color(0.93, 0.87, 0.72)
const PARCHMENT_EDGE: Color = Color(0.82, 0.74, 0.55)
const INK: Color = Color(0.24, 0.17, 0.09)
const INK_SOFT: Color = Color(0.24, 0.17, 0.09, 0.45)
const UNION_FILL: Color = Color(0.23, 0.39, 0.62, 0.55)
const CONFED_FILL: Color = Color(0.70, 0.21, 0.15, 0.55)
const NEUTRAL_BASE: Color = Color(0.86, 0.79, 0.61, 0.60)
const RIVER_INK: Color = Color(0.20, 0.36, 0.48, 0.85)
const HIGHLIGHT: Color = Color(0.95, 0.82, 0.25, 0.95)
const SELECT_INK: Color = Color(0.10, 0.07, 0.03)

var _polys: Dictionary = {}
var _rivers: Dictionary = {}
var _meta: Dictionary = {}
var _wobbled: Dictionary = {}
var _centroids: Dictionary = {}
var _stripe_tex: ImageTexture = null

var _hovered: String = ""
var _selected: String = ""
var _unit_chip_rects: Array = []

var _zoom: float = 1.0
var _pan: Vector2 = Vector2.ZERO
var _panning: bool = false
var _pan_start: Vector2 = Vector2.ZERO

const KEY_PAN_SPEED: float = 900.0

func _ready() -> void:
	_load_data()
	_stripe_tex = _make_stripe_texture()
	custom_minimum_size = Vector2(DESIGN)
	mouse_filter = Control.MOUSE_FILTER_STOP

func _load_data() -> void:
	var path := "res://data/maps/map_data.json"
	if not FileAccess.file_exists(path):
		push_error("MapV2: map_data.json not found")
		return
	var f := FileAccess.open(path, FileAccess.READ)
	var json := JSON.new()
	var parsed := json.parse(f.get_as_text())
	f.close()
	if parsed != OK:
		push_error("MapV2: parse error")
		return
	var data: Dictionary = json.get_data()
	_polys = data.get("territories", {})
	_rivers = data.get("rivers", {})
	_meta = data.get("meta", {})
	for t_id in _polys:
		var pts := _to_points(_polys[t_id])
		_wobbled[t_id] = _wobble(pts, _seed(t_id))
		_centroids[t_id] = _centroid(pts)
	Logger.info("MapV2", "Loaded %d territories, %d rivers" % [_polys.size(), _rivers.size()])

## --- transforms ---------------------------------------------------------

func _to_points(raw: Array) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for p in raw:
		if p is Dictionary and p.has("x"):
			pts.append(Vector2(float(p["x"]), float(p["y"])))
		elif p is Array and p.size() >= 2:
			pts.append(Vector2(float(p[0]), float(p[1])))
		else:
			var s := str(p).trim_prefix("[").trim_suffix("]").replace(",", " ")
			var parts := s.split_floats(" ", false)
			if parts.size() >= 2:
				pts.append(Vector2(parts[0], parts[1]))
	return pts

func _map_to_screen() -> Transform2D:
	var src_w: float = _meta.get("width", 1200.0)
	var src_h: float = _meta.get("height", 850.0)
	var avail := size - Vector2(MAP_MARGIN * 2.0, MAP_MARGIN * 2.0)
	var s: float = minf(avail.x / src_w, avail.y / src_h) * _zoom
	var off := (size - Vector2(src_w, src_h) * s) * 0.5 + _pan
	# Explicit axes: the 4-arg Transform2D ctor is (rotation, scale, skew,
	# position) - passing the scale factor there silently collapses every
	# point to the origin offset.
	return Transform2D(Vector2(s, 0.0), Vector2(0.0, s), off)

func _wobble(pts: PackedVector2Array, seed: int) -> PackedVector2Array:
	# Deterministic hand-drawn jitter, smoothed so borders stay readable.
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var out := PackedVector2Array()
	for i in pts.size():
		var prev: Vector2 = pts[(i + pts.size() - 1) % pts.size()]
		var nx: Vector2 = pts[(i + 1) % pts.size()]
		var target := (prev + pts[i] * 2.0 + nx) * 0.25
		var jitter := Vector2(rng.randf_range(-2.2, 2.2), rng.randf_range(-2.2, 2.2))
		out.append(pts[i] + (target - pts[i]) * 0.35 + jitter)
	return out

func _seed(s: String) -> int:
	var h := 2166136261
	for c in s:
		h = (h ^ c.unicode_at(0)) * 16777619
		h = h & 0x7FFFFFFF
	return h

func _centroid(pts: PackedVector2Array) -> Vector2:
	var sum := Vector2.ZERO
	for p in pts:
		sum += p
	return sum / maxf(1.0, float(pts.size()))

func _make_stripe_texture() -> ImageTexture:
	# 12x12 tileable diagonal stripe - the "disputed land" hatch.
	var img := Image.create(12, 12, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var ink := Color(0.28, 0.22, 0.10, 0.75)
	for i in 12:
		for o in 2:
			img.set_pixel((i + o) % 12, i, ink)
			img.set_pixel((i + 6 + o) % 12, i, ink)
	return ImageTexture.create_from_image(img)

## --- drawing ------------------------------------------------------------

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), PARCHMENT)
	_draw_parchment_texture()
	_draw_frame()
	var t := _map_to_screen()
	for t_id in _polys:
		_draw_territory(t_id, t)
	for r_id in _rivers:
		_draw_river(r_id, t)
	_draw_cartouche(t)
	_draw_unit_chips(t)

var _dirty: bool = true

func _mark_dirty() -> void:
	_dirty = true

func _process(delta: float) -> void:
	var dir := Vector2.ZERO
	if Input.is_key_pressed(KEY_LEFT):
		dir.x -= 1.0
	if Input.is_key_pressed(KEY_RIGHT):
		dir.x += 1.0
	if Input.is_key_pressed(KEY_UP):
		dir.y -= 1.0
	if Input.is_key_pressed(KEY_DOWN):
		dir.y += 1.0
	if dir != Vector2.ZERO:
		_pan -= dir.normalized() * KEY_PAN_SPEED * delta
		_dirty = true
	var m := get_local_mouse_position()
	var hit := _territory_at(m)
	if hit != _hovered:
		_hovered = hit
		_dirty = true
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if hit != "" else Control.CURSOR_ARROW
	if _dirty:
		_dirty = false
		queue_redraw()

func _draw_parchment_texture() -> void:
	# Faint fibre flecks, deterministic.
	var rng := RandomNumberGenerator.new()
	rng.seed = 18610412
	for i in 900:
		var p := Vector2(rng.randf() * size.x, rng.randf() * size.y)
		draw_line(p, p + Vector2(2.0, 1.0), PARCHMENT_EDGE if i % 3 == 0 else INK_SOFT, 0.6)

func _draw_frame() -> void:
	var m := 10.0
	draw_rect(Rect2(m, m, size.x - m * 2.0, size.y - m * 2.0), INK, false, 3.0)
	draw_rect(Rect2(m + 7.0, m + 7.0, size.x - (m + 7.0) * 2.0, size.y - (m + 7.0) * 2.0), INK_SOFT, false, 1.0)

func _draw_territory(t_id: String, t: Transform2D) -> void:
	var pts: PackedVector2Array = _wobbled[t_id]
	var scr := PackedVector2Array()
	for p in pts:
		scr.append(t * p)
	if scr.size() < 3:
		return
	var owner: String = GameManager.get_territory_owner(t_id)
	var td: Dictionary = CardDatabase.get_territory(t_id)
	var uv := PackedVector2Array()
	for p in pts:
		uv.append(p / 24.0)
	match owner:
		"union":
			draw_polygon(scr, [UNION_FILL])
		"confederate":
			draw_polygon(scr, [CONFED_FILL])
		_:
			draw_polygon(scr, [NEUTRAL_BASE])
			draw_polygon(scr, [Color(1, 1, 1, 1)], uv, _stripe_tex)
			# Belt-and-braces: visible diagonal strokes over the hatch.
			var rect := Rect2(scr[0], Vector2.ZERO)
			for p in scr:
				rect = rect.expand(p)
			var d: float = rect.position.x + rect.position.y
			while d < rect.end.x + rect.end.y:
				var seg := PackedVector2Array()
				for k in scr.size():
					var a: Vector2 = scr[k]
					var b: Vector2 = scr[(k + 1) % scr.size()]
					var hit: Variant = _seg_cross_diag(a, b, d)
					if hit != null:
						seg.append(hit)
				if seg.size() >= 2:
					draw_polyline(seg, Color(0.30, 0.24, 0.12, 0.55), 1.6, false)
				d += 26.0
	# ink border with an engraved double stroke
	draw_polyline(scr, INK_SOFT, 4.5, true)
	draw_polyline(scr, INK, 1.8, true)
	if t_id == _hovered and t_id != _selected:
		draw_polyline(scr, HIGHLIGHT, 3.5, true)
	if t_id == _selected:
		draw_polyline(scr, SELECT_INK, 5.0, true)
		draw_polyline(scr, HIGHLIGHT, 2.0, true)
	_draw_label(t_id, t)

func _draw_label(t_id: String, t: Transform2D) -> void:
	var td: Dictionary = CardDatabase.get_territory(t_id)
	var name_loc: String = Localization.t("territory." + t_id) if Localization.has_key("territory." + t_id) else str(td.get("name_en", t_id))
	var c: Vector2 = t * _centroids[t_id]
	var fs: int = 13 if _zoom < 2.2 else 15
	if t.get_scale().x < 1.1:
		fs = int(fs * 0.85)
	var font := FontLoader.get_font("caption")
	var cap: String = " ★" if td.get("is_capital", false) else ""
	draw_string(font, c + Vector2(-40, -6), name_loc + cap, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, INK)

func _draw_river(r_id: String, t: Transform2D) -> void:
	var pts := _to_points(_rivers[r_id])
	if pts.is_empty():
		return
	var scr := PackedVector2Array()
	for p in pts:
		scr.append(t * p)
	draw_polyline(scr, RIVER_INK, 2.2, true)
	var echo_pts := PackedVector2Array()
	for p in scr:
		echo_pts.append(p + Vector2(1.5, 1.5))
	draw_polyline(echo_pts, Color(RIVER_INK, 0.35), 1.0, true)

func _draw_cartouche(t: Transform2D) -> void:
	var origin := Vector2(34.0, 30.0)
	var box := Rect2(origin, Vector2(330.0, 64.0))
	draw_rect(box, PARCHMENT)
	draw_rect(box, INK, false, 2.0)
	draw_string(FontLoader.get_font("title"), origin + Vector2(14, 30), Localization.t("map.cartouche"), HORIZONTAL_ALIGNMENT_LEFT, -1, 24, INK)
	draw_string(FontLoader.get_font("body"), origin + Vector2(14, 52), Localization.t("map.cartouche.sub"), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, INK_SOFT)

func _draw_unit_chips(t: Transform2D) -> void:
	_unit_chip_rects.clear()
	for t_id in GameManager._units_on_map:
		var units: Array = GameManager._units_on_map[t_id]
		var alive: int = 0
		var side: String = "union"
		for u in units:
			if u.has_method("is_alive") and u.is_alive():
				alive += 1
				side = u.side
		if alive <= 0 or not _centroids.has(t_id):
			continue
		var c: Vector2 = t * (_centroids[t_id] + Vector2(0, -14))
		var r: float = 13.0
		var col: Color = UNION_FILL if side == "union" else CONFED_FILL
		col.a = 0.95
		draw_circle(c, r + 2.0, PARCHMENT)
		draw_circle(c, r, col)
		draw_arc(c, r, 0, TAU, 24, INK, 1.5, true)
		draw_string(FontLoader.get_font("caption"), c + Vector2(-6, 5), str(alive), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1, 1, 0.95))
		_unit_chip_rects.append({"t_id": t_id, "rect": Rect2(c - Vector2(r + 3, r + 3), Vector2(r * 2 + 6, r * 2 + 6))})

## --- input ----------------------------------------------------------------

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F9:
		# Preview toggle back to the classic map (branch map-v2).
		get_tree().change_scene_to_file("res://scenes/game_map.tscn")

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			_zoom = clampf(_zoom * 1.15, 1.0, 6.0)
			accept_event()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			_zoom = clampf(_zoom / 1.15, 1.0, 6.0)
			accept_event()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_panning = event.pressed
			_pan_start = event.position - _pan
			accept_event()
		elif event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_handle_click(event.position)
			accept_event()
	elif event is InputEventMouseMotion and _panning:
		_pan = event.position - _pan_start
		accept_event()

## Intersection of segment (a,b) with the line x + y = d, or null.
func _seg_cross_diag(a: Vector2, b: Vector2, d: float) -> Variant:
	var fa: float = a.x + a.y - d
	var fb: float = b.x + b.y - d
	if (fa > 0.0 and fb > 0.0) or (fa < 0.0 and fb < 0.0):
		return null
	var denom: float = fa - fb
	if absf(denom) < 0.0001:
		return null
	var t: float = fa / denom
	return a + (b - a) * t

func _handle_click(pos: Vector2) -> void:
	for chip in _unit_chip_rects:
		if chip["rect"].has_point(pos):
			unit_marker_clicked.emit(chip["t_id"])
			_selected = chip["t_id"]
			territory_clicked.emit(chip["t_id"])
			return
	var hit := _territory_at(pos)
	if hit != "":
		_selected = hit
		territory_clicked.emit(hit)

func _territory_at(pos: Vector2) -> String:
	var t := _map_to_screen()
	for t_id in _polys:
		var scr := PackedVector2Array()
		for p in _wobbled[t_id]:
			scr.append(t * p)
		if Geometry2D.is_point_in_polygon(pos, scr):
			return t_id
	return ""

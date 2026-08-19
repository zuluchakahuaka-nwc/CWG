class_name MapController
extends Control

var _territories: Dictionary = {}
var _unit_markers: Dictionary = {}
var _selected_territory: String = ""
var _highlighted_territories: Array = []
var _polygons: Dictionary = {}
var _rivers_data: Dictionary = {}
var _mountains_data: Dictionary = {}
var _forests_data: Array = []
var _map_meta: Dictionary = {}
var _built: bool = false
var _bg_tex: Texture2D = null
var _overlay_tex: Texture2D = null

var _view_zoom: float = 1.0
var _view_pan: Vector2 = Vector2.ZERO
var _b_scale: float = 1.0
var _b_offset: Vector2 = Vector2.ZERO
var _s: float = 1.0

var _edit_mode: bool = false
var _edit_territory: String = ""
var _edit_drag_idx: int = -1

signal territory_clicked(territory_id: String)
signal territory_hovered(territory_id: String)

const COLOR_UNION: Color = Color(0.20, 0.38, 0.72, 0.82)
const COLOR_CONFEDERATE: Color = Color(0.68, 0.18, 0.15, 0.82)
const COLOR_NEUTRAL: Color = Color(0.48, 0.48, 0.42, 0.72)
const COLOR_HIGHLIGHT: Color = Color(1.0, 0.95, 0.3, 0.80)
const PARCHMENT: Color = Color(0.88, 0.83, 0.72, 1.0)
const OCEAN: Color = Color(0.14, 0.25, 0.42, 1.0)
const RIVER_COL: Color = Color(0.22, 0.40, 0.65, 0.75)
const BORDER_COL: Color = Color(0.40, 0.35, 0.25, 0.85)
const MTN_COL: Color = Color(0.55, 0.48, 0.38, 0.60)
const MTN_SNOW: Color = Color(0.90, 0.90, 0.95, 0.50)
const FOREST_COL: Color = Color(0.18, 0.40, 0.15, 0.55)
const FOREST_COL2: Color = Color(0.22, 0.48, 0.18, 0.60)

const TERRAIN_TINT: Dictionary = {
	"plains": Color(0.55, 0.62, 0.32, 0.25),
	"forest": Color(0.18, 0.42, 0.15, 0.35),
	"hills": Color(0.52, 0.46, 0.30, 0.30),
	"mountains": Color(0.48, 0.42, 0.34, 0.35),
	"swamp": Color(0.28, 0.46, 0.28, 0.30),
	"city": Color(0.58, 0.52, 0.42, 0.25),
	"river": Color(0.28, 0.48, 0.65, 0.25),
}

func _ready() -> void:
	_load_map_data()
	_load_background()
	call_deferred("_build_map")

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and _built:
		queue_redraw()

func _load_map_data() -> void:
	var path: String = "res://data/maps/map_data.json"
	if not FileAccess.file_exists(path):
		push_error("MapController: map_data.json not found")
		return
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return
	var json: JSON = JSON.new()
	if json.parse(file.get_as_text()) != OK:
		push_error("MapController: parse error in map_data.json")
		file.close()
		return
	file.close()
	var data: Dictionary = json.get_data()
	_polygons = data.get("territories", {})
	_rivers_data = data.get("rivers", {})
	_mountains_data = data.get("mountains", {})
	_map_meta = data.get("meta", {})
	_forests_data = data.get("forests", [])

func _load_background() -> void:
	var base_path: String = "res://assets/sprites/map/map_base.png"
	var tex_path: String = "res://assets/sprites/map/map_texture.png"
	if ResourceLoader.exists(base_path):
		_bg_tex = ResourceLoader.load(base_path)
	if ResourceLoader.exists(tex_path):
		_overlay_tex = ResourceLoader.load(tex_path)
	if _bg_tex:
		Logger.info("MapController", "Base map texture loaded")
	if _overlay_tex:
		Logger.info("MapController", "Overlay texture loaded")

func _get_area() -> Vector2:
	var parent: Node = get_parent()
	if parent and parent is Control:
		return (parent as Control).get_rect().size
	return get_viewport().get_visible_rect().size

func _calc_transforms() -> void:
	var area: Vector2 = _get_area()
	var src_w: float = _map_meta.get("width", 1200.0)
	var src_h: float = _map_meta.get("height", 850.0)
	_b_scale = minf(area.x / src_w, area.y / src_h)
	_s = _b_scale * _view_zoom
	var draw_w: float = src_w * _s
	var draw_h: float = src_h * _s
	_b_offset = Vector2((area.x - draw_w) * 0.5 + _view_pan.x, (area.y - draw_h) * 0.5 + _view_pan.y)

func _xp(p: Array) -> Vector2:
	var ox: float = _b_offset.x + _view_pan.x
	var oy: float = _b_offset.y + _view_pan.y
	return Vector2(ox + p[0] * _s, oy + p[1] * _s)

func _xp_arr(arr: Array) -> PackedVector2Array:
	var pts: PackedVector2Array = PackedVector2Array()
	var n: int = arr.size()
	if n < 3:
		return pts
	var first: Array = arr[0]
	var last: Array = arr[n - 1]
	var closed: bool = (absf(first[0] - last[0]) < 0.01 and absf(first[1] - last[1]) < 0.01)
	var count: int = n - 1 if closed else n
	for i in range(count):
		pts.append(_xp(arr[i]))
	return pts

func _center_of(key: String) -> Vector2:
	var poly: Array = _polygons.get(key, [])
	if poly.is_empty():
		return Vector2.ZERO
	var cx: float = 0.0
	var cy: float = 0.0
	for p in poly:
		cx += p[0]
		cy += p[1]
	return _xp([cx / poly.size(), cy / poly.size()])

func _build_map() -> void:
	var area: Vector2 = _get_area()
	if area.x < 50 or area.y < 50:
		await get_tree().process_frame
		area = _get_area()
	for t_id in CardDatabase._territories:
		var t_data: Dictionary = CardDatabase.get_territory(t_id)
		_territories[t_id] = {"data": t_data, "terrain": t_data.get("terrain", "plains")}
	var decorative: Array = [
		"new_york", "new_jersey", "connecticut",
		"ohio", "indiana", "illinois", "michigan", "wisconsin",
		"minnesota", "minnesota_south", "iowa", "kansas", "nebraska",
		"district_columbia",
	]
	for d_id in decorative:
		if not _polygons.has(d_id):
			continue
		if _territories.has(d_id):
			continue
		_territories[d_id] = {
			"data": {"name_en": d_id.replace("_", " ").capitalize(), "terrain": "plains"},
			"terrain": "plains",
			"decorative": true,
		}
	_built = true
	queue_redraw()
	Logger.info("MapController", "Built %d territories from geographic data" % _territories.size())

func set_edit_mode(enabled: bool) -> void:
	_edit_mode = enabled
	if not enabled:
		_edit_territory = ""
		_edit_drag_idx = -1
	queue_redraw()

func _draw() -> void:
	if not _built:
		return
	_calc_transforms()
	var area: Vector2 = _get_area()
	var src_w: float = _map_meta.get("width", 1200.0)
	var src_h: float = _map_meta.get("height", 850.0)
	var dst_rect: Rect2 = Rect2(_b_offset + _view_pan, Vector2(src_w * _s, src_h * _s))

	draw_rect(Rect2(Vector2.ZERO, area), PARCHMENT)

	if _bg_tex:
		draw_texture_rect(_bg_tex, dst_rect, false, Color(1.0, 1.0, 1.0, 0.85))

	if _overlay_tex:
		draw_texture_rect(_overlay_tex, dst_rect, false, Color(1.0, 1.0, 1.0, 0.30))

	_draw_fills()
	_draw_rivers()
	_draw_mountains()
	_draw_forests()
	_draw_borders()
	_draw_labels()
	_draw_badges()
	_draw_compass()
	if _edit_mode:
		_draw_edit_handles()

func _draw_ocean() -> void:
	for tid in ["atlantic_coast", "gulf_coast"]:
		var poly: Array = _polygons.get(tid, [])
		if poly.size() < 3:
			continue
		var pts: PackedVector2Array = _xp_arr(poly)
		if pts.size() < 3:
			continue
		_ear_clip_fill(pts, Color(0.14, 0.24, 0.42, 0.6))

func _draw_fills() -> void:
	var skip: Array = ["mississippi_river"]
	for t_id in _territories:
		if t_id in skip:
			continue
		var poly: Array = _polygons.get(t_id, [])
		if poly.size() < 3:
			continue
		var pts: PackedVector2Array = _xp_arr(poly)
		if pts.size() < 3:
			continue
		var info: Dictionary = _territories[t_id]
		var owner: String = GameManager.get_territory_owner(t_id)
		var base: Color = _owner_color(owner)
		var t_data: Dictionary = info.get("data", {})
		var is_cap: bool = t_data.get("is_capital", false)
		var is_hi: bool = t_id in _highlighted_territories
		var col: Color
		if is_cap:
			col = Color(base.r, base.g, base.b, 0.65)
		elif info.get("decorative", false):
			col = Color(0.5, 0.48, 0.42, 0.15)
		else:
			col = Color(base.r, base.g, base.b, 0.45)
		if is_hi:
			col = COLOR_HIGHLIGHT
		if Geometry2D.is_polygon_clockwise(pts):
			pts.reverse()
		var tri: Array = Geometry2D.triangulate_polygon(pts)
		if not tri.is_empty():
			draw_colored_polygon(pts, col)
		else:
			draw_polyline(pts, Color(col.r, col.g, col.b, minf(col.a * 2.0, 1.0)), 2.0 * _s, true)

func _ear_clip_fill(pts: PackedVector2Array, col: Color) -> void:
	if pts.size() < 3:
		return
	draw_polyline(pts, col, maxf(_s * 3, 2), true)
	var center: Vector2 = Vector2.ZERO
	for p in pts:
		center += p
	center /= pts.size()
	for i in range(pts.size()):
		var a: Vector2 = pts[i]
		var b: Vector2 = pts[(i + 1) % pts.size()]
		draw_colored_polygon(PackedVector2Array([a, b, center]), col)

func _draw_rivers() -> void:
	for r_name in _rivers_data:
		var pts_raw: Array = _rivers_data[r_name]
		if pts_raw.size() < 2:
			continue
		var pts: PackedVector2Array = _xp_arr(pts_raw)
		var w: float = 3.0 * _s
		if r_name == "mississippi":
			w = 5.0 * _s
		elif r_name == "ohio":
			w = 4.0 * _s
		elif r_name == "potomac":
			w = 3.0 * _s
		draw_polyline(pts, RIVER_COL, w, true)

func _draw_mountains() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 42
	for m_name in _mountains_data:
		var pts_raw: Array = _mountains_data[m_name]
		if pts_raw.size() < 2:
			continue
		var base_pts: PackedVector2Array = _xp_arr(pts_raw)
		for i in range(base_pts.size() - 1):
			var a: Vector2 = base_pts[i]
			var b: Vector2 = base_pts[i + 1]
			var dir: Vector2 = (b - a).normalized()
			var perp: Vector2 = Vector2(-dir.y, dir.x)
			var seg_len: float = a.distance_to(b)
			var count: int = maxi(int(seg_len / (6.0 * _s)), 2)
			for j in range(count):
				var t: float = (float(j) + 0.5) / float(count)
				var bp: Vector2 = a.lerp(b, t)
				var h: float = (4.0 + rng.randf() * 5.0) * _s
				var peak: Vector2 = bp + perp * h
				var hw: float = (2.5 + rng.randf() * 2.0) * _s
				var left: Vector2 = bp - dir * hw
				var right: Vector2 = bp + dir * hw
				var tri: PackedVector2Array = PackedVector2Array([left, peak, right])
				var shade: float = 0.40 + rng.randf() * 0.15
				draw_colored_polygon(tri, Color(shade + 0.12, shade + 0.08, shade - 0.02, 0.55))
				if h > 6.0 * _s:
					var sp: Vector2 = peak
					var sl: Vector2 = peak - perp * h * 0.35 - dir * hw * 0.3
					var sr: Vector2 = peak - perp * h * 0.35 + dir * hw * 0.3
					draw_colored_polygon(PackedVector2Array([sl, sp, sr]), MTN_SNOW)

func _draw_forests() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	for f in _forests_data:
		var cx: float = f.get("cx", 0.0)
		var cy: float = f.get("cy", 0.0)
		if f.has("lat") and f.has("lon"):
			var SX_L: float = _map_meta.get("width", 1200.0) / 40.0
			var SY_L: float = _map_meta.get("height", 850.0) / 24.0
			cx = (f["lon"] + 107.0) * SX_L
			cy = (48.0 - f["lat"]) * SY_L
		if cx == 0.0 and cy == 0.0:
			continue
		var center: Vector2 = _xp([cx, cy])
		var r: float = f.get("r", 1.0) * 30.0 * _s
		var n: int = f.get("n", 8)
		rng.seed = hash(int(cx * 100 + cy * 7))
		for i in range(n):
			var angle: float = rng.randf() * TAU
			var dist: float = rng.randf() * r
			var fp: Vector2 = center + Vector2(cos(angle), sin(angle)) * dist
			var fr: float = (2.0 + rng.randf() * 3.0) * _s
			draw_circle(fp, fr, FOREST_COL)
			draw_circle(fp - Vector2(0, fr * 0.25), fr * 0.7, FOREST_COL2)

func _draw_borders() -> void:
	var skip: Array = ["mississippi_river"]
	for t_id in _territories:
		if t_id in skip:
			continue
		var poly: Array = _polygons.get(t_id, [])
		if poly.size() < 3:
			continue
		var pts: PackedVector2Array = _xp_arr(poly)
		if pts.size() < 3:
			continue
		var owner: String = GameManager.get_territory_owner(t_id)
		var is_hi: bool = t_id in _highlighted_territories
		var is_cap: bool = false
		if _territories[t_id].has("data"):
			is_cap = _territories[t_id]["data"].get("is_capital", false)
		var bc: Color
		if is_hi:
			bc = Color(1.0, 0.9, 0.0)
		elif is_cap:
			bc = Color(0.0, 0.0, 0.0, 0.9)
		else:
			bc = _owner_border_color(owner)
		var bw: float = 3.0 * _s if is_cap else 1.5 * _s
		draw_polyline(pts, bc, bw, true)

func _draw_labels() -> void:
	var placed: Array = []
	var font: Font = ThemeDB.fallback_font
	for t_id in _territories:
		var poly: Array = _polygons.get(t_id, [])
		if poly.size() < 3:
			continue
		var info: Dictionary = _territories[t_id]
		var t_data: Dictionary = info["data"]
		var is_deco: bool = info.get("decorative", false)
		var name: String = _localized_name(t_data, t_id)
		var fs: int = maxi(7, int(9 * _s))
		if is_deco:
			fs = maxi(5, int(7 * _s))
		var is_cap: bool = t_data.get("is_capital", false)
		var is_port: bool = t_data.get("is_port", false)
		var is_rr: bool = t_data.get("is_railroad", false)
		var is_city: bool = is_port or is_rr or is_cap

		var center: Vector2 = _center_of(t_id)
		var label_pos: Vector2 = center

		if is_city:
			var offset_y: float = -fs * 1.5
			label_pos = center + Vector2(0, offset_y)

		for p in placed:
			if label_pos.distance_to(p) < fs * 1.8:
				label_pos = p + Vector2(0, fs * 1.2)
				break
		placed.append(label_pos)

		if is_cap:
			draw_string(font, label_pos - Vector2(0, fs + 2), "★", HORIZONTAL_ALIGNMENT_CENTER, -1, fs + 4, Color(1.0, 0.85, 0.0, 0.9))

		var owner: String = GameManager.get_territory_owner(t_id)
		var outline_col: Color = _owner_border_color(owner)
		var ow: float = maxf(1.0, _s * 0.8)
		var offsets: Array = [Vector2(-ow, 0), Vector2(ow, 0), Vector2(0, -ow), Vector2(0, ow)]
		for off in offsets:
			draw_string(font, label_pos + off, name, HORIZONTAL_ALIGNMENT_CENTER, -1, fs, outline_col)
		draw_string(font, label_pos, name, HORIZONTAL_ALIGNMENT_CENTER, -1, fs, Color(0.12, 0.08, 0.04, 0.95))

		var icons: String = ""
		if is_port:
			icons += "⚓"
		if is_rr:
			icons += "═"
		if icons != "":
			draw_string(font, label_pos + Vector2(0, fs + 2), icons, HORIZONTAL_ALIGNMENT_CENTER, -1, fs - 1, Color(0.3, 0.5, 0.7, 0.6))

func _draw_badges() -> void:
	for t_id in GameManager._units_on_map:
		var units: Array = GameManager._units_on_map[t_id]
		if units.is_empty():
			continue
		var poly: Array = _polygons.get(t_id, [])
		if poly.size() < 3:
			continue
		var center: Vector2 = _center_of(t_id)
		var counts: Dictionary = {}
		for unit in units:
			if unit.has_method("get_effective_attack"):
				counts[unit.side] = counts.get(unit.side, 0) + 1
		var badge_y: float = 12.0 * _s
		for side in counts:
			var count: int = counts[side]
			var txt: String = str(count) + " ⚔"
			var c: Color = Color(0.3, 0.55, 1.0) if side == "union" else Color(1.0, 0.35, 0.35)
			var bw: float = (8.0 + txt.length() * 5.5) * _s
			var bh: float = 11.0 * _s
			var bp: Vector2 = center + Vector2(-bw * 0.5, badge_y)
			draw_rect(Rect2(bp, Vector2(bw, bh)), Color(0, 0, 0, 0.75), true)
			draw_rect(Rect2(bp, Vector2(bw, bh)), c, false, 1.0)
			draw_string(ThemeDB.fallback_font, bp + Vector2(2 * _s, bh * 0.8), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, maxi(7, int(8 * _s)), c)
			badge_y += bh + 1.0

func _draw_compass() -> void:
	var area: Vector2 = _get_area()
	var cx: float = area.x - 50
	var cy: float = 50
	var r: float = 20
	draw_circle(Vector2(cx, cy), r + 2, Color(0.15, 0.12, 0.08, 0.3))
	draw_line(Vector2(cx, cy - r), Vector2(cx, cy + r), Color(0.3, 0.25, 0.18, 0.6), 1.5)
	draw_line(Vector2(cx - r, cy), Vector2(cx + r, cy), Color(0.3, 0.25, 0.18, 0.6), 1.5)
	draw_string(ThemeDB.fallback_font, Vector2(cx - 3, cy - r - 4), "N", HORIZONTAL_ALIGNMENT_CENTER, -1, 10, Color(0.3, 0.25, 0.18, 0.7))

func _localized_name(t_data: Dictionary, t_id: String) -> String:
	var loc_key: String = "territory." + t_id
	if Localization and Localization.has_key(loc_key):
		return Localization.t(loc_key)
	var field: String = "name_" + Localization.get_language() if Localization else "name_en"
	if t_data.has(field):
		return t_data[field]
	return t_data.get("name_en", t_id)

func _owner_color(owner: String) -> Color:
	match owner:
		"union": return COLOR_UNION
		"confederate": return COLOR_CONFEDERATE
		"neutral": return COLOR_NEUTRAL
		_: return Color(0.4, 0.4, 0.4, 0.7)

func _owner_border_color(owner: String) -> Color:
	match owner:
		"union": return Color(0.35, 0.55, 0.90, 0.8)
		"confederate": return Color(0.90, 0.30, 0.25, 0.8)
		"neutral": return BORDER_COL
		_: return BORDER_COL

func _point_in_polygon(pt: Vector2, poly_pts: PackedVector2Array) -> bool:
	var n: int = poly_pts.size()
	if n < 3:
		return false
	var inside: bool = false
	var j: int = n - 1
	for i in range(n):
		var vi: Vector2 = poly_pts[i]
		var vj: Vector2 = poly_pts[j]
		if ((vi.y > pt.y) != (vj.y > pt.y)) and (pt.x < (vj.x - vi.x) * (pt.y - vi.y) / (vj.y - vi.y) + vi.x):
			inside = not inside
		j = i
	return inside

func _draw_edit_handles() -> void:
	var t_id: String = _edit_territory
	if t_id == "":
		for tid in _territories:
			var poly: Array = _polygons.get(tid, [])
			if poly.size() < 3:
				continue
			var c: Vector2 = _center_of(tid)
			draw_circle(c, 4.0, Color(1, 1, 1, 0.4))
		return
	var poly: Array = _polygons.get(t_id, [])
	if poly.size() < 2:
		return
	var pts: PackedVector2Array = _xp_arr(poly)
	for i in range(pts.size()):
		var p: Vector2 = pts[i]
		var col: Color = Color(1.0, 0.3, 0.3) if i == _edit_drag_idx else Color(1.0, 1.0, 0.0)
		draw_circle(p, 6.0, col)
		draw_circle(p, 4.0, Color(0, 0, 0))
		draw_circle(p, 3.0, col)
		draw_string(ThemeDB.fallback_font, p + Vector2(6, -4), str(i), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1, 1, 0.7))

func _gui_input(event: InputEvent) -> void:
	if _edit_mode:
		_handle_edit_input(event)
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var best_id: String = ""
		var best_d: float = 1e9
		for t_id in _territories:
			var poly: Array = _polygons.get(t_id, [])
			if poly.size() < 3:
				continue
			var pts: PackedVector2Array = _xp_arr(poly)
			if _point_in_polygon(event.position, pts):
				var c: Vector2 = _center_of(t_id)
				var d: float = event.position.distance_squared_to(c)
				if d < best_d:
					best_d = d
					best_id = t_id
		if best_id != "":
			_selected_territory = best_id
			territory_clicked.emit(best_id)
	elif event is InputEventMouseMotion:
		for t_id in _territories:
			var poly: Array = _polygons.get(t_id, [])
			if poly.size() < 3:
				continue
			var pts: PackedVector2Array = _xp_arr(poly)
			if _point_in_polygon(event.position, pts):
				territory_hovered.emit(t_id)
				return

func _handle_edit_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if _edit_territory != "":
				var poly: Array = _polygons.get(_edit_territory, [])
				var pts: PackedVector2Array = _xp_arr(poly)
				var best_i: int = -1
				var best_d: float = 100.0
				for i in range(pts.size()):
					var d: float = event.position.distance_to(pts[i])
					if d < best_d:
						best_d = d
						best_i = i
				if best_i >= 0:
					_edit_drag_idx = best_i
				else:
					_edit_territory = ""
					_edit_drag_idx = -1
					queue_redraw()
			else:
				for t_id in _territories:
					var poly: Array = _polygons.get(t_id, [])
					if poly.size() < 3:
						continue
					var pts: PackedVector2Array = _xp_arr(poly)
					if _point_in_polygon(event.position, pts):
						_edit_territory = t_id
						_edit_drag_idx = -1
						queue_redraw()
						return
		else:
			if _edit_drag_idx >= 0:
				_save_polygon_to_disk()
			_edit_drag_idx = -1
			queue_redraw()
	elif event is InputEventMouseMotion and _edit_drag_idx >= 0:
		var inv_s: float = 1.0 / _s
		var ox: float = _b_offset.x + _view_pan.x
		var oy: float = _b_offset.y + _view_pan.y
		var wx: float = (event.position.x - ox) / _s
		var wy: float = (event.position.y - oy) / _s
		var poly: Array = _polygons.get(_edit_territory, [])
		if _edit_drag_idx < poly.size():
			poly[_edit_drag_idx] = [wx, wy]
			queue_redraw()

func _save_polygon_to_disk() -> void:
	if _edit_territory == "":
		return
	var path: String = "res://data/maps/map_data.json"
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return
	var json: JSON = JSON.new()
	json.parse(file.get_as_text())
	file.close()
	var data: Dictionary = json.get_data()
	if not data.has("territories"):
		return
	data["territories"][_edit_territory] = _polygons[_edit_territory]
	var wfile: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if wfile:
		wfile.store_string(JSON.stringify(data, "\t"))
		wfile.close()
		Logger.info("MapController", "Saved polygon for %s" % _edit_territory)

func export_map_data() -> void:
	var src_path: String = "res://data/maps/map_data.json"
	var file: FileAccess = FileAccess.open(src_path, FileAccess.READ)
	if file == null:
		Logger.error("MapController", "Cannot read map_data.json")
		return
	var content: String = file.get_as_text()
	file.close()
	var dst_path: String = "user://map_data_export.json"
	var wfile: FileAccess = FileAccess.open(dst_path, FileAccess.WRITE)
	if wfile:
		wfile.store_string(content)
		wfile.close()
		Logger.info("MapController", "Map exported to %s" % dst_path)
		Logger.info("MapController", "Windows path: %s" % ProjectSettings.globalize_path(dst_path))

func set_view_transform(zoom: float, pan: Vector2) -> void:
	_view_zoom = zoom
	_view_pan = pan
	queue_redraw()

func update_territory_display() -> void:
	queue_redraw()

func update_unit_markers() -> void:
	queue_redraw()

func highlight_territories(territory_ids: Array) -> void:
	clear_highlights()
	_highlighted_territories = territory_ids.duplicate()
	queue_redraw()

func clear_highlights() -> void:
	_highlighted_territories.clear()
	queue_redraw()

func get_selected_territory() -> String:
	return _selected_territory

func get_territory_at_point(screen_pos: Vector2) -> String:
	var local_pos: Vector2 = screen_pos - get_global_position()
	for t_id in _territories:
		var poly: Array = _polygons.get(t_id, [])
		if poly.size() < 3:
			continue
		var pts: PackedVector2Array = _xp_arr(poly)
		if _point_in_polygon(local_pos, pts):
			return t_id
	return ""

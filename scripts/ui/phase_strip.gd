class_name PhaseStrip
extends PanelContainer
## Bright phase strip under the TopBar (owner feedback 21.11: "I don't
## see the phases - how do I draw, how do I recruit"). Six segments:
## the CURRENT phase is highlighted amber, past phases are dimmed with a
## check mark, future phases are ink outlines. Big localized names.

signal phase_clicked(phase_idx: int)

const PHASE_KEYS: PackedStringArray = [
	"phase.resources", "phase.draw", "phase.movement",
	"phase.combat", "phase.events", "phase.end"
]

const PARCHMENT: Color = Color(0.93, 0.87, 0.72, 0.96)
const PARCHMENT_DIM: Color = Color(0.82, 0.76, 0.62, 0.92)
const AMBER: Color = Color(0.98, 0.78, 0.22, 1.0)
const INK: Color = Color(0.24, 0.17, 0.09)
const INK_DIM: Color = Color(0.45, 0.38, 0.28, 0.75)

var _segments: Array = []

func _init() -> void:
	custom_minimum_size = Vector2(0, 52)
	var strip_style := StyleBoxFlat.new()
	strip_style.bg_color = Color(0, 0, 0, 0.0)
	_build()
	GameManager.phase_changed.connect(_on_phase_changed)

func _build() -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	add_child(row)
	for i in range(PHASE_KEYS.size()):
		var idx: int = i
		var seg := Button.new()
		seg.custom_minimum_size = Vector2(150, 44)
		seg.clip_text = false
		seg.add_theme_font_size_override("font_size", 17)
		seg.add_theme_font_override("font", null)
		seg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		seg.pressed.connect(func() -> void: phase_clicked.emit(idx))
		row.add_child(seg)
		_segments.append(seg)
	_localize()
	_refresh(GameManager.get_current_phase())

func _localize() -> void:
	for i in range(_segments.size()):
		var btn: Button = _segments[i]
		btn.text = Localization.t(PHASE_KEYS[i])
	_update_language_hook()

func _update_language_hook() -> void:
	if not Localization.language_changed.is_connected(_on_language_changed):
		Localization.language_changed.connect(_on_language_changed)

func _on_language_changed() -> void:
	_localize()
	_refresh(GameManager.get_current_phase())

func _on_phase_changed(phase: int) -> void:
	_refresh(phase)

func _refresh(current: int) -> void:
	for i in range(_segments.size()):
		var btn: Button = _segments[i]
		var style := StyleBoxFlat.new()
		style.set_corner_radius_all(4)
		style.content_margin_left = 10.0
		style.content_margin_right = 10.0
		if i < current:
			# Past: dimmed parchment, thin ink border, check mark.
			style.bg_color = PARCHMENT_DIM
			style.border_color = INK_DIM
			style.set_border_width_all(1)
			btn.add_theme_color_override("font_color", INK_DIM)
			btn.add_theme_color_override("font_pressed_color", INK_DIM)
			btn.add_theme_color_override("font_hover_color", INK_DIM)
			btn.text = "✓ " + Localization.t(PHASE_KEYS[i])
		elif i == current:
			# Current: bright amber, thick ink border, big bold text.
			style.bg_color = AMBER
			style.border_color = INK
			style.set_border_width_all(3)
			style.content_margin_left = 14.0
			style.content_margin_right = 14.0
			btn.add_theme_color_override("font_color", INK)
			btn.add_theme_color_override("font_pressed_color", INK)
			btn.add_theme_color_override("font_hover_color", INK)
			btn.text = "▶ " + Localization.t(PHASE_KEYS[i])
		else:
			# Future: ink outline on translucent parchment.
			style.bg_color = Color(0.93, 0.87, 0.72, 0.35)
			style.border_color = INK
			style.set_border_width_all(2)
			btn.add_theme_color_override("font_color", INK)
			btn.add_theme_color_override("font_pressed_color", INK)
			btn.add_theme_color_override("font_hover_color", INK)
			btn.text = Localization.t(PHASE_KEYS[i])
		btn.add_theme_stylebox_override("normal", style)
		btn.add_theme_stylebox_override("hover", style)
		btn.add_theme_stylebox_override("pressed", style)
		btn.add_theme_stylebox_override("disabled", style)
		btn.add_theme_stylebox_override("focus", style)

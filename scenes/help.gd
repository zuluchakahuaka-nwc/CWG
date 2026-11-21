extends Control
## In-game help (owner request: the turn order and where troops come from
## must be explained IN the game, not guessed). Built fully in code so
## the one-language law suite has no scene placeholders to cover.

var _back_target: String = "res://scenes/main_menu.tscn"

func _ready() -> void:
	# If a game is in progress, back returns to the map (save exists).
	if FileAccess.file_exists("user://save_game.json"):
		var f := FileAccess.open("user://save_game.json", FileAccess.READ)
		if f:
			var text := f.get_as_text()
			f.close()
			if text.strip_edges() != "":
				_back_target = "res://scenes/game_map.tscn"
	_build()
	AudioManager.attach_button_sounds(self)

func _build() -> void:
	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 80.0
	root.offset_right = -80.0
	root.offset_top = 50.0
	root.offset_bottom = -50.0
	root.add_theme_constant_override("separation", 18)
	add_child(root)

	var title := Label.new()
	title.text = Localization.t("help.title")
	title.add_theme_font_override("font", FontLoader.get_font("title"))
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", Color(0.87, 0.74, 0.46))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(title)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 14)
	scroll.add_child(box)

	_add_section(box, "help.flow")
	_add_section(box, "help.units")
	_add_section(box, "help.controls")

	var back := Button.new()
	back.text = Localization.t("ui.close")
	back.pressed.connect(func() -> void:
		get_tree().change_scene_to_file(_back_target)
	)
	root.add_child(back)

func _add_section(parent: VBoxContainer, key: String) -> void:
	var head := Label.new()
	head.text = Localization.t(key + ".title")
	head.add_theme_font_override("font", FontLoader.get_font("caption"))
	head.add_theme_font_size_override("font_size", 26)
	head.add_theme_color_override("font_color", Color(0.20, 0.14, 0.07))
	parent.add_child(head)
	var body := Label.new()
	body.text = Localization.t(key + ".body")
	body.add_theme_font_override("font", FontLoader.get_font("body"))
	body.add_theme_font_size_override("font_size", 19)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(body)

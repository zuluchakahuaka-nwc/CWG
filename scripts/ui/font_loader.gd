extends Node

var font_title: FontFile
var font_body: FontFile
var font_caption: FontFile
var font_display: FontFile

func _ready() -> void:
	font_title = _load_font("Cinzel-Bold.ttf")
	font_body = _load_font("CrimsonText-Regular.ttf")
	font_caption = _load_font("CrimsonText-Bold.ttf")
	font_display = _load_font("PlayfairDisplay-Regular.ttf")

func _load_font(filename: String) -> FontFile:
	var path: String = "res://assets/fonts/" + filename
	if ResourceLoader.exists(path):
		var f: FontFile = load(path)
		if f:
			return f
	return null

func get_font(purpose: String) -> FontFile:
	match purpose:
		"title": return font_title if font_title else ThemeDB.fallback_font
		"body": return font_body if font_body else ThemeDB.fallback_font
		"caption": return font_caption if font_caption else ThemeDB.fallback_font
		"display": return font_display if font_display else ThemeDB.fallback_font
		_: return ThemeDB.fallback_font

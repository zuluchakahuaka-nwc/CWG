extends Node

var font_title: FontFile
var font_body: FontFile
var font_caption: FontFile
var font_display: FontFile

## Unicode safety net (hub law: font coverage per language with fallbacks).
## The vintage faces cover Latin+Cyrillic only; CJK, Arabic, Devanagari and
## Hangul glyphs render through these Noto (SIL OFL) fallbacks instead of
## tofu squares. Order matters per-script: SC han first (biggest locale),
## then JP kana, then KR Hangul.
const FALLBACK_FONTS: PackedStringArray = [
	"NotoSansSC.ttf",
	"NotoSansJP.ttf",
	"NotoSansKR.ttf",
	"NotoSansArabic.ttf",
	"NotoSansDevanagari.ttf",
	"NotoSansBase.ttf",
]

var _fallbacks: Array[Font] = []

func _ready() -> void:
	for fname in FALLBACK_FONTS:
		var f: FontFile = _load_font(fname)
		if f:
			_fallbacks.append(f)
	font_title = _load_font("Cinzel-Bold.ttf")
	font_body = _load_font("CrimsonText-Regular.ttf")
	font_caption = _load_font("CrimsonText-Bold.ttf")
	font_display = _load_font("PlayfairDisplay-Regular.ttf")
	for f in [font_title, font_body, font_caption, font_display]:
		if f:
			f.fallbacks = _fallbacks
	_install_default_theme()

func _load_font(filename: String) -> FontFile:
	var path: String = "res://assets/fonts/" + filename
	if ResourceLoader.exists(path):
		var f: FontFile = load(path)
		if f:
			return f
	return null

## Nodes without an explicit font override draw with the theme default
## font. Give them the sans Noto base (visually close to the engine's own
## default) wired to the same fallback chain, so default-styled text stops
## rendering tofu for zh/ja/ko/ar/hi as well.
func _install_default_theme() -> void:
	var base: FontFile = _load_font("NotoSansBase.ttf")
	if base == null:
		Logger.warn("FontLoader", "No NotoSansBase - default theme left as-is")
		return
	base.fallbacks = _fallbacks
	var theme := Theme.new()
	theme.default_font = base
	theme.default_font_size = 16
	get_tree().root.theme = theme

func get_font(purpose: String) -> FontFile:
	match purpose:
		"title": return font_title if font_title else ThemeDB.fallback_font
		"body": return font_body if font_body else ThemeDB.fallback_font
		"caption": return font_caption if font_caption else ThemeDB.fallback_font
		"display": return font_display if font_display else ThemeDB.fallback_font
		_: return ThemeDB.fallback_font

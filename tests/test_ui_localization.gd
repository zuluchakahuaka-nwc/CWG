extends Node
## Suite: one-language-per-screen law (hub AGENTS.md).
## 1) Scene files must not carry placeholder texts that survive runtime:
##    every text node is either empty, or runtime-localized (whitelisted
##    with a justification), otherwise FAIL.
## 2) Scripts must not assign literal strings to .text (Localization.t
##    wrappers are fine); whitelisted exceptions documented below.

var _pass_count: int = 0
var _fail_count: int = 0
var _test_results: Array = []

## Node paths whose .tscn placeholders are provably overwritten by
## _localize/_update_ui/_show_* before the first visible frame.
const SCENE_WHITELIST: Dictionary = {
	"res://scenes/game_map.tscn": [
		"TopBar/HBox/TurnInfo", "TopBar/HBox/PhaseLabel", "TopBar/HBox/SideLabel",
		"TopBar/HBox/EditMapButton", "TopBar/HBox/SaveMapButton",
		"TopBar/HBox/SettingsButton", "TopBar/HBox/PhonographButton",
		"TopBar/HBox/MenuButton", "StatusBar/ManpowerLabel", "StatusBar/MoneyLabel",
		"StatusBar/SupplyLabel", "StatusBar/MoraleLabel", "StatusBar/MoraleStatus",
		"StatusBar/EndTurnButton", "StatusBar/AutoTurnButton",
		"CardDetailPopup/DetailVBox/DetailName", "CardDetailPopup/DetailVBox/DetailStats",
		"CardDetailPopup/DetailVBox/DetailClose", "TerritoryInfoPanel/TVBox/TName",
		"TerritoryInfoPanel/TVBox/TOwner", "TerritoryInfoPanel/TVBox/TTerrain",
		"TerritoryInfoPanel/TVBox/TUnitsLabel", "TerritoryInfoPanel/TVBox/TClose",
	],
	"res://scenes/main_menu.tscn": [
		"VBoxContainer/TitleLabel", "VBoxContainer/SubtitleLabel",
		"VBoxContainer/NewGameButton", "VBoxContainer/ContinueButton",
		"VBoxContainer/SettingsButton", "VBoxContainer/LanguageButton",
		"VBoxContainer/QuitButton", "VersionLabel",
	],
	"res://scenes/phonograph.tscn": [
		"Panel/VBox/TitleLabel", "Panel/VBox/ModeLabel", "Panel/VBox/NowPlayingLabel",
		"Panel/VBox/Controls/PrevBtn", "Panel/VBox/Controls/PlayBtn",
		"Panel/VBox/Controls/StopBtn", "Panel/VBox/Controls/NextBtn",
		"Panel/VBox/Controls/ShuffleBtn", "Panel/VBox/Controls/RepeatBtn",
		"Panel/VBox/VolumeLabel", "Panel/VBox/CloseButton",
		"Panel/VBox/SideTabs/UnionBtn", "Panel/VBox/SideTabs/ConfedBtn",
	],
	"res://scenes/scenario_select.tscn": [
		"TitleLabel", "SideLabel", "SideHBox/UnionButton", "SideHBox/ConfederateButton",
		"BackButton", "ScrollContainer/VBoxContainer/Scenario1861",
		"ScrollContainer/VBoxContainer/Scenario1862",
		"ScrollContainer/VBoxContainer/Scenario1863",
		"ScrollContainer/VBoxContainer/Scenario1864",
		"ScrollContainer/VBoxContainer/Scenario1865",
		"ScrollContainer/VBoxContainer/ScenarioFull",
	],
	"res://scenes/settings.tscn": [
		"MarginContainer/VBox/TitleLabel", "MarginContainer/VBox/LangSection/LangLabel",
		"MarginContainer/VBox/AudioSection/AudioLabel",
		"MarginContainer/VBox/AudioSection/VolumeRow/VolumeLabel",
		"MarginContainer/VBox/MusicSection/MusicLabel",
		"MarginContainer/VBox/MusicSection/UnionMusicRow/UnionMusicLabel",
		"MarginContainer/VBox/MusicSection/ConfedMusicRow/ConfedMusicLabel",
		"MarginContainer/VBox/DisplaySection/FullscreenCheck",
		"MarginContainer/VBox/ButtonRow/BackButton",
	],
	# Dead skeleton scene (audit P2 rewrite queue) - not reachable in game.
	"res://scenes/battle_screen.tscn": ["*"],
}

## Literal snippets allowed in script .text assignments.
## - battle_screen "Resolve": dead skeleton scene (P2).
## - "HAND: 0 cards": initializer, overwritten by _update_ui same frame.
## - "HP:%d/%d  A:%d D:%d": universal stat abbreviations (same convention
##   as ui.card_stats which keeps ATK/DEF/HP in every locale).
const SCRIPT_WHITELIST: Dictionary = {
	"res://scenes/battle_screen.gd": ["Resolve"],
	"res://scenes/game_map.gd": ["HAND: 0 cards", "HP:%d/%d"],
}

const LAW_KEYS: PackedStringArray = [
	"game.settings", "phonograph.title", "ui.menu", "ui.edit_map",
	"ui.save_map", "ui.done", "ui.close", "ui.card_stats",
	"ui.info.battle_line", "ui.info.battle_captured", "scenario.select.title",
	"scenario.1861", "scenario.1862", "scenario.1863", "scenario.1864",
	"scenario.1865", "scenario.full",
	"morale.sacred_fervor", "morale.uplift", "morale.normal", "morale.neutral",
	"morale.gloom", "morale.unrest", "morale.rebellion", "morale.revolution",
	"game.over.title", "game.title", "splash.skip",
	"ui.info.resources_first", "game.help", "help.title",
	"help.flow.title", "help.flow.body", "help.units.title",
	"help.units.body", "help.controls.title", "help.controls.body",
	"ui.tip.resources", "ui.tip.draw", "ui.tip.movement", "ui.tip.combat",
	"ui.tip.events", "ui.tip.end", "ui.tip.help_hint",
	"ui.res.manpower.tip", "ui.res.money.tip", "ui.res.supply.tip",
	"ui.res.morale.tip",
]

func _ready() -> void:
	print("\n=== TEST: OneLanguagePerScreen law ===")
	test_csv_hygiene()
	test_scene_texts_covered()
	test_script_text_literals_covered()
	test_law_keys_exist_in_ru_and_en()
	test_all_code_keys_resolve()
	test_every_key_has_ru_and_en()
	test_every_key_has_all_locales()
	test_font_coverage_all_locales()
	test_card_names_fit_card_width()
	test_all_scene_scripts_compile()
	_print_summary()

## Hub law: the game ships 14 locales. A language that only exists in the
## header but has holes silently degrades to English mid-screen (mix bug).
const REQUIRED_LOCALES: PackedStringArray = [
	"ru", "en", "fr", "es", "de", "pt", "zh", "ja", "hi", "ar",
	"it", "pl", "tr", "ko",
]

## Per-script probe strings: chars our vintage fonts do NOT carry, so the
## test proves the Noto fallback chain actually loads and covers them.
const SCRIPT_PROBES: Dictionary = {
	"pl": "ąćęłńóśźż", "tr": "ğışçöüİŞĞ",
	"zh": "汉字测试", "ja": "いろはにほへと", "ko": "한국어핵",
	"ar": "العربية", "hi": "हिन्दी",
}

## A script that fails to parse kills its scene silently (no handlers,
## no drawing - the "gray F9 screen" incident was exactly this). Guard:
## EVERY game .gd under scenes/ and scripts/ must compile.
func test_all_scene_scripts_compile() -> void:
	var config := ConfigFile.new()
	var autoload_paths: Array = []
	if config.load("res://project.godot") == OK and config.has_section("autoload"):
		for key in config.get_section_keys("autoload"):
			var p: String = config.get_value("autoload", key)
			autoload_paths.append(p.trim_prefix("*"))
	var broken: Array = []
	for path in _collect_gd_files("res://scenes") + _collect_gd_files("res://scripts"):
		if path in autoload_paths:
			continue
		var script: GDScript = load(path)
		if script == null:
			broken.append(path + " (unloadable)")
			continue
		if script.reload() != OK:
			broken.append(path)
	_assert(broken.is_empty(), "every game script compiles %s" % str(broken).left(300))

## CSV hygiene: the player must never see raw keys, so the dictionary
## itself must be sane - 11 fields per row, unique keys, ru+en filled.
func test_csv_hygiene() -> void:
	var path := "res://data/localization/translations.csv"
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		_assert(false, "translations.csv readable")
		return
	var malformed: Array = []
	var seen: Dictionary = {}
	var dupes: Array = []
	var header: PackedStringArray = f.get_csv_line()
	var expected_fields: int = header.size()
	var count: int = 0
	while not f.eof_reached():
		var line: PackedStringArray = f.get_csv_line()
		if line.size() == 1 and line[0].strip_edges() == "":
			continue
		count += 1
		if line.size() != expected_fields:
			malformed.append("row %d (%s) has %d fields" % [count, line[0], line.size()])
		var key := line[0].strip_edges()
		if key != "":
			if seen.has(key):
				dupes.append(key)
			seen[key] = true
	f.close()
	_assert(expected_fields == REQUIRED_LOCALES.size() + 1,
		"CSV has %d columns (key + %d locales), got %d" % [REQUIRED_LOCALES.size() + 1, REQUIRED_LOCALES.size(), expected_fields])
	_assert(malformed.is_empty(), "every CSV row has the same field count %s" % str(malformed).left(200))
	_assert(dupes.is_empty(), "no duplicate keys (dupes overwrite translations) %s" % str(dupes).left(200))
	for i in range(1, header.size()):
		_assert(REQUIRED_LOCALES.has(header[i].strip_edges()),
			"CSV column %d is a known locale (got '%s')" % [i, header[i]])

func test_every_key_has_all_locales() -> void:
	for lang in REQUIRED_LOCALES:
		var dict: Dictionary = Localization._translations.get(lang, {})
		var missing: Array = []
		for key in Localization._translations.get("ru", {}).keys():
			if not dict.has(key) or str(dict[key]).strip_edges() == "":
				missing.append(key)
				if missing.size() >= 5:
					break
		_assert(missing.is_empty(),
			"locale '%s' has no holes (%s...)" % [lang, str(missing).left(150)])

func test_font_coverage_all_locales() -> void:
	var purposes: PackedStringArray = ["title", "body", "caption", "display"]
	var broken: Array = []
	for lang in REQUIRED_LOCALES:
		var sample: String = Localization.get_language_native_name(lang) + SCRIPT_PROBES.get(lang, "Aa")
		for purpose in purposes:
			var font: Font = FontLoader.get_font(purpose)
			if font == null:
				broken.append("%s/%s: no font" % [lang, purpose])
				continue
			for ch in sample:
				if not _font_stack_has(font, ch):
					broken.append("%s/%s: no glyph U+%04X '%s'" % [lang, purpose, ch.unicode_at(0), ch])
					break
	_assert(broken.is_empty(), "every locale renders on every font stack %s" % str(broken).left(300))

## Every localized card name must FIT its card after the shrink-to-fit +
## ellipsis pass (card_widget). Long German/Polish names are the driver.
func test_card_names_fit_card_width() -> void:
	var widget: Control = load("res://scripts/ui/card_widget.gd").new()
	var font: Font = FontLoader.get_font("display")
	var card_w: float = 225.0 - 8.0
	var broken: Array = []
	var cards: Array = []
	cards += CardDatabase.get_all_units_for_side("union")
	cards += CardDatabase.get_all_units_for_side("confederate")
	for card in cards:
		for lang in REQUIRED_LOCALES:
			var name: String = str(card.get("name_" + lang, ""))
			var size: int = 31
			while size > 7 and font.get_string_size(name, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > card_w:
				size -= 1
			var fitted: String = name
			if font.get_string_size(fitted, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > card_w:
				fitted = widget._ellipsize_to_width(fitted, font, size, card_w)
			if font.get_string_size(fitted, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > card_w * 1.05:
				broken.append("%s:%s" % [card.get("id", "?"), lang])
	_assert(broken.is_empty(),
		"every localized name fits the card after shrink+ellipsis %s" % str(broken).left(200))
	widget.free()

func _font_stack_has(font: Font, ch: String) -> bool:
	if font.has_char(ch.unicode_at(0)):
		return true
	for fb in font.fallbacks:
		if fb is Font and fb.has_char(ch.unicode_at(0)):
			return true
	return false

func test_every_key_has_ru_and_en() -> void:
	var empty_ru: Array = []
	var empty_en: Array = []
	for key in Localization._translations.get("ru", {}).keys():
		if str(Localization._translations["ru"][key]).strip_edges() == "":
			empty_ru.append(key)
	for key in Localization._translations.get("en", {}).keys():
		if str(Localization._translations["en"][key]).strip_edges() == "":
			empty_en.append(key)
	_assert(empty_ru.is_empty(), "no key with empty ru value %s" % str(empty_ru).left(200))
	_assert(empty_en.is_empty(), "no key with empty en value %s" % str(empty_en).left(200))

func _assert(condition: bool, test_name: String) -> void:
	if condition:
		_pass_count += 1
		_test_results.append("  PASS: " + test_name)
	else:
		_fail_count += 1
		_test_results.append("  FAIL: " + test_name)

func test_scene_texts_covered() -> void:
	var node_re := RegEx.new()
	node_re.compile("^\\[node name=\"([^\"]+)\"(?:[^\\]]*parent=\"([^\"]+)\")?")
	var text_re := RegEx.new()
	text_re.compile("^text = \"(.*)\"$")
	var violations: Array = []
	for scene_path in SCENE_WHITELIST.keys():
		if not FileAccess.file_exists(scene_path):
			_assert(false, "whitelisted scene exists: %s" % scene_path)
			continue
		var allowed: Array = SCENE_WHITELIST[scene_path]
		if allowed.has("*"):
			continue
		var f := FileAccess.open(scene_path, FileAccess.READ)
		var current := ""
		while not f.eof_reached():
			var line := f.get_line()
			var nm := node_re.search(line)
			if nm:
				var parent := nm.get_string(2)
				current = parent + "/" + nm.get_string(1) if parent != "" and parent != "." else nm.get_string(1)
				continue
			var tm := text_re.search(line)
			if tm and tm.get_string(1) != "" and _has_letters(tm.get_string(1)):
				if not allowed.has(current):
					violations.append("%s :: %s :: %s" % [scene_path, current, tm.get_string(1)])
		f.close()
	_assert(violations.is_empty(), "every scene text node is empty or runtime-covered %s" % str(violations).left(300))

func test_script_text_literals_covered() -> void:
	var assign_re := RegEx.new()
	assign_re.compile("\\.text\\s*=\\s*\"([^\"]*)\"")
	var violations: Array = []
	for path in _collect_gd_files("res://scenes") + _collect_gd_files("res://scripts"):
		var allowed: Array = SCRIPT_WHITELIST.get(path, [])
		var f := FileAccess.open(path, FileAccess.READ)
		if f == null:
			continue
		while not f.eof_reached():
			var line := f.get_line()
			if line.contains("Localization.t("):
				continue
			var m := assign_re.search(line)
			if m and _has_letters(m.get_string(1)):
				var snippet := m.get_string(1)
				var ok := false
				for wl in allowed:
					if snippet.contains(wl) or wl.contains(snippet):
						ok = true
						break
				if not ok:
					violations.append("%s :: %s" % [path, snippet])
		f.close()
	_assert(violations.is_empty(), "no literal .text assignments outside whitelist %s" % str(violations).left(300))

func test_law_keys_exist_in_ru_and_en() -> void:
	var saved := Localization.get_language()
	Localization.set_language("ru")
	for key in LAW_KEYS:
		var ru_val: String = Localization.t(key)
		_assert(ru_val != key, "key '%s' resolves in ru" % key)
	Localization.set_language("en")
	for key in LAW_KEYS:
		var en_val: String = Localization.t(key)
		_assert(en_val != key, "key '%s' resolves in en" % key)
	Localization.set_language(saved)

func test_all_code_keys_resolve() -> void:
	# A raw key leaking into the UI (e.g. "month.april") is a language-mix
	# bug: every Localization.t("<literal>") used in code must exist in the
	# CSV. Dynamic keys (concatenation) are checked by their base presence
	# in LAW_KEYS-style tests or caught by the E2E vision pass.
	var key_re := RegEx.new()
	key_re.compile("Localization\\.t\\(\"([^\"]+)\"\\)")
	var missing: Array = []
	var saved := Localization.get_language()
	Localization.set_language("en")
	for path in _collect_gd_files("res://scenes") + _collect_gd_files("res://scripts"):
		var f := FileAccess.open(path, FileAccess.READ)
		if f == null:
			continue
		var source := f.get_as_text()
		f.close()
		for m in key_re.search_all(source):
			var key := m.get_string(1)
			if not Localization.has_key(key):
				missing.append("%s :: %s" % [path, key])
	Localization.set_language(saved)
	_assert(missing.is_empty(), "every literal key used in code resolves %s" % str(missing).left(300))

func _has_letters(s: String) -> bool:
	# printf-style specifiers (%d %s %0.2f) are format, not language
	var spec := RegEx.new()
	spec.compile("%[-+ #0-9.]*[a-zA-Z]")
	var stripped := spec.sub(s, "", true)
	for c in stripped.to_lower():
		if (c >= "a" and c <= "z") or (c >= "а" and c <= "я") or c == "ё":
			return true
	return false

func _collect_gd_files(dir_path: String) -> Array:
	var out: Array = []
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return out
	dir.list_dir_begin()
	var name := dir.get_next()
	while name != "":
		if dir.current_is_dir() and not name.begins_with("."):
			out += _collect_gd_files(dir_path + "/" + name)
		elif name.ends_with(".gd"):
			out.append(dir_path + "/" + name)
		name = dir.get_next()
	dir.list_dir_end()
	return out

func _print_summary() -> void:
	for r in _test_results:
		print(r)
	var total: int = _pass_count + _fail_count
	print("\n  TOTAL: %d/%d passed, %d failed" % [_pass_count, total, _fail_count])
	if _fail_count == 0:
		print("  ALL TESTS PASSED!")
	else:
		print("  SOME TESTS FAILED!")
	print("===========================\n")

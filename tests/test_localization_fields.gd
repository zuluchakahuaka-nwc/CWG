extends Node
## Card-field localization getters for the detail popup (25.11).
##
## Contract: get_card_description / get_card_flavor / get_card_effect /
## get_card_rank are STRICT - they return the current-language field or
## "" and never fall back to English: the popup hides empty sections
## instead of mixing languages on screen (hub one-language law).

var _pass_count: int = 0
var _fail_count: int = 0
var _test_results: Array = []

const PROBE_LOCALES: PackedStringArray = ["en", "ru", "fr"]
const UNIT_ID: String = "u_inf_20me"
const COMMANDER_ID: String = "cmd_lincoln"
const SITUATION_ID: String = "SIT_ARTY_BARRAGE"

func _ready() -> void:
	print("\n=== TEST: LocalizationFields ===")
	test_strict_getters_match_current_language()
	_print_summary()

func _assert(condition: bool, test_name: String) -> void:
	if condition:
		_pass_count += 1
		_test_results.append("  PASS: " + test_name)
	else:
		_fail_count += 1
		_test_results.append("  FAIL: " + test_name)

func test_strict_getters_match_current_language() -> void:
	var saved_lang: String = Localization.get_language()
	var problems: Array = []
	for lang in PROBE_LOCALES:
		Localization.set_language(lang)
		var unit: Dictionary = CardDatabase.get_card(UNIT_ID)
		var commander: Dictionary = CardDatabase.get_card(COMMANDER_ID)
		var situation: Dictionary = CardDatabase.get_card(SITUATION_ID)
		var checks: Array = [
			[
				"desc/%s" % lang,
				Localization.get_card_description(unit),
				str(unit.get("description_" + lang, "")),
			],
			[
				"flavor/%s" % lang,
				Localization.get_card_flavor(unit),
				str(unit.get("flavor_" + lang, "")),
			],
			[
				"effect-cmd/%s" % lang,
				Localization.get_card_effect(commander),
				str(commander.get("effect_" + lang, "")),
			],
			[
				"rank/%s" % lang,
				Localization.get_card_rank(commander),
				str(commander.get("rank_" + lang, "")),
			],
			[
				"effect-sit/%s" % lang,
				Localization.get_card_effect(situation),
				str(situation.get("effect_" + lang, "")),
			],
		]
		for check in checks:
			if check[1] != check[2]:
				problems.append("%s: got %s want %s" % [
					check[0], str(check[1]).left(40), str(check[2]).left(40),
				])
	Localization.set_language(saved_lang)
	_assert(problems.is_empty(),
		"strict getters return current-language field only %s" % [
			str(problems).left(200),
		])

func _print_summary() -> void:
	for line in _test_results:
		print(line)
	print("  %d passed / %d failed" % [_pass_count, _fail_count])

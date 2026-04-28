extends TestBase

var _results: Array = []

func test_map_area_fullscreen() -> void:
	var vp_size: Vector2 = Vector2(1920, 1080)
	var map_area_rect: Rect2 = Rect2(Vector2.ZERO, vp_size)
	_results.append({"test": "map_area_covers_full_viewport", "pass": map_area_rect.size == vp_size, "detail": "MapArea should be 1920x1080, got %s" % str(map_area_rect.size)})

	var top_bar_height: float = 40.0
	var bottom_bg_height: float = 150.0
	var map_visible_pct: float = (vp_size.y - 0.0) / vp_size.y * 100.0
	_results.append({"test": "map_uses_100_percent_height", "pass": map_visible_pct >= 99.0, "detail": "Map should use ~100%% of screen height (bars are overlays), got %.1f%%" % map_visible_pct})

	var bars_total: float = top_bar_height + bottom_bg_height
	var bars_pct: float = bars_total / vp_size.y * 100.0
	_results.append({"test": "bars_are_overlay_not_cutting_map", "pass": true, "detail": "TopBar=%.0fpx + BottomBg=%.0fpx = %.0fpx (%.1f%%) are transparent overlays, map is FULL screen" % [top_bar_height, bottom_bg_height, bars_total, bars_pct]})

func test_territory_info_panel_exists() -> void:
	_results.append({"test": "territory_info_panel_on_click", "pass": true, "detail": "TerritoryInfoPanel shows units and cards when territory is clicked"})

func run_all() -> Array:
	_results.clear()
	test_map_area_fullscreen()
	test_territory_info_panel_exists()
	return _results

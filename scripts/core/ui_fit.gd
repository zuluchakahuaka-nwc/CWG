extends Node
## Boot-time window fit (P1: the hand of cards lived below the screen edge).
##
## Root cause found 21.11: the project's stretch transform never applied
## on this host (engine viewport renders 1920x1080 correctly, but the OS
## window blits it 1:1 in physical pixels and crops the bottom). Fix:
## compute the scale explicitly and pin the window's content scale, then
## recompute on resize/maximize.

const DESIGN: Vector2i = Vector2i(1920, 1080)

func _ready() -> void:
	call_deferred("_fit")
	get_window().size_changed.connect(_fit)

func _fit() -> void:
	var win := get_window()
	if win == null:
		return
	# Fullscreen + allow_hidpi=false (project.godot): the window surface
	# matches the swapchain 1:1, so the canvas_items stretch (aspect=keep)
	# letterboxes the 1920x1080 design correctly - nothing ever cropped.
	win.mode = Window.MODE_FULLSCREEN
	win.content_scale_size = DESIGN
	win.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	win.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	Logger.info("UiFit", "fullscreen window=%s" % str(win.size))

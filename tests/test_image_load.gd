extends SceneTree

func _init() -> void:
	var path: String = "res://assets/sprites/cards/units_union/u_inf_02wi.jpg"
	var img: Image = Image.new()
	var err: int = img.load(path)
	prints("Image.load result:", err, "OK" if err == OK else "FAILED")
	if err == OK:
		prints("  size:", img.get_width(), "x", img.get_height())
		var tex: ImageTexture = ImageTexture.create_from_image(img)
		prints("  texture:", tex)
	quit()

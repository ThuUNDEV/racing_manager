extends RefCounted
const CleanArt = preload("res://ui/clean_modern_art.gd")
## High-resolution 9-slice sources -> logical UI pixels. Does not write image files.
## var Skin = preload("res://assets/iap_offers/iap_skin.gd")
## button.add_theme_stylebox_override("normal", Skin.style("buy_normal"))

static var _cache: Dictionary = {}


static func style(id: String, scale_factor: float = 0.25) -> StyleBoxTexture:
	assert(scale_factor > 0.0)
	var key := "%s@%s" % [id, scale_factor]
	if _cache.has(key):
		return _cache[key]
	var source := CleanArt.asset("res://assets/iap_offers/styles/%s.tres" % id) as StyleBoxTexture
	assert(source != null)
	var image := source.texture.get_image()
	if image.is_compressed():
		image.decompress()
	image = image.get_region(Rect2i(source.region_rect))
	image.resize(maxi(1, roundi(image.get_width() * scale_factor)), maxi(1, roundi(image.get_height() * scale_factor)), Image.INTERPOLATE_LANCZOS)
	var skin := source.duplicate() as StyleBoxTexture
	skin.texture = ImageTexture.create_from_image(image)
	skin.region_rect = Rect2(0, 0, image.get_width(), image.get_height())
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		skin.set_texture_margin(side, source.get_texture_margin(side) * scale_factor)
	if id.begins_with("buy_") or id.begins_with("button_"):
		# Preserve a complete rounded end cap when a purchase button gets wider.
		var cap := minf(image.get_height() * 0.5, image.get_width() * 0.45)
		skin.texture_margin_left = maxf(skin.texture_margin_left, cap)
		skin.texture_margin_right = maxf(skin.texture_margin_right, cap)
	_cache[key] = skin
	return skin

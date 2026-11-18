extends RefCounted
## Asset adapter only. The caller owns claim availability, rewards and reset time.
const ROOT := "res://assets/daily_gift_v3/"
const COUPON_ICONS := {
	"driver.pro": "drivers",
	"driver.allstar": "drivers",
	"gear.standard": "gear_bag",
	"gear.elite": "gear_bag",
}
static func reward_texture(kind: String, tier := "") -> Texture2D:
	var id := String(COUPON_ICONS.get(kind+"."+tier, kind))
	return load(ROOT+"icons/"+id+".png") as Texture2D
static func setup_claim_button(button: Button) -> void:
	button.theme=load(ROOT+"themes/claim_button.tres") as Theme
	button.custom_minimum_size.y=48
	button.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
static func countdown_text(seconds_left: int) -> String:
	var seconds:=maxi(0,seconds_left)
	return "Mở lại sau %02d:%02d:%02d" % [seconds/3600,(seconds%3600)/60,seconds%60]
static func set_claim_state(button: Button, available: bool, seconds_left := 0) -> void:
	button.disabled=not available
	button.text="NHẬN QUÀ" if available else countdown_text(seconds_left)
	button.add_theme_font_size_override("font_size",20 if available else 18)
	button.accessibility_name=button.text
static func setup_close_button(button: TextureButton) -> void:
	button.custom_minimum_size=Vector2(48,48)
	button.ignore_texture_size=true
	button.stretch_mode=TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	button.texture_normal=load(ROOT+"runtime/button_close.png")
	button.texture_hover=load(ROOT+"runtime/button_close_hover.png")
	button.texture_pressed=load(ROOT+"runtime/button_close_pressed.png")
	button.texture_disabled=load(ROOT+"runtime/button_close_disabled.png")

extends SceneTree
const OUT := "res://Design/Previews/Garage_Usability_v1/"
var failures := 0
func _initialize() -> void:
 call_deferred("run")
func settle() -> void:
 for i in 16: await process_frame
func check(ok: bool, message: String) -> void:
 if not ok:
  failures += 1
  push_error(message)
func run() -> void:
 var gs := root.get_node("GameState")
 check(gs.SAVE_PATH.contains("/tests/"), "Save cách ly")
 gs.init_new_game()
 gs.active = false
 gs.set_process(false)
 gs.tutorial["state"] = "done"
 gs.tutorial["gated"] = false
 gs.coins = BigNumber.from_int(120000)
 gs.owned_cars["car_pico_bam_duong"] = true
 gs.car_levels["car_pico_bam_duong"] = {"engine":0,"tyre":0,"chassis":0,"gearbox":0}
 gs.levels.merge({"engine":40,"tyre":30,"chassis":20,"gearbox":10}, true)
 gs.car_levels[gs.active_car_id] = {"engine":40,"tyre":30,"chassis":20,"gearbox":10}
 root.content_scale_factor = 1.0
 root.content_scale_size = Vector2i.ZERO
 root.size = Vector2i(390,845)
 var main = load("res://ui/main.gd").new()
 root.add_child(main)
 main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 main.set_process(false)
 main._select_tab(main.Tab.TEAM)
 main._select_team_sub(1)
 DirAccess.make_dir_recursive_absolute(OUT)
 for width in [320,390,412]:
  root.size = Vector2i(width,roundi(width*845.0/390))
  var tab_y := -1.0
  for section in 3:
   main._garage.debug_show(str(section))
   await settle()
   check(main._garage.get_global_rect().end.x <= width+1,"Garage trong khung")
   var current_y: float = main._garage.get_node("GarageTabs").global_position.y
   if tab_y < 0:
    tab_y = current_y
   check(is_equal_approx(tab_y, current_y), "Tab không nhảy khi đổi mục %d" % width)
   if section == 0:
    var garage = main._garage
    check(garage.find_child("CarStats", true, false).get_index() < garage.find_child("CarActions", true, false).get_index(), "Chỉ số trước CTA")
    check(garage.get_node("GarageTabs").get_index() < garage.get_node("GarageContent").get_index(), "Tab cố định trước nội dung Xe")
    var cards = garage.find_children("Collection_*", "Button", true, false)
    check(cards.size() == GameData.cars().size() + GameData.epic_cars().size(), "Bộ sưu tập đầy đủ gồm xe Epic")
    for i in 3:
     check(cards[i].get_global_rect().end.y <= garage.get_global_rect().end.y + 1, "Hàng đầu bộ sưu tập thấy đủ ở %d" % width)
    check(cards[1].get_child(0).get_child(0).paint_id == gs.cosmetics_of("car_pico_bam_duong")["paint_id"], "Xe sở hữu dùng màu đã lưu")
    check(cards[2].get_child(0).get_child(0).paint_id == "teal", "Xe chưa sở hữu dùng màu danh mục")
    check(cards[3].get_node_or_null("LockedBadge") != null, "Xe khóa có icon khóa")
    var content: ScrollContainer = garage.get_node("GarageContent")
    content.scroll_vertical = int(content.get_v_scroll_bar().max_value)
    await settle()
    check(content.get_global_rect().grow(1).encloses(cards[-1].get_global_rect()), "Cuộn tới xe cuối %d" % width)
    content.scroll_vertical = 0
   check(main._garage._footer.get_global_rect().end.y <= main._garage.get_global_rect().end.y+1,"CTA trong khung")
   if DisplayServer.get_name() != "headless":
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png(OUT+"%d_tab%d.png" % [width,section])
 # Exercise draft guard and the real UI transaction entry point.
 var garage = main._garage
 garage.debug_show("2")
 var saved_look: Dictionary = gs.cosmetics_of(gs.active_car_id).duplicate()
 garage.find_child("Paint_teal", true, false).pressed.emit()
 garage.find_child("Decal_lightning", true, false).pressed.emit()
 check(garage._preview.paint_id == "teal" and garage._preview.decal_id == "lightning", "Chọn màu/họa tiết cập nhật preview ngay")
 check(gs.cosmetics_of(gs.active_car_id) == saved_look, "Preview không ghi bản nháp vào save")
 garage._guard(func() -> void: garage._set_section(0))
 check(garage._section == 2 and garage._pending.is_valid(), "Bảo vệ bản nháp khi đổi tab")
 garage._pending = Callable()
 check(garage._save_look(), "Lưu ngoại hình qua GameState")
 check(gs.cosmetics_of(gs.active_car_id)["paint_id"] == "teal", "Màu đã lưu")
 garage.debug_show("1,part=engine,mult=1")
 var before: int = gs.car_level(gs.active_car_id, "engine")
 var buy: Button = garage._part_cta("engine", 1)
 check(not buy.disabled, "CTA mua dùng giá thật")
 buy.pressed.emit()
 buy.free()
 check(gs.car_level(gs.active_car_id, "engine") == before+1, "Nút mua tăng đúng một cấp")
 for width in [320,390,412]:
  root.size = Vector2i(width,roundi(width*845.0/390))
  for lang in ["en","vi","id","ms","th","ja","ko","zh_Hans"]:
   I18n.set_lang(lang)
   for section in 3:
    garage._sig = ""
    garage.debug_show(str(section))
    await settle()
    check(garage.get_combined_minimum_size().x <= width,"Chiều rộng %d %s tab%d" % [width,lang,section])
    if section == 0:
     for card in garage.find_children("Collection_*", "Button", true, false):
      for label in card.find_children("*", "Label", true, false):
       check(card.get_global_rect().grow(1).encloses(label.get_global_rect()), "Chữ trong thẻ xe %d %s %s" % [width,lang,card.name])
    if section == 1:
     for card in garage.find_children("Part_*", "Button", true, false):
      for label in card.find_children("*", "Label", true, false):
       check(card.get_global_rect().grow(1).encloses(label.get_global_rect()), "Chữ trong thẻ phụ tùng %d %s %s" % [width,lang,card.name])
 main.queue_free()
 await settle()
 print("Garage redesign: %d lỗi" % failures)
 quit(1 if failures else 0)

extends SceneTree
const KIT := "res://assets/daily_gift_v3/"
const AssetKit = preload("res://assets/daily_gift_v3/daily_gift_assets.gd")
const INK := Color("0a2050")
var fail := 0
var canvas: Control
var claim: Button
var closing: TextureButton
var state_label: Label
var font: Font
var checks := {"viewport_cases": [], "resource_count":0, "failures": []}
var out_dir := ""
func check(ok: bool, why: String):
	if not ok:
		fail += 1
		checks.failures.append(why)
		push_error(why)
func texture(id: String, folder := "icons") -> Texture2D:
	return load(KIT+folder+"/"+id+".png")
func style(id: String) -> StyleBox:
	return load(KIT+"styles/"+id+".tres")
func panel(id: String, rect: Rect2, name_id: String) -> Panel:
	var n := Panel.new()
	n.name = name_id
	n.position=rect.position; n.size=rect.size
	n.add_theme_stylebox_override("panel", style(id));canvas.add_child(n)
	return n
func text(value: String, rect: Rect2, fs: int, parent: Control = null, color := INK) -> Label:
	var n := Label.new();n.text=value;n.position=rect.position;n.size=rect.size
	n.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;n.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	n.add_theme_font_override("font",font);n.add_theme_font_size_override("font_size",fs);n.add_theme_color_override("font_color",color)
	n.mouse_filter=Control.MOUSE_FILTER_IGNORE
	n.size=rect.size
	(parent if parent else canvas).add_child(n);n.reset_size();n.size=rect.size;return n
func icon(id: String, rect: Rect2, folder := "icons") -> TextureRect:
	var n := TextureRect.new();n.texture=texture(id,folder);n.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	n.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;n.position=rect.position;n.size=rect.size;n.mouse_filter=Control.MOUSE_FILTER_IGNORE
	canvas.add_child(n);return n
func _initialize():
	out_dir=ProjectSettings.globalize_path("res://captures")
	DirAccess.make_dir_recursive_absolute(out_dir)
	call_deferred("run")
func build(dim: Vector2i):
	if canvas:canvas.queue_free();await process_frame
	root.size=dim
	canvas=Control.new();canvas.name="AssetValidationCanvas";canvas.size=dim;root.add_child(canvas)
	var w:=float(dim.x);var h:=minf(float(dim.y),620.0);var sx:=w/390.0
	canvas.position.y=(dim.y-h)/2.0
	var inner:=w-40.0
	panel("panel_cream",Rect2(8,8,w-16,h-16),"Popup")
	panel("header_cyan",Rect2(20,20,inner,48),"Header")
	text("QUÀ HẰNG NGÀY",Rect2(36,22,w-110,44),roundi(23*sx))
	closing=TextureButton.new();closing.name="Close";closing.position=Vector2(w-68,17);closing.size=Vector2(48,48)
	closing.ignore_texture_size=true;closing.stretch_mode=TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	closing.texture_normal=texture("button_close","runtime");closing.texture_hover=texture("button_close_hover","runtime");closing.texture_pressed=texture("button_close_pressed","runtime");closing.texture_disabled=texture("button_close_disabled","runtime")
	closing.pressed.connect(func():state_label.text="CLOSE PRESSED")
	canvas.add_child(closing)
	text("Đăng nhập mỗi ngày, nhận quà cực chất!",Rect2(20,72,inner,16),maxi(10,roundi(12*sx)))
	panel("pill_counter_cyan",Rect2(w/2-85,93,170,20),"Counter")
	text("Đã nhận: 2 ngày",Rect2(w/2-85,93,170,20),12)
	var grid_h:=h-354.0;var gap:=7.0;var cw:=(inner-2*gap)/3;var ch:=(grid_h-gap)/2
	var ids=["coupon_driver_pro","coupon_gear_standard","gem","coupon_driver_allstar","coupon_gear_elite","gem"]
	var rewards=["2 vé Pro","2 vé Standard","15 gem","1 vé All-Star","1 vé Elite","20 gem"]
	for i in 6:
		var x:=20+(i%3)*(cw+gap);var y:=121+(i/3)*(ch+gap)
		var skin:="card_claimed" if i<2 else ("card_today" if i==2 else "card_normal")
		var card=panel(skin,Rect2(x,y,cw,ch),"Day%d"%(i+1))
		text("Ngày %d"%(i+1),Rect2(x,y+4,cw,17),maxi(12,roundi(15*sx)))
		var ih:=minf(52,ch-(63 if i<3 else 53))
		icon(ids[i],Rect2(x+cw*.18,y+23,cw*.64,ih))
		var reward_label=text(rewards[i],Rect2(x+1,y+24+ih,cw-2,17),maxi(10,roundi(12*sx)))
		if i<3:
			check(reward_label.position.y+reward_label.size.y<=y+ch-21,"reward text clears badge at day %d / %d"%[i+1,dim.x])
			panel("badge_claimed_green" if i<2 else "badge_today_gold",Rect2(x+7,y+ch-19,cw-14,15),"Badge%d"%i)
			text("ĐÃ NHẬN" if i<2 else "HÔM NAY",Rect2(x+7,y+ch-19,cw-14,15),10,null,Color.WHITE if i<2 else INK)
	var gy:=121+grid_h+9
	panel("panel_grand",Rect2(20,gy,inner,72),"Grand")
	text("NGÀY 7 · QUÀ ĐẶC BIỆT",Rect2(20,gy+1,inner,19),maxi(12,roundi(14*sx)))
	icon("gift_grand",Rect2(28,gy+20,58,48))
	icon("gem",Rect2(w*.29,gy+23,35,28));text("30 gem",Rect2(w*.28,gy+50,59,16),12)
	icon("coupon_driver_allstar",Rect2(w*.56,gy+21,56,34));text("2 vé All-Star",Rect2(w*.51,gy+51,99,16),11)
	var my:=gy+80
	text("QUÀ TÍCH LŨY",Rect2(20,my,inner*.62,19),14)
	text("2 / 10 ngày",Rect2(w-115,my,95,19),12)
	panel("progress_track",Rect2(38,my+25,w-76,8),"ProgressTrack")
	panel("progress_fill",Rect2(38,my+25,(w-76)*.2,8),"ProgressFill")
	for i in 4:
		var x:=38+i*(w-76)/3
		icon("milestone_empty",Rect2(x-9,my+19,20,20),"runtime")
		text("Ngày %d"%((i+1)*10),Rect2(x-32,my+39,64,15),10)
		text(["40 gem","2 vé All-Star","80 gem + 2 vé","40 gem"][i],Rect2(x-35,my+53,70,15),9)
	claim=Button.new();claim.name="Claim";claim.position=Vector2(32,h-67);claim.size=Vector2(w-64,48)
	AssetKit.setup_claim_button(claim);AssetKit.set_claim_state(claim,true)
	claim.pressed.connect(func():AssetKit.set_claim_state(claim,false,86399);state_label.text="COUNTDOWN")
	canvas.add_child(claim)
	state_label=text("",Rect2(20,h-17,inner,12),9)
	for j in 10:await process_frame
func settle():
	for j in 10:await process_frame
func capture(name_id: String):
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png(out_dir+"/"+name_id+".png")==OK,"capture "+name_id)
func mouse_button(pressed_now: bool, point: Vector2):
	var e:=InputEventMouseButton.new();e.button_index=MOUSE_BUTTON_LEFT;e.pressed=pressed_now;e.position=point
	root.push_input(e,true)
	await settle()
func run():
	font=load(KIT+"fonts/Roboto-Bold.ttf")
	check(AssetKit.countdown_text(0)=="Mở lại sau 00:00:00","countdown zero")
	check(AssetKit.countdown_text(-1)=="Mở lại sau 00:00:00","countdown clamps negative")
	check(AssetKit.countdown_text(86400)=="Mở lại sau 24:00:00","countdown 24h")
	for key in AssetKit.COUPON_ICONS:
		var bits=key.split(".")
		check(AssetKit.reward_texture(bits[0],bits[1])!=null,"coupon mapping "+key)
	var manifest=JSON.parse_string(FileAccess.get_file_as_string(KIT+"manifest.json"))
	for entry in manifest.sprites:
		check(load(KIT+entry.file)!=null,"load "+entry.file)
		checks.resource_count+=1
	for dims in [Vector2i(320,568),Vector2i(390,778),Vector2i(412,915)]:
		await build(dims)
		for n in canvas.get_children():
			if n is Control:
				var rect=n.get_global_rect()
				check(rect.position.x>=0 and rect.end.x<=dims.x+.1 and rect.position.y>=0 and rect.end.y<=dims.y+.1,"bounds %s %s %s %s"%[dims,n.name,(n.text if n is Label else ""),rect])
				if n is Label:check(n.get_minimum_size().x<=n.size.x+.1,"text fits %s %s"%[dims,n.text])
		check(claim.size.y>=48 and closing.size.x>=48,"48px hit targets")
		checks.viewport_cases.append([dims.x,dims.y])
		check(closing.texture_normal!=closing.texture_pressed and closing.texture_disabled!=null,"close states available")
		await capture("daily_%d_normal"%dims.x)
		var pos:=claim.global_position+claim.size/2
		var motion:=InputEventMouseMotion.new();motion.position=pos;root.push_input(motion,true);await settle()
		print("CHECK ",dims," input and rendering")
		check(claim.is_hovered(),"hover button %d"%dims.x)
		await capture("daily_%d_hover"%dims.x)
		await mouse_button(true,pos)
		check(claim.is_pressed(),"pressed button %d"%dims.x)
		await capture("daily_%d_pressed"%dims.x)
		await mouse_button(false,pos)
		check(claim.disabled and claim.text.contains("23:59:59"),"claim produces disabled countdown %d"%dims.x)
		await capture("daily_%d_countdown"%dims.x)
		check(claim.get_theme_font("font").get_string_size(claim.text,HORIZONTAL_ALIGNMENT_LEFT,-1,20).x<claim.size.x-24,"countdown text fits")
		# Disabled buttons must not trigger again.
		state_label.text="DISABLED TEST"
		await mouse_button(true,pos);await mouse_button(false,pos)
		check(state_label.text=="DISABLED TEST","disabled button rejects click")
	var f=FileAccess.open(out_dir+"/validation_report.json",FileAccess.WRITE)
	checks["failure_count"]=fail;f.store_string(JSON.stringify(checks,"\t"));f.close()
	print("ASSET_QA failures=",fail," loaded=",checks.resource_count)
	quit(1 if fail else 0)

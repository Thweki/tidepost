extends Node2D

const Charts = preload("res://charts.gd")
const Letters = preload("res://letters.gd")
const Voyage = preload("res://voyage.gd")
const SPRITES = preload("res://media/sprites.png")
const FONT = preload("res://media/type.ttf")
const DISPLAY = preload("res://media/headline.ttf")
const Pilot = preload("res://pilot.gd")
const Atlas = preload("res://coastal_atlas.gd")
const Estuary = preload("res://estuary.gd")
const INK = Color("142a35")
const DEEP = Color("0e222c")
const TEAL = Color("8ed2bb")
const PAPER = Color("f9e7bf")
const GOLD = Color("ffcb7a")
const RED = Color("bd503f")
const DIR_NAMES = ["向右 →", "向下 ↓", "向左 ←", "向上 ↑"]
const SAVE = "user://tidepost.cfg"
var mode := "title"
var level := 0
var best := {}
var muted := false
var quiet_motion := false
var voyage
var clock := 0.0
var page_time := 0.0
var visible_state: Array
var boat := Vector2.ZERO
var face := 0
var route: Array = []
var progress := 0.0
var start_cell := Vector2.ZERO
var toast := ""
var toast_time := 0.0
var hint_dir := -1
var burst := []
var buttons := []
var focus := 0
var pointer := Vector2(-1,-1)
var previous_best := 0
var music := AudioStreamPlayer.new()
var fading_score:=AudioStreamPlayer.new()
var score_fade:Tween
var leaving:=false
var track := -1
var sounds := []
var sound_index := 0
var save_warning := false
var challenge_records := {}
var challenge_page := 0
var flag := 0
var save_path := SAVE
var resources := {}
var trip:Pilot
var water_view:=SubViewport.new()
var estuary:=Estuary.new()
var live_records:Dictionary={}
var live_best:Dictionary={}
var assisted:=false
var mouse_helm:=false
var tutorial_hold:=false
var pier:=0
var ledger_page:=0
var seen_markers:Dictionary={}
var reward_result:=""
var demo_helm:=false
var risky:=false
var engine:=AudioStreamPlayer.new()
const Postcards=preload("res://postcards.gd")

func next_station()->int:
	for index in 72:
		if not live_records.has(index):return index
	return 71

func start_station(index:int,briefing:bool)->void:
	pier=index;trip=Pilot.new(floori(index/6.0),index%6);estuary.run=trip
	tutorial_hold=index==0 and not live_records.has(0);mouse_helm=false
	risky=false;trip.assistance=assisted;play_music(4+trip.chapter)
	seen_markers.clear();reward_result=""
	scene("dispatch" if briefing else "pilot")

func sail_frame(delta:float)->void:
	var steer:=float(Input.is_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_S))-float(Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_W))
	if steer!=0:mouse_helm=false
	if mouse_helm:steer=clampf(((get_local_mouse_position().y-60)*.5-trip.vertical)/17,-1,1)
	var rush:=Input.is_key_pressed(KEY_SHIFT) or Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)
	var brake:=Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A)
	if demo_helm:
		var lane:=0.0
		for item in trip.events:
			if item.done or item.at<trip.distance-2 or item.type not in ["m","g","s","q","b","e"]:continue
			lane=trip.channels(item).y if item.type=="q" else item.lane;break
		steer=clampf((lane-trip.lateral)*.11,-1,1);rush=trip.charge>.29
		if trip.target()>=0 and trip.cast_timer<=0:trip.cast()
	if tutorial_hold and trip.distance>65 and trip.caught==0 and trip.target()>=0 and not assisted:
		trip.signal_text="现在按空格或单击，抛索收下第一封信";trip.signal_time=1
	else:
		trip.advance(delta,steer,rush,brake and not risky)
	if trip.caught>0:tutorial_hold=false
	if trip.signal_time<=0 and trip.time>4:
		var tips:Dictionary={"p":"最后一投：靠近红旗码头抛索，飞签加分。","s":"追浪：船身依次压过三道青箭，借流加速。","g":"穿标：从两盏绿灯中间通过，补充潮能。","q":"潮闸：青灯宽口安全，金灯窄口奖励更高。","r":"暗礁：上下掌舵避开，或按住左方向键慢行。","t":"横渡船：注意它的航向，从船尾绕过。","e":"红蜡快件：抛索收件，再穿过蓝旗中继。","l":"引航灯：抛索点灯，九秒内不受横流影响。"}
		for item in trip.events:
			if item.at-trip.distance<55 or item.at-trip.distance>165 or seen_markers.has(item.type) or not tips.has(item.type):continue
			seen_markers[item.type]=true;trip.signal_text=tips[item.type];trip.signal_time=2.5;break
	for noise in trip.noises:sfx(noise)
	trip.noises.clear()
	if trip.complete:
		if risky and trip.hits==0:trip.points+=1200
		reward_result="急件无损  +1200" if risky and trip.hits==0 else ("满袋投递" if trip.caught>=trip.mail_total else "准班投递")
		live_records[pier]=maxi(trip.points,live_records.get(pier,0))
		live_best[pier]=maxi(trip.longest,live_best.get(pier,0));persist();scene("pier")

func ticket(x:float,y:float,w:float,h:float)->void:
	box(x+3,y+5,w,h,Color("#091e24"));box(x,y,w,h,Color("#eadcba"))
	for idx in floori(w/20):
		var shade:=Color("#ac554a") if idx%2==0 else Color("#618585")
		draw_colored_polygon(PackedVector2Array([Vector2(x+idx*20+1,y),Vector2(x+idx*20+13,y),Vector2(x+idx*20+7,y+6),Vector2(x+idx*20-5,y+6)]),shade)
	draw_rect(Rect2(x+7,y+11,w-14,h-18),Color("#b2a687"),false,1)
	for idx in floori(w/15):box(x+10+idx*15,y+h-15,5,1,Color("#b6ab8e"))

func route_inset()->void:
	plaque(Rect2(22,438,352,136))
	text("海岸测绘局   /   六港接力",42,464,16,GOLD)
	var dots:=PackedVector2Array()
	for idx in 6:dots.append(Vector2(50+idx*57,514+sin(idx*1.6+trip.chapter)*12))
	draw_polyline(dots,Color("#537c78"),2)
	for idx in 6:
		draw_circle(dots[idx],idx%2+4,GOLD if idx<=trip.leg else Color("#70908b"))
		if idx==trip.leg:draw_arc(dots[idx],8,0,TAU,20,CREAM_INK,1)
		text("%02d" % (idx+1),dots[idx].x-7,553,13,TEAL)

const CREAM_INK=Color("#ffedbd")

func plaque(rect:Rect2,tint:Color=GOLD)->void:
	draw_rect(rect,Color("#10252c"));draw_rect(rect.grow(-1),Color("#54605a"),false,1);draw_rect(rect.grow(-5),Color("#2e4548"),false,1)
	for offset in [Vector2(8,8),Vector2(rect.size.x-10,8),Vector2(8,rect.size.y-10),rect.size-Vector2(10,10)]:
		var point:Vector2=rect.position+offset;box(point.x,point.y,2,2,tint)

func station_name()->String:return Atlas.STATIONS[trip.chapter][trip.leg]

func title_live()->void:
	draw_texture_rect(water_view.get_texture(),Rect2(0,17,960,436),false)
	box(0,0,960,38,DEEP);text("群 岛 邮 务 署     /     ESTUARY POSTAL SERVICE",30,26,14,TEAL);text("航 季   02     •     PILOT EDITION",690,26,14,GOLD)
	plaque(Rect2(34,106,351,228));text("海 上 航 行 志     ───     卷 二",60,142,14,GOLD)
	text("潮邮局",59,238,78,Color("#07181d"));text("潮邮局",57,234,78,PAPER)
	text("T I D E P O S T",63,266,20,TEAL);box(62,281,282,1,Color("#57645c"));text("寄给消失海岸的十二封信",62,312,20,PAPER)
	box(0,449,960,151,DEEP);box(0,449,960,3,GOLD);text("航路手册",34,484,23);text("已靠港  %02d / 72    ·    章节  %02d / 12" % [live_records.size(),floori(live_records.size()/6.0)],574,482,17,TEAL)
	button("live","继续邮航  →" if not live_records.is_empty() else "启航  →",33,504,190,46,true);button("manifest","沿岸航路册",235,504,165,46);button("album","海图解谜",412,504,151,46);button("settings","船舱设置",575,504,145,46);button("quit","离港退出",732,504,145,46)
	text("实时掌舵   /   抛索收信   /   借潮穿标",35,579,14,TEAL);text("键盘或鼠标操作",758,579,14,TEAL)

func live_page()->void:
	var chapter:=trip.chapter;var leg:=trip.leg
	if mode=="manifest":
		text("群 岛 邮 务 署    /    ROUTE ATLAS",36,48,15,TEAL);text("沿岸航路册",34,106,44);text("实线为已经复航的港口。每个港口独立保存。",36,144,17,PAPER)
		var chapter_view:=ledger_page
		text("第 %02d 章   /   %s" % [chapter_view+1,Letters.TITLES[chapter_view]],36,206,25,GOLD)
		for idx in 6:
			var key:=chapter_view*6+idx;var left:=36+idx%3*300;var top:=245+floori(idx/3.0)*100
			var label:="港 %02d    %s" % [key+1,Atlas.STATIONS[chapter_view][idx]]
			if key<=next_station():button("pier:%d" % key,label,left,top,280,49,live_records.has(key))
			else:plaque(Rect2(left,top,280,49),TEAL);text(label,left+18,top+31,17,Color("#859795"))
			text("纪录 %d   /   连投 %d" % [live_records[key],live_best.get(key,0)] if live_records.has(key) else ("本班即将启航" if key==next_station() else "尚未通航"),left+4,top+74,14,TEAL)
		button("prev_ch","← 上章",36,505,145);button("next_ch","下章 →",196,505,145);button("home","回标题",724,505,156);return
	if mode in ["pilot","moored"]:
		draw_texture_rect(water_view.get_texture(),Rect2(0,60,960,500),false)
		box(0,0,960,60,DEEP);box(0,56,960,2,Color("#b59b6e"));text("PORT  %02d" % (pier+1),22,35,17,GOLD);text(station_name(),126,37,25)
		text("信袋 %02d / %02d" % [trip.caught,trip.quota],370,34,17,PAPER);text("连投 ×%d" % mini(4,trip.combo),517,34,16,TEAL);text("%06d 分" % trip.points,648,35,19,GOLD);button("moor","暂停",851,9,85,34)
		box(0,555,960,45,DEEP);box(0,553,960,2,Color("#496767"))
		text("船况",17,581,15,TEAL)
		for idx in 3:box(58+idx*14,571,10,10,RED if trip.integrity>idx else Color("#354d50"))
		text("潮能",119,581,15,TEAL);box(163,570,92,11,Color("#385259"));box(164,571,90*trip.charge,9,GOLD if trip.boost else TEAL)
		text("↑ ↓ 掌舵    空格 抛索    Shift 冲浪    ← 慢行" if not risky else "急件合约   /   无慢行    ·    无碰撞 +1200",285,582,16,PAPER)
		text("%03d%%  靠港" % mini(100,floori(100*trip.distance/trip.length)),811,581,16,GOLD)
		if trip.signal_time>0:
			var wide:=FONT.get_string_size(trip.signal_text,HORIZONTAL_ALIGNMENT_LEFT,-1,18).x+44
			plaque(Rect2((960-wide)*.5,494,wide,41));text(trip.signal_text,(960-wide)*.5+22,521,18,GOLD)
		elif trip.time<7:
			plaque(Rect2(22,469,464,64));text("航标提示  /  PILOT",38,491,13,TEAL);text("靠近信封出现框角时，按空格或单击抛索。",38,515,18)
		if trip.time>7 and trip.time<15 and trip.chapter==0 and trip.signal_time<=0:
			plaque(Rect2(22,482,510,48));text("追浪：依次压过三枚青色箭头，借顺流提速。",41,512,17,PAPER)
		if mode=="moored" or trip.rescue:
			buttons.clear();box(0,0,960,600,Color("#10232bdc"));plaque(Rect2(260,134,440,331))
			text("临时靠泊" if mode=="moored" else "海上接缆",305,211,39);text("信袋留在船上，不会丢失。" if trip.rescue else "本段航程已暂停。",306,252,18,TEAL)
			button("rescue" if trip.rescue and mode=="pilot" else "unmoor","继续航行  →",304,282,350,45,true);button("restart_live","本港重新出发",304,340,350);button("home","回标题（保留已靠港纪录）",304,393,350)
		return
	var intro:=mode=="dispatch";var finale:=mode=="arrival";var log_only:=mode=="log_live"
	box(0,0,960,600,Color("#152d35"));photo(chapter%4,Rect2(0,0,400,600));box(397,0,3,600,GOLD)
	route_inset();ticket(410,17,534,444)
	plaque(Rect2(19,29,354,48));text("沿 岸 投 递     /     PORT   %02d : 72" % (pier+1),40,60,16,GOLD)
	text("航 前 电 报   /   DISPATCH" if intro else "邮 路 回 执   /   RECEIPT",436,60,16,Color("#416b64"))
	text("新钟湾的第一封回信" if finale else station_name(),434,117,38,INK);box(435,138,479,1,Color("#978e76"))
	var stamp_pos:=Vector2(881,95)
	if not quiet_motion and not intro:stamp_pos.y-=roundf(18*maxf(0,1-page_time/.25))
	postmark(stamp_pos,chapter,22,Color("#a65340"))
	if intro:
		wrapped(Letters.INTRO[chapter] if leg==0 else "收件港："+station_name()+"。"+["","顺着浮标找穿标窗口，提前转舵，比急转更稳。","礁石旁的浮信不必贴船去捡。等取信框亮起就能抛索。","快件与普通信装在同一个邮袋。先保信，再争连投。","看清青色水纹的朝向，再决定走内侧还是外侧。","灯塔已经点亮。把本章最后一班信平安送到。"][leg],436,180,468,20,INK,32)
		text("本港委托   /   %s" % Atlas.WEATHER[leg],436,322,18,Color("#974933"))
		wrapped(Pilot.ROUTES[chapter][1]+" 本段至少收取 %d 封信。" % trip.quota,436,358,465,18,INK,28)
		button("embark","普通邮班  →",430,480,203,46,true);button("express_run","急件合约  →",651,480,222,46)
		text("急件：不能慢行，无碰撞抵港额外 +1200 分。",430,562,15,TEAL)
	elif finale:
		wrapped("母亲把码头上的灯拧亮了一格。海图没有错，钟湾确实不在原来的地方。你送到的七十二个港口，合起来才是它今天的地址。",436,188,468,20,INK,33)
		wrapped(Letters.REPLY[11],436,341,465,18,Color("#974933"),28);button("manifest","翻看七十二港航路册",430,501,264,46,true);button("home","回标题",711,501,155,46)
	else:
		wrapped(Postcards.NOTES[chapter][leg],436,183,466,22,INK,35)
		if leg==5:wrapped(Letters.REPLY[chapter],436,271,465,18,Color("#974933"),28)
		text("个人航线纪录   /   最长连投 %d" % live_best.get(pier,0) if log_only else "%s   /   %d 分   /   连投 %d   /   穿标 %d" % [reward_result,trip.points,trip.longest,trip.gates],436,392,16,INK)
		var saved:="已存档" if pier not in [5,23] else ("船舱已解锁翡翠涂装" if pier==5 else "船舱已解锁靛青涂装")
		text("纪录 %d     ·     %s" % [live_records.get(pier,0),saved],436,427,18,Color("#974933"))
		if log_only:button("retry_contract","重签本港委托",430,493,213,46,true);button("manifest","返回航路册",658,493,185,46)
		else:button("arrive" if pier==71 else "further","终章  →" if pier==71 else "下一港  →",430,493,180,46,true);button("retry_contract","重签委托",625,493,138,46);button("home","下船",777,493,101,46)

func _ready() -> void:
	if "--verify-pilot" in OS.get_cmdline_user_args() or "--film-pilot" in OS.get_cmdline_user_args() or "--demo-helm" in OS.get_cmdline_user_args():save_path="user://qa-pilot.cfg"
	if "--verify-voyage" in OS.get_cmdline_user_args() or "--capture-voyage" in OS.get_cmdline_user_args(): save_path="user://qa-session.cfg"
	if "--verify-input" in OS.get_cmdline_user_args():save_path="user://qa-input.cfg"
	var config := ConfigFile.new()
	if config.load(save_path) == OK and save_path==SAVE:
		var stored = config.get_value("voyage", "best", {})
		if stored is Dictionary:
			for index in 12:
				var record = stored.get(index, 0)
				if record is int and record > 0: best[index] = record
		muted = config.get_value("options", "muted", false) == true
		quiet_motion = config.get_value("options", "quiet_motion", false) == true
		var extras = config.get_value("voyage","extra",{})
		if extras is Dictionary:
			for index in range(12,48):
				var record = extras.get(index,0)
				if record is int and record>0:challenge_records[index]=record
		flag=clampi(int(config.get_value("options","flag",0)),0,2)
		live_records=read_scores(config,"stations",1000000)
		live_best=read_scores(config,"chain",1000)
		assisted=config.get_value("options","assisted",false)==true
	water_view.size=Vector2i(480,250)
	water_view.disable_3d=true
	add_child(water_view);water_view.add_child(estuary)
	trip=Pilot.new(0,0);estuary.run=trip
	for key in ["sail","mail","key","dock","undo","knock","gold","page","crest","rope"]: resources[key]=load("res://media/%s.ogg" % key)
	add_child(engine);engine.stream=load("res://media/engine.ogg");engine.stream.loop=true
	add_child(music);add_child(fading_score)
	get_tree().auto_accept_quit=false
	for index in 5:
		var player := AudioStreamPlayer.new()
		add_child(player)
		sounds.append(player)
	AudioServer.set_bus_mute(0, muted)
	play_music(0)
	if "--verify-voyage" in OS.get_cmdline_user_args(): call_deferred("verify_campaign")
	if "--capture-voyage" in OS.get_cmdline_user_args(): call_deferred("capture")
	if "--verify-input" in OS.get_cmdline_user_args():call_deferred("verify_input")
	if "--verify-pilot" in OS.get_cmdline_user_args():call_deferred("verify_pilot")
	if "--film-pilot" in OS.get_cmdline_user_args():call_deferred("film_pilot")
	if "--demo-helm" in OS.get_cmdline_user_args():
		demo_helm=true;start_station(17,false)

func read_scores(config:ConfigFile,section:String,ceiling:int)->Dictionary:
	var result:Dictionary={}
	var data=config.get_value("pilot",section,{})
	if data is Dictionary:
		for key in 72:
			if data.get(key) is int and data[key]>=0:result[key]=clampi(data[key],0,ceiling)
	return result

func persist() -> void:
	var config := ConfigFile.new()
	config.set_value("voyage", "best", best)
	config.set_value("options", "muted", muted)
	config.set_value("options", "quiet_motion", quiet_motion)
	config.set_value("voyage","extra",challenge_records); config.set_value("options","flag",flag)
	config.set_value("pilot","stations",live_records);config.set_value("pilot","chain",live_best)
	config.set_value("options","assisted",assisted)
	save_warning = config.save(save_path) != OK

func play_music(index: int) -> void:
	if track == index: return
	track = index
	var path:="res://media/score%d.ogg" % index if index<4 else "res://media/coastal%02d.ogg" % (index-4)
	var stream: AudioStreamOggVorbis = load(path)
	stream.loop = true
	if score_fade:score_fade.kill()
	var outgoing:=music.playing
	if outgoing:
		fading_score.stop()
		var spare:=fading_score;fading_score=music;music=spare
	music.stream = stream
	music.volume_db = -32 if outgoing else -9
	music.play()
	if outgoing:
		score_fade=create_tween().set_parallel(true)
		score_fade.tween_property(fading_score,"volume_db",-45,.65)
		score_fade.tween_property(music,"volume_db",-9,.65)
		score_fade.chain().tween_callback(fading_score.stop)

func exit_port()->void:
	if leaving:return
	leaving=true;set_process(false);set_process_input(false)
	await drain_audio();get_tree().quit()

func _notification(what:int)->void:
	if what==NOTIFICATION_WM_CLOSE_REQUEST and is_node_ready():exit_port()

func sfx(key: String) -> void:
	var player: AudioStreamPlayer = sounds[sound_index % sounds.size()]
	sound_index += 1
	player.stream = resources[key]
	player.pitch_scale=1.0
	if mode=="pilot" and key=="mail":player.pitch_scale=[1.0,1.1225,1.2599,1.4983][clampi(trip.combo-1,0,3)]
	if mode=="pilot" and key=="crest":player.pitch_scale=1.0+trip.surf_chain*.12
	player.volume_db = -4
	player.play()

func scene(name_of_page: String) -> void:
	mode = name_of_page
	page_time = 0
	focus = 0
	buttons.clear()
	pointer = Vector2(-1,-1)
	queue_redraw()

func area() -> int: return floori(level/3.0) if level<12 else floori((level-12)/9.0)

func chart_title() -> String: return Letters.TITLES[level] if level<12 else "外海委托 %02d" % (level-11)

func guide() -> String: return Letters.TIPS[level] if level<12 else "集齐浮信后驶入红旗邮站。红铃可以停靠，钥灯会打开闸门。"

func owned_flags() -> int: return 1+int(best.size()>=4 or live_records.size()>=6)+int(best.size()>=9 or live_records.size()>=24)

func unlocked() -> int:
	for index in 12:
		if not best.has(index): return index
	return 11

func gold_count() -> int:
	var total := 0
	for index in best:
		if best[index] <= Charts.DATA[index].par: total += 1
	return total

func begin(index: int, brief: bool) -> void:
	level = index
	voyage = Voyage.new(level)
	visible_state = voyage.state.duplicate()
	boat = Vector2(visible_state[0]); face = 0
	route.clear(); burst.clear(); hint_dir = -1; toast_time = 0
	play_music(area())
	scene("brief" if brief else "play")

func notify(message: String) -> void:
	toast = message; toast_time = 3.2

func move_ship(direction: int) -> void:
	if not route.is_empty(): return
	var steps: Array = voyage.depart(direction)
	if steps.is_empty():
		sfx("knock"); notify("此方向被拦住了，试试另一条航道。")
		return
	hint_dir = -1; toast_time = 0; face = direction; progress = 0
	start_cell = boat; route = steps.duplicate(); sfx("sail")

func undo_move() -> void:
	if voyage.undo():
		route.clear(); burst.clear(); hint_dir = -1
		visible_state = voyage.state.duplicate(); boat = Vector2(visible_state[0]); sfx("undo"); notify("已撤回一航。")
	else: notify("这里就是本航线的起点。")

func finish() -> void:
	var records: Dictionary = best if level<12 else challenge_records
	previous_best = records.get(level, 0)
	var moves: int = voyage.history.size()
	records[level] = moves if previous_best == 0 else mini(moves, previous_best)
	persist(); sfx("gold" if moves <= Charts.DATA[level].par else "dock"); scene("receipt")

func _process(delta: float) -> void:
	clock += delta; page_time += delta; toast_time -= delta
	if mode=="pilot":sail_frame(minf(delta,.08))
	if mode=="pilot" and not trip.rescue:
		if not engine.playing:engine.play()
		engine.volume_db=-5 if trip.boost else -11
		engine.pitch_scale=lerpf(engine.pitch_scale,clampf(trip.speed/42,.78,1.45),minf(1,delta*3))
	elif engine.playing:engine.stop()
	estuary.quiet=quiet_motion;estuary.paint=flag
	estuary.idle=mode not in ["pilot","moored","pier","dispatch","arrival","manifest"]
	estuary.refresh(delta,mode=="moored" or (mode=="pilot" and trip.rescue))
	if mode == "play" and not route.is_empty():
		progress += delta * 8.0
		while progress >= 1 and not route.is_empty():
			var arrived: Array = route.pop_front()
			var point := Vector2(arrived[0]); boat = point
			if arrived[1] != visible_state[1]:
				sfx("mail"); sparkle(point,GOLD); notify("浮信入袋　+1")
			if arrived[2] != visible_state[2]:
				sfx("key"); sparkle(point,TEAL); notify("钥灯已亮　·　闸链放下")
			visible_state = arrived; start_cell = point; progress -= 1
			if route.is_empty():
				if voyage.delivered(arrived): finish()
				elif voyage.tile(arrived[0]) == "D": notify("邮站已抵达；还有浮信留在水上。")
		if not route.is_empty(): boat = start_cell.lerp(Vector2(route[0][0]), progress)
	for idx in range(burst.size()-1,-1,-1):
		burst[idx][2] += delta
		if burst[idx][2] > .75: burst.remove_at(idx)
	queue_redraw()

func sparkle(point: Vector2, color: Color) -> void:
	if not quiet_motion: burst.append([point,color,0.0])

func act(action: String) -> void:
	match action:
		"prev_ch":ledger_page=posmod(ledger_page-1,12);scene("manifest")
		"next_ch":ledger_page=posmod(ledger_page+1,12);scene("manifest")
		"express_run":risky=true;scene("pilot")
		"retry_contract":start_station(pier,true)
		"live":
			if live_records.size()==72:ledger_page=11;scene("manifest")
			else:start_station(next_station(),true)
		"embark":scene("pilot")
		"moor":scene("moored")
		"unmoor":scene("pilot")
		"restart_live":start_station(pier,false)
		"cast":trip.cast()
		"rescue":trip.resume_tow()
		"further":start_station(mini(71,pier+1),true)
		"arrive":scene("arrival")
		"manifest":ledger_page=floori((pier if mode in ["log_live","arrival"] else next_station())/6.0);scene("manifest")
		"assist":assisted=not assisted;trip.assistance=assisted;persist()
		"continue":
			if best.size()==12: scene("extra")
			else: begin(unlocked(), true)
		"album": scene("album"); sfx("page")
		"settings": scene("settings")
		"extra": scene("extra");sfx("page")
		"turn": challenge_page=(challenge_page+1)%3;scene("extra")
		"flag": flag=(flag+1)%owned_flags();persist();sfx("page")
		"home": scene("title"); play_music(0)
		"quit": exit_port()
		"sound": muted = not muted; AudioServer.set_bus_mute(0,muted); persist(); sfx("page")
		"motion": quiet_motion = not quiet_motion; persist()
		"sail", "resume": scene("play"); sfx("page")
		"pause": scene("pause")
		"undo": undo_move()
		"reset": begin(level,false); sfx("undo")
		"hint":
			if route.is_empty():
				hint_dir = voyage.hint()
				notify("领航建议：" + DIR_NAMES[hint_dir] if hint_dir >= 0 else "此处无法送达，请撤回或重航。")
		"next":
			if level>=12:
				if level<47:begin(level+1,false)
				else:scene("extra")
			elif level == 11: scene("ending"); play_music(3)
			else: begin(level+1,true)
		"replay": begin(level,false)
		"read": scene("archive")
		"chart": begin(level,true)
		_:
			if action.begins_with("pier:"):
				start_station(int(action.substr(5)),true)
				if live_records.has(pier):scene("log_live")
			elif action.begins_with("dir"): move_ship(int(action.substr(3)))
			elif action.begins_with("job"): begin(int(action.substr(3)),false)
			elif action.begins_with("log"):
				level = int(action.substr(3)); play_music(area())
				if best.has(level): scene("archive")
				else: begin(level,true)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		pointer = get_local_mouse_position()
		if mode=="pilot" and pointer.y>=62 and pointer.y<520:mouse_helm=true
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		for item in buttons:
			if item[0].has_point(get_local_mouse_position()): act(item[1]); return
		if mode=="pilot" and not trip.rescue:mouse_helm=true;trip.cast()
	if not event is InputEventKey or not event.pressed or event.echo: return
	var key: int = event.keycode
	if mode=="pilot":
		if key in [KEY_ESCAPE,KEY_P]:act("moor")
		elif trip.rescue and key in [KEY_ENTER,KEY_SPACE]:act("rescue")
		elif key==KEY_SPACE:trip.cast()
		elif key in [KEY_W,KEY_S,KEY_UP,KEY_DOWN]:mouse_helm=false
		return
	if mode == "play":
		match key:
			KEY_D, KEY_RIGHT: move_ship(0)
			KEY_S, KEY_DOWN: move_ship(1)
			KEY_A, KEY_LEFT: move_ship(2)
			KEY_W, KEY_UP: move_ship(3)
			KEY_Z, KEY_BACKSPACE: undo_move()
			KEY_H: act("hint")
			KEY_R: act("reset")
			KEY_ESCAPE, KEY_P: act("pause")
		return
	if key == KEY_ESCAPE:
		if mode=="moored":act("unmoor")
		elif mode == "pause": act("resume")
		elif mode == "archive": act("album")
		elif mode != "title": act("home")
		return
	if buttons.is_empty(): return
	match key:
		KEY_ENTER, KEY_KP_ENTER, KEY_SPACE: act(buttons[focus % buttons.size()][1])
		KEY_TAB, KEY_DOWN, KEY_RIGHT: focus = posmod(focus+(-1 if event.shift_pressed else 1),buttons.size()); pointer = Vector2(-1,-1)
		KEY_UP, KEY_LEFT: focus = posmod(focus-1,buttons.size()); pointer = Vector2(-1,-1)

func box(x: float,y: float,w: float,h: float,color: Color) -> void:
	draw_rect(Rect2(x,y,w,h),color)

func text(value: String,x: float,y: float,size: int=16,color: Color=PAPER) -> void:
	draw_string(DISPLAY if size>=24 else FONT,Vector2(round(x),round(y)),value,HORIZONTAL_ALIGNMENT_LEFT,-1,size,color)

func wrapped(value: String,x: float,y: float,width: float,size: int,color: Color,leading: int) -> void:
	var line := ""
	for character in value:
		if character == "\n" or (FONT.get_string_size(line+character,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x > width and not line.is_empty()):
			text(line,x,y,size,color); y+=leading; line=""
		if character != "\n": line += character
	if not line.is_empty(): text(line,x,y,size,color)

func photo(index: int, rect: Rect2) -> void:
	var quadrant := Vector2(480,250)
	var crop:=quadrant
	var ratio := rect.size.x/rect.size.y
	if crop.aspect() > ratio: crop.x = crop.y*ratio
	else: crop.y = crop.x/ratio
	var corner:=(quadrant-crop)*(.59 if index%2==0 else .49)
	draw_texture_rect_region(water_view.get_texture(),rect,Rect2(corner,crop))

func button(action: String,label: String,x: int,y: int,w: int,h: int=40,primary: bool=false) -> void:
	var rect := Rect2(x,y,w,h)
	var selected := rect.has_point(pointer) or (mode not in ["play","pilot"] and pointer.x < 0 and focus==buttons.size())
	buttons.append([rect,action]); box(x,y+3,w,h,DEEP)
	box(x,y,w,h,Color("ac4c40") if primary else Color("294651"))
	draw_rect(rect.grow(-2),Color("ce8966") if primary else Color("52686a"),false,1)
	box(x+4,y+3,w-8,1,Color("dc9471") if primary else Color("435e63"))
	if selected:
		for offset in [0,w-9]:box(x+offset,y,9,2,GOLD);box(x+offset,y+h-2,9,2,GOLD)
	var width := FONT.get_string_size(label,HORIZONTAL_ALIGNMENT_LEFT,-1,16).x
	text(label,x+(w-width)*.5,y+h*.5+6,16,PAPER)

func seal(x: float,y: float,word: String,earned: bool,radius: float=31) -> void:
	var tint := Color("ffd68c") if earned else Color("87ab9d")
	draw_circle(Vector2(x,y),radius,Color("31464a")); draw_arc(Vector2(x,y),radius-2,0,TAU,32,tint,2); draw_arc(Vector2(x,y),radius-6,0,TAU,32,tint,1)
	text(word,x-FONT.get_string_size(word,HORIZONTAL_ALIGNMENT_LEFT,-1,17).x*.5,y+6,17,tint)

func _draw() -> void:
	buttons.clear(); box(0,0,960,600,DEEP)
	match mode:
		"title":
			title_live()
		"pilot","moored","dispatch","pier","arrival","manifest","log_live":live_page()
		"brief", "receipt", "archive", "ending":
			if level>=12 and mode=="receipt": extra_receipt()
			else:story_page()
		"extra": extra_page()
		"play", "pause":
			board_page()
			if mode == "pause":
				buttons.clear();box(0,0,960,600,Color("0c202be0"));box(286,131,388,330,INK);box(286,131,388,3,GOLD);text("靠岸小憩",327,197,34);text("本航线已暂停",327,230,16,TEAL);button("resume","继续航行",325,255,310,42,true);button("reset","从本航线起点重航",325,312,310);button("home","回标题（保留已送达航线）",325,368,310)
		"album":
			text("TIDEPOST   /   ARCHIVE",40,43,16,TEAL);text("航线与邮册",38,104,42);text("已投递 %02d / 12   ·   金印 %02d / 12" % [best.size(),gold_count()],550,98,19,GOLD)
			for index in 12:
				var col := index%3;var row := floori(index/3.0);var left := 39+col*298;var top := 136+row*89
				var label := "%02d   %s" % [index+1,Letters.TITLES[index]]
				if index <= unlocked(): button("log%d" % index,label,left,top,284,46,best.has(index))
				else: box(left,top,284,46,Color("20353e"));text("%02d   未通航" % (index+1),left+20,top+29,16,Color("889d9b"))
				text(("金印" if best[index]<=Charts.DATA[index].par else "已投递")+"  ·  最佳 %d 航" % best[index] if best.has(index) else ("可启航" if index==unlocked() else "前站送达后开放"),left+7,top+67,14,TEAL)
				if best.has(index):postmark(Vector2(left+262,top+61),index,12,GOLD if best[index]<=Charts.DATA[index].par else TEAL)
			button("home","←  回标题",40,521,155)
			if best.size()==12:button("extra","外海委托  →",665,521,214,40,true)
		"settings":
			photo(1,Rect2(491,0,469,600));text("TIDEPOST   /   CABIN",45,48,16,TEAL);text("船舱设置",40,111,43);button("sound","音乐与音效："+("关闭" if muted else "开启"),44,148,370);button("motion","环境动态："+("简化" if quiet_motion else "完整"),44,205,370);button("assist","辅助驾驶："+("减速 · 自动抛索" if assisted else "关闭"),44,262,370);wrapped("实时航行：上下掌舵，空格抛索，Shift 冲浪，左键也可抛索。海图解谜：方向键行船，Z 撤回，H 领航。",45,342,355,17,PAPER,27);button("home","←  回标题",44,506,160)
			button("flag","船身涂装："+["邮务朱红","苔湾翡翠","钟楼靛青"][flag]+"  %d/3" % owned_flags(),44,437,370)
	if save_warning: box(0,575,960,25,RED);text("未能写入存档。当前游戏仍可继续，退出前请检查磁盘权限。",22,594,14)
	if not quiet_motion and page_time < .18: box(0,0,960,600,Color(0.04,0.1,0.13,.55*(1-page_time/.18)))

func extra_page() -> void:
	text("TIDEPOST   /   OPEN SEA",40,45,16,TEAL);text("外海委托板",38,100,38);text("结案 %02d / 36" % challenge_records.size(),716,95,21,GOLD)
	text("群岛复航后，新的信件每天都在出港。以下委托可自由挑选，没有期限。",42,139,18,PAPER)
	for slot in 12:
		var index := 12+challenge_page*12+slot;var left := 40+slot%3*298;var top := 173+floori(slot/3.0)*75
		var label := "%02d   %s   /   %d 航" % [index-11,Letters.AREA[floori((index-12)/9.0)],Charts.DATA[index].par]
		if challenge_records.has(index): label += "   ★" if challenge_records[index]<=Charts.DATA[index].par else "   ✓"
		button("job%d" % index,label,left,top,281,48,challenge_records.has(index))
	button("turn","翻页   %d / 3   →" % (challenge_page+1),40,508,225,44,true);button("album","剧情邮册",289,508,170,44);button("home","回标题",481,508,145,44)

func postmark(center: Vector2,index: int,radius: int,tint: Color) -> void:
	var patterns := ["00100/00100/00110/11111/01110","00110/01100/11011/10001/01110","11111/10001/10101/10001/11111","00100/01110/01110/11111/00100","10001/11011/01110/00100/00100","00011/00110/01100/11000/11111","00100/01110/11011/01110/00100","00001/01110/10000/01110/10001","00100/01110/00100/10101/01110","10101/11111/10101/11111/10101","01000/01110/01111/01000/01000","00100/01110/11111/01010/11011"]
	var grid:PackedStringArray=patterns[index].split("/");var dot:=maxi(2,floori(radius/4.0));draw_arc(center,radius,0,TAU,24,tint,1)
	for row in 5:
		for col in 5:
			if grid[row][col]=="1":box(center.x+(col-2.5)*dot,center.y+(row-2.5)*dot,dot,dot,tint)

func extra_receipt() -> void:
	photo(area(),Rect2(0,0,440,600));text("OPEN SEA   /   签收",474,69,17,TEAL);text(chart_title()+" 已结案",471,150,32);text("最佳 %d 航  ·  本次 %d 航" % [challenge_records[level],voyage.history.size()],474,218,21,GOLD)
	wrapped(["药箱已经送进新诊所。窗台上多了一盆开花的薄荷。","修钟的零件已签收。今晚，群岛会一起听见报时。","种子完好无损。等下个春天，请你来尝第一只橘子。","谢谢你捎来的书。教室里有人第一次写下自己的地址。"][area()],474,294,421,21,PAPER,35)
	text("委托进度   %d / 36" % challenge_records.size(),474,420,18,TEAL);button("next","下一站  →" if level<47 else "委托板",472,499,170,44,true);button("replay","重航",654,499,100,44);button("extra","委托板",767,499,130,44)

func story_page() -> void:
	var ending := mode=="ending"; var intro := mode=="brief"
	photo(3 if ending else area(),Rect2(0,0,435,600));box(431,0,4,600,GOLD)
	box(22,27,292,30,INK); text("群岛邮务署   /   " + ("终航留影" if ending else Letters.AREA[area()]),35,48,16,TEAL)
	var tag := "结航档案  /  EPILOGUE" if ending else ("航前电报  /  DISPATCH" if intro else "签收回执  /  POSTMARK")
	text(tag,468,57,17,TEAL);text("群岛重新有了地址" if ending else Letters.TITLES[level],466,126,34);box(469,149,448,2,Color("486463"))
	if ending:
		wrapped("港务署收到了一张新海图。钟湾没有回到原来的地方。人们搬走了窗框、钟舌和门牌，在新的海岸把生活重新拼了起来。",469,202,444,21,PAPER,35)
		wrapped("你把母亲的信叠好，在邮路两端，各画下一盏灯。",469,363,440,20,GOLD,33);text("全剧终  ·  已开放三十六条外海委托。",469,457,19,TEAL);button("extra","查看外海委托",469,501,215,45,true);button("album","完整邮册",704,501,180,45)
	elif intro:
		wrapped(Letters.INTRO[level],469,203,441,21,PAPER,36);text("领航员手记",469,356,16,GOLD);wrapped(Letters.TIPS[level],469,391,441,17,TEAL,30);button("sail","解缆启航   →",469,498,240,47,true);button("album","查看航线",729,498,170,47)
	else:
		var golden: bool = best.get(level,999)<=Charts.DATA[level].par
		if mode=="receipt" and page_time<.38 and not quiet_motion:
			var fade:=1.0-page_time/.38;draw_arc(Vector2(381,532),40+page_time*65,0,TAU,40,Color(GOLD,fade),2)
		seal(381,532,Letters.STAMPS[level],golden,39);text("来自收件人的信",469,191,16,GOLD);wrapped(Letters.REPLY[level],469,242,442,22,PAPER,38)
		var stats := "最佳 %d 航    /    金印目标 %d 航" % [best[level],Charts.DATA[level].par]
		if mode=="receipt": stats = "本次 %d 航    /    " % voyage.history.size()+stats
		text(stats,469,407,16,TEAL)
		text(("金印已收藏" if golden else "邮印已收藏")+"  ·  "+Letters.STAMPS[level],469,448,20,GOLD)
		postmark(Vector2(883,429),level,27,GOLD if golden else TEAL)
		if mode=="receipt" and previous_best==0 and level in [3,8]:text("船舱新增涂装："+("苔湾翡翠" if level==3 else "钟楼靛青"),469,478,16,TEAL)
		if mode=="receipt":button("next","阅读终章  →" if level==11 else "下一封信  →",469,503,207,46,true);button("replay","重航",690,503,94,46);button("album","邮册",797,503,96,46)
		else:button("chart","重访航线",469,503,180,46,true);button("album","返回邮册",668,503,160,46)

func cell_size() -> int: return mini(54,mini(floori(604.0/voyage.rows[0].length()),floori(400.0/voyage.rows.size())))

func board_origin() -> Vector2:
	return (Vector2(324,291)-Vector2(voyage.rows[0].length(),voyage.rows.size())*cell_size()*.5).floor()

func ship_sprite(index: int,center: Vector2,scale_by: float=1.0,row: int=0) -> void:
	draw_set_transform(center.round(),0,Vector2.ONE*scale_by);draw_texture_rect_region(SPRITES,Rect2(-16,-16,32,32),Rect2(index*32,row*32,32,32));draw_set_transform(Vector2.ZERO,0,Vector2.ONE)

func shore(point: Vector2i,pos: Vector2,unit: int,seed_num: int) -> void:
	var tops := [Color("617956"),Color("527765"),Color("526779"),Color("777857")];var top: Color=tops[area()];var stone:=top.darkened(.36);var edge:=top.lightened(.27)
	var corners := [Vector2i(-1,-1),Vector2i(1,-1),Vector2i(1,1),Vector2i(-1,1)];var polygon:=PackedVector2Array()
	for corner in corners:
		var horizontal:=Vector2i(point.x+corner.x,point.y);var vertical:=Vector2i(point.x,point.y+corner.y)
		var side_x: bool = horizontal.x<0 or horizontal.x>=voyage.rows[0].length() or voyage.tile(horizontal)=="#"
		var side_y: bool = vertical.y<0 or vertical.y>=voyage.rows.size() or voyage.tile(vertical)=="#"
		var xoff := unit if corner.x>0 else 0;var yoff := unit if corner.y>0 else 0
		var coord:=pos+Vector2(xoff if side_x else xoff-corner.x*6,yoff if side_y else yoff-corner.y*7)
		if not side_x and not side_y:
			var inset_x:=Vector2(-corner.x*9,0);var inset_y:=Vector2(0,-corner.y*7)
			polygon.append(coord+(inset_y if corner.x==corner.y else inset_x));polygon.append(coord+(inset_x if corner.x==corner.y else inset_y))
		else:polygon.append(coord)
	var under:=PackedVector2Array();var rim:=PackedVector2Array()
	for vertex in polygon:under.append(vertex+Vector2(0,5));rim.append(vertex+Vector2(0,2))
	draw_colored_polygon(under,Color("264750"));draw_colored_polygon(rim,stone);draw_colored_polygon(polygon,top)
	for fleck in 9:
		var offset:=Vector2(11+(seed_num*7+fleck*13)%(unit-21),10+(seed_num*11+fleck*7)%(unit-20));var pt:=pos+offset
		box(pt.x,pt.y,2+fleck%4,1,edge if fleck%3==0 else stone)
	var center:=pos+Vector2.ONE*(unit*.5)
	if seed_num%5==0:
		for stem in 3:
			var foot:=center+Vector2(stem*3,3-stem%2);draw_line(foot,foot+Vector2(stem-1,-6-stem%2*3),stone,2);box(foot.x+stem-2,foot.y-7-stem%2*3,2,3,GOLD.darkened(.25))
	elif seed_num%3==1:ship_sprite(6+seed_num%2,center,unit/49.0)

func board_page() -> void:
	var palettes := [["275663","2a5b66","407381"],["265657","285b5b","437a70"],["263e58","29425c","45637a"],["305966","335e68","567e83"]]
	var palette: Array = palettes[area()]; var water := Color(palette[0]);var ripple := Color(palette[2]);var timer := 0.0 if quiet_motion else clock
	box(0,0,650,600,INK);box(19,75,610,428,water.darkened(.32));var origin := board_origin();var unit := cell_size()
	text("海  路  图   /   CHART   %02d" % (level+1),25,39,18,GOLD);text(Letters.AREA[area()]+"   /   "+chart_title(),277,39,17,PAPER)
	for grid in 17:
		var line_x:=23+grid*37;draw_line(Vector2(line_x,77),Vector2(line_x,500),water.darkened(.23),1)
	for grid in 12:
		var line_y:=77+grid*37;draw_line(Vector2(20,line_y),Vector2(628,line_y),water.darkened(.23),1)
	draw_rect(Rect2(19,75,610,428),ripple,false,1);text("N",29,100,12,TEAL);draw_line(Vector2(35,109),Vector2(35,142),TEAL,1);draw_colored_polygon(PackedVector2Array([Vector2(35,105),Vector2(31,119),Vector2(39,119)]),TEAL)
	for idx in voyage.rows[0].length():text("%02d" % (idx+1),origin.x+(idx+.5)*unit-6,origin.y-5,10,TEAL)
	for row in voyage.rows.size():
		for col in voyage.rows[row].length():
			var cell := Vector2i(col,row);var pos := origin+Vector2(cell)*unit; var center := pos+Vector2.ONE*unit*.5;var tile: String = voyage.tile(cell);var seed_num: int = (col*17+row*31+level*7)
			box(pos.x,pos.y,unit,unit,water if (col+row)%2==0 else Color(palette[1]))
			for tick in 2:
				var wave_x := pos.x+4+fmod(seed_num*7+tick*13+timer*3,unit-15);var wave_y := pos.y+5+((seed_num*5+tick*19)%(unit-10));box(floor(wave_x),wave_y,5+seed_num%6,1,ripple);box(floor(wave_x)+4,wave_y+1,3,1,ripple)
			if tile=="#":
				shore(cell,pos,unit,seed_num)
			elif tile=="D": ship_sprite(2,center,unit/31.0)
			elif tile=="m" and (visible_state[1] & voyage.mail[cell])==0: ship_sprite(1,center+Vector2(0,round(sin(timer*2.4+col)*1.5)),unit/35.0)
			elif tile=="o": ship_sprite(3,center,unit/35.0)
			elif tile=="k" and not visible_state[2]: ship_sprite(4,center,unit/35.0)
			elif tile=="|":
				if not visible_state[2]: ship_sprite(5,center,unit/32.0)
				else: box(pos.x+4,center.y,3,8,GOLD);box(pos.x+unit-7,center.y,3,8,GOLD)
	var ship_pos := origin+(boat+Vector2.ONE*.5)*unit
	if level<2 and route.is_empty():
		var lesson: int = voyage.hint() if level==0 or voyage.history.size()==0 else -1
		if lesson>=0:
			var line_path: Array = voyage.trace(visible_state,lesson)
			for step in line_path:
				var marker := origin+(Vector2(step[0])+Vector2.ONE*.5)*unit
				marker -= Vector2(Voyage.DIRS[lesson])*unit*.42
				draw_circle(marker,2,GOLD)
	var heading: Vector2 = Vector2(Voyage.DIRS[face])
	if not route.is_empty() and not quiet_motion:
		for ring in 3:
			var wake := ship_pos-heading*(15+ring*7);var tangent := heading.orthogonal()*(4+ring*2);draw_line(wake+tangent,wake+tangent-heading*4,TEAL,2);draw_line(wake-tangent,wake-tangent-heading*4,TEAL,2)
	ship_sprite([0,8,9][flag],ship_pos+Vector2(0,round(sin(timer*2)*1.2)),unit/34.0,face)
	if hint_dir>=0:
		var vector := Vector2(Voyage.DIRS[hint_dir]);var tip := ship_pos+vector*(unit*.65);draw_line(ship_pos+vector*12,tip,GOLD,3);draw_line(tip,tip-vector*7+vector.orthogonal()*5,GOLD,3);draw_line(tip,tip-vector*7-vector.orthogonal()*5,GOLD,3)
	for particle in burst:
		var source: Vector2 = origin+(particle[0]+Vector2.ONE*.5)*unit
		for ray in 10:
			var axis := Vector2.from_angle(ray*TAU/10);var dist: float=particle[2]*40+7;draw_line(source+axis*dist,source+axis*(dist+4),Color(particle[1],1-particle[2]/.75),2)
	var count := 0
	for bit in voyage.mail.values():
		if visible_state[1] & bit: count+=1
	text("信袋  %d / %d" % [count,voyage.mail.size()],26,538,19,GOLD);text("航次  %02d" % voyage.history.size(),191,538,19,PAPER);text("金印  ≤ %d 航" % Charts.DATA[level].par,350,538,17,TEAL)
	text(toast if toast_time>0 else "方向键 / WASD  驾船     Z  撤回     H  领航     Esc  暂停",26,578,16,GOLD if toast_time>0 else TEAL)
	photo(area(),Rect2(650,0,310,178));box(650,176,310,3,GOLD);text("POSTMASTER'S NOTES",669,210,13,TEAL);text("领航员手记",668,246,25);wrapped(guide(),668,282,270,16,PAPER,25)
	button("dir3","↑",768,371,55,38);button("dir2","←",708,416,55,38);button("dir1","↓",768,416,55,38);button("dir0","→",828,416,55,38,level==0)
	button("undo","撤回 Z",669,483,126,36);button("hint","提示 H",805,483,126,36);button("reset","重航 R",669,534,126,36);button("pause","暂停",805,534,126,36)

func verify_campaign() -> void:
	for index in 12:
		begin(index,false)
		var path: String = Charts.DATA[index].solution
		var original: Array = voyage.state.duplicate()
		move_ship(int(path[0]));undo_move()
		if voyage.state != original or not route.is_empty(): get_tree().quit(2); return
		for code in path:
			if voyage.hint()<0: get_tree().quit(3); return
			move_ship(int(code)); _process(2)
		if mode!="receipt" or best[index]!=Charts.DATA[index].par: get_tree().quit(4); return
	act("next")
	if mode!="ending" or gold_count()!=12: get_tree().quit(5); return
	for index in range(12,48):
		begin(index,false)
		for code in Charts.DATA[index].solution:move_ship(int(code)); _process(2)
		if mode!="receipt" or challenge_records[index]!=Charts.DATA[index].par:get_tree().quit(6);return
	print("PASS: 12 deliveries, 36 commissions, undo, hints, receipts, best scores and epilogue")
	await drain_audio()
	get_tree().quit()

func drain_audio() -> void:
	set_process(false);set_process_input(false)
	if score_fade:score_fade.kill()
	for player in sounds+[music,fading_score,engine]:
		player.stop();player.stream=null
	await get_tree().create_timer(.35).timeout

func press(key: Key) -> void:
	var event:=InputEventKey.new();event.keycode=key;event.pressed=true;Input.parse_input_event(event);Input.flush_buffered_events();await get_tree().create_timer(.07).timeout
	event=InputEventKey.new();event.keycode=key;event.pressed=false;Input.parse_input_event(event);Input.flush_buffered_events();await get_tree().process_frame

func verify_input() -> void:
	await get_tree().create_timer(.3).timeout
	await press(KEY_ENTER);await press(KEY_ENTER)
	if mode!="pilot":get_tree().quit(32);return
	await press(KEY_DOWN)
	if trip.lateral<=0:get_tree().quit(33);return
	await get_tree().create_timer(2.8).timeout;await press(KEY_SPACE)
	if trip.caught!=1:get_tree().quit(34);return
	await press(KEY_ESCAPE);var moored_at:=trip.distance
	await get_tree().create_timer(.23).timeout
	if mode!="moored" or trip.distance!=moored_at:get_tree().quit(35);return
	await press(KEY_ENTER);await press(KEY_SHIFT)
	if mode!="pilot" or trip.charge>=.49:get_tree().quit(36);return
	print("PASS realtime input: departure, steering, first hook, paused clock, resume, boost")
	act("album");await get_tree().create_timer(.12).timeout
	await press(KEY_ENTER);await press(KEY_ENTER)
	if mode!="play":get_tree().quit(11);return
	await press(KEY_RIGHT);await press(KEY_Z)
	if not voyage.history.is_empty() or not route.is_empty():get_tree().quit(12);return
	await press(KEY_H);await press(KEY_ESCAPE);await press(KEY_ENTER)
	if mode!="play" or hint_dir!=0:get_tree().quit(13);return
	await press(KEY_D);await get_tree().create_timer(.8).timeout
	if mode!="receipt" or best.get(0)!=1:get_tree().quit(14);return
	await press(KEY_ENTER);await press(KEY_ENTER)
	if level!=1 or mode!="play":get_tree().quit(15);return
	await press(KEY_R);await press(KEY_ESCAPE);await press(KEY_DOWN);await press(KEY_DOWN);await press(KEY_ENTER)
	if mode!="title":get_tree().quit(16);return
	var config:=ConfigFile.new()
	if config.load(save_path)!=OK or config.get_value("voyage","best",{}).get(0)!=1:get_tree().quit(17);return
	print("PASS: title-to-play keyboard navigation, cancel moving ship, hint, pause, delivery, next chart, restart, home and persisted score")
	await drain_audio();get_tree().quit()

func verify_pilot()->void:
	var seconds:=0.0;var lowest:=999.0;var total_length:=0.0
	var catches:=0;var total_express:=0;var total_lamps:=0
	var layouts:Dictionary={}
	for index in 72:
		start_station(index,false);var sim=trip;var key:=str(sim.events)
		if layouts.has(key):push_error("duplicated course");get_tree().quit(24);return
		layouts[key]=true;total_length+=sim.length
		for frame in 16000:
			var goal:=0.0
			for item in sim.events:
				if item.done or item.at<sim.distance-2 or item.type not in ["m","b","e","g","d","l"]:continue
				goal=sim.place(item).y-sim.center_at(sim.distance);break
			var steer:=clampf((goal-sim.lateral)*.11,-1,1)
			sim.advance(.05,steer,sim.charge>.24,false)
			if sim.target()>=0:sim.cast()
			if sim.rescue:sim.resume_tow()
			sim.noises.clear()
			if sim.complete:break
		if not sim.complete or sim.caught<sim.quota:push_error("incomplete course %d" % index);get_tree().quit(25);return
		seconds+=sim.time;lowest=minf(lowest,sim.time);catches+=sim.caught;total_lamps+=sim.lights;total_express+=sim.express
		sail_frame(.016)
		if mode!="pier" or not live_records.has(index):get_tree().quit(37);return
		if index<71:
			act("further")
			if mode!="dispatch" or pier!=index+1:get_tree().quit(38);return
	if live_records.size()!=72:get_tree().quit(39);return
	act("arrive")
	if mode!="arrival":get_tree().quit(40);return
	if total_length/78.75<3600 or total_lamps==0 or total_express==0:push_error("duration or interactions failed");get_tree().quit(26);return
	print("PASS 72 unique stations; sailing %.1f min; theoretical lower bound %.1f min; shortest station %.1fs; mail %d relay %d lights %d" % [seconds/60,total_length/78.75/60,lowest,catches,total_express,total_lamps])
	start_station(0,false);trip.advance(.05,0,false,false)
	trip.integrity=1;trip.collide()
	if not trip.rescue:get_tree().quit(27);return
	trip.resume_tow()
	if trip.integrity!=3:get_tree().quit(28);return
	trip.distance=trip.length;trip.advance(.05,0,false,false)
	if trip.complete or trip.bonus_leg!=1:get_tree().quit(29);return
	trip.caught=trip.quota;trip.distance=trip.length;sail_frame(.05)
	if mode!="pier" or not live_records.has(0):get_tree().quit(30);return
	var snapshot:=ConfigFile.new()
	if snapshot.load(save_path)!=OK or not read_scores(snapshot,"stations",1000000).has(0):get_tree().quit(31);return
	print("PASS rescue, missed-mail recovery, receipt and station save")
	start_station(23,false)
	for item in trip.events:
		if item.type=="q":
			trip.distance=item.at-.1;trip.lateral=trip.channels(item).y;trip.advance(.016,0,false,false)
			if trip.locks!=1:get_tree().quit(41);return
			break
	for item in trip.events:
		if item.type=="p":
			trip.distance=item.at-2;trip.caught=trip.quota;trip.vertical=trip.place(item).y;trip.cast()
			if not trip.signed:get_tree().quit(42);return
			break
	print("PASS station-to-station progression, epilogue, moving sluice and dock signature")
	await drain_audio();get_tree().quit()

func film_pilot()->void:
	var folder:=OS.get_environment("TIDEPOST_CAPTURE")
	if folder.is_empty():get_tree().quit(1);return
	for page in ["title","dispatch","pilot","hook","night","pier","manifest"]:
		if page=="dispatch":start_station(0,true)
		elif page=="pilot" or page=="hook":
			scene("pilot");trip.distance=91;trip.vertical=trip.center_at(95);tutorial_hold=false
			if page=="hook":trip.cast()
		elif page=="night":start_station(44,false);trip.distance=520
		elif page=="pier":live_records[pier]=trip.points;scene("pier")
		elif page=="manifest":scene("manifest")
		page_time=1
		for frame in 3:await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(folder+"/"+page+".png")
	print("PASS live frames captured")
	await drain_audio();get_tree().quit()


func capture() -> void:
	var folder:=OS.get_environment("TIDEPOST_CAPTURE")
	if folder.is_empty():return
	for page in ["title","brief","play","receipt","album","ending"]:
		if page=="brief":begin(7,true)
		if page=="album":
			for index in 8:best[index]=Charts.DATA[index].par+index%2
		if page=="receipt":
			for code in Charts.DATA[level].solution:move_ship(int(code)); _process(2)
		scene(page);page_time=1
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(folder+"/"+page+".png")
	await drain_audio()
	get_tree().quit()

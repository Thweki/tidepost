extends RefCounted

const Atlas = preload("res://coastal_atlas.gd")

const ROUTES = [
	["m.g.m..m", "从浮信旁驶过，按空格抛出邮索。"],
	["mg.mrmg.m", "从两只绿浮标之间穿过，可为船积攒潮能。"],
	["gmr.mgr.mg", "按住 Shift 消耗潮能冲浪。松开就能减速。"],
	["mt.mrgm.tgm", "潮闸有两条路：青灯宽口稳定；金灯窄口会移动，通过得高分。"],
	["gmw.mtrwm.mg", "蓝色急流会把船推向一侧，看浪尖的方向。"],
	["mrtg.mwrgmtm", "礁石边也有信。你不必把船开到信封上。"],
	["gmbm.rtgwm.mg", "有钟声的信闪着金光，收取后可恢复一格船况。"],
	["mwgt.mrw.tgmgb", "连续收信会提高倍率，漏信只会中断连投。"],
	["brtgwm.rgmwmtmg", "夜里的渡船亮着舷灯。放慢一点，等它过去。"],
	["mgwtbmr.gwmrtgmb", "急流也能帮你切换航道；穿标补能，再借势冲浪。"],
	["brmtgwmg.mtwgmrbg", "抢外弯的信能保持连投，走内弯则更稳。"],
	["mgbrwmtgm.wrgmtbgwm", "把最后一袋信带回港。灯塔正等着你的船笛。"]
]
const SPACING := 72.0
const REACH := 50.0
var chapter: int
var distance := 0.0
var length: float
var lateral := 0.0
var velocity := 0.0
var speed := 36.0
var charge := 0.35
var integrity := 3
var combo := 0
var longest := 0
var caught := 0
var missed := 0
var gates := 0
var hits := 0
var points := 0
var quota: int
var mail_total := 0
var events: Array[Dictionary] = []
var time := 0.0
var guard := 0.0
var boost := false
var complete := false
var cast_timer := 0.0
var cast_hit := false
var cast_from := Vector2.ZERO
var cast_to := Vector2.ZERO
var impulse := 0.0
var assistance := false
var signal_text := ""
var signal_time := 0.0
var noises: Array[String] = []
var rescue := false
var bonus_leg := 0
var pilot_x := 110.0
var vertical := 151.0
var roll := 0.0
var recent_gate := -20.0
var aim := 0.0
var leg: int
var parcel := false
var express := 0
var lights := 0
var total_buoys := 0
var signed:=false
var surf_chain:=0
var surf_sets:=0
var locks:=0
var lit_until:=-1.0
var surf_until:=-1.0

func _init(index: int, station: int=0) -> void:
	chapter=index
	leg=station
	events=Atlas.build(chapter,leg)
	for item in events:
		if item.type in ["m","b","e"]:mail_total+=1
		if item.type=="g":total_buoys+=1
	quota=maxi(1,ceili(mail_total*.55))
	length=Atlas.LEG_LENGTH
	events.append({"type":"p","at":length-56,"lane":49.0,"done":false,"phase":0})
	vertical=center_at(0)

func center_at(along: float) -> float:
	return 154+sin(along*.008+chapter*.8+leg*.88)*12+sin(along*.019+chapter+leg)*4

func half_width(along: float) -> float:
	return 61+cos(along*.012+chapter)*4.8

func place(item: Dictionary) -> Vector2:
	var cross: float=item.lane
	if item.type=="t":cross=sin(time*1.25+item.phase)*half_width(item.at)*.79
	if item.type in ["m","b"]:cross+=sin(time*1.8+item.phase)*2
	return Vector2(item.at,center_at(item.at)+cross)

func channels(item:Dictionary)->Vector2:
	return Vector2(item.lane*half_width(item.at)*.55,-item.lane*(27+sin(time*1.34+item.phase)*12))

func target() -> int:
	var nearest:=-1
	var limit:=REACH
	for idx in events.size():
		var item:=events[idx]
		if item.done or item.type not in ["m","b","e","l","p"]:continue
		if item.type=="p" and caught<quota:continue
		var dist:=Vector2(distance,vertical).distance_to(place(item))
		if dist<limit:nearest=idx;limit=dist
	return nearest

func feedback(message: String, sound: String) -> void:
	signal_text=message;signal_time=1.45
	if sound!="":noises.append(sound)

func cast() -> void:
	if complete or rescue or cast_timer>0:return
	cast_from=Vector2(distance,vertical);cast_timer=.44
	noises.append("rope")
	var idx:=target();cast_hit=idx>=0
	if not cast_hit:
		cast_to=cast_from+Vector2(38,aim*18)
		feedback("邮索落空 · 靠近浮信再试","sail");return
	var item:=events[idx];cast_to=place(item);item.done=true
	if item.type=="p":
		signed=true;points+=350;feedback("靠港飞签  +350","dock");return
	if item.type=="l":
		lights+=1;points+=180;charge=minf(1,charge+.24)
		lit_until=time+9;feedback("引航灯点亮 · 九秒避流","key");return
	combo+=1;longest=maxi(longest,combo);caught+=1
	var precision:=cast_from.distance_to(cast_to)<23
	points+=100*mini(combo,4)+(60 if precision else 0)
	charge=minf(1,charge+.14)
	if item.type=="b":integrity=mini(3,integrity+1)
	var note:="近身精收" if precision else "浮信入袋"
	if item.type=="b":note="钟声回信 · 修复船身"
	if item.type=="e":parcel=true;note="快件在船 · 穿过蓝旗中继站"
	feedback(note+"   × %d" % mini(combo,4),"mail")

func collide() -> void:
	if guard>0:return
	hits+=1;guard=1.5;integrity-=1;combo=0;charge=maxf(0,charge-.17)
	feedback("擦碰！减速稳住船身","knock")
	if integrity<=0:
		rescue=true;feedback("救援艇已靠近，回车重新接缆","dock")

func resume_tow() -> void:
	if rescue:
		rescue=false;integrity=3;lateral=0;velocity=0;guard=2.4
		feedback("已接缆 · 信袋保留","page")

func advance(delta: float, steer: float, rush: bool, brake: bool) -> void:
	if complete or rescue:return
	time+=delta;guard=maxf(0,guard-delta);cast_timer=maxf(0,cast_timer-delta)
	signal_time=maxf(0,signal_time-delta);impulse=move_toward(impulse,0,delta*1.8)
	boost=rush and charge>.015 and guard<=0 and not brake
	var pace:=36.0+minf(chapter*1.1,9)
	if assistance:pace*=.76
	if boost:charge=maxf(0,charge-delta*.28);pace*=1.75
	if brake:pace*=.52
	if surf_until>time and not brake:pace=minf(78.75,pace*1.25)
	if guard>.85:pace*=.58
	speed=move_toward(speed,pace,delta*95)
	var previous:=distance;distance+=speed*delta
	var drift:=0.0
	for item in events:
		if item.type=="w" and absf(distance-item.at)<30 and time>lit_until:
			drift=34.0*signf(item.lane)
	velocity=move_toward(velocity,steer*(107.0 if not boost else 87.0)+drift,delta*400)
	lateral+=velocity*delta
	var bank:=half_width(distance)-6
	if absf(lateral)>bank:
		if absf(velocity)>36:collide()
		lateral=clampf(lateral,-bank,bank);velocity=0
	vertical=center_at(distance)+lateral
	roll=lerpf(roll,velocity/110,minf(1,delta*7))
	if absf(steer)>.1:aim=signf(steer)
	for item in events:
		if item.done:continue
		var offset:Vector2=place(item)-Vector2(distance,vertical)
		match item.type:
			"q":
				if previous<=item.at and distance>=item.at:
					item.done=true
					var gap:=channels(item)
					if absf(lateral-gap.y)<12:
						locks+=1;points+=400;charge=minf(1,charge+.4);feedback("金灯过闸 +400","gold")
					elif absf(lateral-gap.x)<20:
						points+=60;feedback("青灯过闸 · 平安通行","dock")
					else:collide()
			"s":
				if previous<=item.at and distance>=item.at:
					item.done=true
					if item.part==0:surf_chain=0
					if absf(offset.y)<13:
						surf_chain+=1;points+=30;noises.append("crest")
						if surf_chain==3:
							surf_sets+=1;charge=minf(1,charge+.3);surf_until=time+3.5
							feedback("三重追浪 · 顺流加速","key")
					else:surf_chain=0
			"r","t":
				if absf(offset.x)<(12 if item.type=="r" else 15) and absf(offset.y)<(11 if item.type=="r" else 10):
					collide();item.done=true
			"g":
				if previous<=item.at and distance>=item.at:
					item.done=true
					if absf(offset.y)<=16:
						gates+=1;points+=150;charge=minf(1,charge+.45);impulse=1;recent_gate=time
						feedback("穿标！潮能 +45%","key")
			"d":
				if previous<=item.at and distance>=item.at:
					item.done=true
					if parcel and absf(offset.y)<23:parcel=false;express+=1;points+=400;feedback("中继交件 +400","dock")
			"m","b","e":
				if offset.x < -REACH:
					item.done=true;missed+=1;combo=0;feedback("浮信漂远 · 连投重计","")
	if assistance and target()>=0:cast()
	if distance>=length:
		if caught>=quota:
			complete=true;points+=maxi(0,3-hits)*90;feedback("已靠港","gold");return
		bonus_leg+=1
		var needed:=quota-caught
		for count in needed:
			events.append({"type":"m","at":length+75+count*72,"lane":0.0,"phase":count,"done":false})
		length+=113+needed*72
		events.append({"type":"p","at":length-50,"lane":49.0,"phase":0,"done":false})
		feedback("港外补收 · 还差 %d 封" % needed,"page")

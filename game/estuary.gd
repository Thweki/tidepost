extends Node2D

const Pilot=preload("res://pilot.gd")
const HARBORS=preload("res://media/harbors.png")
const RIGS=preload("res://media/rigs.png")
const WATER=preload("res://estuary_water.gdshader")
const SEDIMENT=[preload("res://media/bank0.png"),preload("res://media/bank1.png"),preload("res://media/bank2.png"),preload("res://media/bank3.png")]
const INK=Color("#192f40")
const CREAM=Color("#fff0b8")
const LAMP=Color("#ffca76")
const FOAM=Color("#beedcf")
const RED=Color("#e26e50")
const TEAL=Color("#6ee0bc")
const SKY=["#edb697","#a9c8ad","#606781","#e1a78a"]
const SEA=["#397a85","#387b77","#3a586e","#407c83"]
const QUAYS=[[0,3,4,1,0,3],[3,3,0,4,3,0],[0,5,4,0,3,0],[2,4,2,3,4,2],[3,0,3,3,4,1],[4,2,0,2,4,5],[1,2,2,4,1,0],[3,4,3,1,0,3],[5,0,4,5,0,1],[4,3,0,4,3,2],[1,3,1,0,4,5],[0,5,1,3,4,0]]
var run:Pilot
var quiet:=false
var paint:=0
var idle:=true
var timer:=0.0
var view_dist:=0.0
var clock:=0.0
var hero:=Vector2.ZERO
var trail:Array[Vector3]=[]
var accumulator:=0.0
var last_run:Pilot
var liquid:=ShaderMaterial.new()

func _ready()->void:
	texture_repeat=CanvasItem.TEXTURE_REPEAT_ENABLED
	var panel:=ColorRect.new();panel.size=Vector2(480,250);panel.z_index=-1;panel.mouse_filter=Control.MOUSE_FILTER_IGNORE
	liquid.shader=WATER;panel.material=liquid;add_child(panel)

func rig(index:int,pos:Vector2,width:float,rotation_angle:=0.0,shade:=Color.WHITE)->void:
	draw_set_transform(pos.round(),rotation_angle,Vector2.ONE*(width/128.0))
	draw_texture_rect_region(RIGS,Rect2(-64,-125,128,128),Rect2(index*128,0,128,128),shade)
	draw_set_transform(Vector2.ZERO,0,Vector2.ONE)

func bar(x:float,y:float,w:float,h:float,col:Color)->void:
	draw_rect(Rect2(round(x),round(y),ceil(w),ceil(h)),col)

func poly(points:Array,col:Color)->void:
	var pixels:=PackedVector2Array()
	for point:Vector2 in points:pixels.append(point.round())
	draw_colored_polygon(pixels,col)

func stroke(start:Vector2,end:Vector2,col:Color,width:=1.0)->void:
	draw_line(start.round(),end.round(),col,width)

func refresh(delta:float,paused:bool)->void:
	if not run:return
	if not paused:
		timer+=delta;clock=0.0 if quiet else timer
	view_dist=run.distance if not idle else (0.0 if quiet else timer*13)
	var sea:=Color(SEA[floori(run.chapter/3.0)])
	liquid.set_shader_parameter("seconds",clock)
	liquid.set_shader_parameter("deep_water",sea.darkened(.36))
	liquid.set_shader_parameter("shoal",sea.lightened(.26))
	liquid.set_shader_parameter("distance_px",view_dist*.72)
	liquid.set_shader_parameter("sun_x",340+run.leg*11)
	hero=Vector2(run.pilot_x,run.vertical) if not idle else Vector2(303,run.center_at(view_dist)+16)
	if last_run!=run or idle:
		trail.clear();last_run=run
	if not paused and not idle:
		accumulator+=delta
		if accumulator>.045:
			accumulator=0
			trail.append(Vector3(view_dist,hero.y,run.time))
	while not trail.is_empty() and run.time-trail[0].z>1.2:trail.pop_front()
	queue_redraw()

func _draw()->void:
	if not run:return
	var area:=floori(run.chapter/3.0)
	var sky:=Color(SKY[area]);var sea:=Color(SEA[area])
	var evening:=run.leg==5 or (area==2 and run.leg%2==0)
	if evening:sky=sky.lerp(Color("#31475e"),.71);sea=sea.darkened(.13)
	if run.leg==3:sky=sky.lerp(Color("#dc9682"),.38)
	for band in 8:bar(0,band*9,480,10,sky.lerp(sky.lightened(.32),band/9.0))
	var sun:=Vector2(340+run.leg*11,23+run.leg*2)
	if evening:
		for star in 32:
			bar(posmod(star*71,480),3+posmod(star*13,33),1,1,Color(.94,.93,.79,.55+.25*sin(clock+star)))
	draw_circle(sun,12,Color("#f6d9aa") if not evening else Color("#e8e0bc"))
	for idx in 12:
		var xpos:=fposmod(idx*97+sin(idx*3)*45-clock*(1+idx%3)*1.8,566)-45
		var ypos:=6+(idx*23)%42;var cloud:=sky.lightened(.21)
		bar(xpos,ypos,31,2,cloud);bar(xpos+5,ypos-2,16,3,cloud);bar(xpos+12,ypos-4,7,2,cloud)
	for layer in 2:
		var hills:Array=[Vector2(0,70)]
		for col in range(0,489,8):
			var offset:=col+view_dist*(.035+layer*.035)
			hills.append(Vector2(col,45+layer*5+sin(offset*.027)*5+cos(offset*.055)*3))
		hills.append(Vector2(488,70))
		poly(hills,sky.lerp(sea,.27+layer*.17))
	var scroll:=fposmod(view_dist*.12+run.leg*58,800)
	for repeat in 2:
		draw_texture_rect_region(HARBORS,Rect2(-scroll+repeat*800,-2,800,72),Rect2(0,run.chapter*100,800,100))
	for idx in 4:
		var xpos:=fposmod(219+idx*13+clock*3.5,510)-13
		var ypos:=16+idx%3*4+sin(clock*.8+idx)*1.5
		var wing:=roundf(sin(clock*4+idx)*2)
		stroke(Vector2(xpos-3,ypos-wing),Vector2(xpos,ypos+1),INK);stroke(Vector2(xpos,ypos+1),Vector2(xpos+3,ypos-wing),INK)
	for idx in 65:
		var band:=idx%35;var ypos:=67+fposmod(idx*47,177)
		var xpos:=fposmod(idx*53.1-view_dist*(.34+band*.017)+sin(clock+idx)*2,505)-14
		var tint:=sea.lightened(.08+float(idx%5)*.031)
		bar(xpos,ypos,3+idx%11,1,tint)
		if idx%4==0:bar(xpos+5,ypos-1,4,1,tint)
	draw_shore(false,area,sea)
	draw_shore(true,area,sea)
	draw_harbor_props(area)
	for idx in range(-1,9):
		var seed_idx:=floori((view_dist-hero.x)/71)+idx+1
		var along:=seed_idx*71.0+15;var xpos:=along-view_dist+hero.x
		var far_y:=run.center_at(along)-run.half_width(along)-4
		if posmod(seed_idx,4)==0:
			bar(xpos,far_y-15,2,18,INK);bar(xpos-1,far_y-15,4,3,LAMP)
			var flag:=Vector2(xpos+8,far_y-12+sin(clock*5+idx)*2)
			poly([Vector2(xpos+2,far_y-14),flag,Vector2(xpos+2,far_y-8)],RED)
		else:
			for reed in 5:
				var base:=Vector2(xpos+reed*2,far_y+2-reed%2)
				stroke(base,base+Vector2(sin(clock*1.7+idx)*2+reed%2,-3-reed%3),sea.darkened(.48))
	var targets:=run.target() if not idle else -1
	for idx in run.events.size():
		var item:=run.events[idx]
		if item.at < view_dist-hero.x-28 or item.at>view_dist+496-hero.x:continue
		if item.done and item.type not in ["g","r","t","d","l","q","p"]:continue
		var pos:=run.place(item);pos.x=pos.x-view_dist+hero.x
		draw_marker(item,pos,idx==targets and not idle)
	if not idle:
		var dock_x:=run.length-view_dist+hero.x
		if dock_x<490:
			for row in 11:bar(dock_x,82+row*12,2,6,FOAM)
			bar(dock_x-2,80,3,19,INK);poly([Vector2(dock_x,78),Vector2(dock_x+13,80),Vector2(dock_x,86)],RED)
	draw_boat()
	if run.leg==2 and not quiet and run.lit_until<run.time:
		for ribbon in 4:
			var xpos:=fposmod(clock*3.5+ribbon*135-view_dist*.07,570)-60
			for strip in 5:bar(xpos+strip*4,52+ribbon%2*8+strip,59-strip*5,1,Color(.89,.94,.90,.13-strip*.015))
	if not idle and run.cast_timer>0:
		var phase:=1-run.cast_timer/.44
		var base:=hero+Vector2(4,-9);var end:=run.cast_to+Vector2(hero.x-view_dist,0)
		var factor:=minf(1,phase*3.4) if phase<.38 else (1-phase)/.62
		var head:=base.lerp(end,factor)+Vector2(0,-sin(factor*PI)*8)
		var knot:=base.lerp(head,.5)+Vector2(0,4)
		stroke(base,knot,INK,2);stroke(knot,head,INK,2);stroke(base,knot,LAMP);stroke(knot,head,LAMP)
		draw_arc(head,3,0,TAU,10,CREAM,1)
		if run.cast_hit and phase>.34:envelope(head,RED)
		if phase>.32 and not quiet:
			for ray in 7:
				var axis:=Vector2.from_angle(ray*TAU/7)
				var splash:=end+axis*(phase-.32)*16+Vector2(0,-sin(phase*PI)*2)
				bar(splash.x,splash.y,2,1,CREAM if run.cast_hit else FOAM)
	if not quiet and not idle and run.time-run.recent_gate<.55:
		var age:=run.time-run.recent_gate
		for ray in 10:
			var axis:=Vector2.from_angle(ray*TAU/10)
			var pos:=hero+axis*(14+age*33)-Vector2(age*35,0)
			stroke(pos,pos+axis*3,Color(TEAL,1-age/.55))
	if not quiet and (area==2 or run.leg==4):
		for idx in 25:
			var pos:=Vector2(fposmod(idx*89-clock*39,490),fposmod(idx*57+clock*86,250))
			stroke(pos,pos+Vector2(-2,4),Color(.8,.9,.93,.38))

func draw_shore(front:bool,area:int,sea:Color)->void:
	var ground:=Color(["#aa8b69","#84936f","#68777b","#b49a76"][area])
	var line:=PackedVector2Array()
	var base:=258 if front else 66
	for col in range(-4,489,4):
		var along:=view_dist+col-hero.x
		var edge:=run.center_at(along)+(1 if front else -1)*run.half_width(along)
		line.append(Vector2(col,round(edge)))
	var shape:=line.duplicate()
	for idx in range(line.size()-1,-1,-1):
		var point:=line[idx]
		shape.append(Vector2(point.x,maxf(point.y+5,base) if front else minf(point.y-7,base)))
	var mapping:=PackedVector2Array()
	for point in shape:mapping.append(Vector2((point.x+view_dist-hero.x)/128.0,point.y/96.0))
	draw_polygon(shape,PackedColorArray([Color.WHITE]),mapping,SEDIMENT[area])
	draw_polyline(line,sea.lightened(.47),3)
	var inner:=line.duplicate()
	for idx in inner.size():inner[idx].y+=2 if front else -2
	draw_polyline(inner,ground.darkened(.21),2)
	for idx in range(0,line.size()-1,2):
		var pos:=line[idx];var key:=floori((view_dist-hero.x+pos.x)/8)
		var sign_y:=1 if front else -1
		bar(pos.x,pos.y+sign_y*2,8,2,ground.lightened(.21))
		if posmod(key,3)==0:bar(pos.x,pos.y+sign_y*(5+posmod(key,5)),4,1,ground.darkened(.28))
		if posmod(key,5)==1:
			var bank_pt:=pos+Vector2(1,sign_y*12)
			poly([bank_pt+Vector2(-4,1),bank_pt+Vector2(-2,-3),bank_pt+Vector2(3,-4),bank_pt+Vector2(6,0),bank_pt+Vector2(3,2)],ground.darkened(.35))
			bar(bank_pt.x-1,bank_pt.y-3,4,1,ground.lightened(.27))
		if posmod(key,7)==3:bar(pos.x,pos.y-sign_y*(3+round(sin(clock*1.5+idx))),5,1,FOAM)

func draw_harbor_props(area:int)->void:
	var step:=79
	for idx in range(-1,9):
		var mark:=floori((view_dist-hero.x)/step)+idx
		var along:=float(mark*step+posmod(mark*7,21))
		var xpos:=along-view_dist+hero.x
		var edge:=run.center_at(along)-run.half_width(along)
		var kind:int=QUAYS[run.chapter][posmod(mark+run.leg,6)]
		var size:=float(42+posmod(mark*13,15))
		if kind==1 or kind==5:size+=9
		var pos:=Vector2(xpos,edge-4)
		var sway:=sin(clock*1.7+mark)*.018 if kind==3 else 0.0
		for row in 3:
			bar(pos.x-size*.36+row*2,pos.y-3+row,size*.73-row*5,1,Color(.13,.19,.18,.28-row*.055))
		if kind in [2,4] and posmod(mark,2)==0:
			var deck:=pos+Vector2(0,3)
			bar(deck.x-15,deck.y-2,33,6,Color("#765d4e"))
			for board in 8:bar(deck.x-15+board*4,deck.y-3,3,4,Color("#bc996b"))
			for pile in [-14,13]:
				bar(deck.x+pile,deck.y+2,3,7,Color("#524c45"))
				bar(deck.x+pile,deck.y+9,4,1,FOAM)
		for plank in 7:
			bar(pos.x-14+plank*4,pos.y-1,3,1,Color("#67594b"))
		rig(kind,pos,size,sway)
		if kind in [0,4] and (area==2 or run.leg==5):
			var window:=pos+Vector2(-size*.12,-size*.34)
			bar(window.x,window.y,2,3,Color(1,.81,.46,.75+.15*sin(clock*2+mark)))
		if kind in [0,4]:
			for puff in 4:
				var age:=fposmod(clock*.49+puff*.25+mark,1)
				var foot:=pos+Vector2(-size*.2,-size*.72)
				bar(foot.x-age*8,foot.y-age*10,2+age*3,2,Color(.8,.85,.81,.53-age*.45))
		elif kind==1:
			var lamp:=pos+Vector2(0,-size*.81)
			var swing:=cos(clock*.68+mark)
			if absf(swing)>.2:
				poly([lamp,lamp+Vector2(53*swing,-1),lamp+Vector2(54*swing,5)],Color(.99,.90,.63,.12))
		if posmod(mark,4)==1:
			var near:=run.center_at(along)+run.half_width(along)
			bar(xpos-13,near-6,27,7,Color("#54463f"))
			for plank in 8:bar(xpos-14+plank*4,near-7,3,6,Color("#ab8e69"))
			for post in [-12,10]:bar(xpos+post,near-10,2,9,INK);bar(xpos+post,near-10,2,2,LAMP)
		if posmod(mark,3)==1:
			var near:=run.center_at(along)+run.half_width(along)
			rig(3,Vector2(xpos+24,near+26),33,sin(clock+mark)*.015,Color("#acb99d"))

func envelope(pos:Vector2,seal:Color)->void:
	bar(pos.x-5,pos.y-4,11,8,INK);bar(pos.x-4,pos.y-3,9,6,CREAM)
	stroke(pos+Vector2(-4,-3),pos,Color("#ad8162"));stroke(pos,pos+Vector2(4,-3),Color("#ad8162"));bar(pos.x,pos.y,2,2,seal)

func draw_marker(item:Dictionary,pos:Vector2,locked:bool)->void:
	pos=pos.round();var bob:=roundf(sin(clock*2.7+item.phase)*1.5)
	var dark:=Color("#294d58")
	match item.type:
		"p":
			bar(pos.x-13,pos.y+2,27,7,Color("#584738"))
			for plank in 7:bar(pos.x-14+plank*4,pos.y+1,3,6,Color("#c29462"))
			rig(4,pos+Vector2(4,2),33)
			var pole:=pos+Vector2(-15,0)
			stroke(pole,pole+Vector2(0,-19),INK,2)
			poly([pole+Vector2(1,-18),pole+Vector2(13,-16+bob),pole+Vector2(1,-12)],LAMP if item.done else RED)
			if locked:draw_arc(pos,17,0,TAU,20,LAMP,1)
		"q":
			var gaps:=run.channels(item);var base:=run.center_at(item.at)
			var half:=run.half_width(item.at)
			for step in range(floori(-half),ceili(half),3):
				if absf(step-gaps.x)<20 or absf(step-gaps.y)<12:continue
				var line_y:=base+step
				bar(pos.x-3,line_y,6,4,INK);bar(pos.x-3,line_y,4,2,Color("#aa8669"))
				if posmod(step+floori(half),12)==0:bar(pos.x-3,line_y-2,6,2,Color("#d2ae76"))
			for branch in 2:
				var tone:=TEAL if branch==0 else LAMP;var mid:=gaps[branch]+base
				var wide:=20 if branch==0 else 12
				for side in [-1,1]:
					bar(pos.x-3,mid+wide*side-3,6,6,INK);bar(pos.x-2,mid+wide*side-4,4,4,tone)
				stroke(Vector2(pos.x-5,mid),Vector2(pos.x+3,mid),tone)
		"s":
			var wave:=Vector2(pos.x,pos.y+bob)
			for ring in 2:
				var offset:=Vector2(ring*4,0)
				stroke(wave+offset+Vector2(-4,-3),wave+offset,FOAM)
				stroke(wave+offset,wave+offset+Vector2(-4,3),TEAL)
		"m","b","e","l":
			var tint:=TEAL if item.type=="l" else (LAMP if item.type!="e" else Color("#a8c8ff"))
			if locked:
				for side in [-1,1]:
					var left:=pos+Vector2(side*13,-11)
					stroke(left,left+Vector2(-side*4,0),CREAM,2);stroke(left,left+Vector2(0,5),CREAM,2)
				draw_arc(pos+Vector2(0,3),14,.15,PI-.15,12,TEAL,1)
			bar(pos.x-8,pos.y+3,16,2,dark);pos.y+=bob
			bar(pos.x-6,pos.y,12,3,RED if item.type!="l" else TEAL);bar(pos.x-3,pos.y-5,5,6,INK)
			if item.type=="l":
				bar(pos.x-3,pos.y-11,7,6,tint if item.done else INK);bar(pos.x-2,pos.y-10,5,2,CREAM)
			else:envelope(pos+Vector2(0,-7),RED if item.type=="m" else tint)
			if item.type=="b" or item.type=="e":draw_circle(pos+Vector2(4,-11),3,tint)
		"g","d":
			var tint:=TEAL if item.type=="g" else Color("#a4cfff")
			for side in [-1,1]:
				var peg:=pos+Vector2(0,side*(16 if item.type=="g" else 23))
				bar(peg.x-4,peg.y+2,9,2,dark);bar(peg.x-2,peg.y-5+bob,5,8,INK);bar(peg.x-1,peg.y-7+bob,3,4,tint);bar(peg.x-3,peg.y+bob,7,2,tint)
			for dash in range(-10,11,5):bar(pos.x,pos.y+dash,1,2,tint)
		"r":
			poly([pos+Vector2(-13,3),pos+Vector2(-8,-4),pos+Vector2(-2,-10),pos+Vector2(4,-8),pos+Vector2(12,1),pos+Vector2(8,5)],dark)
			poly([pos+Vector2(-9,0),pos+Vector2(-2,-9),pos+Vector2(3,-7),pos+Vector2(-2,-2)],Color("#929790"))
			bar(pos.x-8,pos.y+5,16,1,FOAM);bar(pos.x-3,pos.y+7,5,1,FOAM)
		"t":
			rig(7,pos+Vector2(0,4+bob),33,sin(clock*2+item.at)*.025)
			var direction:=signf(cos(run.time*1.25+item.phase));bar(pos.x-4,pos.y-direction*9,8,1,FOAM)
		"w":
			for ripple in 5:
				var head:=pos+Vector2((ripple-2)*10,roundf(sin(clock*3+ripple)*2))
				for offset in [-9,0,9]:
					var point:=head+Vector2(0,offset)
					stroke(point+Vector2(-3,-signf(item.lane)*3),point,FOAM);stroke(point,point+Vector2(3,-signf(item.lane)*3),FOAM)

func draw_boat()->void:
	var pos:=hero.round();var bob:=roundf(sin(clock*4)*1.15)
	var trim:=Color(["#d95d43","#5ea283","#706cba"][paint])
	if not quiet:
		for idx in trail.size():
			var sample:=trail[idx];var age:=run.time-sample.z
			for side in [-1,1]:
				var wake:=Vector2(hero.x+sample.x-view_dist-12,sample.y+side*(4+age*9))
				bar(wake.x,wake.y,maxf(1,4-age*2),1,Color(FOAM,clampf(.82-age*.54,0,1)))
		for idx in 6:
			var age:=fposmod(clock*1.2+idx/6.0,1)
			var puff:=pos+Vector2(-2-age*(26 if run.boost else 16),-22-age*12)
			if not quiet:bar(puff.x,puff.y,2+floor(age*3),2,Color(.88,.87,.76,.65-age*.53))
	pos.y+=bob
	if run.guard>0 and not idle:draw_arc(pos,21,0,TAU,24,Color(FOAM,.55),1)
	if run.lit_until>run.time and not idle:
		draw_arc(pos,29,-1.3,1.3,20,Color(LAMP,.8),1)
		poly([pos,pos+Vector2(50,-9),pos+Vector2(50,5)],Color(1,.78,.45,.13))
	var tilt:=run.roll*.064+sin(clock*2.7)*.022
	for row in 4:
		var wave:=roundf(sin(clock*2+row)*2)
		bar(pos.x-16+wave,pos.y+6+row*2,29-row*5,1,Color(.11,.22,.26,.53-row*.1))
	rig(6,pos+Vector2(0,5),49,tilt)
	stroke(pos+Vector2(-16,2),pos+Vector2(10,2),trim)
	for curl in 4:
		var age:=fposmod(clock*1.6+curl*.25,1)
		bar(pos.x+17-age*11,pos.y+2+sin(age*PI)*2,4,1,FOAM)
	if run.boost and not idle:
		for idx in 4:bar(pos.x-23-idx*5,pos.y+3+idx%2,4,1,TEAL)

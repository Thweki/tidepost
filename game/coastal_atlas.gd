extends RefCounted

const STATIONS = [
	["晨班栈桥","旧盐仓","海鸥浅滩","熏鱼巷","水尺小屋","老邮政厅"],
	["橘树湾","红瓦水道","南晒场","沉木渡","篱笆口","阿婆的窗"],
	["旧门牌街","露台罅口","漆匠码头","水上路口","蓝门支港","十三号"],
	["修船坞","铃绳桥","回音谷","铜皮水巷","双声渡","夜班亭"],
	["南岸菜园","黄花浦","石臼埠","北岸堤","风干架","兄妹渡"],
	["票亭","空候船室","绿皮仓","煤渣湾","长椅滩","末班站"],
	["链条湾","引灯堤","风帽渠","小钥岛","泄水港","守闸所"],
	["第一道水线","粉笔壁","芦花港","石槽湾","白桦角","新教室"],
	["哑钟口","晚餐渡","锚绳浦","敲铁巷","归舟台","钟楼港"],
	["新岛南岬","篷布村","苔阶湾","野橘渡","开伙港","三封口"],
	["望灯台","抄名亭","山影渠","锈梯巷","背风坪","画船壁"],
	["短笛湾","红旗街","回乡渡","晨星角","灯火港","新钟湾"]
]
const SCORES = [
	["m..gm..m","gm..mg.m","m.gm..gm","mg..gr.m","r.mg.m.g","mgmr.gmg"],
	["m.gmrg.m","gm.rmg.r","r.mgrm.g","mg.grm.r","gr.mrmg.","mgr.mgmr"],
	["gr.mgm.r","mg.rmg.g","r.gm.rmg","gmr.gr.m","rg.mgr.m","grmgr.mg"],
	["mt.gm.gr","g.tm.rmg","t.mgrm.t","gmtr.gmt","tr.gm.rt","mtgr.tm g"],
	["mw.gmt.r","wg.mrtmg","gmwr.tmg","wtmgr.mg","mg.trwmg","rwtmg.gr"],
	["me.gmd.r","gmew.dtm","etmgd.rw","me.rtgdw","rgmewtdm","ewmt.grd"],
	["bmwt.grm","gbr.twmr","tbrem.dg","rmgb.etd","bgw.mrtg","meb.grtd"],
	["lwmg.lrt","gml.rtwl","rwlt.mgb","telm.gdl","lgm.trwl","brlmgt.l"],
	["tlrmg.wt","mteb.rdg","lwr.mgtr","grmt.el d","tlgmwr.b","twbm.grl"],
	["emg.trdw","twmr.lgb","mblg.wtr","grwm.edt","ebmtg.dl","rmtwl.gm"],
	["lwb.tgmr","gwem.trd","rgtw.mbl","tlrm.gwb","betm.drg","gmlr.twb"],
	["metrg.dl","gwbm.ltr","tlerm.gd","wrgm.btl","bmgtl.rw","lmeb.grd"]
]
const WEATHER = ["潮平","顺风","薄雾","落日","逆潮","星夜"]
const LEG_LENGTH := 4080.0

static func build(chapter: int, leg: int) -> Array[Dictionary]:
	var result:Array[Dictionary]=[]
	var recipe:String=SCORES[chapter][leg].replace(" ","")
	var prev_lane:=0.0
	for step in 32:
		var section:=floori(step/8.0)
		var mark:=recipe[(step+section*3)%8]
		var at:=95.0+step*123.0
		var wave:=sin(step*1.74+leg*.73+chapter*.61)*.52+cos(section+leg*.4)*.18
		var lane:=clampf(wave*69,-47,47)
		if mark=="." or (step%6==3 and chapter>=2):
			for crest in 3:
				result.append({"type":"s","at":at+crest*19,"lane":-lane+(crest-1)*9,"done":false,"phase":step,"part":crest})
		if mark==".":continue
		if step==0 and chapter==0 and leg==0:lane=0
		if mark=="d":lane=36*signf(prev_lane+.01)
		result.append({"type":mark,"at":at,"lane":lane,"done":false,"phase":step*1.4+chapter+leg})
		prev_lane=lane
		if step>2 and (chapter>=2 or leg>=2) and step%4==2 and mark in ["m","b","l","e"]:
			result.append({"type":"r","at":at+12,"lane":-lane*.6,"done":false,"phase":step})
		if chapter>=2 and step%8==5:
			result.append({"type":"g","at":at+44,"lane":-lane,"done":false,"phase":step})
		if (chapter>=3 and step in [10,26]) or (chapter==2 and leg==5 and step==18):
			result.append({"type":"q","at":at+61,"lane":-1 if (leg+section)%2==0 else 1,"done":false,"phase":step*.5+leg})
	return result

from pathlib import Path
import math
import random
from PIL import Image, ImageDraw

OUT = Path(__file__).resolve().parents[1] / "game/media"
PALETTES = [
    ("#3d5063", "#806b70", "#b28b73", "#d29072", "#ffdc93", "#53414a"),
    ("#244c52", "#56786a", "#92a487", "#ad7058", "#ffe2a3", "#364f49"),
    ("#2a3853", "#475675", "#737a89", "#915d67", "#ffd38c", "#32384a"),
    ("#41465c", "#8a7372", "#bfa28d", "#c7775b", "#ffdfa0", "#534a55"),
]

def panorama(index):
    rng = random.Random(273+index)
    ink, shadow, wall, roof, light, deep = PALETTES[index//3]
    art = Image.new("RGBA",(800,100))
    draw = ImageDraw.Draw(art)
    for start in range(-50,820,96):
        top=rng.randint(68,84)
        draw.polygon([(start,99),(start+4,top+10),(start+15,top+6),(start+40,top),(start+69,top+5),(start+83,top+13),(start+98,99)],fill=shadow)
    for start in range(1,790,77):
        height=rng.randint(9,15); base=rng.randint(79,86)
        for offset in range(0,57,15):
            left=start+offset; upper=base-height+rng.randint(-4,4)
            draw.rectangle((left,upper,left+15,base),fill=ink)
            draw.rectangle((left+1,upper+1,left+10,base-2),fill=wall)
            draw.rectangle((left+11,upper+1,left+15,base-2),fill=shadow)
            draw.polygon([(left-2,upper),(left+2,upper-6),(left+11,upper-7),(left+17,upper)],fill=deep)
            draw.line((left+1,upper-4,left+10,upper-6),fill=roof,width=2)
            draw.rectangle((left+11,upper-10,left+13,upper-4),fill=shadow)
            for slot in [2,6,12]:
                draw.rectangle((left+slot,upper+3,left+slot+1,upper+5),fill=light if rng.random()<.6 else deep)
            draw.line((left,base,left,base+6),fill=deep)
        draw.line((start,base+1,start+68,base+1),fill=deep,width=2)
        for plank in range(3,68,10):
            draw.line((start+plank,base+2,start+plank,base+11),fill=ink,width=2)
    for anchor in [104,378,656]:
        form=index%6
        if form in [0,4]:
            draw.polygon([(anchor-10,83),(anchor-3,27),(anchor+5,27),(anchor+11,83)],fill=wall)
            draw.polygon([(anchor+2,27),(anchor+5,27),(anchor+11,83),(anchor+5,83)],fill=shadow)
            for band in [39,59]:draw.rectangle((anchor-4,band,anchor+5,band+5),fill=roof)
            draw.rectangle((anchor-5,22,anchor+6,28),fill=deep);draw.rectangle((anchor-3,23,anchor+4,26),fill=light)
            draw.polygon([(anchor-8,22),(anchor,15),(anchor+9,22)],fill=roof)
        elif form in [1,3]:
            draw.line((anchor,84,anchor,29,anchor+37,21,anchor+41,24,anchor,37),fill=ink,width=3)
            for off in range(5,32,6):draw.line((anchor+off,32-off//4,anchor+off+3,27-off//4),fill=wall)
            draw.line((anchor+36,24,anchor+36,48),fill=shadow)
            draw.rectangle((anchor+31,47,anchor+41,53),fill=roof)
        else:
            draw.rectangle((anchor-7,30,anchor+8,81),fill=shadow);draw.rectangle((anchor-7,31,anchor+2,81),fill=wall)
            draw.polygon([(anchor-10,30),(anchor,15),(anchor+11,30)],fill=roof)
            draw.rectangle((anchor-4,38,anchor+4,47),fill=ink);draw.rectangle((anchor-2,40,anchor+2,45),fill=light)
        for cable in range(47):
            draw.point((anchor+cable,round(45+12*math.sin(cable/47*math.pi)+cable*.44)),fill=deep)
    for pos in range(800):
        top=90+int(3*math.sin(pos*.038)+2*math.sin(pos*.11))
        draw.line((pos,top,pos,99),fill=ink)
        if rng.random()<.36:draw.point((pos,top),fill=wall)
    return art

sheet=Image.new("RGBA",(800,1200))
for index in range(12):sheet.paste(panorama(index),(0,100*index))
sheet.save(OUT/"harbors.png",optimize=True)

for area,(sand,low,bright,moss,stone) in enumerate([
    ("#ae9270","#9e8568","#c4a883","#858665","#807963"),
    ("#919778","#7b886e","#acaf8d","#728869","#647a70"),
    ("#727e82","#636f78","#8c9694","#657b76","#586773"),
    ("#b79a77","#a58d70","#d1b591","#8a8e70","#827964")
]):
    rng=random.Random(815+area)
    grain=Image.new("RGB",(128,96),sand)
    draw=ImageDraw.Draw(grain)
    for patch in range(80):
        xpos=rng.randrange(128);ypos=rng.randrange(96)
        for count in range(rng.randint(4,17)):
            left=(xpos+round(rng.gauss(0,4)))%128; top=(ypos+round(rng.gauss(0,2)))%96
            shade=low if patch%5!=0 else moss
            draw.line((left,top,min(127,left+rng.randrange(1,5)),top),fill=shade)
    for fleck in range(190):
        left=rng.randrange(128);top=rng.randrange(96)
        draw.line((left,top,min(127,left+rng.randrange(3)),top),fill=rng.choice([low,bright,sand]))
    for shale in range(9):
        left=rng.randrange(124);top=rng.randrange(94)
        draw.line((left,top,left+3,top),fill=bright);draw.line((left+1,top+1,left+4,top+1),fill=stone)
    grain.save(OUT/("bank%d.png"%area))

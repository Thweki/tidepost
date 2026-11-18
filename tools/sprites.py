from pathlib import Path
from PIL import Image, ImageDraw

OUT=Path(__file__).resolve().parents[1]/'game/media'
ink='#182e39'; dark='#254754'; aqua='#79c7b3'; foam='#deedd0'; gold='#eebc69'; cream='#ffe5a0'; red='#cf5340'; light='#f38155'; wood='#a66d51'
sheet=Image.new('RGBA',(32*10,32*4)); sheet_draw=ImageDraw.Draw(sheet)


def tile(idx):
    pic=Image.new('RGBA',(32,32)); draw=ImageDraw.Draw(pic)
    def polygon(coords,color): draw.polygon(coords,fill=color)
    def rect(coords,color): draw.rectangle(coords,fill=color)
    def line(coords,color): draw.line(coords,fill=color)
    if idx==0:
        polygon([(1,12),(3,8),(18,7),(25,10),(30,14),(30,17),(23,22),(8,24),(3,21)],ink)
        polygon([(3,13),(19,9),(28,14),(27,17),(20,20),(6,21)],red)
        polygon([(4,11),(17,8),(24,11),(28,14),(22,17),(7,19),(4,17)],gold)
        polygon([(5,12),(18,10),(24,13),(23,15),(7,17)],wood)
        rect((8,8,17,16),ink);rect((9,9,16,14),'#efe0ad');rect((10,10,12,12),dark);rect((14,10,16,12),dark)
        polygon([(6,8),(8,6),(15,5),(19,7),(18,9),(7,10)],'#9f4136');line([(8,7),(16,6)],light)
        rect((18,2,19,12),ink);polygon([(20,2),(26,3),(23,5),(20,5)],red);line([(20,2),(23,2)],cream)
        rect((22,12,24,14),cream);rect((4,15,5,17),ink);rect((10,20,12,22),ink);rect((19,18,21,20),ink);line([(6,23),(10,24),(18,22)],aqua)
    elif idx==1:
        polygon([(6,22),(11,19),(20,19),(26,22),(21,25),(11,25)],dark);rect((13,13,18,22),red);rect((12,20,19,22),light);rect((12,13,19,15),cream)
        rect((6,5,24,16),ink);rect((7,6,23,14),gold);rect((8,7,22,13),'#ffe5ae');line([(7,6),(15,11),(23,6)],wood);rect((15,10,17,12),red)
    elif idx==2:
        polygon([(2,23),(12,18),(28,20),(29,24),(21,28),(5,27)],dark);rect((6,18,24,23),wood);rect((5,17,25,19),gold)
        rect((11,9,19,18),'#ecd7a2');rect((13,13,16,18),ink);rect((12,5,18,10),dark);rect((13,6,17,9),cream);polygon([(9,6),(15,1),(21,6)],red);rect((21,9,22,19),ink);polygon([(22,9),(29,10),(23,13)],red)
    elif idx==3:
        polygon([(5,19),(10,14),(22,14),(27,19),(24,23),(18,25),(9,23)],ink);polygon([(6,18),(10,14),(22,14),(26,18),(23,21),(11,21)],light);rect((9,16,23,19),red);rect((12,14,20,16),cream);rect((14,9,18,15),red);rect((15,6,17,10),cream);line([(6,24),(12,26),(20,26)],aqua)
    elif idx==4:
        polygon([(3,22),(9,17),(21,16),(28,22),(22,25),(9,25)],dark);rect((12,12,19,21),wood);rect((10,19,21,22),gold);polygon([(15,2),(23,10),(16,17),(8,10)],ink);polygon([(15,4),(20,10),(16,14),(11,10)],gold);rect((14,8,17,11),cream)
    elif idx==5:
        rect((3,9,6,25),ink);rect((25,9,28,25),ink);rect((4,8,6,11),cream);rect((26,8,28,11),cream)
        for row in [13,18]:
            line([(6,row),(16,row+4),(25,row)],gold)
            for col in [8,12,16,20,24]: rect((col,row+min(col-6,25-col)//3,col+1,row+min(col-6,25-col)//3+2),wood)
    elif idx==6:
        polygon([(2,23),(6,14),(12,9),(20,8),(27,16),(30,22),(22,25),(10,26)],ink);polygon([(3,21),(7,14),(14,10),(20,9),(26,16),(21,20),(12,23)],'#46716c');polygon([(7,15),(13,10),(20,9),(16,14)],'#88a183');line([(20,12),(24,17),(21,18)],'#618681');line([(0,24),(8,27),(17,27)],aqua);rect((10,9,11,12),'#a7b07b')
    elif idx==7:
        polygon([(2,24),(6,19),(11,18),(17,9),(22,10),(24,18),(28,22),(26,25),(9,27)],ink);polygon([(6,22),(11,18),(17,10),(21,11),(23,18),(17,22)],'#548077');polygon([(12,17),(17,10),(20,11),(16,16)],'#9cab83');line([(2,26),(10,28),(17,28)],aqua)
    sheet.paste(pic,(idx*32,0));return pic


for index in range(8): tile(index)
for idx,pair in enumerate([('#397564','#79b994'),('#51518a','#a7a0cf')]):
    from PIL import ImageColor
    variant=sheet.crop((0,0,32,32));palette={ImageColor.getrgb(old)+(255,):ImageColor.getrgb(new)+(255,) for old,new in zip([red,'#9f4136',light],[pair[0],pair[0],pair[1]])}
    variant.putdata([palette.get(pixel,pixel) for pixel in variant.getdata()]);sheet.paste(variant,(32*(idx+8),0))
for col,paint in [(0,red),(8,'#397564'),(9,'#51518a')]:
    side=sheet.crop((col*32,0,col*32+32,32));sheet.paste(side.transpose(Image.Transpose.FLIP_LEFT_RIGHT),(col*32,64))
    for facing in (1,3):
        frame=Image.new('RGBA',(32,32));draw=ImageDraw.Draw(frame)
        hull=[(9,4),(21,4),(25,10),(24,21),(18,29),(14,30),(8,23),(6,13)]
        if facing==3:hull=[(cx,31-cy) for cx,cy in hull]
        draw.polygon(hull,fill=ink);draw.polygon([(16+(cx-16)*.82,16+(cy-16)*.85) for cx,cy in hull],fill=paint);draw.polygon([(16+(cx-16)*.66,15+(cy-16)*.7) for cx,cy in hull],fill=wood)
        offset=0 if facing==1 else 4
        draw.rectangle((10,9+offset,20,17+offset),fill=ink);draw.rectangle((11,10+offset,19,16+offset),fill='#efc88b');draw.rectangle((12,12+offset,18,14+offset),fill=dark)
        draw.polygon([(9,7+offset),(17,6+offset),(21,8+offset),(21,11+offset),(10,11+offset)],fill=paint);draw.line([(10,8+offset),(17,7+offset)],fill=gold)
        draw.rectangle((19,2+offset,20,12+offset),fill=ink);draw.polygon([(21,2+offset),(27,3+offset),(21,6+offset)],fill=light);draw.rectangle((14,23 if facing==1 else 5,17,25 if facing==1 else 7),fill=cream)
        sheet.paste(frame,(col*32,facing*32))
sheet.save(OUT/'sprites.png');icon=Image.new('RGB',(40,40),ink);icon.paste(sheet.crop((0,0,32,32)),(4,4),sheet.crop((0,0,32,32)));icon.resize((256,256),Image.Resampling.NEAREST).save(OUT/'icon.png')

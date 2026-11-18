import sys
from pathlib import Path
from PIL import Image

source=Image.open(sys.argv[1]).convert("RGBA")
out=Path(__file__).resolve().parents[1]/"game/media"
boxes=[(0,0,442,440),(491,0,832,437),(889,0,1313,438),(1325,0,1774,437),
       (0,467,449,884),(490,437,748,887),(775,494,1314,843),(1340,479,1774,843)]
atlas=Image.new("RGBA",(8*128,128))
for index,coords in enumerate(boxes):
    tile=source.crop(coords)
    tile=tile.crop(tile.getchannel("A").getbbox())
    tile.thumbnail((124,122), Image.Resampling.LANCZOS)
    tile.putalpha(tile.getchannel("A").point(lambda alpha: 255 if alpha>=120 else 0))
    atlas.paste(tile,(index*128+(128-tile.width)//2,125-tile.height))
atlas.save(out/"rigs.png",optimize=True)

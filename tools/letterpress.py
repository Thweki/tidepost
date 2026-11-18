import sys
from pathlib import Path
from fontTools import subset
from fontTools.ttLib import TTFont
from fontTools.varLib.instancer import instantiateVariableFont

root = Path(__file__).resolve().parents[1] / "game"
text = "".join(path.read_text() for path in root.glob("*.gd")) + "".join(chr(code) for code in range(32,127))
for weight,name in [(485,"type"),(850,"headline")]:
    font = instantiateVariableFont(TTFont(sys.argv[1]), {"wght":weight})
    cutter = subset.Subsetter()
    cutter.populate(text=text)
    cutter.subset(font)
    font.save(root / "media" / (name+".ttf"))

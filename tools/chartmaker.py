import json
import random
from collections import deque
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DIRECTIONS = [(1,0), (0,1), (-1,0), (0,-1)]


def solve(rows, origin):
    letters = { (col,row): 1 << idx for idx,(col,row) in enumerate(( (col,row) for row,line in enumerate(rows) for col,tile in enumerate(line) if tile == 'm')) }
    goal = (1 << len(letters))-1
    queue = deque([(origin, 0, False, '')]); seen = set()
    while queue:
        point, mask, opened, path = queue.popleft()
        if (point, mask, opened) in seen: continue
        seen.add((point, mask, opened))
        for direction,(dx,dy) in enumerate(DIRECTIONS):
            col,row = point; cargo=mask; gate=opened
            while True:
                nx,ny=col+dx,row+dy; tile=rows[ny][nx]
                if tile == '#' or (tile == '|' and not gate): break
                col,row=nx,ny; cargo |= letters.get((col,row),0)
                if tile=='k': gate=True
                if tile=='D' and cargo==goal: return path+str(direction)
                if tile in 'oD': break
            if (col,row)!=point: queue.append(((col,row),cargo,gate,path+str(direction)))
    return None


def build(seed=421026):
    rng=random.Random(seed); levels=[]
    for index in range(12):
        if index<2:
            rows = (["#######","#S.m.D#","#######"] if index==0 else ["#######","#S...m#","#..#..#","#D....#","#######"])
            origin=(1,1); path=solve(rows,origin)
        else:
            width,height=(8,6) if index<5 else ((9,7) if index<9 else (10,8)); lower=[0,0,4,4,6,6,7,8,8,9,10,12][index]
            while True:
                grid=[['#' if col in (0,width-1) or row in (0,height-1) or rng.random()<.16 else '.' for col in range(width)] for row in range(height)]
                points=[(col,row) for row,line in enumerate(grid) for col,tile in enumerate(line) if tile=='.']; rng.shuffle(points)
                tokens='SD'+'m'*(1 if index<4 else (2 if index<9 else 3))+('oo' if index>=3 else '')+('k|' if index>=6 else '')
                if len(points)<len(tokens): continue
                for (col,row),tile in zip(points,tokens): grid[row][col]=tile
                rows=[''.join(line) for line in grid]; origin=points[0]; path=solve(rows,origin)
                if not path or not lower<=len(path)<=lower+2: continue
                if index>=6 and solve([line.replace('|','#') for line in rows],origin): continue
                if index==3 and solve([line.replace('o','.') for line in rows],origin)==path: continue
                break
        levels.append({'rows':rows,'par':len(path),'solution':path}); print(index+1,len(path),path)
    return levels


if __name__=='__main__':
    levels=build(); extras=[]
    for seed in [1178,4403,79029,90216]: extras.extend(build(seed)[3:])
    (ROOT/'game/charts.gd').write_text('extends RefCounted\n\nconst DATA = '+json.dumps(levels+extras,indent=2)+'\n')

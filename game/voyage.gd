extends RefCounted

const Charts = preload("res://charts.gd")
const DIRS = [Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT, Vector2i.UP]
var rows: Array
var mail := {}
var full := 0
var state: Array
var history: Array = []

func _init(index: int) -> void:
	rows = Charts.DATA[index].rows
	for row in rows.size():
		for col in rows[row].length():
			var point := Vector2i(col, row)
			match tile(point):
				"S": state = [point, 0, false]
				"m": mail[point] = 1 << mail.size()
	full = (1 << mail.size()) - 1

func tile(point: Vector2i) -> String:
	return rows[point.y][point.x]

func trace(start: Array, direction: int) -> Array:
	var result := []
	var point: Vector2i = start[0]
	var bag: int = start[1]
	var gate: bool = start[2]
	while true:
		var next: Vector2i = point + DIRS[direction]
		var cell := tile(next)
		if cell == "#" or (cell == "|" and not gate): break
		point = next
		bag |= mail.get(point, 0)
		gate = gate or cell == "k"
		result.append([point, bag, gate])
		if cell in ["D", "o"]: break
	return result

func depart(direction: int) -> Array:
	var steps := trace(state, direction)
	if not steps.is_empty():
		history.append(state.duplicate())
		state = steps.back()
	return steps

func undo() -> bool:
	if history.is_empty(): return false
	state = history.pop_back()
	return true

func delivered(current: Array) -> bool:
	return tile(current[0]) == "D" and current[1] == full

func hint() -> int:
	var queue := [[state, -1]]
	var seen := {state: true}
	var head := 0
	while head < queue.size():
		var node: Array = queue[head]
		head += 1
		for direction in 4:
			var path := trace(node[0], direction)
			if path.is_empty(): continue
			var last: Array = path.back()
			var first: int = direction if node[1] < 0 else node[1]
			if delivered(last): return first
			if not seen.has(last):
				seen[last] = true
				queue.append([last, first])
	return -1

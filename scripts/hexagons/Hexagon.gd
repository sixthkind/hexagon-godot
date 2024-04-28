# A hexagon in cube coordinates
class_name Hexagon extends Node3D

var grid_position: Vector3 # q, r, s

var world: World

func initialise(grid_position: Vector3, world: World) -> Hexagon:
	self.grid_position = grid_position
	self.world = world
	return self

func get_neighbour_positions() -> Array[Vector3]:
	var neighbours: Array[Vector3] = []
	neighbours.assign(HexagonUtils.neighbour_offsets.map(func(x): return grid_position + x))
	return neighbours
	
func get_neighbour_position(index: int) -> Vector3:
	return grid_position + HexagonUtils.get_neighbour_offset(index)

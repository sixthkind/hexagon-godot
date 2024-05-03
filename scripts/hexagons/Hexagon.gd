# A hexagon in cube coordinates
class_name Hexagon extends Node3D

var grid_position: Vector3 # q, r, s
var height: int = 0 # amount of tiles high
var terrain_type: TerrainType

var world: World

func initialise(grid_position: Vector3, terrain_type: TerrainType, world: World) -> Hexagon:
	self.grid_position = grid_position
	self.terrain_type = terrain_type
	self.world = world
	self.height = 0 if grid_position.length() > 3 else randi_range(0, 5)
	return self

func update_meshes():
	remove_meshes()
	place_meshes()
	update_collider()

func remove_meshes():
	for child: Node3D in find_child("Meshes").get_children():
		child.queue_free()

func place_meshes():
	var min_height: int = get_min_tile_height()
	var mesh_parent: Node3D = find_child("Meshes")
	
	# Place terrain meshes
	for h: int in range(min_height, self.height):
		var terrain_mesh: Node3D = self.terrain_type.terrain_mesh.instantiate()
		mesh_parent.add_child(terrain_mesh)
		terrain_mesh.position = Vector3(0, h, 0)
	
	# Place cover mesh
	var cover_mesh: Node3D = self.terrain_type.cover_mesh.instantiate()
	mesh_parent.add_child(cover_mesh)
	cover_mesh.position = Vector3(0, self.height, 0)
	
	# Place overhang meshes
	if self.terrain_type.overhang_mesh == null: return
	var neighbours: Array[Vector3] = get_neighbour_positions()
	
	for i: int in range(6):
		# Only create overhangs when neighbour is further down
		if neighbours[i] in world.hexagons and world.hexagons[neighbours[i]].height >= self.height:
			continue
		
		var overhang_mesh: Node3D = self.terrain_type.overhang_mesh.instantiate()
		mesh_parent.add_child(overhang_mesh)
		overhang_mesh.position = Vector3(0, self.height, 0)
		overhang_mesh.rotation = Vector3(0, HexagonUtils.edge_angles[i], 0)

func update_collider():
	var collider: CollisionPolygon3D = find_child("Collider")
	var height: float = self.height + HexagonUtils.COVER_HEIGHT
	collider.position = Vector3(0, height / 2, 0)
	collider.depth = height

func update_height(change: int):
	height += change
	height = clamp(height, 0, world.max_hexagon_height)

func get_min_tile_height() -> int:
	var min_height: int = TYPE_MAX
	
	for neighbour_position in get_neighbour_positions():
		if neighbour_position in world.hexagons:
			min_height = min(min_height, world.hexagons[neighbour_position].height)
		else:
			return 0 # atleast one side is not hidden
	
	return min_height

func get_neighbour_positions() -> Array[Vector3]:
	var neighbours: Array[Vector3] = []
	neighbours.assign(HexagonUtils.neighbour_offsets.map(func(x): return grid_position + x))
	return neighbours
	
func get_neighbour_position(index: int) -> Vector3:
	return grid_position + HexagonUtils.get_neighbour_offset(index)

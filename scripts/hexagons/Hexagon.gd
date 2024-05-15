# A hexagon in cube coordinates
class_name Hexagon extends Node3D

var grid_position: Vector3i # q, r, s
var height: int = 0 # amount of tiles high
var terrain_type: TerrainType
var has_decoration: bool

var world: World

func initialise(grid_position: Vector3i, terrain_type: TerrainType, has_decoration: bool, height: int, world: World) -> Hexagon:
	self.grid_position = grid_position
	self.terrain_type = terrain_type
	self.has_decoration = has_decoration
	self.world = world
	self.height = height
	return self

func update_meshes():
	remove_meshes()
	place_meshes()
	update_collider()

func remove_meshes():
	for child: Node3D in find_child("Meshes").get_children():
		child.queue_free()

func place_meshes():
	var mesh_parent: Node3D = find_child("Meshes")
	
	place_terrain_meshes(mesh_parent)
	place_cover_mesh(mesh_parent)
	place_overhang_meshes(mesh_parent)
	place_water_mesh(mesh_parent)
	place_decoration_mesh(mesh_parent)

func place_terrain_meshes(mesh_parent: Node3D):
	var min_height: int = get_min_tile_height()
	for h: int in range(min_height, self.height):
		var terrain_mesh: Node3D = self.terrain_type.terrain_mesh.instantiate()
		mesh_parent.add_child(terrain_mesh)
		terrain_mesh.position = Vector3i(0, h, 0)

func place_cover_mesh(mesh_parent: Node3D):
	var cover_mesh: Node3D = self.terrain_type.cover_mesh.instantiate()
	mesh_parent.add_child(cover_mesh)
	cover_mesh.position = Vector3i(0, self.height, 0)

func place_overhang_meshes(mesh_parent: Node3D):
	if self.terrain_type.overhang_mesh == null: return
	var neighbours: Array[Vector3i] = get_neighbour_positions()
	
	for i: int in range(6):
		# Only create overhangs when neighbour is further down
		if neighbours[i] in world.hexagons and world.hexagons[neighbours[i]].height >= self.height:
			continue
		
		var overhang_mesh: Node3D = self.terrain_type.overhang_mesh.instantiate()
		mesh_parent.add_child(overhang_mesh)
		overhang_mesh.position = Vector3i(0, self.height, 0)
		overhang_mesh.rotation = Vector3(0, HexagonUtils.edge_angles[i], 0)

func place_water_mesh(mesh_parent: Node3D):
	if self.height > world.water_height: return
	
	var water_mesh: Node3D = world.water_instance.instantiate()
	mesh_parent.add_child(water_mesh)
	water_mesh.position = Vector3(0, world.water_height, 0)

func place_decoration_mesh(mesh_parent: Node3D):
	if not self.terrain_type.decorations: return
	if not self.has_decoration: return
	
	var decoration: Decoration = self.terrain_type.get_decoration(self.height >= world.water_height)
	if not decoration: return
	
	var decoration_mesh: Node3D = decoration.mesh.instantiate()
	mesh_parent.add_child(decoration_mesh)
	
	# Random position
	var x_position: float = randf_range(-decoration.max_position_modifier, decoration.max_position_modifier)
	var z_position: float = randf_range(-decoration.max_position_modifier, decoration.max_position_modifier)
	decoration_mesh.position = Vector3(x_position, self.height + HexagonUtils.COVER_HEIGHT, z_position)
	
	# Random rotation
	if decoration.random_rotation:
		decoration_mesh.rotation = Vector3(0, randf_range(0, 2 * PI), 0)
	
	# Random scale
	var new_scale = randf_range(1 - decoration.max_scale_modifier, 1 + decoration.max_scale_modifier)
	decoration_mesh.scale = Vector3(new_scale, new_scale, new_scale)

func update_collider():
	var collider: CollisionPolygon3D = find_child("Collider")
	var height: float = self.height + HexagonUtils.COVER_HEIGHT
	collider.position = Vector3(0, height / 2, 0)
	collider.depth = height

func set_height(new_height: int, force: int):
	new_height = height + sign(new_height - height) * min(force, abs(new_height - height))
	self.height = clamp(new_height, 0, world.max_hexagon_height)

func update_height(change: int):
	set_height(height + change, TYPE_MAX)

func set_terrain_type(new_terrain_type: TerrainType):
	self.terrain_type = new_terrain_type
	update_meshes()

func set_decoration(decoration: bool):
	if len(self.terrain_type.decorations) == 0: return
	
	self.has_decoration = decoration
	update_meshes()

func get_min_tile_height() -> int:
	var min_height: int = TYPE_MAX
	
	for neighbour_position in get_neighbour_positions():
		if neighbour_position in world.hexagons:
			min_height = min(min_height, world.hexagons[neighbour_position].height)
		else:
			return 0 # atleast one side is not hidden
	
	return min_height

func get_neighbour_positions() -> Array[Vector3i]:
	var neighbours: Array[Vector3i] = []
	neighbours.assign(HexagonUtils.neighbour_offsets.map(func(x): return grid_position + x))
	return neighbours
	
func get_neighbour_position(index: int) -> Vector3i:
	return grid_position + HexagonUtils.get_neighbour_offset(index)

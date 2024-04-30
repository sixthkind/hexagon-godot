class_name World extends Node3D

@export_category("World Settings")
@export_range(0, 10) var hexagon_count: int = 3 # Radius of hexagons around center
@export_range(1, 20) var max_hexagon_height: int = 10

@export_category("Terrain")
@export var terrain_types: Array[TerrainType]

@export_group("Instances")
@export var hexagon_instance: PackedScene

var hexagons: Dictionary = {} # Key = cube position

func generate_map():
	if (verify_inputs()):
		generate_hexagons()

func verify_inputs() -> bool:
	if len(terrain_types) == 0:
		print("Invalid configuration: must have atleast 1 terrain type")
		return false
	
	return true

func generate_hexagons():
	# Generate honeycomb of hexagons
	for q: int in range(-hexagon_count, hexagon_count + 1):
		for r: int in range(-hexagon_count, hexagon_count + 1):
			if abs(-q-r) > hexagon_count: continue
			
			var hexagon_grid_position: Vector3 = Vector3(q, r, -q-r)
			var hexagon_global_position: Vector2 = HexagonUtils.get_world_position(hexagon_grid_position)
			var hexagon: Hexagon = hexagon_instance.instantiate().initialise(hexagon_grid_position, terrain_types[0], self)
			find_child("Hexagons").add_child(hexagon)
			hexagon.global_position = MathUtils.with_y(hexagon_global_position, 0)
			
			hexagons[hexagon_grid_position] = hexagon

	# Place meshes
	for hexagon: Hexagon in hexagons.values():
		hexagon.update_meshes()

func _ready():
	generate_map()

func _input(event):
	if event is InputEventMouseButton and event.pressed && event.button_index == MOUSE_BUTTON_LEFT:
		deform_terrain(event)

func deform_terrain(event: InputEventMouseButton):
	const SIZE: int = 1
	var force: int = -1 if event.shift_pressed else 1
	var mouse_position: Vector2 = get_viewport().get_mouse_position()
	var ray_origin: Vector3 = get_viewport().get_camera_3d().project_ray_origin(mouse_position)
	var ray_end: Vector3 = ray_origin + get_viewport().get_camera_3d().project_ray_normal(mouse_position) * 2000
	var intersection: Dictionary =  get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(ray_origin, ray_end, 1 << 3))
	
	if intersection:
		var hexagon_position: Vector3 = intersection["collider"].get_parent().grid_position
		var hexagons_to_update: Dictionary = {} # Used as set
		
		for q: int in range(hexagon_position.x - SIZE, hexagon_position.x + SIZE + 1):
			for r: int in range(hexagon_position.y - SIZE, hexagon_position.y + SIZE + 1):
				for s: int in range(hexagon_position.z - SIZE, hexagon_position.z + SIZE + 1):
					var update_position: Vector3 = Vector3(q, r, s)
					if update_position in hexagons:
						if (hexagons[update_position].height <= hexagons[hexagon_position].height and force > 0) or \
							(hexagons[update_position].height >= hexagons[hexagon_position].height and force < 0):
								hexagons[update_position].update_height(force)
								hexagons_to_update[update_position] = true
								
								for neighbour: Vector3 in hexagons[update_position].get_neighbour_positions():
									hexagons_to_update[neighbour] = true

		for update_position in hexagons_to_update.keys():
			if update_position in hexagons:
				hexagons[update_position].update_meshes()

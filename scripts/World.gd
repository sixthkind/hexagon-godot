class_name World extends Node3D

@export_category("World Settings")
@export_range(0, 10) var hexagon_count: int = 3 # Radius of hexagons around center

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
			print(hexagon_global_position)
			
			hexagons[hexagon_grid_position] = hexagon

	# Place meshes
	for hexagon: Hexagon in hexagons.values():
		hexagon.update_meshes()

func _ready():
	generate_map()

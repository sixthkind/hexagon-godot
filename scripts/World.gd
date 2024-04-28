class_name World extends Node3D

@export_category("World Settings")
@export var hexagon_size: float = 50
@export_range(0, 10) var hexagon_count: int = 3 # Radius of hexagons around center

@export_group("Instances")
@export var hexagon_instance: PackedScene

var hexagons: Dictionary = {} # Key = cube position

func generate_map():
	generate_hexagons()

func generate_hexagons():
	# Generate honeycomb of hexagons
	for q: int in range(-hexagon_count, hexagon_count + 1):
		for r: int in range(-hexagon_count, hexagon_count + 1):
			if abs(-q-r) > hexagon_count: continue
			
			var hexagon_grid_position: Vector3 = Vector3(q, r, -q-r)
			var hexagon_global_position: Vector2 = HexagonUtils.get_world_position(hexagon_grid_position)
			var hexagon: Hexagon = hexagon_instance.instantiate().initialise(hexagon_grid_position, self)
			find_child("Hexagons").add_child(hexagon)
			hexagon.global_position = MathUtils.with_y(hexagon_global_position, 0)
			
			hexagons[hexagon_grid_position] = hexagon

func _ready():
	generate_map()

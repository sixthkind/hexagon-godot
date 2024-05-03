class_name World extends Node3D

@export_category("World Settings")
@export_range(0, 10) var hexagon_count: int = 3 # Radius of hexagons around center
@export_range(1, 20) var max_hexagon_height: int = 10

@export_category("Terrain")
@export var terrain_types: Array[TerrainType]

@export_category("Edit mode")
@export_range(1, 5) var max_edit_size = 3

@export_group("Instances")
@export var hexagon_instance: PackedScene
@export var highlight_instance: PackedScene

var hexagons: Dictionary = {} # Key = cube position
var center_highlighted_hexagon_position: Vector3 = Vector3.INF
var highlighted_hexagon_positions: Array[Vector3] = []

enum Mode { View, Terrain, Decoration }
var mode: Mode = Mode.Terrain
var edit_size: int = 1
var selected_terrain_type: TerrainType
var selected_height: int = 0

func generate_map():
	if (verify_inputs()):
		generate_hexagons()

func verify_inputs() -> bool:
	if len(terrain_types) == 0:
		print("Invalid configuration: must have atleast 1 terrain type")
		return false
	
	selected_terrain_type = terrain_types[0]
	
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
			hexagon.position = MathUtils.with_y(hexagon_global_position, 0)
			hexagons[hexagon_grid_position] = hexagon

	# Place meshes
	for hexagon: Hexagon in hexagons.values():
		hexagon.update_meshes()

func _ready():
	generate_map()

func _input(event):
	if event is InputEventKey and event.is_pressed():
		keyboard_input(event)
	
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if mode != Mode.View:
				interact_terrain(event)
		elif event.button_index == MOUSE_BUTTON_MIDDLE:
			select_terrain()

func keyboard_input(event: InputEventKey):
	if event.keycode == KEY_UP:
		self.edit_size = min(self.edit_size + 1, self.max_edit_size)
	elif event.keycode == KEY_DOWN:
		self.edit_size = max(self.edit_size - 1, 0)
	elif event.keycode == KEY_LEFT:
		self.mode = wrap(self.mode - 1, 0, len(Mode.values()))
	elif event.keycode == KEY_RIGHT:
		self.mode = wrap(self.mode + 1, 0, len(Mode.values()))

func interact_terrain(event: InputEventMouseButton):
	if mode == Mode.Terrain:
		if event.ctrl_pressed:
			level_terrain()
		else:
			raise_terrain(-1 if event.shift_pressed else 1)
	elif mode == Mode.Decoration:
		if event.ctrl_pressed:
			set_decoration()
		else:
			change_decoration(-1 if event.shift_pressed else 1)

func level_terrain():
	var hexagons_to_update: Dictionary = {} # Used as set
	
	for highlighted_hexagon_position: Vector3 in highlighted_hexagon_positions:
		hexagons[highlighted_hexagon_position].set_height(selected_height, 1)
		hexagons_to_update[highlighted_hexagon_position] = true
		
		for neighbour: Vector3 in hexagons[highlighted_hexagon_position].get_neighbour_positions():
			hexagons_to_update[neighbour] = true

	for update_position in hexagons_to_update.keys():
		if update_position in hexagons:
			hexagons[update_position].update_meshes()

func raise_terrain(force: int):
	var hexagons_to_update: Dictionary = {} # Used as set
	
	for highlighted_hexagon_position: Vector3 in highlighted_hexagon_positions:
		if (hexagons[highlighted_hexagon_position].height <= hexagons[center_highlighted_hexagon_position].height and force > 0) or \
			(hexagons[highlighted_hexagon_position].height >= hexagons[center_highlighted_hexagon_position].height and force < 0):
				hexagons[highlighted_hexagon_position].update_height(force)
				hexagons_to_update[highlighted_hexagon_position] = true
				
				for neighbour: Vector3 in hexagons[highlighted_hexagon_position].get_neighbour_positions():
					hexagons_to_update[neighbour] = true

		for update_position in hexagons_to_update.keys():
			if update_position in hexagons:
				hexagons[update_position].update_meshes()

func set_decoration():
	for highlighted_hexagon_position: Vector3 in highlighted_hexagon_positions:
		hexagons[highlighted_hexagon_position].set_terrain_type(selected_terrain_type)

func change_decoration(index_change: int):
	for highlighted_hexagon_position: Vector3 in highlighted_hexagon_positions:
		var new_terrain_type_index: int = wrap(terrain_types.find(hexagons[highlighted_hexagon_position].terrain_type) + index_change, 0, len(terrain_types))
		hexagons[highlighted_hexagon_position].set_terrain_type(terrain_types[new_terrain_type_index])

func select_terrain():
	if mode == Mode.View: return
	
	# Find highlighted hexagon
	var mouse_position: Vector2 = get_viewport().get_mouse_position()
	var ray_origin: Vector3 = get_viewport().get_camera_3d().project_ray_origin(mouse_position)
	var ray_end: Vector3 = ray_origin + get_viewport().get_camera_3d().project_ray_normal(mouse_position) * 2000
	var intersection: Dictionary =  get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(ray_origin, ray_end, 1 << 3))
	
	if intersection:
		var highlighted_hexagon: Hexagon = intersection["collider"].get_parent()
		
		if mode == Mode.Terrain:
			selected_height = highlighted_hexagon.height
		elif mode == Mode.Decoration:
			selected_terrain_type = highlighted_hexagon.terrain_type

func _process(_delta):
	update_highlight()

func update_highlight():
	# Find highlighted hexagon
	var mouse_position: Vector2 = get_viewport().get_mouse_position()
	var ray_origin: Vector3 = get_viewport().get_camera_3d().project_ray_origin(mouse_position)
	var ray_end: Vector3 = ray_origin + get_viewport().get_camera_3d().project_ray_normal(mouse_position) * 2000
	var intersection: Dictionary =  get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(ray_origin, ray_end, 1 << 3))
	
	highlighted_hexagon_positions = []
	
	if intersection and mode != Mode.View:
		center_highlighted_hexagon_position = intersection["collider"].get_parent().grid_position

		for q: int in range(center_highlighted_hexagon_position.x - edit_size, center_highlighted_hexagon_position.x + edit_size + 1):
			for r: int in range(center_highlighted_hexagon_position.y - edit_size, center_highlighted_hexagon_position.y + edit_size + 1):
				for s: int in range(center_highlighted_hexagon_position.z - edit_size, center_highlighted_hexagon_position.z + edit_size + 1):
					var highlight_position: Vector3 = Vector3(q, r, s)
					if highlight_position in hexagons:
						highlighted_hexagon_positions.push_back(highlight_position)
	else:
		center_highlighted_hexagon_position = Vector3.INF
		
		for child: Node3D in find_child("Highlight").get_children():
			child.queue_free()
		
		return
	
	# Update meshes
	var highlight_meshes: Node3D = find_child("Highlight")

	for i: int in range(max(highlight_meshes.get_child_count(), len(highlighted_hexagon_positions))):
		# Add mesh
		if i > highlight_meshes.get_child_count() - 1:
			var new_highlight_mesh = highlight_instance.instantiate()
			highlight_meshes.add_child(new_highlight_mesh)
		
		# Set position
		if i < len(highlighted_hexagon_positions):
			var highlight_height: float = hexagons[highlighted_hexagon_positions[i]].height + HexagonUtils.COVER_HEIGHT
			var highlight_position: Vector3 = MathUtils.with_y(HexagonUtils.get_world_position(highlighted_hexagon_positions[i]), highlight_height)
			highlight_meshes.get_child(i).position = highlight_position
		
		# Remove mesh
		if i >= len(highlighted_hexagon_positions):
			highlight_meshes.get_child(-1).queue_free()

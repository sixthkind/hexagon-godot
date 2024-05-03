class_name TerrainType extends Resource

@export var name: String

@export_category("Decoration")
@export var decoration_mesh: PackedScene
@export_range(0, 0.3) var max_position_modifier: float = 0.1
@export_range(0, 0.5) var max_scale_modifier: float = 0.2
@export var random_rotation: bool = true
@export var place_decoration_underwater: bool = false

@export_group("References")
@export var cover_mesh: PackedScene
@export var overhang_mesh: PackedScene
@export var terrain_mesh: PackedScene

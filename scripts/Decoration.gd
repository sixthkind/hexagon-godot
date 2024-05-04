class_name Decoration extends Resource

@export var mesh: PackedScene
@export_range(1, 10) var weight = 1
@export_range(0, 0.3) var max_position_modifier: float = 0.2
@export_range(0, 0.5) var max_scale_modifier: float = 0.25
@export var random_rotation: bool = true

enum UnderwaterStrategy { Ignore, AboveOnly, BelowOnly }
@export var underwater_strategy: UnderwaterStrategy = UnderwaterStrategy.AboveOnly

class_name TerrainType extends Resource

@export var name: String
@export var decorations: Array[Decoration]

@export_group("References")
@export var cover_mesh: PackedScene
@export var overhang_mesh: PackedScene
@export var terrain_mesh: PackedScene

func get_total_weight(above_water: bool) -> Array:
	var total_weight: int = 0
	var filted_decorations: Array[Decoration] = []
	
	for decoration in decorations:
		if decoration.underwater_strategy == Decoration.UnderwaterStrategy.Ignore or \
		(decoration.underwater_strategy == Decoration.UnderwaterStrategy.AboveOnly and above_water) or \
		(decoration.underwater_strategy == Decoration.UnderwaterStrategy.BelowOnly and not above_water):
			total_weight += decoration.weight
			filted_decorations.push_back(decoration)
	
	return [filted_decorations, total_weight]

func get_decoration(above_water: bool) -> Decoration:
	var results: Array = get_total_weight(above_water)
	var filtered_decorations: Array[Decoration] = results[0]
	var randomized_value: int = randi_range(0, results[1])
	var decoration_index: int = 0
	
	if len(filtered_decorations) == 0: return null
	
	while randomized_value > filtered_decorations[decoration_index].weight:
		randomized_value -= filtered_decorations[decoration_index].weight
		decoration_index += 1
		
		if decoration_index >= len(filtered_decorations):
			return null
	
	return filtered_decorations[decoration_index]

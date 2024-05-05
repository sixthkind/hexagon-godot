extends Label

func _ready():
	Signals.mode_update.connect(mode_updated)
	mode_updated(World.Mode.Terrain)

func mode_updated(mode: World.Mode):
	if mode == World.Mode.View:
		text = "Mode: View"
	elif mode == World.Mode.Terrain:
		text = "Mode: Terrain"
	elif mode == World.Mode.TerrainType:
		text = "Mode: Biome"
	elif mode == World.Mode.Decoration:
		text = "Mode: Decoration"

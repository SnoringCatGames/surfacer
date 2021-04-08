tool
class_name SurfacesTileMap
extends TileMap

export var id: String

func _init() -> void:
    add_to_group(Surfacer.group_name_surfaces)

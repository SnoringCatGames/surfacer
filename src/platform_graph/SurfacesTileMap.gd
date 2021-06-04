tool
class_name SurfacesTileMap
extends TileMap

const GROUP_NAME_SURFACES := "surfaces"

export var id: String


func _init() -> void:
    add_to_group(GROUP_NAME_SURFACES)

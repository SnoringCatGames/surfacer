tool
class_name TilemapWithManyAngles
extends SurfacesTilemap


const DEFAULT_TILE_SET := preload( \
        "res://addons/surfacer/src/tiles/tileset_with_many_angles.tres")


func _ready() -> void:
    if tile_set == null or \
            tile_set == Su.default_tileset:
        tile_set = DEFAULT_TILE_SET

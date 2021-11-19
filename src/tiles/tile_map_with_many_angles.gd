tool
class_name TileMapWithManyAngles
extends SurfacesTileMap


const DEFAULT_TILE_SET := preload( \
        "res://addons/surfacer/src/tiles/tile_set_with_many_angles.tres")


func _ready() -> void:
    if tile_set == null or \
            tile_set == Su.default_tile_set:
        tile_set = DEFAULT_TILE_SET

class_name CollisionTileMapCoordResult
extends Reference


# In case the Player is colliding with multiple sides, this should indicate
# which side tile_map_coord corresponds to.
var surface_side := SurfaceSide.NONE

var tile_map_coord := Vector2.INF

var error_message := ""


func reset() -> void:
    self.surface_side = SurfaceSide.NONE
    self.tile_map_coord = Vector2.INF
    self.error_message = ""

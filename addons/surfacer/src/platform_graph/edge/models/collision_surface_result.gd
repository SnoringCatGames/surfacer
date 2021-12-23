class_name CollisionSurfaceResult
extends Reference


# In case the SurfacerCharacter is colliding with multiple sides, this should
# indicate which side tile_map_coord corresponds to.
var surface_side := SurfaceSide.NONE

var surface: Surface

var tile_map_coord := Vector2.INF

var tile_map_index := -1

var flipped_sides_for_nested_call := false

var error_message := ""


func reset() -> void:
    self.surface_side = SurfaceSide.NONE
    self.surface = null
    self.tile_map_coord = Vector2.INF
    self.tile_map_index = -1
    self.flipped_sides_for_nested_call = false
    self.error_message = ""

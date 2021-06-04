class_name CollisionTileMapCoordResult
extends Reference


# Sometimes Godot's collision engine can generate incorrect (opposite
# direction) results for is_on_floor/is_on_ceiling when the player is sliding
# along a corner. We attempt to detect such cases and record them here.
var is_godot_floor_ceiling_detection_correct := true

# In case the Player is colliding with multiple sides, this should indicate
# which side tile_map_coord corresponds to.
var surface_side := SurfaceSide.NONE

var tile_map_coord := Vector2.INF

var error_message := ""


func reset() -> void:
    self.is_godot_floor_ceiling_detection_correct = true
    self.surface_side = SurfaceSide.NONE
    self.tile_map_coord = Vector2.INF
    self.error_message = ""

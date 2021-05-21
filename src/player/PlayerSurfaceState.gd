class_name PlayerSurfaceState
extends Reference

var is_touching_floor := false
var is_touching_ceiling := false
var is_touching_left_wall := false
var is_touching_right_wall := false
var is_touching_wall := false
var is_touching_a_surface := false

var just_touched_floor := false
var just_stopped_touching_floor := false
var just_touched_ceiling := false
var just_stopped_touching_ceiling := false
var just_touched_wall := false
var just_stopped_touching_wall := false
var just_touched_a_surface := false
var just_stopped_touching_a_surface := false

var is_grabbing_floor := false
var is_grabbing_ceiling := false
var is_grabbing_left_wall := false
var is_grabbing_right_wall := false
var is_grabbing_wall := false
var is_grabbing_a_surface := false

var just_grabbed_floor := false
var just_grabbed_ceiling := false
var just_grabbed_left_wall := false
var just_grabbed_right_wall := false
var just_grabbed_a_surface := false

var is_facing_wall := false
var is_pressing_into_wall := false
var is_pressing_away_from_wall := false

var is_triggering_wall_grab := false
var is_triggering_fall_through := false
var is_falling_through_floors := false
var is_grabbing_walk_through_walls := false

var which_wall: int = SurfaceSide.NONE

var center_position := Vector2.INF
var previous_center_position := Vector2.INF
var collision_count: int
var grab_position := Vector2.INF
var collision_tile_map_coord_result := CollisionTileMapCoordResult.new()
var grab_position_tile_map_coord := Vector2.INF
var grabbed_tile_map: SurfacesTileMap
var grabbed_tile_map_index: int
var grabbed_surface: Surface
var previous_grabbed_surface: Surface
# SurfaceSide
var grabbed_side: int
var grabbed_surface_normal := Vector2.INF
var center_position_along_surface := PositionAlongSurface.new()

var velocity := Vector2.INF

var just_changed_surface := false
var just_changed_tile_map := false
var just_changed_tile_map_coord := false
var just_changed_grab_position := false
var just_entered_air := false
var just_left_air := false

var horizontal_facing_sign := -1
var horizontal_acceleration_sign := 0
var toward_wall_sign := 0

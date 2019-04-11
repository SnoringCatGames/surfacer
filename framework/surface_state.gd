extends Reference
class_name SurfaceState

var is_touching_floor := false
var is_touching_ceiling := false
var is_touching_left_wall := false
var is_touching_right_wall := false
var is_touching_wall := false
var is_touching_a_surface := false

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

var which_wall := "none"

var grab_position: Vector2
var grab_position_tile_map_coord: Vector2
var grabbed_tile_map: TileMap
var grabbed_surface: PoolVector2Array
# "floor"|"ceiling"|"left_wall"|"right_wall"|"none"
var grabbed_side: String

var just_changed_surface := false
var just_changed_tile_map := false
var just_changed_tile_map_coord := false
var just_changed_grab_position := false
var just_entered_air := false
var just_left_air := false

var horizontal_facing_sign := -1
var horizontal_movement_sign := 0
var toward_wall_sign := 0

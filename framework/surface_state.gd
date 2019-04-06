extends Reference
class_name SurfaceState

var horizontal_facing_sign := -1
var horizontal_movement_sign := 0
var toward_wall_sign := 0

var which_wall := "none"
var is_on_floor := false
var is_touching_ceiling := false
var is_touching_wall := false
var is_touching_left_wall := false
var is_touching_right_wall := false

var is_facing_wall := false
var is_pressing_into_wall := false
var is_pressing_away_from_wall := false

var is_triggering_wall_grab := false
var is_triggering_fall_through := false
var is_grabbing_wall := false
var is_falling_through_floors := false
var is_grabbing_walk_through_walls := false

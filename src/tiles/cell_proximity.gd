class_name CellProximity
extends Reference


var position: Vector2
var bitmask: int

var is_top_left_neighbor_exposed_at_top_left: bool
var is_top_neighbor_exposed_at_top: bool
var is_top_right_neighbor_exposed_at_top_right: bool
var is_left_neighbor_exposed_at_left: bool
var is_right_neighbor_exposed_at_right: bool
var is_bottom_left_neighbor_exposed_at_bottom_left: bool
var is_bottom_neighbor_exposed_at_bottom: bool
var is_bottom_right_neighbor_exposed_at_bottom_right: bool

var angle_type := CellAngleType.UNKNOWN
var top_neighbor_angle_type := CellAngleType.UNKNOWN
var bottom_neighbor_angle_type := CellAngleType.UNKNOWN
var left_neighbor_angle_type := CellAngleType.UNKNOWN
var right_neighbor_angle_type := CellAngleType.UNKNOWN

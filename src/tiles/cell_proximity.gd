class_name CellProximity
extends Reference


const FULLY_INTERNAL_BITMASK := \
        TileSet.BIND_TOPLEFT | \
        TileSet.BIND_TOP | \
        TileSet.BIND_TOPRIGHT | \
        TileSet.BIND_LEFT | \
        TileSet.BIND_RIGHT | \
        TileSet.BIND_BOTTOMLEFT | \
        TileSet.BIND_BOTTOM | \
        TileSet.BIND_BOTTOMRIGHT
const ALL_SIDES_BITMASK := \
        TileSet.BIND_TOP | \
        TileSet.BIND_LEFT | \
        TileSet.BIND_RIGHT | \
        TileSet.BIND_BOTTOM

var tile_map: SurfacesTileMap
var tile_set: SurfacesTileSet

var position: Vector2
var tile_id: int
var angle_type: int
var bitmask: int

# FIXME: LEFT OFF HERE: ---------- Remove any unused members.

var is_fully_internal: bool \
        setget ,_get_is_fully_internal
var are_all_sides_covered: bool \
        setget ,_get_are_all_sides_covered

var top_left_angle_type: int \
        setget ,_get_top_left_angle_type
var top_angle_type: int \
        setget ,_get_top_angle_type
var top_right_angle_type: int \
        setget ,_get_top_right_angle_type
var left_angle_type: int \
        setget ,_get_left_angle_type
var right_angle_type: int \
        setget ,_get_right_angle_type
var bottom_left_angle_type: int \
        setget ,_get_bottom_left_angle_type
var bottom_angle_type: int \
        setget ,_get_bottom_angle_type
var bottom_right_angle_type: int \
        setget ,_get_bottom_right_angle_type

var is_angle_type_90: bool \
        setget ,_get_is_angle_type_90
var is_angle_type_45: bool \
        setget ,_get_is_angle_type_45
var is_angle_type_27: bool \
        setget ,_get_is_angle_type_27

var is_top_left_empty: bool setget ,_get_is_top_left_empty
var is_top_empty: bool setget ,_get_is_top_empty
var is_top_right_empty: bool setget ,_get_is_top_right_empty
var is_left_empty: bool setget ,_get_is_left_empty
var is_right_empty: bool setget ,_get_is_right_empty
var is_bottom_left_empty: bool setget ,_get_is_bottom_left_empty
var is_bottom_empty: bool setget ,_get_is_bottom_empty
var is_bottom_right_empty: bool setget ,_get_is_bottom_right_empty

var is_top_or_left_empty: bool setget ,_get_is_top_or_left_empty
var is_top_or_right_empty: bool setget ,_get_is_top_or_right_empty
var is_bottom_or_left_empty: bool setget ,_get_is_bottom_or_left_empty
var is_bottom_or_right_empty: bool setget ,_get_is_bottom_or_right_empty

var is_empty_around_top_left: bool \
        setget ,_get_is_empty_around_top_left
var is_empty_around_top_right: bool \
        setget ,_get_is_empty_around_top_right
var is_empty_around_bottom_left: bool \
        setget ,_get_is_empty_around_bottom_left
var is_empty_around_bottom_right: bool \
        setget ,_get_is_empty_around_bottom_right

var is_top_left_empty_at_top_left: bool \
        setget ,_get_is_top_left_empty_at_top_left
var is_top_empty_at_top: bool \
        setget ,_get_is_top_empty_at_top
var is_top_right_empty_at_top_right: bool \
        setget ,_get_is_top_right_empty_at_top_right
var is_left_empty_at_left: bool \
        setget ,_get_is_left_empty_at_left
var is_right_empty_at_right: bool \
        setget ,_get_is_right_empty_at_right
var is_bottom_left_empty_at_bottom_left: bool \
        setget ,_get_is_bottom_left_empty_at_bottom_left
var is_bottom_empty_at_bottom: bool \
        setget ,_get_is_bottom_empty_at_bottom
var is_bottom_right_empty_at_bottom_right: bool \
        setget ,_get_is_bottom_right_empty_at_bottom_right

var is_top_left_empty_at_top_or_left: bool \
        setget ,_get_is_top_left_empty_at_top_or_left
var is_top_right_empty_at_top_or_right: bool \
        setget ,_get_is_top_right_empty_at_top_or_right
var is_bottom_left_empty_at_bottom_or_left: bool \
        setget ,_get_is_bottom_left_empty_at_bottom_or_left
var is_bottom_right_empty_at_bottom_or_right: bool \
        setget ,_get_is_bottom_right_empty_at_bottom_or_right

var is_top_empty_around_top: bool \
        setget ,_get_is_top_empty_around_top
var is_bottom_empty_around_bottom: bool \
        setget ,_get_is_bottom_empty_around_bottom
var is_left_empty_around_left: bool \
        setget ,_get_is_left_empty_around_left
var is_right_empty_around_right: bool \
        setget ,_get_is_right_empty_around_right

var is_top_left_empty_around_top_left: bool \
        setget ,_get_is_top_left_empty_around_top_left
var is_top_right_empty_around_top_right: bool \
        setget ,_get_is_top_right_empty_around_top_right
var is_bottom_left_empty_around_bottom_left: bool \
        setget ,_get_is_bottom_left_empty_around_bottom_left
var is_bottom_right_empty_around_bottom_right: bool \
        setget ,_get_is_bottom_right_empty_around_bottom_right

var is_45_pos_floor: bool \
        setget ,_get_is_45_pos_floor
var is_45_neg_floor: bool \
        setget ,_get_is_45_neg_floor
var is_45_pos_ceiling: bool \
        setget ,_get_is_45_pos_ceiling
var is_45_neg_ceiling: bool \
        setget ,_get_is_45_neg_ceiling

var is_27_shallow_pos_floor: bool \
        setget ,_get_is_27_shallow_pos_floor
var is_27_shallow_neg_floor: bool \
        setget ,_get_is_27_shallow_neg_floor
var is_27_shallow_pos_ceiling: bool \
        setget ,_get_is_27_shallow_pos_ceiling
var is_27_shallow_neg_ceiling: bool \
        setget ,_get_is_27_shallow_neg_ceiling

var is_27_steep_pos_floor: bool \
        setget ,_get_is_27_steep_pos_floor
var is_27_steep_neg_floor: bool \
        setget ,_get_is_27_steep_neg_floor
var is_27_steep_pos_ceiling: bool \
        setget ,_get_is_27_steep_pos_ceiling
var is_27_steep_neg_ceiling: bool \
        setget ,_get_is_27_steep_neg_ceiling

var is_top_45_pos: bool \
        setget ,_get_is_top_45_pos
var is_top_45_neg: bool \
        setget ,_get_is_top_45_neg
var is_bottom_45_pos: bool \
        setget ,_get_is_bottom_45_pos
var is_bottom_45_neg: bool \
        setget ,_get_is_bottom_45_neg
var is_left_45_pos: bool \
        setget ,_get_is_left_45_pos
var is_left_45_neg: bool \
        setget ,_get_is_left_45_neg
var is_right_45_pos: bool \
        setget ,_get_is_right_45_pos
var is_right_45_neg: bool \
        setget ,_get_is_right_45_neg

var is_top_27_shallow_pos: bool \
        setget ,_get_is_top_27_shallow_pos
var is_top_27_shallow_neg: bool \
        setget ,_get_is_top_27_shallow_neg
var is_bottom_27_shallow_pos: bool \
        setget ,_get_is_bottom_27_shallow_pos
var is_bottom_27_shallow_neg: bool \
        setget ,_get_is_bottom_27_shallow_neg
var is_left_27_shallow_pos: bool \
        setget ,_get_is_left_27_shallow_pos
var is_left_27_shallow_neg: bool \
        setget ,_get_is_left_27_shallow_neg
var is_right_27_shallow_pos: bool \
        setget ,_get_is_right_27_shallow_pos
var is_right_27_shallow_neg: bool \
        setget ,_get_is_right_27_shallow_neg

var is_top_27_steep_pos: bool \
        setget ,_get_is_top_27_steep_pos
var is_top_27_steep_neg: bool \
        setget ,_get_is_top_27_steep_neg
var is_bottom_27_steep_pos: bool \
        setget ,_get_is_bottom_27_steep_pos
var is_bottom_27_steep_neg: bool \
        setget ,_get_is_bottom_27_steep_neg
var is_left_27_steep_pos: bool \
        setget ,_get_is_left_27_steep_pos
var is_left_27_steep_neg: bool \
        setget ,_get_is_left_27_steep_neg
var is_right_27_steep_pos: bool \
        setget ,_get_is_right_27_steep_pos
var is_right_27_steep_neg: bool \
        setget ,_get_is_right_27_steep_neg

var is_top_cap: bool \
        setget ,_get_is_top_cap
var is_bottom_cap: bool \
        setget ,_get_is_bottom_cap
var is_left_cap: bool \
        setget ,_get_is_left_cap
var is_right_cap: bool \
        setget ,_get_is_right_cap

var is_90_floor: bool \
        setget ,_get_is_90_floor
var is_90_ceiling: bool \
        setget ,_get_is_90_ceiling
var is_90_left_wall: bool \
        setget ,_get_is_90_left_wall
var is_90_right_wall: bool \
        setget ,_get_is_90_right_wall

var is_floor_with_45_curve_in_at_left: bool \
        setget ,_get_is_floor_with_45_curve_in_at_left
var is_floor_with_45_curve_in_at_right: bool \
        setget ,_get_is_floor_with_45_curve_in_at_right
var is_ceiling_with_45_curve_in_at_left: bool \
        setget ,_get_is_ceiling_with_45_curve_in_at_left
var is_ceiling_with_45_curve_in_at_right: bool \
        setget ,_get_is_ceiling_with_45_curve_in_at_right
var is_left_wall_with_45_curve_in_at_top: bool \
        setget ,_get_is_left_wall_with_45_curve_in_at_top
var is_left_wall_with_45_curve_in_at_bottom: bool \
        setget ,_get_is_left_wall_with_45_curve_in_at_bottom
var is_right_wall_with_45_curve_in_at_top: bool \
        setget ,_get_is_right_wall_with_45_curve_in_at_top
var is_right_wall_with_45_curve_in_at_bottom: bool \
        setget ,_get_is_right_wall_with_45_curve_in_at_bottom

var is_top_90_left_wall: bool \
        setget ,_get_is_top_90_left_wall
var is_bottom_90_left_wall: bool \
        setget ,_get_is_bottom_90_left_wall
var is_top_90_right_wall: bool \
        setget ,_get_is_top_90_right_wall
var is_bottom_90_right_wall: bool \
        setget ,_get_is_bottom_90_right_wall
var is_left_90_floor: bool \
        setget ,_get_is_left_90_floor
var is_right_90_floor: bool \
        setget ,_get_is_right_90_floor
var is_left_90_ceiling: bool \
        setget ,_get_is_left_90_ceiling
var is_right_90_ceiling: bool \
        setget ,_get_is_right_90_ceiling

var is_top_left_corner_concave_90: bool \
        setget ,_get_is_top_left_corner_concave_90
var is_top_right_corner_concave_90: bool \
        setget ,_get_is_top_right_corner_concave_90
var is_bottom_left_corner_concave_90: bool \
        setget ,_get_is_bottom_left_corner_concave_90
var is_bottom_right_corner_concave_90: bool \
        setget ,_get_is_bottom_right_corner_concave_90

var is_top_left_corner_concave_45: bool \
        setget ,_get_is_top_left_corner_concave_45
var is_top_right_corner_concave_45: bool \
        setget ,_get_is_top_right_corner_concave_45
var is_bottom_left_corner_concave_45: bool \
        setget ,_get_is_bottom_left_corner_concave_45
var is_bottom_right_corner_concave_45: bool \
        setget ,_get_is_bottom_right_corner_concave_45

var is_top_left_corner_concave_partial_45: bool \
        setget ,_get_is_top_left_corner_concave_partial_45
var is_top_right_corner_concave_partial_45: bool \
        setget ,_get_is_top_right_corner_concave_partial_45
var is_bottom_left_corner_concave_partial_45: bool \
        setget ,_get_is_bottom_left_corner_concave_partial_45
var is_bottom_right_corner_concave_partial_45: bool \
        setget ,_get_is_bottom_right_corner_concave_partial_45
var is_any_corner_concave_partial_45: bool \
        setget ,_get_is_any_corner_concave_partial_45

var is_top_left_corner_concave_90_vertical_to_45: bool \
        setget ,_get_is_top_left_corner_concave_90_vertical_to_45
var is_top_right_corner_concave_90_vertical_to_45: bool \
        setget ,_get_is_top_right_corner_concave_90_vertical_to_45
var is_bottom_left_corner_concave_90_vertical_to_45: bool \
        setget ,_get_is_bottom_left_corner_concave_90_vertical_to_45
var is_bottom_right_corner_concave_90_vertical_to_45: bool \
        setget ,_get_is_bottom_right_corner_concave_90_vertical_to_45

var is_top_left_corner_concave_90_horizontal_to_45: bool \
        setget ,_get_is_top_left_corner_concave_90_horizontal_to_45
var is_top_right_corner_concave_90_horizontal_to_45: bool \
        setget ,_get_is_top_right_corner_concave_90_horizontal_to_45
var is_bottom_left_corner_concave_90_horizontal_to_45: bool \
        setget ,_get_is_bottom_left_corner_concave_90_horizontal_to_45
var is_bottom_right_corner_concave_90_horizontal_to_45: bool \
        setget ,_get_is_bottom_right_corner_concave_90_horizontal_to_45


func _init(
        tile_map: SurfacesTileMap,
        tile_set: SurfacesTileSet,
        position: Vector2,
        tile_id: int,
        bitmask: int) -> void:
    self.tile_map = tile_map
    self.tile_set = tile_set
    self.position = position
    self.tile_id = tile_id
    self.bitmask = bitmask
    self.angle_type = get_neighbor_angle_type(0,0)


func get_neighbor_angle_type(relative_x: int, relative_y: int) -> int:
    var neighbor_id := tile_map.get_cell(
            position.x + relative_x,
            position.y + relative_y)
    return tile_set.tile_get_neighbor_angle_type(neighbor_id)


func get_is_neighbor_present(relative_x: int, relative_y: int) -> bool:
    var neighbor_id := tile_map.get_cell(
            position.x + relative_x,
            position.y + relative_y)
    return tile_set._is_tile_bound(tile_id, neighbor_id)


func get_is_neighbor_empty(relative_x: int, relative_y: int) -> bool:
    var neighbor_id := tile_map.get_cell(
            position.x + relative_x,
            position.y + relative_y)
    return !tile_set._is_tile_bound(tile_id, neighbor_id)


func _get_is_fully_internal() -> bool:
    return bitmask == FULLY_INTERNAL_BITMASK


func _get_are_all_sides_covered() -> bool:
    return (bitmask ^ ALL_SIDES_BITMASK) == 0


func _get_top_left_angle_type() -> int:
    return get_neighbor_angle_type(-1,-1)


func _get_top_angle_type() -> int:
    return get_neighbor_angle_type(0,-1)


func _get_top_right_angle_type() -> int:
    return get_neighbor_angle_type(1,-1)


func _get_left_angle_type() -> int:
    return get_neighbor_angle_type(-1,0)


func _get_right_angle_type() -> int:
    return get_neighbor_angle_type(1,0)


func _get_bottom_left_angle_type() -> int:
    return get_neighbor_angle_type(-1,1)


func _get_bottom_angle_type() -> int:
    return get_neighbor_angle_type(0,1)


func _get_bottom_right_angle_type() -> int:
    return get_neighbor_angle_type(1,1)


func _get_is_angle_type_90() -> bool:
    return angle_type == CellAngleType.A90


func _get_is_angle_type_45() -> bool:
    return angle_type == CellAngleType.A45


func _get_is_angle_type_27() -> bool:
    return angle_type == CellAngleType.A27


func _get_is_top_left_present() -> bool:
    return !!(bitmask & TileSet.BIND_TOPLEFT)


func _get_is_top_present() -> bool:
    return !!(bitmask & TileSet.BIND_TOP)


func _get_is_top_right_present() -> bool:
    return !!(bitmask & TileSet.BIND_TOPRIGHT)


func _get_is_left_present() -> bool:
    return !!(bitmask & TileSet.BIND_LEFT)


func _get_is_right_present() -> bool:
    return !!(bitmask & TileSet.BIND_RIGHT)


func _get_is_bottom_left_present() -> bool:
    return !!(bitmask & TileSet.BIND_BOTTOMLEFT)


func _get_is_bottom_present() -> bool:
    return !!(bitmask & TileSet.BIND_BOTTOM)


func _get_is_bottom_right_present() -> bool:
    return !!(bitmask & TileSet.BIND_BOTTOMRIGHT)


func _get_is_top_left_empty() -> bool:
    return !(bitmask & TileSet.BIND_TOPLEFT)


func _get_is_top_empty() -> bool:
    return !(bitmask & TileSet.BIND_TOP)


func _get_is_top_right_empty() -> bool:
    return !(bitmask & TileSet.BIND_TOPRIGHT)


func _get_is_left_empty() -> bool:
    return !(bitmask & TileSet.BIND_LEFT)


func _get_is_right_empty() -> bool:
    return !(bitmask & TileSet.BIND_RIGHT)


func _get_is_bottom_left_empty() -> bool:
    return !(bitmask & TileSet.BIND_BOTTOMLEFT)


func _get_is_bottom_empty() -> bool:
    return !(bitmask & TileSet.BIND_BOTTOM)


func _get_is_bottom_right_empty() -> bool:
    return !(bitmask & TileSet.BIND_BOTTOMRIGHT)


func _get_is_top_or_left_empty() -> bool:
    return _get_is_top_empty() or \
            _get_is_left_empty()


func _get_is_top_or_right_empty() -> bool:
    return _get_is_top_empty() or \
            _get_is_right_empty()


func _get_is_bottom_or_left_empty() -> bool:
    return _get_is_bottom_empty() or \
            _get_is_left_empty()


func _get_is_bottom_or_right_empty() -> bool:
    return _get_is_bottom_empty() or \
            _get_is_right_empty()


func _get_is_empty_around_top_left() -> bool:
    return _get_is_top_left_empty() or \
            _get_is_top_empty() or \
            _get_is_left_empty()


func _get_is_empty_around_top_right() -> bool:
    return _get_is_top_right_empty() or \
            _get_is_top_empty() or \
            _get_is_right_empty()


func _get_is_empty_around_bottom_left() -> bool:
    return _get_is_bottom_left_empty() or \
            _get_is_bottom_empty() or \
            _get_is_left_empty()


func _get_is_empty_around_bottom_right() -> bool:
    return _get_is_bottom_right_empty() or \
            _get_is_bottom_empty() or \
            _get_is_right_empty()


func _get_is_top_left_empty_at_top_left() -> bool:
    return get_is_neighbor_empty(-2,-2)


func _get_is_top_empty_at_top() -> bool:
    return get_is_neighbor_empty(0,-2)


func _get_is_top_right_empty_at_top_right() -> bool:
    return get_is_neighbor_empty(2,-2)


func _get_is_left_empty_at_left() -> bool:
    return get_is_neighbor_empty(-2,0)


func _get_is_right_empty_at_right() -> bool:
    return get_is_neighbor_empty(2,0)


func _get_is_bottom_left_empty_at_bottom_left() -> bool:
    return get_is_neighbor_empty(-2,2)


func _get_is_bottom_empty_at_bottom() -> bool:
    return get_is_neighbor_empty(0,2)


func _get_is_bottom_right_empty_at_bottom_right() -> bool:
    return get_is_neighbor_empty(2,2)


func _get_is_top_left_empty_at_top_or_left() -> bool:
    return get_is_neighbor_empty(-1,-2) or \
            get_is_neighbor_empty(-2,-1)


func _get_is_top_right_empty_at_top_or_right() -> bool:
    return get_is_neighbor_empty(1,-2) or \
            get_is_neighbor_empty(2,-1)


func _get_is_bottom_left_empty_at_bottom_or_left() -> bool:
    return get_is_neighbor_empty(-1,2) or \
            get_is_neighbor_empty(-2,1)


func _get_is_bottom_right_empty_at_bottom_or_right() -> bool:
    return get_is_neighbor_empty(1,2) or \
            get_is_neighbor_empty(2,1)


func _get_is_top_empty_around_top() -> bool:
    return get_is_neighbor_empty(-1,-2) or \
            get_is_neighbor_empty(0,-2) or \
            get_is_neighbor_empty(1,-2)


func _get_is_bottom_empty_around_bottom() -> bool:
    return get_is_neighbor_empty(-1,2) or \
            get_is_neighbor_empty(0,2) or \
            get_is_neighbor_empty(1,2)


func _get_is_left_empty_around_left() -> bool:
    return get_is_neighbor_empty(-2,-1) or \
            get_is_neighbor_empty(-2,0) or \
            get_is_neighbor_empty(-2,1)


func _get_is_right_empty_around_right() -> bool:
    return get_is_neighbor_empty(2,-1) or \
            get_is_neighbor_empty(2,0) or \
            get_is_neighbor_empty(2,1)


func _get_is_top_left_empty_around_top_left() -> bool:
    return get_is_neighbor_empty(-2,-2) or \
            get_is_neighbor_empty(-1,-2) or \
            get_is_neighbor_empty(-2,-1)


func _get_is_top_right_empty_around_top_right() -> bool:
    return get_is_neighbor_empty(2,-2) or \
            get_is_neighbor_empty(1,-2) or \
            get_is_neighbor_empty(2,-1)


func _get_is_bottom_left_empty_around_bottom_left() -> bool:
    return get_is_neighbor_empty(-2,2) or \
            get_is_neighbor_empty(-1,2) or \
            get_is_neighbor_empty(-2,1)


func _get_is_bottom_right_empty_around_bottom_right() -> bool:
    return get_is_neighbor_empty(2,2) or \
            get_is_neighbor_empty(1,2) or \
            get_is_neighbor_empty(2,1)


func _get_is_45_pos_floor() -> bool:
    return angle_type == CellAngleType.A45 and \
            _get_is_top_empty() and \
            _get_is_left_empty() and \
            _get_is_bottom_present() and \
            _get_is_right_present()


func _get_is_45_neg_floor() -> bool:
    return angle_type == CellAngleType.A45 and \
            _get_is_top_empty() and \
            _get_is_right_empty() and \
            _get_is_bottom_present() and \
            _get_is_left_present()


func _get_is_45_pos_ceiling() -> bool:
    return angle_type == CellAngleType.A45 and \
            _get_is_bottom_empty() and \
            _get_is_left_empty() and \
            _get_is_top_present() and \
            _get_is_right_present()


func _get_is_45_neg_ceiling() -> bool:
    return angle_type == CellAngleType.A45 and \
            _get_is_bottom_empty() and \
            _get_is_right_empty() and \
            _get_is_top_present() and \
            _get_is_left_present()


func _get_is_27_shallow_pos_floor() -> bool:
    # FIXME: LEFT OFF HERE: -----------------------
    return false


func _get_is_27_shallow_neg_floor() -> bool:
    # FIXME: LEFT OFF HERE: -----------------------
    return false


func _get_is_27_shallow_pos_ceiling() -> bool:
    # FIXME: LEFT OFF HERE: -----------------------
    return false


func _get_is_27_shallow_neg_ceiling() -> bool:
    # FIXME: LEFT OFF HERE: -----------------------
    return false


func _get_is_27_steep_pos_floor() -> bool:
    # FIXME: LEFT OFF HERE: -----------------------
    return false


func _get_is_27_steep_neg_floor() -> bool:
    # FIXME: LEFT OFF HERE: -----------------------
    return false


func _get_is_27_steep_pos_ceiling() -> bool:
    # FIXME: LEFT OFF HERE: -----------------------
    return false


func _get_is_27_steep_neg_ceiling() -> bool:
    # FIXME: LEFT OFF HERE: -----------------------
    return false


func _get_is_top_45_pos() -> bool:
    return _get_top_angle_type() == CellAngleType.A45 and \
            _get_is_top_present() and \
            _get_is_top_right_present() and \
            _get_is_top_left_empty() and \
            get_is_neighbor_empty(0,-2)


func _get_is_top_45_neg() -> bool:
    return _get_top_angle_type() == CellAngleType.A45 and \
            _get_is_top_present() and \
            _get_is_top_left_present() and \
            _get_is_top_right_empty() and \
            get_is_neighbor_empty(0,-2)


func _get_is_bottom_45_pos() -> bool:
    return _get_bottom_angle_type() == CellAngleType.A45 and \
            _get_is_bottom_present() and \
            _get_is_bottom_left_present() and \
            _get_is_bottom_right_empty() and \
            get_is_neighbor_empty(0,2)


func _get_is_bottom_45_neg() -> bool:
    return _get_bottom_angle_type() == CellAngleType.A45 and \
            _get_is_bottom_present() and \
            _get_is_bottom_right_present() and \
            _get_is_bottom_left_empty() and \
            get_is_neighbor_empty(0,2)


func _get_is_left_45_pos() -> bool:
    return _get_left_angle_type() == CellAngleType.A45 and \
            _get_is_left_present() and \
            _get_is_bottom_left_present() and \
            _get_is_top_left_empty() and \
            get_is_neighbor_empty(-2,0)


func _get_is_left_45_neg() -> bool:
    return _get_left_angle_type() == CellAngleType.A45 and \
            _get_is_left_present() and \
            _get_is_top_left_present() and \
            _get_is_bottom_left_empty() and \
            get_is_neighbor_empty(-2,0)


func _get_is_right_45_pos() -> bool:
    return _get_right_angle_type() == CellAngleType.A45 and \
            _get_is_right_present() and \
            _get_is_top_right_present() and \
            _get_is_bottom_right_empty() and \
            get_is_neighbor_empty(2,0)


func _get_is_right_45_neg() -> bool:
    return _get_right_angle_type() == CellAngleType.A45 and \
            _get_is_right_present() and \
            _get_is_bottom_right_present() and \
            _get_is_top_right_empty() and \
            get_is_neighbor_empty(2,0)


func _get_is_top_27_shallow_pos() -> bool:
    # FIXME: LEFT OFF HERE: -----------------------
    return false


func _get_is_top_27_shallow_neg() -> bool:
    # FIXME: LEFT OFF HERE: -----------------------
    return false


func _get_is_bottom_27_shallow_pos() -> bool:
    # FIXME: LEFT OFF HERE: -----------------------
    return false


func _get_is_bottom_27_shallow_neg() -> bool:
    # FIXME: LEFT OFF HERE: -----------------------
    return false


func _get_is_left_27_shallow_pos() -> bool:
    # FIXME: LEFT OFF HERE: -----------------------
    return false


func _get_is_left_27_shallow_neg() -> bool:
    # FIXME: LEFT OFF HERE: -----------------------
    return false


func _get_is_right_27_shallow_pos() -> bool:
    # FIXME: LEFT OFF HERE: -----------------------
    return false


func _get_is_right_27_shallow_neg() -> bool:
    # FIXME: LEFT OFF HERE: -----------------------
    return false


func _get_is_top_27_steep_pos() -> bool:
    # FIXME: LEFT OFF HERE: -----------------------
    return false


func _get_is_top_27_steep_neg() -> bool:
    # FIXME: LEFT OFF HERE: -----------------------
    return false


func _get_is_bottom_27_steep_pos() -> bool:
    # FIXME: LEFT OFF HERE: -----------------------
    return false


func _get_is_bottom_27_steep_neg() -> bool:
    # FIXME: LEFT OFF HERE: -----------------------
    return false


func _get_is_left_27_steep_pos() -> bool:
    # FIXME: LEFT OFF HERE: -----------------------
    return false


func _get_is_left_27_steep_neg() -> bool:
    # FIXME: LEFT OFF HERE: -----------------------
    return false


func _get_is_right_27_steep_pos() -> bool:
    # FIXME: LEFT OFF HERE: -----------------------
    return false


func _get_is_right_27_steep_neg() -> bool:
    # FIXME: LEFT OFF HERE: -----------------------
    return false


func _get_is_top_cap() -> bool:
    return _get_is_top_present() and \
            _get_is_top_left_empty() and \
            _get_is_top_right_empty() and \
            get_is_neighbor_empty(0,-2)


func _get_is_bottom_cap() -> bool:
    return _get_is_bottom_present() and \
            _get_is_bottom_left_empty() and \
            _get_is_bottom_right_empty() and \
            get_is_neighbor_empty(0,2)


func _get_is_left_cap() -> bool:
    return _get_is_left_present() and \
            _get_is_top_left_empty() and \
            _get_is_bottom_left_empty() and \
            get_is_neighbor_empty(-2,0)


func _get_is_right_cap() -> bool:
    return _get_is_right_present() and \
            _get_is_top_right_empty() and \
            _get_is_bottom_right_empty() and \
            get_is_neighbor_empty(2,0)


func _get_is_90_floor() -> bool:
    return _get_is_top_empty() and \
            (angle_type == CellAngleType.A90 or \
            _get_is_left_present() and \
            _get_is_right_present())


func _get_is_90_ceiling() -> bool:
    return _get_is_bottom_empty() and \
            (angle_type == CellAngleType.A90 or \
            _get_is_left_present() and \
            _get_is_right_present())


func _get_is_90_left_wall() -> bool:
    return _get_is_right_empty() and \
            (angle_type == CellAngleType.A90 or \
            _get_is_top_present() and \
            _get_is_bottom_present())


func _get_is_90_right_wall() -> bool:
    return _get_is_left_empty() and \
            (angle_type == CellAngleType.A90 or \
            _get_is_top_present() and \
            _get_is_bottom_present())


func _get_is_floor_with_45_curve_in_at_left() -> bool:
    return _get_is_right_present() and \
            _get_is_top_empty() and \
            _get_left_angle_type() == CellAngleType.A45 and \
            _get_is_top_left_empty() and \
            get_is_neighbor_empty(-2,0) and \
            _get_is_bottom_left_present()


func _get_is_floor_with_45_curve_in_at_right() -> bool:
    return _get_is_left_present() and \
            _get_is_top_empty() and \
            _get_right_angle_type() == CellAngleType.A45 and \
            _get_is_top_right_empty() and \
            get_is_neighbor_empty(2,0) and \
            _get_is_bottom_right_present()


func _get_is_ceiling_with_45_curve_in_at_left() -> bool:
    return _get_is_right_present() and \
            _get_is_bottom_empty() and \
            _get_left_angle_type() == CellAngleType.A45 and \
            _get_is_bottom_left_empty() and \
            get_is_neighbor_empty(-2,0) and \
            _get_is_top_left_present()


func _get_is_ceiling_with_45_curve_in_at_right() -> bool:
    return _get_is_left_present() and \
            _get_is_bottom_empty() and \
            _get_right_angle_type() == CellAngleType.A45 and \
            _get_is_bottom_right_empty() and \
            get_is_neighbor_empty(2,0) and \
            _get_is_top_right_present()


func _get_is_left_wall_with_45_curve_in_at_top() -> bool:
    return _get_is_bottom_present() and \
            _get_is_right_empty() and \
            _get_top_angle_type() == CellAngleType.A45 and \
            _get_is_top_right_empty() and \
            get_is_neighbor_empty(0,-2) and \
            (_get_is_top_left_present() or \
                _get_is_top_cap() and \
                    _get_is_left_empty())


func _get_is_left_wall_with_45_curve_in_at_bottom() -> bool:
    return _get_is_top_present() and \
            _get_is_right_empty() and \
            _get_bottom_angle_type() == CellAngleType.A45 and \
            _get_is_bottom_right_empty() and \
            get_is_neighbor_empty(0,2) and \
            (_get_is_bottom_left_present() or \
                _get_is_bottom_cap() and \
                    _get_is_left_empty())


func _get_is_right_wall_with_45_curve_in_at_top() -> bool:
    return _get_is_bottom_present() and \
            _get_is_left_empty() and \
            _get_top_angle_type() == CellAngleType.A45 and \
            _get_is_top_left_empty() and \
            get_is_neighbor_empty(0,-2) and \
            (_get_is_top_right_present() or \
                _get_is_top_cap() and \
                    _get_is_right_empty())


func _get_is_right_wall_with_45_curve_in_at_bottom() -> bool:
    return _get_is_top_present() and \
            _get_is_left_empty() and \
            _get_bottom_angle_type() == CellAngleType.A45 and \
            _get_is_bottom_left_empty() and \
            get_is_neighbor_empty(0,2) and \
            (_get_is_bottom_right_present() or \
                _get_is_bottom_cap() and \
                    _get_is_right_empty())


func _get_is_top_90_left_wall() -> bool:
    return (_get_top_angle_type() == CellAngleType.A90 or \
            get_is_neighbor_present(0,-2)) and \
            _get_is_top_right_empty()


func _get_is_bottom_90_left_wall() -> bool:
    return (_get_bottom_angle_type() == CellAngleType.A90 or \
            get_is_neighbor_present(0,2)) and \
            _get_is_bottom_right_empty()


func _get_is_top_90_right_wall() -> bool:
    return (_get_top_angle_type() == CellAngleType.A90 or \
            get_is_neighbor_present(0,-2)) and \
            _get_is_top_left_empty()


func _get_is_bottom_90_right_wall() -> bool:
    return (_get_bottom_angle_type() == CellAngleType.A90 or \
            get_is_neighbor_present(0,2)) and \
            _get_is_bottom_left_empty()


func _get_is_left_90_floor() -> bool:
    return (_get_left_angle_type() == CellAngleType.A90 or \
            get_is_neighbor_present(-2,0)) and \
            _get_is_top_left_empty()


func _get_is_right_90_floor() -> bool:
    return (_get_right_angle_type() == CellAngleType.A90 or \
            get_is_neighbor_present(2,0)) and \
            _get_is_top_right_empty()


func _get_is_left_90_ceiling() -> bool:
    return (_get_left_angle_type() == CellAngleType.A90 or \
            get_is_neighbor_present(-2,0)) and \
            _get_is_bottom_left_empty()


func _get_is_right_90_ceiling() -> bool:
    return (_get_right_angle_type() == CellAngleType.A90 or \
            get_is_neighbor_present(2,0)) and \
            _get_is_bottom_right_empty()


func _get_is_top_left_corner_concave_90() -> bool:
    return _get_is_top_90_right_wall() and \
            _get_is_left_90_floor()


func _get_is_top_right_corner_concave_90() -> bool:
    return _get_is_top_90_left_wall() and \
            _get_is_right_90_floor()


func _get_is_bottom_left_corner_concave_90() -> bool:
    return _get_is_bottom_90_right_wall() and \
            _get_is_left_90_ceiling()


func _get_is_bottom_right_corner_concave_90() -> bool:
    return _get_is_bottom_90_left_wall() and \
            _get_is_right_90_ceiling()


func _get_is_top_left_corner_concave_45() -> bool:
    return _get_is_top_left_empty() and \
            _get_is_top_present() and \
            _get_is_left_present() and \
            !_get_is_top_90_right_wall() and \
            !_get_is_left_90_floor()


func _get_is_top_right_corner_concave_45() -> bool:
    return _get_is_top_right_empty() and \
            _get_is_top_present() and \
            _get_is_right_present() and \
            !_get_is_top_90_left_wall() and \
            !_get_is_right_90_floor()


func _get_is_bottom_left_corner_concave_45() -> bool:
    return _get_is_bottom_left_empty() and \
            _get_is_bottom_present() and \
            _get_is_left_present() and \
            !_get_is_bottom_90_right_wall() and \
            !_get_is_left_90_ceiling()


func _get_is_bottom_right_corner_concave_45() -> bool:
    return _get_is_bottom_right_empty() and \
            _get_is_bottom_present() and \
            _get_is_right_present() and \
            !_get_is_bottom_90_left_wall() and \
            !_get_is_right_90_ceiling()


func _get_is_top_left_corner_concave_partial_45() -> bool:
    return _get_is_top_left_empty() and \
            _get_is_top_present() and \
            _get_is_left_present() and \
            (!_get_is_top_90_right_wall() or \
            !_get_is_left_90_floor())


func _get_is_top_right_corner_concave_partial_45() -> bool:
    return _get_is_top_right_empty() and \
            _get_is_top_present() and \
            _get_is_right_present() and \
            (!_get_is_top_90_left_wall() or \
            !_get_is_right_90_floor())


func _get_is_bottom_left_corner_concave_partial_45() -> bool:
    return _get_is_bottom_left_empty() and \
            _get_is_bottom_present() and \
            _get_is_left_present() and \
            (!_get_is_bottom_90_right_wall() or \
            !_get_is_left_90_ceiling())


func _get_is_bottom_right_corner_concave_partial_45() -> bool:
    return _get_is_bottom_right_empty() and \
            _get_is_bottom_present() and \
            _get_is_right_present() and \
            (!_get_is_bottom_90_left_wall() or \
            !_get_is_right_90_ceiling())


func _get_is_any_corner_concave_partial_45() -> bool:
    return _get_is_top_left_corner_concave_partial_45() or \
            _get_is_top_right_corner_concave_partial_45() or \
            _get_is_bottom_left_corner_concave_partial_45() or \
            _get_is_bottom_right_corner_concave_partial_45()


func _get_is_top_left_corner_concave_90_vertical_to_45() -> bool:
    return _get_is_top_left_empty() and \
            _get_is_top_90_right_wall() and \
            _get_is_top_present() and \
            !_get_is_left_90_floor()


func _get_is_top_right_corner_concave_90_vertical_to_45() -> bool:
    return _get_is_top_right_empty() and \
            _get_is_top_90_left_wall() and \
            _get_is_top_present() and \
            !_get_is_right_90_floor()


func _get_is_bottom_left_corner_concave_90_vertical_to_45() -> bool:
    return _get_is_bottom_left_empty() and \
            _get_is_bottom_90_right_wall() and \
            _get_is_bottom_present() and \
            !_get_is_left_90_ceiling()


func _get_is_bottom_right_corner_concave_90_vertical_to_45() -> bool:
    return _get_is_bottom_right_empty() and \
            _get_is_bottom_90_left_wall() and \
            _get_is_bottom_present() and \
            !_get_is_right_90_ceiling()


func _get_is_top_left_corner_concave_90_horizontal_to_45() -> bool:
    return _get_is_top_left_empty() and \
            _get_is_left_90_floor() and \
            _get_is_top_present() and \
            !_get_is_top_90_right_wall()


func _get_is_top_right_corner_concave_90_horizontal_to_45() -> bool:
    return _get_is_top_right_empty() and \
            _get_is_right_90_floor() and \
            _get_is_top_present() and \
            !_get_is_top_90_left_wall()


func _get_is_bottom_left_corner_concave_90_horizontal_to_45() -> bool:
    return _get_is_bottom_left_empty() and \
            _get_is_left_90_ceiling() and \
            _get_is_bottom_present() and \
            !_get_is_bottom_90_right_wall()


func _get_is_bottom_right_corner_concave_90_horizontal_to_45() -> bool:
    return _get_is_bottom_right_empty() and \
            _get_is_right_90_ceiling() and \
            _get_is_bottom_present() and \
            !_get_is_bottom_90_left_wall()

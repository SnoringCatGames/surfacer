class_name CellProximity
extends Reference


var position: Vector2
var angle_type: int
var bitmask: int

var top_left_neighbor_angle_type: int
var top_neighbor_angle_type: int
var top_right_neighbor_angle_type: int
var left_neighbor_angle_type: int
var right_neighbor_angle_type: int
var bottom_left_neighbor_angle_type: int
var bottom_neighbor_angle_type: int
var bottom_right_neighbor_angle_type: int

var top_left_neighbor_bitmask: int
var top_neighbor_bitmask: int
var top_right_neighbor_bitmask: int
var left_neighbor_bitmask: int
var right_neighbor_bitmask: int
var bottom_left_neighbor_bitmask: int
var bottom_neighbor_bitmask: int
var bottom_right_neighbor_bitmask: int

var is_exposed_at_top_left: bool setget ,_get_is_exposed_at_top_left
var is_exposed_at_top: bool setget ,_get_is_exposed_at_top
var is_exposed_at_top_right: bool setget ,_get_is_exposed_at_top_right
var is_exposed_at_left: bool setget ,_get_is_exposed_at_left
var is_exposed_at_right: bool setget ,_get_is_exposed_at_right
var is_exposed_at_bottom_left: bool setget ,_get_is_exposed_at_bottom_left
var is_exposed_at_bottom: bool setget ,_get_is_exposed_at_bottom
var is_exposed_at_bottom_right: bool setget ,_get_is_exposed_at_bottom_right

var is_exposed_at_top_or_left: bool setget ,_get_is_exposed_at_top_or_left
var is_exposed_at_top_or_right: bool setget ,_get_is_exposed_at_top_or_right
var is_exposed_at_bottom_or_left: bool setget ,_get_is_exposed_at_bottom_or_left
var is_exposed_at_bottom_or_right: bool setget ,_get_is_exposed_at_bottom_or_right

var is_exposed_around_top_left: bool \
        setget ,_get_is_exposed_around_top_left
var is_exposed_around_top_right: bool \
        setget ,_get_is_exposed_around_top_right
var is_exposed_around_bottom_left: bool \
        setget ,_get_is_exposed_around_bottom_left
var is_exposed_around_bottom_right: bool \
        setget ,_get_is_exposed_around_bottom_right

var is_top_left_neighbor_exposed_at_top_left: bool \
        setget ,_get_is_top_left_neighbor_exposed_at_top_left
var is_top_neighbor_exposed_at_top: bool \
        setget ,_get_is_top_neighbor_exposed_at_top
var is_top_right_neighbor_exposed_at_top_right: bool \
        setget ,_get_is_top_right_neighbor_exposed_at_top_right
var is_left_neighbor_exposed_at_left: bool \
        setget ,_get_is_left_neighbor_exposed_at_left
var is_right_neighbor_exposed_at_right: bool \
        setget ,_get_is_right_neighbor_exposed_at_right
var is_bottom_left_neighbor_exposed_at_bottom_left: bool \
        setget ,_get_is_bottom_left_neighbor_exposed_at_bottom_left
var is_bottom_neighbor_exposed_at_bottom: bool \
        setget ,_get_is_bottom_neighbor_exposed_at_bottom
var is_bottom_right_neighbor_exposed_at_bottom_right: bool \
        setget ,_get_is_bottom_right_neighbor_exposed_at_bottom_right

var is_top_left_neighbor_exposed_at_top_or_left: bool \
        setget ,_get_is_top_left_neighbor_exposed_at_top_or_left
var is_top_right_neighbor_exposed_at_top_or_right: bool \
        setget ,_get_is_top_right_neighbor_exposed_at_top_or_right
var is_bottom_left_neighbor_exposed_at_bottom_or_left: bool \
        setget ,_get_is_bottom_left_neighbor_exposed_at_bottom_or_left
var is_bottom_right_neighbor_exposed_at_bottom_or_right: bool \
        setget ,_get_is_bottom_right_neighbor_exposed_at_bottom_or_right

var is_top_neighbor_exposed_around_top: bool \
        setget ,_get_is_top_neighbor_exposed_around_top
var is_bottom_neighbor_exposed_around_bottom: bool \
        setget ,_get_is_bottom_neighbor_exposed_around_bottom
var is_left_neighbor_exposed_around_left: bool \
        setget ,_get_is_left_neighbor_exposed_around_left
var is_right_neighbor_exposed_around_right: bool \
        setget ,_get_is_right_neighbor_exposed_around_right

var is_top_left_neighbor_exposed_around_top_left: bool \
        setget ,_get_is_top_left_neighbor_exposed_around_top_left
var is_top_right_neighbor_exposed_around_top_right: bool \
        setget ,_get_is_top_right_neighbor_exposed_around_top_right
var is_bottom_left_neighbor_exposed_around_bottom_left: bool \
        setget ,_get_is_bottom_left_neighbor_exposed_around_bottom_left
var is_bottom_right_neighbor_exposed_around_bottom_right: bool \
        setget ,_get_is_bottom_right_neighbor_exposed_around_bottom_right

var is_internal: bool setget ,_get_is_internal

var is_top_left_neighbor_same_angle_type: bool \
        setget ,_get_is_top_left_neighbor_same_angle_type
var is_top_neighbor_same_angle_type: bool \
        setget ,_get_is_top_neighbor_same_angle_type
var is_top_right_neighbor_same_angle_type: bool \
        setget ,_get_is_top_right_neighbor_same_angle_type
var is_left_neighbor_same_angle_type: bool \
        setget ,_get_is_left_neighbor_same_angle_type
var is_right_neighbor_same_angle_type: bool \
        setget ,_get_is_right_neighbor_same_angle_type
var is_bottom_left_neighbor_same_angle_type: bool \
        setget ,_get_is_bottom_left_neighbor_same_angle_type
var is_bottom_neighbor_same_angle_type: bool \
        setget ,_get_is_bottom_neighbor_same_angle_type
var is_bottom_right_neighbor_same_angle_type: bool \
        setget ,_get_is_bottom_right_neighbor_same_angle_type

var are_all_neighbors_same_angle_type: bool \
        setget, _get_are_all_neighbors_same_angle_type


func _get_is_exposed_at_top_left() -> bool:
    return !(bitmask & TileSet.BIND_TOPLEFT)


func _get_is_exposed_at_top() -> bool:
    return !(bitmask & TileSet.BIND_TOP)


func _get_is_exposed_at_top_right() -> bool:
    return !(bitmask & TileSet.BIND_TOPRIGHT)


func _get_is_exposed_at_left() -> bool:
    return !(bitmask & TileSet.BIND_LEFT)


func _get_is_exposed_at_right() -> bool:
    return !(bitmask & TileSet.BIND_RIGHT)


func _get_is_exposed_at_bottom_left() -> bool:
    return !(bitmask & TileSet.BIND_BOTTOMLEFT)


func _get_is_exposed_at_bottom() -> bool:
    return !(bitmask & TileSet.BIND_BOTTOM)


func _get_is_exposed_at_bottom_right() -> bool:
    return !(bitmask & TileSet.BIND_BOTTOMRIGHT)


func _get_is_exposed_at_top_or_left() -> bool:
    return !(bitmask & TileSet.BIND_TOP) or \
            !(bitmask & TileSet.BIND_LEFT)


func _get_is_exposed_at_top_or_right() -> bool:
    return !(bitmask & TileSet.BIND_TOP) or \
            !(bitmask & TileSet.BIND_RIGHT)


func _get_is_exposed_at_bottom_or_left() -> bool:
    return !(bitmask & TileSet.BIND_BOTTOM) or \
            !(bitmask & TileSet.BIND_LEFT)


func _get_is_exposed_at_bottom_or_right() -> bool:
    return !(bitmask & TileSet.BIND_BOTTOM) or \
            !(bitmask & TileSet.BIND_RIGHT)


func _get_is_exposed_around_top_left() -> bool:
    return !(bitmask & TileSet.BIND_TOPLEFT) or \
            !(bitmask & TileSet.BIND_TOP) or \
            !(bitmask & TileSet.BIND_LEFT)


func _get_is_exposed_around_top_right() -> bool:
    return !(bitmask & TileSet.BIND_TOPRIGHT) or \
            !(bitmask & TileSet.BIND_TOP) or \
            !(bitmask & TileSet.BIND_RIGHT)


func _get_is_exposed_around_bottom_left() -> bool:
    return !(bitmask & TileSet.BIND_BOTTOMLEFT) or \
            !(bitmask & TileSet.BIND_BOTTOM) or \
            !(bitmask & TileSet.BIND_LEFT)


func _get_is_exposed_around_bottom_right() -> bool:
    return !(bitmask & TileSet.BIND_BOTTOMRIGHT) or \
            !(bitmask & TileSet.BIND_BOTTOM) or \
            !(bitmask & TileSet.BIND_RIGHT)


func _get_is_top_left_neighbor_exposed_at_top_left() -> bool:
    return !(top_left_neighbor_bitmask & TileSet.BIND_TOPLEFT)


func _get_is_top_neighbor_exposed_at_top() -> bool:
    return !(top_neighbor_bitmask & TileSet.BIND_TOP)


func _get_is_top_right_neighbor_exposed_at_top_right() -> bool:
    return !(top_right_neighbor_bitmask & TileSet.BIND_TOPRIGHT)


func _get_is_left_neighbor_exposed_at_left() -> bool:
    return !(left_neighbor_bitmask & TileSet.BIND_LEFT)


func _get_is_right_neighbor_exposed_at_right() -> bool:
    return !(right_neighbor_bitmask & TileSet.BIND_RIGHT)


func _get_is_bottom_left_neighbor_exposed_at_bottom_left() -> bool:
    return !(bottom_left_neighbor_bitmask & TileSet.BIND_BOTTOMLEFT)


func _get_is_bottom_neighbor_exposed_at_bottom() -> bool:
    return !(bottom_neighbor_bitmask & TileSet.BIND_BOTTOM)


func _get_is_bottom_right_neighbor_exposed_at_bottom_right() -> bool:
    return !(bottom_right_neighbor_bitmask & TileSet.BIND_BOTTOMRIGHT)


func _get_is_top_left_neighbor_exposed_at_top_or_left() -> bool:
    return !(top_left_neighbor_bitmask & TileSet.BIND_TOP) or \
            !(top_left_neighbor_bitmask & TileSet.BIND_LEFT)


func _get_is_top_right_neighbor_exposed_at_top_or_right() -> bool:
    return !(top_right_neighbor_bitmask & TileSet.BIND_TOP) or \
            !(top_right_neighbor_bitmask & TileSet.BIND_RIGHT)


func _get_is_bottom_left_neighbor_exposed_at_bottom_or_left() -> bool:
    return !(bottom_left_neighbor_bitmask & TileSet.BIND_BOTTOM) or \
            !(bottom_left_neighbor_bitmask & TileSet.BIND_LEFT)


func _get_is_bottom_right_neighbor_exposed_at_bottom_or_right() -> bool:
    return !(bottom_right_neighbor_bitmask & TileSet.BIND_BOTTOM) or \
            !(bottom_right_neighbor_bitmask & TileSet.BIND_RIGHT)


func _get_is_top_neighbor_exposed_around_top() -> bool:
    return !(top_neighbor_bitmask & TileSet.BIND_TOPLEFT) or \
            !(top_neighbor_bitmask & TileSet.BIND_TOP) or \
            !(top_neighbor_bitmask & TileSet.BIND_TOPRIGHT)


func _get_is_bottom_neighbor_exposed_around_bottom() -> bool:
    return !(bottom_neighbor_bitmask & TileSet.BIND_BOTTOMLEFT) or \
            !(bottom_neighbor_bitmask & TileSet.BIND_BOTTOM) or \
            !(bottom_neighbor_bitmask & TileSet.BIND_BOTTOMRIGHT)


func _get_is_left_neighbor_exposed_around_left() -> bool:
    return !(left_neighbor_bitmask & TileSet.BIND_TOPLEFT) or \
            !(left_neighbor_bitmask & TileSet.BIND_LEFT) or \
            !(left_neighbor_bitmask & TileSet.BIND_BOTTOMLEFT)


func _get_is_right_neighbor_exposed_around_right() -> bool:
    return !(right_neighbor_bitmask & TileSet.BIND_TOPRIGHT) or \
            !(right_neighbor_bitmask & TileSet.BIND_RIGHT) or \
            !(right_neighbor_bitmask & TileSet.BIND_BOTTOMRIGHT)


func _get_is_top_left_neighbor_exposed_around_top_left() -> bool:
    return !(top_left_neighbor_bitmask & TileSet.BIND_TOPLEFT) or \
            !(top_left_neighbor_bitmask & TileSet.BIND_TOP) or \
            !(top_left_neighbor_bitmask & TileSet.BIND_LEFT)


func _get_is_top_right_neighbor_exposed_around_top_right() -> bool:
    return !(top_right_neighbor_bitmask & TileSet.BIND_TOPRIGHT) or \
            !(top_right_neighbor_bitmask & TileSet.BIND_TOP) or \
            !(top_right_neighbor_bitmask & TileSet.BIND_RIGHT)


func _get_is_bottom_left_neighbor_exposed_around_bottom_left() -> bool:
    return !(bottom_left_neighbor_bitmask & TileSet.BIND_BOTTOMLEFT) or \
            !(bottom_left_neighbor_bitmask & TileSet.BIND_BOTTOM) or \
            !(bottom_left_neighbor_bitmask & TileSet.BIND_LEFT)


func _get_is_bottom_right_neighbor_exposed_around_bottom_right() -> bool:
    return !(bottom_right_neighbor_bitmask & TileSet.BIND_BOTTOMRIGHT) or \
            !(bottom_right_neighbor_bitmask & TileSet.BIND_BOTTOM) or \
            !(bottom_right_neighbor_bitmask & TileSet.BIND_RIGHT)


func _get_is_internal() -> bool:
    return bitmask == SurfacesTileSet.FULL_BITMASK_3x3


func _get_is_top_left_neighbor_same_angle_type() -> bool:
    return (top_left_neighbor_angle_type == angle_type or \
            top_left_neighbor_angle_type == CellAngleType.EMPTY)


func _get_is_top_neighbor_same_angle_type() -> bool:
    return (top_neighbor_angle_type == angle_type or \
            top_neighbor_angle_type == CellAngleType.EMPTY)


func _get_is_top_right_neighbor_same_angle_type() -> bool:
    return (top_right_neighbor_angle_type == angle_type or \
            top_right_neighbor_angle_type == CellAngleType.EMPTY)


func _get_is_left_neighbor_same_angle_type() -> bool:
    return (left_neighbor_angle_type == angle_type or \
            left_neighbor_angle_type == CellAngleType.EMPTY)


func _get_is_right_neighbor_same_angle_type() -> bool:
    return (right_neighbor_angle_type == angle_type or \
            right_neighbor_angle_type == CellAngleType.EMPTY)


func _get_is_bottom_left_neighbor_same_angle_type() -> bool:
    return (bottom_left_neighbor_angle_type == angle_type or \
            bottom_left_neighbor_angle_type == CellAngleType.EMPTY)


func _get_is_bottom_neighbor_same_angle_type() -> bool:
    return (bottom_neighbor_angle_type == angle_type or \
            bottom_neighbor_angle_type == CellAngleType.EMPTY)


func _get_is_bottom_right_neighbor_same_angle_type() -> bool:
    return (bottom_right_neighbor_angle_type == angle_type or \
            bottom_right_neighbor_angle_type == CellAngleType.EMPTY)


func _get_are_all_neighbors_same_angle_type() -> bool:
    return (top_left_neighbor_angle_type == angle_type or \
            top_left_neighbor_angle_type == CellAngleType.EMPTY) and \
            (top_neighbor_angle_type == angle_type or \
            top_neighbor_angle_type == CellAngleType.EMPTY) and \
            (top_right_neighbor_angle_type == angle_type or \
            top_right_neighbor_angle_type == CellAngleType.EMPTY) and \
            (left_neighbor_angle_type == angle_type or \
            left_neighbor_angle_type == CellAngleType.EMPTY) and \
            (right_neighbor_angle_type == angle_type or \
            right_neighbor_angle_type == CellAngleType.EMPTY) and \
            (bottom_left_neighbor_angle_type == angle_type or \
            bottom_left_neighbor_angle_type == CellAngleType.EMPTY) and \
            (bottom_neighbor_angle_type == angle_type or \
            bottom_neighbor_angle_type == CellAngleType.EMPTY) and \
            (bottom_right_neighbor_angle_type == angle_type or \
            bottom_right_neighbor_angle_type == CellAngleType.EMPTY)

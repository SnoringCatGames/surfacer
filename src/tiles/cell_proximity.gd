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

var tile_map: TileMap
var tile_set: TileSet

var position: Vector2
var tile_id: int
var angle_type: int
var bitmask: int

var is_angle_type_90: bool \
        setget ,_get_is_angle_type_90
var is_angle_type_45: bool \
        setget ,_get_is_angle_type_45
var is_angle_type_27: bool \
        setget ,_get_is_angle_type_27

var is_top_left_present: bool setget ,_get_is_top_left_present
var is_top_present: bool setget ,_get_is_top_present
var is_top_right_present: bool setget ,_get_is_top_right_present
var is_left_present: bool setget ,_get_is_left_present
var is_center_present: bool setget ,_get_is_center_present
var is_right_present: bool setget ,_get_is_right_present
var is_bottom_left_present: bool setget ,_get_is_bottom_left_present
var is_bottom_present: bool setget ,_get_is_bottom_present
var is_bottom_right_present: bool setget ,_get_is_bottom_right_present

var is_top_left_empty: bool setget ,_get_is_top_left_empty
var is_top_empty: bool setget ,_get_is_top_empty
var is_top_right_empty: bool setget ,_get_is_top_right_empty
var is_left_empty: bool setget ,_get_is_left_empty
var is_right_empty: bool setget ,_get_is_right_empty
var is_bottom_left_empty: bool setget ,_get_is_bottom_left_empty
var is_bottom_empty: bool setget ,_get_is_bottom_empty
var is_bottom_right_empty: bool setget ,_get_is_bottom_right_empty


func _init(
        tile_map: TileMap,
        tile_set: TileSet,
        position: Vector2,
        tile_id := TileMap.INVALID_CELL) -> void:
    self.tile_map = tile_map
    self.tile_set = tile_set
    self.position = position
    self.tile_id = \
            tile_id if \
            tile_id != TileMap.INVALID_CELL else \
            tile_map.get_cellv(position)
    self.bitmask = get_cell_actual_bitmask(position, tile_map)
    self.angle_type = get_angle_type(0,0)


static func get_cell_actual_bitmask(
        position: Vector2,
        tile_map: TileMap) -> int:
    var bitmask := 0
    if tile_map.get_cellv(position + Vector2(-1, -1)) != TileMap.INVALID_CELL:
        bitmask |= TileSet.BIND_TOPLEFT
    if tile_map.get_cellv(position + Vector2(0, -1)) != TileMap.INVALID_CELL:
        bitmask |= TileSet.BIND_TOP
    if tile_map.get_cellv(position + Vector2(1, -1)) != TileMap.INVALID_CELL:
        bitmask |= TileSet.BIND_TOPRIGHT
    if tile_map.get_cellv(position + Vector2(-1, 0)) != TileMap.INVALID_CELL:
        bitmask |= TileSet.BIND_LEFT
    if tile_map.get_cellv(position) != TileMap.INVALID_CELL:
        bitmask |= TileSet.BIND_CENTER
    if tile_map.get_cellv(position + Vector2(1, 0)) != TileMap.INVALID_CELL:
        bitmask |= TileSet.BIND_RIGHT
    if tile_map.get_cellv(position + Vector2(-1, 1)) != TileMap.INVALID_CELL:
        bitmask |= TileSet.BIND_BOTTOMLEFT
    if tile_map.get_cellv(position + Vector2(0, 1)) != TileMap.INVALID_CELL:
        bitmask |= TileSet.BIND_BOTTOM
    if tile_map.get_cellv(position + Vector2(1, 1)) != TileMap.INVALID_CELL:
        bitmask |= TileSet.BIND_BOTTOMRIGHT
    return bitmask


func to_string() -> String:
    var neighbors := []
    var neighbors_presence := [
        "tl", is_top_left_present,
        "t", is_top_present,
        "tr", is_top_right_present,
        "l", is_left_present,
        "c", is_center_present,
        "r", is_right_present,
        "bl", is_bottom_left_present,
        "b", is_bottom_present,
        "br", is_bottom_right_present,
    ]
    for i in range(0, neighbors_presence.size(), 2):
        if neighbors_presence[i + 1]:
            neighbors.push_back(neighbors_presence[i])
    return "CellProximity(p=%s, neighbors=%s)" % [
        Sc.utils.get_vector_string(position, 0),
        Sc.utils.join(neighbors),
    ]


func get_angle_type(relative_x := 0, relative_y := 0) -> int:
    var neighbor_id := tile_map.get_cell(
            position.x + relative_x,
            position.y + relative_y)
    return tile_set.tile_get_angle_type(neighbor_id)


func get_is_present(relative_x := 0, relative_y := 0) -> bool:
    var neighbor_id := tile_map.get_cell(
            position.x + relative_x,
            position.y + relative_y)
    return tile_set._is_tile_bound(tile_id, neighbor_id)


func get_is_empty(relative_x := 0, relative_y := 0) -> bool:
    var neighbor_id := tile_map.get_cell(
            position.x + relative_x,
            position.y + relative_y)
    return !tile_set._is_tile_bound(tile_id, neighbor_id)


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


func _get_is_center_present() -> bool:
    return !!(bitmask & TileSet.BIND_CENTER)


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


func get_is_top_cap(relative_x := 0, relative_y := 0) -> bool:
    return get_is_present(relative_x, relative_y) and \
            get_is_present(relative_x, relative_y + 1) and \
            get_is_empty(relative_x - 1, relative_y) and \
            get_is_empty(relative_x + 1, relative_y)


func get_is_bottom_cap(relative_x := 0, relative_y := 0) -> bool:
    return get_is_present(relative_x, relative_y) and \
            get_is_present(relative_x, relative_y - 1) and \
            get_is_empty(relative_x - 1, relative_y) and \
            get_is_empty(relative_x + 1, relative_y)


func get_is_left_cap(relative_x := 0, relative_y := 0) -> bool:
    return get_is_present(relative_x, relative_y) and \
            get_is_present(relative_x + 1, relative_y) and \
            get_is_empty(relative_x, relative_y - 1) and \
            get_is_empty(relative_x, relative_y + 1)


func get_is_right_cap(relative_x := 0, relative_y := 0) -> bool:
    return get_is_present(relative_x, relative_y) and \
            get_is_present(relative_x - 1, relative_y) and \
            get_is_empty(relative_x, relative_y - 1) and \
            get_is_empty(relative_x, relative_y + 1)


func get_is_90_floor(
        relative_x := 0,
        relative_y := 0) -> bool:
    if get_is_empty(relative_x, relative_y):
        return false
    if get_is_present(relative_x, relative_y - 1):
        # Can't be a floor if there is another block in front.
        return false
    match get_angle_type(relative_x, relative_y):
        CellAngleType.A90:
            return true
        CellAngleType.A45:
            # A45s become A90s when there are neighbors on either side and at
            # least one of the two front corners are empty.
            return get_is_present(relative_x - 1, relative_y) and \
                    get_is_present(relative_x + 1, relative_y) and \
                    (get_is_empty(relative_x - 1, relative_y - 1) or \
                    get_is_empty(relative_x + 1, relative_y - 1))
        CellAngleType.A27:
            # A27s become A90s in a few cases.
            # FIXME: LEFT OFF HERE: -------- A27
            # - Copy the logic in _get_is_90_left_wall.
            return false
        _:
            Sc.logger.error("CellProximity.get_is_90_floor")
            return false


func get_is_90_ceiling(
        relative_x := 0,
        relative_y := 0) -> bool:
    if get_is_empty(relative_x, relative_y):
        return false
    if get_is_present(relative_x, relative_y + 1):
        # Can't be a ceiling if there is another block in front.
        return false
    match get_angle_type(relative_x, relative_y):
        CellAngleType.A90:
            return true
        CellAngleType.A45:
            # A45s become A90s when there are neighbors on either side and at
            # least one of the two front corners are empty.
            return get_is_present(relative_x - 1, relative_y) and \
                    get_is_present(relative_x + 1, relative_y) and \
                    (get_is_empty(relative_x - 1, relative_y + 1) or \
                    get_is_empty(relative_x + 1, relative_y + 1))
        CellAngleType.A27:
            # A27s become A90s in a few cases.
            # FIXME: LEFT OFF HERE: -------- A27
            # - Copy the logic in _get_is_90_left_wall.
            return false
        _:
            Sc.logger.error("CellProximity.get_is_90_ceiling")
            return false


func get_is_90_left_wall(
        relative_x := 0,
        relative_y := 0) -> bool:
    if get_is_empty(relative_x, relative_y):
        return false
    if get_is_present(relative_x + 1, relative_y):
        # Can't be a wall if there is another block in front.
        return false
    match get_angle_type(relative_x, relative_y):
        CellAngleType.A90:
            return true
        CellAngleType.A45:
            # A45s become A90s when there are neighbors on either side and at
            # least one of the two front corners are empty.
            return get_is_present(relative_x, relative_y - 1) and \
                    get_is_present(relative_x, relative_y + 1) and \
                    (get_is_empty(relative_x + 1, relative_y - 1) or \
                    get_is_empty(relative_x + 1, relative_y + 1))
        CellAngleType.A27:
            # A27s become A90s in a few cases.
            var two_exposed_at_top := \
                    get_is_present(relative_x, relative_y - 1) and \
                    get_is_present(relative_x, relative_y - 2) and \
                    get_is_empty(relative_x + 1, relative_y - 1) and \
                    get_is_empty(relative_x + 1, relative_y - 2)
            var two_exposed_at_bottom := \
                    get_is_present(relative_x, relative_y + 1) and \
                    get_is_present(relative_x, relative_y + 2) and \
                    get_is_empty(relative_x + 1, relative_y + 1) and \
                    get_is_empty(relative_x + 1, relative_y + 2)
            # Long side.
            if two_exposed_at_top and \
                    two_exposed_at_bottom:
                return true
            # Convex on one side.
            if two_exposed_at_top and \
                    get_is_empty(relative_x, relative_y - 3):
                return true
            if two_exposed_at_bottom and \
                    get_is_empty(relative_x, relative_y + 3):
                return true
            # Concave on one side.
            if two_exposed_at_top and \
                    get_is_present(relative_x, relative_y - 3) and \
                    get_is_empty(relative_x + 1, relative_y - 3) and \
                    get_is_present(relative_x, relative_y + 1) and \
                    get_is_present(relative_x + 1, relative_y + 1):
                return true
            if two_exposed_at_top and \
                    get_is_present(relative_x, relative_y + 1) and \
                    get_is_empty(relative_x + 1, relative_y + 1) and \
                    get_is_present(relative_x, relative_y + 2) and \
                    get_is_present(relative_x + 1, relative_y + 2):
                return true
            if two_exposed_at_bottom and \
                    get_is_present(relative_x, relative_y + 3) and \
                    get_is_empty(relative_x + 1, relative_y + 3) and \
                    get_is_present(relative_x, relative_y - 1) and \
                    get_is_present(relative_x + 1, relative_y - 1):
                return true
            if two_exposed_at_bottom and \
                    get_is_present(relative_x, relative_y - 1) and \
                    get_is_empty(relative_x + 1, relative_y - 1) and \
                    get_is_present(relative_x, relative_y - 2) and \
                    get_is_present(relative_x + 1, relative_y - 2):
                return true
            # Cap on one side, with this tile being exposed on opposite sides.
            if get_is_present(relative_x, relative_y - 1) and \
                    get_is_empty(relative_x + 1, relative_y - 1) and \
                    get_is_empty(relative_x, relative_y - 2) and \
                    get_is_empty(relative_x - 1, relative_y - 1) and \
                    get_is_empty(relative_x - 1, relative_y) and \
                    get_is_present(relative_x, relative_y + 1):
                return true
            if get_is_present(relative_x, relative_y + 1) and \
                    get_is_empty(relative_x + 1, relative_y + 1) and \
                    get_is_empty(relative_x, relative_y + 2) and \
                    get_is_empty(relative_x - 1, relative_y + 1) and \
                    get_is_empty(relative_x - 1, relative_y) and \
                    get_is_present(relative_x, relative_y - 1):
                return true
            # Non-A27 A90 surface on one side and long on the other side.
            var is_top_non_a27_a90_exposed := \
                    get_angle_type(relative_x, relative_y - 1) != \
                        CellAngleType.A27 and \
                    get_is_90_left_wall(relative_x, relative_y - 1)
            if is_top_non_a27_a90_exposed and \
                    two_exposed_at_bottom:
                return true
            var is_bottom_non_a27_a90_exposed := \
                    get_angle_type(relative_x, relative_y + 1) != \
                        CellAngleType.A27 and \
                    get_is_90_left_wall(relative_x, relative_y + 1)
            if is_bottom_non_a27_a90_exposed and \
                    two_exposed_at_top:
                return true
            # Non-A27 A90 surface on one side and concave on the other side.
            if is_top_non_a27_a90_exposed and \
                    get_is_present(relative_x, relative_y + 1) and \
                    (get_is_present(relative_x + 1, relative_y + 1) or \
                    get_is_present(relative_x, relative_y + 2) and \
                    get_is_present(relative_x + 1, relative_y + 2)):
                return true
            if is_bottom_non_a27_a90_exposed and \
                    get_is_present(relative_x, relative_y - 1) and \
                    (get_is_present(relative_x + 1, relative_y - 1) or \
                    get_is_present(relative_x, relative_y - 2) and \
                    get_is_present(relative_x + 1, relative_y - 2)):
                return true
            # Non-A27 A90 surface on both sides.
            if is_top_non_a27_a90_exposed and \
                    is_bottom_non_a27_a90_exposed:
                return true
            return false
        _:
            Sc.logger.error("CellProximity.get_is_90_left_wall")
            return false


func get_is_90_right_wall(
        relative_x := 0,
        relative_y := 0) -> bool:
    if get_is_empty(relative_x, relative_y):
        return false
    if get_is_present(relative_x - 1, relative_y):
        # Can't be a wall if there is another block in front.
        return false
    match get_angle_type(relative_x, relative_y):
        CellAngleType.A90:
            return true
        CellAngleType.A45:
            # A45s become A90s when there are neighbors on either side and at
            # least one of the two front corners are empty.
            return get_is_present(relative_x, relative_y - 1) and \
                    get_is_present(relative_x, relative_y + 1) and \
                    (get_is_empty(relative_x - 1, relative_y - 1) or \
                    get_is_empty(relative_x - 1, relative_y + 1))
        CellAngleType.A27:
            # A27s become A90s in a few cases.
            # FIXME: LEFT OFF HERE: -------- A27
            # - Copy the logic in _get_is_90_left_wall.
            return false
        _:
            Sc.logger.error("CellProximity.get_is_90_right_wall")
            return false


func get_is_45_pos_floor(relative_x := 0, relative_y := 0) -> bool:
    if get_is_empty(relative_x, relative_y):
        return false
    if get_is_present(relative_x - 1, relative_y) or \
            get_is_present(relative_x, relative_y - 1):
        # Can't be a 45 floor if there is another block in front.
        return false
    match get_angle_type(relative_x, relative_y):
        CellAngleType.A90:
            return false
        CellAngleType.A45:
            # The angle of A45 caps can be flipped in order to transition
            # smoothly from a diagonal neighbor.
            if get_is_present(relative_x + 1, relative_y) and \
                    (get_is_present(
                        relative_x + 1, relative_y - 1) or \
                    get_is_empty(relative_x + 1, relative_y + 1)):
                return true
            if get_is_present(relative_x, relative_y + 1) and \
                    (get_is_present(
                        relative_x - 1, relative_y + 1) or \
                    get_is_empty(relative_x + 1, relative_y + 1)):
                return true
            return false
        CellAngleType.A27:
            # FIXME: LEFT OFF HERE: -------- A27
            return false
        _:
            Sc.logger.error("CellProximity.get_is_45_pos_floor")
            return false


func get_is_45_neg_floor(relative_x := 0, relative_y := 0) -> bool:
    if get_is_empty(relative_x, relative_y):
        return false
    if get_is_present(relative_x + 1, relative_y) or \
            get_is_present(relative_x, relative_y - 1):
        # Can't be a 45 floor if there is another block in front.
        return false
    match get_angle_type(relative_x, relative_y):
        CellAngleType.A90:
            return false
        CellAngleType.A45:
            # The angle of A45 caps can be flipped in order to transition
            # smoothly from a diagonal neighbor.
            if get_is_present(relative_x - 1, relative_y) and \
                    (get_is_present(
                        relative_x - 1, relative_y - 1) or \
                    get_is_empty(relative_x - 1, relative_y + 1)):
                return true
            if get_is_present(relative_x, relative_y + 1) and \
                    (get_is_present(
                        relative_x + 1, relative_y + 1) or \
                    get_is_empty(relative_x - 1, relative_y + 1)):
                return true
            return false
        CellAngleType.A27:
            # FIXME: LEFT OFF HERE: -------- A27
            return false
        _:
            Sc.logger.error("CellProximity.get_is_45_neg_floor")
            return false


func get_is_45_pos_ceiling(relative_x := 0, relative_y := 0) -> bool:
    if get_is_empty(relative_x, relative_y):
        return false
    if get_is_present(relative_x + 1, relative_y) or \
            get_is_present(relative_x, relative_y + 1):
        # Can't be a 45 ceiling if there is another block in front.
        return false
    match get_angle_type(relative_x, relative_y):
        CellAngleType.A90:
            return false
        CellAngleType.A45:
            # The angle of A45 caps can be flipped in order to transition
            # smoothly from a diagonal neighbor.
            if get_is_present(relative_x - 1, relative_y) and \
                    (get_is_present(
                        relative_x - 1, relative_y + 1) or \
                    get_is_empty(relative_x - 1, relative_y - 1)):
                return true
            if get_is_present(relative_x, relative_y - 1) and \
                    (get_is_present(
                        relative_x + 1, relative_y - 1) or \
                    get_is_empty(relative_x - 1, relative_y - 1)):
                return true
            return false
        CellAngleType.A27:
            # FIXME: LEFT OFF HERE: -------- A27
            return false
        _:
            Sc.logger.error("CellProximity.get_is_45_pos_ceiling")
            return false


func get_is_45_neg_ceiling(relative_x := 0, relative_y := 0) -> bool:
    if get_is_empty(relative_x, relative_y):
        return false
    if get_is_present(relative_x - 1, relative_y) or \
            get_is_present(relative_x, relative_y + 1):
        # Can't be a 45 ceiling if there is another block in front.
        return false
    match get_angle_type(relative_x, relative_y):
        CellAngleType.A90:
            return false
        CellAngleType.A45:
            # The angle of A45 caps can be flipped in order to transition
            # smoothly from a diagonal neighbor.
            if get_is_present(relative_x + 1, relative_y) and \
                    (get_is_present(
                        relative_x + 1, relative_y + 1) or \
                    get_is_empty(relative_x + 1, relative_y - 1)):
                return true
            if get_is_present(relative_x, relative_y - 1) and \
                    (get_is_present(
                        relative_x - 1, relative_y - 1) or \
                    get_is_empty(relative_x + 1, relative_y - 1)):
                return true
            return false
        CellAngleType.A27:
            # FIXME: LEFT OFF HERE: -------- A27
            return false
        _:
            Sc.logger.error("CellProximity.get_is_45_neg_ceiling")
            return false


func get_is_27_pos_floor_in_top(relative_x := 0, relative_y := 0) -> bool:
    if get_is_empty(relative_x, relative_y):
        return false
    # FIXME: LEFT OFF HERE: -------- A27
    return false


func get_is_27_neg_floor_in_top(relative_x := 0, relative_y := 0) -> bool:
    if get_is_empty(relative_x, relative_y):
        return false
    # FIXME: LEFT OFF HERE: -------- A27
    return false


func get_is_27_pos_floor_in_bottom(relative_x := 0, relative_y := 0) -> bool:
    if get_is_empty(relative_x, relative_y):
        return false
    # FIXME: LEFT OFF HERE: -------- A27
    return false


func get_is_27_neg_floor_in_bottom(relative_x := 0, relative_y := 0) -> bool:
    if get_is_empty(relative_x, relative_y):
        return false
    # FIXME: LEFT OFF HERE: -------- A27
    return false


func get_is_27_pos_ceiling_in_top(relative_x := 0, relative_y := 0) -> bool:
    if get_is_empty(relative_x, relative_y):
        return false
    # FIXME: LEFT OFF HERE: -------- A27
    return false


func get_is_27_neg_ceiling_in_top(relative_x := 0, relative_y := 0) -> bool:
    if get_is_empty(relative_x, relative_y):
        return false
    # FIXME: LEFT OFF HERE: -------- A27
    return false


func get_is_27_pos_ceiling_in_bottom(relative_x := 0, relative_y := 0) -> bool:
    if get_is_empty(relative_x, relative_y):
        return false
    # FIXME: LEFT OFF HERE: -------- A27
    return false


func get_is_27_neg_ceiling_in_bottom(relative_x := 0, relative_y := 0) -> bool:
    if get_is_empty(relative_x, relative_y):
        return false
    # FIXME: LEFT OFF HERE: -------- A27
    return false


func get_is_27_pos_left_wall_in_left(relative_x := 0, relative_y := 0) -> bool:
    if get_is_empty(relative_x, relative_y):
        return false
    # FIXME: LEFT OFF HERE: -------- A27
    return false


func get_is_27_neg_left_wall_in_left(relative_x := 0, relative_y := 0) -> bool:
    if get_is_empty(relative_x, relative_y):
        return false
    # FIXME: LEFT OFF HERE: -------- A27
    return false


func get_is_27_pos_left_wall_in_right(relative_x := 0, relative_y := 0) -> bool:
    if get_is_empty(relative_x, relative_y):
        return false
    # FIXME: LEFT OFF HERE: -------- A27
    return false


func get_is_27_neg_left_wall_in_right(relative_x := 0, relative_y := 0) -> bool:
    if get_is_empty(relative_x, relative_y):
        return false
    # FIXME: LEFT OFF HERE: -------- A27
    return false


func get_is_27_pos_right_wall_in_left(relative_x := 0, relative_y := 0) -> bool:
    if get_is_empty(relative_x, relative_y):
        return false
    # FIXME: LEFT OFF HERE: -------- A27
    return false


func get_is_27_neg_right_wall_in_left(relative_x := 0, relative_y := 0) -> bool:
    if get_is_empty(relative_x, relative_y):
        return false
    # FIXME: LEFT OFF HERE: -------- A27
    return false


func get_is_27_pos_right_wall_in_right(relative_x := 0, relative_y := 0) -> bool:
    if get_is_empty(relative_x, relative_y):
        return false
    # FIXME: LEFT OFF HERE: -------- A27
    return false


func get_is_27_neg_right_wall_in_right(relative_x := 0, relative_y := 0) -> bool:
    if get_is_empty(relative_x, relative_y):
        return false
    # FIXME: LEFT OFF HERE: -------- A27
    return false


func get_is_90_floor_at_right(
        relative_x := 0,
        relative_y := 0) -> bool:
    # FIXME: LEFT OFF HERE: ------------------------
    # - Account for transitions to other angles:
    #   - The below treats A90 with curve-in to A45 as a false positive.
    #   - The below treats half-A90 to A27 as a false negative.
    #   - The below treats cut-out corners as false negatives.
    #     - BUT, I probably don't want this function to consider cut-out corners
    #       either.
    return get_is_90_floor(relative_x, relative_y)


func get_is_90_floor_at_left(
        relative_x := 0,
        relative_y := 0) -> bool:
    # FIXME: LEFT OFF HERE: ------------------------
    # - Account for transitions to other angles:
    #   - The below treats A90 with curve-in to A45 as a false positive.
    #   - The below treats half-A90 to A27 as a false negative.
    #   - The below treats cut-out corners as false negatives.
    #     - BUT, I probably don't want this function to consider cut-out corners
    #       either.
    return get_is_90_floor(relative_x, relative_y)


func get_is_90_ceiling_at_right(
        relative_x := 0,
        relative_y := 0) -> bool:
    # FIXME: LEFT OFF HERE: ------------------------
    # - Account for transitions to other angles:
    #   - The below treats A90 with curve-in to A45 as a false positive.
    #   - The below treats half-A90 to A27 as a false negative.
    #   - The below treats cut-out corners as false negatives.
    #     - BUT, I probably don't want this function to consider cut-out corners
    #       either.
    return get_is_90_ceiling(relative_x, relative_y)


func get_is_90_ceiling_at_left(
        relative_x := 0,
        relative_y := 0) -> bool:
    # FIXME: LEFT OFF HERE: ------------------------
    # - Account for transitions to other angles:
    #   - The below treats A90 with curve-in to A45 as a false positive.
    #   - The below treats half-A90 to A27 as a false negative.
    #   - The below treats cut-out corners as false negatives.
    #     - BUT, I probably don't want this function to consider cut-out corners
    #       either.
    return get_is_90_ceiling(relative_x, relative_y)


func get_is_90_left_wall_at_top(
        relative_x := 0,
        relative_y := 0) -> bool:
    # FIXME: LEFT OFF HERE: ------------------------
    # - Account for transitions to other angles:
    #   - The below treats A90 with curve-in to A45 as a false positive.
    #   - The below treats half-A90 to A27 as a false negative.
    #   - The below treats cut-out corners as false negatives.
    #     - BUT, I probably don't want this function to consider cut-out corners
    #       either.
    return get_is_90_left_wall(relative_x, relative_y)


func get_is_90_left_wall_at_bottom(
        relative_x := 0,
        relative_y := 0) -> bool:
    # FIXME: LEFT OFF HERE: ------------------------
    # - Account for transitions to other angles:
    #   - The below treats A90 with curve-in to A45 as a false positive.
    #   - The below treats half-A90 to A27 as a false negative.
    #   - The below treats cut-out corners as false negatives.
    #     - BUT, I probably don't want this function to consider cut-out corners
    #       either.
    return get_is_90_left_wall(relative_x, relative_y)


func get_is_90_right_wall_at_top(
        relative_x := 0,
        relative_y := 0) -> bool:
    # FIXME: LEFT OFF HERE: ------------------------
    # - Account for transitions to other angles:
    #   - The below treats A90 with curve-in to A45 as a false positive.
    #   - The below treats half-A90 to A27 as a false negative.
    #   - The below treats cut-out corners as false negatives.
    #     - BUT, I probably don't want this function to consider cut-out corners
    #       either.
    return get_is_90_right_wall(relative_x, relative_y)


func get_is_90_right_wall_at_bottom(
        relative_x := 0,
        relative_y := 0) -> bool:
    # FIXME: LEFT OFF HERE: ------------------------
    # - Account for transitions to other angles:
    #   - The below treats A90 with curve-in to A45 as a false positive.
    #   - The below treats half-A90 to A27 as a false negative.
    #   - The below treats cut-out corners as false negatives.
    #     - BUT, I probably don't want this function to consider cut-out corners
    #       either.
    return get_is_90_right_wall(relative_x, relative_y)


func get_is_top_left_corner_clipped(
        relative_x := 0,
        relative_y := 0) -> bool:
    return get_is_present(relative_x, relative_y) and \
            get_is_present(relative_x - 1, relative_y) and \
            get_is_present(relative_x, relative_y - 1) and \
            get_is_empty(relative_x - 1, relative_y - 1)


func get_is_top_right_corner_clipped(
        relative_x := 0,
        relative_y := 0) -> bool:
    return get_is_present(relative_x, relative_y) and \
            get_is_present(relative_x + 1, relative_y) and \
            get_is_present(relative_x, relative_y - 1) and \
            get_is_empty(relative_x + 1, relative_y - 1)


func get_is_bottom_left_corner_clipped(
        relative_x := 0,
        relative_y := 0) -> bool:
    return get_is_present(relative_x, relative_y) and \
            get_is_present(relative_x - 1, relative_y) and \
            get_is_present(relative_x, relative_y + 1) and \
            get_is_empty(relative_x - 1, relative_y + 1)


func get_is_bottom_right_corner_clipped(
        relative_x := 0,
        relative_y := 0) -> bool:
    return get_is_present(relative_x, relative_y) and \
            get_is_present(relative_x + 1, relative_y) and \
            get_is_present(relative_x, relative_y + 1) and \
            get_is_empty(relative_x + 1, relative_y + 1)


func get_is_top_left_corner_clipped_90_90(
        relative_x := 0,
        relative_y := 0) -> bool:
    return get_is_present(relative_x, relative_y) and \
            get_is_90_floor_at_right(
                relative_x - 1, relative_y) and \
            get_is_90_right_wall_at_bottom(
                relative_x, relative_y - 1)


func get_is_top_right_corner_clipped_90_90(
        relative_x := 0,
        relative_y := 0) -> bool:
    return get_is_present(relative_x, relative_y) and \
            get_is_90_floor_at_left(
                relative_x + 1, relative_y) and \
            get_is_90_left_wall_at_bottom(
                relative_x, relative_y - 1)


func get_is_bottom_left_corner_clipped_90_90(
        relative_x := 0,
        relative_y := 0) -> bool:
    return get_is_present(relative_x, relative_y) and \
            get_is_90_ceiling_at_right(
                relative_x - 1, relative_y) and \
            get_is_90_right_wall_at_top(
                relative_x, relative_y + 1)


func get_is_bottom_right_corner_clipped_90_90(
        relative_x := 0,
        relative_y := 0) -> bool:
    return get_is_present(relative_x, relative_y) and \
            get_is_90_ceiling_at_left(
                relative_x + 1, relative_y) and \
            get_is_90_left_wall_at_top(
                relative_x, relative_y + 1)


func get_is_top_left_corner_clipped_45_45(
        relative_x := 0,
        relative_y := 0) -> bool:
    return get_is_present(relative_x, relative_y) and \
            get_is_45_pos_floor(relative_x - 1, relative_y) and \
            get_is_45_pos_floor(relative_x, relative_y - 1)


func get_is_top_right_corner_clipped_45_45(
        relative_x := 0,
        relative_y := 0) -> bool:
    return get_is_present(relative_x, relative_y) and \
            get_is_45_neg_floor(relative_x + 1, relative_y) and \
            get_is_45_neg_floor(relative_x, relative_y - 1)


func get_is_bottom_left_corner_clipped_45_45(
        relative_x := 0,
        relative_y := 0) -> bool:
    return get_is_present(relative_x, relative_y) and \
            get_is_45_neg_ceiling(relative_x - 1, relative_y) and \
            get_is_45_neg_ceiling(relative_x, relative_y + 1)


func get_is_bottom_right_corner_clipped_45_45(
        relative_x := 0,
        relative_y := 0) -> bool:
    return get_is_present(relative_x, relative_y) and \
            get_is_45_pos_ceiling(relative_x + 1, relative_y) and \
            get_is_45_pos_ceiling(relative_x, relative_y + 1)


func get_is_top_left_corner_clipped_90H_45(
        relative_x := 0,
        relative_y := 0) -> bool:
    return get_is_present(relative_x, relative_y) and \
            get_is_90_floor_at_right(
                relative_x - 1, relative_y) and \
            get_is_45_pos_floor(relative_x, relative_y - 1)


func get_is_top_right_corner_clipped_90H_45(
        relative_x := 0,
        relative_y := 0) -> bool:
    return get_is_present(relative_x, relative_y) and \
            get_is_90_floor_at_right(
                relative_x + 1, relative_y) and \
            get_is_45_neg_floor(relative_x, relative_y - 1)


func get_is_bottom_left_corner_clipped_90H_45(
        relative_x := 0,
        relative_y := 0) -> bool:
    return get_is_present(relative_x, relative_y) and \
            get_is_90_ceiling_at_right(
                relative_x - 1, relative_y) and \
            get_is_45_neg_ceiling(relative_x, relative_y + 1)


func get_is_bottom_right_corner_clipped_90H_45(
        relative_x := 0,
        relative_y := 0) -> bool:
    return get_is_present(relative_x, relative_y) and \
            get_is_90_ceiling_at_left(
                relative_x + 1, relative_y) and \
            get_is_45_pos_ceiling(relative_x, relative_y + 1)


func get_is_top_left_corner_clipped_90V_45(
        relative_x := 0,
        relative_y := 0) -> bool:
    return get_is_present(relative_x, relative_y) and \
            get_is_45_pos_floor(relative_x - 1, relative_y) and \
            get_is_90_right_wall_at_bottom(relative_x, relative_y - 1)


func get_is_top_right_corner_clipped_90V_45(
        relative_x := 0,
        relative_y := 0) -> bool:
    return get_is_present(relative_x, relative_y) and \
            get_is_45_neg_floor(relative_x + 1, relative_y) and \
            get_is_90_left_wall_at_bottom(relative_x, relative_y - 1)


func get_is_bottom_left_corner_clipped_90V_45(
        relative_x := 0,
        relative_y := 0) -> bool:
    return get_is_present(relative_x, relative_y) and \
            get_is_45_neg_ceiling(relative_x - 1, relative_y) and \
            get_is_90_right_wall_at_top(relative_x, relative_y + 1)


func get_is_bottom_right_corner_clipped_90V_45(
        relative_x := 0,
        relative_y := 0) -> bool:
    return get_is_present(relative_x, relative_y) and \
            get_is_45_pos_ceiling(relative_x + 1, relative_y) and \
            get_is_90_left_wall_at_top(relative_x, relative_y + 1)


func get_is_top_left_corner_clipped_partial_45(
        relative_x := 0,
        relative_y := 0) -> bool:
    return get_is_present(relative_x, relative_y) and \
            (get_is_45_pos_floor(relative_x - 1, relative_y) or \
            get_is_45_pos_floor(relative_x, relative_y - 1))


func get_is_top_right_corner_clipped_partial_45(
        relative_x := 0,
        relative_y := 0) -> bool:
    return get_is_present(relative_x, relative_y) and \
            (get_is_45_neg_floor(relative_x + 1, relative_y) or \
            get_is_45_neg_floor(relative_x, relative_y - 1))


func get_is_bottom_left_corner_clipped_partial_45(
        relative_x := 0,
        relative_y := 0) -> bool:
    return get_is_present(relative_x, relative_y) and \
            (get_is_45_neg_ceiling(relative_x - 1, relative_y) or \
            get_is_45_neg_ceiling(relative_x, relative_y + 1))


func get_is_bottom_right_corner_clipped_partial_45(
        relative_x := 0,
        relative_y := 0) -> bool:
    return get_is_present(relative_x, relative_y) and \
            (get_is_45_pos_ceiling(relative_x + 1, relative_y) or \
            get_is_45_pos_ceiling(relative_x, relative_y + 1))


func get_is_top_left_corner_clipped_partial_27(
        relative_x := 0,
        relative_y := 0) -> bool:
    # FIXME: LEFT OFF HERE: -------- A27
    return false


func get_is_top_right_corner_clipped_partial_27(
        relative_x := 0,
        relative_y := 0) -> bool:
    # FIXME: LEFT OFF HERE: -------- A27
    return false


func get_is_bottom_left_corner_clipped_partial_27(
        relative_x := 0,
        relative_y := 0) -> bool:
    # FIXME: LEFT OFF HERE: -------- A27
    return false


func get_is_bottom_right_corner_clipped_partial_27(
        relative_x := 0,
        relative_y := 0) -> bool:
    # FIXME: LEFT OFF HERE: -------- A27
    return false









# FIXME: LEFT OFF HERE: -----------------------
# - Add helpers for internal cases.




func _get_is_int_90_90_concave_in_top_left() -> bool:
    # FIXME: LEFT OFF HERE: ------------------------
    return false


func _get_is_int_90h_along_top() -> bool:
    # FIXME: LEFT OFF HERE: ------------------------
    return false


func _get_is_int_90v_along_left() -> bool:
    # FIXME: LEFT OFF HERE: ------------------------
    return false


func _get_is_int_90h_to_45_in_top_left() -> bool:
    # FIXME: LEFT OFF HERE: ------------------------
    return false


func _get_is_int_90v_to_45_in_top_left() -> bool:
    # FIXME: LEFT OFF HERE: ------------------------
    return false


func _get_is_int_90h_to_27_shallow_in_top_left() -> bool:
    # FIXME: LEFT OFF HERE: -------- A27
    return false


func _get_is_int_90h_to_27_steep_short_in_top_left() -> bool:
    # FIXME: LEFT OFF HERE: -------- A27
    return false


func _get_is_int_90h_to_27_steep_long_in_top_left() -> bool:
    # FIXME: LEFT OFF HERE: -------- A27
    return false


func _get_is_int_90v_to_27_shallow_short_in_top_left() -> bool:
    # FIXME: LEFT OFF HERE: -------- A27
    return false


func _get_is_int_90v_to_27_shallow_long_in_top_left() -> bool:
    # FIXME: LEFT OFF HERE: -------- A27
    return false


func _get_is_int_90v_to_27_steep_in_top_left() -> bool:
    # FIXME: LEFT OFF HERE: -------- A27
    return false


func _get_is_int_45_ext_corner_in_top_left() -> bool:
    # FIXME: LEFT OFF HERE: ------------------------
    return false

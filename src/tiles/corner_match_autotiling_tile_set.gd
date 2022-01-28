tool
class_name CornerMatchAutotilingTileSet
extends SurfacesTileSet


# FIXME: LEFT OFF HERE: ----------------------------------
# - Plan how to deal with 45-interior-transition strips that don't actually fade
#   to dark, and then also end abruptly due to not opening up into a wider area.


# FIXME: LEFT OFF HERE: ------------------------------------------------------
# - Update the corner-type legend to match the latest enums list.

# FIXME: LEFT OFF HERE: --------------------------------------------------------------
# - RE-THINK THE BINDING STRATEGY!
# - Instead of being based on sides (top-left, top-right, left-top, left-bottom, etc.), be based on corners.
#   - This should be more intuitive to conceptualize, and less text to encode?
# - This might be more enum cases, but probably simpler logic for matching.
# SubtileCorner
enum {
    UNKNOWN,
    
    # Air or space beyond the collision boundary.
    EMPTY,
    # Space inside the collision boundary, but before transitioning to the
    # more-faded interior (green, purple, yellow, or light-grey in the
    # template).
    EXTERIOR,
    # Space both inside the collision boundary, and after transitioning to the
    # more-faded interior (the darker grey colors in the template).
    INTERIOR,
    
    EXT_90H,
    EXT_90V,
    EXT_90_90_CONVEX,
    EXT_90_90_CONCAVE,
    
    
    EXT_45_CONCAVE,
    EXT_45_FLOOR,
    EXT_45_CEILING,
    
    EXT_45_FLOOR_TO_90,
    EXT_45_FLOOR_TO_45_CONVEX,
    EXT_45_CEILING_TO_90,
    EXT_45_CEILING_TO_45_CONVEX,
    
    
    EXT_27_SHALLOW_CONCAVE,
    EXT_27_STEEP_CONCAVE,
    
    EXT_27P_FLOOR_SHALLOW,
    EXT_27N_FLOOR_SHALLOW,
    EXT_27P_FLOOR_STEEP,
    EXT_27N_FLOOR_STEEP,
    
    
    EXT_27P_CEILING_SHALLOW,
    EXT_27N_CEILING_SHALLOW,
    EXT_27P_CEILING_STEEP,
    EXT_27N_CEILING_STEEP,
    
    
    EXT_90H_45_CONCAVE,
    EXT_90V_45_CONCAVE,
    
    EXT_90H_45_CONVEX,
    EXT_90V_45_CONVEX,
    EXT_90H_45_CONVEX_ACUTE,
    EXT_90V_45_CONVEX_ACUTE,
    
    
    INT_90H,
    INT_90V,
    INT_90_90_CONCAVE,
    INT_90_90_CONVEX,
    INT_90H_TO_45,
    INT_90V_TO_45,
    INT_90H_TO_27_SHALLOW,
    INT_90H_TO_27_STEEP_SHORT,
    INT_90H_TO_27_STEEP_LONG,
    INT_90V_TO_27_SHALLOW_SHORT,
    INT_90V_TO_27_SHALLOW_LONG,
    INT_90V_TO_27_STEEP,
    
    INT_45_EXT_CORNER,
    INT_45_EXT_CORNER_TO_90H,
    INT_45_EXT_CORNER_TO_90V,
    INT_45_EXT_CORNER_TO_90H_AND_90V,
    
    INT_45_INT_CORNER,
    INT_45_INT_CORNER_WITH_90_90_CONCAVE,
    INT_45_INT_CORNER_WITH_90_90_CONVEX,
    INT_45_INT_CORNER_WITH_90H,
    INT_45_INT_CORNER_WITH_90V,
    INT_45_INT_CORNER_NARROW,
    INT_45_MID_NOTCH_H,
    INT_45_MID_NOTCH_V,
    
    INT_27_INT_CORNER_SHALLOW,
    INT_27_INT_CORNER_STEEP,
}

# FIXME: LEFT OFF HERE: -----------------------------------------
# - Is there a simpler way to allow the tile-set author to configure which
#   slopes are allowed to transition into which others?

# NOTE:
# -   This mapping enables us to match one corner type with another.
# -   Defining a value as negative will configure it as a valid match, but with
#     a lower-priority than a positive value.
# -   This maps from an expected target corner type to what is actually
#     configured in the given tile-set.
var _CORNER_TYPE_TO_ADDITIONAL_MATCHING_TYPES := {
    UNKNOWN: [],
    
    EMPTY: [EXT_90_90_CONVEX, EXT_90H_45_CONVEX_ACUTE, EXT_90V_45_CONVEX_ACUTE],
    EXTERIOR: [],
    INTERIOR: [],
    
    EXT_90H: [],
    EXT_90V: [],
    EXT_90_90_CONVEX: [EMPTY],
    EXT_90_90_CONCAVE: [-EXT_45_CONCAVE],
    
    
    EXT_45_CONCAVE: [],
    EXT_45_FLOOR: [],
    EXT_45_CEILING: [],
    
    EXT_45_FLOOR_TO_90: [-EXT_45_FLOOR],
    EXT_45_FLOOR_TO_45_CONVEX: [-EXT_45_FLOOR],
    EXT_45_CEILING_TO_90: [-EXT_45_CEILING],
    EXT_45_CEILING_TO_45_CONVEX: [-EXT_45_CEILING],
    
    
    EXT_27_SHALLOW_CONCAVE: [-EXT_45_CONCAVE],
    EXT_27_STEEP_CONCAVE: [-EXT_45_CONCAVE],
    EXT_27P_FLOOR_SHALLOW: [-EXT_90H],
    EXT_27N_FLOOR_SHALLOW: [-EXT_90H],
    EXT_27P_FLOOR_STEEP: [-EXT_90V],
    EXT_27N_FLOOR_STEEP: [-EXT_90V],
    
    
    EXT_27P_CEILING_SHALLOW: [-EXT_90H],
    EXT_27N_CEILING_SHALLOW: [-EXT_90H],
    EXT_27P_CEILING_STEEP: [-EXT_90V],
    EXT_27N_CEILING_STEEP: [-EXT_90V],
    
    
    EXT_90H_45_CONCAVE: [-EXT_45_CONCAVE],
    EXT_90V_45_CONCAVE: [-EXT_45_CONCAVE],
    EXT_90H_45_CONVEX: [-EXT_90H],
    EXT_90V_45_CONVEX: [-EXT_90V],
    EXT_90H_45_CONVEX_ACUTE: [EMPTY, EXT_90_90_CONVEX, EXT_90V_45_CONVEX_ACUTE],
    EXT_90V_45_CONVEX_ACUTE: [EMPTY, EXT_90_90_CONVEX, EXT_90H_45_CONVEX_ACUTE],
    
    # FIXME: LEFT OFF HERE: ------------------------------------
    
    INT_90H: [],
    INT_90V: [],
    INT_90_90_CONCAVE: [],
    INT_90_90_CONVEX: [],
    INT_90H_TO_45: [],
    INT_90V_TO_45: [],
    INT_90H_TO_27_SHALLOW: [],
    INT_90H_TO_27_STEEP_SHORT: [],
    INT_90H_TO_27_STEEP_LONG: [],
    INT_90V_TO_27_SHALLOW_SHORT: [],
    INT_90V_TO_27_SHALLOW_LONG: [],
    INT_90V_TO_27_STEEP: [],
    
    INT_45_EXT_CORNER: [],
    INT_45_EXT_CORNER_TO_90H: [],
    INT_45_EXT_CORNER_TO_90V: [],
    INT_45_EXT_CORNER_TO_90H_AND_90V: [],
    
    INT_45_INT_CORNER: [],
    INT_45_INT_CORNER_WITH_90_90_CONCAVE: [],
    INT_45_INT_CORNER_WITH_90_90_CONVEX: [],
    INT_45_INT_CORNER_WITH_90H: [],
    INT_45_INT_CORNER_WITH_90V: [],
    INT_45_INT_CORNER_NARROW: [],
    INT_45_MID_NOTCH_H: [],
    INT_45_MID_NOTCH_V: [],
    
    INT_27_INT_CORNER_SHALLOW: [],
    INT_27_INT_CORNER_STEEP: [],
}

var _CORNERS := ["tl", "tr", "bl", "br"]

# FIXME: LEFT OFF HERE: --------------------------------
var _ACCEPTABLE_MATCH_PRIORITY_THRESHOLD := 2.0

# Dictionary<int, String>
var _SUBTILE_CORNER_TYPE_VALUE_TO_KEY: Dictionary

# Dictionary<
#     ("tl"|"tr"|"bl"|"br"),
#     Dictionary<
#         SubtileCorner,
#         Dictionary<Vector2, {
#             p: Vector2,
#             a: Array<90|45|27>,
#             tl: SubtileCorner,
#             tr: SubtileCorner,
#             bl: SubtileCorner,
#             br: SubtileCorner,
#         }>>>
var _corner_to_type_to_subtiles: Dictionary

var _error_indicator_subtile_position: Vector2

# -   If true, the autotiling logic will try to find the best match given which
#     subtiles are available.
#     -   The tile-set author can then omit many of the possible subtile angle
#         combinations.
#     -   This may impact performance if many tiles are updated frequently at
#         run time.
# -   If false, the autotiling logic will assume all possible subtile angle
#         combinations are defined.
#     -   The tile-set author then needs to draw, and configure in GDScript,
#         many more subtile angle combinations.
#     -   Only exact matches will be used.
#     -   If an exact match isn't defined, then a single given fallback
#         error-indicator subtile will be used.
#     -   The level author can then see the error-indicator subtile and change
#         their level topography to instead use whichever subtiles are
#         available.
var _allows_partial_matches: bool

# -   If false, then custom corner-match autotiling behavior will not happen at
#     runtime, and will only happen when editing within the scene editor.
var _supports_runtime_autotiling: bool


func _init(
        tiles_manifest: Array,
        subtiles_manifest: Dictionary,
        allows_partial_matches: bool,
        supports_runtime_autotiling: bool).(tiles_manifest) -> void:
    self._allows_partial_matches = allows_partial_matches
    self._supports_runtime_autotiling = supports_runtime_autotiling
    _parse_enum_key_values()
    _parse_subtiles_manifest(subtiles_manifest)


func _parse_subtiles_manifest(subtiles_manifest: Dictionary) -> void:
    if !Engine.editor_hint and \
            !_supports_runtime_autotiling:
        return
    
    # FIXME: LEFT OFF HERE: ----------------- Parse other parts of manifest.
    
    assert(subtiles_manifest.has("error_indicator_subtile_position") and \
            subtiles_manifest.error_indicator_subtile_position is Vector2)
    _error_indicator_subtile_position = \
            subtiles_manifest.error_indicator_subtile_position
    
    # Check that the corner-type enum values match the
    # corner-type-to-matching-types map.
    assert(_SUBTILE_CORNER_TYPE_VALUE_TO_KEY.size() == \
            _CORNER_TYPE_TO_ADDITIONAL_MATCHING_TYPES.size())
    for corner_type in _SUBTILE_CORNER_TYPE_VALUE_TO_KEY:
        assert(_CORNER_TYPE_TO_ADDITIONAL_MATCHING_TYPES.has(corner_type))
        assert(_CORNER_TYPE_TO_ADDITIONAL_MATCHING_TYPES[corner_type is Array])
    
    # Convert additional-matching arrays into sets.
    for corner_type in _CORNER_TYPE_TO_ADDITIONAL_MATCHING_TYPES:
        var list: Array = _CORNER_TYPE_TO_ADDITIONAL_MATCHING_TYPES[corner_type]
        var set := {}
        for matching_type in list:
            set[matching_type] = true
        _CORNER_TYPE_TO_ADDITIONAL_MATCHING_TYPES[corner_type] = set
    
    # Create the nested dictionary structure for holding the subtile manifest.
    for corner in _CORNERS:
        var type_to_subtiles := {}
        _corner_to_type_to_subtiles[corner] = type_to_subtiles
        for corner_type in _SUBTILE_CORNER_TYPE_VALUE_TO_KEY:
            if _get_is_subtile_corner_type_interesting(corner_type):
                var subtiles := {}
                type_to_subtiles[corner_type] = subtiles
    
    # Create a structured mapping to subtile positions based on type.
    for subtile_config in subtiles_manifest.subtiles:
        assert(subtile_config.has("p") and \
                subtile_config.p is Vector2)
        assert(subtile_config.has("a"))
        
        # Parse angle types.
        var angle_types: Array = \
                subtile_config.a if \
                subtile_config.a is Array else \
                [subtile_config.a]
        var is_angle_type_90 := false
        var is_angle_type_45 := false
        var is_angle_type_27 := false
        for angle_type in angle_types:
            assert(angle_type == 90 or \
                    angle_type == 45 or \
                    angle_type == 27)
            if angle_type == 90:
                assert(!is_angle_type_90)
                is_angle_type_90 = true
            if angle_type == 45:
                assert(!is_angle_type_45)
                is_angle_type_45 = true
            if angle_type == 27:
                assert(!is_angle_type_27)
                is_angle_type_27 = true
        subtile_config.is_a90 = is_angle_type_90
        subtile_config.is_a45 = is_angle_type_45
        subtile_config.is_a27 = is_angle_type_27
        subtile_config.erase("a")
        
        # Add to corresponding corner/corner-type maps.
        var position: Vector2 = subtile_config.p
        var was_a_corner_interesting := false
        for corner in _CORNERS:
            assert(subtile_config.has(corner))
            var corner_type: int = subtile_config[corner]
            assert(corner_type is int and corner_type != UNKNOWN)
            if _get_is_subtile_corner_type_interesting(corner_type):
                _corner_to_type_to_subtiles[corner][corner_type][position] = \
                        subtile_config
                was_a_corner_interesting = true
        assert(was_a_corner_interesting)


# This hacky function exists for a couple reasons:
# -   We need to be able to use the anonymous enum syntax for these
#     SubtileCorner values, so that tile-set authors don't need to include so
#     many extra characters for the enum prefix in their GDScript
#     configurations.
# -   We need to be able to print the key for a given enum value, so that a
#     human can debug what's going on.
# -   We need to be able to iterate over all possible enum values.
# -   GDScript's type system doesn't allow referencing the name of a class from
#     within that class.
func _parse_enum_key_values() -> void:
    if !Engine.editor_hint and \
            !_supports_runtime_autotiling:
        return
    
    var script: Script = self.get_script()
    var constants := script.get_script_constant_map()
    while !constants.has("EMPTY"):
        script = script.get_base_script()
        constants = script.get_script_constant_map()
    for key in constants:
        _SUBTILE_CORNER_TYPE_VALUE_TO_KEY[constants[key]] = key


func get_subtile_corner_string(type: int) -> String:
    return _SUBTILE_CORNER_TYPE_VALUE_TO_KEY[type]


func get_subtile_config_string(subtile_config: Dictionary) -> String:
    var optional_position_string: String = \
            "p:%s, " % subtile_config.p if \
            subtile_config.has("p") else \
            ""
    return "{%stl:%s, tr:%s, bl:%s, br:%s}" % [
        optional_position_string,
        get_subtile_corner_string(subtile_config.tl),
        get_subtile_corner_string(subtile_config.tr),
        get_subtile_corner_string(subtile_config.bl),
        get_subtile_corner_string(subtile_config.br),
    ]


func _get_is_subtile_corner_type_interesting(type: int) -> bool:
    return type != UNKNOWN and \
            type != EMPTY and \
            type != EXTERIOR and \
            type != INTERIOR


func _get_does_angle_type_match(
        actual_corners: Dictionary,
        expected_corners: Dictionary) -> bool:
    return expected_corners.is_a90 and actual_corners.is_a90 or \
            expected_corners.is_a45 and actual_corners.is_a45 or \
            expected_corners.is_a27 and actual_corners.is_a27


func _get_match_priority(
        actual_corners: Dictionary,
        expected_corners: Dictionary) -> float:
    var priority := 0.0
    
    for corner in _CORNERS:
        var actual_corner: int = actual_corners[corner]
        var expected_corner: int = expected_corners[corner]
        
        # Determine the priority-contribution for this corner.
        if actual_corner == expected_corner:
            priority += 1.0
        var additional_matching_types: Dictionary = \
                _CORNER_TYPE_TO_ADDITIONAL_MATCHING_TYPES[expected_corner]
        if additional_matching_types.has(actual_corner):
            if additional_matching_types[actual_corner] > 0:
                priority += 1.0
            else:
                priority += 0.5
        else:
            # FIXME: -------------- Is there a more elegant fallback for this?
            priority += -4.0
    
    return priority


func _forward_subtile_selection(
        tile_id: int,
        bitmask: int,
        tile_map: Object,
        cell_position: Vector2):
    var subtile_position := Vector2.INF
    
    if Engine.editor_hint or \
            _supports_runtime_autotiling:
        var proximity := CellProximity.new(
                tile_map,
                self,
                cell_position,
                tile_id)
        subtile_position = _choose_subtile(proximity)
    
    if subtile_position != Vector2.INF:
        return subtile_position
    else:
        # Fallback to Godot's default autotiling behavior.
        # NOTE:
        # -   Not returning any value here is terrible.
        # -   However, the underlying API apparently doesn't support returning
        #     any actual values that would indicate redirecting back to the
        #     default behavior.
        return


func _choose_subtile(proximity: CellProximity) -> Vector2:
    var target_corners := _get_target_corners(proximity)
    
    # Dictionary<("tl"|"tr"|"bl"|"br"), Dictionary<Vector2, Dictionary>>
    var corner_to_matches := {}
    for corner in _CORNERS:
        var corner_type: int = target_corners[corner]
        corner_to_matches[corner] = \
                _corner_to_type_to_subtiles[corner][corner_type] if \
                _get_is_subtile_corner_type_interesting(corner_type) else \
                {}
    
    # FIXME: LEFT OFF HERE: ---------------------------
    # - As an efficiency step, first check if the pre-existing cell in the
    #   TileMap already has the ideal match.
    
    # FIXME: LEFT OFF HERE: --------------------------------------
    # - Add support for also checking eight in-bound neighbor corner types when
    #   choosing subtiles.
    
    if _allows_partial_matches:
        var set := {}
        var queue := PriorityQueue.new([], false)
        
        for corner in _CORNERS:
            for corner_match in corner_to_matches[corner]:
                if !_get_does_angle_type_match(corner_match, target_corners):
                    # Skip the possible corner match, since it doesn't match
                    # the angle type.
                    continue
                
                var priority := \
                        _get_match_priority(corner_match, target_corners)
                var subtile_position: Vector2 = corner_match.p
                
                if !set.has(subtile_position):
                    set[subtile_position] = true
                    if queue.get_root_priority() == priority:
                        Sc.logger.warning(
                                ("Two subtiles have the same priority: " + \
                                "p1=%s, p2=%s, corners=%s") % [
                                    Sc.utils.get_vector_string(
                                        queue.get_root_value(), 0),
                                    Sc.utils.get_vector_string(
                                        subtile_position, 0),
                                    get_subtile_config_string(target_corners),
                                ])
                    queue.insert(priority, subtile_position)
        
        if queue.get_size() > 0:
            if queue.get_root_priority() < _ACCEPTABLE_MATCH_PRIORITY_THRESHOLD:
                Sc.logger.warning("No subtile was found with a good match.")
            return queue.get_root_value()
        else:
            return _error_indicator_subtile_position
        
    else:
        # Look for a subtile config that matches along all corners.
        for corner in _CORNERS:
            for corner_match in corner_to_matches[corner]:
                var match_priority := \
                        _get_match_priority(corner_match, target_corners)
                var matches_all_corners = match_priority == 4.0
                if matches_all_corners:
                    return corner_match.p
            if _get_is_subtile_corner_type_interesting(target_corners[corner]):
                # If this corner type was interesting, and we didn't find a
                # perfect match for it, then we know that none of the other
                # corner mappings will have a perfect match either.
                break
        Sc.logger.warning(
                "No subtile was found with a perfect match: %s" % \
                get_subtile_config_string(target_corners))
        return _error_indicator_subtile_position


static func _get_target_corners(proximity: CellProximity) -> Dictionary:
    var top_proximity := CellProximity.new(
            proximity.tile_map,
            proximity.tile_set,
            proximity.position + Vector2(0, -1))
    var bottom_proximity := CellProximity.new(
            proximity.tile_map,
            proximity.tile_set,
            proximity.position + Vector2(0, 1))
    var left_proximity := CellProximity.new(
            proximity.tile_map,
            proximity.tile_set,
            proximity.position + Vector2(-1, 0))
    var right_proximity := CellProximity.new(
            proximity.tile_map,
            proximity.tile_set,
            proximity.position + Vector2(1, 0))
    return {
        tl = _get_target_top_left_corner(proximity),
        tr = _get_target_top_right_corner(proximity),
        bl = _get_target_bottom_left_corner(proximity),
        br = _get_target_bottom_right_corner(proximity),
        inbound_t_bl = _get_target_bottom_left_corner(top_proximity),
        inbound_t_br = _get_target_bottom_right_corner(top_proximity),
        inbound_b_tl = _get_target_top_left_corner(bottom_proximity),
        inbound_b_tr = _get_target_top_right_corner(bottom_proximity),
        inbound_l_tr = _get_target_top_right_corner(left_proximity),
        inbound_l_br = _get_target_bottom_right_corner(left_proximity),
        inbound_r_tl = _get_target_top_left_corner(right_proximity),
        inbound_r_bl = _get_target_bottom_left_corner(right_proximity),
        is_a90 = proximity.is_angle_type_90,
        is_a45 = proximity.is_angle_type_45,
        is_a27 = proximity.is_angle_type_27,
    }


static func _get_target_top_left_corner(proximity: CellProximity) -> int:
    if proximity.is_top_empty:
        if proximity.is_left_empty:
            return EMPTY
        else:
            # Top empty, left present.
            if proximity.get_is_90_floor_at_left():
                if proximity.get_is_45_pos_floor_right(-1, 0):
                    return EXT_90H_45_CONVEX
                else:
                    return EXT_90H
            elif proximity.get_is_45_neg_floor():
                if proximity.get_is_45_pos_floor(-1, 0):
                    return EXT_45_FLOOR_TO_45_CONVEX
                elif proximity.get_is_90_floor_at_right(-1, 0):
                    return EXT_45_FLOOR_TO_90
                else:
                    return EXT_45_FLOOR
            elif proximity.is_angle_27:
                # FIXME: LEFT OFF HERE: -------- A27
                pass
            else:
                Sc.logger.error()
    else:
        if proximity.is_left_empty:
            # Top present, left empty.
            if proximity.get_is_90_right_wall_at_top():
                if proximity.get_is_45_pos_floor(0, -1):
                    return EXT_90V_45_CONVEX
                else:
                    return EXT_90V
            elif proximity.get_is_45_neg_ceiling():
                if proximity.get_is_45_pos_floor(0, -1):
                    return EXT_45_CEILING_TO_45_CONVEX
                elif proximity.get_is_90_right_wall_at_bottom(0, -1):
                    return EXT_45_CEILING_TO_90
                else:
                    return EXT_45_CEILING
            elif proximity.is_angle_27:
                # FIXME: LEFT OFF HERE: -------- A27
                pass
            else:
                Sc.logger.error()
        else:
            # Adjacent sides are present.
            if proximity.is_top_left_empty:
                # Adjacent sides are present, adjacent corner is empty.
                if proximity.get_is_90_right_wall_at_bottom(0, -1):
                    if proximity.get_is_90_floor_at_right(-1, 0):
                        return EXT_90_90_CONCAVE
                    elif proximity.get_is_45_pos_floor(-1, 0):
                        return EXT_90V_45_CONCAVE
                    elif proximity.get_angle_type(-1, 0) == CellAngleType.A27:
                        # FIXME: LEFT OFF HERE: -------- A27
                        pass
                    else:
                        Sc.logger.error()
                elif proximity.get_is_45_pos_floor(0, -1):
                    if proximity.get_is_90_floor_at_right(-1, 0):
                        return EXT_90H_45_CONCAVE
                    elif proximity.get_is_45_pos_floor(-1, 0):
                        return EXT_45_CONCAVE
                    elif proximity.get_angle_type(-1, 0) == CellAngleType.A27:
                        # FIXME: LEFT OFF HERE: -------- A27
                        pass
                    else:
                        Sc.logger.error()
                elif proximity.get_angle_type(0, -1) == CellAngleType.A27:
                    # FIXME: LEFT OFF HERE: -------- A27
                    pass
                else:
                    Sc.logger.error()
            else:
                # Adjacent sides and corner are present.
                if proximity.is_bottom_present and \
                        proximity.is_right_present and \
                        proximity.is_bottom_left_empty and \
                        proximity.is_bottom_right_empty and \
                        !proximity.is_top_right_empty:
                    return INT_45_MID_NOTCH_H
                elif proximity.is_bottom_present and \
                        proximity.is_right_present and \
                        proximity.is_top_right_empty and \
                        proximity.is_bottom_right_empty and \
                        !proximity.is_bottom_left_empty:
                    return INT_45_MID_NOTCH_V
                elif proximity.is_bottom_empty or \
                        proximity.is_right_empty or \
                        proximity.is_top_right_empty or \
                        proximity.is_bottom_left_empty:
                    # This corner is not deep enough to have transitioned to
                    # interior.
                    return EXTERIOR
                elif proximity.is_bottom_right_empty:
                    # Only exposed at opposite corner.
                    if proximity.get_is_bottom_right_corner_clipped_partial_45():
                        if proximity.get_is_bottom_right_corner_clipped_partial_27():
                            # FIXME: LEFT OFF HERE: -------- A27
                            pass
                        else:
                            # 45 cutout.
                            if proximity.is_top_left_empty_at_top_left:
                                # FIXME: LEFT OFF HERE: --------------------------------------------------------------
                                # - Replace these with non-tile-type-specific checks.
                                # - Instead, check for a 90-90 cutout IN THE NEIGHBOR.
                                if proximity.get_angle_type(-1, -1) == CellAngleType.A90:
                                    return INT_45_INT_CORNER_WITH_90_90_CONCAVE
                                elif proximity.get_angle_type(-1, -1) == CellAngleType.A27:
                                    # FIXME: LEFT OFF HERE: -------- A27
                                    pass
                                else:
                                    return INT_45_INT_CORNER_NARROW
                            elif proximity.is_left_empty_at_left and \
                                    proximity.is_top_empty_at_top:
                                return INT_45_INT_CORNER_WITH_90_90_CONVEX
                            elif proximity.is_left_empty_at_left:
                                return INT_45_INT_CORNER_WITH_90V
                            elif proximity.is_top_empty_at_top:
                                return INT_45_INT_CORNER_WITH_90H
                            else:
                                return INT_45_INT_CORNER
                    else:
                        if proximity.get_is_bottom_right_corner_clipped_partial_27():
                            # FIXME: LEFT OFF HERE: -------- A27
                            pass
                        else:
                            # 90-90 cutout.
                            return EXTERIOR
                else:
                    # Fully interior.
                    # FIXME: LEFT OFF HERE: -----------------------------------------
                    # - Pause this logic until adding some more CellProximity
                    #   helpers for internal cases.
                    pass
                    return INTERIOR
                    
                    
                    if proximity.is_top_empty_at_top:
                        if proximity.is_left_empty_at_left:
                            if proximity.is_top_left_empty_at_top_left:
                                # FIXME: LEFT OFF HERE: ---------------------------------------
                                pass
                            else:
                                # FIXME: LEFT OFF HERE: ---------------------------------------
                                pass
                        else:
                            # FIXME: LEFT OFF HERE: ---------------------------------------
                            pass
                    else:
                        # FIXME: LEFT OFF HERE: ---------------------------------------
                        pass
    
    # FIXME: LEFT OFF HERE: ---------- Remove after adding all above cases.
    return UNKNOWN


static func _get_target_top_right_corner(proximity: CellProximity) -> int:
    if proximity.is_top_empty:
        if proximity.is_right_empty:
            return EMPTY
        else:
            # Top empty, right present.
            if proximity.get_is_90_floor_at_right():
                if proximity.get_is_45_pos_floor_left(1, 0):
                    return EXT_90H_45_CONVEX
                else:
                    return EXT_90H
            elif proximity.get_is_45_neg_floor():
                if proximity.get_is_45_pos_floor(1, 0):
                    return EXT_45_FLOOR_TO_45_CONVEX
                elif proximity.get_is_90_floor_at_left(1, 0):
                    return EXT_45_FLOOR_TO_90
                else:
                    return EXT_45_FLOOR
            elif proximity.is_angle_27:
                # FIXME: LEFT OFF HERE: -------- A27
                pass
            else:
                Sc.logger.error()
    else:
        if proximity.is_right_empty:
            # Top present, right empty.
            if proximity.get_is_90_left_wall_at_top():
                if proximity.get_is_45_pos_floor(0, -1):
                    return EXT_90V_45_CONVEX
                else:
                    return EXT_90V
            elif proximity.get_is_45_neg_ceiling():
                if proximity.get_is_45_pos_floor(0, -1):
                    return EXT_45_CEILING_TO_45_CONVEX
                elif proximity.get_is_90_left_wall_at_bottom(0, -1):
                    return EXT_45_CEILING_TO_90
                else:
                    return EXT_45_CEILING
            elif proximity.is_angle_27:
                # FIXME: LEFT OFF HERE: -------- A27
                pass
            else:
                Sc.logger.error()
        else:
            # Adjacent sides are present.
            if proximity.is_top_right_empty:
                # Adjacent sides are present, adjacent corner is empty.
                if proximity.get_is_90_left_wall_at_bottom(0, -1):
                    if proximity.get_is_90_floor_at_left(1, 0):
                        return EXT_90_90_CONCAVE
                    elif proximity.get_is_45_pos_floor(1, 0):
                        return EXT_90V_45_CONCAVE
                    elif proximity.get_angle_type(1, 0) == CellAngleType.A27:
                        # FIXME: LEFT OFF HERE: -------- A27
                        pass
                    else:
                        Sc.logger.error()
                elif proximity.get_is_45_pos_floor(0, -1):
                    if proximity.get_is_90_floor_at_left(1, 0):
                        return EXT_90H_45_CONCAVE
                    elif proximity.get_is_45_pos_floor(1, 0):
                        return EXT_45_CONCAVE
                    elif proximity.get_angle_type(1, 0) == CellAngleType.A27:
                        # FIXME: LEFT OFF HERE: -------- A27
                        pass
                    else:
                        Sc.logger.error()
                elif proximity.get_angle_type(0, -1) == CellAngleType.A27:
                    # FIXME: LEFT OFF HERE: -------- A27
                    pass
                else:
                    Sc.logger.error()
            else:
                # Adjacent sides and corner are present.
                if proximity.is_bottom_present and \
                        proximity.is_left_present and \
                        proximity.is_bottom_right_empty and \
                        proximity.is_bottom_left_empty and \
                        !proximity.is_top_left_empty:
                    return INT_45_MID_NOTCH_H
                elif proximity.is_bottom_present and \
                        proximity.is_left_present and \
                        proximity.is_top_left_empty and \
                        proximity.is_bottom_left_empty and \
                        !proximity.is_bottom_right_empty:
                    return INT_45_MID_NOTCH_V
                elif proximity.is_bottom_empty or \
                        proximity.is_left_empty or \
                        proximity.is_top_left_empty or \
                        proximity.is_bottom_right_empty:
                    # This corner is not deep enough to have transitioned to
                    # interior.
                    return EXTERIOR
                elif proximity.is_bottom_left_empty:
                    # Only exposed at opposite corner.
                    if proximity.get_is_bottom_left_corner_clipped_partial_45():
                        if proximity.get_is_bottom_left_corner_clipped_partial_27():
                            # FIXME: LEFT OFF HERE: -------- A27
                            pass
                        else:
                            # 45 cutout.
                            if proximity.is_top_right_empty_at_top_right:
                                # FIXME: LEFT OFF HERE: --------------------------------------------------------------
                                # - Replace these with non-tile-type-specific checks.
                                # - Instead, check for a 90-90 cutout IN THE NEIGHBOR.
                                if proximity.get_angle_type(1, -1) == CellAngleType.A90:
                                    return INT_45_INT_CORNER_WITH_90_90_CONCAVE
                                elif proximity.get_angle_type(1, -1) == CellAngleType.A27:
                                    # FIXME: LEFT OFF HERE: -------- A27
                                    pass
                                else:
                                    return INT_45_INT_CORNER_NARROW
                            elif proximity.is_right_empty_at_right and \
                                    proximity.is_top_empty_at_top:
                                return INT_45_INT_CORNER_WITH_90_90_CONVEX
                            elif proximity.is_right_empty_at_right:
                                return INT_45_INT_CORNER_WITH_90V
                            elif proximity.is_top_empty_at_top:
                                return INT_45_INT_CORNER_WITH_90H
                            else:
                                return INT_45_INT_CORNER
                    else:
                        if proximity.get_is_bottom_left_corner_clipped_partial_27():
                            # FIXME: LEFT OFF HERE: -------- A27
                            pass
                        else:
                            # 90-90 cutout.
                            return EXTERIOR
                else:
                    # Fully interior.
                    # FIXME: LEFT OFF HERE: -----------------------------------------
                    # - Pause this logic until adding some more CellProximity
                    #   helpers for internal cases.
                    pass
                    return INTERIOR
                    
                    
                    if proximity.is_top_empty_at_top:
                        if proximity.is_right_empty_at_right:
                            if proximity.is_top_right_empty_at_top_right:
                                # FIXME: LEFT OFF HERE: ---------------------------------------
                                pass
                            else:
                                # FIXME: LEFT OFF HERE: ---------------------------------------
                                pass
                        else:
                            # FIXME: LEFT OFF HERE: ---------------------------------------
                            pass
                    else:
                        # FIXME: LEFT OFF HERE: ---------------------------------------
                        pass
    
    # FIXME: LEFT OFF HERE: ---------- Remove after adding all above cases.
    return UNKNOWN


static func _get_target_bottom_left_corner(proximity: CellProximity) -> int:
    if proximity.is_bottom_empty:
        if proximity.is_left_empty:
            return EMPTY
        else:
            # Bottom empty, left present.
            if proximity.get_is_90_floor_at_left():
                if proximity.get_is_45_pos_floor_right(-1, 0):
                    return EXT_90H_45_CONVEX
                else:
                    return EXT_90H
            elif proximity.get_is_45_neg_floor():
                if proximity.get_is_45_pos_floor(-1, 0):
                    return EXT_45_FLOOR_TO_45_CONVEX
                elif proximity.get_is_90_floor_at_right(-1, 0):
                    return EXT_45_FLOOR_TO_90
                else:
                    return EXT_45_FLOOR
            elif proximity.is_angle_27:
                # FIXME: LEFT OFF HERE: -------- A27
                pass
            else:
                Sc.logger.error()
    else:
        if proximity.is_left_empty:
            # Bottom present, left empty.
            if proximity.get_is_90_right_wall_at_bottom():
                if proximity.get_is_45_pos_floor(0, 1):
                    return EXT_90V_45_CONVEX
                else:
                    return EXT_90V
            elif proximity.get_is_45_neg_ceiling():
                if proximity.get_is_45_pos_floor(0, 1):
                    return EXT_45_CEILING_TO_45_CONVEX
                elif proximity.get_is_90_right_wall_at_top(0, 1):
                    return EXT_45_CEILING_TO_90
                else:
                    return EXT_45_CEILING
            elif proximity.is_angle_27:
                # FIXME: LEFT OFF HERE: -------- A27
                pass
            else:
                Sc.logger.error()
        else:
            # Adjacent sides are present.
            if proximity.is_bottom_left_empty:
                # Adjacent sides are present, adjacent corner is empty.
                if proximity.get_is_90_right_wall_at_top(0, 1):
                    if proximity.get_is_90_floor_at_right(-1, 0):
                        return EXT_90_90_CONCAVE
                    elif proximity.get_is_45_pos_floor(-1, 0):
                        return EXT_90V_45_CONCAVE
                    elif proximity.get_angle_type(-1, 0) == CellAngleType.A27:
                        # FIXME: LEFT OFF HERE: -------- A27
                        pass
                    else:
                        Sc.logger.error()
                elif proximity.get_is_45_pos_floor(0, -1):
                    if proximity.get_is_90_floor_at_right(-1, 0):
                        return EXT_90H_45_CONCAVE
                    elif proximity.get_is_45_pos_floor(-1, 0):
                        return EXT_45_CONCAVE
                    elif proximity.get_angle_type(-1, 0) == CellAngleType.A27:
                        # FIXME: LEFT OFF HERE: -------- A27
                        pass
                    else:
                        Sc.logger.error()
                elif proximity.get_angle_type(0, 1) == CellAngleType.A27:
                    # FIXME: LEFT OFF HERE: -------- A27
                    pass
                else:
                    Sc.logger.error()
            else:
                # Adjacent sides and corner are present.
                if proximity.is_top_present and \
                        proximity.is_right_present and \
                        proximity.is_top_left_empty and \
                        proximity.is_top_right_empty and \
                        !proximity.is_bottom_right_empty:
                    return INT_45_MID_NOTCH_H
                elif proximity.is_top_present and \
                        proximity.is_right_present and \
                        proximity.is_bottom_right_empty and \
                        proximity.is_top_right_empty and \
                        !proximity.is_top_left_empty:
                    return INT_45_MID_NOTCH_V
                elif proximity.is_top_empty or \
                        proximity.is_right_empty or \
                        proximity.is_bottom_right_empty or \
                        proximity.is_top_left_empty:
                    # This corner is not deep enough to have transitioned to
                    # interior.
                    return EXTERIOR
                elif proximity.is_top_right_empty:
                    # Only exposed at opposite corner.
                    if proximity.get_is_top_right_corner_clipped_partial_45():
                        if proximity.get_is_top_right_corner_clipped_partial_27():
                            # FIXME: LEFT OFF HERE: -------- A27
                            pass
                        else:
                            # 45 cutout.
                            if proximity.is_bottom_left_empty_at_bottom_left:
                                # FIXME: LEFT OFF HERE: --------------------------------------------------------------
                                # - Replace these with non-tile-type-specific checks.
                                # - Instead, check for a 90-90 cutout IN THE NEIGHBOR.
                                if proximity.get_angle_type(-1, 1) == CellAngleType.A90:
                                    return INT_45_INT_CORNER_WITH_90_90_CONCAVE
                                elif proximity.get_angle_type(-1, 1) == CellAngleType.A27:
                                    # FIXME: LEFT OFF HERE: -------- A27
                                    pass
                                else:
                                    return INT_45_INT_CORNER_NARROW
                            elif proximity.is_left_empty_at_left and \
                                    proximity.is_bottom_empty_at_bottom:
                                return INT_45_INT_CORNER_WITH_90_90_CONVEX
                            elif proximity.is_left_empty_at_left:
                                return INT_45_INT_CORNER_WITH_90V
                            elif proximity.is_bottom_empty_at_bottom:
                                return INT_45_INT_CORNER_WITH_90H
                            else:
                                return INT_45_INT_CORNER
                    else:
                        if proximity.get_is_top_right_corner_clipped_partial_27():
                            # FIXME: LEFT OFF HERE: -------- A27
                            pass
                        else:
                            # 90-90 cutout.
                            return EXTERIOR
                else:
                    # Fully interior.
                    # FIXME: LEFT OFF HERE: -----------------------------------------
                    # - Pause this logic until adding some more CellProximity
                    #   helpers for internal cases.
                    pass
                    return INTERIOR
                    
                    
                    if proximity.is_bottom_empty_at_bottom:
                        if proximity.is_left_empty_at_left:
                            if proximity.is_bottom_left_empty_at_bottom_left:
                                # FIXME: LEFT OFF HERE: ---------------------------------------
                                pass
                            else:
                                # FIXME: LEFT OFF HERE: ---------------------------------------
                                pass
                        else:
                            # FIXME: LEFT OFF HERE: ---------------------------------------
                            pass
                    else:
                        # FIXME: LEFT OFF HERE: ---------------------------------------
                        pass
    
    # FIXME: LEFT OFF HERE: ---------- Remove after adding all above cases.
    return UNKNOWN


static func _get_target_bottom_right_corner(proximity: CellProximity) -> int:
    if proximity.is_bottom_empty:
        if proximity.is_right_empty:
            return EMPTY
        else:
            # Bottom empty, right present.
            if proximity.get_is_90_floor_at_right():
                if proximity.get_is_45_pos_floor_left(-1, 0):
                    return EXT_90H_45_CONVEX
                else:
                    return EXT_90H
            elif proximity.get_is_45_neg_floor():
                if proximity.get_is_45_pos_floor(-1, 0):
                    return EXT_45_FLOOR_TO_45_CONVEX
                elif proximity.get_is_90_floor_at_left(-1, 0):
                    return EXT_45_FLOOR_TO_90
                else:
                    return EXT_45_FLOOR
            elif proximity.is_angle_27:
                # FIXME: LEFT OFF HERE: -------- A27
                pass
            else:
                Sc.logger.error()
    else:
        if proximity.is_right_empty:
            # Bottom present, right empty.
            if proximity.get_is_90_left_wall_at_bottom():
                if proximity.get_is_45_pos_floor(0, 1):
                    return EXT_90V_45_CONVEX
                else:
                    return EXT_90V
            elif proximity.get_is_45_neg_ceiling():
                if proximity.get_is_45_pos_floor(0, 1):
                    return EXT_45_CEILING_TO_45_CONVEX
                elif proximity.get_is_90_left_wall_at_top(0, 1):
                    return EXT_45_CEILING_TO_90
                else:
                    return EXT_45_CEILING
            elif proximity.is_angle_27:
                # FIXME: LEFT OFF HERE: -------- A27
                pass
            else:
                Sc.logger.error()
        else:
            # Adjacent sides are present.
            if proximity.is_bottom_right_empty:
                # Adjacent sides are present, adjacent corner is empty.
                if proximity.get_is_90_left_wall_at_top(0, 1):
                    if proximity.get_is_90_floor_at_left(-1, 0):
                        return EXT_90_90_CONCAVE
                    elif proximity.get_is_45_pos_floor(-1, 0):
                        return EXT_90V_45_CONCAVE
                    elif proximity.get_angle_type(-1, 0) == CellAngleType.A27:
                        # FIXME: LEFT OFF HERE: -------- A27
                        pass
                    else:
                        Sc.logger.error()
                elif proximity.get_is_45_pos_floor(0, -1):
                    if proximity.get_is_90_floor_at_left(-1, 0):
                        return EXT_90H_45_CONCAVE
                    elif proximity.get_is_45_pos_floor(-1, 0):
                        return EXT_45_CONCAVE
                    elif proximity.get_angle_type(-1, 0) == CellAngleType.A27:
                        # FIXME: LEFT OFF HERE: -------- A27
                        pass
                    else:
                        Sc.logger.error()
                elif proximity.get_angle_type(0, 1) == CellAngleType.A27:
                    # FIXME: LEFT OFF HERE: -------- A27
                    pass
                else:
                    Sc.logger.error()
            else:
                # Adjacent sides and corner are present.
                if proximity.is_top_present and \
                        proximity.is_left_present and \
                        proximity.is_top_right_empty and \
                        proximity.is_top_left_empty and \
                        !proximity.is_bottom_left_empty:
                    return INT_45_MID_NOTCH_H
                elif proximity.is_top_present and \
                        proximity.is_left_present and \
                        proximity.is_bottom_left_empty and \
                        proximity.is_top_left_empty and \
                        !proximity.is_top_right_empty:
                    return INT_45_MID_NOTCH_V
                elif proximity.is_top_empty or \
                        proximity.is_left_empty or \
                        proximity.is_bottom_left_empty or \
                        proximity.is_top_right_empty:
                    # This corner is not deep enough to have transitioned to
                    # interior.
                    return EXTERIOR
                elif proximity.is_top_left_empty:
                    # Only exposed at opposite corner.
                    if proximity.get_is_top_left_corner_clipped_partial_45():
                        if proximity.get_is_top_left_corner_clipped_partial_27():
                            # FIXME: LEFT OFF HERE: -------- A27
                            pass
                        else:
                            # 45 cutout.
                            if proximity.is_bottom_right_empty_at_bottom_right:
                                # FIXME: LEFT OFF HERE: --------------------------------------------------------------
                                # - Replace these with non-tile-type-specific checks.
                                # - Instead, check for a 90-90 cutout IN THE NEIGHBOR.
                                if proximity.get_angle_type(-1, 1) == CellAngleType.A90:
                                    return INT_45_INT_CORNER_WITH_90_90_CONCAVE
                                elif proximity.get_angle_type(-1, 1) == CellAngleType.A27:
                                    # FIXME: LEFT OFF HERE: -------- A27
                                    pass
                                else:
                                    return INT_45_INT_CORNER_NARROW
                            elif proximity.is_right_empty_at_right and \
                                    proximity.is_bottom_empty_at_bottom:
                                return INT_45_INT_CORNER_WITH_90_90_CONVEX
                            elif proximity.is_right_empty_at_right:
                                return INT_45_INT_CORNER_WITH_90V
                            elif proximity.is_bottom_empty_at_bottom:
                                return INT_45_INT_CORNER_WITH_90H
                            else:
                                return INT_45_INT_CORNER
                    else:
                        if proximity.get_is_top_left_corner_clipped_partial_27():
                            # FIXME: LEFT OFF HERE: -------- A27
                            pass
                        else:
                            # 90-90 cutout.
                            return EXTERIOR
                else:
                    # Fully interior.
                    # FIXME: LEFT OFF HERE: -----------------------------------------
                    # - Pause this logic until adding some more CellProximity
                    #   helpers for internal cases.
                    pass
                    return INTERIOR
                    
                    
                    if proximity.is_bottom_empty_at_bottom:
                        if proximity.is_right_empty_at_right:
                            if proximity.is_bottom_right_empty_at_bottom_right:
                                # FIXME: LEFT OFF HERE: ---------------------------------------
                                pass
                            else:
                                # FIXME: LEFT OFF HERE: ---------------------------------------
                                pass
                        else:
                            # FIXME: LEFT OFF HERE: ---------------------------------------
                            pass
                    else:
                        # FIXME: LEFT OFF HERE: ---------------------------------------
                        pass
    
    # FIXME: LEFT OFF HERE: ---------- Remove after adding all above cases.
    return UNKNOWN

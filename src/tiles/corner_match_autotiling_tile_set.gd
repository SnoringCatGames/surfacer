tool
class_name CornerMatchAutotilingTileSet
extends SurfacesTileSet


# FIXME: LEFT OFF HERE: ----------------------------------
# - Plan how to deal with 45-interior-transition strips that don't actually fade
#   to dark, and then also end abruptly due to not opening up into a wider area.


# FIXME: LEFT OFF HERE: ------------------------------------------------------
# - Update the corner-type legend to match the latest enums list.


# typedef SubtileConfig: {
#     # Required.
#     p: Vector2,
#     a: Array<90|45|27>,
#     tl: SubtileCorner,
#     tr: SubtileCorner,
#     bl: SubtileCorner,
#     br: SubtileCorner,
#     
#     # Optional.
#     inbound_t_bl?: SubtileCorner,
#     inbound_t_br?: SubtileCorner,
#     inbound_b_tl?: SubtileCorner,
#     inbound_b_tr?: SubtileCorner,
#     inbound_l_tr?: SubtileCorner,
#     inbound_l_br?: SubtileCorner,
#     inbound_r_tl?: SubtileCorner,
#     inbound_r_bl?: SubtileCorner,
# }


# FIXME: LEFT OFF HERE: -----------------------------------------
# - Is there a simpler way to allow the tile-set author to configure which
#   slopes are allowed to transition into which others?

var _CORNERS := [
    "tl",
    "tr",
    "bl",
    "br",
]
var _INBOUND_CORNERS := [
    "inbound_t_bl",
    "inbound_t_br",
    "inbound_b_tl",
    "inbound_b_tr",
    "inbound_l_tr",
    "inbound_l_br",
    "inbound_r_tl",
    "inbound_r_bl",
]



# NOTE:
# -   This mapping enables us to match one corner type with another.
# -   Defining a value as negative will configure it as a valid match, but with
#     a lower-priority than a positive value.
# -   This maps from an expected target corner type to what is actually
#     configured in the given tile-set.
const _CORNER_TYPE_TO_ADDITIONAL_MATCHING_TYPES := {
    SubtileCorner.UNKNOWN: [],
    
    SubtileCorner.EMPTY: [SubtileCorner.EXT_90_90_CONVEX, SubtileCorner.EXT_90H_TO_45_CONVEX_ACUTE, SubtileCorner.EXT_90V_TO_45_CONVEX_ACUTE],
    SubtileCorner.EXTERIOR: [],
    SubtileCorner.INTERIOR: [],
    
    SubtileCorner.EXT_90H: [],
    SubtileCorner.EXT_90V: [],
    SubtileCorner.EXT_90_90_CONVEX: [SubtileCorner.EMPTY],
    
    SubtileCorner.EXT_CLIPPED_90_90: [-SubtileCorner.EXT_CLIPPED_45_45],
    
    
    SubtileCorner.EXT_CLIPPED_45_45: [],
    SubtileCorner.EXT_45_FLOOR: [],
    SubtileCorner.EXT_45_CEILING: [],
    
    SubtileCorner.EXT_45_FLOOR_TO_90: [-SubtileCorner.EXT_45_FLOOR],
    SubtileCorner.EXT_45_FLOOR_TO_45_CONVEX: [-SubtileCorner.EXT_45_FLOOR],
    SubtileCorner.EXT_45_CEILING_TO_90: [-SubtileCorner.EXT_45_CEILING],
    SubtileCorner.EXT_45_CEILING_TO_45_CONVEX: [-SubtileCorner.EXT_45_CEILING],
    
    
    SubtileCorner.EXT_CLIPPED_27_SHALLOW: [-SubtileCorner.EXT_CLIPPED_45_45],
    SubtileCorner.EXT_CLIPPED_27_STEEP: [-SubtileCorner.EXT_CLIPPED_45_45],
    SubtileCorner.EXT_27_FLOOR_SHALLOW_CLOSE: [-SubtileCorner.EXT_90H],
    SubtileCorner.EXT_27_FLOOR_SHALLOW_FAR: [],
    SubtileCorner.EXT_27_FLOOR_STEEP_CLOSE: [-SubtileCorner.EXT_90V],
    SubtileCorner.EXT_27_FLOOR_STEEP_FAR: [],
    
    
    SubtileCorner.EXT_27_CEILING_SHALLOW_CLOSE: [-SubtileCorner.EXT_90H],
    SubtileCorner.EXT_27_CEILING_SHALLOW_FAR: [],
    SubtileCorner.EXT_27_CEILING_STEEP_CLOSE: [-SubtileCorner.EXT_90V],
    SubtileCorner.EXT_27_CEILING_STEEP_FAR: [],
    
    
    SubtileCorner.EXT_CLIPPED_90H_45: [-SubtileCorner.EXT_CLIPPED_45_45],
    SubtileCorner.EXT_CLIPPED_90V_45: [-SubtileCorner.EXT_CLIPPED_45_45],
    SubtileCorner.EXT_90H_TO_45_CONVEX: [-SubtileCorner.EXT_90H],
    SubtileCorner.EXT_90V_TO_45_CONVEX: [-SubtileCorner.EXT_90V],
    SubtileCorner.EXT_90H_TO_45_CONVEX_ACUTE: [SubtileCorner.EMPTY, SubtileCorner.EXT_90_90_CONVEX, SubtileCorner.EXT_90V_TO_45_CONVEX_ACUTE],
    SubtileCorner.EXT_90V_TO_45_CONVEX_ACUTE: [SubtileCorner.EMPTY, SubtileCorner.EXT_90_90_CONVEX, SubtileCorner.EXT_90H_TO_45_CONVEX_ACUTE],
    
    # SubtileCorner.FIXME: SubtileCorner.LEFT SubtileCorner.OFF SubtileCorner.HERE: ------------------------------------
    
    SubtileCorner.INT_90H: [],
    SubtileCorner.INT_90V: [],
    SubtileCorner.INT_90_90_CONCAVE: [],
    SubtileCorner.INT_90_90_CONVEX: [],
    SubtileCorner.INT_90H_TO_45: [],
    SubtileCorner.INT_90V_TO_45: [],
    SubtileCorner.INT_90H_TO_27_SHALLOW: [],
    SubtileCorner.INT_90H_TO_27_STEEP_SHORT: [],
    SubtileCorner.INT_90H_TO_27_STEEP_LONG: [],
    SubtileCorner.INT_90V_TO_27_SHALLOW_SHORT: [],
    SubtileCorner.INT_90V_TO_27_SHALLOW_LONG: [],
    SubtileCorner.INT_90V_TO_27_STEEP: [],
    
    SubtileCorner.INT_45_EXT_CORNER: [],
    SubtileCorner.INT_45_EXT_CORNER_TO_90H: [],
    SubtileCorner.INT_45_EXT_CORNER_TO_90V: [],
    SubtileCorner.INT_45_EXT_CORNER_TO_90H_AND_90V: [],
    
    SubtileCorner.INT_45_INT_CORNER: [],
    SubtileCorner.INT_45_INT_CORNER_WITH_90_90_CONCAVE: [],
    SubtileCorner.INT_45_INT_CORNER_WITH_90_90_CONVEX: [],
    SubtileCorner.INT_45_INT_CORNER_WITH_90H: [],
    SubtileCorner.INT_45_INT_CORNER_WITH_90V: [],
    SubtileCorner.INT_45_INT_CORNER_NARROW: [],
    SubtileCorner.INT_45_MID_NOTCH_H: [],
    SubtileCorner.INT_45_MID_NOTCH_V: [],
    
    SubtileCorner.INT_27_INT_CORNER_SHALLOW: [],
    SubtileCorner.INT_27_INT_CORNER_STEEP: [],
}

# FIXME: LEFT OFF HERE: --------------------------------
var _ACCEPTABLE_MATCH_PRIORITY_THRESHOLD := 2.0

# Dictionary<int, String>
var _SUBTILE_CORNER_TYPE_VALUE_TO_KEY: Dictionary

# Dictionary<
#     ("tl"|"tr"|"bl"|"br"),
#     Dictionary<
#         SubtileCorner,
#         Dictionary<Vector2, SubtileConfig>>>
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
    
    # If the additional matching type map is a const and has already been
    # parsed, then skip it.
    if !(_CORNER_TYPE_TO_ADDITIONAL_MATCHING_TYPES[SubtileCorner.UNKNOWN] is \
            Dictionary):
        # Check that the corner-type enum values match the
        # corner-type-to-matching-types map.
        assert(_SUBTILE_CORNER_TYPE_VALUE_TO_KEY.size() == \
                _CORNER_TYPE_TO_ADDITIONAL_MATCHING_TYPES.size())
        for corner_type in _SUBTILE_CORNER_TYPE_VALUE_TO_KEY:
            assert(_CORNER_TYPE_TO_ADDITIONAL_MATCHING_TYPES.has(corner_type))
            assert(_CORNER_TYPE_TO_ADDITIONAL_MATCHING_TYPES[corner_type] is Array)
        
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
        assert(subtile_config.has("a") or \
                subtile_config.has("is_a90") and \
                subtile_config.has("is_a45") and \
                subtile_config.has("is_a27"))
        
        # If subtiles_manifest is a const and has already been parsed, then
        # skip parsing the subtile configs.
        if subtile_config.has("a"):
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
            assert(corner_type is int and corner_type != SubtileCorner.UNKNOWN)
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
    
    var script: Script = SubtileCorner
    var constants := script.get_script_constant_map()
    # FIXME: ------- REMOVE this after finaling tile-set system.
#    while !constants.has("EMPTY"):
#        script = script.get_base_script()
#        constants = script.get_script_constant_map()
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
    return type != SubtileCorner.UNKNOWN and \
            type != SubtileCorner.EMPTY and \
            type != SubtileCorner.EXTERIOR and \
            type != SubtileCorner.INTERIOR


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
        var additional_matching_types: Dictionary = \
                _CORNER_TYPE_TO_ADDITIONAL_MATCHING_TYPES[expected_corner]
        # Determine the priority-contribution for this corner.
        if actual_corner == expected_corner or \
                additional_matching_types.has(actual_corner):
            priority += 1.0
        elif additional_matching_types.has(-actual_corner):
            priority += 0.1
        else:
            # FIXME: -------------- Is there a more elegant fallback for this?
            priority -= 5.0
    
    for inbound_corner in _INBOUND_CORNERS:
        if !actual_corners.has(inbound_corner):
            continue
        var actual_corner: int = actual_corners[inbound_corner]
        var expected_corner: int = expected_corners[inbound_corner]
        var additional_matching_types: Dictionary = \
                _CORNER_TYPE_TO_ADDITIONAL_MATCHING_TYPES[expected_corner]
        # Determine the priority-contribution for this inbound corner.
        if actual_corner == expected_corner or \
                additional_matching_types.has(actual_corner):
            priority += 0.01
        elif additional_matching_types.has(-actual_corner):
            priority += 0.001
        else:
            # Do nothing for non-matching corners.
            pass
    
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
    
    # FIXME: Uncomment this to help with debugging.
#    Sc.logger.print(">>>>>>>>>>_choose_subtile: %s, corners=%s" % [
#        proximity.to_string(),
#        get_subtile_config_string(target_corners),
#    ])
    
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
    #   TileMap already has the ideal match?
    
    var best_match_positions := {}
    var best_match_priority := -INF
    
    for corner in _CORNERS:
        for corner_match in corner_to_matches[corner].values():
            if !_get_does_angle_type_match(corner_match, target_corners):
                # Skip the possible corner match, since it doesn't match
                # the angle type.
                continue
            
            var priority := _get_match_priority(corner_match, target_corners)
            var subtile_position: Vector2 = corner_match.p
            
            if !_allows_partial_matches and \
                    priority < 4.0:
                # The subtile config doesn't match all four outbound corners.
                continue
            
            if priority > best_match_priority:
                best_match_priority = priority
                best_match_positions.clear()
                best_match_positions[subtile_position] = true
            elif priority == best_match_priority and \
                    !best_match_positions.has(subtile_position):
                best_match_positions[subtile_position] = true
        
        if _allows_partial_matches and \
                !best_match_positions.empty() and \
                best_match_priority >= 4.0:
            # If we already found a full match from this corner, then we cannot
            # find a more full match from another corner.
            break
        
        if !_allows_partial_matches and \
                _get_is_subtile_corner_type_interesting(
                    target_corners[corner]) and \
                best_match_positions.empty():
            # If this corner type was interesting, and we didn't find a full
            # match for it, then we know that none of the other corner mappings
            # will have a full match either.
            break
    
    if !best_match_positions.empty():
        var best_matches := best_match_positions.keys()
        var best_match: Vector2 = best_matches[0]
        if best_matches.size() > 1:
            Sc.logger.warning(
                    ("Multiple subtiles have the same priority: " +
                    "priority=%s, p1=%s, p2=%s, corners=%s") % [
                        str(best_match_priority),
                        Sc.utils.get_vector_string(best_matches[0], 0),
                        Sc.utils.get_vector_string(best_matches[1], 0),
                        get_subtile_config_string(target_corners),
                    ])
        if best_match_priority < _ACCEPTABLE_MATCH_PRIORITY_THRESHOLD:
            Sc.logger.warning(
                ("No subtile was found with a good match: " +
                "priority=%s, value=%s") % [
                    best_match_priority,
                    Sc.utils.get_vector_string(best_match, 0),
                ])
        return best_match
    else:
        return _error_indicator_subtile_position


static func _get_target_corners(proximity: CellProximity) -> Dictionary:
    var target_corners := {
        tl = SubtileTargetCornerUtils \
                ._get_target_top_left_corner(proximity),
        tr = SubtileTargetCornerUtils \
                ._get_target_top_right_corner(proximity),
        bl = SubtileTargetCornerUtils \
                ._get_target_bottom_left_corner(proximity),
        br = SubtileTargetCornerUtils \
                ._get_target_bottom_right_corner(proximity),
        inbound_t_bl = SubtileCorner.UNKNOWN,
        inbound_t_br = SubtileCorner.UNKNOWN,
        inbound_b_tl = SubtileCorner.UNKNOWN,
        inbound_b_tr = SubtileCorner.UNKNOWN,
        inbound_l_tr = SubtileCorner.UNKNOWN,
        inbound_l_br = SubtileCorner.UNKNOWN,
        inbound_r_tl = SubtileCorner.UNKNOWN,
        inbound_r_bl = SubtileCorner.UNKNOWN,
        is_a90 = proximity.is_angle_type_90,
        is_a45 = proximity.is_angle_type_45,
        is_a27 = proximity.is_angle_type_27,
    }
    
    if proximity.get_is_present(0, -1):
        var top_proximity := CellProximity.new(
                proximity.tile_map,
                proximity.tile_set,
                proximity.position + Vector2(0, -1))
        target_corners.inbound_t_bl = SubtileTargetCornerUtils \
                ._get_target_bottom_left_corner(top_proximity)
        target_corners.inbound_t_br = SubtileTargetCornerUtils \
                ._get_target_bottom_right_corner(top_proximity)
    if proximity.get_is_present(0, 1):
        var bottom_proximity := CellProximity.new(
                proximity.tile_map,
                proximity.tile_set,
                proximity.position + Vector2(0, 1))
        target_corners.inbound_b_tl = SubtileTargetCornerUtils \
                ._get_target_top_left_corner(bottom_proximity)
        target_corners.inbound_b_tr = SubtileTargetCornerUtils \
                ._get_target_top_right_corner(bottom_proximity)
    if proximity.get_is_present(-1, 0):
        var left_proximity := CellProximity.new(
                proximity.tile_map,
                proximity.tile_set,
                proximity.position + Vector2(-1, 0))
        target_corners.inbound_l_tr = SubtileTargetCornerUtils \
                ._get_target_top_right_corner(left_proximity)
        target_corners.inbound_l_br = SubtileTargetCornerUtils \
                ._get_target_bottom_right_corner(left_proximity)
    if proximity.get_is_present(1, 0):
        var right_proximity := CellProximity.new(
                proximity.tile_map,
                proximity.tile_set,
                proximity.position + Vector2(1, 0))
        target_corners.inbound_r_tl = SubtileTargetCornerUtils \
                ._get_target_top_left_corner(right_proximity)
        target_corners.inbound_r_bl = SubtileTargetCornerUtils \
                ._get_target_bottom_left_corner(right_proximity)
    
    return target_corners

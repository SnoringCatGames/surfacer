tool
class_name CornerMatchAutotilingTileSet
extends SurfacesTileSet


# SubtileBinding
# -   Each end of each side (e.g., top-left, top-right, left-top, left-bottom,
#     ...) of a subtile is represented by one of these flags.
#enum {
#    UNKNOWN,
#
#    EMPTY,
#    EXTERIOR,
#    INTERIOR,
#
#    # Exterior edges (the transition from exterior to air).
#    EXT_90,
#    EXT_45,
#    EXT_45N,
#    EXT_27P_SHALLOW,
#    EXT_27P_STEEP,
#    EXT_27N_STEEP,
#    EXT_27P_INV_STEEP,
#    EXT_27N_INV_STEEP,
#
#    # Interior edges (the transition from interior to exterior).
#    INT_90_PERPENDICULAR,
#    INT_90_PERP_AND_PARALLEL,
#    INT_90_PARALLEL,
#    INT_90_PARALLEL_TO_45,
#    INT_90_PARALLEL_TO_27_SHALLOW,
#    INT_90_PARALLEL_TO_27_STEEP_SHORT,
#    INT_90_PARALLEL_TO_27_STEEP_LONG,
#    INT_45,
#    INT_45_TO_PARALLEL,
#    INT_45_INV,
#    INT_45_INV_WITH_90_PERPENDICULAR,
#    INT_45_INV_WITH_90_PERP_AND_PARALLEL,
#    INT_45_INV_WITH_90_PARALLEL,
#    INT_45_INV_NARROW,
#    INT_45_INV_MID_NOTCH,
#    INT_27_SHALLOW,
#    INT_27_SHALLOW_TO_PARALLEL,
#    INT_27_STEEP_CLOSE,
#    INT_27_STEEP_CLOSE_TO_PARALLEL,
#    INT_27_STEEP_FAR,
#    INT_27_STEEP_FAR_TO_PARALLEL,
#    INT_27N_STEEP,
#}





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
    
    
    EXT_45P_FLOOR,
    EXT_45N_FLOOR,
    EXT_45P_CEILING,
    EXT_45N_CEILING,
    
    
    EXT_27P_FLOOR_SHALLOW,
    EXT_27N_FLOOR_SHALLOW,
    EXT_27P_FLOOR_STEEP,
    EXT_27N_FLOOR_STEEP,
    
    
    EXT_27P_CEILING_SHALLOW,
    EXT_27N_CEILING_SHALLOW,
    EXT_27P_CEILING_STEEP,
    EXT_27N_CEILING_STEEP,
    
    
    EXT_90H_45_CONVEX,
    EXT_90H_45_CONCAVE,
    EXT_90V_45_CONVEX,
    EXT_90V_45_CONCAVE,
    
    
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
    
    INT_45_FLOOR,
    INT_45_FLOOR_TO_90H,
    INT_45_FLOOR_TO_90V,
    INT_45_FLOOR_TO_90H_AND_90V,
    
    INT_45_CEILING,
    INT_45_CEILING_WITH_90_90_CONCAVE,
    INT_45_CEILING_WITH_90_90_CONVEX,
    INT_45_CEILING_WITH_90H,
    INT_45_CEILING_WITH_90V,
    INT_45_CEILING_NARROW,
    INT_45_MID_NOTCH_H,
    INT_45_MID_NOTCH_V,
    
    INT_27_CEILING_SHALLOW,
    INT_27_CEILING_STEEP,
}

const _CORNERS := ["tl", "tr", "bl", "br"]

# FIXME: LEFT OFF HERE: --------------------------------
const _ACCEPTABLE_MATCH_PRIORITY_THRESHOLD := 4.0

# Dictionary<int, String>
var _subtile_corner_type_value_to_key: Dictionary

# Dictionary<
#     ("tl"|"tr"|"bl"|"br"),
#     Dictionary<
#         SubtileCorner,
#         Dictionary<Vector2, {
#             p: Vector2,
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




# FIXME: LEFT OFF HERE: ---------------------------
# - Abandon the 5x5 bitmask idea for internal tiles.
#   - Way too complicated:
#     - I'd need to encode a _lot_ of optional bits.
#     - I'd also need to know shapes of neighbors.
# - Instead, just describe the shape of the internal exposure transition.
#   - flat along side
#   - 90 in corner
#   - 45 in corner
#   - 27 in corner
# - Then, have the logic look at the interesting exposure edge cases, and
#   decide which exposure-transition-shape properties must be matched.

# FIXME: LEFT OFF HERE: ---------------------------------
# - Include in the subtiles configuration a way to specify which angles are
#   allowed to transition into eachother.
# - For example, 45 into 27, 27 into 90, 27-open into 27-closed, etc.
# - Then, the tile-set author can choose how much art they want to make.
# - And account for this in the matching logic.

# FIXME: LEFT OFF HERE: ----------------------------------
# - Plan how to deal with 45-interior-transition strips that don't actually fade
#   to dark, and then also end abruptly due to not opening up into a wider area.

# FIXME: LEFT OFF HERE: ----------------------------------
# - How to handle the special subtiles that are designed to transition into a
#   different angle on the next subtile:
#   - Allow an optional second pair of flags for a side to indicate the in-bound
#     shape that this side will bind to.
# - Implement this matching logic!


func _init(
        tiles_manifest: Array,
        subtiles_manifest: Dictionary,
        allows_partial_matches: bool).(tiles_manifest) -> void:
    self._allows_partial_matches = allows_partial_matches
    _parse_enum_key_values()
    _parse_subtiles_manifest(subtiles_manifest)


func _parse_subtiles_manifest(subtiles_manifest: Dictionary) -> void:
    # FIXME: LEFT OFF HERE: ----------------- Parse other parts of manifest.
    
    assert(subtiles_manifest.has("error_indicator_subtile_position") and \
            subtiles_manifest.error_indicator_subtile_position is Vector2)
    _error_indicator_subtile_position = \
            subtiles_manifest.error_indicator_subtile_position
    
    # Create the nested dictionary structure for holding the subtile manifest.
    for corner in _CORNERS:
        var type_to_subtiles := {}
        _corner_to_type_to_subtiles[corner] = type_to_subtiles
        for corner_type in _subtile_corner_type_value_to_key:
            if _get_is_subtile_corner_type_interesting(corner_type):
                var subtiles := {}
                type_to_subtiles[corner_type] = subtiles
    
    for subtile_config in subtiles_manifest.subtiles:
        assert(subtile_config.has("p") and \
                subtile_config.p is Vector2)
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


func _forward_subtile_selection(
        tile_id: int,
        bitmask: int,
        tile_map: Object,
        cell_position: Vector2):
    var proximity := CellProximity.new(
            tile_map,
            self,
            cell_position,
            tile_id)
    var subtile_position := _choose_subtile(proximity)
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
    
    if _allows_partial_matches:
        var set := {}
        var queue := PriorityQueue.new([], false)
        
        for corner in _CORNERS:
            for corner_match in corner_to_matches[corner]:
                var priority := 0.0
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
                var matches_all_corners: bool = \
                        corner_match.tl == target_corners.tl and \
                        corner_match.tr == target_corners.tr and \
                        corner_match.bl == target_corners.bl and \
                        corner_match.br == target_corners.br
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


func _get_target_corners(proximity: CellProximity) -> Dictionary:
    # FIXME: LEFT OFF HERE: -----------------------
    # - Define target_corners according to neighbor tile presence and angle-types.
    
    return {
        tl = EMPTY,
        tr = EXT_45P_FLOOR,
        bl = EXT_45P_FLOOR,
        br = EXTERIOR,
    }


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
    var script: Script = self.get_script()
    var constants := script.get_script_constant_map()
    while !constants.has("EMPTY"):
        script = script.get_base_script()
        constants = script.get_script_constant_map()
    for key in constants:
        _subtile_corner_type_value_to_key[constants[key]] = key


func get_subtile_corner_string(type: int) -> String:
    return _subtile_corner_type_value_to_key[type]


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
    return type != EMPTY and \
            type != EXTERIOR and \
            type != INTERIOR

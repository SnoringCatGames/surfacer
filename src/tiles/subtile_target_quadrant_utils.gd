class_name SubtileTargetQuadrantUtils
extends Reference


static func get_target_quadrants(target_corners: Dictionary) -> Dictionary:
    var tl := _get_target_top_left_corner(target_corners)
    var tr := _get_target_top_right_corner(target_corners)
    var bl := _get_target_bottom_left_corner(target_corners)
    var br := _get_target_bottom_right_corner(target_corners)
    
    if tl == SubtileQuadrant.UNKNOWN:
        tl = SubtileQuadrant.ERROR_TL
    if tr == SubtileQuadrant.UNKNOWN:
        tr = SubtileQuadrant.ERROR_TR
    if bl == SubtileQuadrant.UNKNOWN:
        bl = SubtileQuadrant.ERROR_BL
    if br == SubtileQuadrant.UNKNOWN:
        br = SubtileQuadrant.ERROR_BR
    
    return {
        tl = tl,
        tr = tr,
        bl = bl,
        br = br,
    }


static func _get_target_top_left_corner(target_corners: Dictionary) -> int:
    match target_corners.tl:
        SubtileCorner.EMPTY:
            return SubtileQuadrant.EMPTY_TL
        SubtileCorner.INTERIOR:
            return SubtileQuadrant.INTERIOR_TL
        SubtileCorner.EXTERIOR:
            # FIXME: LEFT OFF HERE: --------------------------
            return SubtileQuadrant.UNKNOWN
        
        SubtileCorner.EXT_90H:
            return SubtileQuadrant.EXT_90_FLOOR_EXT_TL
        SubtileCorner.EXT_90V:
            return SubtileQuadrant.EXT_90_LEFT_SIDE_EXT_TL
        SubtileCorner.EXT_90_90_CONVEX:
            return SubtileQuadrant.EXT_90_90_CONVEX_EXT_TL
        
        SubtileCorner.EXT_45_FLOOR:
            # FIXME: LEFT OFF HERE: --------------------------
            return SubtileQuadrant.UNKNOWN
        SubtileCorner.EXT_45_CEILING:
            # FIXME: LEFT OFF HERE: --------------------------
            return SubtileQuadrant.UNKNOWN
        
        SubtileCorner.EXT_CLIPPED_90_90:
            # FIXME: LEFT OFF HERE: --------------------------
            return SubtileQuadrant.UNKNOWN
        SubtileCorner.EXT_CLIPPED_45_45:
            # FIXME: LEFT OFF HERE: --------------------------
            return SubtileQuadrant.UNKNOWN
        SubtileCorner.EXT_CLIPPED_90H_45:
            # FIXME: LEFT OFF HERE: --------------------------
            return SubtileQuadrant.UNKNOWN
        SubtileCorner.EXT_CLIPPED_90V_45:
            # FIXME: LEFT OFF HERE: --------------------------
            return SubtileQuadrant.UNKNOWN
        
        SubtileCorner.EXT_90H_TO_45_CONVEX:
            # FIXME: LEFT OFF HERE: --------------------------
            return SubtileQuadrant.UNKNOWN
        SubtileCorner.EXT_90V_TO_45_CONVEX:
            # FIXME: LEFT OFF HERE: --------------------------
            return SubtileQuadrant.UNKNOWN
        SubtileCorner.EXT_90H_TO_45_CONVEX_ACUTE:
            # FIXME: LEFT OFF HERE: --------------------------
            return SubtileQuadrant.UNKNOWN
        SubtileCorner.EXT_90V_TO_45_CONVEX_ACUTE:
            # FIXME: LEFT OFF HERE: --------------------------
            return SubtileQuadrant.UNKNOWN

        SubtileCorner.EXT_45_FLOOR_TO_90:
            # FIXME: LEFT OFF HERE: --------------------------
            return SubtileQuadrant.UNKNOWN
        SubtileCorner.EXT_45_FLOOR_TO_45_CONVEX:
            # FIXME: LEFT OFF HERE: --------------------------
            return SubtileQuadrant.UNKNOWN
        SubtileCorner.EXT_45_CEILING_TO_90:
            # FIXME: LEFT OFF HERE: --------------------------
            return SubtileQuadrant.UNKNOWN
        SubtileCorner.EXT_45_CEILING_TO_45_CONVEX:
            # FIXME: LEFT OFF HERE: --------------------------
            return SubtileQuadrant.UNKNOWN
        
        
        SubtileCorner.EXT_CLIPPED_27_SHALLOW:
            # FIXME: LEFT OFF HERE: --------------------------
            return SubtileQuadrant.UNKNOWN
        SubtileCorner.EXT_CLIPPED_27_STEEP:
            # FIXME: LEFT OFF HERE: --------------------------
            return SubtileQuadrant.UNKNOWN
        
        SubtileCorner.EXT_27_FLOOR_SHALLOW_CLOSE:
            # FIXME: LEFT OFF HERE: --------------------------
            return SubtileQuadrant.UNKNOWN
        SubtileCorner.EXT_27_FLOOR_SHALLOW_FAR:
            # FIXME: LEFT OFF HERE: --------------------------
            return SubtileQuadrant.UNKNOWN
        SubtileCorner.EXT_27_FLOOR_STEEP_CLOSE:
            # FIXME: LEFT OFF HERE: --------------------------
            return SubtileQuadrant.UNKNOWN
        SubtileCorner.EXT_27_FLOOR_STEEP_FAR:
            # FIXME: LEFT OFF HERE: --------------------------
            return SubtileQuadrant.UNKNOWN
        
        SubtileCorner.EXT_27_CEILING_SHALLOW_CLOSE:
            # FIXME: LEFT OFF HERE: --------------------------
            return SubtileQuadrant.UNKNOWN
        SubtileCorner.EXT_27_CEILING_SHALLOW_FAR:
            # FIXME: LEFT OFF HERE: --------------------------
            return SubtileQuadrant.UNKNOWN
        SubtileCorner.EXT_27_CEILING_STEEP_CLOSE:
            # FIXME: LEFT OFF HERE: --------------------------
            return SubtileQuadrant.UNKNOWN
        SubtileCorner.EXT_27_CEILING_STEEP_FAR:
            # FIXME: LEFT OFF HERE: --------------------------
            return SubtileQuadrant.UNKNOWN
        
        SubtileCorner.INT_90H:
            # FIXME: LEFT OFF HERE: --------------------------
            return SubtileQuadrant.UNKNOWN
        SubtileCorner.INT_90V:
            # FIXME: LEFT OFF HERE: --------------------------
            return SubtileQuadrant.UNKNOWN
        SubtileCorner.INT_90_90_CONCAVE:
            # FIXME: LEFT OFF HERE: --------------------------
            return SubtileQuadrant.UNKNOWN
        SubtileCorner.INT_90_90_CONVEX:
            # FIXME: LEFT OFF HERE: --------------------------
            return SubtileQuadrant.UNKNOWN
        SubtileCorner.INT_90H_TO_45:
            # FIXME: LEFT OFF HERE: --------------------------
            return SubtileQuadrant.UNKNOWN
        SubtileCorner.INT_90V_TO_45:
            # FIXME: LEFT OFF HERE: --------------------------
            return SubtileQuadrant.UNKNOWN
        SubtileCorner.INT_90H_TO_27_SHALLOW:
            # FIXME: LEFT OFF HERE: --------------------------
            return SubtileQuadrant.UNKNOWN
        SubtileCorner.INT_90H_TO_27_STEEP_SHORT:
            # FIXME: LEFT OFF HERE: --------------------------
            return SubtileQuadrant.UNKNOWN
        SubtileCorner.INT_90H_TO_27_STEEP_LONG:
            # FIXME: LEFT OFF HERE: --------------------------
            return SubtileQuadrant.UNKNOWN
        SubtileCorner.INT_90V_TO_27_SHALLOW_SHORT:
            # FIXME: LEFT OFF HERE: --------------------------
            return SubtileQuadrant.UNKNOWN
        SubtileCorner.INT_90V_TO_27_SHALLOW_LONG:
            # FIXME: LEFT OFF HERE: --------------------------
            return SubtileQuadrant.UNKNOWN
        SubtileCorner.INT_90V_TO_27_STEEP:
            # FIXME: LEFT OFF HERE: --------------------------
            return SubtileQuadrant.UNKNOWN
        
        SubtileCorner.INT_45_EXT_CORNER:
            # FIXME: LEFT OFF HERE: --------------------------
            return SubtileQuadrant.UNKNOWN
        SubtileCorner.INT_45_EXT_CORNER_TO_90H:
            # FIXME: LEFT OFF HERE: --------------------------
            return SubtileQuadrant.UNKNOWN
        SubtileCorner.INT_45_EXT_CORNER_TO_90V:
            # FIXME: LEFT OFF HERE: --------------------------
            return SubtileQuadrant.UNKNOWN
        SubtileCorner.INT_45_EXT_CORNER_TO_90H_AND_90V:
            # FIXME: LEFT OFF HERE: --------------------------
            return SubtileQuadrant.UNKNOWN
        
        SubtileCorner.INT_45_INT_CORNER:
            # FIXME: LEFT OFF HERE: --------------------------
            return SubtileQuadrant.UNKNOWN
        SubtileCorner.INT_45_INT_CORNER_WITH_90_90_CONCAVE:
            # FIXME: LEFT OFF HERE: --------------------------
            return SubtileQuadrant.UNKNOWN
        SubtileCorner.INT_45_INT_CORNER_WITH_90_90_CONVEX:
            # FIXME: LEFT OFF HERE: --------------------------
            return SubtileQuadrant.UNKNOWN
        SubtileCorner.INT_45_INT_CORNER_WITH_90H:
            # FIXME: LEFT OFF HERE: --------------------------
            return SubtileQuadrant.UNKNOWN
        SubtileCorner.INT_45_INT_CORNER_WITH_90V:
            # FIXME: LEFT OFF HERE: --------------------------
            return SubtileQuadrant.UNKNOWN
        SubtileCorner.INT_45_INT_CORNER_NARROW:
            # FIXME: LEFT OFF HERE: --------------------------
            return SubtileQuadrant.UNKNOWN
        SubtileCorner.INT_45_MID_NOTCH_H:
            # FIXME: LEFT OFF HERE: --------------------------
            return SubtileQuadrant.UNKNOWN
        SubtileCorner.INT_45_MID_NOTCH_V:
            # FIXME: LEFT OFF HERE: --------------------------
            return SubtileQuadrant.UNKNOWN
        
        SubtileCorner.INT_27_INT_CORNER_SHALLOW:
            # FIXME: LEFT OFF HERE: --------------------------
            return SubtileQuadrant.UNKNOWN
        SubtileCorner.INT_27_INT_CORNER_STEEP:
            # FIXME: LEFT OFF HERE: --------------------------
            return SubtileQuadrant.UNKNOWN
        
        SubtileCorner.UNKNOWN, \
        _:
            Sc.logger.error()
            return SubtileQuadrant.UNKNOWN


static func _get_target_top_right_corner(target_corners: Dictionary) -> int:
    # FIXME: LEFT OFF HERE: -------------------------------
    return SubtileQuadrant.UNKNOWN


static func _get_target_bottom_left_corner(target_corners: Dictionary) -> int:
    # FIXME: LEFT OFF HERE: -------------------------------
    return SubtileQuadrant.UNKNOWN


static func _get_target_bottom_right_corner(target_corners: Dictionary) -> int:
    # FIXME: LEFT OFF HERE: -------------------------------
    return SubtileQuadrant.UNKNOWN


static func _get_target_top_left_exterior_corner(
        target_corners: Dictionary) -> int:
    assert(target_corners.tl == SubtileCorner.EXTERIOR)
    
    # FIXME: LEFT OFF HERE: -------------------------------
    
    match target_corners.tr:
        SubtileCorner.EMPTY:
            return SubtileQuadrant.UNKNOWN
        SubtileCorner.INTERIOR:
            return SubtileQuadrant.INTERIOR_TL
        SubtileCorner.EXTERIOR:
            # FIXME: LEFT OFF HERE: --------------------------
            return SubtileQuadrant.UNKNOWN
        
        SubtileCorner.EXT_90H:
            return SubtileQuadrant.EXT_90_FLOOR_EXT_TL
        SubtileCorner.EXT_90V:
            return SubtileQuadrant.EXT_90_LEFT_SIDE_EXT_TL
        SubtileCorner.EXT_90_90_CONVEX:
            return SubtileQuadrant.EXT_90_90_CONVEX_EXT_TL
        
        SubtileCorner.EXT_45_FLOOR:
            # FIXME: LEFT OFF HERE: --------------------------
            return SubtileQuadrant.UNKNOWN
        SubtileCorner.EXT_45_CEILING:
            # FIXME: LEFT OFF HERE: --------------------------
            return SubtileQuadrant.UNKNOWN
        
        SubtileCorner.EXT_CLIPPED_90_90:
            # FIXME: LEFT OFF HERE: --------------------------
            return SubtileQuadrant.UNKNOWN
        SubtileCorner.EXT_CLIPPED_45_45:
            # FIXME: LEFT OFF HERE: --------------------------
            return SubtileQuadrant.UNKNOWN
        SubtileCorner.EXT_CLIPPED_90H_45:
            # FIXME: LEFT OFF HERE: --------------------------
            return SubtileQuadrant.UNKNOWN
        SubtileCorner.EXT_CLIPPED_90V_45:
            # FIXME: LEFT OFF HERE: --------------------------
            return SubtileQuadrant.UNKNOWN
        
        SubtileCorner.EXT_90H_TO_45_CONVEX:
            # FIXME: LEFT OFF HERE: --------------------------
            return SubtileQuadrant.UNKNOWN
        SubtileCorner.EXT_90V_TO_45_CONVEX:
            # FIXME: LEFT OFF HERE: --------------------------
            return SubtileQuadrant.UNKNOWN
        SubtileCorner.EXT_90H_TO_45_CONVEX_ACUTE:
            # FIXME: LEFT OFF HERE: --------------------------
            return SubtileQuadrant.UNKNOWN
        SubtileCorner.EXT_90V_TO_45_CONVEX_ACUTE:
            # FIXME: LEFT OFF HERE: --------------------------
            return SubtileQuadrant.UNKNOWN

        SubtileCorner.EXT_45_FLOOR_TO_90:
            # FIXME: LEFT OFF HERE: --------------------------
            return SubtileQuadrant.UNKNOWN
        SubtileCorner.EXT_45_FLOOR_TO_45_CONVEX:
            # FIXME: LEFT OFF HERE: --------------------------
            return SubtileQuadrant.UNKNOWN
        SubtileCorner.EXT_45_CEILING_TO_90:
            # FIXME: LEFT OFF HERE: --------------------------
            return SubtileQuadrant.UNKNOWN
        SubtileCorner.EXT_45_CEILING_TO_45_CONVEX:
            # FIXME: LEFT OFF HERE: --------------------------
            return SubtileQuadrant.UNKNOWN
        
        
        SubtileCorner.EXT_CLIPPED_27_SHALLOW:
            # FIXME: LEFT OFF HERE: --------------------------
            return SubtileQuadrant.UNKNOWN
        SubtileCorner.EXT_CLIPPED_27_STEEP:
            # FIXME: LEFT OFF HERE: --------------------------
            return SubtileQuadrant.UNKNOWN
        
        SubtileCorner.EXT_27_FLOOR_SHALLOW_CLOSE:
            # FIXME: LEFT OFF HERE: --------------------------
            return SubtileQuadrant.UNKNOWN
        SubtileCorner.EXT_27_FLOOR_SHALLOW_FAR:
            # FIXME: LEFT OFF HERE: --------------------------
            return SubtileQuadrant.UNKNOWN
        SubtileCorner.EXT_27_FLOOR_STEEP_CLOSE:
            # FIXME: LEFT OFF HERE: --------------------------
            return SubtileQuadrant.UNKNOWN
        SubtileCorner.EXT_27_FLOOR_STEEP_FAR:
            # FIXME: LEFT OFF HERE: --------------------------
            return SubtileQuadrant.UNKNOWN
        
        SubtileCorner.EXT_27_CEILING_SHALLOW_CLOSE:
            # FIXME: LEFT OFF HERE: --------------------------
            return SubtileQuadrant.UNKNOWN
        SubtileCorner.EXT_27_CEILING_SHALLOW_FAR:
            # FIXME: LEFT OFF HERE: --------------------------
            return SubtileQuadrant.UNKNOWN
        SubtileCorner.EXT_27_CEILING_STEEP_CLOSE:
            # FIXME: LEFT OFF HERE: --------------------------
            return SubtileQuadrant.UNKNOWN
        SubtileCorner.EXT_27_CEILING_STEEP_FAR:
            # FIXME: LEFT OFF HERE: --------------------------
            return SubtileQuadrant.UNKNOWN
        
        SubtileCorner.INT_90H:
            # FIXME: LEFT OFF HERE: --------------------------
            return SubtileQuadrant.UNKNOWN
        SubtileCorner.INT_90V:
            # FIXME: LEFT OFF HERE: --------------------------
            return SubtileQuadrant.UNKNOWN
        SubtileCorner.INT_90_90_CONCAVE:
            # FIXME: LEFT OFF HERE: --------------------------
            return SubtileQuadrant.UNKNOWN
        SubtileCorner.INT_90_90_CONVEX:
            # FIXME: LEFT OFF HERE: --------------------------
            return SubtileQuadrant.UNKNOWN
        SubtileCorner.INT_90H_TO_45:
            # FIXME: LEFT OFF HERE: --------------------------
            return SubtileQuadrant.UNKNOWN
        SubtileCorner.INT_90V_TO_45:
            # FIXME: LEFT OFF HERE: --------------------------
            return SubtileQuadrant.UNKNOWN
        SubtileCorner.INT_90H_TO_27_SHALLOW:
            # FIXME: LEFT OFF HERE: --------------------------
            return SubtileQuadrant.UNKNOWN
        SubtileCorner.INT_90H_TO_27_STEEP_SHORT:
            # FIXME: LEFT OFF HERE: --------------------------
            return SubtileQuadrant.UNKNOWN
        SubtileCorner.INT_90H_TO_27_STEEP_LONG:
            # FIXME: LEFT OFF HERE: --------------------------
            return SubtileQuadrant.UNKNOWN
        SubtileCorner.INT_90V_TO_27_SHALLOW_SHORT:
            # FIXME: LEFT OFF HERE: --------------------------
            return SubtileQuadrant.UNKNOWN
        SubtileCorner.INT_90V_TO_27_SHALLOW_LONG:
            # FIXME: LEFT OFF HERE: --------------------------
            return SubtileQuadrant.UNKNOWN
        SubtileCorner.INT_90V_TO_27_STEEP:
            # FIXME: LEFT OFF HERE: --------------------------
            return SubtileQuadrant.UNKNOWN
        
        SubtileCorner.INT_45_EXT_CORNER:
            # FIXME: LEFT OFF HERE: --------------------------
            return SubtileQuadrant.UNKNOWN
        SubtileCorner.INT_45_EXT_CORNER_TO_90H:
            # FIXME: LEFT OFF HERE: --------------------------
            return SubtileQuadrant.UNKNOWN
        SubtileCorner.INT_45_EXT_CORNER_TO_90V:
            # FIXME: LEFT OFF HERE: --------------------------
            return SubtileQuadrant.UNKNOWN
        SubtileCorner.INT_45_EXT_CORNER_TO_90H_AND_90V:
            # FIXME: LEFT OFF HERE: --------------------------
            return SubtileQuadrant.UNKNOWN
        
        SubtileCorner.INT_45_INT_CORNER:
            # FIXME: LEFT OFF HERE: --------------------------
            return SubtileQuadrant.UNKNOWN
        SubtileCorner.INT_45_INT_CORNER_WITH_90_90_CONCAVE:
            # FIXME: LEFT OFF HERE: --------------------------
            return SubtileQuadrant.UNKNOWN
        SubtileCorner.INT_45_INT_CORNER_WITH_90_90_CONVEX:
            # FIXME: LEFT OFF HERE: --------------------------
            return SubtileQuadrant.UNKNOWN
        SubtileCorner.INT_45_INT_CORNER_WITH_90H:
            # FIXME: LEFT OFF HERE: --------------------------
            return SubtileQuadrant.UNKNOWN
        SubtileCorner.INT_45_INT_CORNER_WITH_90V:
            # FIXME: LEFT OFF HERE: --------------------------
            return SubtileQuadrant.UNKNOWN
        SubtileCorner.INT_45_INT_CORNER_NARROW:
            # FIXME: LEFT OFF HERE: --------------------------
            return SubtileQuadrant.UNKNOWN
        SubtileCorner.INT_45_MID_NOTCH_H:
            # FIXME: LEFT OFF HERE: --------------------------
            return SubtileQuadrant.UNKNOWN
        SubtileCorner.INT_45_MID_NOTCH_V:
            # FIXME: LEFT OFF HERE: --------------------------
            return SubtileQuadrant.UNKNOWN
        
        SubtileCorner.INT_27_INT_CORNER_SHALLOW:
            # FIXME: LEFT OFF HERE: --------------------------
            return SubtileQuadrant.UNKNOWN
        SubtileCorner.INT_27_INT_CORNER_STEEP:
            # FIXME: LEFT OFF HERE: --------------------------
            return SubtileQuadrant.UNKNOWN
        
        _:
            # Try another corner
            pass
    
    match target_corners.bl:
        _:
            # Try another corner
            pass
    
    match target_corners.br:
        _:
            # Try another corner
            pass
    
    return SubtileQuadrant.UNKNOWN


static func _get_target_top_right_exterior_corner(
        target_corners: Dictionary) -> int:
    # FIXME: LEFT OFF HERE: -------------------------------
    return SubtileQuadrant.UNKNOWN


static func _get_target_bottom_left_exterior_corner(
        target_corners: Dictionary) -> int:
    # FIXME: LEFT OFF HERE: -------------------------------
    return SubtileQuadrant.UNKNOWN


static func _get_target_bottom_right_exterior_corner(
        target_corners: Dictionary) -> int:
    # FIXME: LEFT OFF HERE: -------------------------------
    return SubtileQuadrant.UNKNOWN

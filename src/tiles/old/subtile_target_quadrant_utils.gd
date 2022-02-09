class_name SubtileTargetQuadrantUtils
extends Reference


static func get_target_quadrants(
        corners: Dictionary,
        proximity: CellProximity) -> Dictionary:
    var tl := SubtileQuadrant.ERROR_TL
    var tr := SubtileQuadrant.ERROR_TR
    var bl := SubtileQuadrant.ERROR_BL
    var br := SubtileQuadrant.ERROR_BR
    
    match corners.tl:
        SubtileCorner.EMPTY:
            # FIXME: LEFT OFF HERE: --------------------------
            pass
        SubtileCorner.INTERIOR:
            # FIXME: LEFT OFF HERE: --------------------------
            pass
        SubtileCorner.EXTERIOR:
            # FIXME: LEFT OFF HERE: --------------------------
            pass
        
        SubtileCorner.EXT_90H:
            if corners.tr == SubtileCorner.EXT_90H:
                match corners.bl:
                    SubtileCorner.EXTERIOR:
                        match corners.br:
                            SubtileCorner.EXTERIOR:
                                tl = SubtileQuadrant.EXT_90_FLOOR_TL
                                tr = SubtileQuadrant.EXT_90_FLOOR_TR
                                bl = SubtileQuadrant.EXT_90_FLOOR_BL
                                br = SubtileQuadrant.EXT_90_FLOOR_BR
                            SubtileCorner.EXT_CLIPPED_90_90:
                                # FIXME: LEFT OFF HERE: --------------------------------
                                pass
                            SubtileCorner.EXT_CLIPPED_45_45:
                                # FIXME: LEFT OFF HERE: --------------------------------
                                pass
                            SubtileCorner.EXT_CLIPPED_90H_45:
                                # FIXME: LEFT OFF HERE: --------------------------------
                                pass
                            SubtileCorner.EXT_CLIPPED_90V_45:
                                # FIXME: LEFT OFF HERE: --------------------------------
                                pass
                            SubtileCorner.EXT_CLIPPED_27_SHALLOW:
                                # FIXME: LEFT OFF HERE: --------------------------------
                                pass
                            SubtileCorner.EXT_CLIPPED_27_STEEP:
                                # FIXME: LEFT OFF HERE: --------------------------------
                                pass
                            _:
                                _log_error(
                                        "Invalid corners.br",
                                        corners,
                                        proximity)
                    SubtileCorner.EXT_90H:
                        # FIXME: LEFT OFF HERE: --------------------------------
                        pass
                    SubtileCorner.EXT_CLIPPED_90_90:
                        # FIXME: LEFT OFF HERE: --------------------------------
                        pass
                    SubtileCorner.EXT_CLIPPED_45_45:
                        # FIXME: LEFT OFF HERE: --------------------------------
                        pass
                    SubtileCorner.EXT_CLIPPED_90H_45:
                        # FIXME: LEFT OFF HERE: --------------------------------
                        pass
                    SubtileCorner.EXT_CLIPPED_90V_45:
                        # FIXME: LEFT OFF HERE: --------------------------------
                        pass
                    SubtileCorner.EXT_90H_TO_45_CONVEX:
                        # FIXME: LEFT OFF HERE: --------------------------------
                        pass
                    SubtileCorner.EXT_CLIPPED_27_SHALLOW:
                        # FIXME: LEFT OFF HERE: --------------------------------
                        pass
                    SubtileCorner.EXT_CLIPPED_27_STEEP:
                        # FIXME: LEFT OFF HERE: --------------------------------
                        pass
                    SubtileCorner.EXT_27_CEILING_SHALLOW_CLOSE:
                        # FIXME: LEFT OFF HERE: --------------------------------
                        pass
                    
                    SubtileCorner.UNKNOWN, \
                    _:
                        _log_error(
                                "Invalid corners.bl",
                                corners,
                                proximity)
            elif corners.tr == SubtileCorner.EXT_90_90_CONVEX:
                # FIXME: LEFT OFF HERE: --------------------------------
                pass
            elif corners.tr == SubtileCorner.EXT_90H_TO_45_CONVEX:
                # FIXME: LEFT OFF HERE: --------------------------------
                pass
            elif corners.tr == SubtileCorner.EXT_90H_TO_45_CONVEX_ACUTE:
                # FIXME: LEFT OFF HERE: --------------------------------
                pass
            else:
                _log_error(
                        "Invalid corners.tr",
                        corners,
                        proximity)
            
            
            
            
            
            
            
            
            
            
        SubtileCorner.EXT_90V:
            # FIXME: LEFT OFF HERE: --------------------------
            pass
        SubtileCorner.EXT_90_90_CONVEX:
            # FIXME: LEFT OFF HERE: --------------------------
            pass
        
        SubtileCorner.EXT_45_FLOOR:
            if proximity.get_is_bottom_left_corner_clipped():
                return SubtileQuadrant.EXT_45N_FLOOR_TL
            else:
                if corners.bl == SubtileCorner.EXT_CLIPPED_90_90:
                    return SubtileQuadrant.EXT_45N_FLOOR_CLIPPED_90_90_TL
                elif corners.bl == SubtileCorner.EXT_CLIPPED_90H_45:
                    return SubtileQuadrant \
                            .EXT_45N_FLOOR_CLIPPED_90_CEILING_45N_CEILING_TL
                elif corners.bl == SubtileCorner.EXT_CLIPPED_90V_45:
                    return SubtileQuadrant \
                            .EXT_45N_FLOOR_CLIPPED_90_LEFT_SIDE_45N_CEILING_TL
                elif corners.bl == SubtileCorner.EXT_CLIPPED_45_45:
                    return SubtileQuadrant.EXT_45N_FLOOR_CLIPPED_45N_CEILING_TL
                elif corners.bl == SubtileCorner.EXT_CLIPPED_27_SHALLOW:
                    # FIXME: LEFT OFF HERE: ------------- A27
                    pass
                elif corners.bl == SubtileCorner.EXT_CLIPPED_27_STEEP:
                    # FIXME: LEFT OFF HERE: ------------- A27
                    pass
                else:
                    _log_error(
                            "_get_target_top_left_corner",
                            corners,
                            proximity)
                    pass
        SubtileCorner.EXT_45_CEILING:
            if proximity.get_is_top_right_corner_clipped():
                return SubtileQuadrant.EXT_45N_CEILING_TL
            else:
                if corners.bl == SubtileCorner.EXT_CLIPPED_90_90:
                    return SubtileQuadrant.EXT_45N_CEILING_CLIPPED_90_90_TL
                elif corners.bl == SubtileCorner.EXT_CLIPPED_90H_45:
                    return SubtileQuadrant \
                            .EXT_45N_CEILING_CLIPPED_90_CEILING_45N_CEILING_TL
                elif corners.bl == SubtileCorner.EXT_CLIPPED_90V_45:
                    return SubtileQuadrant \
                            .EXT_45N_CEILING_CLIPPED_90_LEFT_SIDE_45N_CEILING_TL
                elif corners.bl == SubtileCorner.EXT_CLIPPED_45_45:
                    return SubtileQuadrant \
                            .EXT_45N_CEILING_CLIPPED_45N_CEILING_TL
                elif corners.bl == SubtileCorner.EXT_CLIPPED_27_SHALLOW:
                    # FIXME: LEFT OFF HERE: ------------- A27
                    pass
                elif corners.bl == SubtileCorner.EXT_CLIPPED_27_STEEP:
                    # FIXME: LEFT OFF HERE: ------------- A27
                    pass
                else:
                    _log_error(
                            "_get_target_top_left_corner",
                            corners,
                            proximity)
                    pass
        
        SubtileCorner.EXT_CLIPPED_90_90:
            if corners.tr == SubtileCorner.EXT_CLIPPED_90H_45:
                # FIXME: LEFT OFF HERE: --------------------------
                pass
            elif corners.tr == SubtileCorner.EXT_CLIPPED_45_45:
                # FIXME: LEFT OFF HERE: --------------------------
                pass
            elif corners.tr == SubtileCorner.EXT_CLIPPED_27_SHALLOW:
                # FIXME: LEFT OFF HERE: ------------- A27
                pass
            elif corners.tr == SubtileCorner.EXT_CLIPPED_27_STEEP:
                # FIXME: LEFT OFF HERE: ------------- A27
                pass
            elif corners.tr == SubtileCorner.EXT_45_CEILING:
                # FIXME: LEFT OFF HERE: --------------------------
                pass
            elif corners.tr == SubtileCorner.EXT_90V_TO_45_CONVEX:
                # FIXME: LEFT OFF HERE: --------------------------
                pass
            else:
                if corners.bl == SubtileCorner.EXT_CLIPPED_90V_45:
                    # FIXME: LEFT OFF HERE: --------------------------
                    pass
                elif corners.bl == SubtileCorner.EXT_CLIPPED_45_45:
                    # FIXME: LEFT OFF HERE: --------------------------
                    pass
                elif corners.bl == SubtileCorner.EXT_CLIPPED_27_SHALLOW:
                    # FIXME: LEFT OFF HERE: ------------- A27
                    pass
                elif corners.bl == SubtileCorner.EXT_CLIPPED_27_STEEP:
                    # FIXME: LEFT OFF HERE: ------------- A27
                    pass
                elif corners.bl == SubtileCorner.EXT_45_CEILING:
                    # FIXME: LEFT OFF HERE: --------------------------
                    pass
                elif corners.bl == SubtileCorner.EXT_90H_TO_45_CONVEX:
                    # FIXME: LEFT OFF HERE: --------------------------
                    pass
                else:
                    return SubtileQuadrant.EXT_CLIPPED_90_90_EXT_TL
        SubtileCorner.EXT_CLIPPED_45_45:
            # FIXME: LEFT OFF HERE: --------------------------
            pass
        SubtileCorner.EXT_CLIPPED_90H_45:
            # FIXME: LEFT OFF HERE: --------------------------
            pass
        SubtileCorner.EXT_CLIPPED_90V_45:
            # FIXME: LEFT OFF HERE: --------------------------
            pass
        
        SubtileCorner.EXT_90H_TO_45_CONVEX:
            # FIXME: LEFT OFF HERE: --------------------------
            pass
        SubtileCorner.EXT_90V_TO_45_CONVEX:
            # FIXME: LEFT OFF HERE: --------------------------
            pass
        SubtileCorner.EXT_90H_TO_45_CONVEX_ACUTE:
            # FIXME: LEFT OFF HERE: --------------------------
            pass
        SubtileCorner.EXT_90V_TO_45_CONVEX_ACUTE:
            # FIXME: LEFT OFF HERE: --------------------------
            pass

        SubtileCorner.EXT_45_FLOOR_TO_90:
            # FIXME: LEFT OFF HERE: --------------------------
            pass
        SubtileCorner.EXT_45_FLOOR_TO_45_CONVEX:
            # FIXME: LEFT OFF HERE: --------------------------
            pass
        SubtileCorner.EXT_45_CEILING_TO_90:
            # FIXME: LEFT OFF HERE: --------------------------
            pass
        SubtileCorner.EXT_45_CEILING_TO_45_CONVEX:
            # FIXME: LEFT OFF HERE: --------------------------
            pass
        
        
        SubtileCorner.EXT_CLIPPED_27_SHALLOW:
            # FIXME: LEFT OFF HERE: --------------------------
            pass
        SubtileCorner.EXT_CLIPPED_27_STEEP:
            # FIXME: LEFT OFF HERE: --------------------------
            pass
        
        SubtileCorner.EXT_27_FLOOR_SHALLOW_CLOSE:
            # FIXME: LEFT OFF HERE: --------------------------
            pass
        SubtileCorner.EXT_27_FLOOR_SHALLOW_FAR:
            # FIXME: LEFT OFF HERE: --------------------------
            pass
        SubtileCorner.EXT_27_FLOOR_STEEP_CLOSE:
            # FIXME: LEFT OFF HERE: --------------------------
            pass
        SubtileCorner.EXT_27_FLOOR_STEEP_FAR:
            # FIXME: LEFT OFF HERE: --------------------------
            pass
        
        SubtileCorner.EXT_27_CEILING_SHALLOW_CLOSE:
            # FIXME: LEFT OFF HERE: --------------------------
            pass
        SubtileCorner.EXT_27_CEILING_SHALLOW_FAR:
            # FIXME: LEFT OFF HERE: --------------------------
            pass
        SubtileCorner.EXT_27_CEILING_STEEP_CLOSE:
            # FIXME: LEFT OFF HERE: --------------------------
            pass
        SubtileCorner.EXT_27_CEILING_STEEP_FAR:
            # FIXME: LEFT OFF HERE: --------------------------
            pass
        
        SubtileCorner.INT_90H:
            # FIXME: LEFT OFF HERE: --------------------------
            pass
        SubtileCorner.INT_90V:
            # FIXME: LEFT OFF HERE: --------------------------
            pass
        SubtileCorner.INT_90_90_CONCAVE:
            # FIXME: LEFT OFF HERE: --------------------------
            pass
        SubtileCorner.INT_90_90_CONVEX:
            # FIXME: LEFT OFF HERE: --------------------------
            pass
        SubtileCorner.INT_90H_TO_45:
            # FIXME: LEFT OFF HERE: --------------------------
            pass
        SubtileCorner.INT_90V_TO_45:
            # FIXME: LEFT OFF HERE: --------------------------
            pass
        SubtileCorner.INT_90H_TO_27_SHALLOW:
            # FIXME: LEFT OFF HERE: --------------------------
            pass
        SubtileCorner.INT_90H_TO_27_STEEP_SHORT:
            # FIXME: LEFT OFF HERE: --------------------------
            pass
        SubtileCorner.INT_90H_TO_27_STEEP_LONG:
            # FIXME: LEFT OFF HERE: --------------------------
            pass
        SubtileCorner.INT_90V_TO_27_SHALLOW_SHORT:
            # FIXME: LEFT OFF HERE: --------------------------
            pass
        SubtileCorner.INT_90V_TO_27_SHALLOW_LONG:
            # FIXME: LEFT OFF HERE: --------------------------
            pass
        SubtileCorner.INT_90V_TO_27_STEEP:
            # FIXME: LEFT OFF HERE: --------------------------
            pass
        
        SubtileCorner.INT_45_EXT_CORNER:
            # FIXME: LEFT OFF HERE: --------------------------
            pass
        SubtileCorner.INT_45_EXT_CORNER_TO_90H:
            # FIXME: LEFT OFF HERE: --------------------------
            pass
        SubtileCorner.INT_45_EXT_CORNER_TO_90V:
            # FIXME: LEFT OFF HERE: --------------------------
            pass
        SubtileCorner.INT_45_EXT_CORNER_TO_90H_AND_90V:
            # FIXME: LEFT OFF HERE: --------------------------
            pass
        
        SubtileCorner.INT_45_INT_CORNER:
            # FIXME: LEFT OFF HERE: --------------------------
            pass
        SubtileCorner.INT_45_INT_CORNER_WITH_90_90_CONCAVE:
            # FIXME: LEFT OFF HERE: --------------------------
            pass
        SubtileCorner.INT_45_INT_CORNER_WITH_90_90_CONVEX:
            # FIXME: LEFT OFF HERE: --------------------------
            pass
        SubtileCorner.INT_45_INT_CORNER_WITH_90H:
            # FIXME: LEFT OFF HERE: --------------------------
            pass
        SubtileCorner.INT_45_INT_CORNER_WITH_90V:
            # FIXME: LEFT OFF HERE: --------------------------
            pass
        SubtileCorner.INT_45_INT_CORNER_NARROW:
            # FIXME: LEFT OFF HERE: --------------------------
            pass
        SubtileCorner.INT_45_MID_NOTCH_H:
            # FIXME: LEFT OFF HERE: --------------------------
            pass
        SubtileCorner.INT_45_MID_NOTCH_V:
            # FIXME: LEFT OFF HERE: --------------------------
            pass
        
        SubtileCorner.INT_27_INT_CORNER_SHALLOW:
            # FIXME: LEFT OFF HERE: --------------------------
            pass
        SubtileCorner.INT_27_INT_CORNER_STEEP:
            # FIXME: LEFT OFF HERE: --------------------------
            pass
        
        SubtileCorner.UNKNOWN, \
        _:
            _log_error(
                    "_get_target_top_left_corner, invalid corner_type",
                    corners,
                    proximity)
    
    # Ensure that each quadrant was assigned.
    assert(tl == SubtileQuadrant.ERROR_TL, "tl was not assigned")
    assert(tr == SubtileQuadrant.ERROR_TR, "tr was not assigned")
    assert(bl == SubtileQuadrant.ERROR_BL, "bl was not assigned")
    assert(br == SubtileQuadrant.ERROR_BR, "br was not assigned")
    
    return {
        tl = tl,
        tr = tr,
        bl = bl,
        br = br,
    }


static func _log_error(
        message: String,
        corners: Dictionary,
        proximity: CellProximity) -> void:
    Sc.logger.error(
            "An error occured trying to find a matching subtile quadrant: " + \
            "%s; %s; %s" % [message, corners, proximity])



# FIXME: LEFT OFF HERE: --------------- REMOVE; This is useful for copy/pasting.
#                match corners.bl:
#                    SubtileCorner.EMPTY:
#                        # FIXME: LEFT OFF HERE: --------------------------------
#                        pass
#                    SubtileCorner.EXTERIOR:
#                        # FIXME: LEFT OFF HERE: --------------------------------
#                        pass
#                    SubtileCorner.INTERIOR:
#                        # FIXME: LEFT OFF HERE: --------------------------------
#                        pass
#
#                    SubtileCorner.EXT_90H:
#                        # FIXME: LEFT OFF HERE: --------------------------------
#                        pass
#                    SubtileCorner.EXT_90V:
#                        # FIXME: LEFT OFF HERE: --------------------------------
#                        pass
#                    SubtileCorner.EXT_90_90_CONVEX:
#                        # FIXME: LEFT OFF HERE: --------------------------------
#                        pass
#
#                    SubtileCorner.EXT_45_FLOOR:
#                        # FIXME: LEFT OFF HERE: --------------------------------
#                        pass
#                    SubtileCorner.EXT_45_CEILING:
#                        # FIXME: LEFT OFF HERE: --------------------------------
#                        pass
#
#                    SubtileCorner.EXT_CLIPPED_90_90:
#                        # FIXME: LEFT OFF HERE: --------------------------------
#                        pass
#                    SubtileCorner.EXT_CLIPPED_45_45:
#                        # FIXME: LEFT OFF HERE: --------------------------------
#                        pass
#                    SubtileCorner.EXT_CLIPPED_90H_45:
#                        # FIXME: LEFT OFF HERE: --------------------------------
#                        pass
#                    SubtileCorner.EXT_CLIPPED_90V_45:
#                        # FIXME: LEFT OFF HERE: --------------------------------
#                        pass
#
#                    SubtileCorner.EXT_90H_TO_45_CONVEX:
#                        # FIXME: LEFT OFF HERE: --------------------------------
#                        pass
#                    SubtileCorner.EXT_90V_TO_45_CONVEX:
#                        # FIXME: LEFT OFF HERE: --------------------------------
#                        pass
#                    SubtileCorner.EXT_90H_TO_45_CONVEX_ACUTE:
#                        # FIXME: LEFT OFF HERE: --------------------------------
#                        pass
#                    SubtileCorner.EXT_90V_TO_45_CONVEX_ACUTE:
#                        # FIXME: LEFT OFF HERE: --------------------------------
#                        pass
#
#                    SubtileCorner.EXT_45_FLOOR_TO_90:
#                        # FIXME: LEFT OFF HERE: --------------------------------
#                        pass
#                    SubtileCorner.EXT_45_FLOOR_TO_45_CONVEX:
#                        # FIXME: LEFT OFF HERE: --------------------------------
#                        pass
#                    SubtileCorner.EXT_45_CEILING_TO_90:
#                        # FIXME: LEFT OFF HERE: --------------------------------
#                        pass
#                    SubtileCorner.EXT_45_CEILING_TO_45_CONVEX:
#                        # FIXME: LEFT OFF HERE: --------------------------------
#                        pass
#
#                    SubtileCorner.EXT_CLIPPED_27_SHALLOW:
#                        # FIXME: LEFT OFF HERE: --------------------------------
#                        pass
#                    SubtileCorner.EXT_CLIPPED_27_STEEP:
#                        # FIXME: LEFT OFF HERE: --------------------------------
#                        pass
#
#                    SubtileCorner.EXT_27_FLOOR_SHALLOW_CLOSE:
#                        # FIXME: LEFT OFF HERE: --------------------------------
#                        pass
#                    SubtileCorner.EXT_27_FLOOR_SHALLOW_FAR:
#                        # FIXME: LEFT OFF HERE: --------------------------------
#                        pass
#                    SubtileCorner.EXT_27_FLOOR_STEEP_CLOSE:
#                        # FIXME: LEFT OFF HERE: --------------------------------
#                        pass
#                    SubtileCorner.EXT_27_FLOOR_STEEP_FAR:
#                        # FIXME: LEFT OFF HERE: --------------------------------
#                        pass
#
#                    SubtileCorner.EXT_27_CEILING_SHALLOW_CLOSE:
#                        # FIXME: LEFT OFF HERE: --------------------------------
#                        pass
#                    SubtileCorner.EXT_27_CEILING_SHALLOW_FAR:
#                        # FIXME: LEFT OFF HERE: --------------------------------
#                        pass
#                    SubtileCorner.EXT_27_CEILING_STEEP_CLOSE:
#                        # FIXME: LEFT OFF HERE: --------------------------------
#                        pass
#                    SubtileCorner.EXT_27_CEILING_STEEP_FAR:
#                        # FIXME: LEFT OFF HERE: --------------------------------
#                        pass
#
#                    SubtileCorner.UNKNOWN, \
#                    _:
#                        _log_error(
#                                "Invalid corners.bl",
#                                corners,
#                                proximity)
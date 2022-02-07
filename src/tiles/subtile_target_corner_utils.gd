class_name SubtileTargetCornerUtils
extends Reference


static func get_target_top_left_corner(proximity: CellProximity) -> int:
    if proximity.is_top_empty:
        if proximity.is_left_empty:
            if proximity.is_angle_type_45 or \
                    proximity.is_angle_type_27:
                return SubtileCorner.EMPTY
            else:
                return SubtileCorner.EXT_90_90_CONVEX
        else:
            # Top empty, left present.
            if proximity.get_is_90_floor_at_left():
                if proximity.get_is_45_pos_floor(-1, 0):
                    return SubtileCorner.EXT_90H_45_CONVEX
                else:
                    return SubtileCorner.EXT_90H
            elif proximity.get_is_45_neg_floor():
                return SubtileCorner.EXT_45_FLOOR
            elif proximity.is_angle_type_27:
                # FIXME: LEFT OFF HERE: -------- A27
                pass
            else:
                return SubtileCorner.EXT_90H
    else:
        if proximity.is_left_empty:
            # Top present, left empty.
            if proximity.get_is_90_right_wall_at_top():
                if proximity.get_is_45_pos_floor(0, -1):
                    return SubtileCorner.EXT_90V_45_CONVEX
                else:
                    return SubtileCorner.EXT_90V
            elif proximity.get_is_45_neg_ceiling():
                return SubtileCorner.EXT_45_CEILING
            elif proximity.is_angle_type_27:
                # FIXME: LEFT OFF HERE: -------- A27
                pass
            else:
                return SubtileCorner.EXT_90V
        else:
            # Adjacent sides are present.
            if proximity.is_top_left_empty:
                # Clipped corner.
                if proximity.get_is_90_right_wall_at_bottom(0, -1):
                    if proximity.get_is_90_floor_at_right(-1, 0):
                        return SubtileCorner.EXT_90_90_CONCAVE
                    elif proximity.get_is_45_pos_floor(-1, 0):
                        return SubtileCorner.EXT_90V_45_CONCAVE
                    elif proximity.get_angle_type(-1, 0) == CellAngleType.A27:
                        # FIXME: LEFT OFF HERE: -------- A27
                        pass
                    else:
                        _log_error(
                                "get_target_top_left_corner, " + \
                                "Clipped corner",
                                proximity)
                elif proximity.get_is_45_pos_floor(0, -1):
                    if proximity.get_is_90_floor_at_right(-1, 0):
                        return SubtileCorner.EXT_90H_45_CONCAVE
                    elif proximity.get_is_45_pos_floor(-1, 0):
                        return SubtileCorner.EXT_45_CLIPPED
                    elif proximity.get_angle_type(-1, 0) == CellAngleType.A27:
                        # FIXME: LEFT OFF HERE: -------- A27
                        pass
                    else:
                        _log_error(
                                "get_target_top_left_corner, " + \
                                "Clipped corner",
                                proximity)
                elif proximity.get_angle_type(0, -1) == CellAngleType.A27:
                    # FIXME: LEFT OFF HERE: -------- A27
                    pass
                else:
                    _log_error(
                            "get_target_top_left_corner, " + \
                            "Clipped corner",
                            proximity)
            else:
                # Internal(ish): Adjacent sides and corner are present.
                if proximity.is_bottom_empty:
                    if proximity.is_right_empty:
                        # Opposite sides are empty.
                        if proximity.is_angle_type_45:
                            return SubtileCorner.EXT_INT_45_CLIPPED
                        elif proximity.is_angle_type_27:
                            # FIXME: LEFT OFF HERE: -------- A27
                            pass
                        else:
                            return SubtileCorner.EXT_INT_90_90_CONVEX
                    else:
                        # Adjacent sides and corner and opposite horizontal
                        # side are present.
                        if proximity.is_top_right_empty:
                            if proximity.get_is_top_right_corner_clipped_90_90() or \
                                    proximity.get_is_top_right_corner_clipped_90V_45():
                                if proximity.get_is_45_neg_ceiling(-1,0):
                                    return SubtileCorner.EXT_INT_90V_45_CONVEX_ACUTE
                                else:
                                    return SubtileCorner.EXT_INT_90_90_CONVEX
                            elif proximity.get_is_top_right_corner_clipped_45_45() or \
                                    proximity.get_is_top_right_corner_clipped_90H_45():
                                if proximity.get_is_45_neg_ceiling(-1,0):
                                    return SubtileCorner.EXT_INT_45_FLOOR_45_CEILING
                                else:
                                    return SubtileCorner.EXT_INT_90H_45_CONVEX_ACUTE
                            else:
                                # FIXME: LEFT OFF HERE: -------- A27
                                pass
                        else:
                            if proximity.get_is_45_neg_ceiling(-1,0):
                                return SubtileCorner.EXT_INT_90H_45_CONVEX
                            else:
                                return SubtileCorner.EXT_INT_90H
                else:
                    if proximity.is_right_empty:
                        # Adjacent sides and corner and opposite vertical side
                        # are present.
                        if proximity.is_bottom_left_empty:
                            if proximity.get_is_bottom_left_corner_clipped_90_90() or \
                                    proximity.get_is_bottom_left_corner_clipped_90H_45():
                                if proximity.get_is_45_neg_floor(0,-1):
                                    return SubtileCorner.EXT_INT_90H_45_CONVEX
                                else:
                                    return SubtileCorner.EXT_INT_90_90_CONVEX
                            elif proximity.get_is_bottom_left_corner_clipped_45_45() or \
                                    proximity.get_is_bottom_left_corner_clipped_90V_45():
                                if proximity.get_is_45_neg_floor(0,-1):
                                    return SubtileCorner.EXT_INT_45_FLOOR_45_CEILING
                                else:
                                    return SubtileCorner.EXT_INT_90V_45_CONVEX
                            else:
                                # FIXME: LEFT OFF HERE: -------- A27
                                pass
                        else:
                            if proximity.get_is_45_neg_floor(0,-1):
                                return SubtileCorner.EXT_INT_90V_45_CONVEX
                            else:
                                return SubtileCorner.EXT_INT_90V
                    else:
                        # All sides and adjacent corner are present.
                        if proximity.is_top_right_empty:
                            if proximity.is_bottom_left_empty:
                                if proximity.is_bottom_right_empty:
                                    # FIXME: LEFT OFF HERE: --------------------
                                    pass
                                else:
                                    # FIXME: LEFT OFF HERE: --------------------
                                    pass
                            else:
                                if proximity.is_bottom_right_empty:
                                    # FIXME: LEFT OFF HERE: --------------------
                                    pass
                                else:
                                    # FIXME: LEFT OFF HERE: --------------------
                                    pass
                        else:
                            if proximity.is_bottom_left_empty:
                                if proximity.is_bottom_right_empty:
                                    # FIXME: LEFT OFF HERE: --------------------
                                    pass
                                else:
                                    # FIXME: LEFT OFF HERE: --------------------
                                    pass
                            else:
                                if proximity.is_bottom_right_empty:
                                    # FIXME: LEFT OFF HERE: --------------------
                                    pass
                                else:
                                    # FIXME: LEFT OFF HERE: --------------------
                                    pass
                
                
                
                
                
                
                
                
                
                
                
                
                
                # FIXME: LEFT OFF HERE: ---------------------------------------
                
                if proximity.is_bottom_empty or \
                        proximity.is_right_empty or \
                        proximity.is_top_right_empty or \
                        proximity.is_bottom_left_empty:
                    # FIXME: LEFT OFF HERE: ------------
                    pass
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
                                    return SubtileCorner.INT_45_INT_CORNER_WITH_90_90_CONCAVE
                                elif proximity.get_angle_type(-1, -1) == CellAngleType.A27:
                                    # FIXME: LEFT OFF HERE: -------- A27
                                    pass
                                else:
                                    return SubtileCorner.INT_45_INT_CORNER_NARROW
                            elif proximity.is_left_empty_at_left and \
                                    proximity.is_top_empty_at_top:
                                return SubtileCorner.INT_45_INT_CORNER_WITH_90_90_CONVEX
                            elif proximity.is_left_empty_at_left:
                                return SubtileCorner.INT_45_INT_CORNER_WITH_90V
                            elif proximity.is_top_empty_at_top:
                                return SubtileCorner.INT_45_INT_CORNER_WITH_90H
                            else:
                                return SubtileCorner.INT_45_INT_CORNER
                    else:
                        if proximity.get_is_bottom_right_corner_clipped_partial_27():
                            # FIXME: LEFT OFF HERE: -------- A27
                            pass
                        else:
                            # 90-90 cutout.
                            # FIXME: LEFT OFF HERE: ------------
                            pass
                else:
                    # Fully interior.
                    # FIXME: LEFT OFF HERE: -----------------------------------------
                    # - Pause this logic until adding some more CellProximity
                    #   helpers for internal cases.
                    pass
                    
                    
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
    return SubtileCorner.UNKNOWN


static func get_target_top_right_corner(proximity: CellProximity) -> int:
    # FIXME: LEFT OFF HERE: -----------------------------------
    
    # FIXME: LEFT OFF HERE: ---------- Remove after adding all above cases.
    return SubtileCorner.UNKNOWN


static func get_target_bottom_left_corner(proximity: CellProximity) -> int:
    # FIXME: LEFT OFF HERE: -----------------------------------
    
    # FIXME: LEFT OFF HERE: ---------- Remove after adding all above cases.
    return SubtileCorner.UNKNOWN


static func get_target_bottom_right_corner(proximity: CellProximity) -> int:
    # FIXME: LEFT OFF HERE: -----------------------------------
    
    # FIXME: LEFT OFF HERE: ---------- Remove after adding all above cases.
    return SubtileCorner.UNKNOWN


static func _log_error(
        message: String,
        proximity: CellProximity) -> void:
    Sc.logger.error(
            "An error occured trying to find a matching " + \
            "subtile corner type: %s; %s" % [message, proximity])

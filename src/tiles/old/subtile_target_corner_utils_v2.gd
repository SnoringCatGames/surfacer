class_name SubtileTargetCornerUtils
extends Reference


static func _get_target_top_left_corner(proximity: CellProximityV2) -> int:
    if proximity.is_top_empty:
        if proximity.is_left_empty:
            return SubtileCornerV2.EMPTY
        else:
            # Top empty, left present.
            if proximity.get_is_90_floor_at_left():
                if proximity.get_is_45_pos_floor(-1, 0):
                    return SubtileCornerV2.EXT_90H_TO_45_CONVEX
                else:
                    return SubtileCornerV2.EXT_90H
            elif proximity.get_is_45_neg_floor():
                if proximity.get_is_45_pos_floor(-1, 0):
                    return SubtileCornerV2.EXT_45_FLOOR_TO_45_CONVEX
                elif proximity.get_is_90_floor_at_right(-1, 0):
                    return SubtileCornerV2.EXT_45_FLOOR_TO_90
                else:
                    return SubtileCornerV2.EXT_45_FLOOR
            elif proximity.is_angle_type_27:
                # FIXME: LEFT OFF HERE: -------- A27
                pass
            else:
                return SubtileCornerV2.EXT_90H
    else:
        if proximity.is_left_empty:
            # Top present, left empty.
            if proximity.get_is_90_right_wall_at_top():
                if proximity.get_is_45_pos_floor(0, -1):
                    return SubtileCornerV2.EXT_90V_TO_45_CONVEX
                else:
                    return SubtileCornerV2.EXT_90V
            elif proximity.get_is_45_neg_ceiling():
                if proximity.get_is_45_pos_floor(0, -1):
                    return SubtileCornerV2.EXT_45_CEILING_TO_45_CONVEX
                elif proximity.get_is_90_right_wall_at_bottom(0, -1):
                    return SubtileCornerV2.EXT_45_CEILING_TO_90
                else:
                    return SubtileCornerV2.EXT_45_CEILING
            elif proximity.is_angle_type_27:
                # FIXME: LEFT OFF HERE: -------- A27
                pass
            else:
                return SubtileCornerV2.EXT_90V
        else:
            # Adjacent sides are present.
            if proximity.is_top_left_empty:
                # Clipped corner.
                if proximity.get_is_90_right_wall_at_bottom(0, -1):
                    if proximity.get_is_90_floor_at_right(-1, 0):
                        return SubtileCornerV2.EXT_CLIPPED_90_90
                    elif proximity.get_is_45_pos_floor(-1, 0):
                        return SubtileCornerV2.EXT_CLIPPED_90V_45
                    elif proximity.get_angle_type(-1, 0) == CellAngleType.A27:
                        # FIXME: LEFT OFF HERE: -------- A27
                        pass
                    else:
                        Sc.logger.error(
                                "_get_target_top_left_corner: " +
                                "Clipped corner: " + 
                                "Invalid case: %s" % proximity.to_string())
                elif proximity.get_is_45_pos_floor(0, -1):
                    if proximity.get_is_90_floor_at_right(-1, 0):
                        return SubtileCornerV2.EXT_CLIPPED_90H_45
                    elif proximity.get_is_45_pos_floor(-1, 0):
                        return SubtileCornerV2.EXT_CLIPPED_45_45
                    elif proximity.get_angle_type(-1, 0) == CellAngleType.A27:
                        # FIXME: LEFT OFF HERE: -------- A27
                        pass
                    else:
                        Sc.logger.error(
                                "_get_target_top_left_corner: " +
                                "Clipped corner: " + 
                                "Invalid case: %s" % proximity.to_string())
                elif proximity.get_angle_type(0, -1) == CellAngleType.A27:
                    # FIXME: LEFT OFF HERE: -------- A27
                    pass
                else:
                    Sc.logger.error(
                            "_get_target_top_left_corner: " +
                            "Clipped corner: " + 
                            "Invalid case: %s" % proximity.to_string())
            else:
                # Adjacent sides and corner are present.
                if proximity.get_is_bottom_left_corner_clipped_45_45() and \
                        proximity.get_is_bottom_right_corner_clipped_45_45() and \
                        !proximity.is_top_right_empty:
                    return SubtileCornerV2.INT_45_MID_NOTCH_H
                elif proximity.get_is_top_right_corner_clipped_45_45() and \
                        proximity.get_is_bottom_right_corner_clipped_45_45() and \
                        !proximity.is_bottom_left_empty:
                    return SubtileCornerV2.INT_45_MID_NOTCH_V
                elif proximity.is_bottom_empty or \
                        proximity.is_right_empty or \
                        proximity.is_top_right_empty or \
                        proximity.is_bottom_left_empty:
                    # This corner is not deep enough to have transitioned to
                    # interior.
                    return SubtileCornerV2.EXTERIOR
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
                                    return SubtileCornerV2.INT_45_INT_CORNER_WITH_90_90_CONCAVE
                                elif proximity.get_angle_type(-1, -1) == CellAngleType.A27:
                                    # FIXME: LEFT OFF HERE: -------- A27
                                    pass
                                else:
                                    return SubtileCornerV2.INT_45_INT_CORNER_NARROW
                            elif proximity.is_left_empty_at_left and \
                                    proximity.is_top_empty_at_top:
                                return SubtileCornerV2.INT_45_INT_CORNER_WITH_90_90_CONVEX
                            elif proximity.is_left_empty_at_left:
                                return SubtileCornerV2.INT_45_INT_CORNER_WITH_90V
                            elif proximity.is_top_empty_at_top:
                                return SubtileCornerV2.INT_45_INT_CORNER_WITH_90H
                            else:
                                return SubtileCornerV2.INT_45_INT_CORNER
                    else:
                        if proximity.get_is_bottom_right_corner_clipped_partial_27():
                            # FIXME: LEFT OFF HERE: -------- A27
                            pass
                        else:
                            # 90-90 cutout.
                            return SubtileCornerV2.EXTERIOR
                else:
                    # Fully interior.
                    # FIXME: LEFT OFF HERE: -----------------------------------------
                    # - Pause this logic until adding some more CellProximityV2
                    #   helpers for internal cases.
                    pass
                    return SubtileCornerV2.INTERIOR
                    
                    
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
    return SubtileCornerV2.UNKNOWN


static func _get_target_top_right_corner(proximity: CellProximityV2) -> int:
    if proximity.is_top_empty:
        if proximity.is_right_empty:
            return SubtileCornerV2.EMPTY
        else:
            # Top empty, right present.
            if proximity.get_is_90_floor_at_right():
                if proximity.get_is_45_pos_floor(1, 0):
                    return SubtileCornerV2.EXT_90H_TO_45_CONVEX
                else:
                    return SubtileCornerV2.EXT_90H
            elif proximity.get_is_45_neg_floor():
                if proximity.get_is_45_pos_floor(1, 0):
                    return SubtileCornerV2.EXT_45_FLOOR_TO_45_CONVEX
                elif proximity.get_is_90_floor_at_left(1, 0):
                    return SubtileCornerV2.EXT_45_FLOOR_TO_90
                else:
                    return SubtileCornerV2.EXT_45_FLOOR
            elif proximity.is_angle_type_27:
                # FIXME: LEFT OFF HERE: -------- A27
                pass
            else:
                return SubtileCornerV2.EXT_90H
    else:
        if proximity.is_right_empty:
            # Top present, right empty.
            if proximity.get_is_90_left_wall_at_top():
                if proximity.get_is_45_pos_floor(0, -1):
                    return SubtileCornerV2.EXT_90V_TO_45_CONVEX
                else:
                    return SubtileCornerV2.EXT_90V
            elif proximity.get_is_45_neg_ceiling():
                if proximity.get_is_45_pos_floor(0, -1):
                    return SubtileCornerV2.EXT_45_CEILING_TO_45_CONVEX
                elif proximity.get_is_90_left_wall_at_bottom(0, -1):
                    return SubtileCornerV2.EXT_45_CEILING_TO_90
                else:
                    return SubtileCornerV2.EXT_45_CEILING
            elif proximity.is_angle_type_27:
                # FIXME: LEFT OFF HERE: -------- A27
                pass
            else:
                return SubtileCornerV2.EXT_90V
        else:
            # Adjacent sides are present.
            if proximity.is_top_right_empty:
                # Clipped corner.
                if proximity.get_is_90_left_wall_at_bottom(0, -1):
                    if proximity.get_is_90_floor_at_left(1, 0):
                        return SubtileCornerV2.EXT_CLIPPED_90_90
                    elif proximity.get_is_45_pos_floor(1, 0):
                        return SubtileCornerV2.EXT_CLIPPED_90V_45
                    elif proximity.get_angle_type(1, 0) == CellAngleType.A27:
                        # FIXME: LEFT OFF HERE: -------- A27
                        pass
                    else:
                        Sc.logger.error(
                                "_get_target_top_right_corner: " +
                                "Clipped corner: " + 
                                "Invalid case: %s" % proximity.to_string())
                elif proximity.get_is_45_pos_floor(0, -1):
                    if proximity.get_is_90_floor_at_left(1, 0):
                        return SubtileCornerV2.EXT_CLIPPED_90H_45
                    elif proximity.get_is_45_pos_floor(1, 0):
                        return SubtileCornerV2.EXT_CLIPPED_45_45
                    elif proximity.get_angle_type(1, 0) == CellAngleType.A27:
                        # FIXME: LEFT OFF HERE: -------- A27
                        pass
                    else:
                        Sc.logger.error(
                                "_get_target_top_right_corner: " +
                                "Clipped corner: " + 
                                "Invalid case: %s" % proximity.to_string())
                elif proximity.get_angle_type(0, -1) == CellAngleType.A27:
                    # FIXME: LEFT OFF HERE: -------- A27
                    pass
                else:
                    Sc.logger.error(
                            "_get_target_top_right_corner: " +
                            "Clipped corner: " + 
                            "Invalid case: %s" % proximity.to_string())
            else:
                # Adjacent sides and corner are present.
                if proximity.get_is_bottom_left_corner_clipped_45_45() and \
                        proximity.get_is_bottom_right_corner_clipped_45_45() and \
                        !proximity.is_top_left_empty:
                    return SubtileCornerV2.INT_45_MID_NOTCH_H
                elif proximity.get_is_top_left_corner_clipped_45_45() and \
                        proximity.get_is_bottom_right_corner_clipped_45_45() and \
                        !proximity.is_bottom_right_empty:
                    return SubtileCornerV2.INT_45_MID_NOTCH_V
                elif proximity.is_bottom_empty or \
                        proximity.is_left_empty or \
                        proximity.is_top_left_empty or \
                        proximity.is_bottom_right_empty:
                    # This corner is not deep enough to have transitioned to
                    # interior.
                    return SubtileCornerV2.EXTERIOR
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
                                    return SubtileCornerV2.INT_45_INT_CORNER_WITH_90_90_CONCAVE
                                elif proximity.get_angle_type(1, -1) == CellAngleType.A27:
                                    # FIXME: LEFT OFF HERE: -------- A27
                                    pass
                                else:
                                    return SubtileCornerV2.INT_45_INT_CORNER_NARROW
                            elif proximity.is_right_empty_at_right and \
                                    proximity.is_top_empty_at_top:
                                return SubtileCornerV2.INT_45_INT_CORNER_WITH_90_90_CONVEX
                            elif proximity.is_right_empty_at_right:
                                return SubtileCornerV2.INT_45_INT_CORNER_WITH_90V
                            elif proximity.is_top_empty_at_top:
                                return SubtileCornerV2.INT_45_INT_CORNER_WITH_90H
                            else:
                                return SubtileCornerV2.INT_45_INT_CORNER
                    else:
                        if proximity.get_is_bottom_left_corner_clipped_partial_27():
                            # FIXME: LEFT OFF HERE: -------- A27
                            pass
                        else:
                            # 90-90 cutout.
                            return SubtileCornerV2.EXTERIOR
                else:
                    # Fully interior.
                    # FIXME: LEFT OFF HERE: -----------------------------------------
                    # - Pause this logic until adding some more CellProximityV2
                    #   helpers for internal cases.
                    pass
                    return SubtileCornerV2.INTERIOR
                    
                    
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
    return SubtileCornerV2.UNKNOWN


static func _get_target_bottom_left_corner(proximity: CellProximityV2) -> int:
    if proximity.is_bottom_empty:
        if proximity.is_left_empty:
            return SubtileCornerV2.EMPTY
        else:
            # Bottom empty, left present.
            if proximity.get_is_90_ceiling_at_left():
                if proximity.get_is_45_pos_ceiling(-1, 0):
                    return SubtileCornerV2.EXT_90H_TO_45_CONVEX
                else:
                    return SubtileCornerV2.EXT_90H
            elif proximity.get_is_45_neg_ceiling():
                if proximity.get_is_45_pos_ceiling(-1, 0):
                    return SubtileCornerV2.EXT_45_CEILING_TO_45_CONVEX
                elif proximity.get_is_90_ceiling_at_right(-1, 0):
                    return SubtileCornerV2.EXT_45_CEILING_TO_90
                else:
                    return SubtileCornerV2.EXT_45_CEILING
            elif proximity.is_angle_type_27:
                # FIXME: LEFT OFF HERE: -------- A27
                pass
            else:
                return SubtileCornerV2.EXT_90H
    else:
        if proximity.is_left_empty:
            # Bottom present, left empty.
            if proximity.get_is_90_right_wall_at_bottom():
                if proximity.get_is_45_pos_ceiling(0, 1):
                    return SubtileCornerV2.EXT_90V_TO_45_CONVEX
                else:
                    return SubtileCornerV2.EXT_90V
            elif proximity.get_is_45_neg_floor():
                if proximity.get_is_45_pos_ceiling(0, 1):
                    return SubtileCornerV2.EXT_45_FLOOR_TO_45_CONVEX
                elif proximity.get_is_90_right_wall_at_top(0, 1):
                    return SubtileCornerV2.EXT_45_FLOOR_TO_90
                else:
                    return SubtileCornerV2.EXT_45_FLOOR
            elif proximity.is_angle_type_27:
                # FIXME: LEFT OFF HERE: -------- A27
                pass
            else:
                return SubtileCornerV2.EXT_90V
        else:
            # Adjacent sides are present.
            if proximity.is_bottom_left_empty:
                # Clipped corner.
                if proximity.get_is_90_right_wall_at_top(0, 1):
                    if proximity.get_is_90_ceiling_at_right(-1, 0):
                        return SubtileCornerV2.EXT_CLIPPED_90_90
                    elif proximity.get_is_45_pos_ceiling(-1, 0):
                        return SubtileCornerV2.EXT_CLIPPED_90V_45
                    elif proximity.get_angle_type(-1, 0) == CellAngleType.A27:
                        # FIXME: LEFT OFF HERE: -------- A27
                        pass
                    else:
                        Sc.logger.error(
                                "_get_target_bottom_left_corner: " +
                                "Clipped corner: " + 
                                "Invalid case: %s" % proximity.to_string())
                elif proximity.get_is_45_pos_ceiling(0, 1):
                    if proximity.get_is_90_ceiling_at_right(-1, 0):
                        return SubtileCornerV2.EXT_CLIPPED_90H_45
                    elif proximity.get_is_45_pos_ceiling(-1, 0):
                        return SubtileCornerV2.EXT_CLIPPED_45_45
                    elif proximity.get_angle_type(-1, 0) == CellAngleType.A27:
                        # FIXME: LEFT OFF HERE: -------- A27
                        pass
                    else:
                        Sc.logger.error(
                                "_get_target_bottom_left_corner: " +
                                "Clipped corner: " + 
                                "Invalid case: %s" % proximity.to_string())
                elif proximity.get_angle_type(0, 1) == CellAngleType.A27:
                    # FIXME: LEFT OFF HERE: -------- A27
                    pass
                else:
                    Sc.logger.error(
                            "_get_target_bottom_left_corner: " +
                            "Clipped corner: " + 
                            "Invalid case: %s" % proximity.to_string())
            else:
                # Adjacent sides and corner are present.
                if proximity.get_is_top_left_corner_clipped_45_45() and \
                        proximity.get_is_top_right_corner_clipped_45_45() and \
                        !proximity.is_bottom_right_empty:
                    return SubtileCornerV2.INT_45_MID_NOTCH_H
                elif proximity.get_is_top_right_corner_clipped_45_45() and \
                        proximity.get_is_bottom_right_corner_clipped_45_45() and \
                        !proximity.is_top_left_empty:
                    return SubtileCornerV2.INT_45_MID_NOTCH_V
                elif proximity.is_top_empty or \
                        proximity.is_right_empty or \
                        proximity.is_bottom_right_empty or \
                        proximity.is_top_left_empty:
                    # This corner is not deep enough to have transitioned to
                    # interior.
                    return SubtileCornerV2.EXTERIOR
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
                                    return SubtileCornerV2.INT_45_INT_CORNER_WITH_90_90_CONCAVE
                                elif proximity.get_angle_type(-1, 1) == CellAngleType.A27:
                                    # FIXME: LEFT OFF HERE: -------- A27
                                    pass
                                else:
                                    return SubtileCornerV2.INT_45_INT_CORNER_NARROW
                            elif proximity.is_left_empty_at_left and \
                                    proximity.is_bottom_empty_at_bottom:
                                return SubtileCornerV2.INT_45_INT_CORNER_WITH_90_90_CONVEX
                            elif proximity.is_left_empty_at_left:
                                return SubtileCornerV2.INT_45_INT_CORNER_WITH_90V
                            elif proximity.is_bottom_empty_at_bottom:
                                return SubtileCornerV2.INT_45_INT_CORNER_WITH_90H
                            else:
                                return SubtileCornerV2.INT_45_INT_CORNER
                    else:
                        if proximity.get_is_top_right_corner_clipped_partial_27():
                            # FIXME: LEFT OFF HERE: -------- A27
                            pass
                        else:
                            # 90-90 cutout.
                            return SubtileCornerV2.EXTERIOR
                else:
                    # Fully interior.
                    # FIXME: LEFT OFF HERE: -----------------------------------------
                    # - Pause this logic until adding some more CellProximityV2
                    #   helpers for internal cases.
                    pass
                    return SubtileCornerV2.INTERIOR
                    
                    
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
    return SubtileCornerV2.UNKNOWN


static func _get_target_bottom_right_corner(proximity: CellProximityV2) -> int:
    if proximity.is_bottom_empty:
        if proximity.is_right_empty:
            return SubtileCornerV2.EMPTY
        else:
            # Bottom empty, right present.
            if proximity.get_is_90_ceiling_at_right():
                if proximity.get_is_45_pos_ceiling(1, 0):
                    return SubtileCornerV2.EXT_90H_TO_45_CONVEX
                else:
                    return SubtileCornerV2.EXT_90H
            elif proximity.get_is_45_neg_ceiling():
                if proximity.get_is_45_pos_ceiling(1, 0):
                    return SubtileCornerV2.EXT_45_CEILING_TO_45_CONVEX
                elif proximity.get_is_90_ceiling_at_left(1, 0):
                    return SubtileCornerV2.EXT_45_CEILING_TO_90
                else:
                    return SubtileCornerV2.EXT_45_CEILING
            elif proximity.is_angle_type_27:
                # FIXME: LEFT OFF HERE: -------- A27
                pass
            else:
                return SubtileCornerV2.EXT_90H
    else:
        if proximity.is_right_empty:
            # Bottom present, right empty.
            if proximity.get_is_90_left_wall_at_bottom():
                if proximity.get_is_45_pos_ceiling(0, 1):
                    return SubtileCornerV2.EXT_90V_TO_45_CONVEX
                else:
                    return SubtileCornerV2.EXT_90V
            elif proximity.get_is_45_neg_floor():
                if proximity.get_is_45_pos_ceiling(0, 1):
                    return SubtileCornerV2.EXT_45_FLOOR_TO_45_CONVEX
                elif proximity.get_is_90_left_wall_at_top(0, 1):
                    return SubtileCornerV2.EXT_45_FLOOR_TO_90
                else:
                    return SubtileCornerV2.EXT_45_FLOOR
            elif proximity.is_angle_type_27:
                # FIXME: LEFT OFF HERE: -------- A27
                pass
            else:
                return SubtileCornerV2.EXT_90V
        else:
            # Adjacent sides are present.
            if proximity.is_bottom_right_empty:
                # Clipped corner.
                if proximity.get_is_90_left_wall_at_top(0, 1):
                    if proximity.get_is_90_ceiling_at_left(1, 0):
                        return SubtileCornerV2.EXT_CLIPPED_90_90
                    elif proximity.get_is_45_pos_ceiling(1, 0):
                        return SubtileCornerV2.EXT_CLIPPED_90V_45
                    elif proximity.get_angle_type(1, 0) == CellAngleType.A27:
                        # FIXME: LEFT OFF HERE: -------- A27
                        pass
                    else:
                        Sc.logger.error(
                                "_get_target_bottom_right_corner: " +
                                "Clipped corner: " + 
                                "Invalid case: %s" % proximity.to_string())
                elif proximity.get_is_45_pos_ceiling(0, 1):
                    if proximity.get_is_90_ceiling_at_left(1, 0):
                        return SubtileCornerV2.EXT_CLIPPED_90H_45
                    elif proximity.get_is_45_pos_ceiling(1, 0):
                        return SubtileCornerV2.EXT_CLIPPED_45_45
                    elif proximity.get_angle_type(1, 0) == CellAngleType.A27:
                        # FIXME: LEFT OFF HERE: -------- A27
                        pass
                    else:
                        Sc.logger.error(
                                "_get_target_bottom_right_corner: " +
                                "Clipped corner: " + 
                                "Invalid case: %s" % proximity.to_string())
                elif proximity.get_angle_type(0, 1) == CellAngleType.A27:
                    # FIXME: LEFT OFF HERE: -------- A27
                    pass
                else:
                    Sc.logger.error(
                            "_get_target_bottom_right_corner: " +
                            "Clipped corner: " + 
                            "Invalid case: %s" % proximity.to_string())
            else:
                # Adjacent sides and corner are present.
                if proximity.get_is_top_left_corner_clipped_45_45() and \
                        proximity.get_is_top_right_corner_clipped_45_45() and \
                        !proximity.is_bottom_left_empty:
                    return SubtileCornerV2.INT_45_MID_NOTCH_H
                elif proximity.get_is_top_left_corner_clipped_45_45() and \
                        proximity.get_is_bottom_left_corner_clipped_45_45() and \
                        !proximity.is_top_right_empty:
                    return SubtileCornerV2.INT_45_MID_NOTCH_V
                elif proximity.is_top_empty or \
                        proximity.is_left_empty or \
                        proximity.is_bottom_left_empty or \
                        proximity.is_top_right_empty:
                    # This corner is not deep enough to have transitioned to
                    # interior.
                    return SubtileCornerV2.EXTERIOR
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
                                if proximity.get_angle_type(1, 1) == CellAngleType.A90:
                                    return SubtileCornerV2.INT_45_INT_CORNER_WITH_90_90_CONCAVE
                                elif proximity.get_angle_type(1, 1) == CellAngleType.A27:
                                    # FIXME: LEFT OFF HERE: -------- A27
                                    pass
                                else:
                                    return SubtileCornerV2.INT_45_INT_CORNER_NARROW
                            elif proximity.is_right_empty_at_right and \
                                    proximity.is_bottom_empty_at_bottom:
                                return SubtileCornerV2.INT_45_INT_CORNER_WITH_90_90_CONVEX
                            elif proximity.is_right_empty_at_right:
                                return SubtileCornerV2.INT_45_INT_CORNER_WITH_90V
                            elif proximity.is_bottom_empty_at_bottom:
                                return SubtileCornerV2.INT_45_INT_CORNER_WITH_90H
                            else:
                                return SubtileCornerV2.INT_45_INT_CORNER
                    else:
                        if proximity.get_is_top_left_corner_clipped_partial_27():
                            # FIXME: LEFT OFF HERE: -------- A27
                            pass
                        else:
                            # 90-90 cutout.
                            return SubtileCornerV2.EXTERIOR
                else:
                    # Fully interior.
                    # FIXME: LEFT OFF HERE: -----------------------------------------
                    # - Pause this logic until adding some more CellProximityV2
                    #   helpers for internal cases.
                    pass
                    return SubtileCornerV2.INTERIOR
                    
                    
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
    return SubtileCornerV2.UNKNOWN

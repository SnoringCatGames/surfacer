class_name SubtileTargetCornerCalculator
extends Node


func get_target_top_left_corner(proximity: CellProximity) -> int:
    if proximity.is_top_empty:
        if proximity.is_left_empty:
            if proximity.get_is_90_floor():
                if proximity.get_is_90_right_wall():
                    return SubtileCorner.EXT_90_90_CONVEX
                elif proximity.get_is_45_neg_ceiling():
                    return SubtileCorner.EXT_90H_45_CONVEX_ACUTE
                else:
                    # FIXME: LEFT OFF HERE: -------- A27
                    pass
            elif proximity.get_is_90_right_wall():
                if proximity.get_is_45_neg_floor():
                    return SubtileCorner.EXT_90V_45_CONVEX_ACUTE
                else:
                    # FIXME: LEFT OFF HERE: -------- A27
                    pass
            else:
                return SubtileCorner.EMPTY
        else:
            # Top empty, left present.
            if proximity.get_is_90_floor_at_left():
                if proximity.get_is_45_pos_floor(-1,0):
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
                if proximity.get_is_45_pos_floor(0,-1):
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
                if proximity.get_is_90_right_wall_at_bottom(0,-1):
                    if proximity.get_is_90_floor_at_right(-1,0):
                        return SubtileCorner.EXT_90_90_CONCAVE
                    elif proximity.get_is_45_pos_floor(-1,0):
                        return SubtileCorner.EXT_90V_45_CONCAVE
                    elif proximity.get_angle_type(-1,0) == CellAngleType.A27:
                        # FIXME: LEFT OFF HERE: -------- A27
                        pass
                    else:
                        _log_error(
                                "get_target_top_left_corner, " + \
                                "Clipped corner",
                                proximity)
                elif proximity.get_is_45_pos_floor(0,-1):
                    if proximity.get_is_90_floor_at_right(-1,0):
                        return SubtileCorner.EXT_90H_45_CONCAVE
                    elif proximity.get_is_45_pos_floor(-1,0):
                        return SubtileCorner.EXT_EXT_45_CLIPPED
                    elif proximity.get_angle_type(-1,0) == CellAngleType.A27:
                        # FIXME: LEFT OFF HERE: -------- A27
                        pass
                    else:
                        _log_error(
                                "get_target_top_left_corner, " + \
                                "Clipped corner",
                                proximity)
                elif proximity.get_angle_type(0,-1) == CellAngleType.A27:
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
                                    return SubtileCorner.EXT_INT_90H_45_CONVEX_ACUTE
                                else:
                                    return SubtileCorner.EXT_INT_90_90_CONVEX
                            elif proximity.get_is_bottom_left_corner_clipped_45_45() or \
                                    proximity.get_is_bottom_left_corner_clipped_90V_45():
                                if proximity.get_is_45_neg_floor(0,-1):
                                    return SubtileCorner.EXT_INT_45_FLOOR_45_CEILING
                                else:
                                    return SubtileCorner.EXT_INT_90V_45_CONVEX_ACUTE
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
                                # Only the horizontal-opposite and vertical-opposite corners are empty.
                                if proximity.get_is_top_right_corner_clipped_90_90() or \
                                        proximity.get_is_top_right_corner_clipped_90V_45():
                                    if proximity.get_is_bottom_left_corner_clipped_90_90() or \
                                            proximity.get_is_bottom_left_corner_clipped_90H_45():
                                        return SubtileCorner.EXT_INT_90_90_CONVEX
                                    elif proximity.get_is_bottom_left_corner_clipped_45_45() or \
                                            proximity.get_is_bottom_left_corner_clipped_90V_45():
                                        return SubtileCorner.EXT_INT_90V_45_CONVEX_ACUTE
                                    else:
                                        # FIXME: LEFT OFF HERE: -------- A27
                                        pass
                                elif proximity.get_is_top_right_corner_clipped_45_45() or \
                                        proximity.get_is_top_right_corner_clipped_90H_45():
                                    if proximity.get_is_bottom_left_corner_clipped_90_90() or \
                                            proximity.get_is_bottom_left_corner_clipped_90H_45():
                                        return SubtileCorner.EXT_INT_90H_45_CONVEX_ACUTE
                                    elif proximity.get_is_bottom_left_corner_clipped_45_45() or \
                                            proximity.get_is_bottom_left_corner_clipped_90V_45():
                                        return SubtileCorner.EXT_INT_45_FLOOR_45_CEILING
                                    else:
                                        # FIXME: LEFT OFF HERE: -------- A27
                                        pass
                                else:
                                    # FIXME: LEFT OFF HERE: -------- A27
                                    pass
                            else:
                                # Only the horizontal-opposite corner is empty.
                                if proximity.get_is_top_right_corner_clipped_90_90():
                                    return SubtileCorner.EXT_INT_90V
                                elif proximity.get_is_top_right_corner_clipped_45_45() or \
                                        proximity.get_is_top_right_corner_clipped_90H_45():
                                    if proximity.get_is_90_right_wall(-1,0):
                                        return SubtileCorner.INT_90V_EXT_INT_45_CONVEX_ACUTE
                                    else:
                                        return SubtileCorner.EXT_INT_45_FLOOR
                                elif proximity.get_is_top_right_corner_clipped_90V_45():
                                    if proximity.get_is_90_right_wall(-1,0):
                                        return SubtileCorner.INT_90V_EXT_INT_90V_45_CONCAVE
                                    else:
                                        return SubtileCorner.EXT_INT_90V_45_CONCAVE
                                else:
                                    # FIXME: LEFT OFF HERE: -------- A27
                                    pass
                        else:
                            if proximity.is_bottom_left_empty:
                                # Only the vertical-opposite corner is empty.
                                if proximity.get_is_bottom_left_corner_clipped_90_90():
                                    return SubtileCorner.EXT_INT_90H
                                elif proximity.get_is_bottom_left_corner_clipped_45_45() or \
                                        proximity.get_is_bottom_left_corner_clipped_90V_45():
                                    if proximity.get_is_90_floor(0,-1):
                                        return SubtileCorner.INT_90H_EXT_INT_45_CONVEX_ACUTE
                                    else:
                                        return SubtileCorner.EXT_INT_45_CEILING
                                elif proximity.get_is_bottom_left_corner_clipped_90H_45():
                                    if proximity.get_is_90_floor(0,-1):
                                        return SubtileCorner.INT_90H_EXT_INT_90H_45_CONCAVE
                                    else:
                                        return SubtileCorner.EXT_INT_90H_45_CONCAVE
                                else:
                                    # FIXME: LEFT OFF HERE: -------- A27
                                    pass
                            else:
                                if proximity.is_bottom_right_empty:
                                    # Only the opposite corner is empty.
                                    if proximity.get_is_bottom_right_corner_clipped_90_90():
                                        return SubtileCorner.EXT_INT_90_90_CONCAVE
                                    elif proximity.get_is_45_pos_floor(-1,-1):
                                        if proximity.get_is_90_floor(0,-1):
                                            if proximity.get_is_90_right_wall(-1,0):
                                                return SubtileCorner.INT_90_90_CONVEX_INT_EXT_45_CLIPPED
                                            else:
                                                return SubtileCorner.INT_90H_INT_EXT_45_CLIPPED
                                        else:
                                            if proximity.get_is_90_right_wall(-1,0):
                                                return SubtileCorner.INT_90V_INT_EXT_45_CLIPPED
                                            else:
                                                return SubtileCorner.INT_EXT_45_CLIPPED
                                    elif proximity.get_is_90_floor(0,-1):
                                        if proximity.get_is_90_right_wall(-1,0):
                                            # This is an interior floor and interior right-wall.
                                            return SubtileCorner.INT_90_90_CONVEX
                                        else:
                                            # This is an interior floor.
                                            return SubtileCorner.INT_90H
                                    else:
                                        # All neighbors are present, except for the opposite corner.
                                        if proximity.get_is_90_right_wall(-1,0):
                                            # This is an interior right-wall.
                                            return SubtileCorner.INT_90V
                                        else:
                                            if proximity.get_is_top_left_corner_clipped_90_90(-1,-1):
                                                # This is an interior 90-90 concave corner.
                                                return SubtileCorner.INT_90_90_CONCAVE
                                            else:
                                                # This is a deeply-interior corner.
                                                if proximity.get_is_bottom_right_corner_clipped_90_90():
                                                    return SubtileCorner.EXT_INT_90_90_CONCAVE
                                                elif proximity.get_is_bottom_right_corner_clipped_45_45():
                                                    return SubtileCorner.INT_INT_45_CLIPPED
                                                elif proximity.get_is_bottom_right_corner_clipped_90H_45():
                                                    return SubtileCorner.INT_EXT_90H_45_CONCAVE
                                                elif proximity.get_is_bottom_right_corner_clipped_90V_45():
                                                    return SubtileCorner.INT_EXT_90V_45_CONCAVE
                                                else:
                                                    # FIXME: LEFT OFF HERE: -------- A27
                                                    pass
                                else:
                                    # Fully internal: All sides and corners are present.
                                    
                                    # FIXME: LEFT OFF HERE: -------- A27
                                    
                                    if proximity.get_is_90_floor(0,-1) or \
                                            proximity.get_is_90_floor(-1,-1):
                                        if proximity.get_is_90_right_wall(-1,0) or \
                                                proximity.get_is_90_right_wall(-1,-1):
                                            if proximity.get_is_45_pos_floor(-1,-1):
                                                return SubtileCorner.INT_90_90_CONVEX_INT_EXT_45_CLIPPED
                                            else:
                                                return SubtileCorner.INT_90_90_CONVEX
                                        else:
                                            if proximity.get_is_45_pos_floor(-1,-1):
                                                return SubtileCorner.INT_90H_INT_EXT_45_CLIPPED
                                            elif proximity.get_is_bottom_left_corner_clipped_90V_45(-1,0):
                                                return SubtileCorner.INT_90H_INT_INT_90V_45_CONCAVE
                                            else:
                                                return SubtileCorner.INT_90H
                                    else:
                                        if proximity.get_is_90_right_wall(-1,0) or \
                                                proximity.get_is_90_right_wall(-1,-1):
                                            if proximity.get_is_45_pos_floor(-1,-1):
                                                return SubtileCorner.INT_90V_INT_EXT_45_CLIPPED
                                            elif proximity.get_is_top_right_corner_clipped_90H_45(0,-1):
                                                return SubtileCorner.INT_90V_INT_INT_90H_45_CONCAVE
                                            else:
                                                return SubtileCorner.INT_90V
                                        else:
                                            if proximity.get_is_45_pos_floor(-1,-1):
                                                return SubtileCorner.INT_EXT_45_CLIPPED
                                            else:
                                                if proximity.get_is_top_left_corner_clipped_90_90(-1,-1):
                                                    if proximity.get_is_45_neg_floor(0,-2):
                                                        if proximity.get_is_45_neg_ceiling(-2,0):
                                                            return SubtileCorner.INT_90_90_CONCAVE_INT_45_FLOOR_45_CEILING
                                                        else:
                                                            if proximity.get_is_bottom_left_corner_clipped_90V_45(-1,0):
                                                                return SubtileCorner.INT_90_90_CONCAVE_INT_INT_90V_45_CONCAVE_INT_45_FLOOR
                                                            else:
                                                                return SubtileCorner.INT_90_90_CONCAVE_INT_45_FLOOR
                                                    else:
                                                        if proximity.get_is_45_neg_ceiling(-2,0):
                                                            if proximity.get_is_top_right_corner_clipped_90H_45(0,-1):
                                                                return SubtileCorner.INT_90_90_CONCAVE_INT_INT_90H_45_CONCAVE_INT_45_CEILING
                                                            else:
                                                                return SubtileCorner.INT_90_90_CONCAVE_INT_45_CEILING
                                                        else:
                                                            if proximity.get_is_top_right_corner_clipped_90H_45(0,-1):
                                                                if proximity.get_is_bottom_left_corner_clipped_90V_45(-1,0):
                                                                    return SubtileCorner.INT_90_90_CONCAVE_INT_INT_90H_45_CONCAVE_90V_45_CONCAVE
                                                                else:
                                                                    return SubtileCorner.INT_90_90_CONCAVE_INT_INT_90H_45_CONCAVE
                                                            else:
                                                                if proximity.get_is_bottom_left_corner_clipped_90V_45(-1,0):
                                                                    return SubtileCorner.INT_90_90_CONCAVE_INT_INT_90V_45_CONCAVE
                                                                else:
                                                                    return SubtileCorner.INT_90_90_CONCAVE
                                                else:
                                                    # All indirect neighbors in the directions of this corner are present.
                                                    if proximity.get_is_45_neg_floor(0,-2):
                                                        if proximity.get_is_45_neg_ceiling(-2,0):
                                                            if proximity.get_is_top_right_corner_clipped_90H_45(0,-1):
                                                                if proximity.get_is_bottom_left_corner_clipped_90V_45(-1,0):
                                                                    return SubtileCorner.INT_INT_90H_45_CONCAVE_90V_45_CONCAVE
                                                                else:
                                                                    return SubtileCorner.INT_INT_90H_45_CONCAVE_INT_45_CEILING
                                                            else:
                                                                if proximity.get_is_bottom_left_corner_clipped_90V_45(-1,0):
                                                                    return SubtileCorner.INT_INT_90V_45_CONCAVE_INT_45_FLOOR
                                                                else:
                                                                    return SubtileCorner.INT_45_FLOOR_45_CEILING
                                                        else:
                                                            if proximity.get_is_top_right_corner_clipped_90H_45(-1,0):
                                                                return SubtileCorner.INT_INT_90H_45_CONCAVE
                                                            else:
                                                                return SubtileCorner.INT_45_FLOOR
                                                    else:
                                                        if proximity.get_is_45_neg_ceiling(-2,0):
                                                            if proximity.get_is_bottom_left_corner_clipped_90V_45(-1,0):
                                                                return SubtileCorner.INT_INT_90V_45_CONCAVE
                                                            else:
                                                                return SubtileCorner.INT_45_CEILING
                                                        else:
                                                            return SubtileCorner.FULLY_INTERIOR
    
    # FIXME: LEFT OFF HERE: ---------- Remove after adding all above cases.
    return SubtileCorner.UNKNOWN


func get_target_top_right_corner(proximity: CellProximity) -> int:
    if proximity.is_top_empty:
        if proximity.is_right_empty:
            if proximity.get_is_90_floor():
                if proximity.get_is_90_left_wall():
                    return SubtileCorner.EXT_90_90_CONVEX
                elif proximity.get_is_45_pos_ceiling():
                    return SubtileCorner.EXT_90H_45_CONVEX_ACUTE
                else:
                    # FIXME: LEFT OFF HERE: -------- A27
                    pass
            elif proximity.get_is_90_left_wall():
                if proximity.get_is_45_pos_floor():
                    return SubtileCorner.EXT_90V_45_CONVEX_ACUTE
                else:
                    # FIXME: LEFT OFF HERE: -------- A27
                    pass
            else:
                return SubtileCorner.EMPTY
        else:
            # Top empty, right present.
            if proximity.get_is_90_floor_at_right():
                if proximity.get_is_45_neg_floor(1,0):
                    return SubtileCorner.EXT_90H_45_CONVEX
                else:
                    return SubtileCorner.EXT_90H
            elif proximity.get_is_45_pos_floor():
                return SubtileCorner.EXT_45_FLOOR
            elif proximity.is_angle_type_27:
                # FIXME: LEFT OFF HERE: -------- A27
                pass
            else:
                return SubtileCorner.EXT_90H
    else:
        if proximity.is_right_empty:
            # Top present, right empty.
            if proximity.get_is_90_left_wall_at_top():
                if proximity.get_is_45_neg_floor(0,-1):
                    return SubtileCorner.EXT_90V_45_CONVEX
                else:
                    return SubtileCorner.EXT_90V
            elif proximity.get_is_45_pos_ceiling():
                return SubtileCorner.EXT_45_CEILING
            elif proximity.is_angle_type_27:
                # FIXME: LEFT OFF HERE: -------- A27
                pass
            else:
                return SubtileCorner.EXT_90V
        else:
            # Adjacent sides are present.
            if proximity.is_top_right_empty:
                # Clipped corner.
                if proximity.get_is_90_left_wall_at_bottom(0,-1):
                    if proximity.get_is_90_floor_at_left(1,0):
                        return SubtileCorner.EXT_90_90_CONCAVE
                    elif proximity.get_is_45_neg_floor(1,0):
                        return SubtileCorner.EXT_90V_45_CONCAVE
                    elif proximity.get_angle_type(1,0) == CellAngleType.A27:
                        # FIXME: LEFT OFF HERE: -------- A27
                        pass
                    else:
                        _log_error(
                                "get_target_top_right_corner, " + \
                                "Clipped corner",
                                proximity)
                elif proximity.get_is_45_neg_floor(0,-1):
                    if proximity.get_is_90_floor_at_left(1,0):
                        return SubtileCorner.EXT_90H_45_CONCAVE
                    elif proximity.get_is_45_neg_floor(1,0):
                        return SubtileCorner.EXT_EXT_45_CLIPPED
                    elif proximity.get_angle_type(1,0) == CellAngleType.A27:
                        # FIXME: LEFT OFF HERE: -------- A27
                        pass
                    else:
                        _log_error(
                                "get_target_top_right_corner, " + \
                                "Clipped corner",
                                proximity)
                elif proximity.get_angle_type(0,-1) == CellAngleType.A27:
                    # FIXME: LEFT OFF HERE: -------- A27
                    pass
                else:
                    _log_error(
                            "get_target_top_right_corner, " + \
                            "Clipped corner",
                            proximity)
            else:
                # Internal(ish): Adjacent sides and corner are present.
                if proximity.is_bottom_empty:
                    if proximity.is_left_empty:
                        # Opnegite sides are empty.
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
                        if proximity.is_top_left_empty:
                            if proximity.get_is_top_left_corner_clipped_90_90() or \
                                    proximity.get_is_top_left_corner_clipped_90V_45():
                                if proximity.get_is_45_pos_ceiling(1,0):
                                    return SubtileCorner.EXT_INT_90V_45_CONVEX_ACUTE
                                else:
                                    return SubtileCorner.EXT_INT_90_90_CONVEX
                            elif proximity.get_is_top_left_corner_clipped_45_45() or \
                                    proximity.get_is_top_left_corner_clipped_90H_45():
                                if proximity.get_is_45_pos_ceiling(1,0):
                                    return SubtileCorner.EXT_INT_45_FLOOR_45_CEILING
                                else:
                                    return SubtileCorner.EXT_INT_90H_45_CONVEX_ACUTE
                            else:
                                # FIXME: LEFT OFF HERE: -------- A27
                                pass
                        else:
                            if proximity.get_is_45_pos_ceiling(1,0):
                                return SubtileCorner.EXT_INT_90H_45_CONVEX
                            else:
                                return SubtileCorner.EXT_INT_90H
                else:
                    if proximity.is_left_empty:
                        # Adjacent sides and corner and opposite vertical side
                        # are present.
                        if proximity.is_bottom_right_empty:
                            if proximity.get_is_bottom_right_corner_clipped_90_90() or \
                                    proximity.get_is_bottom_right_corner_clipped_90H_45():
                                if proximity.get_is_45_pos_floor(0,-1):
                                    return SubtileCorner.EXT_INT_90H_45_CONVEX_ACUTE
                                else:
                                    return SubtileCorner.EXT_INT_90_90_CONVEX
                            elif proximity.get_is_bottom_right_corner_clipped_45_45() or \
                                    proximity.get_is_bottom_right_corner_clipped_90V_45():
                                if proximity.get_is_45_pos_floor(0,-1):
                                    return SubtileCorner.EXT_INT_45_FLOOR_45_CEILING
                                else:
                                    return SubtileCorner.EXT_INT_90V_45_CONVEX_ACUTE
                            else:
                                # FIXME: LEFT OFF HERE: -------- A27
                                pass
                        else:
                            if proximity.get_is_45_pos_floor(0,-1):
                                return SubtileCorner.EXT_INT_90V_45_CONVEX
                            else:
                                return SubtileCorner.EXT_INT_90V
                    else:
                        # All sides and adjacent corner are present.
                        if proximity.is_top_left_empty:
                            if proximity.is_bottom_right_empty:
                                # Only the horizontal-opposite and vertical-opposite corners are empty.
                                if proximity.get_is_top_left_corner_clipped_90_90() or \
                                        proximity.get_is_top_left_corner_clipped_90V_45():
                                    if proximity.get_is_bottom_right_corner_clipped_90_90() or \
                                            proximity.get_is_bottom_right_corner_clipped_90H_45():
                                        return SubtileCorner.EXT_INT_90_90_CONVEX
                                    elif proximity.get_is_bottom_right_corner_clipped_45_45() or \
                                            proximity.get_is_bottom_right_corner_clipped_90V_45():
                                        return SubtileCorner.EXT_INT_90V_45_CONVEX_ACUTE
                                    else:
                                        # FIXME: LEFT OFF HERE: -------- A27
                                        pass
                                elif proximity.get_is_top_left_corner_clipped_45_45() or \
                                        proximity.get_is_top_left_corner_clipped_90H_45():
                                    if proximity.get_is_bottom_right_corner_clipped_90_90() or \
                                            proximity.get_is_bottom_right_corner_clipped_90H_45():
                                        return SubtileCorner.EXT_INT_90H_45_CONVEX_ACUTE
                                    elif proximity.get_is_bottom_right_corner_clipped_45_45() or \
                                            proximity.get_is_bottom_right_corner_clipped_90V_45():
                                        return SubtileCorner.EXT_INT_45_FLOOR_45_CEILING
                                    else:
                                        # FIXME: LEFT OFF HERE: -------- A27
                                        pass
                                else:
                                    # FIXME: LEFT OFF HERE: -------- A27
                                    pass
                            else:
                                # Only the horizontal-opposite corner is empty.
                                if proximity.get_is_top_left_corner_clipped_90_90():
                                    return SubtileCorner.EXT_INT_90V
                                elif proximity.get_is_top_left_corner_clipped_45_45() or \
                                        proximity.get_is_top_left_corner_clipped_90H_45():
                                    if proximity.get_is_90_left_wall(1,0):
                                        return SubtileCorner.INT_90V_EXT_INT_45_CONVEX_ACUTE
                                    else:
                                        return SubtileCorner.EXT_INT_45_FLOOR
                                elif proximity.get_is_top_left_corner_clipped_90V_45():
                                    if proximity.get_is_90_left_wall(1,0):
                                        return SubtileCorner.INT_90V_EXT_INT_90V_45_CONCAVE
                                    else:
                                        return SubtileCorner.EXT_INT_90V_45_CONCAVE
                                else:
                                    # FIXME: LEFT OFF HERE: -------- A27
                                    pass
                        else:
                            if proximity.is_bottom_right_empty:
                                # Only the vertical-opposite corner is empty.
                                if proximity.get_is_bottom_right_corner_clipped_90_90():
                                    return SubtileCorner.EXT_INT_90H
                                elif proximity.get_is_bottom_right_corner_clipped_45_45() or \
                                        proximity.get_is_bottom_right_corner_clipped_90V_45():
                                    if proximity.get_is_90_floor(0,-1):
                                        return SubtileCorner.INT_90H_EXT_INT_45_CONVEX_ACUTE
                                    else:
                                        return SubtileCorner.EXT_INT_45_CEILING
                                elif proximity.get_is_bottom_right_corner_clipped_90H_45():
                                    if proximity.get_is_90_floor(0,-1):
                                        return SubtileCorner.INT_90H_EXT_INT_90H_45_CONCAVE
                                    else:
                                        return SubtileCorner.EXT_INT_90H_45_CONCAVE
                                else:
                                    # FIXME: LEFT OFF HERE: -------- A27
                                    pass
                            else:
                                if proximity.is_bottom_left_empty:
                                    # Only the opposite corner is empty.
                                    if proximity.get_is_bottom_left_corner_clipped_90_90():
                                        return SubtileCorner.EXT_INT_90_90_CONCAVE
                                    elif proximity.get_is_45_neg_floor(1,-1):
                                        if proximity.get_is_90_floor(0,-1):
                                            if proximity.get_is_90_left_wall(1,0):
                                                return SubtileCorner.INT_90_90_CONVEX_INT_EXT_45_CLIPPED
                                            else:
                                                return SubtileCorner.INT_90H_INT_EXT_45_CLIPPED
                                        else:
                                            if proximity.get_is_90_left_wall(1,0):
                                                return SubtileCorner.INT_90V_INT_EXT_45_CLIPPED
                                            else:
                                                return SubtileCorner.INT_EXT_45_CLIPPED
                                    elif proximity.get_is_90_floor(0,-1):
                                        if proximity.get_is_90_left_wall(1,0):
                                            # This is an interior floor and interior left-wall.
                                            return SubtileCorner.INT_90_90_CONVEX
                                        else:
                                            # This is an interior floor.
                                            return SubtileCorner.INT_90H
                                    else:
                                        # All neighbors are present, except for the opposite corner.
                                        if proximity.get_is_90_left_wall(1,0):
                                            # This is an interior left-wall.
                                            return SubtileCorner.INT_90V
                                        else:
                                            if proximity.get_is_top_right_corner_clipped_90_90(1,-1):
                                                # This is an interior 90-90 concave corner.
                                                return SubtileCorner.INT_90_90_CONCAVE
                                            else:
                                                # This is a deeply-interior corner.
                                                if proximity.get_is_bottom_left_corner_clipped_90_90():
                                                    return SubtileCorner.EXT_INT_90_90_CONCAVE
                                                elif proximity.get_is_bottom_left_corner_clipped_45_45():
                                                    return SubtileCorner.INT_INT_45_CLIPPED
                                                elif proximity.get_is_bottom_left_corner_clipped_90H_45():
                                                    return SubtileCorner.INT_EXT_90H_45_CONCAVE
                                                elif proximity.get_is_bottom_left_corner_clipped_90V_45():
                                                    return SubtileCorner.INT_EXT_90V_45_CONCAVE
                                                else:
                                                    # FIXME: LEFT OFF HERE: -------- A27
                                                    pass
                                else:
                                    # Fully internal: All sides and corners are present.
                                    
                                    # FIXME: LEFT OFF HERE: -------- A27
                                    
                                    if proximity.get_is_90_floor(0,-1) or \
                                            proximity.get_is_90_floor(1,-1):
                                        if proximity.get_is_90_left_wall(1,0) or \
                                                proximity.get_is_90_left_wall(1,-1):
                                            if proximity.get_is_45_neg_floor(1,-1):
                                                return SubtileCorner.INT_90_90_CONVEX_INT_EXT_45_CLIPPED
                                            else:
                                                return SubtileCorner.INT_90_90_CONVEX
                                        else:
                                            if proximity.get_is_45_neg_floor(1,-1):
                                                return SubtileCorner.INT_90H_INT_EXT_45_CLIPPED
                                            elif proximity.get_is_bottom_right_corner_clipped_90V_45(1,0):
                                                return SubtileCorner.INT_90H_INT_INT_90V_45_CONCAVE
                                            else:
                                                return SubtileCorner.INT_90H
                                    else:
                                        if proximity.get_is_90_left_wall(1,0) or \
                                                proximity.get_is_90_left_wall(1,-1):
                                            if proximity.get_is_45_neg_floor(1,-1):
                                                return SubtileCorner.INT_90V_INT_EXT_45_CLIPPED
                                            elif proximity.get_is_top_left_corner_clipped_90H_45(0,-1):
                                                return SubtileCorner.INT_90V_INT_INT_90H_45_CONCAVE
                                            else:
                                                return SubtileCorner.INT_90V
                                        else:
                                            if proximity.get_is_45_neg_floor(1,-1):
                                                return SubtileCorner.INT_EXT_45_CLIPPED
                                            else:
                                                if proximity.get_is_top_right_corner_clipped_90_90(1,-1):
                                                    if proximity.get_is_45_pos_floor(0,-2):
                                                        if proximity.get_is_45_pos_ceiling(2,0):
                                                            return SubtileCorner.INT_90_90_CONCAVE_INT_45_FLOOR_45_CEILING
                                                        else:
                                                            if proximity.get_is_bottom_right_corner_clipped_90V_45(1,0):
                                                                return SubtileCorner.INT_90_90_CONCAVE_INT_INT_90V_45_CONCAVE_INT_45_FLOOR
                                                            else:
                                                                return SubtileCorner.INT_90_90_CONCAVE_INT_45_FLOOR
                                                    else:
                                                        if proximity.get_is_45_pos_ceiling(2,0):
                                                            if proximity.get_is_top_left_corner_clipped_90H_45(0,-1):
                                                                return SubtileCorner.INT_90_90_CONCAVE_INT_INT_90H_45_CONCAVE_INT_45_CEILING
                                                            else:
                                                                return SubtileCorner.INT_90_90_CONCAVE_INT_45_CEILING
                                                        else:
                                                            if proximity.get_is_top_left_corner_clipped_90H_45(0,-1):
                                                                if proximity.get_is_bottom_right_corner_clipped_90V_45(1,0):
                                                                    return SubtileCorner.INT_90_90_CONCAVE_INT_INT_90H_45_CONCAVE_90V_45_CONCAVE
                                                                else:
                                                                    return SubtileCorner.INT_90_90_CONCAVE_INT_INT_90H_45_CONCAVE
                                                            else:
                                                                if proximity.get_is_bottom_right_corner_clipped_90V_45(1,0):
                                                                    return SubtileCorner.INT_90_90_CONCAVE_INT_INT_90V_45_CONCAVE
                                                                else:
                                                                    return SubtileCorner.INT_90_90_CONCAVE
                                                else:
                                                    # All indirect neighbors in the directions of this corner are present.
                                                    if proximity.get_is_45_pos_floor(0,-2):
                                                        if proximity.get_is_45_pos_ceiling(2,0):
                                                            if proximity.get_is_top_left_corner_clipped_90H_45(0,-1):
                                                                if proximity.get_is_bottom_right_corner_clipped_90V_45(1,0):
                                                                    return SubtileCorner.INT_INT_90H_45_CONCAVE_90V_45_CONCAVE
                                                                else:
                                                                    return SubtileCorner.INT_INT_90H_45_CONCAVE_INT_45_CEILING
                                                            else:
                                                                if proximity.get_is_bottom_right_corner_clipped_90V_45(1,0):
                                                                    return SubtileCorner.INT_INT_90V_45_CONCAVE_INT_45_FLOOR
                                                                else:
                                                                    return SubtileCorner.INT_45_FLOOR_45_CEILING
                                                        else:
                                                            if proximity.get_is_top_left_corner_clipped_90H_45(1,0):
                                                                return SubtileCorner.INT_INT_90H_45_CONCAVE
                                                            else:
                                                                return SubtileCorner.INT_45_FLOOR
                                                    else:
                                                        if proximity.get_is_45_pos_ceiling(2,0):
                                                            if proximity.get_is_bottom_right_corner_clipped_90V_45(1,0):
                                                                return SubtileCorner.INT_INT_90V_45_CONCAVE
                                                            else:
                                                                return SubtileCorner.INT_45_CEILING
                                                        else:
                                                            return SubtileCorner.FULLY_INTERIOR
    
    # FIXME: LEFT OFF HERE: ---------- Remove after adding all above cases.
    return SubtileCorner.UNKNOWN


func get_target_bottom_left_corner(proximity: CellProximity) -> int:
    if proximity.is_bottom_empty:
        if proximity.is_left_empty:
            if proximity.get_is_90_ceiling():
                if proximity.get_is_90_right_wall():
                    return SubtileCorner.EXT_90_90_CONVEX
                elif proximity.get_is_45_pos_floor():
                    return SubtileCorner.EXT_90H_45_CONVEX_ACUTE
                else:
                    # FIXME: LEFT OFF HERE: -------- A27
                    pass
            elif proximity.get_is_90_right_wall():
                if proximity.get_is_45_pos_ceiling():
                    return SubtileCorner.EXT_90V_45_CONVEX_ACUTE
                else:
                    # FIXME: LEFT OFF HERE: -------- A27
                    pass
            else:
                return SubtileCorner.EMPTY
        else:
            # Top empty, left present.
            if proximity.get_is_90_ceiling_at_left():
                if proximity.get_is_45_neg_ceiling(-1,0):
                    return SubtileCorner.EXT_90H_45_CONVEX
                else:
                    return SubtileCorner.EXT_90H
            elif proximity.get_is_45_pos_ceiling():
                return SubtileCorner.EXT_45_CEILING
            elif proximity.is_angle_type_27:
                # FIXME: LEFT OFF HERE: -------- A27
                pass
            else:
                return SubtileCorner.EXT_90H
    else:
        if proximity.is_left_empty:
            # Top present, left empty.
            if proximity.get_is_90_right_wall_at_bottom():
                if proximity.get_is_45_neg_ceiling(0,1):
                    return SubtileCorner.EXT_90V_45_CONVEX
                else:
                    return SubtileCorner.EXT_90V
            elif proximity.get_is_45_pos_floor():
                return SubtileCorner.EXT_45_FLOOR
            elif proximity.is_angle_type_27:
                # FIXME: LEFT OFF HERE: -------- A27
                pass
            else:
                return SubtileCorner.EXT_90V
        else:
            # Adjacent sides are present.
            if proximity.is_bottom_left_empty:
                # Clipped corner.
                if proximity.get_is_90_right_wall_at_top(0,1):
                    if proximity.get_is_90_ceiling_at_right(-1,0):
                        return SubtileCorner.EXT_90_90_CONCAVE
                    elif proximity.get_is_45_neg_ceiling(-1,0):
                        return SubtileCorner.EXT_90V_45_CONCAVE
                    elif proximity.get_angle_type(-1,0) == CellAngleType.A27:
                        # FIXME: LEFT OFF HERE: -------- A27
                        pass
                    else:
                        _log_error(
                                "get_target_bottom_left_corner, " + \
                                "Clipped corner",
                                proximity)
                elif proximity.get_is_45_neg_ceiling(0,1):
                    if proximity.get_is_90_ceiling_at_right(-1,0):
                        return SubtileCorner.EXT_90H_45_CONCAVE
                    elif proximity.get_is_45_neg_ceiling(-1,0):
                        return SubtileCorner.EXT_EXT_45_CLIPPED
                    elif proximity.get_angle_type(-1,0) == CellAngleType.A27:
                        # FIXME: LEFT OFF HERE: -------- A27
                        pass
                    else:
                        _log_error(
                                "get_target_bottom_left_corner, " + \
                                "Clipped corner",
                                proximity)
                elif proximity.get_angle_type(0,1) == CellAngleType.A27:
                    # FIXME: LEFT OFF HERE: -------- A27
                    pass
                else:
                    _log_error(
                            "get_target_bottom_left_corner, " + \
                            "Clipped corner",
                            proximity)
            else:
                # Internal(ish): Adjacent sides and corner are present.
                if proximity.is_top_empty:
                    if proximity.is_right_empty:
                        # Opnegite sides are empty.
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
                        if proximity.is_bottom_right_empty:
                            if proximity.get_is_bottom_right_corner_clipped_90_90() or \
                                    proximity.get_is_bottom_right_corner_clipped_90V_45():
                                if proximity.get_is_45_pos_floor(-1,0):
                                    return SubtileCorner.EXT_INT_90V_45_CONVEX_ACUTE
                                else:
                                    return SubtileCorner.EXT_INT_90_90_CONVEX
                            elif proximity.get_is_bottom_right_corner_clipped_45_45() or \
                                    proximity.get_is_bottom_right_corner_clipped_90H_45():
                                if proximity.get_is_45_pos_floor(-1,0):
                                    return SubtileCorner.EXT_INT_45_CEILING_45_FLOOR
                                else:
                                    return SubtileCorner.EXT_INT_90H_45_CONVEX_ACUTE
                            else:
                                # FIXME: LEFT OFF HERE: -------- A27
                                pass
                        else:
                            if proximity.get_is_45_pos_floor(-1,0):
                                return SubtileCorner.EXT_INT_90H_45_CONVEX
                            else:
                                return SubtileCorner.EXT_INT_90H
                else:
                    if proximity.is_right_empty:
                        # Adjacent sides and corner and opposite vertical side
                        # are present.
                        if proximity.is_top_left_empty:
                            if proximity.get_is_top_left_corner_clipped_90_90() or \
                                    proximity.get_is_top_left_corner_clipped_90H_45():
                                if proximity.get_is_45_pos_ceiling(0,1):
                                    return SubtileCorner.EXT_INT_90H_45_CONVEX_ACUTE
                                else:
                                    return SubtileCorner.EXT_INT_90_90_CONVEX
                            elif proximity.get_is_top_left_corner_clipped_45_45() or \
                                    proximity.get_is_top_left_corner_clipped_90V_45():
                                if proximity.get_is_45_pos_ceiling(0,1):
                                    return SubtileCorner.EXT_INT_45_CEILING_45_FLOOR
                                else:
                                    return SubtileCorner.EXT_INT_90V_45_CONVEX_ACUTE
                            else:
                                # FIXME: LEFT OFF HERE: -------- A27
                                pass
                        else:
                            if proximity.get_is_45_pos_ceiling(0,1):
                                return SubtileCorner.EXT_INT_90V_45_CONVEX
                            else:
                                return SubtileCorner.EXT_INT_90V
                    else:
                        # All sides and adjacent corner are present.
                        if proximity.is_bottom_right_empty:
                            if proximity.is_top_left_empty:
                                # Only the horizontal-opposite and vertical-opposite corners are empty.
                                if proximity.get_is_bottom_right_corner_clipped_90_90() or \
                                        proximity.get_is_bottom_right_corner_clipped_90V_45():
                                    if proximity.get_is_top_left_corner_clipped_90_90() or \
                                            proximity.get_is_top_left_corner_clipped_90H_45():
                                        return SubtileCorner.EXT_INT_90_90_CONVEX
                                    elif proximity.get_is_top_left_corner_clipped_45_45() or \
                                            proximity.get_is_top_left_corner_clipped_90V_45():
                                        return SubtileCorner.EXT_INT_90V_45_CONVEX_ACUTE
                                    else:
                                        # FIXME: LEFT OFF HERE: -------- A27
                                        pass
                                elif proximity.get_is_bottom_right_corner_clipped_45_45() or \
                                        proximity.get_is_bottom_right_corner_clipped_90H_45():
                                    if proximity.get_is_top_left_corner_clipped_90_90() or \
                                            proximity.get_is_top_left_corner_clipped_90H_45():
                                        return SubtileCorner.EXT_INT_90H_45_CONVEX_ACUTE
                                    elif proximity.get_is_top_left_corner_clipped_45_45() or \
                                            proximity.get_is_top_left_corner_clipped_90V_45():
                                        return SubtileCorner.EXT_INT_45_CEILING_45_FLOOR
                                    else:
                                        # FIXME: LEFT OFF HERE: -------- A27
                                        pass
                                else:
                                    # FIXME: LEFT OFF HERE: -------- A27
                                    pass
                            else:
                                # Only the horizontal-opposite corner is empty.
                                if proximity.get_is_bottom_right_corner_clipped_90_90():
                                    return SubtileCorner.EXT_INT_90V
                                elif proximity.get_is_bottom_right_corner_clipped_45_45() or \
                                        proximity.get_is_bottom_right_corner_clipped_90H_45():
                                    if proximity.get_is_90_right_wall(-1,0):
                                        return SubtileCorner.INT_90V_EXT_INT_45_CONVEX_ACUTE
                                    else:
                                        return SubtileCorner.EXT_INT_45_CEILING
                                elif proximity.get_is_bottom_right_corner_clipped_90V_45():
                                    if proximity.get_is_90_right_wall(-1,0):
                                        return SubtileCorner.INT_90V_EXT_INT_90V_45_CONCAVE
                                    else:
                                        return SubtileCorner.EXT_INT_90V_45_CONCAVE
                                else:
                                    # FIXME: LEFT OFF HERE: -------- A27
                                    pass
                        else:
                            if proximity.is_top_left_empty:
                                # Only the vertical-opposite corner is empty.
                                if proximity.get_is_top_left_corner_clipped_90_90():
                                    return SubtileCorner.EXT_INT_90H
                                elif proximity.get_is_top_left_corner_clipped_45_45() or \
                                        proximity.get_is_top_left_corner_clipped_90V_45():
                                    if proximity.get_is_90_ceiling(0,1):
                                        return SubtileCorner.INT_90H_EXT_INT_45_CONVEX_ACUTE
                                    else:
                                        return SubtileCorner.EXT_INT_45_FLOOR
                                elif proximity.get_is_top_left_corner_clipped_90H_45():
                                    if proximity.get_is_90_ceiling(0,1):
                                        return SubtileCorner.INT_90H_EXT_INT_90H_45_CONCAVE
                                    else:
                                        return SubtileCorner.EXT_INT_90H_45_CONCAVE
                                else:
                                    # FIXME: LEFT OFF HERE: -------- A27
                                    pass
                            else:
                                if proximity.is_top_right_empty:
                                    # Only the opposite corner is empty.
                                    if proximity.get_is_top_right_corner_clipped_90_90():
                                        return SubtileCorner.EXT_INT_90_90_CONCAVE
                                    elif proximity.get_is_45_neg_ceiling(-1,1):
                                        if proximity.get_is_90_ceiling(0,1):
                                            if proximity.get_is_90_right_wall(-1,0):
                                                return SubtileCorner.INT_90_90_CONVEX_INT_EXT_45_CLIPPED
                                            else:
                                                return SubtileCorner.INT_90H_INT_EXT_45_CLIPPED
                                        else:
                                            if proximity.get_is_90_right_wall(-1,0):
                                                return SubtileCorner.INT_90V_INT_EXT_45_CLIPPED
                                            else:
                                                return SubtileCorner.INT_EXT_45_CLIPPED
                                    elif proximity.get_is_90_ceiling(0,1):
                                        if proximity.get_is_90_right_wall(-1,0):
                                            # This is an interior ceiling and interior right-wall.
                                            return SubtileCorner.INT_90_90_CONVEX
                                        else:
                                            # This is an interior ceiling.
                                            return SubtileCorner.INT_90H
                                    else:
                                        # All neighbors are present, except for the opposite corner.
                                        if proximity.get_is_90_right_wall(-1,0):
                                            # This is an interior right-wall.
                                            return SubtileCorner.INT_90V
                                        else:
                                            if proximity.get_is_bottom_left_corner_clipped_90_90(-1,1):
                                                # This is an interior 90-90 concave corner.
                                                return SubtileCorner.INT_90_90_CONCAVE
                                            else:
                                                # This is a deeply-interior corner.
                                                if proximity.get_is_top_right_corner_clipped_90_90():
                                                    return SubtileCorner.EXT_INT_90_90_CONCAVE
                                                elif proximity.get_is_top_right_corner_clipped_45_45():
                                                    return SubtileCorner.INT_INT_45_CLIPPED
                                                elif proximity.get_is_top_right_corner_clipped_90H_45():
                                                    return SubtileCorner.INT_EXT_90H_45_CONCAVE
                                                elif proximity.get_is_top_right_corner_clipped_90V_45():
                                                    return SubtileCorner.INT_EXT_90V_45_CONCAVE
                                                else:
                                                    # FIXME: LEFT OFF HERE: -------- A27
                                                    pass
                                else:
                                    # Fully internal: All sides and corners are present.
                                    
                                    # FIXME: LEFT OFF HERE: -------- A27
                                    
                                    if proximity.get_is_90_ceiling(0,1) or \
                                            proximity.get_is_90_ceiling(-1,1):
                                        if proximity.get_is_90_right_wall(-1,0) or \
                                                proximity.get_is_90_right_wall(-1,1):
                                            if proximity.get_is_45_neg_ceiling(-1,1):
                                                return SubtileCorner.INT_90_90_CONVEX_INT_EXT_45_CLIPPED
                                            else:
                                                return SubtileCorner.INT_90_90_CONVEX
                                        else:
                                            if proximity.get_is_45_neg_ceiling(-1,1):
                                                return SubtileCorner.INT_90H_INT_EXT_45_CLIPPED
                                            elif proximity.get_is_top_left_corner_clipped_90V_45(-1,0):
                                                return SubtileCorner.INT_90H_INT_INT_90V_45_CONCAVE
                                            else:
                                                return SubtileCorner.INT_90H
                                    else:
                                        if proximity.get_is_90_right_wall(-1,0) or \
                                                proximity.get_is_90_right_wall(-1,1):
                                            if proximity.get_is_45_neg_ceiling(-1,1):
                                                return SubtileCorner.INT_90V_INT_EXT_45_CLIPPED
                                            elif proximity.get_is_bottom_right_corner_clipped_90H_45(0,1):
                                                return SubtileCorner.INT_90V_INT_INT_90H_45_CONCAVE
                                            else:
                                                return SubtileCorner.INT_90V
                                        else:
                                            if proximity.get_is_45_neg_ceiling(-1,1):
                                                return SubtileCorner.INT_EXT_45_CLIPPED
                                            else:
                                                if proximity.get_is_bottom_left_corner_clipped_90_90(-1,1):
                                                    if proximity.get_is_45_pos_ceiling(0,2):
                                                        if proximity.get_is_45_pos_floor(-2,0):
                                                            return SubtileCorner.INT_90_90_CONCAVE_INT_45_CEILING_45_FLOOR
                                                        else:
                                                            if proximity.get_is_top_left_corner_clipped_90V_45(-1,0):
                                                                return SubtileCorner.INT_90_90_CONCAVE_INT_INT_90V_45_CONCAVE_INT_45_CEILING
                                                            else:
                                                                return SubtileCorner.INT_90_90_CONCAVE_INT_45_CEILING
                                                    else:
                                                        if proximity.get_is_45_pos_floor(-2,0):
                                                            if proximity.get_is_bottom_right_corner_clipped_90H_45(0,1):
                                                                return SubtileCorner.INT_90_90_CONCAVE_INT_INT_90H_45_CONCAVE_INT_45_FLOOR
                                                            else:
                                                                return SubtileCorner.INT_90_90_CONCAVE_INT_45_FLOOR
                                                        else:
                                                            if proximity.get_is_bottom_right_corner_clipped_90H_45(0,1):
                                                                if proximity.get_is_top_left_corner_clipped_90V_45(-1,0):
                                                                    return SubtileCorner.INT_90_90_CONCAVE_INT_INT_90H_45_CONCAVE_90V_45_CONCAVE
                                                                else:
                                                                    return SubtileCorner.INT_90_90_CONCAVE_INT_INT_90H_45_CONCAVE
                                                            else:
                                                                if proximity.get_is_top_left_corner_clipped_90V_45(-1,0):
                                                                    return SubtileCorner.INT_90_90_CONCAVE_INT_INT_90V_45_CONCAVE
                                                                else:
                                                                    return SubtileCorner.INT_90_90_CONCAVE
                                                else:
                                                    # All indirect neighbors in the directions of this corner are present.
                                                    if proximity.get_is_45_pos_ceiling(0,2):
                                                        if proximity.get_is_45_pos_floor(-2,0):
                                                            if proximity.get_is_bottom_right_corner_clipped_90H_45(0,1):
                                                                if proximity.get_is_top_left_corner_clipped_90V_45(-1,0):
                                                                    return SubtileCorner.INT_INT_90H_45_CONCAVE_90V_45_CONCAVE
                                                                else:
                                                                    return SubtileCorner.INT_INT_90H_45_CONCAVE_INT_45_FLOOR
                                                            else:
                                                                if proximity.get_is_top_left_corner_clipped_90V_45(-1,0):
                                                                    return SubtileCorner.INT_INT_90V_45_CONCAVE_INT_45_CEILING
                                                                else:
                                                                    return SubtileCorner.INT_45_CEILING_45_FLOOR
                                                        else:
                                                            if proximity.get_is_bottom_right_corner_clipped_90H_45(-1,0):
                                                                return SubtileCorner.INT_INT_90H_45_CONCAVE
                                                            else:
                                                                return SubtileCorner.INT_45_CEILING
                                                    else:
                                                        if proximity.get_is_45_pos_floor(-2,0):
                                                            if proximity.get_is_top_left_corner_clipped_90V_45(-1,0):
                                                                return SubtileCorner.INT_INT_90V_45_CONCAVE
                                                            else:
                                                                return SubtileCorner.INT_45_FLOOR
                                                        else:
                                                            return SubtileCorner.FULLY_INTERIOR
    
    # FIXME: LEFT OFF HERE: ---------- Remove after adding all above cases.
    return SubtileCorner.UNKNOWN


func get_target_bottom_right_corner(proximity: CellProximity) -> int:
    if proximity.is_bottom_empty:
        if proximity.is_right_empty:
            if proximity.get_is_90_ceiling():
                if proximity.get_is_90_left_wall():
                    return SubtileCorner.EXT_90_90_CONVEX
                elif proximity.get_is_45_neg_floor():
                    return SubtileCorner.EXT_90H_45_CONVEX_ACUTE
                else:
                    # FIXME: LEFT OFF HERE: -------- A27
                    pass
            elif proximity.get_is_90_left_wall():
                if proximity.get_is_45_neg_ceiling():
                    return SubtileCorner.EXT_90V_45_CONVEX_ACUTE
                else:
                    # FIXME: LEFT OFF HERE: -------- A27
                    pass
            else:
                return SubtileCorner.EMPTY
        else:
            # Top empty, right present.
            if proximity.get_is_90_ceiling_at_right():
                if proximity.get_is_45_pos_ceiling(1,0):
                    return SubtileCorner.EXT_90H_45_CONVEX
                else:
                    return SubtileCorner.EXT_90H
            elif proximity.get_is_45_neg_ceiling():
                return SubtileCorner.EXT_45_CEILING
            elif proximity.is_angle_type_27:
                # FIXME: LEFT OFF HERE: -------- A27
                pass
            else:
                return SubtileCorner.EXT_90H
    else:
        if proximity.is_right_empty:
            # Top present, right empty.
            if proximity.get_is_90_left_wall_at_bottom():
                if proximity.get_is_45_pos_ceiling(0,1):
                    return SubtileCorner.EXT_90V_45_CONVEX
                else:
                    return SubtileCorner.EXT_90V
            elif proximity.get_is_45_neg_floor():
                return SubtileCorner.EXT_45_FLOOR
            elif proximity.is_angle_type_27:
                # FIXME: LEFT OFF HERE: -------- A27
                pass
            else:
                return SubtileCorner.EXT_90V
        else:
            # Adjacent sides are present.
            if proximity.is_bottom_right_empty:
                # Clipped corner.
                if proximity.get_is_90_left_wall_at_top(0,1):
                    if proximity.get_is_90_ceiling_at_left(1,0):
                        return SubtileCorner.EXT_90_90_CONCAVE
                    elif proximity.get_is_45_pos_ceiling(1,0):
                        return SubtileCorner.EXT_90V_45_CONCAVE
                    elif proximity.get_angle_type(1,0) == CellAngleType.A27:
                        # FIXME: LEFT OFF HERE: -------- A27
                        pass
                    else:
                        _log_error(
                                "get_target_bottom_right_corner, " + \
                                "Clipped corner",
                                proximity)
                elif proximity.get_is_45_pos_ceiling(0,1):
                    if proximity.get_is_90_ceiling_at_left(1,0):
                        return SubtileCorner.EXT_90H_45_CONCAVE
                    elif proximity.get_is_45_pos_ceiling(1,0):
                        return SubtileCorner.EXT_EXT_45_CLIPPED
                    elif proximity.get_angle_type(1,0) == CellAngleType.A27:
                        # FIXME: LEFT OFF HERE: -------- A27
                        pass
                    else:
                        _log_error(
                                "get_target_bottom_right_corner, " + \
                                "Clipped corner",
                                proximity)
                elif proximity.get_angle_type(0,1) == CellAngleType.A27:
                    # FIXME: LEFT OFF HERE: -------- A27
                    pass
                else:
                    _log_error(
                            "get_target_bottom_right_corner, " + \
                            "Clipped corner",
                            proximity)
            else:
                # Internal(ish): Adjacent sides and corner are present.
                if proximity.is_top_empty:
                    if proximity.is_left_empty:
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
                        if proximity.is_bottom_left_empty:
                            if proximity.get_is_bottom_left_corner_clipped_90_90() or \
                                    proximity.get_is_bottom_left_corner_clipped_90V_45():
                                if proximity.get_is_45_neg_floor(1,0):
                                    return SubtileCorner.EXT_INT_90V_45_CONVEX_ACUTE
                                else:
                                    return SubtileCorner.EXT_INT_90_90_CONVEX
                            elif proximity.get_is_bottom_left_corner_clipped_45_45() or \
                                    proximity.get_is_bottom_left_corner_clipped_90H_45():
                                if proximity.get_is_45_neg_floor(1,0):
                                    return SubtileCorner.EXT_INT_45_CEILING_45_FLOOR
                                else:
                                    return SubtileCorner.EXT_INT_90H_45_CONVEX_ACUTE
                            else:
                                # FIXME: LEFT OFF HERE: -------- A27
                                pass
                        else:
                            if proximity.get_is_45_neg_floor(1,0):
                                return SubtileCorner.EXT_INT_90H_45_CONVEX
                            else:
                                return SubtileCorner.EXT_INT_90H
                else:
                    if proximity.is_left_empty:
                        # Adjacent sides and corner and opposite vertical side
                        # are present.
                        if proximity.is_top_right_empty:
                            if proximity.get_is_top_right_corner_clipped_90_90() or \
                                    proximity.get_is_top_right_corner_clipped_90H_45():
                                if proximity.get_is_45_neg_ceiling(0,1):
                                    return SubtileCorner.EXT_INT_90H_45_CONVEX_ACUTE
                                else:
                                    return SubtileCorner.EXT_INT_90_90_CONVEX
                            elif proximity.get_is_top_right_corner_clipped_45_45() or \
                                    proximity.get_is_top_right_corner_clipped_90V_45():
                                if proximity.get_is_45_neg_ceiling(0,1):
                                    return SubtileCorner.EXT_INT_45_CEILING_45_FLOOR
                                else:
                                    return SubtileCorner.EXT_INT_90V_45_CONVEX_ACUTE
                            else:
                                # FIXME: LEFT OFF HERE: -------- A27
                                pass
                        else:
                            if proximity.get_is_45_neg_ceiling(0,1):
                                return SubtileCorner.EXT_INT_90V_45_CONVEX
                            else:
                                return SubtileCorner.EXT_INT_90V
                    else:
                        # All sides and adjacent corner are present.
                        if proximity.is_bottom_left_empty:
                            if proximity.is_top_right_empty:
                                # Only the horizontal-opposite and vertical-opposite corners are empty.
                                if proximity.get_is_bottom_left_corner_clipped_90_90() or \
                                        proximity.get_is_bottom_left_corner_clipped_90V_45():
                                    if proximity.get_is_top_right_corner_clipped_90_90() or \
                                            proximity.get_is_top_right_corner_clipped_90H_45():
                                        return SubtileCorner.EXT_INT_90_90_CONVEX
                                    elif proximity.get_is_top_right_corner_clipped_45_45() or \
                                            proximity.get_is_top_right_corner_clipped_90V_45():
                                        return SubtileCorner.EXT_INT_90V_45_CONVEX_ACUTE
                                    else:
                                        # FIXME: LEFT OFF HERE: -------- A27
                                        pass
                                elif proximity.get_is_bottom_left_corner_clipped_45_45() or \
                                        proximity.get_is_bottom_left_corner_clipped_90H_45():
                                    if proximity.get_is_top_right_corner_clipped_90_90() or \
                                            proximity.get_is_top_right_corner_clipped_90H_45():
                                        return SubtileCorner.EXT_INT_90H_45_CONVEX_ACUTE
                                    elif proximity.get_is_top_right_corner_clipped_45_45() or \
                                            proximity.get_is_top_right_corner_clipped_90V_45():
                                        return SubtileCorner.EXT_INT_45_CEILING_45_FLOOR
                                    else:
                                        # FIXME: LEFT OFF HERE: -------- A27
                                        pass
                                else:
                                    # FIXME: LEFT OFF HERE: -------- A27
                                    pass
                            else:
                                # Only the horizontal-opposite corner is empty.
                                if proximity.get_is_bottom_left_corner_clipped_90_90():
                                    return SubtileCorner.EXT_INT_90V
                                elif proximity.get_is_bottom_left_corner_clipped_45_45() or \
                                        proximity.get_is_bottom_left_corner_clipped_90H_45():
                                    if proximity.get_is_90_left_wall(1,0):
                                        return SubtileCorner.INT_90V_EXT_INT_45_CONVEX_ACUTE
                                    else:
                                        return SubtileCorner.EXT_INT_45_CEILING
                                elif proximity.get_is_bottom_left_corner_clipped_90V_45():
                                    if proximity.get_is_90_left_wall(1,0):
                                        return SubtileCorner.INT_90V_EXT_INT_90V_45_CONCAVE
                                    else:
                                        return SubtileCorner.EXT_INT_90V_45_CONCAVE
                                else:
                                    # FIXME: LEFT OFF HERE: -------- A27
                                    pass
                        else:
                            if proximity.is_top_right_empty:
                                # Only the vertical-opposite corner is empty.
                                if proximity.get_is_top_right_corner_clipped_90_90():
                                    return SubtileCorner.EXT_INT_90H
                                elif proximity.get_is_top_right_corner_clipped_45_45() or \
                                        proximity.get_is_top_right_corner_clipped_90V_45():
                                    if proximity.get_is_90_ceiling(0,1):
                                        return SubtileCorner.INT_90H_EXT_INT_45_CONVEX_ACUTE
                                    else:
                                        return SubtileCorner.EXT_INT_45_FLOOR
                                elif proximity.get_is_top_right_corner_clipped_90H_45():
                                    if proximity.get_is_90_ceiling(0,1):
                                        return SubtileCorner.INT_90H_EXT_INT_90H_45_CONCAVE
                                    else:
                                        return SubtileCorner.EXT_INT_90H_45_CONCAVE
                                else:
                                    # FIXME: LEFT OFF HERE: -------- A27
                                    pass
                            else:
                                if proximity.is_top_left_empty:
                                    # Only the opposite corner is empty.
                                    if proximity.get_is_top_left_corner_clipped_90_90():
                                        return SubtileCorner.EXT_INT_90_90_CONCAVE
                                    elif proximity.get_is_45_pos_ceiling(1,1):
                                        if proximity.get_is_90_ceiling(0,1):
                                            if proximity.get_is_90_left_wall(1,0):
                                                return SubtileCorner.INT_90_90_CONVEX_INT_EXT_45_CLIPPED
                                            else:
                                                return SubtileCorner.INT_90H_INT_EXT_45_CLIPPED
                                        else:
                                            if proximity.get_is_90_left_wall(1,0):
                                                return SubtileCorner.INT_90V_INT_EXT_45_CLIPPED
                                            else:
                                                return SubtileCorner.INT_EXT_45_CLIPPED
                                    elif proximity.get_is_90_ceiling(0,1):
                                        if proximity.get_is_90_left_wall(1,0):
                                            # This is an interior ceiling and interior left-wall.
                                            return SubtileCorner.INT_90_90_CONVEX
                                        else:
                                            # This is an interior ceiling.
                                            return SubtileCorner.INT_90H
                                    else:
                                        # All neighbors are present, except for the opposite corner.
                                        if proximity.get_is_90_left_wall(1,0):
                                            # This is an interior left-wall.
                                            return SubtileCorner.INT_90V
                                        else:
                                            if proximity.get_is_bottom_right_corner_clipped_90_90(1,1):
                                                # This is an interior 90-90 concave corner.
                                                return SubtileCorner.INT_90_90_CONCAVE
                                            else:
                                                # This is a deeply-interior corner.
                                                if proximity.get_is_top_left_corner_clipped_90_90():
                                                    return SubtileCorner.EXT_INT_90_90_CONCAVE
                                                elif proximity.get_is_top_left_corner_clipped_45_45():
                                                    return SubtileCorner.INT_INT_45_CLIPPED
                                                elif proximity.get_is_top_left_corner_clipped_90H_45():
                                                    return SubtileCorner.INT_EXT_90H_45_CONCAVE
                                                elif proximity.get_is_top_left_corner_clipped_90V_45():
                                                    return SubtileCorner.INT_EXT_90V_45_CONCAVE
                                                else:
                                                    # FIXME: LEFT OFF HERE: -------- A27
                                                    pass
                                else:
                                    # Fully internal: All sides and corners are present.
                                    
                                    # FIXME: LEFT OFF HERE: -------- A27
                                    
                                    if proximity.get_is_90_ceiling(0,1) or \
                                            proximity.get_is_90_ceiling(1,1):
                                        if proximity.get_is_90_left_wall(1,0) or \
                                                proximity.get_is_90_left_wall(1,1):
                                            if proximity.get_is_45_pos_ceiling(1,1):
                                                return SubtileCorner.INT_90_90_CONVEX_INT_EXT_45_CLIPPED
                                            else:
                                                return SubtileCorner.INT_90_90_CONVEX
                                        else:
                                            if proximity.get_is_45_pos_ceiling(1,1):
                                                return SubtileCorner.INT_90H_INT_EXT_45_CLIPPED
                                            elif proximity.get_is_top_right_corner_clipped_90V_45(1,0):
                                                return SubtileCorner.INT_90H_INT_INT_90V_45_CONCAVE
                                            else:
                                                return SubtileCorner.INT_90H
                                    else:
                                        if proximity.get_is_90_left_wall(1,0) or \
                                                proximity.get_is_90_left_wall(1,1):
                                            if proximity.get_is_45_pos_ceiling(1,1):
                                                return SubtileCorner.INT_90V_INT_EXT_45_CLIPPED
                                            elif proximity.get_is_bottom_left_corner_clipped_90H_45(0,1):
                                                return SubtileCorner.INT_90V_INT_INT_90H_45_CONCAVE
                                            else:
                                                return SubtileCorner.INT_90V
                                        else:
                                            if proximity.get_is_45_pos_ceiling(1,1):
                                                return SubtileCorner.INT_EXT_45_CLIPPED
                                            else:
                                                if proximity.get_is_bottom_right_corner_clipped_90_90(1,1):
                                                    if proximity.get_is_45_neg_ceiling(0,2):
                                                        if proximity.get_is_45_neg_floor(2,0):
                                                            return SubtileCorner.INT_90_90_CONCAVE_INT_45_CEILING_45_FLOOR
                                                        else:
                                                            if proximity.get_is_top_right_corner_clipped_90V_45(1,0):
                                                                return SubtileCorner.INT_90_90_CONCAVE_INT_INT_90V_45_CONCAVE_INT_45_CEILING
                                                            else:
                                                                return SubtileCorner.INT_90_90_CONCAVE_INT_45_CEILING
                                                    else:
                                                        if proximity.get_is_45_neg_floor(2,0):
                                                            if proximity.get_is_bottom_left_corner_clipped_90H_45(0,1):
                                                                return SubtileCorner.INT_90_90_CONCAVE_INT_INT_90H_45_CONCAVE_INT_45_FLOOR
                                                            else:
                                                                return SubtileCorner.INT_90_90_CONCAVE_INT_45_FLOOR
                                                        else:
                                                            if proximity.get_is_bottom_left_corner_clipped_90H_45(0,1):
                                                                if proximity.get_is_top_right_corner_clipped_90V_45(1,0):
                                                                    return SubtileCorner.INT_90_90_CONCAVE_INT_INT_90H_45_CONCAVE_90V_45_CONCAVE
                                                                else:
                                                                    return SubtileCorner.INT_90_90_CONCAVE_INT_INT_90H_45_CONCAVE
                                                            else:
                                                                if proximity.get_is_top_right_corner_clipped_90V_45(1,0):
                                                                    return SubtileCorner.INT_90_90_CONCAVE_INT_INT_90V_45_CONCAVE
                                                                else:
                                                                    return SubtileCorner.INT_90_90_CONCAVE
                                                else:
                                                    # All indirect neighbors in the directions of this corner are present.
                                                    if proximity.get_is_45_neg_ceiling(0,2):
                                                        if proximity.get_is_45_neg_floor(2,0):
                                                            if proximity.get_is_bottom_left_corner_clipped_90H_45(0,1):
                                                                if proximity.get_is_top_right_corner_clipped_90V_45(1,0):
                                                                    return SubtileCorner.INT_INT_90H_45_CONCAVE_90V_45_CONCAVE
                                                                else:
                                                                    return SubtileCorner.INT_INT_90H_45_CONCAVE_INT_45_FLOOR
                                                            else:
                                                                if proximity.get_is_top_right_corner_clipped_90V_45(1,0):
                                                                    return SubtileCorner.INT_INT_90V_45_CONCAVE_INT_45_CEILING
                                                                else:
                                                                    return SubtileCorner.INT_45_CEILING_45_FLOOR
                                                        else:
                                                            if proximity.get_is_bottom_left_corner_clipped_90H_45(1,0):
                                                                return SubtileCorner.INT_INT_90H_45_CONCAVE
                                                            else:
                                                                return SubtileCorner.INT_45_CEILING
                                                    else:
                                                        if proximity.get_is_45_neg_floor(2,0):
                                                            if proximity.get_is_top_right_corner_clipped_90V_45(1,0):
                                                                return SubtileCorner.INT_INT_90V_45_CONCAVE
                                                            else:
                                                                return SubtileCorner.INT_45_FLOOR
                                                        else:
                                                            return SubtileCorner.FULLY_INTERIOR
    
    # FIXME: LEFT OFF HERE: ---------- Remove after adding all above cases.
    return SubtileCorner.UNKNOWN


func _log_error(
        message: String,
        proximity: CellProximity) -> void:
    Sc.logger.error(
            "An error occured trying to find a matching " + \
            "subtile corner type: %s; %s" % [message, proximity])

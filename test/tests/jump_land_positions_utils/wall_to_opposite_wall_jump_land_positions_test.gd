extends JumpLandPositionsUtilsTestBed

func test_walls_face_each_other() -> void:
    var jump_surface := create_surface({ \
        side = SurfaceSide.LEFT_WALL,
        is_top = true,
        is_left = true,
        is_short = true,
    })
    var land_surface := create_surface({ \
        side = SurfaceSide.RIGHT_WALL,
        is_top = true,
        is_left = false,
        is_short = true,
    })
    
    var all_jump_land_positions := \
            JumpLandPositionsUtils.calculate_jump_land_positions_for_surface_pair(
                    movement_params,
                    jump_surface,
                    land_surface)
    
    assert_eq(
            all_jump_land_positions.size(),
            2,
            "should consider two pairs")
    
    assert_eq(
            all_jump_land_positions[0].jump_position.target_point.y,
            -512.0,
            "first pair should use top end of jump surface")
    assert_eq(
            all_jump_land_positions[0].land_position.target_point.y,
            -512.0,
            "first pair should use top end of land surface")
    
    assert_eq(
            all_jump_land_positions[1].jump_position.target_point.y,
            -384.0,
            "second pair should use bottom end of jump surface")
    assert_eq(
            all_jump_land_positions[1].land_position.target_point.y,
            -384.0,
            "second pair should use bottom end of land surface")

func test_walls_face_away_with_no_vertical_overlap() -> void:
    var jump_surface := create_surface({ \
        side = SurfaceSide.RIGHT_WALL,
        is_top = false,
        is_left = true,
        is_short = true,
    })
    var land_surface := create_surface({ \
        side = SurfaceSide.LEFT_WALL,
        is_top = true,
        is_left = false,
        is_short = true,
    })
    
    var all_jump_land_positions := \
            JumpLandPositionsUtils.calculate_jump_land_positions_for_surface_pair(
                    movement_params,
                    jump_surface,
                    land_surface)
    
    assert_eq(
            all_jump_land_positions.size(),
            2,
            "should consider two pairs")
    
    assert_eq(
            all_jump_land_positions[0].jump_position.target_point.y,
            -64.0,
            "first pair should use top end of jump surface")
    assert_between(
            all_jump_land_positions[0].land_position.target_point.y,
            -512.0,
            -512.0 + vertical_offset_for_movement_around_wall_max,
            "first pair should use top end of land surface with slight offset")

    assert_eq(
            all_jump_land_positions[1].jump_position.target_point.y,
            -64.0,
            "second pair should use top end of jump surface")
    assert_eq(
            all_jump_land_positions[1].land_position.target_point.y,
            -384.0,
            "second pair should use bottom end of land surface")

# TODO: Add a test for non-straight walls that face each other and have some interior closest point
#       for a third possible jump-land pair result.

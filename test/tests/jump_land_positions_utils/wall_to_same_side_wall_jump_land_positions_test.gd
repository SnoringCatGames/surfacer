extends JumpLandPositionsUtilsTestBed

func test_jump_surface_in_front_and_higher() -> void:
    var jump_surface := create_surface({ \
        side = SurfaceSide.LEFT_WALL,
        is_top = true,
        is_left = false,
        is_short = true,
    })
    var land_surface := create_surface({ \
        side = SurfaceSide.LEFT_WALL,
        is_top = false,
        is_left = true,
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
    assert_between(
            all_jump_land_positions[0].land_position.target_point.y,
            -64.0,
            64.0,
            "first pair should use displacement on land surface")
    
    assert_eq(
            all_jump_land_positions[1].jump_position.target_point.y,
            -384.0,
            "second pair should use bottom end of jump surface")
    assert_between(
            all_jump_land_positions[1].land_position.target_point.y,
            -64.0,
            64.0,
            "second pair should use displacement on land surface")

func test_jump_surface_behind_and_lower() -> void:
    var jump_surface := create_surface({ \
        side = SurfaceSide.LEFT_WALL,
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
    # Bring the land surface just a little closer, so the jump around underneath pair can work.
    translate_surface(
            land_surface,
            Vector2(-32.0, 0.0))
    
    var all_jump_land_positions := \
            JumpLandPositionsUtils.calculate_jump_land_positions_for_surface_pair(
                    movement_params,
                    jump_surface,
                    land_surface)
    
    assert_eq(
            all_jump_land_positions.size(),
            2,
            "should consider two pairs")
    
    assert_between(
            all_jump_land_positions[0].jump_position.target_point.y,
            -64.0,
            64.0,
            "first pair should use displacement on jump surface")
    assert_between(
            all_jump_land_positions[0].land_position.target_point.y,
            -512.0,
            -512.0 + vertical_offset_for_movement_around_wall_max,
            "first pair should use top end of land surface with slight displacement")
    
    assert_between(
            all_jump_land_positions[1].jump_position.target_point.y,
            -64.0,
            64.0,
            "second pair should use displacement on jump surface")
    assert_eq(
            all_jump_land_positions[1].land_position.target_point.y,
            -384.0,
            "second pair should use bottom end of land surface")

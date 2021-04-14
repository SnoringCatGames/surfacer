extends JumpLandPositionsUtilsTestBed

func test_jump_in_front_of_wall_non_overlapping_wall_is_higher() -> void:
    var jump_surface := create_surface({ \
        side = SurfaceSide.FLOOR,
        is_top = false,
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
            JumpLandPositionsUtils.calculate_jump_land_positions_for_surface_pair( \
                    movement_params,
                    jump_surface,
                    land_surface)
    
    assert_eq( \
            all_jump_land_positions.size(),
            1,
            "should consider one pair")
    
    assert_eq( \
            all_jump_land_positions[0].velocity_start.x,
            movement_params.max_horizontal_speed_default,
            "first pair should use max-speed start velocity")
    assert_between( \
            all_jump_land_positions[0].jump_position.target_point.x,
            -192.0 + 0.1,
            -64.0 - 0.1,
            "first pair should use near-end with displacement for floor")
    assert_between( \
            all_jump_land_positions[0].land_position.target_point.y,
            -512.0,
            -384.0,
            "first pair should use close point with displacement offset for wall")

func test_jump_in_front_of_wall_non_overlapping_wall_is_lower() -> void:
    var jump_surface := create_surface({ \
        side = SurfaceSide.FLOOR,
        is_top = true,
        is_left = true,
        is_short = true,
    })
    var land_surface := create_surface({ \
        side = SurfaceSide.RIGHT_WALL,
        is_top = false,
        is_left = false,
        is_short = true,
    })
    
    var all_jump_land_positions := \
            JumpLandPositionsUtils.calculate_jump_land_positions_for_surface_pair( \
                    movement_params,
                    jump_surface,
                    land_surface)
    
    assert_eq( \
            all_jump_land_positions.size(),
            2,
            "should consider two pairs")
    
    assert_eq( \
            all_jump_land_positions[0].velocity_start.x,
            movement_params.max_horizontal_speed_default,
            "first pair should use max-speed start velocity")
    assert_between( \
            all_jump_land_positions[0].jump_position.target_point.x,
            -192.0 + 0.1,
            -64.0 - 0.1,
            "first pair should use near-end with displacement for floor")
    assert_between( \
            all_jump_land_positions[0].land_position.target_point.y,
            -64.0,
            64.0,
            "first pair should use close point with displacement offset for wall")
    
    assert_eq( \
            all_jump_land_positions[1].velocity_start.x,
            -movement_params.max_horizontal_speed_default,
            "second pair should use max-speed start velocity")
    assert_eq( \
            all_jump_land_positions[1].jump_position.target_point.x,
            -192.0,
            "second pair should use far-end for floor")
    assert_between( \
            all_jump_land_positions[1].land_position.target_point.y,
            -64.0,
            64.0,
            "second pair should use close point with displacement offset for wall")

func test_jump_in_front_of_wall_overlapping_wall_is_higher() -> void:
    var jump_surface := create_surface({ \
        side = SurfaceSide.FLOOR,
        is_top = false,
        is_left = true,
        is_short = false,
    })
    var land_surface := create_surface({ \
        side = SurfaceSide.RIGHT_WALL,
        is_top = true,
        is_left = true,
        is_short = true,
    })
    
    var all_jump_land_positions := \
            JumpLandPositionsUtils.calculate_jump_land_positions_for_surface_pair( \
                    movement_params,
                    jump_surface,
                    land_surface)
    
    assert_eq( \
            all_jump_land_positions.size(),
            3,
            "should consider three pairs")
    
    assert_eq( \
            all_jump_land_positions[0].velocity_start.x,
            movement_params.max_horizontal_speed_default,
            "first pair should use max-speed start velocity")
    assert_between( \
            all_jump_land_positions[0].jump_position.target_point.x,
            -640.0,
            -128.0 - 0.1,
            "first pair should use near-end with displacement for floor")
    assert_between( \
            all_jump_land_positions[0].land_position.target_point.y,
            -512.0,
            -384.0,
            "first pair should use close point with displacement offset for wall")
    
    assert_eq( \
            all_jump_land_positions[1].velocity_start.x,
            0.0,
            "second pair should use min-speed start velocity")
    assert_between( \
            all_jump_land_positions[1].jump_position.target_point.x,
            -128.0 - half_width_max_offset,
            -128.0 - half_width_min_offset,
            "second pair should use near-end with displacement for floor")
    assert_between( \
            all_jump_land_positions[1].land_position.target_point.y,
            -512.0,
            -384.0,
            "second pair should use close point with displacement offset for wall")
    
    assert_eq( \
            all_jump_land_positions[2].velocity_start.x,
            movement_params.max_horizontal_speed_default,
            "third pair should use max-speed start velocity")
    assert_between( \
            all_jump_land_positions[2].jump_position.target_point.x,
            -128.0 + half_width_min_offset,
            -64.0 + half_width_max_offset,
            "third pair should use near-end with displacement for floor")
    assert_eq( \
            all_jump_land_positions[2].land_position.target_point.y,
            -512.0,
            "third pair should use top point for wall")

func test_jump_in_front_of_wall_overlapping_wall_is_lower() -> void:
    var jump_surface := create_surface({ \
        side = SurfaceSide.FLOOR,
        is_top = true,
        is_left = true,
        is_short = true,
    })
    var land_surface := create_surface({ \
        side = SurfaceSide.RIGHT_WALL,
        is_top = false,
        is_left = true,
        is_short = true,
    })
    
    var all_jump_land_positions := \
            JumpLandPositionsUtils.calculate_jump_land_positions_for_surface_pair( \
                    movement_params,
                    jump_surface,
                    land_surface)
    
    assert_eq( \
            all_jump_land_positions.size(),
            2,
            "should consider two pairs")
    
    assert_eq( \
            all_jump_land_positions[0].velocity_start.x,
            -movement_params.max_horizontal_speed_default,
            "first pair should use max-speed start velocity")
    assert_eq( \
            all_jump_land_positions[0].jump_position.target_point.x,
            -192.0,
            "first pair should use front-end for floor")
    assert_between( \
            all_jump_land_positions[0].land_position.target_point.y,
            -64.0,
            64.0,
            "first pair should use top point with displacement offset for wall")
    
    assert_eq( \
            all_jump_land_positions[1].velocity_start.x,
            movement_params.max_horizontal_speed_default,
            "second pair should use max-speed start velocity")
    assert_eq( \
            all_jump_land_positions[1].jump_position.target_point.x,
            -64,
            "second pair should use back-end for floor")
    assert_eq( \
            all_jump_land_positions[1].land_position.target_point.y,
            -64.0,
            "second pair should use top point for wall")

func test_jump_behind_wall_wall_is_lower() -> void:
    var jump_surface := create_surface({ \
        side = SurfaceSide.FLOOR,
        is_top = true,
        is_left = false,
        is_short = true,
    })
    var land_surface := create_surface({ \
        side = SurfaceSide.RIGHT_WALL,
        is_top = false,
        is_left = true,
        is_short = true,
    })
    
    var all_jump_land_positions := \
            JumpLandPositionsUtils.calculate_jump_land_positions_for_surface_pair( \
                    movement_params,
                    jump_surface,
                    land_surface)
    
    assert_eq( \
            all_jump_land_positions.size(),
            2,
            "should consider two pairs")
    
    assert_eq( \
            all_jump_land_positions[0].velocity_start.x,
            -movement_params.max_horizontal_speed_default,
            "first pair should use max-speed start velocity")
    assert_eq( \
            all_jump_land_positions[0].jump_position.target_point.x,
            64.0,
            "first pair should use near-end for floor")
    assert_between( \
            all_jump_land_positions[0].land_position.target_point.y,
            -64.0,
            -64.0 + vertical_offset_for_movement_around_wall_max,
            "first pair should use top end with slight offset for wall")
    
    assert_eq( \
            all_jump_land_positions[1].velocity_start.x,
            movement_params.max_horizontal_speed_default,
            "second pair should use max-speed start velocity")
    assert_eq( \
            all_jump_land_positions[1].jump_position.target_point.x,
            192.0,
            "second pair should use far-end for floor")
    assert_between( \
            all_jump_land_positions[1].land_position.target_point.y,
            -64.0,
            -64.0 + vertical_offset_for_movement_around_wall_max,
            "second pair should use top end with slight offset for wall")

func test_jump_behind_wall_wall_is_higher() -> void:
    var jump_surface := create_surface({ \
        side = SurfaceSide.FLOOR,
        is_top = false,
        is_left = false,
        is_short = true,
    })
    var land_surface := create_surface({ \
        side = SurfaceSide.RIGHT_WALL,
        is_top = true,
        is_left = true,
        is_short = true,
    })
    
    var all_jump_land_positions := \
            JumpLandPositionsUtils.calculate_jump_land_positions_for_surface_pair( \
                    movement_params,
                    jump_surface,
                    land_surface)
    
    assert_eq( \
            all_jump_land_positions.size(),
            3,
            "should consider three pairs")
    
    assert_eq( \
            all_jump_land_positions[0].velocity_start.x,
            -movement_params.max_horizontal_speed_default,
            "first pair should use max-speed start velocity")
    assert_between( \
            all_jump_land_positions[0].jump_position.target_point.x,
            64.0,
            192.0,
            "first pair should use close point with displacement for floor")
    assert_between( \
            all_jump_land_positions[0].land_position.target_point.y,
            -512.0,
            -512.0 + vertical_offset_for_movement_around_wall_max,
            "first pair should use top point with slight offset for wall")
    
    assert_eq( \
            all_jump_land_positions[1].velocity_start.x,
            0.0,
            "second pair should use min-speed start velocity")
    assert_eq( \
            all_jump_land_positions[1].jump_position.target_point.x,
            64.0,
            "second pair should use close point for floor")
    assert_between( \
            all_jump_land_positions[1].land_position.target_point.y,
            -512.0,
            -512.0 + vertical_offset_for_movement_around_wall_max,
            "second pair should use top point with slight offset for wall")
    
    assert_eq( \
            all_jump_land_positions[2].velocity_start.x,
            -movement_params.max_horizontal_speed_default,
            "third pair should use max-speed start velocity")
    assert_eq( \
            all_jump_land_positions[2].jump_position.target_point.x,
            64.0,
            "third pair should use near-end for floor")
    assert_eq( \
            all_jump_land_positions[2].land_position.target_point.y,
            -384.0,
            "third pair should use bottom point for wall")

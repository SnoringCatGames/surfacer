extends JumpLandPositionsUtilsTestBed

func test_wall_is_higher_can_jump_in_front_and_behind() -> void:
    var jump_surface := create_surface({ \
        side = SurfaceSide.LEFT_WALL,
        is_top = true,
        is_left = true,
        is_short = true,
    })
    var land_surface := create_surface({ \
        side = SurfaceSide.FLOOR,
        is_top = false,
        is_left = true,
        is_short = false,
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
    
    assert_between(
            all_jump_land_positions[0].jump_position.target_point.y,
            -512.0,
            -348.0,
            "first pair should use vertical displacement for wall")
    assert_between(
            all_jump_land_positions[0].land_position.target_point.x,
            -128.0,
            384.0,
            "first pair should use close point with displacement offset for floor")
    
    assert_eq(
            all_jump_land_positions[1].jump_position.target_point.y,
            -512.0,
            "second pair should use top end for wall")
    assert_between(
            all_jump_land_positions[1].land_position.target_point.x,
            -192.0 - half_width_max_offset,
            -192.0 - half_width_min_offset,
            "second pair should use close point with player width offset for floor")

func test_wall_is_lower_with_no_overlap() -> void:
    var jump_surface := create_surface({ \
        side = SurfaceSide.LEFT_WALL,
        is_top = false,
        is_left = true,
        is_short = true,
    })
    var land_surface := create_surface({ \
        side = SurfaceSide.FLOOR,
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
            1,
            "should consider one pair")
    
    assert_between(
            all_jump_land_positions[0].jump_position.target_point.y,
            -64.0,
            64.0,
            "first pair should use vertical displacement for wall")
    assert_eq(
            all_jump_land_positions[0].land_position.target_point.x,
            64.0,
            "first pair should use near end for floor")

func test_wall_is_lower_with_overlap() -> void:
    var jump_surface := create_surface({ \
        side = SurfaceSide.LEFT_WALL,
        is_top = false,
        is_left = true,
        is_short = true,
    })
    var land_surface := create_surface({ \
        side = SurfaceSide.FLOOR,
        is_top = true,
        is_left = true,
        is_short = false,
    })
    
    var all_jump_land_positions := \
            JumpLandPositionsUtils.calculate_jump_land_positions_for_surface_pair(
                    movement_params,
                    jump_surface,
                    land_surface)
    
    assert_eq(
            all_jump_land_positions.size(),
            1,
            "should consider one pair")
    
    assert_between(
            all_jump_land_positions[0].jump_position.target_point.y,
            -64.0,
            64.0,
            "first pair should use vertical displacement for wall")
    assert_eq(
            all_jump_land_positions[0].land_position.target_point.x,
            384.0,
            "first pair should use front end for floor")

func test_floor_is_in_front_of_wall_with_vertical_overlap() -> void:
    var jump_surface := create_surface({ \
        side = SurfaceSide.LEFT_WALL,
        is_top = true,
        is_left = true,
        is_short = true,
    })
    var land_surface := create_surface({ \
        side = SurfaceSide.FLOOR,
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
            1,
            "should consider one pair")
    
    assert_between(
            all_jump_land_positions[0].jump_position.target_point.y,
            -512.0,
            -348.0,
            "first pair should use vertical displacement for wall")
    assert_between(
            all_jump_land_positions[0].land_position.target_point.x,
            -64.0,
            64.0,
            "first pair should use close point with displacement offset for floor")

func test_floor_is_in_behind_wall_with_vertical_overlap() -> void:
    var jump_surface := create_surface({ \
        side = SurfaceSide.LEFT_WALL,
        is_top = true,
        is_left = false,
        is_short = true,
    })
    var land_surface := create_surface({ \
        side = SurfaceSide.FLOOR,
        is_top = true,
        is_left = true,
        is_short = true,
    })
    
    var all_jump_land_positions := \
            JumpLandPositionsUtils.calculate_jump_land_positions_for_surface_pair(
                    movement_params,
                    jump_surface,
                    land_surface
    
    assert_eq(
            all_jump_land_positions.size(),
            1,
            "should consider one pair")
    
    assert_eq(
            all_jump_land_positions[0].jump_position.target_point.y,
            -512.0,
            "first pair should use top end for wall")
    assert_between(
            all_jump_land_positions[0].land_position.target_point.x,
            -192.0,
            -64.0,
            "first pair should use close point with displacement offset for floor")

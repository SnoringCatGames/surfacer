extends JumpLandPositionsUtilsTestBed

func test_non_overlapping_at_same_level() -> void:
    var jump_surface := create_surface({ \
        side = SurfaceSide.FLOOR, \
        is_top = true, \
        is_left = true, \
        is_short = true, \
    })
    var land_surface := create_surface({ \
        side = SurfaceSide.FLOOR, \
        is_top = true, \
        is_left = false, \
        is_short = true, \
    })
    
    var all_jump_land_positions := \
            JumpLandPositionsUtils.calculate_jump_land_positions_for_surface_pair( \
                    movement_params, \
                    jump_surface, \
                    land_surface, \
                    is_a_jump_calculator)
    
    assert_eq( \
            all_jump_land_positions.size(), \
            2, \
            "should consider two pairs")
    
    assert_eq( \
            all_jump_land_positions[0].velocity_start.x, \
            movement_params.max_horizontal_speed_default, \
            "first pair should use max-speed start velocity")
    assert_almost_ne( \
            all_jump_land_positions[0].land_position.target_point.x, \
            64.0, \
            0.1, \
            "first pair should include horizontal displacement on one of the surfaces")
    assert_eq( \
            all_jump_land_positions[0].jump_position.target_point.x, \
            -64.0, \
            "first pair should not include horizontal displacement on one of the surfaces")
    
    assert_eq( \
            all_jump_land_positions[1].velocity_start.x, \
            0.0, \
            "second pair should use min-speed start velocity")
    assert_eq( \
            all_jump_land_positions[1].jump_position.target_point.x, \
            -64.0, \
            "second pair should use jump surface near end")
    assert_eq( \
            all_jump_land_positions[1].land_position.target_point.x, \
            64.0, \
            "second pair should use land surface near end")

func test_non_overlapping_with_upper_left_jump_surface() -> void:
    var jump_surface := create_surface({ \
        side = SurfaceSide.FLOOR, \
        is_top = true, \
        is_left = true, \
        is_short = true, \
    })
    var land_surface := create_surface({ \
        side = SurfaceSide.FLOOR, \
        is_top = false, \
        is_left = false, \
        is_short = true, \
    })
    
    var all_jump_land_positions := \
            JumpLandPositionsUtils.calculate_jump_land_positions_for_surface_pair( \
                    movement_params, \
                    jump_surface, \
                    land_surface, \
                    is_a_jump_calculator)
    
    assert_eq( \
            all_jump_land_positions.size(), \
            3, \
            "should consider three pairs")
    
    assert_eq( \
            all_jump_land_positions[0].velocity_start.x, \
            movement_params.max_horizontal_speed_default, \
            "first pair should use max-speed start velocity")
    assert_almost_ne( \
            all_jump_land_positions[0].land_position.target_point.x, \
            64.0, \
            0.1, \
            "first pair should include horizontal displacement on the lower surface")
    assert_eq( \
            all_jump_land_positions[0].jump_position.target_point.x, \
            -64.0, \
            "first pair should not include horizontal displacement on the upper surface")
    
    assert_eq( \
            all_jump_land_positions[1].velocity_start.x, \
            0.0, \
            "second pair should use min-speed start velocity")
    assert_eq( \
            all_jump_land_positions[1].jump_position.target_point.x, \
            -64.0, \
            "second pair should use jump surface near end")
    assert_eq( \
            all_jump_land_positions[1].land_position.target_point.x, \
            64.0, \
            "second pair should use land surface near end")
    
    assert_eq( \
            all_jump_land_positions[2].velocity_start.x, \
            -movement_params.max_horizontal_speed_default, \
            "third pair should use max-speed start velocity")
    assert_eq( \
            all_jump_land_positions[2].jump_position.target_point.x, \
            -192.0, \
            "third pair should use jump surface far end")
    assert_eq( \
            all_jump_land_positions[2].land_position.target_point.x, \
            64.0, \
            "third pair should use land surface near end")

func test_non_overlapping_with_lower_left_jump_surface() -> void:
    var jump_surface := create_surface({ \
        side = SurfaceSide.FLOOR, \
        is_top = false, \
        is_left = true, \
        is_short = true, \
    })
    var land_surface := create_surface({ \
        side = SurfaceSide.FLOOR, \
        is_top = true, \
        is_left = false, \
        is_short = true, \
    })
    
    var all_jump_land_positions := \
            JumpLandPositionsUtils.calculate_jump_land_positions_for_surface_pair( \
                    movement_params, \
                    jump_surface, \
                    land_surface, \
                    is_a_jump_calculator)
    
    assert_eq( \
            all_jump_land_positions.size(), \
            3, \
            "should consider three pairs")
    
    assert_eq( \
            all_jump_land_positions[0].velocity_start.x, \
            movement_params.max_horizontal_speed_default, \
            "first pair should use max-speed start velocity")
    assert_eq( \
            all_jump_land_positions[0].jump_position.target_point.x, \
            -192.0, \
            "first pair should include horizontal displacement on the lower surface")
    assert_almost_ne( \
            all_jump_land_positions[0].land_position.target_point.x, \
            64.0, \
            0.1, \
            "first pair should include horizontal displacement on the upper surface")
    
    assert_eq( \
            all_jump_land_positions[1].velocity_start.x, \
            0.0, \
            "second pair should use min-speed start velocity")
    assert_eq( \
            all_jump_land_positions[1].jump_position.target_point.x, \
            -64.0, \
            "second pair should use jump surface near end")
    assert_eq( \
            all_jump_land_positions[1].land_position.target_point.x, \
            64.0, \
            "second pair should use land surface near end")
    
    assert_eq( \
            all_jump_land_positions[2].velocity_start.x, \
            movement_params.max_horizontal_speed_default, \
            "third pair should use max-speed start velocity")
    assert_eq( \
            all_jump_land_positions[2].jump_position.target_point.x, \
            -64.0, \
            "third pair should use jump surface far end")
    assert_eq( \
            all_jump_land_positions[2].land_position.target_point.x, \
            192.0, \
            "third pair should use land surface near end")

func test_non_overlapping_with_upper_right_jump_surface() -> void:
    var jump_surface := create_surface({ \
        side = SurfaceSide.FLOOR, \
        is_top = true, \
        is_left = false, \
        is_short = true, \
    })
    var land_surface := create_surface({ \
        side = SurfaceSide.FLOOR, \
        is_top = false, \
        is_left = true, \
        is_short = true, \
    })
    
    var all_jump_land_positions := \
            JumpLandPositionsUtils.calculate_jump_land_positions_for_surface_pair( \
                    movement_params, \
                    jump_surface, \
                    land_surface, \
                    is_a_jump_calculator)
    
    assert_eq( \
            all_jump_land_positions.size(), \
            3, \
            "should consider three pairs")
    
    assert_eq( \
            all_jump_land_positions[0].velocity_start.x, \
            -movement_params.max_horizontal_speed_default, \
            "first pair should use max-speed start velocity")
    assert_almost_ne( \
            all_jump_land_positions[0].land_position.target_point.x, \
            -64.0, \
            0.1, \
            "first pair should include horizontal displacement on the lower surface")
    assert_eq( \
            all_jump_land_positions[0].jump_position.target_point.x, \
            64.0, \
            "first pair should not include horizontal displacement on the upper surface")
    
    assert_eq( \
            all_jump_land_positions[1].velocity_start.x, \
            0.0, \
            "second pair should use min-speed start velocity")
    assert_eq( \
            all_jump_land_positions[1].jump_position.target_point.x, \
            64.0, \
            "second pair should use jump surface near end")
    assert_eq( \
            all_jump_land_positions[1].land_position.target_point.x, \
            -64.0, \
            "second pair should use land surface near end")
    
    assert_eq( \
            all_jump_land_positions[2].velocity_start.x, \
            movement_params.max_horizontal_speed_default, \
            "third pair should use max-speed start velocity")
    assert_eq( \
            all_jump_land_positions[2].jump_position.target_point.x, \
            192.0, \
            "third pair should use jump surface far end")
    assert_eq( \
            all_jump_land_positions[2].land_position.target_point.x, \
            -64.0, \
            "third pair should use land surface near end")

func test_non_overlapping_with_lower_right_jump_surface() -> void:
    var jump_surface := create_surface({ \
        side = SurfaceSide.FLOOR, \
        is_top = false, \
        is_left = false, \
        is_short = true, \
    })
    var land_surface := create_surface({ \
        side = SurfaceSide.FLOOR, \
        is_top = true, \
        is_left = true, \
        is_short = true, \
    })
    
    var all_jump_land_positions := \
            JumpLandPositionsUtils.calculate_jump_land_positions_for_surface_pair( \
                    movement_params, \
                    jump_surface, \
                    land_surface, \
                    is_a_jump_calculator)
    
    assert_eq( \
            all_jump_land_positions.size(), \
            3, \
            "should consider three pairs")
    
    assert_eq( \
            all_jump_land_positions[0].velocity_start.x, \
            -movement_params.max_horizontal_speed_default, \
            "first pair should use max-speed start velocity")
    assert_eq( \
            all_jump_land_positions[0].jump_position.target_point.x, \
            192.0, \
            "first pair should include horizontal displacement on the lower surface")
    assert_almost_ne( \
            all_jump_land_positions[0].land_position.target_point.x, \
            -64.0, \
            0.1, \
            "first pair should include horizontal displacement on the upper surface")
    
    assert_eq( \
            all_jump_land_positions[1].velocity_start.x, \
            0.0, \
            "second pair should use min-speed start velocity")
    assert_eq( \
            all_jump_land_positions[1].jump_position.target_point.x, \
            64.0, \
            "second pair should use jump surface near end")
    assert_eq( \
            all_jump_land_positions[1].land_position.target_point.x, \
            -64.0, \
            "second pair should use land surface near end")
    
    assert_eq( \
            all_jump_land_positions[2].velocity_start.x, \
            -movement_params.max_horizontal_speed_default, \
            "third pair should use max-speed start velocity")
    assert_eq( \
            all_jump_land_positions[2].jump_position.target_point.x, \
            64.0, \
            "third pair should use jump surface far end")
    assert_eq( \
            all_jump_land_positions[2].land_position.target_point.x, \
            -192.0, \
            "third pair should use land surface near end")

func test_non_overlapping_with_higher_jump_surface_farther_on_both_sides() -> void:
    var jump_surface := create_surface({ \
        side = SurfaceSide.FLOOR, \
        is_top = true, \
        is_left = true, \
        is_short = false, \
    })
    var land_surface := create_surface({ \
        side = SurfaceSide.FLOOR, \
        is_top = false, \
        is_left = true, \
        is_short = true, \
    })
    
    var all_jump_land_positions := \
            JumpLandPositionsUtils.calculate_jump_land_positions_for_surface_pair( \
                    movement_params, \
                    jump_surface, \
                    land_surface, \
                    is_a_jump_calculator)
    
    assert_eq( \
            all_jump_land_positions.size(), \
            2, \
            "should consider two pairs")
    
    assert_eq( \
            all_jump_land_positions[0].velocity_start.x, \
            -movement_params.max_horizontal_speed_default, \
            "first pair should use max-speed start velocity")
    assert_eq( \
            all_jump_land_positions[0].jump_position.target_point.x, \
            -640.0, \
            "first pair should not include horizontal displacement on the upper surface")
    assert_eq( \
            all_jump_land_positions[0].land_position.target_point.x, \
            -192.0, \
            "first pair should not include horizontal displacement on the lower surface")
    
    assert_eq( \
            all_jump_land_positions[1].velocity_start.x, \
            movement_params.max_horizontal_speed_default, \
            "second pair should use max-speed start velocity")
    assert_eq( \
            all_jump_land_positions[1].jump_position.target_point.x, \
            384.0, \
            "second pair should not include horizontal displacement on the upper surface")
    assert_eq( \
            all_jump_land_positions[1].land_position.target_point.x, \
            -64.0, \
            "second pair should not include horizontal displacement on the lower surface")

func test_non_overlapping_with_lower_jump_surface_farther_on_both_sides() -> void:
    var jump_surface := create_surface({ \
        side = SurfaceSide.FLOOR, \
        is_top = false, \
        is_left = true, \
        is_short = false, \
    })
    var land_surface := create_surface({ \
        side = SurfaceSide.FLOOR, \
        is_top = true, \
        is_left = true, \
        is_short = true, \
    })
    
    var all_jump_land_positions := \
            JumpLandPositionsUtils.calculate_jump_land_positions_for_surface_pair( \
                    movement_params, \
                    jump_surface, \
                    land_surface, \
                    is_a_jump_calculator)
    
    assert_eq( \
            all_jump_land_positions.size(), \
            4, \
            "should consider four pairs")
    
    var half_width_min_offset := movement_params.collider_half_width_height.x + 0.01
    var half_width_max_offset := movement_params.collider_half_width_height.x * 2.0
    
    assert_eq( \
            all_jump_land_positions[0].velocity_start.x, \
            movement_params.max_horizontal_speed_default, \
            "first pair should use max-speed start velocity")
    assert_between( \
            all_jump_land_positions[0].jump_position.target_point.x, \
            -640.0, \
            -192.0, \
            "first pair should include horizontal displacement on the lower surface")
    assert_eq( \
            all_jump_land_positions[0].land_position.target_point.x, \
            -192.0, \
            "first pair should not include horizontal displacement on the upper surface")
    
    assert_eq( \
            all_jump_land_positions[1].velocity_start.x, \
            0.0, \
            "second pair should use min-speed start velocity")
    assert_between( \
            all_jump_land_positions[1].jump_position.target_point.x, \
            -192.0 - half_width_max_offset, \
            -192.0 - half_width_min_offset, \
            "second pair should use player half-width displacement on the lower surface")
    assert_eq( \
            all_jump_land_positions[1].land_position.target_point.x, \
            -192.0, \
            "second pair should use upper surface near end")
    
    assert_eq( \
            all_jump_land_positions[2].velocity_start.x, \
            -movement_params.max_horizontal_speed_default, \
            "third pair should use max-speed start velocity")
    assert_between( \
            all_jump_land_positions[2].jump_position.target_point.x, \
            -64.0, \
            384.0, \
            "third pair should include horizontal displacement on the lower surface")
    assert_eq( \
            all_jump_land_positions[2].land_position.target_point.x, \
            -64.0, \
            "third pair should not include horizontal displacement on the upper surface")
    
    assert_eq( \
            all_jump_land_positions[3].velocity_start.x, \
            0.0, \
            "fourth pair should use min-speed start velocity")
    assert_between( \
            all_jump_land_positions[3].jump_position.target_point.x, \
            -64.0 + half_width_min_offset, \
            -64.0 + half_width_max_offset, \
            "fourth pair should use player half-width displacement on the lower surface")
    assert_eq( \
            all_jump_land_positions[3].land_position.target_point.x, \
            -64.0, \
            "fourth pair should use upper surface near end")

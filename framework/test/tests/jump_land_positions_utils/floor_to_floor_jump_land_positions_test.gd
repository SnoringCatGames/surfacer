extends JumpLandPositionsUtilsTestBed

# FIXME: LEFT OFF HERE: -------------------------------------------------A:
# - Add a bunch of very simple test levels, with just two platforms each, and the two in
#   various alignments from each other.
#   - Cover all of the different jump/land surface type/spatial-arrangement combinations that
#     are considered for jump/land position calculations.
# - Correct numbers and combinations of jump-land pair results.

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
            4, \
            "should consider three pairs")
    
    assert_eq( \
            all_jump_land_positions[0].velocity_start.x, \
            0.0, \
            "first pair should use min start velocity")
    assert_almost_eq( \
            all_jump_land_positions[0].jump_surface.target_point.x, \
            -64.0, \
            "first pair should use jump surface near end")
    assert_almost_eq( \
            all_jump_land_positions[0].land_surface.target_point.x, \
            64.0, \
            "first pair should use land surface near end")
    
    assert_almost_ne( \
            all_jump_land_positions[1].velocity_start.x, \
            0.0, \
            "second pair should use max-speed start velocity")
    assert_almost_ne( \
            all_jump_land_positions[1].land_position.target_point.x, \
            land_surface.first_point.x, \
            "second pair should include horizontal displacement on the lower surface")
    assert_eq( \
            all_jump_land_positions[1].jump_position.target_point.x, \
            jump_surface.last_point.x, \
            "second pair should not include horizontal displacement on the higher surface")
    
    assert_almost_ne( \
            all_jump_land_positions[2].velocity_start.x, \
            0.0, \
            "third pair should use max-speed start velocity")
    assert_almost_ne( \
            all_jump_land_positions[2].jump_position.target_point.x, \
            jump_surface.last_point.x, \
            "third pair should include horizontal displacement on the higher surface")
    assert_eq( \
            all_jump_land_positions[2].land_position.target_point.x, \
            land_surface.first_point.x, \
            "third pair should not include horizontal displacement on the lower surface")
    
    # FIXME: -------------- Account for the other case: is_considering_left_end, when we're supposedly trying to go under around behind the jump surface...
    assert_eq(true, false)

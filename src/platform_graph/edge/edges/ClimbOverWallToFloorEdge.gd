# Information for how to climb up and over a wall to stand on the adjacent
# floor.
# 
# The instructions for this edge consist of two consecutive directional-key
# presses (into the wall, and upward), with no corresponding release.
class_name ClimbOverWallToFloorEdge
extends Edge

const TYPE := EdgeType.CLIMB_OVER_WALL_TO_FLOOR_EDGE
const IS_TIME_BASED := false
const SURFACE_TYPE := SurfaceType.WALL
const ENTERS_AIR := true
const INCLUDES_AIR_TRAJECTORY := false

func _init( \
        calculator = null, \
        start: PositionAlongSurface = null, \
        end: PositionAlongSurface = null, \
        movement_params: MovementParams = null) \
        .(TYPE, \
        IS_TIME_BASED, \
        SURFACE_TYPE, \
        ENTERS_AIR, \
        INCLUDES_AIR_TRAJECTORY, \
        calculator, \
        start, \
        end, \
        Vector2.ZERO, \
        Vector2.ZERO, \
        false, \
        false, \
        movement_params, \
        _calculate_instructions(start, end), \
        null, \
        EdgeCalcResultType.EDGE_VALID_WITH_ONE_STEP) -> void:
    pass

func _calculate_distance( \
        start: PositionAlongSurface, \
        end: PositionAlongSurface, \
        trajectory: EdgeTrajectory) -> float:
    return Gs.geometry.calculate_manhattan_distance( \
            start.target_point, \
            end.target_point)

func _calculate_duration( \
        start: PositionAlongSurface, \
        end: PositionAlongSurface, \
        instructions: EdgeInstructions, \
        distance: float) -> float:
    return MovementUtils.calculate_time_to_climb( \
            distance, \
            true, \
            movement_params)

func _check_did_just_reach_destination( \
        navigation_state: PlayerNavigationState, \
        surface_state: PlayerSurfaceState, \
        playback) -> bool:
    return surface_state.just_grabbed_floor

func _get_weight_multiplier() -> float:
    return movement_params.walking_edge_weight_multiplier

static func _calculate_instructions( \
        start: PositionAlongSurface, \
        end: PositionAlongSurface) -> EdgeInstructions:
    assert(start.side == SurfaceSide.LEFT_WALL || \
            start.side == SurfaceSide.RIGHT_WALL)
    assert(end.side == SurfaceSide.FLOOR)
    
    var sideways_input_key := \
            "move_left" if \
            start.side == SurfaceSide.LEFT_WALL else \
            "move_right"
    var inward_instruction := EdgeInstruction.new( \
            sideways_input_key, \
            0.0, \
            true)
    
    var upward_instruction := EdgeInstruction.new( \
            "move_up", \
            0.0, \
            true)
    
    return EdgeInstructions.new( \
            [inward_instruction, upward_instruction], \
            INF)

# This edge needs to override this function, since Godot's collision engine
# generates many false-positive departures and collisions when rounding the
# corner between surfaces. So we need to be more permissible here for what we
# consider to be expected when leaving and entering the air.
func update_navigation_state( \
        navigation_state: PlayerNavigationState, \
        surface_state: PlayerSurfaceState, \
        playback, \
        just_started_new_edge: bool, \
        is_starting_navigation_retry: bool) -> void:
    .update_navigation_state( \
            navigation_state, \
            surface_state, \
            playback, \
            just_started_new_edge, \
            is_starting_navigation_retry)
    if is_starting_navigation_retry:
        # This should never happen.
        Gs.logger.error()
        return
    
    var is_grabbed_surface_expected: bool = \
            surface_state.grabbed_surface == self.start_surface or \
            surface_state.grabbed_surface == self.end_surface
    navigation_state.just_left_air_unexpectedly = \
            surface_state.just_left_air and \
            !is_grabbed_surface_expected and \
            surface_state.collision_count > 0
    
    navigation_state.just_entered_air_unexpectedly = false
    
    navigation_state.just_interrupted_navigation = \
            navigation_state.just_left_air_unexpectedly or \
            navigation_state.just_entered_air_unexpectedly or \
            navigation_state.just_interrupted_by_user_action
    
    navigation_state.just_reached_end_of_edge = \
            _check_did_just_reach_destination( \
                    navigation_state, \
                    surface_state, \
                    playback)

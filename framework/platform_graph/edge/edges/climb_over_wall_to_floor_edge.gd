# Information for how to climb up and over a wall to stand on the adjacent floor.
# 
# The instructions for this edge consist of two consecutive directional-key presses (into the wall,
# and upward), with no corresponding release.
extends Edge
class_name ClimbOverWallToFloorEdge

const TYPE := EdgeType.CLIMB_OVER_WALL_TO_FLOOR_EDGE
const IS_TIME_BASED := false
const SURFACE_TYPE := SurfaceType.WALL
const ENTERS_AIR := true

func _init( \
        calculator, \
        start: PositionAlongSurface, \
        end: PositionAlongSurface, \
        movement_params: MovementParams) \
        .(TYPE, \
        IS_TIME_BASED, \
        SURFACE_TYPE, \
        ENTERS_AIR, \
        calculator, \
        start, \
        end, \
        Vector2.ZERO, \
        Vector2.ZERO, \
        false, \
        false, \
        movement_params, \
        _calculate_instructions(start, end), \
        null) -> void:
    pass

func _calculate_distance( \
        start: PositionAlongSurface, \
        end: PositionAlongSurface, \
        trajectory: MovementTrajectory) -> float:
    return Geometry.calculate_manhattan_distance(start.target_point, end.target_point)

func _calculate_duration( \
        start: PositionAlongSurface, \
        end: PositionAlongSurface, \
        instructions: MovementInstructions, \
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

static func _calculate_instructions( \
        start: PositionAlongSurface, \
        end: PositionAlongSurface) -> MovementInstructions:
    assert(start.surface.side == SurfaceSide.LEFT_WALL || \
            start.surface.side == SurfaceSide.RIGHT_WALL)
    assert(end.surface.side == SurfaceSide.FLOOR)
    
    var sideways_input_key := \
            "move_left" if start.surface.side == SurfaceSide.LEFT_WALL else "move_right"
    var inward_instruction := MovementInstruction.new( \
            sideways_input_key, \
            0.0, \
            true)
    
    var upward_instruction := MovementInstruction.new( \
            "move_up", \
            0.0, \
            true)
    
    return MovementInstructions.new( \
            [inward_instruction, upward_instruction], \
            INF)

# This edge needs to override this function, since Godot's collision engine generates many
# false-positive departures and collisions when rounding the corner between surfaces. So we need to
# be more permissible here for what we consider to be expected when leaving and entering the air.
func update_navigation_state( \
        navigation_state: PlayerNavigationState, \
        surface_state: PlayerSurfaceState, \
        playback, \
        just_started_new_edge: bool) -> void:
    .update_navigation_state( \
            navigation_state, \
            surface_state, \
            playback, \
            just_started_new_edge)
    
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
    
    navigation_state.just_reached_end_of_edge = _check_did_just_reach_destination( \
            navigation_state, \
            surface_state, \
            playback)

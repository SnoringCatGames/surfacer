# Information for how to walk to and off the edge of a floor.
# 
# - The instructions for this edge consist of a single sideways key press, with
#   no corresponding release.
# - The start point for this edge corresponds to the surface-edge end point.
# - This edge consists of a small portion for walking from the start point to
#   the fall-off point, and then another portion for falling from the fall-off
#   point to the landing point.
extends Edge
class_name FallFromFloorEdge

const TYPE := EdgeType.FALL_FROM_FLOOR_EDGE
const IS_TIME_BASED := false
const SURFACE_TYPE := SurfaceType.AIR
const ENTERS_AIR := true
const INCLUDES_AIR_TRAJECTORY := true

var falls_on_left_side: bool
var fall_off_position: PositionAlongSurface

func _init( \
        calculator, \
        start: PositionAlongSurface, \
        end: PositionAlongSurface, \
        velocity_start: Vector2, \
        velocity_end: Vector2, \
        includes_extra_wall_land_horizontal_speed: bool, \
        movement_params: MovementParams, \
        instructions: EdgeInstructions, \
        trajectory: EdgeTrajectory, \
        falls_on_left_side: bool,
        fall_off_position: PositionAlongSurface) \
        .(TYPE, \
        IS_TIME_BASED, \
        SURFACE_TYPE, \
        ENTERS_AIR, \
        INCLUDES_AIR_TRAJECTORY, \
        calculator, \
        start, \
        end, \
        velocity_start, \
        velocity_end, \
        false, \
        includes_extra_wall_land_horizontal_speed, \
        movement_params, \
        instructions, \
        trajectory) -> void:
    self.falls_on_left_side = falls_on_left_side
    self.fall_off_position = fall_off_position

func _calculate_distance( \
        start: PositionAlongSurface, \
        end: PositionAlongSurface, \
        trajectory: EdgeTrajectory) -> float:
    return trajectory.distance_from_continuous_frames

func _calculate_duration( \
        start: PositionAlongSurface, \
        end: PositionAlongSurface, \
        instructions: EdgeInstructions, \
        distance: float) -> float:
    return instructions.duration

func _check_did_just_reach_destination( \
        navigation_state: PlayerNavigationState, \
        surface_state: PlayerSurfaceState, \
        playback) -> bool:
    return Edge.check_just_landed_on_expected_surface( \
            surface_state, \
            self.end_surface)

# When walking off the end of a surface, Godot's underlying collision engine
# can trigger multiple extraneous launch/land events if the player's collision
# boundary is not square. So this function override adds logic to ignore any of
# these extra collisions with the starting surface.
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
    
    var is_still_colliding_with_start_surface := \
            surface_state.grabbed_surface == self.start_surface
    if is_still_colliding_with_start_surface:
        navigation_state.is_expecting_to_enter_air = true
    
    var is_grabbed_surface_expected: bool = \
            surface_state.grabbed_surface == self.end_surface or \
            is_still_colliding_with_start_surface
    navigation_state.just_left_air_unexpectedly = \
            surface_state.just_left_air and \
            !is_grabbed_surface_expected and \
            surface_state.collision_count > 0
    
    navigation_state.just_interrupted_navigation = \
            navigation_state.just_left_air_unexpectedly or \
            navigation_state.just_entered_air_unexpectedly or \
            navigation_state.just_interrupted_by_user_action
    
    navigation_state.just_reached_end_of_edge = \
            _check_did_just_reach_destination( \
                    navigation_state, \
                    surface_state, \
                    playback)

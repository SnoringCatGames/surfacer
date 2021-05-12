# Information for how to climb down a wall to stand on the adjacent floor.
# 
# The instructions for this edge consist of a single downward key press, with no corresponding
# release. This will cause the player to climb down the wall, then grab the floor once they reach
# it.
class_name ClimbDownWallToFloorEdge
extends Edge

const TYPE := EdgeType.CLIMB_DOWN_WALL_TO_FLOOR_EDGE
const IS_TIME_BASED := false
const SURFACE_TYPE := SurfaceType.WALL
const ENTERS_AIR := false
const INCLUDES_AIR_TRAJECTORY := false

func _init(
        calculator = null,
        start: PositionAlongSurface = null,
        end: PositionAlongSurface = null,
        movement_params: MovementParams = null) \
        .(TYPE,
        IS_TIME_BASED,
        SURFACE_TYPE,
        ENTERS_AIR,
        INCLUDES_AIR_TRAJECTORY,
        calculator,
        start,
        end,
        Vector2.ZERO,
        Vector2.ZERO,
        false,
        false,
        movement_params,
        _calculate_instructions(start, end),
        null,
        EdgeCalcResultType.EDGE_VALID_WITH_ONE_STEP,
        0.0) -> void:
    pass

func _calculate_distance(
        start: PositionAlongSurface,
        end: PositionAlongSurface,
        trajectory: EdgeTrajectory) -> float:
    return Gs.geometry.calculate_manhattan_distance(
            start.target_point,
            end.target_point)

func _calculate_duration(
        start: PositionAlongSurface,
        end: PositionAlongSurface,
        instructions: EdgeInstructions,
        distance: float) -> float:
    return MovementUtils.calculate_time_to_climb(
            distance,
            false,
            movement_params)

func get_position_at_time(edge_time: float) -> Vector2:
    if edge_time > duration:
        return Vector2.INF
    var start := get_start()
    var surface := get_start_surface()
    var position_y := start.y + movement_params.climb_down_speed * edge_time
    return Gs.geometry.project_point_onto_surface_with_offset(
            Vector2(0.0, position_y),
            surface,
            movement_params.collider_half_width_height)

func get_velocity_at_time(edge_time: float) -> Vector2:
    if edge_time > duration:
        return Vector2.INF
    var velocity_x := \
            -PlayerActionHandler \
                    .MIN_SPEED_TO_MAINTAIN_HORIZONTAL_COLLISION if \
            get_start_surface().side == SurfaceSide.LEFT_WALL else \
            PlayerActionHandler \
                    .MIN_SPEED_TO_MAINTAIN_HORIZONTAL_COLLISION
    velocity_x /= Gs.time.get_combined_scale()
    return Vector2(velocity_x, movement_params.climb_down_speed)

func get_animation_state_at_time(
        result: PlayerAnimationState,
        edge_time: float) -> void:
    result.player_position = get_position_at_time(edge_time)
    result.animation_type = PlayerAnimationType.CLIMB_DOWN
    result.animation_position = edge_time
    result.facing_left = get_start_surface().side == SurfaceSide.LEFT_WALL

func _check_did_just_reach_destination(
        navigation_state: PlayerNavigationState,
        surface_state: PlayerSurfaceState,
        playback) -> bool:
    if movement_params.bypasses_runtime_physics:
        return playback.get_elapsed_time_scaled() >= duration
    else:
        return surface_state.just_grabbed_floor

func _get_weight_multiplier() -> float:
    return movement_params.walking_edge_weight_multiplier

static func _calculate_instructions(
        start: PositionAlongSurface,
        end: PositionAlongSurface) -> EdgeInstructions:
    if start == null or end == null:
        return null
    
    assert(start.side == SurfaceSide.LEFT_WALL || \
            start.side == SurfaceSide.RIGHT_WALL)
    assert(end.side == SurfaceSide.FLOOR)
    
    var instruction := EdgeInstruction.new(
            "md",
            0.0,
            true)
    
    return EdgeInstructions.new(
            [instruction],
            INF)

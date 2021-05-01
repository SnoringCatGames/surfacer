# Information for how to walk across a floor to grab on to an adjacent upward
# wall.
# 
# The instructions for this edge consist of two consecutive directional-key
# presses (toward the wall, and upward), with no corresponding release.
class_name WalkToAscendWallFromFloorEdge
extends Edge

const TYPE := EdgeType.WALK_TO_ASCEND_WALL_FROM_FLOOR_EDGE
const IS_TIME_BASED := false
const SURFACE_TYPE := SurfaceType.FLOOR
const ENTERS_AIR := false
const INCLUDES_AIR_TRAJECTORY := false

func _init(
        calculator = null,
        start: PositionAlongSurface = null,
        end: PositionAlongSurface = null,
        velocity_start := Vector2.INF,
        movement_params: MovementParams = null) \
        .(TYPE,
        IS_TIME_BASED,
        SURFACE_TYPE,
        ENTERS_AIR,
        INCLUDES_AIR_TRAJECTORY,
        calculator,
        start,
        end,
        velocity_start,
        Vector2.ZERO,
        false,
        false,
        movement_params,
        _calculate_instructions(start, end),
        null,
        EdgeCalcResultType.EDGE_VALID_WITH_ONE_STEP) -> void:
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
    return MovementUtils.calculate_time_to_walk(
            distance,
            0.0,
            movement_params)

func get_position_at_time(edge_time: float) -> Vector2:
    if edge_time > duration:
        return Vector2.INF
    var start := get_start()
    var displacement := get_end() - start
    var surface := get_start_surface()
    var acceleration_x := \
            movement_params.walk_acceleration if \
            displacement.x > 0 else \
            -movement_params.walk_acceleration
    var displacement_x := \
            MovementUtils.calculate_displacement_for_duration(
                    edge_time,
                    velocity_start.x,
                    acceleration_x,
                    movement_params.max_horizontal_speed_default)
    var position_x := start.x + displacement_x
    return Gs.geometry.project_point_onto_surface_with_offset(
            Vector2(position_x, 0.0),
            surface,
            movement_params.collider_half_width_height)

func get_velocity_at_time(edge_time: float) -> Vector2:
    if edge_time > duration:
        return Vector2.INF
    var start := get_start()
    var displacement := get_end() - start
    var acceleration_x := \
            movement_params.walk_acceleration if \
            displacement.x > 0 else \
            -movement_params.walk_acceleration
    var velocity_x := velocity_start.x + acceleration_x * edge_time
    velocity_x = clamp(
            velocity_x,
            -movement_params.max_horizontal_speed_default,
            movement_params.max_horizontal_speed_default)
    var velocity_y := \
            PlayerActionHandler \
                    .MIN_SPEED_TO_MAINTAIN_VERTICAL_COLLISION if \
            get_start_surface().side == SurfaceSide.FLOOR else \
            -PlayerActionHandler \
                    .MIN_SPEED_TO_MAINTAIN_VERTICAL_COLLISION
    return Vector2(velocity_x, velocity_y)

func _check_did_just_reach_destination(
        navigation_state: PlayerNavigationState,
        surface_state: PlayerSurfaceState,
        playback) -> bool:
    return surface_state.just_grabbed_left_wall or \
            surface_state.just_grabbed_right_wall

static func _calculate_instructions(
        start: PositionAlongSurface,
        end: PositionAlongSurface) -> EdgeInstructions:
    if start == null or end == null:
        return null
    
    assert(end.side == SurfaceSide.LEFT_WALL || \
            end.side == SurfaceSide.RIGHT_WALL)
    assert(start.side == SurfaceSide.FLOOR)
    
    var sideways_input_key := \
            "ml" if \
            end.side == SurfaceSide.LEFT_WALL else \
            "mr"
    var inward_instruction := EdgeInstruction.new(
            sideways_input_key,
            0.0,
            true)
    
    var upward_instruction := EdgeInstruction.new(
            "mu",
            0.0,
            true)
    
    return EdgeInstructions.new(
            [inward_instruction, upward_instruction],
            INF)

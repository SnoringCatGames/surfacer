class_name ClimbToAdjacentSurfaceEdge
extends Edge
## Information for how to transition from a surface to a neighbor surface.
## (climbing around an inside or outside corner).
## 
## -   The instructions for this edge consist of one or two directional-key
##     presses with no corresponding release.
##     -   Convex neighbor:
##         -   Into the start surface.
##             -   An explicit grabbing instruction.
##         -   And parallel to the start surface toward the end surface.
##             -   In order to move.
##     -   Concave neighbor:
##         -   Parallel to the start surface toward the end surface.
##             -   In order to move.


const TYPE := EdgeType.CLIMB_TO_ADJACENT_SURFACE_EDGE
const IS_TIME_BASED := false
const ENTERS_AIR := false


func _init(
        calculator = null,
        start: PositionAlongSurface = null,
        end: PositionAlongSurface = null,
        velocity_start := Vector2.INF,
        velocity_end := Vector2.INF,
        distance := INF,
        duration := INF,
        movement_params: MovementParameters = null,
        instructions: EdgeInstructions = null,
        trajectory: EdgeTrajectory = null) \
        .(TYPE,
        IS_TIME_BASED,
        SurfaceType.get_type_from_side(
                start.side if \
                is_instance_valid(start) else \
                SurfaceSide.NONE),
        ENTERS_AIR,
        calculator,
        start,
        end,
        velocity_start,
        velocity_end,
        distance,
        duration,
        false,
        false,
        movement_params,
        instructions,
        trajectory,
        EdgeCalcResultType.EDGE_VALID_WITH_ONE_STEP,
        0.0) -> void:
    pass


func _get_weight_multiplier() -> float:
    return movement_params.climb_to_adjacent_surface_edge_weight_multiplier


func get_animation_state_at_time(
        result: CharacterAnimationState,
        edge_time: float) -> void:
    result.character_position = get_position_at_time(edge_time)
    result.animation_position = edge_time
    
    var displacement := \
            end_position_along_surface.target_point - \
            start_position_along_surface.target_point
    
    match start_position_along_surface.side:
        SurfaceSide.FLOOR:
            result.animation_name = "Walk"
            result.facing_left = displacement.x < 0.0
        SurfaceSide.CEILING:
            result.animation_name = "CrawlOnCeiling"
            result.facing_left = displacement.x < 0.0
        SurfaceSide.LEFT_WALL:
            result.animation_name = \
                    "ClimbUp" if \
                    displacement.y < 0.0 else \
                    "ClimbDown"
            result.facing_left = true
        SurfaceSide.RIGHT_WALL:
            result.animation_name = \
                    "ClimbUp" if \
                    displacement.y < 0.0 else \
                    "ClimbDown"
            result.facing_left = false
        _:
            Sc.logger.error()


func _check_did_just_reach_surface_destination(
        navigation_state: CharacterNavigationState,
        surface_state: CharacterSurfaceState,
        playback,
        just_started_new_edge: bool) -> bool:
    if movement_params.bypasses_runtime_physics:
        return playback.get_elapsed_time_scaled() >= duration
    else:
        var is_clockwise := get_is_clockwise()
        var current_point := surface_state.center_position
        var target_point := end_position_along_surface.target_point
        
        var is_past_end_point: bool
        match end_position_along_surface.side:
            SurfaceSide.FLOOR:
                is_past_end_point = \
                        current_point.x >= target_point.x if \
                        is_clockwise else \
                        current_point.x <= target_point.x
            SurfaceSide.CEILING:
                is_past_end_point = \
                        current_point.x <= target_point.x if \
                        is_clockwise else \
                        current_point.x >= target_point.x
            SurfaceSide.LEFT_WALL:
                is_past_end_point = \
                        current_point.y >= target_point.y if \
                        is_clockwise else \
                        current_point.y <= target_point.y
            SurfaceSide.RIGHT_WALL:
                is_past_end_point = \
                        current_point.y <= target_point.y if \
                        is_clockwise else \
                        current_point.y >= target_point.y
            _:
                Sc.logger.error()
                is_past_end_point = false
        
        return surface_state.grabbed_surface == \
                end_position_along_surface.surface and \
                is_past_end_point


func load_from_json_object(
        json_object: Dictionary,
        context: Dictionary) -> void:
    .load_from_json_object(json_object, context)
    edge_type = SurfaceType.get_type_from_side(
            start_position_along_surface.side)


func get_is_clockwise() -> bool:
    return start_position_along_surface.surface.clockwise_neighbor == \
            end_position_along_surface.surface


func get_is_convex() -> bool:
    return start_position_along_surface.surface \
                    .clockwise_convex_neighbor == \
                    end_position_along_surface.surface or \
            start_position_along_surface.surface \
                    .counter_clockwise_convex_neighbor == \
                    end_position_along_surface.surface

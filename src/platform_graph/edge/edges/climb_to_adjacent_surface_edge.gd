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

var time_at_surface_switch: float


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
        trajectory: EdgeTrajectory = null,
        time_at_surface_switch := INF) \
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
    self.time_at_surface_switch = time_at_surface_switch


func _get_weight_multiplier() -> float:
    return movement_params.climb_to_adjacent_surface_edge_weight_multiplier if \
            !get_is_collinear() else \
            movement_params.move_to_collinear_surface_edge_weight_multiplier


func get_animation_state_at_time(
        result: SurfacerCharacterAnimationState,
        edge_time: float) -> void:
    var surface := \
            start_position_along_surface.surface if \
            edge_time < time_at_surface_switch else \
            end_position_along_surface.surface
    
    result.character_position = get_position_at_time(edge_time)
    result.grabbed_surface = surface
    result.grab_position = Sc.geometry.get_closest_point_on_surface_to_shape(
            surface,
            result.character_position,
            movement_params.collider)
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
            Sc.logger.error("ClimbToAdjacentSurfaceEdge.get_animation_state_at_time")


func _sync_expected_middle_surface_state(
        surface_state: CharacterSurfaceState,
        edge_time: float) -> void:
    var edge_frame_index := int(edge_time / Time.PHYSICS_TIME_STEP)
    var surface_switch_index := \
            int(time_at_surface_switch / Time.PHYSICS_TIME_STEP)
    var did_just_switch := edge_frame_index == surface_switch_index
    var surface := \
            get_start_surface() if \
            edge_frame_index <= surface_switch_index else \
            get_end_surface()
    var position := get_position_at_time(edge_time)
    var velocity := get_velocity_at_time(edge_time)
    var corner_point := get_corner_point()
    var facing_left := \
            true if surface.side == SurfaceSide.LEFT_WALL else \
            false if surface.side == SurfaceSide.RIGHT_WALL else \
            position.x < corner_point.x
    
    if did_just_switch:
        surface_state.sync_state_for_surface_release(
                get_start_surface(),
                position)
    surface_state.sync_state_for_surface_grab(
            surface,
            position,
            did_just_switch,
            facing_left)
    surface_state.velocity = velocity


func _get_is_surface_expected_for_touch_contact(
        contact_surface: Surface,
        navigation_state: CharacterNavigationState) -> bool:
    return ._get_is_surface_expected_for_touch_contact(
            contact_surface,
            navigation_state) or \
            contact_surface == get_next_neighbor()


func _get_is_surface_expected_for_grab(
        grabbed_surface: Surface,
        navigation_state: CharacterNavigationState) -> bool:
    return grabbed_surface == start_position_along_surface.surface or \
            grabbed_surface == start_position_along_surface.surface \
                .clockwise_collinear_neighbor or \
            grabbed_surface == start_position_along_surface.surface \
                .counter_clockwise_collinear_neighbor or \
            grabbed_surface == end_position_along_surface.surface or \
            grabbed_surface == end_position_along_surface.surface \
                .clockwise_collinear_neighbor or \
            grabbed_surface == end_position_along_surface.surface \
                .counter_clockwise_collinear_neighbor or \
            grabbed_surface == get_next_neighbor()


# In order to "reach" our destination, we need to leave the origin surface.
func _check_did_just_reach_surface_destination(
        navigation_state: CharacterNavigationState,
        surface_state: CharacterSurfaceState,
        playback,
        just_started_new_edge: bool) -> bool:
    if movement_params.bypasses_runtime_physics:
        return playback.get_elapsed_time_scaled() >= duration
    
    if get_is_collinear():
        return true
    
    var is_clockwise := get_is_clockwise()
    var start_surface := start_position_along_surface.surface
    var end_surface := end_position_along_surface.surface
    var current_point := surface_state.center_position
    var target_point := end_position_along_surface.target_point
    
    if surface_state.contact_count > 1:
        var concave_neighbor_approaching := \
                end_surface.clockwise_concave_neighbor if \
                is_clockwise else \
                end_surface.counter_clockwise_concave_neighbor
        
        # If we collide with the "next neighbor", then we must be done.
        for contact_surface in surface_state.surfaces_to_contacts:
            if contact_surface == concave_neighbor_approaching:
                # Colliding with the neighbor that we're approaching at the
                # end of the edge.
                return true
        
        # In order to "reach" our destination, we need to leave the origin
        # surface.
        for contact_surface in surface_state.surfaces_to_contacts:
            if contact_surface == start_surface:
                return false
    
    if !get_is_convex() and \
            surface_state.grabbed_surface == end_surface:
        # For a concave or collinear transition, as soon as we are no longer
        # touching the origin surface, we have reached the destination.
        return true
    
    # For a convex corner, we must pass the target coordinate.
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
            Sc.logger.error("ClimbToAdjacentSurfaceEdge._check_did_just_reach_surface_destination")
            is_past_end_point = false
    return surface_state.grabbed_surface == \
            end_position_along_surface.surface and \
            is_past_end_point


func _load_edge_state_from_json_object(
        json_object: Dictionary,
        context: Dictionary) -> void:
    ._load_edge_state_from_json_object(json_object, context)
    surface_type = SurfaceType.get_type_from_side(
            start_position_along_surface.side)
    time_at_surface_switch = json_object.ts


func _edge_state_to_json_object(json_object: Dictionary) -> void:
    ._edge_state_to_json_object(json_object)
    json_object.ts = time_at_surface_switch


func get_corner_point() -> Vector2:
    var start_surface := start_position_along_surface.surface
    var end_surface := end_position_along_surface.surface
    return start_surface.first_point if \
            start_surface.first_point == end_surface.first_point or \
            start_surface.first_point == end_surface.last_point else \
            start_surface.last_point


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


func get_is_concave() -> bool:
    return start_position_along_surface.surface \
                    .clockwise_concave_neighbor == \
                    end_position_along_surface.surface or \
            start_position_along_surface.surface \
                    .counter_clockwise_concave_neighbor == \
                    end_position_along_surface.surface


func get_is_collinear() -> bool:
    return start_position_along_surface.surface \
                    .clockwise_collinear_neighbor == \
                    end_position_along_surface.surface or \
            start_position_along_surface.surface \
                    .counter_clockwise_collinear_neighbor == \
                    end_position_along_surface.surface


func get_next_neighbor() -> Surface:
    return end_position_along_surface.surface.clockwise_neighbor if \
            get_is_clockwise() else \
            end_position_along_surface.surface.counter_clockwise_neighbor

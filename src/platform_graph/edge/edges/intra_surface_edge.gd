class_name IntraSurfaceEdge
extends Edge
## -   Information for how to move along a surface from a start position to an
##     end position.[br]
## -   The instructions for an intra-surface edge consist of a single
##     directional-key press step, with no corresponding release.[br]


const TYPE := EdgeType.INTRA_SURFACE_EDGE
const IS_TIME_BASED := false
const ENTERS_AIR := false

const REACHED_DESTINATION_DISTANCE_THRESHOLD := 3.0

var is_moving_clockwise := false
var is_pressing_left := false
var includes_deceleration_at_end := false
var stopping_distance := INF
var release_time := INF
var release_position := Vector2.INF
var release_velocity := Vector2.INF
# Whether this edge turns around and covers any distance twice.
var is_backtracking := false
# If true, then this edge starts and ends at the same position.
var is_degenerate: bool

func _init(
        calculator = null,
        start_position_along_surface: PositionAlongSurface = null,
        end_position_along_surface: PositionAlongSurface = null,
        velocity_start := Vector2.INF,
        velocity_end := Vector2.INF,
        distance := INF,
        duration := INF,
        is_moving_clockwise := false,
        is_pressing_left := false,
        includes_deceleration_at_end := false,
        stopping_distance := INF,
        release_time := INF,
        release_position := Vector2.INF,
        release_velocity := Vector2.INF,
        is_degenerate := false,
        movement_params: MovementParameters = null,
        instructions: EdgeInstructions = null,
        trajectory: EdgeTrajectory = null) \
        .(TYPE,
        IS_TIME_BASED,
        SurfaceType.get_type_from_side(
                start_position_along_surface.side if \
                is_instance_valid(start_position_along_surface) else \
                SurfaceSide.NONE),
        ENTERS_AIR,
        calculator,
        start_position_along_surface,
        end_position_along_surface,
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
    # Intra-surface edges are never calculated and stored ahead of time;
    # they're only calculated at run time when navigating a specific path.
    self.is_optimized_for_path = true
    self.is_moving_clockwise = is_moving_clockwise
    self.is_pressing_left = is_pressing_left
    self.includes_deceleration_at_end = includes_deceleration_at_end
    self.stopping_distance = stopping_distance
    self.release_time = release_time
    self.release_position = release_position
    self.release_velocity = release_velocity
    self.is_degenerate = is_degenerate


func get_position_at_time(edge_time: float) -> Vector2:
    if is_instance_valid(trajectory):
        return .get_position_at_time(edge_time)
    else:
        return _get_position_at_time_without_trajectory(edge_time)


func get_velocity_at_time(edge_time: float) -> Vector2:
    if is_instance_valid(trajectory):
        return .get_velocity_at_time(edge_time)
    else:
        return _get_velocity_at_time_without_trajectory(edge_time)


func _get_position_at_time_without_trajectory(edge_time: float) -> Vector2:
    if edge_time > duration:
        return Vector2.INF
    var start := get_start()
    var displacement := get_end() - start
    var surface := get_start_surface()
    match surface.side:
        SurfaceSide.FLOOR:
            var position_x: float
            if edge_time < release_time:
                var acceleration_magnitude := MovementUtils \
                        .get_walking_acceleration_with_friction_magnitude(
                            movement_params,
                            surface.properties)
                var acceleration_x := \
                        -acceleration_magnitude if \
                        is_pressing_left else \
                        acceleration_magnitude
                var max_horizontal_speed := \
                        movement_params.get_max_surface_speed() * \
                        surface.properties.speed_multiplier
                var displacement_x := \
                        MovementUtils.calculate_displacement_for_duration(
                            edge_time,
                            velocity_start.x,
                            acceleration_x,
                            max_horizontal_speed)
                position_x = start.x + displacement_x
            else:
                var acceleration_magnitude := MovementUtils \
                        .get_stopping_friction_acceleration_magnitude(
                            movement_params,
                            surface.properties)
                var acceleration_x := \
                        -acceleration_magnitude if \
                        displacement.x > 0 else \
                        acceleration_magnitude
                var max_horizontal_speed := \
                        movement_params.get_max_surface_speed() * \
                        surface.properties.speed_multiplier
                var displacement_x := \
                        MovementUtils.calculate_displacement_for_duration(
                            edge_time - release_time,
                            velocity_start.x,
                            acceleration_x,
                            max_horizontal_speed)
                position_x = release_position.x + displacement_x
            return Sc.geometry.project_shape_onto_surface(
                    Vector2(position_x, 0.0),
                    movement_params.collider,
                    surface,
                    true)
            
        SurfaceSide.LEFT_WALL, \
        SurfaceSide.RIGHT_WALL:
            var velocity_y := \
                    movement_params.climb_up_speed if \
                    displacement.y < 0.0 else \
                    movement_params.climb_down_speed
            velocity_y *= surface.properties.speed_multiplier
            var position_y := start.y + velocity_y * edge_time
            return Sc.geometry.project_shape_onto_surface(
                    Vector2(0.0, position_y),
                    movement_params.collider,
                    surface,
                    true)
        SurfaceSide.CEILING:
            var velocity_x := \
                    movement_params.ceiling_crawl_speed if \
                    displacement.x > 0.0 else \
                    -movement_params.ceiling_crawl_speed
            velocity_x *= surface.properties.speed_multiplier
            var position_x := start.x + velocity_x * edge_time
            return Sc.geometry.project_shape_onto_surface(
                    Vector2(position_x, 0.0),
                    movement_params.collider,
                    surface,
                    true)
        _:
            Sc.logger.error("IntraSurfaceEdge._get_position_at_time_without_trajectory")
            return Vector2.INF


func _get_velocity_at_time_without_trajectory(edge_time: float) -> Vector2:
    if edge_time > duration:
        return Vector2.INF
    var start := get_start()
    var displacement := get_end() - start
    var surface := get_start_surface()
    match surface.side:
        SurfaceSide.FLOOR:
            if edge_time < release_time:
                var acceleration_magnitude := MovementUtils \
                        .get_walking_acceleration_with_friction_magnitude(
                            movement_params,
                            surface.properties)
                var acceleration_x := \
                        -acceleration_magnitude if \
                        is_pressing_left else \
                        acceleration_magnitude
                var max_horizontal_speed := \
                        movement_params.get_max_surface_speed() * \
                        surface.properties.speed_multiplier
                var velocity_x := velocity_start.x + acceleration_x * edge_time
                velocity_x = clamp(
                        velocity_x,
                        -max_horizontal_speed,
                        max_horizontal_speed)
                return Vector2(velocity_x, 0.0)
            else:
                var acceleration_magnitude := MovementUtils \
                        .get_stopping_friction_acceleration_magnitude(
                            movement_params,
                            surface.properties)
                var acceleration_x := \
                        -acceleration_magnitude if \
                        displacement.x > 0 else \
                        acceleration_magnitude
                var velocity_x := \
                        release_velocity.x + \
                        acceleration_x * (edge_time - release_time)
                if displacement.x > 0:
                    velocity_x = max(velocity_x, 0.0)
                else:
                    velocity_x = min(velocity_x, 0.0)
                return Vector2(velocity_x, 0.0)
            
        SurfaceSide.LEFT_WALL, \
        SurfaceSide.RIGHT_WALL:
            var velocity_y := \
                    movement_params.climb_up_speed if \
                    displacement.y < 0.0 else \
                    movement_params.climb_down_speed
            velocity_y *= surface.properties.speed_multiplier
            return Vector2(0.0, velocity_y)
        SurfaceSide.CEILING:
            var velocity_x := \
                    movement_params.ceiling_crawl_speed if \
                    displacement.x > 0.0 else \
                    -movement_params.ceiling_crawl_speed
            velocity_x *= surface.properties.speed_multiplier
            return Vector2(velocity_x, 0.0)
        _:
            Sc.logger.error("IntraSurfaceEdge._get_velocity_at_time_without_trajectory")
            return Vector2.INF


func get_animation_state_at_time(
        result: SurfacerCharacterAnimationState,
        edge_time: float) -> void:
    var displacement := get_end() - get_start()
    
    result.character_position = get_position_at_time(edge_time)
    result.grabbed_surface = start_position_along_surface.surface
    result.grab_position = Sc.geometry.get_closest_point_on_surface_to_shape(
            start_position_along_surface.surface,
            result.character_position,
            movement_params.collider)
    result.animation_position = edge_time
    
    var side := get_start_surface().side
    match side:
        SurfaceSide.FLOOR:
            result.animation_name = "Walk"
            result.facing_left = displacement.x < 0.0
        SurfaceSide.LEFT_WALL, \
        SurfaceSide.RIGHT_WALL:
            result.animation_name = \
                    "ClimbUp" if \
                    displacement.y < 0.0 else \
                    "ClimbDown"
            result.facing_left = side == SurfaceSide.LEFT_WALL
        SurfaceSide.CEILING:
            result.animation_name = "CrawlOnCeiling"
            result.facing_left = displacement.x < 0.0
        _:
            Sc.logger.error("IntraSurfaceEdge.get_animation_state_at_time")


func _sync_expected_middle_surface_state(
        surface_state: CharacterSurfaceState,
        edge_time: float) -> void:
    var position := get_position_at_time(edge_time)
    var velocity := get_velocity_at_time(edge_time)
    var surface := get_start_surface()
    var displacement := get_end() - get_start()
    var facing_left := \
            true if surface.side == SurfaceSide.LEFT_WALL else \
            false if surface.side == SurfaceSide.RIGHT_WALL else \
            displacement.x < 0.0
    
    surface_state.sync_state_for_surface_grab(
            surface,
            position,
            false,
            facing_left)
    surface_state.velocity = velocity


func _check_did_just_reach_surface_destination(
        navigation_state: CharacterNavigationState,
        surface_state: CharacterSurfaceState,
        playback,
        just_started_new_edge: bool) -> bool:
    if movement_params.bypasses_runtime_physics:
        return playback.get_elapsed_time_scaled() >= duration
    
    var surface := get_start_surface()
    
    if surface_state.contact_count > 1:
        var concave_neighbor_approaching := \
                surface.clockwise_concave_neighbor if \
                is_moving_clockwise else \
                surface.counter_clockwise_concave_neighbor
        for contact_surface in surface_state.surfaces_to_contacts:
            if contact_surface == concave_neighbor_approaching:
                # Colliding with the neighbor that we're approaching at the
                # end of the edge.
                return true
    
    # Check whether we were on the other side of the destination in the
    # previous frame.
    
    var end := end_position_along_surface.target_point
    var displacement := \
            end_position_along_surface.target_point - \
            start_position_along_surface.target_point
    var epsilon := 0.1
    
    var was_less_than_end: bool
    var is_less_than_end: bool
    var diff: float
    var is_moving_away_from_destination: bool
    
    if surface_state.is_grabbing_wall:
        var is_moving_upward := displacement.y < 0.0
        var position_end_threshold := \
                end.y + epsilon if \
                is_moving_upward else \
                end.y - epsilon
        was_less_than_end = \
                surface_state.previous_center_position.y < \
                position_end_threshold
        is_less_than_end = \
                    surface_state.center_position.y < \
                position_end_threshold
        diff = position_end_threshold - surface_state.center_position.y
        is_moving_away_from_destination = (diff > 0) == is_moving_upward
        
    else:
        var is_moving_leftward := displacement.x < 0.0
        var position_end_threshold := \
                end.x + epsilon if \
                is_moving_leftward else \
                end.x - epsilon
        was_less_than_end = \
                surface_state.previous_center_position.x < \
                position_end_threshold
        is_less_than_end = \
                surface_state.center_position.x < \
                position_end_threshold
        diff = position_end_threshold - surface_state.center_position.x
        is_moving_away_from_destination = (diff > 0) == is_moving_leftward
    
    var moved_across_destination := was_less_than_end != is_less_than_end
    var is_close_to_destination := \
            abs(diff) < REACHED_DESTINATION_DISTANCE_THRESHOLD
    
    if !is_backtracking:
        return moved_across_destination or \
                is_close_to_destination or \
                is_moving_away_from_destination
    else:
        # FIXME: LEFT OFF HERE: ----------------- Double-check this new logic.
        # TODO: Add support for acceleration and friction along wall and
        #       ceiling surfaces.
        assert(surface.side == SurfaceSide.FLOOR)
        return (moved_across_destination or \
                is_close_to_destination) and \
                Sc.geometry.are_floats_equal_with_epsilon(
                    surface_state.velocity.x,
                    velocity_end.x,
                    0.1)


func _get_is_surface_expected_for_touch_contact(
        contact_surface: Surface,
        navigation_state: CharacterNavigationState) -> bool:
    return ._get_is_surface_expected_for_touch_contact(
            contact_surface,
            navigation_state) or \
            contact_surface == get_next_neighbor()


func get_next_neighbor() -> Surface:
    return end_position_along_surface.surface.clockwise_neighbor if \
            is_moving_clockwise else \
            end_position_along_surface.surface.counter_clockwise_neighbor

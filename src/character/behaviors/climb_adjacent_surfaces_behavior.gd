tool
class_name ClimbAdjacentSurfacesBehavior, \
"res://addons/surfacer/assets/images/editor_icons/climb_adjacent_surfaces_behavior.png"
extends Behavior
## -   This moves a character across a surface, then onto the next adjacent
##     surface, and repeats.
## -   If the character cannot grab the next adjacent surface, then the
##     character will turn around and go back the way it came.


const NAME := "climb_adjacent_surfaces"
const IS_ADDED_MANUALLY := true
const USES_MOVE_TARGET := false
const INCLUDES_MID_MOVEMENT_PAUSE := true
const INCLUDES_POST_MOVEMENT_PAUSE := false
const COULD_RETURN_TO_START_POSITION := false

const DISTANCE_TO_SURFACE_END_THRESHOLD := 4.0

## -   If true, the character will climb in a clockwise direction around convex
##     corners.
##     -   I.e., the character will walk toward the right on floor surfaces.
export var is_clockwise := true

## -   If true, the character will pick a random direction to move in at the
##     start.
## -   If true, then `is_clockwise` will not be used.
export var randomizes_initial_direction := false


func _init().(
        NAME,
        IS_ADDED_MANUALLY,
        USES_MOVE_TARGET,
        INCLUDES_MID_MOVEMENT_PAUSE,
        INCLUDES_POST_MOVEMENT_PAUSE,
        COULD_RETURN_TO_START_POSITION) -> void:
    pass


func _on_active() -> void:
    ._on_active()
    if randomizes_initial_direction:
        is_clockwise = randf() < 0.5


#func _on_ready_to_move() -> void:
#    ._on_ready_to_move()


#func _on_inactive() -> void:
#    ._on_inactive()


#func _on_navigation_ended(did_navigation_finish: bool) -> void:
#    ._on_navigation_ended(did_navigation_finish)


#func _on_physics_process(delta: float) -> void:
#    ._on_physics_process(delta)


func _move() -> int:
    return _attempt_navigation(false)


func _attempt_navigation(just_turned_around: bool) -> int:
    var next_surface := \
            latest_move_start_surface.clockwise_neighbor if \
            is_clockwise else \
            latest_move_start_surface.counter_clockwise_neighbor
    var can_grab_next_surface: bool = \
            next_surface.side == SurfaceSide.FLOOR and \
            character.movement_params.can_grab_floors or \
            next_surface.side == SurfaceSide.CEILING and \
            character.movement_params.can_grab_ceilings or \
            (next_surface.side == SurfaceSide.LEFT_WALL or \
            next_surface.side == SurfaceSide.RIGHT_WALL) and \
            character.movement_params.can_grab_walls
    var intra_surface_destination := _get_intra_surface_destination()
    var is_already_at_surface_end := \
            latest_move_start_position.distance_squared_to( \
                    intra_surface_destination.target_point) < \
            DISTANCE_TO_SURFACE_END_THRESHOLD * \
                    DISTANCE_TO_SURFACE_END_THRESHOLD
    
    if is_already_at_surface_end and \
            !can_grab_next_surface and \
            !just_turned_around:
        # If we've reached the end of a surface, and we can't grab the next
        # surface, then turn around and go the other way.
        is_clockwise = !is_clockwise
        return _attempt_navigation(true)
    
    var edges := []
    
    if !is_already_at_surface_end:
        var intra_surface_edge: IntraSurfaceEdge = \
                Su.movement.intra_surface_calculator.create(
                    latest_move_start_position_along_surface,
                    intra_surface_destination,
                    Vector2.ZERO,
                    character.movement_params,
                    false,
                    false)
        edges.push_back(intra_surface_edge)
    
    if can_grab_next_surface and \
            can_leave_start_surface:
        var climb_to_neighbor_surface_edge := \
                _create_climb_to_neighbor_surface_edge()
        edges.push_back(climb_to_neighbor_surface_edge)
        
        var intra_surface_edge: IntraSurfaceEdge = Su.movement \
                .intra_surface_calculator.create_correction_interstitial(
                    climb_to_neighbor_surface_edge.end_position_along_surface,
                    Vector2.ZERO,
                    character.movement_params)
        edges.push_back(intra_surface_edge)
    
    var path := PlatformGraphPath.new(edges)
    
    var is_navigation_valid: bool = character.navigator.navigate_path(path)
    return BehaviorMoveResult.VALID_MOVE if \
            is_navigation_valid else \
            BehaviorMoveResult.INVALID_MOVE


func _get_intra_surface_destination() -> PositionAlongSurface:
    var max_distance_point := \
            Sc.geometry.get_intersection_of_segment_and_circle(
                    latest_move_start_surface.first_point,
                    latest_move_start_surface.last_point,
                    start_position_for_max_distance_checks,
                    max_distance_from_start_position,
                    true)
    
    var is_max_distance_point_in_the_direction_of_movement := false
    
    if max_distance_point != Vector2.INF:
        var is_max_distance_point_clockwise := is_point_clockwise(
                latest_move_start_position,
                max_distance_point,
                latest_move_start_surface)
        is_max_distance_point_in_the_direction_of_movement = \
                is_max_distance_point_clockwise == is_clockwise
        
        if !is_max_distance_point_in_the_direction_of_movement:
            # The max-distance point is behind the character, but it's possible
            # that there are two max distance points on this surface, so try
            # the other point.
            max_distance_point = \
                    Sc.geometry.get_intersection_of_segment_and_circle(
                            latest_move_start_surface.first_point,
                            latest_move_start_surface.last_point,
                            start_position_for_max_distance_checks,
                            max_distance_from_start_position,
                            false)
            
            is_max_distance_point_clockwise = is_point_clockwise(
                    latest_move_start_position,
                    max_distance_point,
                    latest_move_start_surface)
            is_max_distance_point_in_the_direction_of_movement = \
                    is_max_distance_point_clockwise == is_clockwise
    
    var intra_surface_destination_target := \
            max_distance_point if \
            is_max_distance_point_in_the_direction_of_movement else \
            latest_move_start_surface.last_point if \
            is_clockwise else \
            latest_move_start_surface.first_point
    
    return PositionAlongSurfaceFactory \
            .create_position_offset_from_target_point(
                    intra_surface_destination_target,
                    latest_move_start_surface,
                    character.collider,
                    true)


func _create_climb_to_neighbor_surface_edge() -> ClimbToAdjacentSurfaceEdge:
    var calculator: ClimbToAdjacentSurfaceCalculator = \
            Su.movement.edge_calculators["ClimbToAdjacentSurfaceCalculator"]
    var climb_edge_jump_land_positions := \
            calculator._calculate_jump_land_positions(
                    latest_move_start_surface,
                    is_clockwise,
                    character.movement_params)
    return calculator.calculate_edge(
                    null,
                    character.graph.collision_params,
                    climb_edge_jump_land_positions.jump_position,
                    climb_edge_jump_land_positions.land_position,
                    climb_edge_jump_land_positions.velocity_start) as \
                    ClimbToAdjacentSurfaceEdge


func is_point_clockwise(
        basis: Vector2,
        target: Vector2,
        surface: Surface) -> bool:
    match surface.side:
        SurfaceSide.FLOOR:
            return target.x >= basis.x
        SurfaceSide.CEILING:
            return target.x <= basis.x
        SurfaceSide.LEFT_WALL:
            return target.y >= basis.y
        SurfaceSide.RIGHT_WALL:
            return target.y <= basis.y
        _:
            Sc.logger.error("ClimbAdjacentSurfacesBehavior.is_point_clockwise")
            return false


#func _update_parameters() -> void:
#    ._update_parameters()
#
#    if _configuration_warning != "":
#        return
#
#    _set_configuration_warning("")

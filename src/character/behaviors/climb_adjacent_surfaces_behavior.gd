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
const INCLUDES_MID_MOVEMENT_PAUSE := true
const INCLUDES_POST_MOVEMENT_PAUSE := false
const COULD_RETURN_TO_START_POSITION := false

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
        INCLUDES_MID_MOVEMENT_PAUSE,
        INCLUDES_POST_MOVEMENT_PAUSE,
        COULD_RETURN_TO_START_POSITION) -> void:
    pass


#func _on_active() -> void:
#    ._on_active()


#func _on_ready_to_move() -> void:
#    ._on_ready_to_move()


#func _on_inactive() -> void:
#    ._on_inactive()


#func _on_navigation_ended(did_navigation_finish: bool) -> void:
#    ._on_navigation_ended(did_navigation_finish)


#func _on_physics_process(delta: float) -> void:
#    ._on_physics_process(delta)


func _move() -> bool:
    # FIXME: LEFT OFF HERE: --------------------------
    # - max_distance_from_start_position
    # - start_position_for_max_distance_checks
    # - _reached_max_distance
    # - can_leave_start_surface
    
    if randomizes_initial_direction:
        is_clockwise = randf() < 0.5
    
    var next_surface := \
            start_surface.clockwise_neighbor if \
            is_clockwise else \
            start_surface.counter_clockwise_neighbor
    var can_grab_next_surface: bool = \
            next_surface.side == SurfaceSide.FLOOR and \
            character.movement_params.can_grab_floors or \
            next_surface.side == SurfaceSide.CEILING and \
            character.movement_params.can_grab_ceilings or \
            (next_surface.side == SurfaceSide.LEFT_WALL or \
            next_surface.side == SurfaceSide.RIGHT_WALL) and \
            character.movement_params.can_grab_walls
    
    var edges := []
    
    var intra_surface_edge := _create_intra_surface_edge()
    edges.push_back(intra_surface_edge)
    
    if can_grab_next_surface:
        var climb_to_neighbor_surface_edge := \
                _create_climb_to_neighbor_surface_edge()
        edges.push_back(climb_to_neighbor_surface_edge)
    else:
        is_clockwise = !is_clockwise
    
    var path := PlatformGraphPath.new(edges)
    
    return character.navigator.navigate_path(path)


func _create_intra_surface_edge() -> IntraSurfaceEdge:
    var intra_surface_destination_target := \
            start_surface.last_point if \
            is_clockwise else \
            start_surface.first_point
    var intra_surface_destination := PositionAlongSurfaceFactory \
            .create_position_offset_from_target_point(
                    intra_surface_destination_target,
                    start_surface,
                    character.movement_params.collider_half_width_height,
                    true)
    return IntraSurfaceEdge.new(
            start_position_along_surface,
            intra_surface_destination,
            Vector2.ZERO,
            character.movement_params)


func _create_climb_to_neighbor_surface_edge() -> ClimbToNeighborSurfaceEdge:
    var calculator: ClimbToNeighborSurfaceCalculator = \
            Su.movement.edge_calculators["ClimbToNeighborSurfaceCalculator"]
    var climb_edge_jump_land_positions := \
            calculator._calculate_jump_land_positions(
                    start_surface,
                    is_clockwise,
                    character.movement_params)
    return calculator.calculate_edge(
                    null,
                    character.graph.collision_params,
                    climb_edge_jump_land_positions.jump_position,
                    climb_edge_jump_land_positions.land_position,
                    climb_edge_jump_land_positions.velocity_start) as \
                    ClimbToNeighborSurfaceEdge


#func _update_parameters() -> void:
#    ._update_parameters()
#
#    if _configuration_warning != "":
#        return
#
#    # FIXME: ----------------------------
#
#    _set_configuration_warning("")

tool
class_name JumpBackAndForthBehavior, \
"res://addons/surfacer/assets/images/editor_icons/jump_back_and_forth_behavior.png"
extends MoveBackAndForthBehavior


const JBAFB_NAME := "jump_back_and_forth"
const JBAFB_IS_ADDED_MANUALLY := true
const JBAFB_INCLUDES_MID_MOVEMENT_PAUSE := true
const JBAFB_INCLUDES_POST_MOVEMENT_PAUSE := false
const JBAFB_COULD_RETURN_TO_START_POSITION := false

const MAIN_JUMP_DISTANCE_RATIO_OF_MAX := 0.9
const FALLBACK_JUMP_DISTANCE_RATIO_OF_MAX := 0.5
const CLOSE_ENOUGH_TO_END_DISTANCE_RATIO_OF_JUMP := 0.2


## -   If true, the character will only move by a single jump at a time,
##     pausing in-between movements.
export var limits_to_one_jump_at_a_time := false


func _init().(
        JBAFB_NAME,
        JBAFB_IS_ADDED_MANUALLY,
        JBAFB_INCLUDES_MID_MOVEMENT_PAUSE,
        JBAFB_INCLUDES_POST_MOVEMENT_PAUSE,
        JBAFB_COULD_RETURN_TO_START_POSITION) -> void:
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
    # FIXME: -------------------------- Use limits_to_one_jump_at_a_time.
    
    var destination := _calculate_destination()
    var path := _find_path(destination, false)
    
    if path == null:
        return false
    
    # -   Iterate through the edges in the path.
    # -   If the edge is an IntraSurfaceEdge, then replace it with a series of
    #     jumps.
    # -   Interleave the stardand in-between IntraSurfaceEdges between the
    #     jumps.
    
    var main_jump_distance: float = character.movement_params \
            .floor_jump_max_horizontal_jump_distance * \
            MAIN_JUMP_DISTANCE_RATIO_OF_MAX
    var fallback_jump_distance: float = character.movement_params \
            .floor_jump_max_horizontal_jump_distance * \
            FALLBACK_JUMP_DISTANCE_RATIO_OF_MAX
    var close_enough_to_end_distance: float = character.movement_params \
            .floor_jump_max_horizontal_jump_distance * \
            CLOSE_ENOUGH_TO_END_DISTANCE_RATIO_OF_JUMP
    
    var i := 0
    while i < path.edges.size():
        var original_edge: Edge = path.edges[i]
        var surface := original_edge.get_start_surface()
        
        # We only add jumps for floor IntraSurfaceEdges.
        if !(original_edge is IntraSurfaceEdge) or \
                surface.side != SurfaceSide.FLOOR:
            i += 1
            continue
        
        var was_last_edge := i == path.edges.size() - 1
        
        var new_edges := []
        
        var end_point := original_edge.get_end()
        var current_start_point := original_edge.get_start()
        var displacement := end_point - current_start_point
        var remaining_distance := abs(displacement.x)
        
        var horizontal_movement_sign := \
                -1 if \
                displacement.x < 0 else \
                1
        var movement_direction := horizontal_movement_sign * Vector2(1, 0)
        
        var main_jump_displacement := \
                main_jump_distance * movement_direction
        var fallback_jump_displacement := \
                fallback_jump_distance * movement_direction
        
        var calculator: JumpFromSurfaceCalculator = \
                Su.movement.edge_calculators["JumpFromSurfaceCalculator"]
        var velocity_start := JumpLandPositionsUtils.get_velocity_start(
                character.movement_params,
                surface,
                true,
                displacement.x < 0,
                false)
        
        # Add an in-between IntraSurface edge.
        var previous_velocity_end_x: float = \
                path.edges[i - 1].velocity_end.x if \
                i > 0 else \
                0.0
        var intra_surface_edge := IntraSurfaceEdge.new(
                original_edge.start_position_along_surface,
                original_edge.start_position_along_surface,
                Vector2(previous_velocity_end_x, 0.0),
                character.movement_params)
        new_edges.push_back(intra_surface_edge)
        
        while remaining_distance > close_enough_to_end_distance:
            var jump_origin := PositionAlongSurfaceFactory \
                    .create_position_offset_from_target_point(
                            current_start_point,
                            surface,
                            character.movement_params \
                                    .collider_half_width_height,
                            true)
            
            var possible_displacements := \
                    [main_jump_displacement, fallback_jump_displacement] if \
                    remaining_distance >= main_jump_distance else \
                    [fallback_jump_displacement] if \
                    remaining_distance >= fallback_jump_distance else \
                    [movement_direction * remaining_distance]
            
            var current_end_point: Vector2
            var jump_edge: JumpFromSurfaceEdge
            
            for jump_displacement in possible_displacements:
                current_end_point = current_start_point + jump_displacement
                var jump_destination := PositionAlongSurfaceFactory \
                        .create_position_offset_from_target_point(
                                current_end_point,
                                surface,
                                character.movement_params \
                                        .collider_half_width_height,
                                true)
                jump_edge = calculator.calculate_edge(
                        null,
                        character.graph.collision_params,
                        jump_origin,
                        jump_destination,
                        velocity_start)
                if jump_edge != null:
                    break
            
            if jump_edge != null:
                new_edges.push_back(jump_edge)
                
                # Add an in-between IntraSurface edge.
                previous_velocity_end_x = jump_edge.velocity_end.x
                intra_surface_edge = IntraSurfaceEdge.new(
                        jump_edge.end_position_along_surface,
                        jump_edge.end_position_along_surface,
                        Vector2(previous_velocity_end_x, 0.0),
                        character.movement_params)
                new_edges.push_back(intra_surface_edge)
            
            remaining_distance = abs(end_point.x - current_end_point.x)
            current_start_point = current_end_point
        
        if !was_last_edge:
            # If the path continues on after this, then replace the last
            # in-between intra-surface edge with one that will get us to the
            # original edge end point.
            intra_surface_edge = new_edges.back()
            intra_surface_edge = IntraSurfaceEdge.new(
                    intra_surface_edge.start_position_along_surface,
                    original_edge.end_position_along_surface,
                    intra_surface_edge.velocity_start,
                    character.movement_params)
            new_edges[new_edges.size() - 1] = intra_surface_edge
        
        if new_edges.size() > 1:
            # We created some new jumps, so replace the old edge with them.
            Sc.utils.splice(
                    path.edges,
                    i,
                    1,
                    new_edges)
            i += new_edges.size()
        else:
            # We weren't able to create any new jumps, so keep the old edge.
            i += 1
    
    path.update_distance_and_duration()
    
    return character.navigator.navigate_path(path)


#func _update_parameters() -> void:
#    ._update_parameters()
#
#    if _configuration_warning != "":
#        return
#
#    # FIXME: ----------------------------
#
#    _set_configuration_warning("")

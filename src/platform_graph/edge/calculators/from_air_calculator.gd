class_name FromAirCalculator
extends EdgeCalculator


const NAME := "FromAirCalculator"
const EDGE_TYPE := EdgeType.FROM_AIR_EDGE
const IS_A_JUMP_CALCULATOR := false
const IS_GRAPHABLE := false


func _init().(
        NAME,
        EDGE_TYPE,
        IS_A_JUMP_CALCULATOR,
        IS_GRAPHABLE) -> void:
    pass


func get_can_traverse_from_surface(
        surface: Surface,
        collision_params: CollisionCalcParams) -> bool:
    return surface == null


func get_all_inter_surface_edges_from_surface(
        inter_surface_edges_results: Array,
        collision_params: CollisionCalcParams,
        origin_surface: Surface,
        surfaces_in_fall_range_set: Dictionary,
        surfaces_in_jump_range_set: Dictionary) -> void:
    Sc.logger.error(
            "FromAirCalculator." +
            "get_all_inter_surface_edges_from_surface should not be called")


func calculate_edge(
        edge_result_metadata: EdgeCalcResultMetadata,
        collision_params: CollisionCalcParams,
        position_start: PositionAlongSurface,
        position_end: PositionAlongSurface,
        velocity_start := Vector2.INF,
        needs_extra_jump_duration := false,
        needs_extra_wall_land_horizontal_speed := false,
        basis_edge: EdgeAttempt = null) -> Edge:
    edge_result_metadata = \
            edge_result_metadata if \
            edge_result_metadata != null else \
            EdgeCalcResultMetadata.new(false, false)
    return find_a_landing_trajectory(
            edge_result_metadata,
            collision_params,
            {},
            position_start,
            velocity_start,
            false,
            position_end,
            position_end,
            needs_extra_wall_land_horizontal_speed)


func optimize_edge_land_position_for_path(
        collision_params: CollisionCalcParams,
        path: PlatformGraphPath,
        edge_index: int,
        edge: Edge,
        next_edge: IntraSurfaceEdge) -> void:
    assert(edge is FromAirEdge)
    
    EdgeCalculator.optimize_edge_land_position_for_path_helper(
            collision_params,
            path,
            edge_index,
            edge,
            next_edge,
            self)


# Finds a movement step that will result in landing on a surface, with an
# attempt to minimize the path the character would then have to travel between
# surfaces to reach the given target.
#
# Returns null if no possible landing exists.
func find_a_landing_trajectory(
        edge_result_metadata: EdgeCalcResultMetadata,
        collision_params: CollisionCalcParams,
        all_possible_surfaces_set: Dictionary,
        origin: PositionAlongSurface,
        velocity_start: Vector2,
        can_hold_jump_button_at_start: bool,
        goal: PositionAlongSurface,
        exclusive_land_position: PositionAlongSurface,
        needs_extra_wall_land_horizontal_speed := false) -> FromAirEdge:
    # TODO: Use goal param.
    
    assert(!needs_extra_wall_land_horizontal_speed or \
            exclusive_land_position != null)
    
    var calc_result: EdgeCalcResult
    if exclusive_land_position != null:
        calc_result = \
                FallMovementUtils.find_landing_trajectory_between_positions(
                        edge_result_metadata,
                        collision_params,
                        origin,
                        exclusive_land_position,
                        velocity_start,
                        can_hold_jump_button_at_start,
                        needs_extra_wall_land_horizontal_speed)
        if calc_result == null:
            return null
    else:
        # Find all possible surfaces in landing range.
        var result_set := {}
        FallMovementUtils.find_surfaces_in_fall_range_from_point(
                collision_params.movement_params,
                all_possible_surfaces_set,
                result_set,
                origin.target_point,
                velocity_start,
                can_hold_jump_button_at_start)
        var possible_landing_surfaces_from_point := result_set.keys()
        possible_landing_surfaces_from_point.sort_custom(
                SurfaceMaxYComparator,
                "sort")
        
        # Find the closest landing trajectory.
        var inter_surface_edges_results := []
        FallMovementUtils.find_landing_trajectories_to_any_surface(
                inter_surface_edges_results,
                collision_params,
                all_possible_surfaces_set,
                origin,
                velocity_start,
                can_hold_jump_button_at_start,
                self,
                false,
                possible_landing_surfaces_from_point,
                true)
        for inter_surface_edges_result in inter_surface_edges_results:
            if !inter_surface_edges_result.edge_calc_results.empty():
                calc_result = inter_surface_edges_result.edge_calc_results[0]
                break
        if calc_result == null:
            return null
    
    # Calculate instructions for the given landing trajectory.
    var land_position := calc_result.edge_calc_params.destination_position
    var instructions := EdgeInstructionsUtils \
            .convert_calculation_steps_to_movement_instructions(
                    false,
                    collision_params,
                    calc_result,
                    can_hold_jump_button_at_start,
                    land_position.side)
    var trajectory := \
            EdgeTrajectoryUtils.calculate_trajectory_from_calculation_steps(
                    false,
                    collision_params,
                    calc_result,
                    instructions)
    
    var velocity_end: Vector2 = \
            calc_result.horizontal_steps.back().velocity_step_end
    
    return FromAirEdge.new(
            self,
            origin,
            land_position,
            velocity_start,
            velocity_end,
            trajectory.distance_from_continuous_trajectory,
            instructions.duration,
            calc_result.edge_calc_params \
                    .needs_extra_wall_land_horizontal_speed,
            collision_params.movement_params,
            instructions,
            trajectory,
            calc_result.edge_calc_result_type,
            calc_result.vertical_step.time_peak_height)


# FIXME: ---------------------
# - Review this.
# - Add support for simulating the trajectory collision response when colliding
#   with a non-grabbable surface.
const MAX_FALL_DISTANCE_SQUARED_THRESHOLD := 1024.0 * 1024.0
func create_edge_from_current_fall_trajectory(
        collision_params: CollisionCalcParams,
        all_possible_surfaces_set: Dictionary,
        origin: PositionAlongSurface,
        velocity_start: Vector2) -> FromAirEdge:
    # FIXME: LEFT OFF HERE: --------------------------------
    # - MAX_FALL_DISTANCE_SQUARED_THRESHOLD
    return null
    
    var contact_position_along_surface
    var contact_velocity
    var instructions
    var trajectory
    var time_peak_height
    
#    return FromAirEdge.new(
#            self,
#            origin,
#            contact_position_along_surface,
#            velocity_start,
#            contact_velocity,
#            trajectory.distance_from_continuous_trajectory,
#            instructions.duration,
#            false,
#            collision_params.movement_params,
#            instructions,
#            trajectory,
#            EdgeCalcResultType.EDGE_VALID_WITH_ONE_STEP,
#            time_peak_height)


func create_edge_from_part_of_other_edge(
        other_edge: Edge,
        start_time: float,
        character) -> FromAirEdge:
    var trajectory_start_index := int(start_time / ScaffolderTime.PHYSICS_TIME_STEP)
    var trajectory_frame_count := \
            other_edge.trajectory.frame_continuous_positions_from_steps.size()
    
    if other_edge.trajectory == null or \
            trajectory_start_index >= trajectory_frame_count:
        # Some edges can enter the air but also don't have explicit
        # trajectories.
        return null
    
    var origin := PositionAlongSurfaceFactory.create_position_without_surface(
            character.surface_state.center_position)
    var instructions := EdgeInstructionsUtils.sub_instructions(
            other_edge.instructions,
            start_time)
    var trajectory := EdgeTrajectoryUtils.sub_trajectory(
            other_edge.trajectory,
            start_time)
    var time_peak_height: float = \
            max(other_edge.time_peak_height - start_time, 0.0)
    
    return FromAirEdge.new(
            self,
            origin,
            other_edge.end_position_along_surface,
            character.velocity,
            other_edge.velocity_end,
            trajectory.distance_from_continuous_trajectory,
            instructions.duration,
            other_edge.includes_extra_wall_land_horizontal_speed,
            other_edge.movement_params,
            instructions,
            trajectory,
            other_edge.edge_calc_result_type,
            time_peak_height)


class SurfaceMaxYComparator:
    static func sort(a: Surface, b: Surface) -> bool:
        return a.bounding_box.position.y < b.bounding_box.position.y

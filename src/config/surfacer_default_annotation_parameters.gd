tool
class_name SurfacerDefaultAnnotationParameters
extends Reference
## NOTE: Any color-related property should instead be found in
##       SurfacerDefaultColors.


var DEFAULTS := {
    ### Surface

    surface_alpha_ratio_with_inspector_open = 0.2,

    surface_depth = 16.0,

    surface_depth_divisions_count = 8,
    surface_alpha_end_ratio = 0.2,

    ### Edge

    edge_trajectory_width = 1.0,

    edge_waypoint_stroke_width = edge_trajectory_width,
    edge_waypoint_radius = 6.0 * edge_waypoint_stroke_width,
    edge_start_radius = 3.0 * edge_waypoint_stroke_width,
    edge_end_radius = edge_waypoint_radius,
    edge_end_cone_length = edge_waypoint_radius * 2.0,

    in_air_destination_indicator_cone_count = 3,
    in_air_destination_indicator_size_ratio = 0.8,

    includes_waypoints = true,
    includes_instruction_indicators = true,
    includes_continuous_positions = true,
    includes_discrete_positions = true,

    instruction_indicator_head_length_ratio = 0.35,
    instruction_indicator_head_width_ratio = 0.3,
    instruction_indicator_strike_trough_length_ratio = 0.8,
    instruction_indicator_stroke_width = edge_trajectory_width,

    edge_instruction_indicator_length = edge_trajectory_width * 24,

    path_downbeat_hash_length = edge_trajectory_width * 5.0,
    path_offbeat_hash_length = edge_trajectory_width * 3.0,

    adjacent_vertex_too_close_distance_squared_threshold = 0.25,

    ### FailedEdgeAttempt

    failed_edge_attempt_dash_length = 6.0,
    failed_edge_attempt_dash_gap = 8.0,
    failed_edge_attempt_dash_stroke_width = 2.0,
    failed_edge_attempt_x_width = 20.0,
    failed_edge_attempt_x_height = 28.0,

    failed_edge_attempt_includes_surfaces = false,

    ### EdgeStepCalcResultMetadata

    step_trajectory_stroke_width_faint = 1.0,
    step_trajectory_stroke_width_strong = 3.0,
    step_trajectory_dash_length = 2.0,
    step_trajectory_dash_gap = 8.0,

    invalid_edge_dash_length = failed_edge_attempt_dash_length,
    invalid_edge_dash_gap = failed_edge_attempt_dash_gap,
    invalid_edge_dash_stroke_width = failed_edge_attempt_dash_stroke_width,
    invalid_edge_x_width = failed_edge_attempt_x_width,
    invalid_edge_x_height = failed_edge_attempt_x_height,

    waypoint_radius = 6.0,
    waypoint_stroke_width_faint = waypoint_radius / 3.0,
    waypoint_stroke_width_strong = waypoint_stroke_width_faint * 2.0,
    previous_out_of_reach_waypoint_width_height = 15.0,
    valid_waypoint_width = 16.0,
    valid_waypoint_stroke_width = 2.0,
    invalid_waypoint_width = 12.0,
    invalid_waypoint_height = 16.0,
    invalid_waypoint_stroke_width = 2.0,

    collision_x_width_height = Vector2(16.0, 16.0),
    collision_x_stroke_width_faint = 2.0,
    collision_x_stroke_width_strong = 4.0,
    collision_character_boundary_stroke_width_faint = 1.0,
    collision_character_boundary_stroke_width_strong = 2.0,
    collision_character_boundary_center_radius = 3.0,
    collision_bounding_box_stroke_width = 1.0,
    collision_margin_stroke_width = 1.0,
    collision_margin_dash_length = 6.0,
    collision_margin_dash_gap = 10.0,

    label_offset = Vector2(15.0, -10.0),

    ### JumpLandPositions

    jump_land_positions_radius = 6.0,
    jump_land_positions_dash_length = 4.0,
    jump_land_positions_dash_gap = 4.0,
    jump_land_positions_dash_stroke_width = 1.0,

    ### Path preselection

    preselection_default_duration = 0.6,
    preselection_surface_depth: float = surface_depth + 4.0,
    preselection_surface_outward_offset = 4.0,
    preselection_surface_length_padding = 4.0,
    preselection_position_indicator_length = 128.0,
    preselection_position_indicator_radius = 32.0,
    preselection_path_stroke_width = 12.0,
    preselection_path_downbeat_hash_length = preselection_path_stroke_width * 5,
    preselection_path_offbeat_hash_length = preselection_path_stroke_width * 3,
    preselection_path_downbeat_stroke_width = preselection_path_stroke_width,
    preselection_path_offbeat_stroke_width = preselection_path_stroke_width,
    preselection_path_back_end_trim_radius = 0.0,

    ### Clicks

    click_surface_duration = 0.4,

    ### SurfaceNavigator

    navigator_trajectory_stroke_width = 4.0,
    navigator_pulse_stroke_width = navigator_trajectory_stroke_width * 3.0,

    navigator_origin_indicator_radius = 16.0,
    navigator_destination_indicator_length = 64.0,
    navigator_destination_indicator_radius = 16.0,

    navigator_indicator_stroke_width = navigator_trajectory_stroke_width,

    navigator_trajectory_downbeat_hash_length = \
            navigator_trajectory_stroke_width * 5,
    navigator_trajectory_offbeat_hash_length = \
            navigator_trajectory_stroke_width * 2,

    ### Platform graph inspector selector

    inspector_select_origin_surface_dash_length = 6.0,
    inspector_select_origin_surface_dash_gap = 8.0,
    inspector_select_origin_surface_dash_stroke_width = 4.0,

    inspector_select_origin_position_radius = 5.0,

    inspector_select_click_position_distance_squared_threshold = 10000,

    inspector_select_delay_for_tree_to_handle_inspector_selection_threshold = \
            0.6,

    ### Character position

    character_grab_position_line_width = 5.0,
    character_grab_position_line_length = 10.0,

    character_grab_tile_border_width = 6.0,

    character_position_along_surface_target_point_radius = 4.0,
    character_position_along_surface_t_length_in_surface = 0.0,
    character_position_along_surface_t_length_out_of_surface = 20.0,
    character_position_along_surface_t_width = 4.0,

    ### Polyline

    default_polyline_dash_length = 6.0,
    default_polyline_dash_gap = 8.0,
    default_polyline_stroke_width = 1.0,
}

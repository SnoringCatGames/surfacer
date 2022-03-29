tool
class_name SurfacerDefaultAnnotationParameters
extends Reference
## NOTE: Any color-related property should instead be found in
##       SurfacerDefaultColors.


### Surface

var surface_alpha_ratio_with_inspector_open := 0.2

var surface_depth := 16.0

var surface_depth_divisions_count := 8
var surface_alpha_end_ratio := 0.2

### Edge

var edge_trajectory_width := 1.0

var edge_waypoint_stroke_width := edge_trajectory_width
var edge_waypoint_radius := 6.0 * edge_waypoint_stroke_width
var edge_start_radius := 3.0 * edge_waypoint_stroke_width
var edge_end_radius := edge_waypoint_radius
var edge_end_cone_length := edge_waypoint_radius * 2.0

var in_air_destination_indicator_cone_count := 3
var in_air_destination_indicator_size_ratio := 0.8

var includes_waypoints := true
var includes_instruction_indicators := true
var includes_continuous_positions := true
var includes_discrete_positions := true

var instruction_indicator_head_length_ratio := 0.35
var instruction_indicator_head_width_ratio := 0.3
var instruction_indicator_strike_trough_length_ratio := 0.8
var instruction_indicator_stroke_width := edge_trajectory_width

var edge_instruction_indicator_length := edge_trajectory_width * 24

var path_downbeat_hash_length := edge_trajectory_width * 5.0
var path_offbeat_hash_length := edge_trajectory_width * 3.0

var adjacent_vertex_too_close_distance_squared_threshold := 0.25

### FailedEdgeAttempt

var failed_edge_attempt_dash_length := 6.0
var failed_edge_attempt_dash_gap := 8.0
var failed_edge_attempt_dash_stroke_width := 2.0
var failed_edge_attempt_x_width := 20.0
var failed_edge_attempt_x_height := 28.0

var failed_edge_attempt_includes_surfaces := false

### EdgeStepCalcResultMetadata

var step_trajectory_stroke_width_faint := 1.0
var step_trajectory_stroke_width_strong := 3.0
var step_trajectory_dash_length := 2.0
var step_trajectory_dash_gap := 8.0

var invalid_edge_dash_length := failed_edge_attempt_dash_length
var invalid_edge_dash_gap := failed_edge_attempt_dash_gap
var invalid_edge_dash_stroke_width := failed_edge_attempt_dash_stroke_width
var invalid_edge_x_width := failed_edge_attempt_x_width
var invalid_edge_x_height := failed_edge_attempt_x_height

var waypoint_radius := 6.0
var waypoint_stroke_width_faint := waypoint_radius / 3.0
var waypoint_stroke_width_strong := waypoint_stroke_width_faint * 2.0
var previous_out_of_reach_waypoint_width_height := 15.0
var valid_waypoint_width := 16.0
var valid_waypoint_stroke_width := 2.0
var invalid_waypoint_width := 12.0
var invalid_waypoint_height := 16.0
var invalid_waypoint_stroke_width := 2.0

var collision_x_width_height := Vector2(16.0, 16.0)
var collision_x_stroke_width_faint := 2.0
var collision_x_stroke_width_strong := 4.0
var collision_character_boundary_stroke_width_faint := 1.0
var collision_character_boundary_stroke_width_strong := 2.0
var collision_character_boundary_center_radius := 3.0
var collision_bounding_box_stroke_width := 1.0
var collision_margin_stroke_width := 1.0
var collision_margin_dash_length := 6.0
var collision_margin_dash_gap := 10.0

var label_offset := Vector2(15.0, -10.0)

### JumpLandPositions

var jump_land_positions_radius := 6.0
var jump_land_positions_dash_length := 4.0
var jump_land_positions_dash_gap := 4.0
var jump_land_positions_dash_stroke_width := 1.0

### Path preselection

var preselection_default_duration := 0.6
var preselection_surface_depth := surface_depth + 4.0
var preselection_surface_outward_offset := 4.0
var preselection_surface_length_padding := 4.0
var preselection_position_indicator_length := 128.0
var preselection_position_indicator_radius := 32.0
var preselection_path_stroke_width := 12.0
var preselection_path_downbeat_hash_length := preselection_path_stroke_width * 5
var preselection_path_offbeat_hash_length := preselection_path_stroke_width * 3
var preselection_path_downbeat_stroke_width := preselection_path_stroke_width
var preselection_path_offbeat_stroke_width := preselection_path_stroke_width
var preselection_path_back_end_trim_radius := 0.0

### Clicks

var click_surface_duration := 0.4

### SurfaceNavigator

var navigator_trajectory_stroke_width := 4.0
var navigator_pulse_stroke_width := navigator_trajectory_stroke_width * 3.0

var navigator_origin_indicator_radius := 16.0
var navigator_destination_indicator_length := 64.0
var navigator_destination_indicator_radius := 16.0

var navigator_indicator_stroke_width := navigator_trajectory_stroke_width

var navigator_trajectory_downbeat_hash_length := \
        navigator_trajectory_stroke_width * 5
var navigator_trajectory_offbeat_hash_length := \
        navigator_trajectory_stroke_width * 2

### Platform graph inspector selector

var inspector_select_origin_surface_dash_length := 6.0
var inspector_select_origin_surface_dash_gap := 8.0
var inspector_select_origin_surface_dash_stroke_width := 4.0

var inspector_select_origin_position_radius := 5.0

var inspector_select_click_position_distance_squared_threshold := 10000

var inspector_select_delay_for_tree_to_handle_inspector_selection_threshold := \
        0.6

### Character position

var character_grab_position_line_width := 5.0
var character_grab_position_line_length := 10.0

var character_grab_tile_border_width := 6.0

var character_position_along_surface_target_point_radius := 4.0
var character_position_along_surface_t_length_in_surface := 0.0
var character_position_along_surface_t_length_out_of_surface := 20.0
var character_position_along_surface_t_width := 4.0

### Polyline

var default_polyline_dash_length := 6.0
var default_polyline_dash_gap := 8.0
var default_polyline_stroke_width := 1.0

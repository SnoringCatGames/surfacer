tool
class_name SurfacerAnnotationParameters
extends ScaffolderAnnotationParameters


# TODO: Remove/refactor this class.

### Surface

var surface_hue_min := 0.0
var surface_hue_max := 1.0
var surface_saturation := 0.9
var surface_value := 0.8
var surface_alpha := 0.6

var surface_alpha_ratio_with_inspector_open := 0.2

var default_surface_hue := 0.23
var origin_surface_hue := 0.11
var destination_surface_hue := 0.61

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

var edge_hue_min := 0.0
var edge_hue_max := 1.0

var edge_discrete_trajectory_saturation := 0.8
var edge_discrete_trajectory_value := 0.9
var edge_discrete_trajectory_alpha := 0.8

var edge_continuous_trajectory_saturation := 0.6
var edge_continuous_trajectory_value := 0.6
var edge_continuous_trajectory_alpha := 0.7

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

### Waypoint

var waypoint_hue_min := 0.0
var waypoint_hue_max := 1.0
var waypoint_saturation := 0.6
var waypoint_value := 0.7
var waypoint_alpha := 0.7

### Instruction

var instruction_hue_min := 0.0
var instruction_hue_max := 1.0
var instruction_saturation := 0.3
var instruction_value := 0.9
var instruction_alpha := 0.7

### FailedEdgeAttempt

var failed_edge_attempt_saturation := 0.6
var failed_edge_attempt_value := 0.9
var failed_edge_attempt_opacity := 0.8

var failed_edge_attempt_dash_length := 6.0
var failed_edge_attempt_dash_gap := 8.0
var failed_edge_attempt_dash_stroke_width := 2.0
var failed_edge_attempt_x_width := 20.0
var failed_edge_attempt_x_height := 28.0

var failed_edge_attempt_includes_surfaces := false

### EdgeStepCalcResultMetadata

var step_hue_start := origin_surface_hue
var step_hue_end := destination_surface_hue
var step_saturation := 0.6
var step_value := 0.9
var step_opacity_faint := 0.2
var step_opacity_strong := 0.9

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

var collision_hue := 0.0
var collision_frame_start_hue := step_hue_start
var collision_frame_end_hue := step_hue_end
var collision_frame_previous_hue := 0.91
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

var jump_land_positions_hue_min := 0.0
var jump_land_positions_hue_max := 1.0
var jump_land_positions_saturation := 0.7
var jump_land_positions_value := 0.7
var jump_land_positions_alpha := 0.7

var jump_land_positions_radius := 6.0
var jump_land_positions_dash_length := 4.0
var jump_land_positions_dash_gap := 4.0
var jump_land_positions_dash_stroke_width := 1.0

### Path preselection

var preselection_invalid_surface_color := Sc.colors.opacify(
        Sc.colors.invalid,
        ScaffolderColors.ALPHA_XFAINT)
var preselection_invalid_position_indicator_color := Sc.colors.opacify(
        Sc.colors.invalid,
        ScaffolderColors.ALPHA_XFAINT)

var preselection_min_opacity := 0.5
var preselection_max_opacity := 1.0
var preselection_default_duration := 0.6
var preselection_surface_depth: float = surface_depth + 4.0
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

var click_valid_surface_color: Color = Sc.colors.surface_click_selection
var click_invalid_surface_color: Color = Sc.colors.opacify(
        Sc.colors.invalid,
        ScaffolderColors.ALPHA_SOLID)

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

var inspector_select_origin_surface_color: Color = \
        Sc.colors.inspector_origin

var inspector_select_origin_surface_dash_length := 6.0
var inspector_select_origin_surface_dash_gap := 8.0
var inspector_select_origin_surface_dash_stroke_width := 4.0

var inspector_select_origin_position_radius := 5.0

var inspector_select_click_position_distance_squared_threshold := 10000

var inspector_select_delay_for_tree_to_handle_inspector_selection_threshold := \
        0.6

### Character position

var character_grab_position_opacity := ScaffolderColors.ALPHA_XXFAINT
var character_grab_position_line_width := 5.0
var character_grab_position_line_length := 10.0

var character_position_along_surface_opacity := ScaffolderColors.ALPHA_XXFAINT
var character_position_along_surface_target_point_radius := 4.0
var character_position_along_surface_t_length_in_surface := 0.0
var character_position_along_surface_t_length_out_of_surface := 20.0
var character_position_along_surface_t_width := 4.0

### Polyline

var default_polyline_hue := default_surface_hue
var default_polyline_saturation := 0.6
var default_polyline_value := 0.9
var default_polyline_opacity := 0.8

var default_polyline_dash_length := 6.0
var default_polyline_dash_gap := 8.0
var default_polyline_stroke_width := 1.0

### Colors

var panel_background_color := Color.from_hsv(0.278, 0.17, 0.07, 1.0)
var inspector_description_item_background_color := \
        Color.from_hsv(0.278, 0.1, 0.1, 1.0)
var inspector_step_calc_item_background_color := \
        Color.from_hsv(0.61, 0.3, 0.2, 1.0)

var surface_color_params := \
        ColorParamsFactory.create_hsv_range_color_params_with_constant_sva(
                surface_hue_min,
                surface_hue_max,
                surface_saturation,
                surface_value,
                surface_alpha)
var default_surface_color_params := HsvColorParams.new(
        default_surface_hue,
        surface_saturation,
        surface_value,
        surface_alpha)
var origin_surface_color_params := HsvColorParams.new(
        origin_surface_hue,
        surface_saturation,
        surface_value,
        surface_alpha)
var destination_surface_color_params := HsvColorParams.new(
        destination_surface_hue,
        surface_saturation,
        surface_value,
        surface_alpha)

# - Lighter, more opaque.
# - More accurate to what is actually executed.
# - Less accurate to what is originally calculated.
var edge_discrete_trajectory_color_params := \
        ColorParamsFactory.create_hsv_range_color_params_with_constant_sva(
                edge_hue_min,
                edge_hue_max,
                edge_discrete_trajectory_saturation,
                edge_discrete_trajectory_value,
                edge_discrete_trajectory_alpha)
# - Darker, more transparent.
# - More accurate to what is originally calculated.
# - Less accurate to what is actually executed.
var edge_continuous_trajectory_color_params := \
        ColorParamsFactory.create_hsv_range_color_params_with_constant_sva(
                edge_hue_min,
                edge_hue_max,
                edge_continuous_trajectory_saturation,
                edge_continuous_trajectory_value,
                edge_continuous_trajectory_alpha)

var default_edge_discrete_trajectory_hue := default_surface_hue
var default_edge_discrete_trajectory_color_params := \
        HsvColorParams.new(
                default_edge_discrete_trajectory_hue,
                edge_discrete_trajectory_saturation,
                edge_discrete_trajectory_value,
                edge_discrete_trajectory_alpha)

var default_edge_continuous_trajectory_hue := \
        default_edge_discrete_trajectory_hue
var default_edge_continuous_trajectory_color_params := \
        HsvColorParams.new(
                default_edge_continuous_trajectory_hue,
                edge_continuous_trajectory_saturation,
                edge_continuous_trajectory_value,
                edge_continuous_trajectory_alpha)

var waypoint_color_params := \
        ColorParamsFactory.create_hsv_range_color_params_with_constant_sva(
                waypoint_hue_min,
                waypoint_hue_max,
                waypoint_saturation,
                waypoint_value,
                waypoint_alpha)

var default_waypoint_hue := default_edge_continuous_trajectory_hue
var default_waypoint_color_params := \
        HsvColorParams.new(
                default_waypoint_hue,
                waypoint_saturation,
                waypoint_value,
                waypoint_alpha)

var instruction_color_params := \
        ColorParamsFactory.create_hsv_range_color_params_with_constant_sva(
                instruction_hue_min,
                instruction_hue_max,
                instruction_saturation,
                instruction_value,
                instruction_alpha)

var default_instruction_hue := default_edge_continuous_trajectory_hue
var default_instruction_color_params := \
        HsvColorParams.new(
                default_instruction_hue,
                instruction_saturation,
                instruction_value,
                instruction_alpha)

var failed_edge_attempt_color_params := HsvColorParams.new(
        collision_hue,
        failed_edge_attempt_saturation,
        failed_edge_attempt_value,
        failed_edge_attempt_opacity)

var invalid_edge_color_params := HsvColorParams.new(
        collision_hue,
        step_saturation,
        step_value,
        step_opacity_strong)

var collision_color_faint := Color.from_hsv(
        collision_hue,
        step_saturation,
        step_value,
        step_opacity_faint)
var collision_color_strong := Color.from_hsv(
        collision_hue,
        step_saturation,
        step_value,
        step_opacity_strong)
var collision_frame_start_color := Color.from_hsv(
        collision_frame_start_hue,
        0.7,
        0.9,
        0.5)
var collision_frame_end_color := Color.from_hsv(
        collision_frame_end_hue,
        0.7,
        0.9,
        0.5)
var collision_frame_previous_color := Color.from_hsv(
        collision_frame_previous_hue,
        0.7,
        0.9,
        0.2)
var collision_just_before_collision_color := Color.from_hsv(
        collision_hue,
        0.5,
        0.6,
        0.2)
var collision_at_collision_color := Color.from_hsv(
        collision_hue,
        0.7,
        0.9,
        0.5)

var jump_land_positions_color_params := \
        ColorParamsFactory.create_hsv_range_color_params_with_constant_sva(
                jump_land_positions_hue_min,
                jump_land_positions_hue_max,
                jump_land_positions_saturation,
                jump_land_positions_value,
                jump_land_positions_alpha)

var default_jump_land_positions_hue := default_edge_continuous_trajectory_hue
var default_jump_land_positions_color_params := \
        HsvColorParams.new(
                default_jump_land_positions_hue,
                jump_land_positions_saturation,
                jump_land_positions_value,
                jump_land_positions_alpha)

var default_polyline_color_params := HsvColorParams.new(
        default_polyline_hue,
        default_polyline_saturation,
        default_polyline_value,
        default_polyline_opacity)
var fall_range_polygon_color_params := HsvColorParams.new(
        destination_surface_hue,
        default_polyline_saturation,
        default_polyline_value,
        default_polyline_opacity)

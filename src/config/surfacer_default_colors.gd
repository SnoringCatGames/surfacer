tool
class_name SurfacerDefaultColors
extends Reference


### GUIs

var surface_click_selection := \
        ColorFactory.opacify("white", ColorConfig.ALPHA_SOLID)
var grid_indices := ColorFactory.opacify("white", ColorConfig.ALPHA_FAINT)
var invalid := ColorFactory.palette("red")
var inspector_origin := ColorFactory.opacify("orange", ColorConfig.ALPHA_FAINT)

### Annotations

# Surface

var surface_hue_min := 0.0
var surface_hue_max := 1.0
var surface_saturation := 0.9
var surface_value := 0.8
var surface_alpha := 0.6

var default_surface_hue := 0.23
var origin_surface_hue := 0.11
var destination_surface_hue := 0.61

# Edge

var edge_hue_min := 0.0
var edge_hue_max := 1.0

var edge_discrete_trajectory_saturation := 0.8
var edge_discrete_trajectory_value := 0.9
var edge_discrete_trajectory_alpha := 0.8

var edge_continuous_trajectory_saturation := 0.6
var edge_continuous_trajectory_value := 0.6
var edge_continuous_trajectory_alpha := 0.7

# Waypoint

var waypoint_hue_min := 0.0
var waypoint_hue_max := 1.0
var waypoint_saturation := 0.6
var waypoint_value := 0.7
var waypoint_alpha := 0.7

# Instruction

var instruction_hue_min := 0.0
var instruction_hue_max := 1.0
var instruction_saturation := 0.3
var instruction_value := 0.9
var instruction_alpha := 0.7

# FailedEdgeAttempt

var failed_edge_attempt_saturation := 0.6
var failed_edge_attempt_value := 0.9
var failed_edge_attempt_opacity := 0.8

# EdgeStepCalcResultMetadata

var step_hue_start := origin_surface_hue
var step_hue_end := destination_surface_hue
var step_saturation := 0.6
var step_value := 0.9
var step_opacity_faint := 0.2
var step_opacity_strong := 0.9

var collision_hue := 0.0
var collision_frame_start_hue := step_hue_start
var collision_frame_end_hue := step_hue_end
var collision_frame_previous_hue := 0.91

# JumpLandPositions
var jump_land_positions_hue_min := 0.0
var jump_land_positions_hue_max := 1.0
var jump_land_positions_saturation := 0.7
var jump_land_positions_value := 0.7
var jump_land_positions_alpha := 0.7

# Path preselection

var preselection_invalid_surface_color := \
        ColorFactory.opacify("invalid", ColorConfig.ALPHA_XFAINT)
var preselection_invalid_position_indicator_color := \
        ColorFactory.opacify("invalid", ColorConfig.ALPHA_XFAINT)

var preselection_surface_opacity := ColorConfig.ALPHA_XFAINT
var preselection_indicator_opacity := ColorConfig.ALPHA_XFAINT
var preselection_path_opacity := ColorConfig.ALPHA_XFAINT
var preselection_hash_opacity := ColorConfig.ALPHA_XFAINT

var preselection_min_opacity := 0.5
var preselection_max_opacity := 1.0

# Clicks

var click_valid_surface_color := ColorFactory.palette("surface_click_selection")
var click_invalid_surface_color := \
        ColorFactory.opacify("invalid", ColorConfig.ALPHA_SOLID)

# Platform graph inspector selector

var inspector_select_origin_surface_color := \
        ColorFactory.palette("inspector_origin")

# Character position

var character_grab_position_opacity := ColorConfig.ALPHA_XXFAINT
var character_grab_position_line_width := 5.0
var character_grab_position_line_length := 10.0

var character_grab_tile_border_opacity := ColorConfig.ALPHA_XFAINT
var character_grab_tile_border_width := 6.0

var character_position_along_surface_opacity := ColorConfig.ALPHA_XXFAINT

# Polyline

var default_polyline_hue := default_surface_hue
var default_polyline_saturation := 0.6
var default_polyline_value := 0.9
var default_polyline_opacity := 0.8

# Colors

var panel_background_color := Color.from_hsv(0.278, 0.17, 0.07, 1.0)
var inspector_description_item_background_color := \
        Color.from_hsv(0.278, 0.1, 0.1, 1.0)
var inspector_step_calc_item_background_color := \
        Color.from_hsv(0.61, 0.3, 0.2, 1.0)

var surface_color := ColorFactory.h_range(
        surface_hue_min,
        surface_hue_max,
        surface_saturation,
        surface_value,
        surface_alpha)
var default_surface_color := ColorFactory.hsv(
        default_surface_hue,
        surface_saturation,
        surface_value,
        surface_alpha)
var origin_surface_color := ColorFactory.hsv(
        origin_surface_hue,
        surface_saturation,
        surface_value,
        surface_alpha)
var destination_surface_color := ColorFactory.hsv(
        destination_surface_hue,
        surface_saturation,
        surface_value,
        surface_alpha)

# - Lighter, more opaque.
# - More accurate to what is actually executed.
# - Less accurate to what is originally calculated.
var edge_discrete_trajectory_color := ColorFactory.h_range(
        edge_hue_min,
        edge_hue_max,
        edge_discrete_trajectory_saturation,
        edge_discrete_trajectory_value,
        edge_discrete_trajectory_alpha)
# - Darker, more transparent.
# - More accurate to what is originally calculated.
# - Less accurate to what is actually executed.
var edge_continuous_trajectory_color := ColorFactory.h_range(
        edge_hue_min,
        edge_hue_max,
        edge_continuous_trajectory_saturation,
        edge_continuous_trajectory_value,
        edge_continuous_trajectory_alpha)

var default_edge_discrete_trajectory_hue := default_surface_hue
var default_edge_discrete_trajectory_color := ColorFactory.hsv(
        default_edge_discrete_trajectory_hue,
        edge_discrete_trajectory_saturation,
        edge_discrete_trajectory_value,
        edge_discrete_trajectory_alpha)

var default_edge_continuous_trajectory_hue := \
        default_edge_discrete_trajectory_hue
var default_edge_continuous_trajectory_color := ColorFactory.hsv(
        default_edge_continuous_trajectory_hue,
        edge_continuous_trajectory_saturation,
        edge_continuous_trajectory_value,
        edge_continuous_trajectory_alpha)

var waypoint_color := ColorFactory.h_range(
        waypoint_hue_min,
        waypoint_hue_max,
        waypoint_saturation,
        waypoint_value,
        waypoint_alpha)

var default_waypoint_hue := default_edge_continuous_trajectory_hue
var default_waypoint_color := ColorFactory.hsv(
        default_waypoint_hue,
        waypoint_saturation,
        waypoint_value,
        waypoint_alpha)

var instruction_color := ColorFactory.h_range(
        instruction_hue_min,
        instruction_hue_max,
        instruction_saturation,
        instruction_value,
        instruction_alpha)

var default_instruction_hue := default_edge_continuous_trajectory_hue
var default_instruction_color := ColorFactory.hsv(
        default_instruction_hue,
        instruction_saturation,
        instruction_value,
        instruction_alpha)

var failed_edge_attempt_color := ColorFactory.hsv(
        collision_hue,
        failed_edge_attempt_saturation,
        failed_edge_attempt_value,
        failed_edge_attempt_opacity)

var invalid_edge_color := ColorFactory.hsv(
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

var jump_land_positions_color := ColorFactory.h_range(
        jump_land_positions_hue_min,
        jump_land_positions_hue_max,
        jump_land_positions_saturation,
        jump_land_positions_value,
        jump_land_positions_alpha)

var default_jump_land_positions_hue := default_edge_continuous_trajectory_hue
var default_jump_land_positions_color := \
        ColorFactory.hsv(
                default_jump_land_positions_hue,
                jump_land_positions_saturation,
                jump_land_positions_value,
                jump_land_positions_alpha)

var default_polyline_color := ColorFactory.hsv(
        default_polyline_hue,
        default_polyline_saturation,
        default_polyline_value,
        default_polyline_opacity)
var fall_range_polygon_color := ColorFactory.hsv(
        destination_surface_hue,
        default_polyline_saturation,
        default_polyline_value,
        default_polyline_opacity)

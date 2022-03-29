tool
class_name SurfacerDefaultColors
extends Reference


var DEFAULTS := {
    ### Surface

    surface_hue_min = 0.0,
    surface_hue_max = 1.0,
    surface_saturation = 0.9,
    surface_value = 0.8,
    surface_alpha = 0.6,

    default_surface_hue = 0.23,
    origin_surface_hue = 0.11,
    destination_surface_hue = 0.61,

    ### Edge

    edge_hue_min = 0.0,
    edge_hue_max = 1.0,

    edge_discrete_trajectory_saturation = 0.8,
    edge_discrete_trajectory_value = 0.9,
    edge_discrete_trajectory_alpha = 0.8,

    edge_continuous_trajectory_saturation = 0.6,
    edge_continuous_trajectory_value = 0.6,
    edge_continuous_trajectory_alpha = 0.7,

    ### Waypoint

    waypoint_hue_min = 0.0,
    waypoint_hue_max = 1.0,
    waypoint_saturation = 0.6,
    waypoint_value = 0.7,
    waypoint_alpha = 0.7,

    ### Instruction

    instruction_hue_min = 0.0,
    instruction_hue_max = 1.0,
    instruction_saturation = 0.3,
    instruction_value = 0.9,
    instruction_alpha = 0.7,

    ### FailedEdgeAttempt

    failed_edge_attempt_saturation = 0.6,
    failed_edge_attempt_value = 0.9,
    failed_edge_attempt_opacity = 0.8,

    ### EdgeStepCalcResultMetadata

    step_hue_start = origin_surface_hue,
    step_hue_end = destination_surface_hue,
    step_saturation = 0.6,
    step_value = 0.9,
    step_opacity_faint = 0.2,
    step_opacity_strong = 0.9,

    collision_hue = 0.0,
    collision_frame_start_hue = step_hue_start,
    collision_frame_end_hue = step_hue_end,
    collision_frame_previous_hue = 0.91,

    ### JumpLandPositions

    jump_land_positions_hue_min = 0.0,
    jump_land_positions_hue_max = 1.0,
    jump_land_positions_saturation = 0.7,
    jump_land_positions_value = 0.7,
    jump_land_positions_alpha = 0.7,

    ### Path preselection

    preselection_invalid_surface_color = \
            ColorFactory.opacify("invalid", ColorConfig.ALPHA_XFAINT),
    preselection_invalid_position_indicator_color = \
            ColorFactory.opacify("invalid", ColorConfig.ALPHA_XFAINT),

    preselection_surface_opacity = ColorConfig.ALPHA_XFAINT,
    preselection_indicator_opacity = ColorConfig.ALPHA_XFAINT,
    preselection_path_opacity = ColorConfig.ALPHA_XFAINT,
    preselection_hash_opacity = ColorConfig.ALPHA_XFAINT,

    preselection_min_opacity = 0.5,
    preselection_max_opacity = 1.0,

    ### Clicks

    click_valid_surface_color = ColorFactory.palette("surface_click_selection"),
    click_invalid_surface_color = \
            ColorFactory.opacify("invalid", ColorConfig.ALPHA_SOLID),

    ### Platform graph inspector selector

    inspector_select_origin_surface_color = \
            ColorFactory.palette("inspector_origin"),

    ### Character position

    character_grab_position_opacity = ColorConfig.ALPHA_XXFAINT,
    character_grab_position_line_width = 5.0,
    character_grab_position_line_length = 10.0,

    character_grab_tile_border_opacity = ColorConfig.ALPHA_XFAINT,
    character_grab_tile_border_width = 6.0,

    character_position_along_surface_opacity = ColorConfig.ALPHA_XXFAINT,

    ### Polyline

    default_polyline_hue = default_surface_hue,
    default_polyline_saturation = 0.6,
    default_polyline_value = 0.9,
    default_polyline_opacity = 0.8,

    ### Colors

    panel_background_color = Color.from_hsv(0.278, 0.17, 0.07, 1.0),
    inspector_description_item_background_color = \
            Color.from_hsv(0.278, 0.1, 0.1, 1.0),
    inspector_step_calc_item_background_color = \
            Color.from_hsv(0.61, 0.3, 0.2, 1.0),

    surface_color_config = ColorFactory.h_range(
            surface_hue_min,
            surface_hue_max,
            surface_saturation,
            surface_value,
            surface_alpha),
    default_surface_color_config = ColorFactory.hsv(
            default_surface_hue,
            surface_saturation,
            surface_value,
            surface_alpha),
    origin_surface_color_config = ColorFactory.hsv(
            origin_surface_hue,
            surface_saturation,
            surface_value,
            surface_alpha),
    destination_surface_color_config = ColorFactory.hsv(
            destination_surface_hue,
            surface_saturation,
            surface_value,
            surface_alpha),

    # - Lighter, more opaque.
    # - More accurate to what is actually executed.
    # - Less accurate to what is originally calculated.
    edge_discrete_trajectory_color_config = ColorFactory.h_range(
            edge_hue_min,
            edge_hue_max,
            edge_discrete_trajectory_saturation,
            edge_discrete_trajectory_value,
            edge_discrete_trajectory_alpha),
    # - Darker, more transparent.
    # - More accurate to what is originally calculated.
    # - Less accurate to what is actually executed.
    edge_continuous_trajectory_color_config = ColorFactory.h_range(
            edge_hue_min,
            edge_hue_max,
            edge_continuous_trajectory_saturation,
            edge_continuous_trajectory_value,
            edge_continuous_trajectory_alpha),

    default_edge_discrete_trajectory_hue = default_surface_hue,
    default_edge_discrete_trajectory_color_config = ColorFactory.hsv(
            default_edge_discrete_trajectory_hue,
            edge_discrete_trajectory_saturation,
            edge_discrete_trajectory_value,
            edge_discrete_trajectory_alpha),

    default_edge_continuous_trajectory_hue = \
            default_edge_discrete_trajectory_hue,
    default_edge_continuous_trajectory_color_config = ColorFactory.hsv(
            default_edge_continuous_trajectory_hue,
            edge_continuous_trajectory_saturation,
            edge_continuous_trajectory_value,
            edge_continuous_trajectory_alpha),

    waypoint_color_config = ColorFactory.h_range(
            waypoint_hue_min,
            waypoint_hue_max,
            waypoint_saturation,
            waypoint_value,
            waypoint_alpha),

    default_waypoint_hue = default_edge_continuous_trajectory_hue,
    default_waypoint_color_config = ColorFactory.hsv(
            default_waypoint_hue,
            waypoint_saturation,
            waypoint_value,
            waypoint_alpha),

    instruction_color_config = ColorFactory.h_range(
            instruction_hue_min,
            instruction_hue_max,
            instruction_saturation,
            instruction_value,
            instruction_alpha),

    default_instruction_hue = default_edge_continuous_trajectory_hue,
    default_instruction_color_config = ColorFactory.hsv(
            default_instruction_hue,
            instruction_saturation,
            instruction_value,
            instruction_alpha),

    failed_edge_attempt_color_config = ColorFactory.hsv(
            collision_hue,
            failed_edge_attempt_saturation,
            failed_edge_attempt_value,
            failed_edge_attempt_opacity),

    invalid_edge_color_config = ColorFactory.hsv(
            collision_hue,
            step_saturation,
            step_value,
            step_opacity_strong),

    collision_color_faint = Color.from_hsv(
            collision_hue,
            step_saturation,
            step_value,
            step_opacity_faint),
    collision_color_strong = Color.from_hsv(
            collision_hue,
            step_saturation,
            step_value,
            step_opacity_strong),
    collision_frame_start_color = Color.from_hsv(
            collision_frame_start_hue,
            0.7,
            0.9,
            0.5),
    collision_frame_end_color = Color.from_hsv(
            collision_frame_end_hue,
            0.7,
            0.9,
            0.5),
    collision_frame_previous_color = Color.from_hsv(
            collision_frame_previous_hue,
            0.7,
            0.9,
            0.2),
    collision_just_before_collision_color = Color.from_hsv(
            collision_hue,
            0.5,
            0.6,
            0.2),
    collision_at_collision_color = Color.from_hsv(
            collision_hue,
            0.7,
            0.9,
            0.5),

    jump_land_positions_color_config = ColorFactory.h_range(
            jump_land_positions_hue_min,
            jump_land_positions_hue_max,
            jump_land_positions_saturation,
            jump_land_positions_value,
            jump_land_positions_alpha),

    default_jump_land_positions_hue = default_edge_continuous_trajectory_hue,
    default_jump_land_positions_color_config = \
            ColorFactory.hsv(
                    default_jump_land_positions_hue,
                    jump_land_positions_saturation,
                    jump_land_positions_value,
                    jump_land_positions_alpha),

    default_polyline_color_config = ColorFactory.hsv(
            default_polyline_hue,
            default_polyline_saturation,
            default_polyline_value,
            default_polyline_opacity),
    fall_range_polygon_color_config = ColorFactory.hsv(
            destination_surface_hue,
            default_polyline_saturation,
            default_polyline_value,
            default_polyline_opacity),
}

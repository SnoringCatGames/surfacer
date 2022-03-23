tool
class_name SurfacerSchema
extends FrameworkSchema


const _METADATA_SCRIPT := SurfacerMetadata

var _surfacer_debug_params := {}

var _annotations_manifest := {
    is_player_preselection_trajectory_shown = true,
    
    is_player_slow_mo_trajectory_shown = false,
    is_player_non_slow_mo_trajectory_shown = true,
    is_player_previous_trajectory_shown = false,
    is_player_navigation_destination_shown = true,
    is_player_nav_pulse_shown = false,
    
    is_npc_slow_mo_trajectory_shown = true,
    is_npc_non_slow_mo_trajectory_shown = false,
    is_npc_previous_trajectory_shown = false,
    is_npc_navigation_destination_shown = false,
    is_npc_nav_pulse_shown = true,
    
    does_player_nav_pulse_grow = false,
    is_player_prediction_shown = true,
    
    does_npc_nav_pulse_grow = true,
    is_npc_prediction_shown = true,
    
    nav_selection_prediction_opacity = 0.5,
    nav_selection_prediction_tween_duration = 0.15,
    new_path_pulse_duration = 0.7,
    new_path_pulse_time_length = 1.0,
}

var _surface_properties_manifest := {
    "default": {
        can_grab = true,
        friction_multiplier = 0.7,
        speed_multiplier = 1.0,
    },
    "disabled": {
        can_grab = false,
    },
    "slippery": {
        friction_multiplier = 0.05,
    },
    "sticky": {
        friction_multiplier = 4.0,
    },
    "fast": {
        speed_multiplier = 4.0,
    },
    "slow": {
        speed_multiplier = 0.2,
    },
}

# FIXME: LEFT OFF HERE: --------------------------------------------
# - Use this in Surfacer.
var _tileset_manifest := {
    tilesets = [
        {
            tiles = [
                {
                    name = "old_0_tile_with_90s",
                    angle = CellAngleType.A90,
                    properties = "",
                    is_collidable = true,
                },
                {
                    name = "old_1_tile_with_45s",
                    angle = CellAngleType.A45,
                    properties = "",
                    is_collidable = true,
                },
                {
                    name = "old_2_tile_with_27s",
                    angle = CellAngleType.A27,
                    properties = "",
                    is_collidable = true,
                },
                {
                    name = "ungrabbable_tile",
                    angle = CellAngleType.A90,
                    properties = "disabled",
                    is_collidable = true,
                },
                {
                    name = "slippery_tile",
                    angle = CellAngleType.A90,
                    properties = "slippery",
                    is_collidable = true,
                },
                {
                    name = "sticky_tile",
                    angle = CellAngleType.A90,
                    properties = "sticky",
                    is_collidable = true,
                },
                {
                    name = "fast_tile",
                    angle = CellAngleType.A90,
                    properties = "fast",
                    is_collidable = true,
                },
                {
                    name = "slow_tile",
                    angle = CellAngleType.A90,
                    properties = "slow",
                    is_collidable = true,
                },
                
                # FIXME: ----------------- REMOVE
                {
                    name = "old_0_tile_with_90s_old",
                    angle = CellAngleType.A90,
                    properties = "",
                    is_collidable = true,
                },
                {
                    name = "old_1_tile_with_45s_old",
                    angle = CellAngleType.A45,
                    properties = "",
                    is_collidable = true,
                },
            ],
        },
    ],
}

var _movement_manifest := {
    uses_point_and_click_navigation = true,
    cancels_point_and_click_nav_on_key_press = true,
    
    gravity_default = 5000.0,
    gravity_slow_rise_multiplier_default = 0.38,
    gravity_double_jump_slow_rise_multiplier_default = 0.68,
    walk_acceleration_default = 8000.0,
    in_air_horizontal_acceleration_default = 2500.0,
    climb_up_speed_default = -230.0,
    climb_down_speed_default = 120.0,
    ceiling_crawl_speed_default = 230.0,
    friction_coeff_with_sideways_input_default = 1.0,
    friction_coeff_without_sideways_input_default = 1.25,
    jump_boost_default = -900.0,
    wall_jump_horizontal_boost_default = 200.0,
    wall_fall_horizontal_boost_default = 20.0,
    
    max_horizontal_speed_default_default = 320.0,
    max_vertical_speed_default = 2800.0,
    min_horizontal_speed = 5.0,
    min_vertical_speed = 0.0,
    
    dash_speed_multiplier_default = 3.0,
    dash_vertical_boost_default = -300.0,
    dash_duration_default = 0.3,
    dash_fade_duration_default = 0.1,
    dash_cooldown_default = 1.0,
    
    additional_edge_weight_offset_default = 0.0,
    walking_edge_weight_multiplier_default = 1.2,
    ceiling_crawling_edge_weight_multiplier_default = 2.0,
    climbing_edge_weight_multiplier_default = 1.8,
    climb_to_adjacent_surface_edge_weight_multiplier_default = 1.0,
    move_to_collinear_surface_edge_weight_multiplier_default = 0.0,
    air_edge_weight_multiplier_default = 1.0,
    
    action_handler_classes = \
            SurfacerMovementManifest.DEFAULT_ACTION_HANDLER_CLASSES,
    edge_calculator_classes = \
            SurfacerMovementManifest.DEFAULT_EDGE_CALCULATOR_CLASSES,
}

var _properties := {
    are_oddly_shaped_surfaces_used = true,
    
    precompute_platform_graph_for_levels = [
        [TYPE_STRING, ""],
    ],
    ignores_platform_graph_save_files = false,
    ignores_platform_graph_save_file_trajectory_state = false,
    is_debug_only_platform_graph_state_included = false,
    are_reachable_surfaces_per_player_tracked = true,
    are_loaded_surfaces_deeply_validated = true,
    uses_threads_for_platform_graph_calculation = false,
    
    default_tileset = preload( \
            "res://addons/surfacer/src/tiles/tileset_with_many_angles.tres"),
    path_drag_update_throttle_interval = 0.2,
    path_beat_update_throttle_interval = 0.2,
    
    # Params for CameraPanController.
    snaps_camera_back_to_character = true,
    max_zoom_multiplier_from_pointer = 1.5,
    max_pan_distance_from_pointer = 512.0,
    duration_to_max_pan_from_pointer_at_max_control = 0.67,
    duration_to_max_zoom_from_pointer_at_max_control = 3.0,
    screen_size_ratio_distance_from_edge_to_start_pan_from_pointer = 0.16,
    
    skip_choreography_framerate_multiplier = 4.0,
    
    debug_params = _surfacer_debug_params,
    
    surface_properties_manifest = _surface_properties_manifest,
    movement_manifest = _movement_manifest,
    annotations_manifest = _annotations_manifest,
    tileset_manifest = _tileset_manifest
}


func _init().(_METADATA_SCRIPT, _properties) -> void:
    pass
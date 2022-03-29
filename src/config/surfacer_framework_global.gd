tool
class_name SurfacerFrameworkGlobal
extends FrameworkGlobal


const BACKGROUND_COLOR_TO_EMPHASIZE_ANNOTATIONS := Color("20222A")

func _get_common_overrides_for_release_mode() -> Array:
    var debug: bool = \
            Sc.modes.get_is_active("release", "local_dev") and \
            OS.is_debug_build()
    var playtest: bool = Sc.modes.get_is_active("release", "playtest")
    
    var overrides := [
        ["Sc.manifest.metadata.pauses_on_focus_out",
                Sc.manifest.metadata.pauses_on_focus_out and !debug],
        ["Sc.manifest.metadata.are_all_levels_unlocked",
                Sc.manifest.metadata.are_all_levels_unlocked and debug],
        ["Sc.manifest.metadata.are_test_levels_included",
                Sc.manifest.metadata.are_test_levels_included and \
                (debug or playtest)],
        ["Sc.manifest.metadata.is_save_state_cleared_for_debugging",
                Sc.manifest.metadata.is_save_state_cleared_for_debugging and \
                (debug or playtest)],
        ["Sc.manifest.metadata.opens_directly_to_level_id",
                Sc.manifest.metadata.opens_directly_to_level_id if debug else ""],
        ["Sc.manifest.metadata.is_splash_skipped",
                (Sc.manifest.metadata.is_splash_skipped or \
                Sc.manifest.metadata.opens_directly_to_level_id != "") and debug],
        ["Sc.manifest.metadata.are_button_controls_enabled_by_default",
                Sc.manifest.metadata.are_button_controls_enabled_by_default or debug],
        ["Sc.manifest.metadata.logs_character_events",
                Sc.manifest.metadata.logs_character_events and debug],
        ["Sc.manifest.metadata.logs_analytics_events",
                Sc.manifest.metadata.logs_analytics_events or !debug],
        ["Sc.manifest.metadata.logs_bootstrap_events",
                Sc.manifest.metadata.logs_bootstrap_events or !debug],
        ["Sc.manifest.metadata.logs_device_settings",
                Sc.manifest.metadata.logs_device_settings or !debug],
        ["Sc.manifest.metadata.also_prints_to_stdout",
                Sc.manifest.metadata.also_prints_to_stdout and \
                debug],
        
        ["Sc.manifest.gui_manifest.hud_manifest.is_inspector_enabled_default",
                Sc.manifest.gui_manifest.hud_manifest.is_inspector_enabled_default or \
                debug or \
                playtest],
    ]
    for entry in overrides:
        entry.push_back("release")
    return overrides


func _get_common_overrides_for_annotations_mode() -> Array:
    var are_annotations_emphasized: bool = \
            Sc.modes.get_is_active("annotations", "emphasized")
    if !are_annotations_emphasized:
        return []
    
    var overrides := [
        ["Sc.manifest.colors_manifest.background",
                BACKGROUND_COLOR_TO_EMPHASIZE_ANNOTATIONS],
        ["Sc.manifest.annotation_parameters_manifest.edge_trajectory_width", 2.0],
        ["Sc.manifest.annotation_parameters_manifest.edge_waypoint_stroke_width",
                SurfacerDefaultAnnotationParameters.edge_trajectory_width],
        ["Sc.manifest.annotation_parameters_manifest.path_downbeat_hash_length",
                SurfacerDefaultAnnotationParameters.edge_trajectory_width * 5.0],
        ["Sc.manifest.annotation_parameters_manifest.path_offbeat_hash_length",
                SurfacerDefaultAnnotationParameters.edge_trajectory_width * 3.0],
        ["Sc.manifest.annotation_parameters_manifest.instruction_indicator_stroke_width",
                SurfacerDefaultAnnotationParameters.edge_trajectory_width],
        ["Sc.manifest.annotation_parameters_manifest.edge_instruction_indicator_length",
                SurfacerDefaultAnnotationParameters.edge_trajectory_width * 24.0],
        ["Sc.manifest.annotation_parameters_manifest.surface_alpha_ratio_with_inspector_open", 0.99],

        ["Sc.manifest.annotation_parameters_manifest.edge_hue_min", 0.0],
        ["Sc.manifest.annotation_parameters_manifest.edge_hue_max", 1.0],
        ["Sc.manifest.annotation_parameters_manifest.edge_discrete_trajectory_saturation", 0.8],
        ["Sc.manifest.annotation_parameters_manifest.edge_discrete_trajectory_value", 0.9],
        ["Sc.manifest.annotation_parameters_manifest.edge_discrete_trajectory_alpha", 0.8],
#        ["Sc.manifest.annotation_parameters_manifest.edge_discrete_trajectory_alpha", 0.0],
        ["Sc.manifest.annotation_parameters_manifest.edge_continuous_trajectory_saturation", 0.6],
        ["Sc.manifest.annotation_parameters_manifest.edge_continuous_trajectory_value", 0.6],
        ["Sc.manifest.annotation_parameters_manifest.edge_continuous_trajectory_alpha", 0.8],
        ["Sc.manifest.annotation_parameters_manifest.waypoint_hue_min", 0.0],
        ["Sc.manifest.annotation_parameters_manifest.waypoint_hue_max", 1.0],
        ["Sc.manifest.annotation_parameters_manifest.waypoint_saturation", 0.6],
        ["Sc.manifest.annotation_parameters_manifest.waypoint_value", 0.7],
        ["Sc.manifest.annotation_parameters_manifest.waypoint_alpha", 0.7],
        ["Sc.manifest.annotation_parameters_manifest.instruction_hue_min", 0.0],
        ["Sc.manifest.annotation_parameters_manifest.instruction_hue_max", 1.0],
        ["Sc.manifest.annotation_parameters_manifest.instruction_saturation", 0.3],
        ["Sc.manifest.annotation_parameters_manifest.instruction_value", 0.9],
        ["Sc.manifest.annotation_parameters_manifest.instruction_alpha", 0.9],
#        ["Sc.manifest.annotation_parameters_manifest.instruction_alpha", 0.0],
        ["Sc.manifest.colors_manifest.edge_discrete_trajectory_color",
                ColorFactory.h_range(
                        SurfacerDefaultColors.edge_hue_min,
                        SurfacerDefaultColors.edge_hue_max,
                        SurfacerDefaultColors.edge_discrete_trajectory_saturation,
                        SurfacerDefaultColors.edge_discrete_trajectory_value,
                        SurfacerDefaultColors.edge_discrete_trajectory_alpha)],
        ["Sc.manifest.colors_manifest.edge_continuous_trajectory_color",
                ColorFactory.h_range(
                        SurfacerDefaultColors.edge_hue_min,
                        SurfacerDefaultColors.edge_hue_max,
                        SurfacerDefaultColors.edge_continuous_trajectory_saturation,
                        SurfacerDefaultColors.edge_continuous_trajectory_value,
                        SurfacerDefaultColors.edge_continuous_trajectory_alpha)],
        ["Sc.manifest.colors_manifest.waypoint_color",
                ColorFactory.h_range(
                        SurfacerDefaultColors.waypoint_hue_min,
                        SurfacerDefaultColors.waypoint_hue_max,
                        SurfacerDefaultColors.waypoint_saturation,
                        SurfacerDefaultColors.waypoint_value,
                        SurfacerDefaultColors.waypoint_alpha)],
        ["Sc.manifest.colors_manifest.instruction_color",
                ColorFactory.h_range(
                        SurfacerDefaultColors.instruction_hue_min,
                        SurfacerDefaultColors.instruction_hue_max,
                        SurfacerDefaultColors.instruction_saturation,
                        SurfacerDefaultColors.instruction_value,
                        SurfacerDefaultColors.instruction_alpha)],

        ["Sc.manifest.annotation_parameters_manifest.preselection_min_opacity", 0.8],
        ["Sc.manifest.annotation_parameters_manifest.preselection_max_opacity", 1.0],
        ["Sc.manifest.annotation_parameters_manifest.preselection_surface_opacity", 0.6],
        ["Sc.manifest.annotation_parameters_manifest.preselection_indicator_opacity", 0.6],
        ["Sc.manifest.annotation_parameters_manifest.preselection_path_opacity", 0.6],
        ["Sc.manifest.annotation_parameters_manifest.preselection_hash_opacity", 0.3],
#        ["Sc.manifest.annotation_parameters_manifest.preselection_hash_opacity", 0.0],

        ["Sc.manifest.annotation_parameters_manifest.recent_movement_opacity_newest", 0.99],
#        ["Sc.manifest.annotation_parameters_manifest.recent_movement_opacity_newest", 0.0],
        ["Sc.manifest.annotation_parameters_manifest.recent_movement_opacity_oldest", 0.0],

        ["Sc.manifest.annotation_parameters_manifest.character_position_opacity", 0.0],
        ["Sc.manifest.annotation_parameters_manifest.character_collider_opacity", 0.95],
        ["Sc.manifest.annotation_parameters_manifest.character_grab_position_opacity", 0.0],
        ["Sc.manifest.annotation_parameters_manifest.character_position_along_surface_opacity", 0.0],
        ["Sc.manifest.annotation_parameters_manifest.character_grab_tile_border_opacity", 0.0],
    ]
    for entry in overrides:
        entry.push_back("annotations")
    return overrides


func _init(schema_class).(schema_class) -> void:
    pass

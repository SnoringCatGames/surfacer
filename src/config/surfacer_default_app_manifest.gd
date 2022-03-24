tool
class_name SurfacerDefaultAppManifest
extends FrameworkGlobal


# ---

func _derive_overrides_according_to_debug_or_playtest(
        manifest: Dictionary) -> void:
    var metadata: Dictionary = manifest.metadata
    var is_debug: bool = metadata.debug
    var is_playtest: bool = metadata.playtest
    metadata.pauses_on_focus_out = \
            metadata.pauses_on_focus_out or !is_debug
    metadata.are_all_levels_unlocked = \
            metadata.are_all_levels_unlocked and is_debug
    metadata.are_test_levels_included = \
            metadata.are_test_levels_included and \
            (is_debug or is_playtest)
    metadata.is_save_state_cleared_for_debugging = \
            metadata.is_save_state_cleared_for_debugging and \
            (is_debug or is_playtest)
    metadata.opens_directly_to_level_id = \
            metadata.opens_directly_to_level_id if is_debug else ""
    metadata.is_splash_skipped = \
            (metadata.is_splash_skipped or \
            metadata.opens_directly_to_level_id != "") and is_debug
    metadata.are_button_controls_enabled_by_default = \
            metadata.are_button_controls_enabled_by_default or is_debug
    metadata.logs_character_events = \
            metadata.logs_character_events and is_debug
    metadata.logs_analytics_events = \
            metadata.logs_analytics_events or !is_debug
    metadata.logs_bootstrap_events = \
            metadata.logs_bootstrap_events or !is_debug
    metadata.logs_device_settings = \
            metadata.logs_device_settings or !is_debug
    metadata.also_prints_to_stdout = \
            metadata.also_prints_to_stdout and \
            is_debug
    
    manifest.gui_manifest.hud_manifest.is_inspector_enabled_default = \
            manifest.gui_manifest.hud_manifest.is_inspector_enabled_default or \
            is_debug or \
            is_playtest


func _update_to_emphasize_annotations(manifest: Dictionary) -> void:
    manifest.colors_manifest.background = \
            BACKGROUND_COLOR_TO_EMPHASIZE_ANNOTATIONS
    
    var ann_params_man: Dictionary = manifest.annotation_parameters_manifest
    
    ann_params_man.edge_trajectory_width = 2.0
    ann_params_man.edge_waypoint_stroke_width = \
            ann_params_man.edge_trajectory_width
    ann_params_man.path_downbeat_hash_length = \
            ann_params_man.edge_trajectory_width * 5.0
    ann_params_man.path_offbeat_hash_length = \
            ann_params_man.edge_trajectory_width * 3.0
    ann_params_man.instruction_indicator_stroke_width = \
            ann_params_man.edge_trajectory_width
    ann_params_man.edge_instruction_indicator_length = \
            ann_params_man.edge_trajectory_width * 24.0
    ann_params_man.surface_alpha_ratio_with_inspector_open = 0.99
    
    ann_params_man.edge_hue_min = 0.0
    ann_params_man.edge_hue_max = 1.0
    ann_params_man.edge_discrete_trajectory_saturation = 0.8
    ann_params_man.edge_discrete_trajectory_value = 0.9
    ann_params_man.edge_discrete_trajectory_alpha = 0.8
#    ann_params_man.edge_discrete_trajectory_alpha = 0.0
    ann_params_man.edge_continuous_trajectory_saturation = 0.6
    ann_params_man.edge_continuous_trajectory_value = 0.6
    ann_params_man.edge_continuous_trajectory_alpha = 0.8
    ann_params_man.waypoint_hue_min = 0.0
    ann_params_man.waypoint_hue_max = 1.0
    ann_params_man.waypoint_saturation = 0.6
    ann_params_man.waypoint_value = 0.7
    ann_params_man.waypoint_alpha = 0.7
    ann_params_man.instruction_hue_min = 0.0
    ann_params_man.instruction_hue_max = 1.0
    ann_params_man.instruction_saturation = 0.3
    ann_params_man.instruction_value = 0.9
    ann_params_man.instruction_alpha = 0.9
#    ann_params_man.instruction_alpha = 0.0
    ann_params_man.edge_discrete_trajectory_color_params = \
            ColorParamsFactory.create_hsv_range_color_params_with_constant_sva(
                    ann_params_man.edge_hue_min,
                    ann_params_man.edge_hue_max,
                    ann_params_man.edge_discrete_trajectory_saturation,
                    ann_params_man.edge_discrete_trajectory_value,
                    ann_params_man.edge_discrete_trajectory_alpha)
    ann_params_man.edge_continuous_trajectory_color_params = \
            ColorParamsFactory.create_hsv_range_color_params_with_constant_sva(
                    ann_params_man.edge_hue_min,
                    ann_params_man.edge_hue_max,
                    ann_params_man.edge_continuous_trajectory_saturation,
                    ann_params_man.edge_continuous_trajectory_value,
                    ann_params_man.edge_continuous_trajectory_alpha)
    ann_params_man.waypoint_color_params = \
            ColorParamsFactory.create_hsv_range_color_params_with_constant_sva(
                    ann_params_man.waypoint_hue_min,
                    ann_params_man.waypoint_hue_max,
                    ann_params_man.waypoint_saturation,
                    ann_params_man.waypoint_value,
                    ann_params_man.waypoint_alpha)
    ann_params_man.instruction_color_params = \
            ColorParamsFactory.create_hsv_range_color_params_with_constant_sva(
                    ann_params_man.instruction_hue_min,
                    ann_params_man.instruction_hue_max,
                    ann_params_man.instruction_saturation,
                    ann_params_man.instruction_value,
                    ann_params_man.instruction_alpha)
    
    ann_params_man.preselection_min_opacity = 0.8
    ann_params_man.preselection_max_opacity = 1.0
    ann_params_man.preselection_surface_opacity = 0.6
    ann_params_man.preselection_indicator_opacity = 0.6
    ann_params_man.preselection_path_opacity = 0.6
    ann_params_man.preselection_hash_opacity = 0.3
#    ann_params_man.preselection_hash_opacity = 0.0
    
    ann_params_man.recent_movement_opacity_newest = 0.99
#    ann_params_man.recent_movement_opacity_newest = 0.0
    ann_params_man.recent_movement_opacity_oldest = 0.0
    
    ann_params_man.character_position_opacity = 0.0
    ann_params_man.character_collider_opacity = 0.95
    ann_params_man.character_grab_position_opacity = 0.0
    ann_params_man.character_position_along_surface_opacity = 0.0
    ann_params_man.character_grab_tile_border_opacity = 0.0


# ---

const BACKGROUND_COLOR_TO_EMPHASIZE_ANNOTATIONS := Color("20222A")

var _default_settings_item_manifest := {
    groups = {
        main = {
            label = "",
            is_collapsible = false,
            item_classes = [
                MusicControlRow,
                SoundEffectsControlRow,
                HapticFeedbackControlRow,
            ],
        },
        annotations = {
            label = "Rendering",
            is_collapsible = true,
            item_classes = [
                RulerAnnotatorControlRow,
                PlayerPreselectionTrajectoryAnnotatorControlRow,
                PlayerSlowMoTrajectoryAnnotatorControlRow,
                PlayerNonSlowMoTrajectoryAnnotatorControlRow,
                PlayerPreviousTrajectoryAnnotatorControlRow,
                PlayerNavigationDestinationAnnotatorControlRow,
                NpcSlowMoTrajectoryAnnotatorControlRow,
                NpcNonSlowMoTrajectoryAnnotatorControlRow,
                NpcPreviousTrajectoryAnnotatorControlRow,
                NpcNavigationDestinationAnnotatorControlRow,
                RecentMovementAnnotatorControlRow,
                SurfacesAnnotatorControlRow,
                CharacterPositionAnnotatorControlRow,
                CharacterAnnotatorControlRow,
                LevelAnnotatorControlRow,
            ],
        },
        hud = {
            label = "HUD",
            is_collapsible = true,
            item_classes = [
                InspectorEnabledControlRow,
                DebugPanelControlRow,
            ],
        },
        miscellaneous = {
            label = "Miscellaneous",
            is_collapsible = true,
            item_classes = [
                ButtonControlsControlRow,
                WelcomePanelControlRow,
                IntroChoreographyControlRow,
                CameraZoomControlRow,
                TimeScaleControlRow,
                MetronomeControlRow,
            ],
        },
    },
}

var _default_pause_item_manifest := [
    LevelControlRow,
    TimeControlRow,
]

var _default_game_over_item_manifest := [
    LevelControlRow,
    TimeControlRow,
]

var _default_level_select_item_manifest := [
    TotalPlaysControlRow,
]

var _default_hud_manifest := {
    hud_class = SurfacerHud,
    hud_key_value_box_size = \
            ScaffolderGuiConfig.HUD_KEY_VALUE_BOX_DEFAULT_SIZE,
    hud_key_value_box_scene = \
            preload("res://addons/scaffolder/src/gui/hud/hud_key_value_box.tscn"),
    hud_key_value_list_scene = \
            preload("res://addons/scaffolder/src/gui/hud/hud_key_value_list.tscn"),
    hud_key_value_list_item_manifest = [
        {
            item_class = TimeControlRow,
            settings_enablement_label = "ScaffolderTime",
            enabled_by_default = true,
            settings_group_key = "hud",
        },
    ],
    is_inspector_enabled_default = false,
    inspector_panel_starts_open = false,
}

var _default_welcome_panel_manifest := {
    items = [
        ["*Auto nav*", "click"],
        ["Walk/Climb", "arrow key / wasd"],
        ["Jump", "space / x"],
    ],
    header_color = [
    ],
    body_color = [
    ],
}

var _default_screen_manifest := {
    screens = [
        preload("res://addons/scaffolder/src/gui/screens/about_screen.tscn"),
        preload("res://addons/scaffolder/src/gui/screens/data_agreement_screen.tscn"),
        preload("res://addons/scaffolder/src/gui/screens/developer_splash_screen.tscn"),
        preload("res://addons/scaffolder/src/gui/screens/game_screen.tscn"),
        preload("res://addons/scaffolder/src/gui/screens/game_over_screen.tscn"),
        preload("res://addons/scaffolder/src/gui/screens/godot_splash_screen.tscn"),
        preload("res://addons/scaffolder/src/gui/screens/level_select_screen.tscn"),
        preload("res://addons/scaffolder/src/gui/screens/main_menu_screen.tscn"),
        preload("res://addons/scaffolder/src/gui/screens/notification_screen.tscn"),
        preload("res://addons/scaffolder/src/gui/screens/pause_screen.tscn"),
        preload("res://addons/scaffolder/src/gui/screens/scaffolder_loading_screen.tscn"),
        preload("res://addons/scaffolder/src/gui/screens/settings_screen.tscn"),
        preload("res://addons/scaffolder/src/gui/screens/third_party_licenses_screen.tscn"),
        preload("res://addons/surfacer/src/gui/screens/precompute_platform_graphs_screen.tscn"),
        preload("res://addons/surfacer/src/gui/screens/surfacer_loading_screen.tscn"),
        preload("res://addons/scaffolder/src/gui/screens/confirm_data_deletion_screen_local.tscn"),
#        preload("res://addons/scaffolder/src/gui/screens/scaffolder_loading_screen.tscn"),
#        preload("res://addons/scaffolder/src/gui/screens/confirm_data_deletion_screen_with_analytics.tscn"),
#        preload("res://addons/scaffolder/src/gui/screens/rate_app_screen.tscn"),
    ],
    overlay_mask_transition_fade_in_texture = \
            preload("res://addons/scaffolder/assets/images/transition_masks/radial_mask_transition_in.png"),
    overlay_mask_transition_fade_out_texture = \
            preload("res://addons/scaffolder/assets/images/transition_masks/radial_mask_transition_in.png"),
    screen_mask_transition_fade_texture = \
            preload("res://addons/scaffolder/assets/images/transition_masks/checkers_mask_transition.png"),
    overlay_mask_transition_class = OverlayMaskTransition,
    screen_mask_transition_class = ScreenMaskTransition,
    slide_transition_duration = 0.3,
    fade_transition_duration = 0.3,
    overlay_mask_transition_duration = 1.2,
    screen_mask_transition_duration = 1.2,
    slide_transition_easing = "ease_in_out",
    fade_transition_easing = "ease_in_out",
    overlay_mask_transition_fade_in_easing = "ease_out",
    overlay_mask_transition_fade_out_easing = "ease_in",
    screen_mask_transition_easing = "ease_in",
    default_transition_type = ScreenTransition.FADE,
    fancy_transition_type = ScreenTransition.SCREEN_MASK,
    overlay_mask_transition_color = Color("111111"),
    overlay_mask_transition_uses_pixel_snap = false,
    overlay_mask_transition_smooth_size = 0.02,
    screen_mask_transition_uses_pixel_snap = true,
    screen_mask_transition_smooth_size = 0.0,
}

var _default_slow_motion_manifest := {
    time_scale = 0.5,
    tick_tock_tempo_multiplier = 1,
    saturation = 0.5,
}

var _default_input_map = ScaffolderProjectSettings.DEFAULT_INPUT_MAP

# ---


func _init(schema_class).(schema_class) -> void:
    pass

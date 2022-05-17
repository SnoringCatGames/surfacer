tool
class_name SurfacerSchema
extends FrameworkSchema


const _METADATA_SCRIPT := SurfacerMetadata

var _surfacer_debug_params := {}

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

const DEFAULT_ACTION_HANDLER_CLASSES := [
    preload("res://addons/surfacer/src/character/action/action_handlers/air_dash_action.gd"),
    preload("res://addons/surfacer/src/character/action/action_handlers/air_default_action.gd"),
    preload("res://addons/surfacer/src/character/action/action_handlers/air_jump_action.gd"),
    preload("res://addons/surfacer/src/character/action/action_handlers/all_default_action.gd"),
    preload("res://addons/surfacer/src/character/action/action_handlers/cap_velocity_action.gd"),
    preload("res://addons/surfacer/src/character/action/action_handlers/ceiling_crawl_action.gd"),
    preload("res://addons/surfacer/src/character/action/action_handlers/ceiling_default_action.gd"),
    preload("res://addons/surfacer/src/character/action/action_handlers/ceiling_fall_action.gd"),
    preload("res://addons/surfacer/src/character/action/action_handlers/ceiling_jump_down_action.gd"),
    preload("res://addons/surfacer/src/character/action/action_handlers/floor_dash_action.gd"),
    preload("res://addons/surfacer/src/character/action/action_handlers/floor_default_action.gd"),
    preload("res://addons/surfacer/src/character/action/action_handlers/fall_through_floor_action.gd"),
    preload("res://addons/surfacer/src/character/action/action_handlers/floor_friction_action.gd"),
    preload("res://addons/surfacer/src/character/action/action_handlers/floor_jump_action.gd"),
    preload("res://addons/surfacer/src/character/action/action_handlers/floor_walk_action.gd"),
    preload("res://addons/surfacer/src/character/action/action_handlers/wall_climb_action.gd"),
    preload("res://addons/surfacer/src/character/action/action_handlers/wall_dash_action.gd"),
    preload("res://addons/surfacer/src/character/action/action_handlers/wall_default_action.gd"),
    preload("res://addons/surfacer/src/character/action/action_handlers/wall_fall_action.gd"),
    preload("res://addons/surfacer/src/character/action/action_handlers/wall_jump_action.gd"),
]

const DEFAULT_EDGE_CALCULATOR_CLASSES := [
    preload("res://addons/surfacer/src/platform_graph/edge/calculators/from_air_calculator.gd"),
    preload("res://addons/surfacer/src/platform_graph/edge/calculators/climb_to_adjacent_surface_calculator.gd"),
    preload("res://addons/surfacer/src/platform_graph/edge/calculators/fall_from_floor_calculator.gd"),
    preload("res://addons/surfacer/src/platform_graph/edge/calculators/fall_from_wall_calculator.gd"),
    preload("res://addons/surfacer/src/platform_graph/edge/calculators/intra_surface_calculator.gd"),
    preload("res://addons/surfacer/src/platform_graph/edge/calculators/jump_from_surface_calculator.gd"),
]

var _movement_manifest := {
    uses_point_and_click_navigation = true,
    do_player_actions_interrupt_navigation = true,
    
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
    
    action_handler_classes = DEFAULT_ACTION_HANDLER_CLASSES,
    edge_calculator_classes = DEFAULT_EDGE_CALCULATOR_CLASSES,
}

var _behavior_classes := [
    NavigationOverrideBehavior,
    ClimbAdjacentSurfacesBehavior,
    CollideBehavior,
    FollowBehavior,
    MoveBackAndForthBehavior,
    StaticBehavior,
    ReturnBehavior,
    RunAwayBehavior,
    PlayerNavigationBehavior,
    WanderBehavior,
]

var _camera_manifest := {
    default_camera_class = NavigationPreselectionCamera,
    snaps_camera_back_to_character = true,
    max_zoom_from_pointer = 1.5,
    max_pan_distance_from_pointer = 512.0,
    duration_to_max_pan_from_pointer_at_max_control = 0.67,
    duration_to_max_zoom_from_pointer_at_max_control = 3.0,
    screen_size_ratio_distance_from_edge_to_start_pan_from_pointer = 0.16,
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
    
    cancel_active_player_control_on_invalid_nav_selection = false,
    
    default_tileset = preload( \
            "res://addons/surfacer/src/tiles/tileset_with_many_angles.tres"),
    path_drag_update_throttle_interval = 0.2,
    path_beat_update_throttle_interval = 0.2,
    
    skip_choreography_framerate_multiplier = 4.0,
    
    debug_params = _surfacer_debug_params,
    
    surface_properties_manifest = _surface_properties_manifest,
    movement_manifest = _movement_manifest,
    behavior_classes = _behavior_classes,
}

const WELCOME_PANEL_ITEM_AUTO_NAV := ["*Auto nav*", "click"]
const WELCOME_PANEL_ITEM_INSPECT_GRAPH := ["Inspect graph", "ctrl + click (x2)"]

const DEFAULT_TILESET_CONFIG := {
    recalculate_tileset = [TYPE_CUSTOM, RecalculateTilesetCustomProperty],
    tile_set = preload("res://addons/surfacer/src/tiles/demo_tileset.tres"),
    quadrant_size = 16,
    corner_match_tiles = [
        {
            outer_autotile_name = "autotile",
            inner_autotile_name = "__inner_autotile__",
            tileset_quadrants_path = \
                "res://addons/surface_tiler/assets/images/tileset_quadrants.png",
            tile_corner_type_annotations_path = \
                "res://addons/surface_tiler/assets/images/tileset_corner_type_annotations.png",
            subtile_collision_margin = 3.0,
            are_45_degree_subtiles_used = true,
            are_27_degree_subtiles_used = false,
            properties = "default",
            is_collidable = true,
        },
    ],
    non_corner_match_tiles = [
        {
            name = "ungrabbable_tile",
            properties = "disabled",
            is_collidable = true,
        },
        {
            name = "slippery_tile",
            properties = "slippery",
            is_collidable = true,
        },
        {
            name = "sticky_tile",
            properties = "sticky",
            is_collidable = true,
        },
        {
            name = "fast_tile",
            properties = "fast",
            is_collidable = true,
        },
        {
            name = "slow_tile",
            properties = "slow",
            is_collidable = true,
        },
    ],
}

var _additive_overrides := {
    ScaffolderSchema: {
        colors_manifest = \
            Utils.get_direct_color_properties(SurfacerDefaultColors.new()),
        annotation_parameters_manifest = Sc.utils.merge(
            Utils.get_direct_non_color_properties(
                SurfacerDefaultAnnotationParameters.new()),
            Utils.get_direct_non_color_properties(
                SurfacerDefaultColors.new())),
        audio_manifest = {
            sounds_manifest = [
                {
                    name = "nav_select_fail",
                    volume_db = 0.0,
                    path_prefix = "res://addons/surfacer/assets/sounds/",
                },
                {
                    name = "nav_select_success",
                    volume_db = 0.0,
                    path_prefix = "res://addons/surfacer/assets/sounds/",
                },
                {
                    name = "slow_down",
                    volume_db = 0.0,
                    path_prefix = "res://addons/surfacer/assets/sounds/",
                },
                {
                    name = "speed_up",
                    volume_db = 0.0,
                    path_prefix = "res://addons/surfacer/assets/sounds/",
                },
                {
                    name = "tick",
                    volume_db = -6.0,
                    path_prefix = "res://addons/surfacer/assets/sounds/",
                },
                {
                    name = "tock_low",
                    volume_db = -6.0,
                    path_prefix = "res://addons/surfacer/assets/sounds/",
                },
                {
                    name = "tock_high",
                    volume_db = -6.0,
                    path_prefix = "res://addons/surfacer/assets/sounds/",
                },
                {
                    name = "tock_higher",
                    volume_db = -6.0,
                    path_prefix = "res://addons/surfacer/assets/sounds/",
                },
            ],
        },
        gui_manifest = {
            third_party_license_text = \
                    ScaffolderThirdPartyLicenses.TEXT + \
                    SurfaceTilerThirdPartyLicenses.TEXT + \
                    SurfacerThirdPartyLicenses.TEXT,
            settings_item_manifest = {
                groups = {
                    annotations = {
                        item_classes = [
                            # FIXME: ------------ Include some of these in the surface_parser framework too.
                            PlayerPreselectionTrajectoryAnnotatorControlRow,
                            PlayerSlowMoTrajectoryAnnotatorControlRow,
                            PlayerNonSlowMoTrajectoryAnnotatorControlRow,
                            PlayerPreviousTrajectoryAnnotatorControlRow,
                            PlayerNavigationDestinationAnnotatorControlRow,
                            NpcSlowMoTrajectoryAnnotatorControlRow,
                            NpcNonSlowMoTrajectoryAnnotatorControlRow,
                            NpcPreviousTrajectoryAnnotatorControlRow,
                            NpcNavigationDestinationAnnotatorControlRow,
                            SurfacesAnnotatorControlRow,
                            CharacterPositionAnnotatorControlRow,
                        ],
                    },
                    hud = {
                        item_classes = [
                            InspectorEnabledControlRow,
                        ],
                    },
                    miscellaneous = {
                        item_classes = [
                            IntroChoreographyControlRow,
                        ],
                    },
                },
            },
            hud_manifest = {
                hud_class = SurfacerHud,
                is_inspector_enabled_default = false,
                inspector_panel_starts_open = false,
            },
            welcome_panel_manifest = {
                items = [
                    WELCOME_PANEL_ITEM_AUTO_NAV,
#                    WELCOME_PANEL_ITEM_INSPECT_GRAPH,
                ],
            },
            screen_manifest = {
                screens = [
                    preload("res://addons/surfacer/src/gui/screens/precompute_platform_graphs_screen.tscn"),
                    preload("res://addons/surfacer/src/gui/screens/surfacer_loading_screen.tscn"),
                ],
            },
        },
        camera_manifest = _camera_manifest,
        geometry_class = SurfacerGeometry,
        draw_class = SurfacerDrawUtils,
        annotators_class = SurfacerAnnotators,
        beats_class = SurfacerBeatTracker,
        characters_class = SurfacerCharacterManifest,
        camera_manifest_class = SurfacerCameraManifest,
    },
    SurfaceTilerSchema: {
        tileset_initializer_class = SurfacesTilesetInitializer,
        tilesets = [
            DEFAULT_TILESET_CONFIG,
        ],
    },
}

var _subtractive_overrides := {
    ScaffolderSchema: {
        gui_manifest = {
            settings_item_manifest = {
                groups = {
                    annotations = {
                        item_classes = [
                        ],
                    },
                },
            },
        },
    },
    SurfaceTilerSchema: {
        tilesets = [
            SurfaceTilerSchema.DEFAULT_TILESET_CONFIG,
        ],
    },
}


func _init().(
        _METADATA_SCRIPT,
        _properties,
        _additive_overrides,
        _subtractive_overrides) -> void:
    pass

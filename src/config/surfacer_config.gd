class_name SurfacerConfig
extends Node


# --- Constants ---

const WALLS_AND_FLOORS_COLLISION_MASK_BIT := 0
const FALL_THROUGH_FLOORS_COLLISION_MASK_BIT := 1
const WALK_THROUGH_WALLS_COLLISION_MASK_BIT := 2

const IS_INSPECTOR_ENABLED_SETTINGS_KEY := "is_inspector_enabled"
const IS_SURFACER_LOGGING_SETTINGS_KEY := "is_surfacer_logging"
const IS_METRONOME_ENABLED_SETTINGS_KEY := "is_metronome_enabled"
const IS_INTRO_CHOREOGRAPHY_SHOWN_SETTINGS_KEY := "is_intro_choreography_shown"
const ACTIVE_TRAJECTORY_SHOWN_SETTINGS_KEY := "is_active_trajectory_shown"
const PREVIOUS_TRAJECTORY_SHOWN_SETTINGS_KEY := "is_previous_trajectory_shown"
const PRESELECTION_TRAJECTORY_SHOWN_SETTINGS_KEY := \
        "is_preselection_trajectory_shown"
const NAVIGATION_DESTINATION_SHOWN_SETTINGS_KEY := \
        "is_navigation_destination_shown"

const DEFAULT_PLAYER_ACTION_CLASSES := [
    preload("res://addons/surfacer/src/player/action/action_handlers/air_dash_action.gd"),
    preload("res://addons/surfacer/src/player/action/action_handlers/air_default_action.gd"),
    preload("res://addons/surfacer/src/player/action/action_handlers/air_jump_action.gd"),
    preload("res://addons/surfacer/src/player/action/action_handlers/all_default_action.gd"),
    preload("res://addons/surfacer/src/player/action/action_handlers/cap_velocity_action.gd"),
    preload("res://addons/surfacer/src/player/action/action_handlers/floor_dash_action.gd"),
    preload("res://addons/surfacer/src/player/action/action_handlers/floor_default_action.gd"),
    preload("res://addons/surfacer/src/player/action/action_handlers/fall_through_floor_action.gd"),
    preload("res://addons/surfacer/src/player/action/action_handlers/floor_friction_action.gd"),
    preload("res://addons/surfacer/src/player/action/action_handlers/floor_jump_action.gd"),
    preload("res://addons/surfacer/src/player/action/action_handlers/floor_walk_action.gd"),
    preload("res://addons/surfacer/src/player/action/action_handlers/match_expected_edge_trajectory_action.gd"),
    preload("res://addons/surfacer/src/player/action/action_handlers/wall_climb_action.gd"),
    preload("res://addons/surfacer/src/player/action/action_handlers/wall_dash_action.gd"),
    preload("res://addons/surfacer/src/player/action/action_handlers/wall_default_action.gd"),
    preload("res://addons/surfacer/src/player/action/action_handlers/wall_fall_action.gd"),
    preload("res://addons/surfacer/src/player/action/action_handlers/wall_jump_action.gd"),
    preload("res://addons/surfacer/src/player/action/action_handlers/wall_walk_action.gd"),
]

const DEFAULT_EDGE_MOVEMENT_CLASSES := [
    preload("res://addons/surfacer/src/platform_graph/edge/calculators/from_air_calculator.gd"),
    preload("res://addons/surfacer/src/platform_graph/edge/calculators/climb_down_wall_to_floor_calculator.gd"),
    preload("res://addons/surfacer/src/platform_graph/edge/calculators/climb_over_wall_to_floor_calculator.gd"),
    preload("res://addons/surfacer/src/platform_graph/edge/calculators/fall_from_floor_calculator.gd"),
    preload("res://addons/surfacer/src/platform_graph/edge/calculators/fall_from_wall_calculator.gd"),
    preload("res://addons/surfacer/src/platform_graph/edge/calculators/jump_from_surface_calculator.gd"),
    preload("res://addons/surfacer/src/platform_graph/edge/calculators/walk_to_ascend_wall_from_floor_calculator.gd"),
]

var DEFAULT_SURFACER_SETTINGS_ITEM_MANIFEST := {
    groups = {
        main = {
            label = "",
            is_collapsible = false,
            item_classes = [
                MusicSettingsLabeledControlItem,
                SoundEffectsSettingsLabeledControlItem,
                HapticFeedbackSettingsLabeledControlItem,
            ],
        },
        annotations = {
            label = "Rendering",
            is_collapsible = true,
            item_classes = [
                RulerAnnotatorSettingsLabeledControlItem,
                PreselectionTrajectoryAnnotatorSettingsLabeledControlItem,
                ActiveTrajectoryAnnotatorSettingsLabeledControlItem,
                PreviousTrajectoryAnnotatorSettingsLabeledControlItem,
                NavigationDestinationAnnotatorSettingsLabeledControlItem,
                RecentMovementAnnotatorSettingsLabeledControlItem,
                SurfacesAnnotatorSettingsLabeledControlItem,
                PlayerPositionAnnotatorSettingsLabeledControlItem,
                PlayerAnnotatorSettingsLabeledControlItem,
                LevelAnnotatorSettingsLabeledControlItem,
            ],
        },
        hud = {
            label = "HUD",
            is_collapsible = true,
            item_classes = [
                InspectorEnabledSettingsLabeledControlItem,
                DebugPanelSettingsLabeledControlItem,
            ],
        },
        miscellaneous = {
            label = "Miscellaneous",
            is_collapsible = true,
            item_classes = [
                WelcomePanelSettingsLabeledControlItem,
                IntroChoreographySettingsLabeledControlItem,
                CameraZoomSettingsLabeledControlItem,
                TimeScaleSettingsLabeledControlItem,
                MetronomeSettingsLabeledControlItem,
                LogSurfacerEventsSettingsLabeledControlItem,
            ],
        },
    },
}

# --- Manifest additions ---

var _screen_inclusions := [
    preload("res://addons/surfacer/src/gui/precompute_platform_graphs_screen.tscn"),
]

var _surfacer_sounds := [
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
]

# --- Global state ---

var manifest: Dictionary
var is_inspector_enabled: bool
var are_loaded_surfaces_deeply_validated: bool
var is_surfacer_logging: bool
var is_metronome_enabled: bool
var uses_threads_for_platform_graph_calculation: bool
var precompute_platform_graph_for_levels: Array
var ignores_platform_graph_save_files := false
var ignores_platform_graph_save_file_trajectory_state := false
var is_debug_only_platform_graph_state_included := false
var is_precomputing_platform_graphs: bool
var is_intro_choreography_shown: bool

var default_player_name: String

var is_active_trajectory_shown: bool
var is_previous_trajectory_shown: bool
var is_preselection_trajectory_shown: bool
var is_navigation_destination_shown: bool

var is_human_current_nav_trajectory_shown_with_slow_mo := false
var is_computer_current_nav_trajectory_shown_with_slow_mo := true
var is_human_current_nav_trajectory_shown_without_slow_mo := true
var is_computer_current_nav_trajectory_shown_without_slow_mo := false
var is_human_nav_pulse_shown_with_slow_mo := false
var is_computer_nav_pulse_shown_with_slow_mo := true
var is_human_nav_pulse_shown_without_slow_mo := true
var is_computer_nav_pulse_shown_without_slow_mo := false
var is_human_new_nav_exclamation_mark_shown := false
var is_computer_new_nav_exclamation_mark_shown := true

var does_human_nav_pulse_grow := false
var does_computer_nav_pulse_grow := true
var is_human_prediction_shown := true
var is_computer_prediction_shown := true
var nav_selection_slow_mo_time_scale := 0.02
var nav_selection_slow_mo_tick_tock_tempo_multiplier := 25
var nav_selection_slow_mo_saturation := 0.2
var nav_selection_prediction_opacity := 0.5
var nav_selection_prediction_tween_duration := 0.15
var nav_path_fade_in_duration := 0.2
var new_path_pulse_duration := 0.7
var new_path_pulse_time_length := 1.0

var path_drag_update_throttle_interval := 0.2
var path_beat_update_throttle_interval := 0.2

# Params for CameraPanController.
var snaps_camera_back_to_player := true
var max_zoom_multiplier_from_pointer := 1.5
var max_pan_distance_from_pointer := 512.0
var duration_to_max_pan_from_pointer_at_max_control := 0.67
var duration_to_max_zoom_from_pointer_at_max_control := 3.0
var screen_size_ratio_distance_from_edge_to_start_pan_from_pointer := 0.3

var skip_choreography_framerate_multiplier := 10.0

# Here are some example fields for these debug params:
#{
#    limit_parsing = {
#        player_name = "momma",
#
#        edge_type = EdgeType.JUMP_INTER_SURFACE_EDGE,
##        edge_type = EdgeType.CLIMB_OVER_WALL_TO_FLOOR_EDGE,
##        edge_type = EdgeType.FALL_FROM_WALL_EDGE,
##        edge_type = EdgeType.FALL_FROM_FLOOR_EDGE,
##        edge_type = EdgeType.CLIMB_DOWN_WALL_TO_FLOOR_EDGE,
##        edge_type = EdgeType.WALK_TO_ASCEND_WALL_FROM_FLOOR_EDGE,
#
#        edge = {
#            origin = {
#                surface_side = SurfaceSide.FLOOR,
#                surface_start_vertex = Vector2(-64, 64),
#                position = Vector2(64, 64),
#                epsilon = 10,
#            },
#            destination = {
#                surface_side = SurfaceSide.FLOOR,
#                surface_start_vertex = Vector2(128, -128),
#                position = Vector2(128, -128),
#                epsilon = 10,
#            },
#            #velocity_start = Vector2(0, -1000),
#        },
#    },
#}
var debug_params: Dictionary

var group_name_human_players := Player.GROUP_NAME_HUMAN_PLAYERS
var group_name_computer_players := Player.GROUP_NAME_COMPUTER_PLAYERS
var group_name_surfaces := SurfacesTileMap.GROUP_NAME_SURFACES
var group_name_desaturatable := "desaturatables"

var non_surface_parser_metric_keys := [
    "find_surfaces_in_jump_fall_range_from_surface",
    "edge_calc_broad_phase_check",
    "calculate_jump_land_positions_for_surface_pair",
    "narrow_phase_edge_calculation",
    "check_continuous_horizontal_step_for_collision",
    
    "calculate_jump_from_surface_edge",
    "fall_from_floor_walk_to_fall_off_point_calculation",
    "find_surfaces_in_fall_range_from_point",
    "find_landing_trajectory_between_positions",
    "calculate_land_positions_on_surface",
    "create_edge_calc_params",
    "calculate_vertical_step",
    "calculate_jump_from_surface_steps",
    "convert_calculation_steps_to_movement_instructions",
    "calculate_trajectory_from_calculation_steps",
    "calculate_horizontal_step",
    "calculate_waypoints_around_surface",
    
    # Counts
    "invalid_collision_state_in_calculate_steps_between_waypoints",
    "collision_in_calculate_steps_between_waypoints",
    "calculate_steps_between_waypoints_without_backtracking_on_height",
    "calculate_steps_between_waypoints_with_backtracking_on_height",
    
    "navigator_navigate_path",
    "navigator_find_path",
    "navigator_optimize_edges_for_approach",
    "navigator_ensure_edges_have_trajectory_state",
    "navigator_start_edge",
]

var surface_parser_metric_keys := [
    "parse_tile_map_into_sides_duration",
    "remove_internal_surfaces_duration",
    "merge_continuous_surfaces_duration",
    "remove_internal_collinear_vertices_duration",
    "store_surfaces_duration",
    "populate_derivative_collections",
    "assign_neighbor_surfaces_duration",
    "calculate_shape_bounding_boxes_for_surfaces_duration",
    "assert_surfaces_fully_calculated_duration",
]

var player_actions := {}

var edge_movements := {}

# Dictionary<String, PlayerParams>
var player_params := {}

var human_player: Player
var graph_parser: PlatformGraphParser
var graph_inspector: PlatformGraphInspector
var legend: Legend
var selection_description: SelectionDescription
var annotators: Annotators
var ann_defaults: AnnotationElementDefaults
var edge_from_json_factory := EdgeFromJsonFactory.new()

var player_action_classes: Array
var edge_movement_classes: Array
var player_param_classes: Array

# ---


func _ready() -> void:
    Gs.logger.print("SurfacerConfig._ready")


func amend_app_manifest(manifest: Dictionary) -> void:
    if !manifest.has("colors_class"):
            manifest.colors_class = SurfacerColors
    if !manifest.has("draw_utils_class"):
            manifest.draw_utils_class = SurfacerDrawUtils
    
    var is_precomputing_platform_graphs: bool = \
            manifest.surfacer_manifest \
                    .has("precompute_platform_graph_for_levels") and \
            !manifest.surfacer_manifest \
                    .precompute_platform_graph_for_levels.empty()
    if is_precomputing_platform_graphs:
        manifest.app_metadata.is_splash_skipped = true
    
    # Add Surfacer sounds to the front, so they can be overridden by the app.
    Gs.utils.concat(
            manifest.audio_manifest.sounds_manifest,
            _surfacer_sounds,
            false)
    
    for inclusion in _screen_inclusions:
        if !manifest.gui_manifest.screen_manifest.exclusions \
                .has(inclusion) and \
                !manifest.gui_manifest.screen_manifest.inclusions \
                .has(inclusion):
            manifest.gui_manifest.screen_manifest.inclusions \
                    .push_back(inclusion)
    
    if !manifest.gui_manifest.has("settings_item_manifest"):
        manifest.gui_manifest.settings_item_manifest = \
                DEFAULT_SURFACER_SETTINGS_ITEM_MANIFEST


func register_app_manifest(manifest: Dictionary) -> void:
    self.manifest = manifest
    var surfacer_manifest: Dictionary = manifest.surfacer_manifest
    
    self.are_loaded_surfaces_deeply_validated = \
            surfacer_manifest.are_loaded_surfaces_deeply_validated
    self.uses_threads_for_platform_graph_calculation = \
            surfacer_manifest.uses_threads_for_platform_graph_calculation
    self.player_action_classes = surfacer_manifest.player_action_classes
    self.edge_movement_classes = surfacer_manifest.edge_movement_classes
    self.player_param_classes = surfacer_manifest.player_param_classes
    self.debug_params = surfacer_manifest.debug_params
    self.default_player_name = surfacer_manifest.default_player_name
    
    self.is_precomputing_platform_graphs = \
            surfacer_manifest.has("precompute_platform_graph_for_levels") and \
            !surfacer_manifest.precompute_platform_graph_for_levels.empty()
    if self.is_precomputing_platform_graphs:
        self.precompute_platform_graph_for_levels = \
                surfacer_manifest.precompute_platform_graph_for_levels
    
    if surfacer_manifest.has("ignores_platform_graph_save_files"):
        self.ignores_platform_graph_save_files = \
                surfacer_manifest.ignores_platform_graph_save_files
    if surfacer_manifest.has(
            "ignores_platform_graph_save_file_trajectory_state"):
        self.ignores_platform_graph_save_file_trajectory_state = \
                surfacer_manifest \
                        .ignores_platform_graph_save_file_trajectory_state
    if surfacer_manifest.has("is_debug_only_platform_graph_state_included"):
        self.is_debug_only_platform_graph_state_included = \
                surfacer_manifest.is_debug_only_platform_graph_state_included
    
    if surfacer_manifest.has("nav_selection_slow_mo_time_scale"):
        self.nav_selection_slow_mo_time_scale = \
                surfacer_manifest.nav_selection_slow_mo_time_scale
    if surfacer_manifest.has(
            "nav_selection_slow_mo_tick_tock_tempo_multiplier"):
        self.nav_selection_slow_mo_tick_tock_tempo_multiplier = \
                surfacer_manifest \
                        .nav_selection_slow_mo_tick_tock_tempo_multiplier
    
    if surfacer_manifest.has(
            "is_human_current_nav_trajectory_shown_with_slow_mo"):
        self.is_human_current_nav_trajectory_shown_with_slow_mo = \
                surfacer_manifest \
                        .is_human_current_nav_trajectory_shown_with_slow_mo
    if surfacer_manifest.has(
            "is_computer_current_nav_trajectory_shown_with_slow_mo"):
        self.is_computer_current_nav_trajectory_shown_with_slow_mo = \
                surfacer_manifest \
                        .is_computer_current_nav_trajectory_shown_with_slow_mo
    if surfacer_manifest.has(
            "is_human_current_nav_trajectory_shown_without_slow_mo"):
        self.is_human_current_nav_trajectory_shown_without_slow_mo = \
                surfacer_manifest \
                        .is_human_current_nav_trajectory_shown_without_slow_mo
    if surfacer_manifest.has(
            "is_computer_current_nav_trajectory_shown_without_slow_mo"):
        self.is_computer_current_nav_trajectory_shown_without_slow_mo = \
                surfacer_manifest \
                    .is_computer_current_nav_trajectory_shown_without_slow_mo
    if surfacer_manifest.has("is_human_nav_pulse_shown_with_slow_mo"):
        self.is_human_nav_pulse_shown_with_slow_mo = \
                surfacer_manifest.is_human_nav_pulse_shown_with_slow_mo
    if surfacer_manifest.has("is_computer_nav_pulse_shown_with_slow_mo"):
        self.is_computer_nav_pulse_shown_with_slow_mo = \
                surfacer_manifest.is_computer_nav_pulse_shown_with_slow_mo
    if surfacer_manifest.has("is_human_nav_pulse_shown_without_slow_mo"):
        self.is_human_nav_pulse_shown_without_slow_mo = \
                surfacer_manifest.is_human_nav_pulse_shown_without_slow_mo
    if surfacer_manifest.has("is_computer_nav_pulse_shown_without_slow_mo"):
        self.is_computer_nav_pulse_shown_without_slow_mo = \
                surfacer_manifest.is_computer_nav_pulse_shown_without_slow_mo
    if surfacer_manifest.has("is_human_new_nav_exclamation_mark_shown"):
        self.is_human_new_nav_exclamation_mark_shown = \
                surfacer_manifest.is_human_new_nav_exclamation_mark_shown
    if surfacer_manifest.has("is_computer_new_nav_exclamation_mark_shown"):
        self.is_computer_new_nav_exclamation_mark_shown = \
                surfacer_manifest.is_computer_new_nav_exclamation_mark_shown
    if surfacer_manifest.has("does_human_nav_pulse_grow"):
        self.does_human_nav_pulse_grow = \
                surfacer_manifest.does_human_nav_pulse_grow
    if surfacer_manifest.has("does_computer_nav_pulse_grow"):
        self.does_computer_nav_pulse_grow = \
                surfacer_manifest.does_computer_nav_pulse_grow
    if surfacer_manifest.has("nav_selection_slow_mo_saturation"):
        self.nav_selection_slow_mo_saturation = \
                surfacer_manifest.nav_selection_slow_mo_saturation
    if surfacer_manifest.has("nav_selection_prediction_opacity"):
        self.nav_selection_prediction_opacity = \
                surfacer_manifest.nav_selection_prediction_opacity
    if surfacer_manifest.has("nav_path_fade_in_duration"):
        self.nav_path_fade_in_duration = \
                surfacer_manifest.nav_path_fade_in_duration
    if surfacer_manifest.has("new_path_pulse_duration"):
        self.new_path_pulse_duration = \
                surfacer_manifest.new_path_pulse_duration
    if surfacer_manifest.has("new_path_pulse_time_length"):
        self.new_path_pulse_time_length = \
                surfacer_manifest.new_path_pulse_time_length
    
    if surfacer_manifest.has("path_drag_update_throttle_interval"):
        self.path_drag_update_throttle_interval = \
                surfacer_manifest.path_drag_update_throttle_interval
    if surfacer_manifest.has("path_beat_update_throttle_interval"):
        self.path_beat_update_throttle_interval = \
                surfacer_manifest.path_beat_update_throttle_interval
    
    if surfacer_manifest.has("nav_selection_prediction_tween_duration"):
        self.nav_selection_prediction_tween_duration = \
                surfacer_manifest.nav_selection_prediction_tween_duration
    
    if surfacer_manifest.has("is_human_prediction_shown"):
        self.is_human_prediction_shown = \
                surfacer_manifest.is_human_prediction_shown
    if surfacer_manifest.has("is_computer_prediction_shown"):
        self.is_computer_prediction_shown = \
                surfacer_manifest.is_computer_prediction_shown
    
    if surfacer_manifest.has("skip_choreography_framerate_multiplier"):
        self.skip_choreography_framerate_multiplier = \
                surfacer_manifest.skip_choreography_framerate_multiplier
    
    assert(Gs.manifest.app_metadata.must_restart_level_to_change_settings)


func initialize() -> void:
    assert(Gs.colors is SurfacerColors)
    assert(Gs.draw_utils is SurfacerDrawUtils)
    assert(Gs.level_config is MommaDuckLevelConfig)
    assert(Gs.level_session is MommaDuckLevelSession)
    
    self.is_inspector_enabled = Gs.save_state.get_setting(
            IS_INSPECTOR_ENABLED_SETTINGS_KEY,
            Gs.gui.hud_manifest.is_inspector_enabled_default)
    self.is_surfacer_logging = Gs.save_state.get_setting(
            IS_SURFACER_LOGGING_SETTINGS_KEY,
            false)
    self.is_metronome_enabled = Gs.save_state.get_setting(
            IS_METRONOME_ENABLED_SETTINGS_KEY,
            false)
    self.is_intro_choreography_shown = Gs.save_state.get_setting(
            IS_INTRO_CHOREOGRAPHY_SHOWN_SETTINGS_KEY,
            true)
    self.is_active_trajectory_shown = Gs.save_state.get_setting(
            ACTIVE_TRAJECTORY_SHOWN_SETTINGS_KEY,
            true)
    self.is_previous_trajectory_shown = Gs.save_state.get_setting(
            PREVIOUS_TRAJECTORY_SHOWN_SETTINGS_KEY,
            false)
    self.is_preselection_trajectory_shown = Gs.save_state.get_setting(
            PRESELECTION_TRAJECTORY_SHOWN_SETTINGS_KEY,
            true)
    self.is_navigation_destination_shown = Gs.save_state.get_setting(
            NAVIGATION_DESTINATION_SHOWN_SETTINGS_KEY,
            true)
    
    Gs.profiler.preregister_metric_keys(non_surface_parser_metric_keys)
    Gs.profiler.preregister_metric_keys(surface_parser_metric_keys)
    
    ann_defaults = AnnotationElementDefaults.new()
    annotators = Annotators.new()
    add_child(Surfacer.annotators)

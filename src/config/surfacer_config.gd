class_name SurfacerConfig
extends Node


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

# --- Manifest additions ---

var _must_restart_level_to_change_settings := true

var _screen_path_inclusions := [
    "res://addons/surfacer/src/gui/precompute_platform_graphs_screen.tscn",
]

var _settings_main_item_class_exclusions := []
var _settings_main_item_class_inclusions := []
var _settings_details_item_class_exclusions := []
var _settings_details_item_class_inclusions := [
    TimeScaleSettingsLabeledControlItem,
    IntroChoreographySettingsLabeledControlItem,
    InspectorEnabledSettingsLabeledControlItem,
    PreselectionTrajectoryAnnotatorSettingsLabeledControlItem,
    ActiveTrajectoryAnnotatorSettingsLabeledControlItem,
    PreviousTrajectoryAnnotatorSettingsLabeledControlItem,
    NavigationDestinationAnnotatorSettingsLabeledControlItem,
    PlayerPositionAnnotatorSettingsLabeledControlItem,
    RecentMovementAnnotatorSettingsLabeledControlItem,
    PlayerAnnotatorSettingsLabeledControlItem,
    LevelAnnotatorSettingsLabeledControlItem,
    SurfacesAnnotatorSettingsLabeledControlItem,
    RulerAnnotatorSettingsLabeledControlItem,
    LogSurfacerEventsSettingsLabeledControlItem,
    MetronomeSettingsLabeledControlItem,
]

var _sounds_manifest := [
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

# ---

var manifest: Dictionary
var is_inspector_enabled: bool
var are_loaded_surfaces_deeply_validated: bool
var is_surfacer_logging: bool
var is_metronome_enabled: bool
var inspector_panel_starts_open: bool
var uses_threads_for_platform_graph_calculation: bool
var precompute_platform_graph_for_levels: Array
var ignores_platform_graph_save_files := false
var is_precomputing_platform_graphs: bool
var is_intro_choreography_shown: bool
var are_beats_tracked: bool

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
var new_path_pulse_duration_multiplier := 0.4
var new_path_pulse_time_length := 1.0

# Params for CameraPanController.
var snaps_camera_back_to_player := true
var max_zoom_multiplier_from_pointer := 1.5
var max_pan_distance_from_pointer := 512.0
var duration_to_max_pan_from_pointer_at_max_control := 0.67
var duration_to_max_zoom_from_pointer_at_max_control := 3.0
var screen_size_ratio_distance_from_edge_to_start_pan_from_pointer := 0.3

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
var inspector_panel: InspectorPanel
var annotators: Annotators
var ann_defaults: AnnotationElementDefaults
var edge_from_json_factory := EdgeFromJsonFactory.new()
var slow_motion: SlowMotionController

var player_action_classes: Array
var edge_movement_classes: Array
var player_param_classes: Array

# ---


func amend_app_manifest(manifest: Dictionary) -> void:
    manifest.must_restart_level_to_change_settings = \
            _must_restart_level_to_change_settings
    
    var is_precomputing_platform_graphs: bool = \
            manifest.has("precompute_platform_graph_for_levels") and \
            !manifest.precompute_platform_graph_for_levels.empty()
    if is_precomputing_platform_graphs:
        manifest.is_splash_skipped = true
    
    # Add Surfacer sounds to the front, so they can be overridden by the app.
    Gs.utils.concat(manifest.sounds_manifest, _sounds_manifest, false)
    
    for inclusion in _screen_path_inclusions:
        if !manifest.screen_path_exclusions.has(inclusion) and \
                !manifest.screen_path_inclusions.has(inclusion):
            manifest.screen_path_inclusions.push_back(inclusion)
    
    for exclusion in _settings_main_item_class_exclusions:
        if !manifest.settings_main_item_class_exclusions.has(exclusion) and \
                !manifest.settings_main_item_class_inclusions.has(exclusion):
            manifest.settings_main_item_class_exclusions.push_back(exclusion)
    for inclusion in _settings_main_item_class_inclusions:
        if !manifest.settings_main_item_class_inclusions.has(inclusion) and \
                !manifest.settings_main_item_class_exclusions.has(inclusion):
            manifest.settings_main_item_class_inclusions.push_back(inclusion)
    for exclusion in _settings_details_item_class_exclusions:
        if !manifest.settings_details_item_class_exclusions.has(exclusion) and \
                !manifest.settings_details_item_class_inclusions.has(exclusion):
            manifest.settings_details_item_class_exclusions.push_back(exclusion)
    for inclusion in _settings_details_item_class_inclusions:
        if !manifest.settings_details_item_class_inclusions.has(inclusion) and \
                !manifest.settings_details_item_class_exclusions.has(inclusion):
            manifest.settings_details_item_class_inclusions.push_back(inclusion)


func register_app_manifest(manifest: Dictionary) -> void:
    self.manifest = manifest
    self.are_loaded_surfaces_deeply_validated = \
            are_loaded_surfaces_deeply_validated
    self.inspector_panel_starts_open = manifest.inspector_panel_starts_open
    self.uses_threads_for_platform_graph_calculation = \
            manifest.uses_threads_for_platform_graph_calculation
    self.are_beats_tracked = manifest.are_beats_tracked
    self.player_action_classes = manifest.player_action_classes
    self.edge_movement_classes = manifest.edge_movement_classes
    self.player_param_classes = manifest.player_param_classes
    self.debug_params = manifest.debug_params
    self.default_player_name = manifest.default_player_name
    
    self.is_precomputing_platform_graphs = \
            manifest.has("precompute_platform_graph_for_levels") and \
            !manifest.precompute_platform_graph_for_levels.empty()
    if self.is_precomputing_platform_graphs:
        self.precompute_platform_graph_for_levels = \
                manifest.precompute_platform_graph_for_levels
    
    if manifest.has("ignores_platform_graph_save_files"):
        self.ignores_platform_graph_save_files = \
                manifest.ignores_platform_graph_save_files
    
    if manifest.has("nav_selection_slow_mo_time_scale"):
        self.nav_selection_slow_mo_time_scale = \
                manifest.nav_selection_slow_mo_time_scale
    if manifest.has("nav_selection_slow_mo_tick_tock_tempo_multiplier"):
        self.nav_selection_slow_mo_tick_tock_tempo_multiplier = \
                manifest.nav_selection_slow_mo_tick_tock_tempo_multiplier
    
    if manifest.has("is_human_current_nav_trajectory_shown_with_slow_mo"):
        self.is_human_current_nav_trajectory_shown_with_slow_mo = \
                manifest.is_human_current_nav_trajectory_shown_with_slow_mo
    
    if manifest.has("is_computer_current_nav_trajectory_shown_with_slow_mo"):
        self.is_computer_current_nav_trajectory_shown_with_slow_mo = \
                manifest.is_computer_current_nav_trajectory_shown_with_slow_mo
    
    if manifest.has("is_human_current_nav_trajectory_shown_without_slow_mo"):
        self.is_human_current_nav_trajectory_shown_without_slow_mo = \
                manifest.is_human_current_nav_trajectory_shown_without_slow_mo
    
    if manifest.has(
            "is_computer_current_nav_trajectory_shown_without_slow_mo"):
        self.is_computer_current_nav_trajectory_shown_without_slow_mo = \
                manifest \
                    .is_computer_current_nav_trajectory_shown_without_slow_mo
    
    if manifest.has("is_human_nav_pulse_shown_with_slow_mo"):
        self.is_human_nav_pulse_shown_with_slow_mo = \
                manifest.is_human_nav_pulse_shown_with_slow_mo
    
    if manifest.has("is_computer_nav_pulse_shown_with_slow_mo"):
        self.is_computer_nav_pulse_shown_with_slow_mo = \
                manifest.is_computer_nav_pulse_shown_with_slow_mo
    
    if manifest.has("is_human_nav_pulse_shown_without_slow_mo"):
        self.is_human_nav_pulse_shown_without_slow_mo = \
                manifest.is_human_nav_pulse_shown_without_slow_mo
    
    if manifest.has("is_computer_nav_pulse_shown_without_slow_mo"):
        self.is_computer_nav_pulse_shown_without_slow_mo = \
                manifest.is_computer_nav_pulse_shown_without_slow_mo
    
    if manifest.has("is_human_new_nav_exclamation_mark_shown"):
        self.is_human_new_nav_exclamation_mark_shown = \
                manifest.is_human_new_nav_exclamation_mark_shown
    
    if manifest.has("is_computer_new_nav_exclamation_mark_shown"):
        self.is_computer_new_nav_exclamation_mark_shown = \
                manifest.is_computer_new_nav_exclamation_mark_shown
    
    if manifest.has("does_human_nav_pulse_grow"):
        self.does_human_nav_pulse_grow = \
                manifest.does_human_nav_pulse_grow
    
    if manifest.has("does_computer_nav_pulse_grow"):
        self.does_computer_nav_pulse_grow = \
                manifest.does_computer_nav_pulse_grow
    
    if manifest.has("nav_selection_slow_mo_saturation"):
        self.nav_selection_slow_mo_saturation = \
                manifest.nav_selection_slow_mo_saturation
    
    if manifest.has("nav_selection_prediction_opacity"):
        self.nav_selection_prediction_opacity = \
                manifest.nav_selection_prediction_opacity
    
    if manifest.has("new_path_pulse_duration_multiplier"):
        self.new_path_pulse_duration_multiplier = \
                manifest.new_path_pulse_duration_multiplier
    
    if manifest.has("new_path_pulse_time_length"):
        self.new_path_pulse_time_length = \
                manifest.new_path_pulse_time_length
    
    if manifest.has("nav_selection_prediction_tween_duration"):
        self.nav_selection_prediction_tween_duration = \
                manifest.nav_selection_prediction_tween_duration
    
    if manifest.has("is_human_prediction_shown"):
        self.is_human_prediction_shown = \
                manifest.is_human_prediction_shown
    
    if manifest.has("is_computer_prediction_shown"):
        self.is_computer_prediction_shown = \
                manifest.is_computer_prediction_shown


func initialize() -> void:
    self.is_inspector_enabled = Gs.save_state.get_setting(
            IS_INSPECTOR_ENABLED_SETTINGS_KEY,
            manifest.is_inspector_enabled_default)
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
    
    Gs.audio.is_tracking_beat = Surfacer.are_beats_tracked
    
    slow_motion = SlowMotionController.new()
    add_child(slow_motion)
    
    ann_defaults = AnnotationElementDefaults.new()
    annotators = Annotators.new()
    add_child(Surfacer.annotators)


func get_is_inspector_panel_open() -> bool:
    return is_instance_valid(inspector_panel) and inspector_panel.is_open

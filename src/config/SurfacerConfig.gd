class_name SurfacerConfig
extends Node

const WALLS_AND_FLOORS_COLLISION_MASK_BIT := 0
const FALL_THROUGH_FLOORS_COLLISION_MASK_BIT := 1
const WALK_THROUGH_WALLS_COLLISION_MASK_BIT := 2

# --- Manifest additions ---

var _must_restart_level_to_change_settings := true

var _screen_path_inclusions := [
    "res://addons/surfacer/src/gui/PrecomputePlatformGraphsScreen.tscn",
]

var _settings_main_item_class_exclusions := []
var _settings_main_item_class_inclusions := []
var _settings_details_item_class_exclusions := []
var _settings_details_item_class_inclusions := [
    InspectorEnabledSettingsLabeledControlItem,
    PlayerPositionAnnotatorSettingsLabeledControlItem,
    PlayerTrajectoryAnnotatorSettingsLabeledControlItem,
    PlayerAnnotatorSettingsLabeledControlItem,
    LevelAnnotatorSettingsLabeledControlItem,
    SurfacesAnnotatorSettingsLabeledControlItem,
    RulerAnnotatorSettingsLabeledControlItem,
    LogSurfacerEventsSettingsLabeledControlItem,
]

# ---

var manifest: Dictionary
var is_inspector_enabled: bool
var are_loaded_surfaces_deeply_validated: bool
var is_surfacer_logging: bool
var inspector_panel_starts_open: bool
var uses_threads_for_platform_graph_calculation: bool
var precompute_platform_graph_for_levels: Array
var ignores_platform_graph_save_files := false
var is_precomputing_platform_graphs: bool
var default_player_name: String

var debug_params: Dictionary

var group_name_human_players := Player.GROUP_NAME_HUMAN_PLAYERS
var group_name_computer_players := Player.GROUP_NAME_COMPUTER_PLAYERS
var group_name_surfaces := SurfacesTileMap.GROUP_NAME_SURFACES

var non_surface_parser_metric_keys := [
    "find_surfaces_in_jump_fall_range_from_surface",
    "edge_calc_broad_phase_check",
    "calculate_jump_land_positions_for_surface_pair",
    "narrow_phase_edge_calculation",
    "check_continuous_horizontal_step_for_collision",
    
    "calculate_jump_inter_surface_edge",
    "fall_from_floor_walk_to_fall_off_point_calculation",
    "find_surfaces_in_fall_range_from_point",
    "find_landing_trajectory_between_positions",
    "calculate_land_positions_on_surface",
    "create_edge_calc_params",
    "calculate_vertical_step",
    "calculate_jump_inter_surface_steps",
    "convert_calculation_steps_to_movement_instructions",
    "calculate_trajectory_from_calculation_steps",
    "calculate_horizontal_step",
    "calculate_waypoints_around_surface",
    
    # Counts
    "invalid_collision_state_in_calculate_steps_between_waypoints",
    "collision_in_calculate_steps_between_waypoints",
    "calculate_steps_between_waypoints_without_backtracking_on_height",
    "calculate_steps_between_waypoints_with_backtracking_on_height",
    
    "navigator_navigate_to_position",
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

func initialize() -> void:
    self.is_inspector_enabled = Gs.save_state.get_setting(
            "is_inspector_enabled",
            manifest.is_inspector_enabled_default)
    self.is_surfacer_logging = Gs.save_state.get_setting(
            "is_surfacer_logging",
            false)
    
    Gs.profiler.preregister_metric_keys(non_surface_parser_metric_keys)
    Gs.profiler.preregister_metric_keys(surface_parser_metric_keys)
    
    ann_defaults = AnnotationElementDefaults.new()
    annotators = Annotators.new()
    add_child(Surfacer.annotators)

func get_is_inspector_panel_open() -> bool:
    return is_instance_valid(inspector_panel) and inspector_panel.is_open

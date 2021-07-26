tool
extends FrameworkConfig


# --- Constants ---

const WALLS_AND_FLOORS_COLLISION_MASK_BIT := 0
const FALL_THROUGH_FLOORS_COLLISION_MASK_BIT := 1
const WALK_THROUGH_WALLS_COLLISION_MASK_BIT := 2

const IS_INSPECTOR_ENABLED_SETTINGS_KEY := "is_inspector_enabled"
const IS_SURFACER_LOGGING_SETTINGS_KEY := "is_surfacer_logging"
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
                ButtonControlsSettingsLabeledControlItem,
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

# --- Scaffolder manifest additions ---

var _screen_inclusions := [
    preload("res://addons/surfacer/src/gui/screens/precompute_platform_graphs_screen.tscn"),
    preload("res://addons/surfacer/src/gui/screens/surfacer_loading_screen.tscn"),
]

var _screen_exclusions := [
    preload("res://addons/scaffolder/src/gui/screens/scaffolder_loading_screen.tscn"),
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

# --- Surfacer global state ---

var manifest: Dictionary
var is_inspector_enabled: bool
var are_loaded_surfaces_deeply_validated: bool
var is_surfacer_logging: bool
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

var gravity_default := 5000.0
var gravity_slow_rise_multiplier_default := 0.38
var gravity_double_jump_slow_rise_multiplier_default := 0.68

var walk_acceleration_default := 8000.0
var in_air_horizontal_acceleration_default := 2500.0
var climb_up_speed_default := -230.0
var climb_down_speed_default := 120.0

var friction_coefficient_default := 1.25

var jump_boost_default := -900.0
var wall_jump_horizontal_boost_default := 200.0
var wall_fall_horizontal_boost_default := 20.0

var max_horizontal_speed_default_default := 320.0
var max_vertical_speed_default := 2800.0
var min_horizontal_speed := 5.0
var min_vertical_speed := 0.0

var dash_speed_multiplier_default := 3.0
var dash_vertical_boost_default := -300.0
var dash_duration_default := 0.3
var dash_fade_duration_default := 0.1
var dash_cooldown_default := 1.0

var additional_edge_weight_offset_default := 128.0
var walking_edge_weight_multiplier_default := 1.2
var climbing_edge_weight_multiplier_default := 1.8
var air_edge_weight_multiplier_default := 1.0

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

# FIXME: -----------------------------------------------
var player_actions := {}

# FIXME: -----------------------------------------------
var edge_movements := {}

# FIXME: -----------------------------------------------
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
    assert(is_instance_valid(Sc),
            "The Sc (Scaffolder) AutoLoad must be declared first.")
    
    Sc.logger.on_global_init(self, "Su")
    Sc.register_framework_config(self)
    
    Sc._bootstrap = SurfacerBootstrap.new()


func _amend_app_manifest(manifest: Dictionary) -> void:
    if !manifest.has("colors_class"):
            manifest.colors_class = SurfacerColors
    if !manifest.has("geometry_class"):
            manifest.geometry_class = SurfacerGeometry
    if !manifest.has("draw_utils_class"):
            manifest.draw_utils_class = SurfacerDrawUtils
    
    var is_precomputing_platform_graphs: bool = \
            manifest.surfacer_manifest \
                    .has("precompute_platform_graph_for_levels") and \
            !manifest.surfacer_manifest \
                    .precompute_platform_graph_for_levels.empty()
    if is_precomputing_platform_graphs:
        manifest.metadata.is_splash_skipped = true
    
    # Add Surfacer sounds to the front, so they can be overridden by the app.
    Sc.utils.concat(
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
    for exclusion in _screen_exclusions:
        if !manifest.gui_manifest.screen_manifest.exclusions \
                .has(exclusion) and \
                !manifest.gui_manifest.screen_manifest.inclusions \
                .has(exclusion):
            manifest.gui_manifest.screen_manifest.exclusions \
                    .push_back(exclusion)
    
    if !manifest.gui_manifest.has("settings_item_manifest"):
        manifest.gui_manifest.settings_item_manifest = \
                DEFAULT_SURFACER_SETTINGS_ITEM_MANIFEST


func _register_app_manifest(manifest: Dictionary) -> void:
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
    
    if surfacer_manifest.has("gravity_default"):
        self.gravity_default = \
                surfacer_manifest.gravity_default
    if surfacer_manifest.has("gravity_slow_rise_multiplier_default"):
        self.gravity_slow_rise_multiplier_default = \
                surfacer_manifest.gravity_slow_rise_multiplier_default
    if surfacer_manifest.has("gravity_double_jump_slow_rise_multiplier_default"):
        self.gravity_double_jump_slow_rise_multiplier_default = \
                surfacer_manifest.gravity_double_jump_slow_rise_multiplier_default
    if surfacer_manifest.has("walk_acceleration_default"):
        self.walk_acceleration_default = \
                surfacer_manifest.walk_acceleration_default
    if surfacer_manifest.has("in_air_horizontal_acceleration_default"):
        self.in_air_horizontal_acceleration_default = \
                surfacer_manifest.in_air_horizontal_acceleration_default
    if surfacer_manifest.has("climb_up_speed_default"):
        self.climb_up_speed_default = \
                surfacer_manifest.climb_up_speed_default
    if surfacer_manifest.has("climb_down_speed_default"):
        self.climb_down_speed_default = \
                surfacer_manifest.climb_down_speed_default
    if surfacer_manifest.has("friction_coefficient_default"):
        self.friction_coefficient_default = \
                surfacer_manifest.friction_coefficient_default
    if surfacer_manifest.has("jump_boost_default"):
        self.jump_boost_default = \
                surfacer_manifest.jump_boost_default
    if surfacer_manifest.has("wall_jump_horizontal_boost_default"):
        self.wall_jump_horizontal_boost_default = \
                surfacer_manifest.wall_jump_horizontal_boost_default
    if surfacer_manifest.has("wall_fall_horizontal_boost_default"):
        self.wall_fall_horizontal_boost_default = \
                surfacer_manifest.wall_fall_horizontal_boost_default
    
    if surfacer_manifest.has("max_horizontal_speed_default_default"):
        self.max_horizontal_speed_default_default = \
                surfacer_manifest.max_horizontal_speed_default_default
    if surfacer_manifest.has("max_vertical_speed_default"):
        self.max_vertical_speed_default = \
                surfacer_manifest.max_vertical_speed_default
    if surfacer_manifest.has("min_horizontal_speed"):
        self.min_horizontal_speed = \
                surfacer_manifest.min_horizontal_speed
    if surfacer_manifest.has("min_vertical_speed"):
        self.min_vertical_speed = \
                surfacer_manifest.min_vertical_speed
    
    if surfacer_manifest.has("dash_speed_multiplier_default"):
        self.dash_speed_multiplier_default = \
                surfacer_manifest.dash_speed_multiplier_default
    if surfacer_manifest.has("dash_vertical_boost_default"):
        self.dash_vertical_boost_default = \
                surfacer_manifest.dash_vertical_boost_default
    if surfacer_manifest.has("dash_duration_default"):
        self.dash_duration_default = \
                surfacer_manifest.dash_duration_default
    if surfacer_manifest.has("dash_fade_duration_default"):
        self.dash_fade_duration_default = \
                surfacer_manifest.dash_fade_duration_default
    if surfacer_manifest.has("dash_cooldown_default"):
        self.dash_cooldown_default = \
                surfacer_manifest.dash_cooldown_default
    
    if surfacer_manifest.has("additional_edge_weight_offset_default"):
        self.additional_edge_weight_offset_default = \
                surfacer_manifest.additional_edge_weight_offset_default
    if surfacer_manifest.has("walking_edge_weight_multiplier_default"):
        self.walking_edge_weight_multiplier_default = \
                surfacer_manifest.walking_edge_weight_multiplier_default
    if surfacer_manifest.has("climbing_edge_weight_multiplier_default"):
        self.climbing_edge_weight_multiplier_default = \
                surfacer_manifest.climbing_edge_weight_multiplier_default
    if surfacer_manifest.has("air_edge_weight_multiplier_default"):
        self.air_edge_weight_multiplier_default = \
                surfacer_manifest.air_edge_weight_multiplier_default
    
    assert(Sc._manifest.metadata.must_restart_level_to_change_settings)


func _set_up() -> void:
    assert(Sc.colors is SurfacerColors)
    assert(Sc.draw is SurfacerDrawUtils)
    assert(Sc.level_config is MommaDuckLevelConfig)
    assert(Sc.level_session is MommaDuckLevelSession)
    
    self.is_inspector_enabled = Sc.save_state.get_setting(
            IS_INSPECTOR_ENABLED_SETTINGS_KEY,
            Sc.gui.hud_manifest.is_inspector_enabled_default)
    self.is_surfacer_logging = Sc.save_state.get_setting(
            IS_SURFACER_LOGGING_SETTINGS_KEY,
            false)
    self.is_intro_choreography_shown = Sc.save_state.get_setting(
            IS_INTRO_CHOREOGRAPHY_SHOWN_SETTINGS_KEY,
            true)
    self.is_active_trajectory_shown = Sc.save_state.get_setting(
            ACTIVE_TRAJECTORY_SHOWN_SETTINGS_KEY,
            true)
    self.is_previous_trajectory_shown = Sc.save_state.get_setting(
            PREVIOUS_TRAJECTORY_SHOWN_SETTINGS_KEY,
            false)
    self.is_preselection_trajectory_shown = Sc.save_state.get_setting(
            PRESELECTION_TRAJECTORY_SHOWN_SETTINGS_KEY,
            true)
    self.is_navigation_destination_shown = Sc.save_state.get_setting(
            NAVIGATION_DESTINATION_SHOWN_SETTINGS_KEY,
            true)
    
    Sc.profiler.preregister_metric_keys(non_surface_parser_metric_keys)
    Sc.profiler.preregister_metric_keys(surface_parser_metric_keys)
    
    ann_defaults = AnnotationElementDefaults.new()
    annotators = Annotators.new()
    add_child(Su.annotators)
    
    _validate_configuration()


func _validate_configuration() -> void:
    assert(Su.gravity_default >= 0)
    assert(Su.gravity_slow_rise_multiplier_default >= 0)
    assert(Su.gravity_double_jump_slow_rise_multiplier_default >= 0)
    
    assert(Su.walk_acceleration_default >= 0)
    assert(Su.in_air_horizontal_acceleration_default >= 0)
    assert(Su.climb_up_speed_default <= 0)
    assert(Su.climb_down_speed_default >= 0)
    
    assert(Su.jump_boost_default <= 0)
    assert(Su.wall_jump_horizontal_boost_default >= 0 and \
            Su.wall_jump_horizontal_boost_default <= \
            Su.max_horizontal_speed_default_default)
    assert(Su.wall_fall_horizontal_boost_default >= 0 and \
            Su.wall_fall_horizontal_boost_default <= \
            Su.max_horizontal_speed_default_default)
    
    assert(Su.max_horizontal_speed_default_default >= 0)
    assert(Su.max_vertical_speed_default >= 0)
    assert(Su.min_horizontal_speed >= 0)
    assert(Su.max_vertical_speed_default >= abs(Su.jump_boost_default))
    assert(Su.min_vertical_speed >= 0)
    
    assert(Su.dash_speed_multiplier_default >= 0)
    assert(Su.dash_vertical_boost_default <= 0)
    assert(Su.dash_duration_default >= Su.dash_fade_duration_default)
    assert(Su.dash_fade_duration_default >= 0)
    assert(Su.dash_cooldown_default >= 0)

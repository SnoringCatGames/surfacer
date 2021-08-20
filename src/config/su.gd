tool
extends FrameworkConfig
## -   This is a global singleton that defines a bunch of Surfacer
##     parameters.[br]
## -   All of these parameters can be configured when bootstrapping the
##     app.[br]
## -   You will need to provide an `app_manifest` dictionary which defines some
##     of these parameters.[br]
## -   Define `Su` as an AutoLoad (in Project Settings).[br]
## -   "Su" is short for "Surfacer".[br]


# --- Constants ---

const WALLS_AND_FLOORS_COLLISION_MASK_BIT := 0
const FALL_THROUGH_FLOORS_COLLISION_MASK_BIT := 1
const WALK_THROUGH_WALLS_COLLISION_MASK_BIT := 2

const IS_INSPECTOR_ENABLED_SETTINGS_KEY := "is_inspector_enabled"
const IS_INTRO_CHOREOGRAPHY_SHOWN_SETTINGS_KEY := "is_intro_choreography_shown"
const NPC_TRAJECTORY_SHOWN_SETTINGS_KEY := "is_npc_trajectory_shown"
const ACTIVE_TRAJECTORY_SHOWN_SETTINGS_KEY := "is_active_trajectory_shown"
const PREVIOUS_TRAJECTORY_SHOWN_SETTINGS_KEY := "is_previous_trajectory_shown"
const PRESELECTION_TRAJECTORY_SHOWN_SETTINGS_KEY := \
        "is_preselection_trajectory_shown"
const NAVIGATION_DESTINATION_SHOWN_SETTINGS_KEY := \
        "is_navigation_destination_shown"

const PLACEHOLDER_SURFACES_TILE_SET_PATH := \
        "res://addons/surfacer/src/level/placeholder_surfaces_tile_set.tres"

var DEFAULT_SURFACER_SETTINGS_ITEM_MANIFEST := {
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
                PreselectionTrajectoryAnnotatorControlRow,
                NpcCharacterTrajectoryAnnotatorControlRow,
                ActiveTrajectoryAnnotatorControlRow,
                PreviousTrajectoryAnnotatorControlRow,
                NavigationDestinationAnnotatorControlRow,
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

var DEFAULT_BEHAVIOR_CLASSES := [
    ChoreographyBehavior,
    ClimbAdjacentSurfacesBehavior,
    CollideBehavior,
    FollowBehavior,
    MoveBackAndForthBehavior,
    DefaultBehavior,
    ReturnBehavior,
    RunAwayBehavior,
    PlayerNavigationBehavior,
    WanderBehavior,
]

# --- Scaffolder manifest additions ---

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
var uses_threads_for_platform_graph_calculation: bool
var precompute_platform_graph_for_levels: Array
var ignores_platform_graph_save_files := false
var ignores_platform_graph_save_file_trajectory_state := false
var is_debug_only_platform_graph_state_included := false
var are_reachable_surfaces_per_player_tracked := true

var is_precomputing_platform_graphs: bool
var is_intro_choreography_shown: bool

# Dictionary<String, Script>
var behaviors: Dictionary

var default_tile_set: TileSet

var path_drag_update_throttle_interval := 0.2
var path_beat_update_throttle_interval := 0.2

# Params for CameraPanController.
var snaps_camera_back_to_character := true
var max_zoom_multiplier_from_pointer := 1.5
var max_pan_distance_from_pointer := 512.0
var duration_to_max_pan_from_pointer_at_max_control := 0.67
var duration_to_max_zoom_from_pointer_at_max_control := 3.0
var screen_size_ratio_distance_from_edge_to_start_pan_from_pointer := 0.16

var skip_choreography_framerate_multiplier := 10.0

# Here are some example fields for these debug params:
#{
#    limit_parsing = {
#        character_name = "cat",
#
#        edge_type = EdgeType.JUMP_FROM_SURFACE_EDGE,
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

var graph_inspector: PlatformGraphInspector
var legend: Legend
var selection_description: SelectionDescription
var ann_defaults: AnnotationElementDefaults
var ann_manifest: SurfacerAnnotationsManifest
var movement: SurfacerMovementManifest
var edge_from_json_factory := EdgeFromJsonFactory.new()

# ---


func _ready() -> void:
    assert(has_node("/root/Sc"),
            "The Sc (Scaffolder) AutoLoad must be declared first.")
    
    Sc.logger.on_global_init(self, "Su")
    Sc.register_framework_config(self)
    
    Sc._bootstrap = SurfacerBootstrap.new()


func _amend_app_manifest(app_manifest: Dictionary) -> void:
    if !app_manifest.has("colors_class"):
            app_manifest.colors_class = SurfacerColors
    if !app_manifest.has("geometry_class"):
            app_manifest.geometry_class = SurfacerGeometry
    if !app_manifest.has("draw_utils_class"):
            app_manifest.draw_utils_class = SurfacerDrawUtils
    
    var is_precomputing_platform_graphs: bool = \
            app_manifest.surfacer_manifest \
                    .has("precompute_platform_graph_for_levels") and \
            !app_manifest.surfacer_manifest \
                    .precompute_platform_graph_for_levels.empty()
    if is_precomputing_platform_graphs:
        app_manifest.metadata.is_splash_skipped = true
    
    # Add Surfacer sounds to the front, so they can be overridden by the app.
    Sc.utils.concat(
            app_manifest.audio_manifest.sounds_manifest,
            _surfacer_sounds,
            false)
    
    if !app_manifest.gui_manifest.has("settings_item_manifest"):
        app_manifest.gui_manifest.settings_item_manifest = \
                DEFAULT_SURFACER_SETTINGS_ITEM_MANIFEST


func _register_app_manifest(app_manifest: Dictionary) -> void:
    self.manifest = app_manifest.surfacer_manifest
    
    self.are_loaded_surfaces_deeply_validated = \
            manifest.are_loaded_surfaces_deeply_validated
    self.uses_threads_for_platform_graph_calculation = \
            manifest.uses_threads_for_platform_graph_calculation
    self.debug_params = manifest.debug_params
    
    if manifest.has("default_tile_set"):
        self.default_tile_set = manifest.default_tile_set
    
    self.is_precomputing_platform_graphs = \
            manifest.has("precompute_platform_graph_for_levels") and \
            !manifest.precompute_platform_graph_for_levels.empty()
    if self.is_precomputing_platform_graphs:
        self.precompute_platform_graph_for_levels = \
                manifest.precompute_platform_graph_for_levels
    
    if manifest.has("ignores_platform_graph_save_files"):
        self.ignores_platform_graph_save_files = \
                manifest.ignores_platform_graph_save_files
    if manifest.has(
            "ignores_platform_graph_save_file_trajectory_state"):
        self.ignores_platform_graph_save_file_trajectory_state = \
                manifest \
                        .ignores_platform_graph_save_file_trajectory_state
    if manifest.has("is_debug_only_platform_graph_state_included"):
        self.is_debug_only_platform_graph_state_included = \
                manifest.is_debug_only_platform_graph_state_included
    if manifest.has("are_reachable_surfaces_per_player_tracked"):
        self.are_reachable_surfaces_per_player_tracked = \
                manifest.are_reachable_surfaces_per_player_tracked
    
    if manifest.has("path_drag_update_throttle_interval"):
        self.path_drag_update_throttle_interval = \
                manifest.path_drag_update_throttle_interval
    if manifest.has("path_beat_update_throttle_interval"):
        self.path_beat_update_throttle_interval = \
                manifest.path_beat_update_throttle_interval
    
    if manifest.has("snaps_camera_back_to_character"):
        self.snaps_camera_back_to_character = \
                manifest.snaps_camera_back_to_character
    if manifest.has("max_zoom_multiplier_from_pointer"):
        self.max_zoom_multiplier_from_pointer = \
                manifest.max_zoom_multiplier_from_pointer
    if manifest.has("max_pan_distance_from_pointer"):
        self.max_pan_distance_from_pointer = \
                manifest.max_pan_distance_from_pointer
    if manifest.has("duration_to_max_pan_from_pointer_at_max_control"):
        self.duration_to_max_pan_from_pointer_at_max_control = \
                manifest.duration_to_max_pan_from_pointer_at_max_control
    if manifest.has("duration_to_max_zoom_from_pointer_at_max_control"):
        self.duration_to_max_zoom_from_pointer_at_max_control = \
                manifest.duration_to_max_zoom_from_pointer_at_max_control
    if manifest.has(
            "screen_size_ratio_distance_from_edge_to_start_pan_from_pointer"):
        self.screen_size_ratio_distance_from_edge_to_start_pan_from_pointer = \
                manifest \
                .screen_size_ratio_distance_from_edge_to_start_pan_from_pointer
    
    if manifest.has("skip_choreography_framerate_multiplier"):
        self.skip_choreography_framerate_multiplier = \
                manifest.skip_choreography_framerate_multiplier
    
    self.behaviors = _parse_behaviors(manifest)
    
    assert(Sc._manifest.metadata.must_restart_level_to_change_settings)


func _instantiate_sub_modules() -> void:
    assert(Sc.colors is SurfacerColors)
    assert(Sc.draw is SurfacerDrawUtils)
    assert(Sc.level_config is SurfacerLevelConfig)
    assert(Sc.level_session is SurfacerLevelSession)
    
    Sc.profiler.preregister_metric_keys(non_surface_parser_metric_keys)
    Sc.profiler.preregister_metric_keys(surface_parser_metric_keys)
    
    if manifest.has("surfacer_annotations_manifest_class"):
        self.ann_manifest = manifest.surfacer_annotations_manifest_class.new()
        assert(self.ann_manifest is SurfacerAnnotationsManifest)
    else:
        self.ann_manifest = SurfacerAnnotationsManifest.new()
    add_child(self.ann_manifest)
    
    if manifest.has("surfacer_movement_manifest_class"):
        self.movement = manifest.surfacer_movement_manifest_class.new()
        assert(self.movement is SurfacerMovementManifest)
    else:
        self.movement = SurfacerMovementManifest.new()
    add_child(self.movement)


func _configure_sub_modules() -> void:
    Su.ann_manifest._register_manifest(Su.manifest.annotations_manifest)
    Su.movement._register_manifest(Su.manifest.movement_manifest)
    
    Su.movement._validate_configuration()
    
    self.is_inspector_enabled = Sc.save_state.get_setting(
            IS_INSPECTOR_ENABLED_SETTINGS_KEY,
            Sc.gui.hud_manifest.is_inspector_enabled_default)
    self.is_intro_choreography_shown = Sc.save_state.get_setting(
            IS_INTRO_CHOREOGRAPHY_SHOWN_SETTINGS_KEY,
            true)
    self.ann_manifest.is_npc_current_nav_trajectory_shown_without_slow_mo = \
            Sc.save_state.get_setting(
                    NPC_TRAJECTORY_SHOWN_SETTINGS_KEY,
                    self.ann_manifest \
                        .is_npc_current_nav_trajectory_shown_without_slow_mo)
    self.ann_manifest.is_active_trajectory_shown = \
            Sc.save_state.get_setting(
                    ACTIVE_TRAJECTORY_SHOWN_SETTINGS_KEY,
                    true)
    self.ann_manifest.is_previous_trajectory_shown = \
            Sc.save_state.get_setting(
                    PREVIOUS_TRAJECTORY_SHOWN_SETTINGS_KEY,
                    false)
    self.ann_manifest.is_preselection_trajectory_shown = \
            Sc.save_state.get_setting(
                    PRESELECTION_TRAJECTORY_SHOWN_SETTINGS_KEY,
                    true)
    self.ann_manifest.is_navigation_destination_shown = \
            Sc.save_state.get_setting(
                    NAVIGATION_DESTINATION_SHOWN_SETTINGS_KEY,
                    true)
    
    if manifest.has("annotation_element_defaults_class"):
        self.ann_defaults = manifest.annotation_element_defaults_class.new()
        assert(self.ann_defaults is AnnotationElementDefaults)
    else:
        self.ann_defaults = AnnotationElementDefaults.new()
    add_child(self.ann_defaults)


func _parse_behaviors(manifest: Dictionary) -> Dictionary:
    var behavior_classes: Array = \
            manifest.behaviors if \
            manifest.has("behavior_classes") else \
            DEFAULT_BEHAVIOR_CLASSES
    var behavior_name_to_script := {}
    for behavior_class in behavior_classes:
        behavior_name_to_script[behavior_class.NAME] = behavior_class
    return behavior_name_to_script

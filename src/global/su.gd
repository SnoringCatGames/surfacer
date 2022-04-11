tool
class_name SuInterface
extends FrameworkGlobal
## -   This is a global singleton that defines a bunch of Surfacer
##     parameters.[br]
## -   All of these parameters can be configured when bootstrapping the
##     app.[br]
## -   You will need to provide an `app_manifest` dictionary which defines some
##     of these parameters.[br]
## -   Define `Su` as an AutoLoad (in Project Settings).[br]
## -   "Su" is short for "Surfacer".[br]


# --- Constants ---

const _SCHEMA_PATH := "res://addons/surfacer/src/config/surfacer_schema.gd"

const WALLS_AND_FLOORS_COLLISION_MASK_BIT := 0
const FALL_THROUGH_FLOORS_COLLISION_MASK_BIT := 1
const WALK_THROUGH_WALLS_COLLISION_MASK_BIT := 2

const IS_INSPECTOR_ENABLED_SETTINGS_KEY := "is_inspector_enabled"
const IS_INTRO_CHOREOGRAPHY_SHOWN_SETTINGS_KEY := "is_intro_choreography_shown"

const PLAYER_PRESELECTION_TRAJECTORY_SHOWN_SETTINGS_KEY := \
        "is_player_preselection_trajectory_shown"

const PLAYER_SLOW_MO_TRAJECTORY_SHOWN_SETTINGS_KEY := \
        "is_player_slow_mo_trajectory_shown"
const PLAYER_NON_SLOW_MO_TRAJECTORY_SHOWN_SETTINGS_KEY := \
        "is_player_non_slow_mo_trajectory_shown"
const PLAYER_PREVIOUS_TRAJECTORY_SHOWN_SETTINGS_KEY := \
        "is_player_previous_trajectory_shown"
const PLAYER_NAVIGATION_DESTINATION_SHOWN_SETTINGS_KEY := \
        "is_player_navigation_destination_shown"

const NPC_SLOW_MO_TRAJECTORY_SHOWN_SETTINGS_KEY := \
        "is_npc_slow_mo_trajectory_shown"
const NPC_NON_SLOW_MO_TRAJECTORY_SHOWN_SETTINGS_KEY := \
        "is_npc_non_slow_mo_trajectory_shown"
const NPC_PREVIOUS_TRAJECTORY_SHOWN_SETTINGS_KEY := \
        "is_npc_previous_trajectory_shown"
const NPC_NAVIGATION_DESTINATION_SHOWN_SETTINGS_KEY := \
        "is_npc_navigation_destination_shown"

const PLACEHOLDER_SURFACES_TILE_SET_PATH := \
        "res://addons/surfacer/src/tiles/tileset_with_many_angles.tres"

# --- Surfacer global state ---

var are_oddly_shaped_surfaces_used: bool
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

var default_tileset: TileSet

var path_drag_update_throttle_interval := 0.2
var path_beat_update_throttle_interval := 0.2

var skip_choreography_framerate_multiplier := 10.0

# Here are some example fields for these debug params:
#{
#    limit_parsing = {
#        character_name = "cat",
#
#        edge_type = EdgeType.JUMP_FROM_SURFACE_EDGE,
##        edge_type = EdgeType.CLIMB_TO_ADJACENT_SURFACE_EDGE,
##        edge_type = EdgeType.FALL_FROM_WALL_EDGE,
##        edge_type = EdgeType.FALL_FROM_FLOOR_EDGE,
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

var graph_inspector: PlatformGraphInspector
var selection_description: SelectionDescription
var movement: SurfacerMovementManifest
var surface_properties: SurfacerSurfacePropertiesManifest
var edge_from_json_factory := EdgeFromJsonFactory.new()

var space_state: Physics2DDirectSpaceState

# ---


func _init().(_SCHEMA_PATH) -> void:
    pass


func _destroy() -> void:
    ._destroy()
    
    manifest = {}
    precompute_platform_graph_for_levels = []
    behaviors = {}
    default_tileset = null


func _get_members_to_destroy() -> Array:
    return [
        graph_inspector,
        selection_description,
        movement,
        surface_properties,
#        edge_from_json_factory,
        space_state,
    ]


func _on_auto_load_deps_ready() -> void:
    Sc._bootstrap = SurfacerBootstrap.new()


func _amend_manifest() -> void:
    var is_precomputing_platform_graphs: bool = \
            manifest.has("precompute_platform_graph_for_levels") and \
            !manifest.precompute_platform_graph_for_levels.empty()
    if is_precomputing_platform_graphs:
        Sc.manifest.metadata.is_splash_skipped = true


func _parse_manifest() -> void:
    self.are_oddly_shaped_surfaces_used = \
            manifest.are_oddly_shaped_surfaces_used
    self.are_loaded_surfaces_deeply_validated = \
            manifest.are_loaded_surfaces_deeply_validated
    self.uses_threads_for_platform_graph_calculation = \
            manifest.uses_threads_for_platform_graph_calculation
    self.debug_params = manifest.debug_params
    
    if manifest.has("default_tileset"):
        self.default_tileset = manifest.default_tileset
    
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
    
    if manifest.has("skip_choreography_framerate_multiplier"):
        self.skip_choreography_framerate_multiplier = \
                manifest.skip_choreography_framerate_multiplier
    
    self.behaviors = _parse_behaviors(manifest)
    
    assert(Sc.manifest.metadata.must_restart_level_to_change_settings)


func _instantiate_sub_modules() -> void:
    assert(Sc.draw is SurfacerDrawUtils)
    assert(Sc.level_config is SurfacerLevelConfig)
    assert(Sc.level_session is SurfacerLevelSession)
    assert(Sc.geometry is SurfacerGeometry)
    assert(Sc.characters is SurfacerCharacterManifest)
    
    if manifest.has("surfacer_movement_manifest_class"):
        self.movement = manifest.surfacer_movement_manifest_class.new()
        assert(self.movement is SurfacerMovementManifest)
    else:
        self.movement = SurfacerMovementManifest.new()
    add_child(self.movement)
    
    if manifest.has("surface_properties_class"):
        self.surface_properties = manifest.surface_properties_class.new()
        assert(self.surface_properties is SurfacerSurfacePropertiesManifest)
    else:
        self.surface_properties = SurfacerSurfacePropertiesManifest.new()
    add_child(self.surface_properties)


func _configure_sub_modules() -> void:
    Su.movement._parse_manifest(Su.manifest.movement_manifest)
    Sc.characters._derive_movement_parameters()
    Su.surface_properties._parse_manifest(
            Su.manifest.surface_properties_manifest)
    
    Su.movement._validate_configuration()
    
    self.is_inspector_enabled = Sc.save_state.get_setting(
            IS_INSPECTOR_ENABLED_SETTINGS_KEY,
            Sc.gui.hud_manifest.is_inspector_enabled_default)
    self.is_intro_choreography_shown = Sc.save_state.get_setting(
            IS_INTRO_CHOREOGRAPHY_SHOWN_SETTINGS_KEY,
            true)
    
    Sc.annotators.params.is_player_slow_mo_trajectory_shown = \
            Sc.save_state.get_setting(
                    PLAYER_SLOW_MO_TRAJECTORY_SHOWN_SETTINGS_KEY,
                    Sc.annotators.params.is_player_slow_mo_trajectory_shown)
    Sc.annotators.params.is_player_non_slow_mo_trajectory_shown = \
            Sc.save_state.get_setting(
                    PLAYER_NON_SLOW_MO_TRAJECTORY_SHOWN_SETTINGS_KEY,
                    Sc.annotators.params.is_player_non_slow_mo_trajectory_shown)
    Sc.annotators.params.is_player_previous_trajectory_shown = \
            Sc.save_state.get_setting(
                    PLAYER_PREVIOUS_TRAJECTORY_SHOWN_SETTINGS_KEY,
                    Sc.annotators.params.is_player_previous_trajectory_shown)
    Sc.annotators.params.is_player_preselection_trajectory_shown = \
            Sc.save_state.get_setting(
                    PLAYER_PRESELECTION_TRAJECTORY_SHOWN_SETTINGS_KEY,
                    Sc.annotators.params.is_player_preselection_trajectory_shown)
    Sc.annotators.params.is_player_navigation_destination_shown = \
            Sc.save_state.get_setting(
                    PLAYER_NAVIGATION_DESTINATION_SHOWN_SETTINGS_KEY,
                    Sc.annotators.params.is_player_navigation_destination_shown)
    
    Sc.annotators.params.is_npc_slow_mo_trajectory_shown = \
            Sc.save_state.get_setting(
                    NPC_SLOW_MO_TRAJECTORY_SHOWN_SETTINGS_KEY,
                    Sc.annotators.params.is_npc_slow_mo_trajectory_shown)
    Sc.annotators.params.is_npc_non_slow_mo_trajectory_shown = \
            Sc.save_state.get_setting(
                    NPC_NON_SLOW_MO_TRAJECTORY_SHOWN_SETTINGS_KEY,
                    Sc.annotators.params.is_npc_non_slow_mo_trajectory_shown)
    Sc.annotators.params.is_npc_previous_trajectory_shown = \
            Sc.save_state.get_setting(
                    NPC_PREVIOUS_TRAJECTORY_SHOWN_SETTINGS_KEY,
                    Sc.annotators.params.is_npc_previous_trajectory_shown)
    Sc.annotators.params.is_npc_navigation_destination_shown = \
            Sc.save_state.get_setting(
                    NPC_NAVIGATION_DESTINATION_SHOWN_SETTINGS_KEY,
                    Sc.annotators.params.is_npc_navigation_destination_shown)


func _parse_behaviors(manifest: Dictionary) -> Dictionary:
    var behavior_name_to_script := {}
    for behavior_class in manifest.behavior_classes:
        behavior_name_to_script[behavior_class.NAME] = behavior_class
    return behavior_name_to_script

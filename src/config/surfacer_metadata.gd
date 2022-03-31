tool
class_name SurfacerMetadata
extends FrameworkMetadata


const DISPLAY_NAME := "Surfacer"
const FOLDER_NAME := "surfacer"
const AUTO_LOAD_NAME := "Su"
const AUTO_LOAD_DEPS := ["Sc", "St"]
const AUTO_LOAD_PATH := "res://addons/surfacer/src/global/su.gd"
const PLUGIN_ICON_PATH_PREFIX := \
        "res://addons/surfacer/assets/images/editor_icons/plugin/surfacer"
const SCHEMA_PATH := "res://addons/surfacer/src/config/surfacer_schema.gd"
const MANIFEST_PATH_OVERRIDE := ""
const NON_SURFACE_PARSER_METRIC_KEYS := [
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
const SURFACE_PARSER_METRIC_KEYS := [
    "validate_tileset",
    "parse_tileset",
    "parse_tilemap_cells_into_surfaces",
    "remove_internal_surfaces",
    "merge_continuous_surfaces",
    "get_surface_list_from_map",
    "remove_internal_collinear_vertices_duration",
    "store_surfaces_duration",
    "populate_derivative_collections",
    "assign_neighbor_surfaces_duration",
    "calculate_shape_bounding_boxes_for_surfaces_duration",
    "assert_surfaces_fully_calculated_duration",
]
const MODES := {}


func _init().(
        DISPLAY_NAME,
        FOLDER_NAME,
        AUTO_LOAD_NAME,
        AUTO_LOAD_DEPS,
        AUTO_LOAD_PATH,
        PLUGIN_ICON_PATH_PREFIX,
        SCHEMA_PATH,
        MANIFEST_PATH_OVERRIDE,
        _get_combined_metric_keys(),
        MODES) -> void:
    pass


static func _get_combined_metric_keys() -> Array:
    var non_surface_parser_metric_keys_count := \
            NON_SURFACE_PARSER_METRIC_KEYS.size()
    var surface_parser_metric_keys_count := \
            SURFACE_PARSER_METRIC_KEYS.size()
    var combined_keys := []
    combined_keys.resize(
            non_surface_parser_metric_keys_count + 
            surface_parser_metric_keys_count)
    for i in non_surface_parser_metric_keys_count:
        combined_keys[i] = NON_SURFACE_PARSER_METRIC_KEYS[i]
    for i in surface_parser_metric_keys_count:
        combined_keys[i + surface_parser_metric_keys_count] = \
                SURFACE_PARSER_METRIC_KEYS[i]
    return combined_keys

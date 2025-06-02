#include "surfacer/movement_profile.h"

#include "surfacer/movement_manifest.h"

#include <godot_cpp/core/class_db.hpp>

using namespace godot;

// TODO: Port other derived logic
// (_calculate_dependent_movement_params, _parse_shape_from_parent, collider,
// fall_from_floor_corner_calc_shape, rounding_corner_calc_shape)

// TODO: Port action-handlers and edge-calculators.

// TODO: Port validation logic.

// TODO: Make sure grouping is correct.

// TODO: Port character_category_name and general character category logic.
// Figure out how to set up bitmasks, while
// allowing the client app to specify tag-name options for each bit
// (probably allow specifying names for bits in the manifest, and then allow
// specifying multi-selecting from list of registered names, and then add a
// function for translating string to bit).

void MovementProfile::_bind_methods() {
	ADD_GROUP("Movement abilities", "ability_");

	ClassDB::bind_method(
			D_METHOD("get_can_grab_walls"),
			&MovementProfile::get_can_grab_walls);
	ClassDB::bind_method(
			D_METHOD("set_can_grab_walls", "p_value"),
			&MovementProfile::set_can_grab_walls);
	ADD_PROPERTY(
			PropertyInfo(Variant::BOOL, "ability_can_grab_walls"),
			"set_can_grab_walls", "get_can_grab_walls");

	ClassDB::bind_method(
			D_METHOD("get_can_grab_ceilings"),
			&MovementProfile::get_can_grab_ceilings);
	ClassDB::bind_method(
			D_METHOD("set_can_grab_ceilings", "p_value"),
			&MovementProfile::set_can_grab_ceilings);
	ADD_PROPERTY(
			PropertyInfo(Variant::BOOL, "ability_can_grab_ceilings"),
			"set_can_grab_ceilings", "get_can_grab_ceilings");

	ClassDB::bind_method(
			D_METHOD("get_can_grab_floors"),
			&MovementProfile::get_can_grab_floors);
	ClassDB::bind_method(
			D_METHOD("set_can_grab_floors", "p_value"),
			&MovementProfile::set_can_grab_floors);
	ADD_PROPERTY(
			PropertyInfo(Variant::BOOL, "ability_can_grab_floors"),
			"set_can_grab_floors", "get_can_grab_floors");

	ClassDB::bind_method(
			D_METHOD("get_can_jump"), &MovementProfile::get_can_jump);
	ClassDB::bind_method(
			D_METHOD("set_can_jump", "p_value"),
			&MovementProfile::set_can_jump);
	ADD_PROPERTY(
			PropertyInfo(Variant::BOOL, "ability_can_jump"), "set_can_jump",
			"get_can_jump");

	ClassDB::bind_method(
			D_METHOD("get_can_dash"), &MovementProfile::get_can_dash);
	ClassDB::bind_method(
			D_METHOD("set_can_dash", "p_value"),
			&MovementProfile::set_can_dash);
	ADD_PROPERTY(
			PropertyInfo(Variant::BOOL, "ability_can_dash"), "set_can_dash",
			"get_can_dash");

	ClassDB::bind_method(
			D_METHOD("get_can_double_jump"),
			&MovementProfile::get_can_double_jump);
	ClassDB::bind_method(
			D_METHOD("set_can_double_jump", "p_value"),
			&MovementProfile::set_can_double_jump);
	ADD_PROPERTY(
			PropertyInfo(Variant::BOOL, "ability_can_double_jump"),
			"set_can_double_jump", "get_can_double_jump");

	ClassDB::bind_method(
			D_METHOD("get_can_target_in_air_destinations"),
			&MovementProfile::get_can_target_in_air_destinations);
	ClassDB::bind_method(
			D_METHOD("set_can_target_in_air_destinations", "p_value"),
			&MovementProfile::set_can_target_in_air_destinations);
	ADD_PROPERTY(
			PropertyInfo(
					Variant::BOOL, "ability_can_target_in_air_destinations"),
			"set_can_target_in_air_destinations",
			"get_can_target_in_air_destinations");

	ADD_GROUP("Physics movement", "physics_");

	ClassDB::bind_method(
			D_METHOD("get_surface_speed_multiplier"),
			&MovementProfile::get_surface_speed_multiplier);
	ClassDB::bind_method(
			D_METHOD("set_surface_speed_multiplier", "p_value"),
			&MovementProfile::set_surface_speed_multiplier);
	ADD_PROPERTY(
			PropertyInfo(
					Variant::FLOAT, "physics_surface_speed_multiplier",
					PROPERTY_HINT_RANGE, "0.1,10.0,0.1"),
			"set_surface_speed_multiplier", "get_surface_speed_multiplier");

	ClassDB::bind_method(
			D_METHOD("get_air_horizontal_speed_multiplier"),
			&MovementProfile::get_air_horizontal_speed_multiplier);
	ClassDB::bind_method(
			D_METHOD("set_air_horizontal_speed_multiplier", "p_value"),
			&MovementProfile::set_air_horizontal_speed_multiplier);
	ADD_PROPERTY(
			PropertyInfo(
					Variant::FLOAT, "physics_air_horizontal_speed_multiplier",
					PROPERTY_HINT_RANGE, "0.1,10.0,0.1"),
			"set_air_horizontal_speed_multiplier",
			"get_air_horizontal_speed_multiplier");

	ClassDB::bind_method(
			D_METHOD("get_gravity_multiplier"),
			&MovementProfile::get_gravity_multiplier);
	ClassDB::bind_method(
			D_METHOD("set_gravity_multiplier", "p_value"),
			&MovementProfile::set_gravity_multiplier);
	ADD_PROPERTY(
			PropertyInfo(
					Variant::FLOAT, "physics_gravity_multiplier",
					PROPERTY_HINT_RANGE, "0.1,10.0,0.1"),
			"set_gravity_multiplier", "get_gravity_multiplier");

	ClassDB::bind_method(
			D_METHOD("get_gravity_slow_rise_multiplier_multiplier"),
			&MovementProfile::get_gravity_slow_rise_multiplier_multiplier);
	ClassDB::bind_method(
			D_METHOD("set_gravity_slow_rise_multiplier_multiplier", "p_value"),
			&MovementProfile::set_gravity_slow_rise_multiplier_multiplier);
	ADD_PROPERTY(
			PropertyInfo(
					Variant::FLOAT,
					"physics_gravity_slow_rise_multiplier_multiplier",
					PROPERTY_HINT_RANGE, "0.1,10.0,0.1"),
			"set_gravity_slow_rise_multiplier_multiplier",
			"get_gravity_slow_rise_multiplier_multiplier");

	ClassDB::bind_method(
			D_METHOD("get_gravity_double_jump_slow_rise_multiplier_multiplier"),
			&MovementProfile::
					get_gravity_double_jump_slow_rise_multiplier_multiplier);
	ClassDB::bind_method(
			D_METHOD(
					"set_gravity_double_jump_slow_rise_multiplier_multiplier",
					"p_value"),
			&MovementProfile::
					set_gravity_double_jump_slow_rise_multiplier_multiplier);
	ADD_PROPERTY(
			PropertyInfo(
					Variant::FLOAT,
					"physics_gravity_double_jump_slow_rise_multiplier_"
					"multiplier",
					PROPERTY_HINT_RANGE, "0.1,10.0,0.1"),
			"set_gravity_double_jump_slow_rise_multiplier_multiplier",
			"get_gravity_double_jump_slow_rise_multiplier_multiplier");

	ClassDB::bind_method(
			D_METHOD("get_walk_acceleration_multiplier"),
			&MovementProfile::get_walk_acceleration_multiplier);
	ClassDB::bind_method(
			D_METHOD("set_walk_acceleration_multiplier", "p_value"),
			&MovementProfile::set_walk_acceleration_multiplier);
	ADD_PROPERTY(
			PropertyInfo(
					Variant::FLOAT, "physics_walk_acceleration_multiplier",
					PROPERTY_HINT_RANGE, "0.1,10.0,0.1"),
			"set_walk_acceleration_multiplier",
			"get_walk_acceleration_multiplier");

	ClassDB::bind_method(
			D_METHOD("get_in_air_horizontal_acceleration_multiplier"),
			&MovementProfile::get_in_air_horizontal_acceleration_multiplier);
	ClassDB::bind_method(
			D_METHOD(
					"set_in_air_horizontal_acceleration_multiplier", "p_value"),
			&MovementProfile::set_in_air_horizontal_acceleration_multiplier);
	ADD_PROPERTY(
			PropertyInfo(
					Variant::FLOAT,
					"physics_in_air_horizontal_acceleration_multiplier",
					PROPERTY_HINT_RANGE, "0.1,10.0,0.1"),
			"set_in_air_horizontal_acceleration_multiplier",
			"get_in_air_horizontal_acceleration_multiplier");

	ClassDB::bind_method(
			D_METHOD("get_climb_up_speed_multiplier"),
			&MovementProfile::get_climb_up_speed_multiplier);
	ClassDB::bind_method(
			D_METHOD("set_climb_up_speed_multiplier", "p_value"),
			&MovementProfile::set_climb_up_speed_multiplier);
	ADD_PROPERTY(
			PropertyInfo(
					Variant::FLOAT, "physics_climb_up_speed_multiplier",
					PROPERTY_HINT_RANGE, "0.1,10.0,0.1"),
			"set_climb_up_speed_multiplier", "get_climb_up_speed_multiplier");

	ClassDB::bind_method(
			D_METHOD("get_climb_down_speed_multiplier"),
			&MovementProfile::get_climb_down_speed_multiplier);
	ClassDB::bind_method(
			D_METHOD("set_climb_down_speed_multiplier", "p_value"),
			&MovementProfile::set_climb_down_speed_multiplier);
	ADD_PROPERTY(
			PropertyInfo(
					Variant::FLOAT, "physics_climb_down_speed_multiplier",
					PROPERTY_HINT_RANGE, "0.1,10.0,0.1"),
			"set_climb_down_speed_multiplier",
			"get_climb_down_speed_multiplier");

	ClassDB::bind_method(
			D_METHOD("get_ceiling_crawl_speed_multiplier"),
			&MovementProfile::get_ceiling_crawl_speed_multiplier);
	ClassDB::bind_method(
			D_METHOD("set_ceiling_crawl_speed_multiplier", "p_value"),
			&MovementProfile::set_ceiling_crawl_speed_multiplier);
	ADD_PROPERTY(
			PropertyInfo(
					Variant::FLOAT, "physics_ceiling_crawl_speed_multiplier",
					PROPERTY_HINT_RANGE, "0.1,10.0,0.1"),
			"set_ceiling_crawl_speed_multiplier",
			"get_ceiling_crawl_speed_multiplier");

	ClassDB::bind_method(
			D_METHOD("get_friction_coefficient_multiplier"),
			&MovementProfile::get_friction_coefficient_multiplier);
	ClassDB::bind_method(
			D_METHOD("set_friction_coefficient_multiplier", "p_value"),
			&MovementProfile::set_friction_coefficient_multiplier);
	ADD_PROPERTY(
			PropertyInfo(
					Variant::FLOAT, "physics_friction_coefficient_multiplier",
					PROPERTY_HINT_RANGE, "0.1,10.0,0.1"),
			"set_friction_coefficient_multiplier",
			"get_friction_coefficient_multiplier");

	ClassDB::bind_method(
			D_METHOD("get_jump_boost_multiplier"),
			&MovementProfile::get_jump_boost_multiplier);
	ClassDB::bind_method(
			D_METHOD("set_jump_boost_multiplier", "p_value"),
			&MovementProfile::set_jump_boost_multiplier);
	ADD_PROPERTY(
			PropertyInfo(
					Variant::FLOAT, "physics_jump_boost_multiplier",
					PROPERTY_HINT_RANGE, "0.1,10.0,0.1"),
			"set_jump_boost_multiplier", "get_jump_boost_multiplier");

	ClassDB::bind_method(
			D_METHOD("get_wall_jump_horizontal_boost_multiplier"),
			&MovementProfile::get_wall_jump_horizontal_boost_multiplier);
	ClassDB::bind_method(
			D_METHOD("set_wall_jump_horizontal_boost_multiplier", "p_value"),
			&MovementProfile::set_wall_jump_horizontal_boost_multiplier);
	ADD_PROPERTY(
			PropertyInfo(
					Variant::FLOAT,
					"physics_wall_jump_horizontal_boost_multiplier",
					PROPERTY_HINT_RANGE, "0.1,10.0,0.1"),
			"set_wall_jump_horizontal_boost_multiplier",
			"get_wall_jump_horizontal_boost_multiplier");

	ClassDB::bind_method(
			D_METHOD("get_wall_fall_horizontal_boost_multiplier"),
			&MovementProfile::get_wall_fall_horizontal_boost_multiplier);
	ClassDB::bind_method(
			D_METHOD("set_wall_fall_horizontal_boost_multiplier", "p_value"),
			&MovementProfile::set_wall_fall_horizontal_boost_multiplier);
	ADD_PROPERTY(
			PropertyInfo(
					Variant::FLOAT,
					"physics_wall_fall_horizontal_boost_multiplier",
					PROPERTY_HINT_RANGE, "0.1,10.0,0.1"),
			"set_wall_fall_horizontal_boost_multiplier",
			"get_wall_fall_horizontal_boost_multiplier");

	ClassDB::bind_method(
			D_METHOD("get_ceiling_fall_velocity_boost"),
			&MovementProfile::get_ceiling_fall_velocity_boost);
	ClassDB::bind_method(
			D_METHOD("set_ceiling_fall_velocity_boost", "p_value"),
			&MovementProfile::set_ceiling_fall_velocity_boost);
	ADD_PROPERTY(
			PropertyInfo(
					Variant::FLOAT, "physics_ceiling_fall_velocity_boost",
					PROPERTY_HINT_RANGE, "0.0,1000.0,1.0"),
			"set_ceiling_fall_velocity_boost",
			"get_ceiling_fall_velocity_boost");

	ClassDB::bind_method(
			D_METHOD("get_max_horizontal_speed_default_multiplier"),
			&MovementProfile::get_max_horizontal_speed_default_multiplier);
	ClassDB::bind_method(
			D_METHOD("set_max_horizontal_speed_default_multiplier", "p_value"),
			&MovementProfile::set_max_horizontal_speed_default_multiplier);
	ADD_PROPERTY(
			PropertyInfo(
					Variant::FLOAT,
					"physics_max_horizontal_speed_default_multiplier",
					PROPERTY_HINT_RANGE, "0.1,10.0,0.1"),
			"set_max_horizontal_speed_default_multiplier",
			"get_max_horizontal_speed_default_multiplier");

	ClassDB::bind_method(
			D_METHOD("get_max_vertical_speed_multiplier"),
			&MovementProfile::get_max_vertical_speed_multiplier);
	ClassDB::bind_method(
			D_METHOD("set_max_vertical_speed_multiplier", "p_value"),
			&MovementProfile::set_max_vertical_speed_multiplier);
	ADD_PROPERTY(
			PropertyInfo(
					Variant::FLOAT, "physics_max_vertical_speed_multiplier",
					PROPERTY_HINT_RANGE, "0.1,10.0,0.1"),
			"set_max_vertical_speed_multiplier",
			"get_max_vertical_speed_multiplier");

	ClassDB::bind_method(
			D_METHOD("get_fall_through_floor_velocity_boost"),
			&MovementProfile::get_fall_through_floor_velocity_boost);
	ClassDB::bind_method(
			D_METHOD("set_fall_through_floor_velocity_boost", "p_value"),
			&MovementProfile::set_fall_through_floor_velocity_boost);
	ADD_PROPERTY(
			PropertyInfo(
					Variant::FLOAT, "physics_fall_through_floor_velocity_boost",
					PROPERTY_HINT_RANGE, "0.0,1000.0,1.0"),
			"set_fall_through_floor_velocity_boost",
			"get_fall_through_floor_velocity_boost");

	ClassDB::bind_method(
			D_METHOD("get_stops_on_slope"),
			&MovementProfile::get_stops_on_slope);
	ClassDB::bind_method(
			D_METHOD("set_stops_on_slope", "p_value"),
			&MovementProfile::set_stops_on_slope);
	ADD_PROPERTY(
			PropertyInfo(Variant::BOOL, "physics_stops_on_slope"),
			"set_stops_on_slope", "get_stops_on_slope");

	ADD_GROUP("Dash", "dash_");

	ClassDB::bind_method(
			D_METHOD("get_dash_speed_multiplier_multiplier"),
			&MovementProfile::get_dash_speed_multiplier_multiplier);
	ClassDB::bind_method(
			D_METHOD("set_dash_speed_multiplier_multiplier", "p_value"),
			&MovementProfile::set_dash_speed_multiplier_multiplier);
	ADD_PROPERTY(
			PropertyInfo(
					Variant::FLOAT, "dash_speed_multiplier_multiplier",
					PROPERTY_HINT_RANGE, "0.1,10.0,0.1"),
			"set_dash_speed_multiplier_multiplier",
			"get_dash_speed_multiplier_multiplier");

	ClassDB::bind_method(
			D_METHOD("get_dash_vertical_boost_multiplier"),
			&MovementProfile::get_dash_vertical_boost_multiplier);
	ClassDB::bind_method(
			D_METHOD("set_dash_vertical_boost_multiplier", "p_value"),
			&MovementProfile::set_dash_vertical_boost_multiplier);
	ADD_PROPERTY(
			PropertyInfo(
					Variant::FLOAT, "dash_vertical_boost_multiplier",
					PROPERTY_HINT_RANGE, "0.1,10.0,0.1"),
			"set_dash_vertical_boost_multiplier",
			"get_dash_vertical_boost_multiplier");

	ClassDB::bind_method(
			D_METHOD("get_dash_duration_multiplier"),
			&MovementProfile::get_dash_duration_multiplier);
	ClassDB::bind_method(
			D_METHOD("set_dash_duration_multiplier", "p_value"),
			&MovementProfile::set_dash_duration_multiplier);
	ADD_PROPERTY(
			PropertyInfo(
					Variant::FLOAT, "dash_duration_multiplier",
					PROPERTY_HINT_RANGE, "0.1,10.0,0.1"),
			"set_dash_duration_multiplier", "get_dash_duration_multiplier");

	ClassDB::bind_method(
			D_METHOD("get_dash_fade_duration_multiplier"),
			&MovementProfile::get_dash_fade_duration_multiplier);
	ClassDB::bind_method(
			D_METHOD("set_dash_fade_duration_multiplier", "p_value"),
			&MovementProfile::set_dash_fade_duration_multiplier);
	ADD_PROPERTY(
			PropertyInfo(
					Variant::FLOAT, "dash_fade_duration_multiplier",
					PROPERTY_HINT_RANGE, "0.1,10.0,0.1"),
			"set_dash_fade_duration_multiplier",
			"get_dash_fade_duration_multiplier");

	ClassDB::bind_method(
			D_METHOD("get_dash_cooldown_multiplier"),
			&MovementProfile::get_dash_cooldown_multiplier);
	ClassDB::bind_method(
			D_METHOD("set_dash_cooldown_multiplier", "p_value"),
			&MovementProfile::set_dash_cooldown_multiplier);
	ADD_PROPERTY(
			PropertyInfo(
					Variant::FLOAT, "dash_cooldown_multiplier",
					PROPERTY_HINT_RANGE, "0.1,10.0,0.1"),
			"set_dash_cooldown_multiplier", "get_dash_cooldown_multiplier");

	ADD_GROUP("Double jump", "double_jump_");

	ClassDB::bind_method(
			D_METHOD("get_max_jump_chain"),
			&MovementProfile::get_max_jump_chain);
	ClassDB::bind_method(
			D_METHOD("set_max_jump_chain", "p_value"),
			&MovementProfile::set_max_jump_chain);
	ADD_PROPERTY(
			PropertyInfo(
					Variant::INT, "double_jump_max_jump_chain",
					PROPERTY_HINT_RANGE, "0,10,1"),
			"set_max_jump_chain", "get_max_jump_chain");

	ADD_GROUP("Edge weights", "edge_weight_");

	ClassDB::bind_method(
			D_METHOD("get_uses_duration_instead_of_distance_for_edge_weight"),
			&MovementProfile::
					get_uses_duration_instead_of_distance_for_edge_weight);
	ClassDB::bind_method(
			D_METHOD(
					"set_uses_duration_instead_of_distance_for_edge_weight",
					"p_value"),
			&MovementProfile::
					set_uses_duration_instead_of_distance_for_edge_weight);
	ADD_PROPERTY(
			PropertyInfo(
					Variant::BOOL,
					"edge_weight_uses_duration_instead_of_distance_for_edge_"
					"weight"),
			"set_uses_duration_instead_of_distance_for_edge_weight",
			"get_uses_duration_instead_of_distance_for_edge_weight");

	ClassDB::bind_method(
			D_METHOD("get_additional_edge_weight_offset_override"),
			&MovementProfile::get_additional_edge_weight_offset_override);
	ClassDB::bind_method(
			D_METHOD("set_additional_edge_weight_offset_override", "p_value"),
			&MovementProfile::set_additional_edge_weight_offset_override);
	ADD_PROPERTY(
			PropertyInfo(
					Variant::FLOAT,
					"edge_weight_additional_edge_weight_offset_override"),
			"set_additional_edge_weight_offset_override",
			"get_additional_edge_weight_offset_override");

	ClassDB::bind_method(
			D_METHOD("get_walking_edge_weight_multiplier_override"),
			&MovementProfile::get_walking_edge_weight_multiplier_override);
	ClassDB::bind_method(
			D_METHOD("set_walking_edge_weight_multiplier_override", "p_value"),
			&MovementProfile::set_walking_edge_weight_multiplier_override);
	ADD_PROPERTY(
			PropertyInfo(
					Variant::FLOAT,
					"edge_weight_walking_edge_weight_multiplier_override"),
			"set_walking_edge_weight_multiplier_override",
			"get_walking_edge_weight_multiplier_override");

	ClassDB::bind_method(
			D_METHOD("get_ceiling_crawling_edge_weight_multiplier_override"),
			&MovementProfile::
					get_ceiling_crawling_edge_weight_multiplier_override);
	ClassDB::bind_method(
			D_METHOD(
					"set_ceiling_crawling_edge_weight_multiplier_override",
					"p_value"),
			&MovementProfile::
					set_ceiling_crawling_edge_weight_multiplier_override);
	ADD_PROPERTY(
			PropertyInfo(
					Variant::FLOAT,
					"edge_weight_ceiling_crawling_edge_weight_multiplier_"
					"override"),
			"set_ceiling_crawling_edge_weight_multiplier_override",
			"get_ceiling_crawling_edge_weight_multiplier_override");

	ClassDB::bind_method(
			D_METHOD("get_climbing_edge_weight_multiplier_override"),
			&MovementProfile::get_climbing_edge_weight_multiplier_override);
	ClassDB::bind_method(
			D_METHOD("set_climbing_edge_weight_multiplier_override", "p_value"),
			&MovementProfile::set_climbing_edge_weight_multiplier_override);
	ADD_PROPERTY(
			PropertyInfo(
					Variant::FLOAT,
					"edge_weight_climbing_edge_weight_multiplier_override"),
			"set_climbing_edge_weight_multiplier_override",
			"get_climbing_edge_weight_multiplier_override");

	ClassDB::bind_method(
			D_METHOD(
					"get_climb_to_adjacent_surface_edge_weight_multiplier_"
					"override"),
			&MovementProfile::
					get_climb_to_adjacent_surface_edge_weight_multiplier_override);
	ClassDB::bind_method(
			D_METHOD(
					"set_climb_to_adjacent_surface_edge_weight_multiplier_"
					"override",
					"p_value"),
			&MovementProfile::
					set_climb_to_adjacent_surface_edge_weight_multiplier_override);
	ADD_PROPERTY(
			PropertyInfo(
					Variant::FLOAT,
					"edge_weight_climb_to_adjacent_surface_edge_weight_"
					"multiplier_"
					"override"),
			"set_climb_to_adjacent_surface_edge_weight_multiplier_override",
			"get_climb_to_adjacent_surface_edge_weight_multiplier_override");

	ClassDB::bind_method(
			D_METHOD(
					"get_move_to_collinear_surface_edge_weight_multiplier_"
					"override"),
			&MovementProfile::
					get_move_to_collinear_surface_edge_weight_multiplier_override);
	ClassDB::bind_method(
			D_METHOD(
					"set_move_to_collinear_surface_edge_weight_multiplier_"
					"override",
					"p_value"),
			&MovementProfile::
					set_move_to_collinear_surface_edge_weight_multiplier_override);
	ADD_PROPERTY(
			PropertyInfo(
					Variant::FLOAT,
					"edge_weight_move_to_collinear_surface_edge_weight_"
					"multiplier_"
					"override"),
			"set_move_to_collinear_surface_edge_weight_multiplier_override",
			"get_move_to_collinear_surface_edge_weight_multiplier_override");

	ClassDB::bind_method(
			D_METHOD("get_air_edge_weight_multiplier_override"),
			&MovementProfile::get_air_edge_weight_multiplier_override);
	ClassDB::bind_method(
			D_METHOD("set_air_edge_weight_multiplier_override", "p_value"),
			&MovementProfile::set_air_edge_weight_multiplier_override);
	ADD_PROPERTY(
			PropertyInfo(
					Variant::FLOAT,
					"edge_weight_air_edge_weight_multiplier_override"),
			"set_air_edge_weight_multiplier_override",
			"get_air_edge_weight_multiplier_override");

	ADD_GROUP("Surface graph calculations", "graph_calc_");

	ClassDB::bind_method(
			D_METHOD("get_minimizes_velocity_change_when_jumping"),
			&MovementProfile::get_minimizes_velocity_change_when_jumping);
	ClassDB::bind_method(
			D_METHOD("set_minimizes_velocity_change_when_jumping", "p_value"),
			&MovementProfile::set_minimizes_velocity_change_when_jumping);
	ADD_PROPERTY(
			PropertyInfo(
					Variant::BOOL,
					"graph_calc_minimizes_velocity_change_when_jumping"),
			"set_minimizes_velocity_change_when_jumping",
			"get_minimizes_velocity_change_when_jumping");

	ClassDB::bind_method(
			D_METHOD("get_optimizes_edge_jump_positions_at_run_time"),
			&MovementProfile::get_optimizes_edge_jump_positions_at_run_time);
	ClassDB::bind_method(
			D_METHOD(
					"set_optimizes_edge_jump_positions_at_run_time", "p_value"),
			&MovementProfile::set_optimizes_edge_jump_positions_at_run_time);
	ADD_PROPERTY(
			PropertyInfo(
					Variant::BOOL,
					"graph_calc_optimizes_edge_jump_positions_at_run_time"),
			"set_optimizes_edge_jump_positions_at_run_time",
			"get_optimizes_edge_jump_positions_at_run_time");

	ClassDB::bind_method(
			D_METHOD("get_optimizes_edge_land_positions_at_run_time"),
			&MovementProfile::get_optimizes_edge_land_positions_at_run_time);
	ClassDB::bind_method(
			D_METHOD(
					"set_optimizes_edge_land_positions_at_run_time", "p_value"),
			&MovementProfile::set_optimizes_edge_land_positions_at_run_time);
	ADD_PROPERTY(
			PropertyInfo(
					Variant::BOOL,
					"graph_calc_optimizes_edge_land_positions_at_run_time"),
			"set_optimizes_edge_land_positions_at_run_time",
			"get_optimizes_edge_land_positions_at_run_time");

	ClassDB::bind_method(
			D_METHOD("get_also_optimizes_preselection_path"),
			&MovementProfile::get_also_optimizes_preselection_path);
	ClassDB::bind_method(
			D_METHOD("set_also_optimizes_preselection_path", "p_value"),
			&MovementProfile::set_also_optimizes_preselection_path);
	ADD_PROPERTY(
			PropertyInfo(
					Variant::BOOL,
					"graph_calc_also_optimizes_preselection_path"),
			"set_also_optimizes_preselection_path",
			"get_also_optimizes_preselection_path");

	ClassDB::bind_method(
			D_METHOD("get_forces_character_position_to_match_edge_at_start"),
			&MovementProfile::
					get_forces_character_position_to_match_edge_at_start);
	ClassDB::bind_method(
			D_METHOD(
					"set_forces_character_position_to_match_edge_at_start",
					"p_value"),
			&MovementProfile::
					set_forces_character_position_to_match_edge_at_start);
	ADD_PROPERTY(
			PropertyInfo(
					Variant::BOOL,
					"graph_calc_forces_character_position_to_match_edge_at_"
					"start"),
			"set_forces_character_position_to_match_edge_at_start",
			"get_forces_character_position_to_match_edge_at_start");

	ClassDB::bind_method(
			D_METHOD("get_forces_character_velocity_to_match_edge_at_start"),
			&MovementProfile::
					get_forces_character_velocity_to_match_edge_at_start);
	ClassDB::bind_method(
			D_METHOD(
					"set_forces_character_velocity_to_match_edge_at_start",
					"p_value"),
			&MovementProfile::
					set_forces_character_velocity_to_match_edge_at_start);
	ADD_PROPERTY(
			PropertyInfo(
					Variant::BOOL,
					"graph_calc_forces_character_velocity_to_match_edge_at_"
					"start"),
			"set_forces_character_velocity_to_match_edge_at_start",
			"get_forces_character_velocity_to_match_edge_at_start");

	ClassDB::bind_method(
			D_METHOD("get_forces_character_position_to_match_path_at_end"),
			&MovementProfile::
					get_forces_character_position_to_match_path_at_end);
	ClassDB::bind_method(
			D_METHOD(
					"set_forces_character_position_to_match_path_at_end",
					"p_value"),
			&MovementProfile::
					set_forces_character_position_to_match_path_at_end);
	ADD_PROPERTY(
			PropertyInfo(
					Variant::BOOL,
					"graph_calc_forces_character_position_to_match_path_at_"
					"end"),
			"set_forces_character_position_to_match_path_at_end",
			"get_forces_character_position_to_match_path_at_end");

	ClassDB::bind_method(
			D_METHOD("get_forces_character_velocity_to_zero_at_path_end"),
			&MovementProfile::
					get_forces_character_velocity_to_zero_at_path_end);
	ClassDB::bind_method(
			D_METHOD(
					"set_forces_character_velocity_to_zero_at_path_end",
					"p_value"),
			&MovementProfile::
					set_forces_character_velocity_to_zero_at_path_end);
	ADD_PROPERTY(
			PropertyInfo(
					Variant::BOOL,
					"graph_calc_forces_character_velocity_to_zero_at_path_end"),
			"set_forces_character_velocity_to_zero_at_path_end",
			"get_forces_character_velocity_to_zero_at_path_end");

	ClassDB::bind_method(
			D_METHOD("get_syncs_character_position_to_edge_trajectory"),
			&MovementProfile::get_syncs_character_position_to_edge_trajectory);
	ClassDB::bind_method(
			D_METHOD(
					"set_syncs_character_position_to_edge_trajectory",
					"p_value"),
			&MovementProfile::set_syncs_character_position_to_edge_trajectory);
	ADD_PROPERTY(
			PropertyInfo(
					Variant::BOOL,
					"graph_calc_syncs_character_position_to_edge_trajectory"),
			"set_syncs_character_position_to_edge_trajectory",
			"get_syncs_character_position_to_edge_trajectory");

	ClassDB::bind_method(
			D_METHOD("get_syncs_character_velocity_to_edge_trajectory"),
			&MovementProfile::get_syncs_character_velocity_to_edge_trajectory);
	ClassDB::bind_method(
			D_METHOD(
					"set_syncs_character_velocity_to_edge_trajectory",
					"p_value"),
			&MovementProfile::set_syncs_character_velocity_to_edge_trajectory);
	ADD_PROPERTY(
			PropertyInfo(
					Variant::BOOL,
					"graph_calc_syncs_character_velocity_to_edge_trajectory"),
			"set_syncs_character_velocity_to_edge_trajectory",
			"get_syncs_character_velocity_to_edge_trajectory");

	ClassDB::bind_method(
			D_METHOD("get_includes_continuous_trajectory_positions"),
			&MovementProfile::get_includes_continuous_trajectory_positions);
	ClassDB::bind_method(
			D_METHOD("set_includes_continuous_trajectory_positions", "p_value"),
			&MovementProfile::set_includes_continuous_trajectory_positions);
	ADD_PROPERTY(
			PropertyInfo(
					Variant::BOOL,
					"graph_calc_includes_continuous_trajectory_positions"),
			"set_includes_continuous_trajectory_positions",
			"get_includes_continuous_trajectory_positions");

	ClassDB::bind_method(
			D_METHOD("get_includes_continuous_trajectory_velocities"),
			&MovementProfile::get_includes_continuous_trajectory_velocities);
	ClassDB::bind_method(
			D_METHOD(
					"set_includes_continuous_trajectory_velocities", "p_value"),
			&MovementProfile::set_includes_continuous_trajectory_velocities);
	ADD_PROPERTY(
			PropertyInfo(
					Variant::BOOL,
					"graph_calc_includes_continuous_trajectory_velocities"),
			"set_includes_continuous_trajectory_velocities",
			"get_includes_continuous_trajectory_velocities");

	ClassDB::bind_method(
			D_METHOD("get_includes_discrete_trajectory_state"),
			&MovementProfile::get_includes_discrete_trajectory_state);
	ClassDB::bind_method(
			D_METHOD("set_includes_discrete_trajectory_state", "p_value"),
			&MovementProfile::set_includes_discrete_trajectory_state);
	ADD_PROPERTY(
			PropertyInfo(
					Variant::BOOL,
					"graph_calc_includes_discrete_trajectory_state"),
			"set_includes_discrete_trajectory_state",
			"get_includes_discrete_trajectory_state");

	ClassDB::bind_method(
			D_METHOD("get_is_trajectory_state_stored_at_build_time"),
			&MovementProfile::get_is_trajectory_state_stored_at_build_time);
	ClassDB::bind_method(
			D_METHOD("set_is_trajectory_state_stored_at_build_time", "p_value"),
			&MovementProfile::set_is_trajectory_state_stored_at_build_time);
	ADD_PROPERTY(
			PropertyInfo(
					Variant::BOOL,
					"graph_calc_is_trajectory_state_stored_at_build_time"),
			"set_is_trajectory_state_stored_at_build_time",
			"get_is_trajectory_state_stored_at_build_time");

	ClassDB::bind_method(
			D_METHOD("get_bypasses_runtime_physics"),
			&MovementProfile::get_bypasses_runtime_physics);
	ClassDB::bind_method(
			D_METHOD("set_bypasses_runtime_physics", "p_value"),
			&MovementProfile::set_bypasses_runtime_physics);
	ADD_PROPERTY(
			PropertyInfo(Variant::BOOL, "graph_calc_bypasses_runtime_physics"),
			"set_bypasses_runtime_physics", "get_bypasses_runtime_physics");

	ClassDB::bind_method(
			D_METHOD("get_default_nav_interrupt_resolution_mode"),
			&MovementProfile::get_default_nav_interrupt_resolution_mode);
	ClassDB::bind_method(
			D_METHOD("set_default_nav_interrupt_resolution_mode", "p_value"),
			&MovementProfile::set_default_nav_interrupt_resolution_mode);
	ADD_PROPERTY(
			PropertyInfo(
					Variant::INT,
					"graph_calc_default_nav_interrupt_resolution_mode"),
			"set_default_nav_interrupt_resolution_mode",
			"get_default_nav_interrupt_resolution_mode");

	ClassDB::bind_method(
			D_METHOD("get_min_intra_surface_distance_to_optimize_jump_for"),
			&MovementProfile::
					get_min_intra_surface_distance_to_optimize_jump_for);
	ClassDB::bind_method(
			D_METHOD(
					"set_min_intra_surface_distance_to_optimize_jump_for",
					"p_value"),
			&MovementProfile::
					set_min_intra_surface_distance_to_optimize_jump_for);
	ADD_PROPERTY(
			PropertyInfo(
					Variant::FLOAT,
					"graph_calc_min_intra_surface_distance_to_optimize_jump_"
					"for"),
			"set_min_intra_surface_distance_to_optimize_jump_for",
			"get_min_intra_surface_distance_to_optimize_jump_for");

	ClassDB::bind_method(
			D_METHOD(
					"get_dist_sq_thres_for_considering_additional_jump_land_"
					"points"),
			&MovementProfile::
					get_dist_sq_thres_for_considering_additional_jump_land_points);
	ClassDB::bind_method(
			D_METHOD(
					"set_dist_sq_thres_for_considering_additional_jump_land_"
					"points",
					"p_value"),
			&MovementProfile::
					set_dist_sq_thres_for_considering_additional_jump_land_points);
	ADD_PROPERTY(
			PropertyInfo(
					Variant::FLOAT,
					"graph_calc_dist_sq_thres_for_considering_additional_jump_"
					"land_"
					"points"),
			"set_dist_sq_thres_for_considering_additional_jump_land_points",
			"get_dist_sq_thres_for_considering_additional_jump_land_points");

	ClassDB::bind_method(
			D_METHOD(
					"get_stops_after_finding_first_valid_edge_for_a_surface_"
					"pair"),
			&MovementProfile::
					get_stops_after_finding_first_valid_edge_for_a_surface_pair);
	ClassDB::bind_method(
			D_METHOD(
					"set_stops_after_finding_first_valid_edge_for_a_surface_"
					"pair",
					"p_value"),
			&MovementProfile::
					set_stops_after_finding_first_valid_edge_for_a_surface_pair);
	ADD_PROPERTY(
			PropertyInfo(
					Variant::BOOL,
					"graph_calc_stops_after_finding_first_valid_edge_for_a_"
					"surface_"
					"pair"),
			"set_stops_after_finding_first_valid_edge_for_a_surface_pair",
			"get_stops_after_finding_first_valid_edge_for_a_surface_pair");

	ClassDB::bind_method(
			D_METHOD("get_calculates_all_valid_edges_for_a_surface_pair"),
			&MovementProfile::
					get_calculates_all_valid_edges_for_a_surface_pair);
	ClassDB::bind_method(
			D_METHOD(
					"set_calculates_all_valid_edges_for_a_surface_pair",
					"p_value"),
			&MovementProfile::
					set_calculates_all_valid_edges_for_a_surface_pair);
	ADD_PROPERTY(
			PropertyInfo(
					Variant::BOOL,
					"graph_calc_calculates_all_valid_edges_for_a_surface_pair"),
			"set_calculates_all_valid_edges_for_a_surface_pair",
			"get_calculates_all_valid_edges_for_a_surface_pair");

	ClassDB::bind_method(
			D_METHOD("get_always_includes_jump_land_positions_at_surface_ends"),
			&MovementProfile::
					get_always_includes_jump_land_positions_at_surface_ends);
	ClassDB::bind_method(
			D_METHOD(
					"set_always_includes_jump_land_positions_at_surface_ends",
					"p_value"),
			&MovementProfile::
					set_always_includes_jump_land_positions_at_surface_ends);
	ADD_PROPERTY(
			PropertyInfo(
					Variant::BOOL,
					"graph_calc_always_includes_jump_land_positions_at_surface_"
					"ends"),
			"set_always_includes_jump_land_positions_at_surface_ends",
			"get_always_includes_jump_land_positions_at_surface_ends");

	ClassDB::bind_method(
			D_METHOD(
					"get_includes_redundant_j_l_positions_with_zero_start_"
					"velocity"),
			&MovementProfile::
					get_includes_redundant_j_l_positions_with_zero_start_velocity);
	ClassDB::bind_method(
			D_METHOD(
					"set_includes_redundant_j_l_positions_with_zero_start_"
					"velocity",
					"p_value"),
			&MovementProfile::
					set_includes_redundant_j_l_positions_with_zero_start_velocity);
	ADD_PROPERTY(
			PropertyInfo(
					Variant::BOOL,
					"graph_calc_includes_redundant_j_l_positions_with_zero_"
					"start_"
					"velocity"),
			"set_includes_redundant_j_l_positions_with_zero_start_velocity",
			"get_includes_redundant_j_l_positions_with_zero_start_velocity");

	ClassDB::bind_method(
			D_METHOD("get_normal_jump_instruction_duration_increase"),
			&MovementProfile::get_normal_jump_instruction_duration_increase);
	ClassDB::bind_method(
			D_METHOD(
					"set_normal_jump_instruction_duration_increase", "p_value"),
			&MovementProfile::set_normal_jump_instruction_duration_increase);
	ADD_PROPERTY(
			PropertyInfo(
					Variant::FLOAT,
					"graph_calc_normal_jump_instruction_duration_increase"),
			"set_normal_jump_instruction_duration_increase",
			"get_normal_jump_instruction_duration_increase");

	ClassDB::bind_method(
			D_METHOD("get_exceptional_jump_instruction_duration_increase"),
			&MovementProfile::
					get_exceptional_jump_instruction_duration_increase);
	ClassDB::bind_method(
			D_METHOD(
					"set_exceptional_jump_instruction_duration_increase",
					"p_value"),
			&MovementProfile::
					set_exceptional_jump_instruction_duration_increase);
	ADD_PROPERTY(
			PropertyInfo(
					Variant::FLOAT,
					"graph_calc_exceptional_jump_instruction_duration_"
					"increase"),
			"set_exceptional_jump_instruction_duration_increase",
			"get_exceptional_jump_instruction_duration_increase");

	ClassDB::bind_method(
			D_METHOD(
					"get_recurses_when_colliding_during_horizontal_step_"
					"calculations"),
			&MovementProfile::
					get_recurses_when_colliding_during_horizontal_step_calculations);
	ClassDB::bind_method(
			D_METHOD(
					"set_recurses_when_colliding_during_horizontal_step_"
					"calculations",
					"p_value"),
			&MovementProfile::
					set_recurses_when_colliding_during_horizontal_step_calculations);
	ADD_PROPERTY(
			PropertyInfo(
					Variant::BOOL,
					"graph_calc_recurses_when_colliding_during_horizontal_step_"
					"calculations"),
			"set_recurses_when_colliding_during_horizontal_step_calculations",
			"get_recurses_when_colliding_during_horizontal_step_calculations");

	ClassDB::bind_method(
			D_METHOD(
					"get_backtracks_for_higher_jumps_during_hor_step_"
					"calculations"),
			&MovementProfile::
					get_backtracks_for_higher_jumps_during_hor_step_calculations);
	ClassDB::bind_method(
			D_METHOD(
					"set_backtracks_for_higher_jumps_during_hor_step_"
					"calculations",
					"p_value"),
			&MovementProfile::
					set_backtracks_for_higher_jumps_during_hor_step_calculations);
	ADD_PROPERTY(
			PropertyInfo(
					Variant::BOOL,
					"graph_calc_backtracks_for_higher_jumps_during_hor_step_"
					"calculations"),
			"set_backtracks_for_higher_jumps_during_hor_step_calculations",
			"get_backtracks_for_higher_jumps_during_hor_step_calculations");

	ClassDB::bind_method(
			D_METHOD("get_collision_margin_for_edge_calculations"),
			&MovementProfile::get_collision_margin_for_edge_calculations);
	ClassDB::bind_method(
			D_METHOD("set_collision_margin_for_edge_calculations", "p_value"),
			&MovementProfile::set_collision_margin_for_edge_calculations);
	ADD_PROPERTY(
			PropertyInfo(
					Variant::FLOAT,
					"graph_calc_collision_margin_for_edge_calculations"),
			"set_collision_margin_for_edge_calculations",
			"get_collision_margin_for_edge_calculations");

	ClassDB::bind_method(
			D_METHOD("get_collision_margin_for_waypoint_positions"),
			&MovementProfile::get_collision_margin_for_waypoint_positions);
	ClassDB::bind_method(
			D_METHOD("set_collision_margin_for_waypoint_positions", "p_value"),
			&MovementProfile::set_collision_margin_for_waypoint_positions);
	ADD_PROPERTY(
			PropertyInfo(
					Variant::FLOAT,
					"graph_calc_collision_margin_for_waypoint_positions"),
			"set_collision_margin_for_waypoint_positions",
			"get_collision_margin_for_waypoint_positions");

	ClassDB::bind_method(
			D_METHOD("get_skips_less_likely_jump_land_positions"),
			&MovementProfile::get_skips_less_likely_jump_land_positions);
	ClassDB::bind_method(
			D_METHOD("set_skips_less_likely_jump_land_positions", "p_value"),
			&MovementProfile::set_skips_less_likely_jump_land_positions);
	ADD_PROPERTY(
			PropertyInfo(
					Variant::BOOL,
					"graph_calc_skips_less_likely_jump_land_positions"),
			"set_skips_less_likely_jump_land_positions",
			"get_skips_less_likely_jump_land_positions");

	ClassDB::bind_method(
			D_METHOD(
					"get_prevents_path_ends_from_exceeding_surface_ends_with_"
					"offsets"),
			&MovementProfile::
					get_prevents_path_ends_from_exceeding_surface_ends_with_offsets);
	ClassDB::bind_method(
			D_METHOD(
					"set_prevents_path_ends_from_exceeding_surface_ends_with_"
					"offsets",
					"p_value"),
			&MovementProfile::
					set_prevents_path_ends_from_exceeding_surface_ends_with_offsets);
	ADD_PROPERTY(
			PropertyInfo(
					Variant::BOOL,
					"graph_calc_prevents_path_ends_from_exceeding_surface_ends_"
					"with_"
					"offsets"),
			"set_prevents_path_ends_from_exceeding_surface_ends_with_offsets",
			"get_prevents_path_ends_from_exceeding_surface_ends_with_offsets");

	ClassDB::bind_method(
			D_METHOD(
					"get_reuses_previous_waypoints_when_backtracking_on_jump_"
					"height"),
			&MovementProfile::
					get_reuses_previous_waypoints_when_backtracking_on_jump_height);
	ClassDB::bind_method(
			D_METHOD(
					"set_reuses_previous_waypoints_when_backtracking_on_jump_"
					"height",
					"p_value"),
			&MovementProfile::
					set_reuses_previous_waypoints_when_backtracking_on_jump_height);
	ADD_PROPERTY(
			PropertyInfo(
					Variant::BOOL,
					"graph_calc_reuses_previous_waypoints_when_backtracking_on_"
					"jump_"
					"height"),
			"set_reuses_previous_waypoints_when_backtracking_on_jump_height",
			"get_reuses_previous_waypoints_when_backtracking_on_jump_height");

	ClassDB::bind_method(
			D_METHOD(
					"get_asserts_no_preexisting_collisions_during_edge_"
					"calculations"),
			&MovementProfile::
					get_asserts_no_preexisting_collisions_during_edge_calculations);
	ClassDB::bind_method(
			D_METHOD(
					"set_asserts_no_preexisting_collisions_during_edge_"
					"calculations",
					"p_value"),
			&MovementProfile::
					set_asserts_no_preexisting_collisions_during_edge_calculations);
	ADD_PROPERTY(
			PropertyInfo(
					Variant::BOOL,
					"graph_calc_asserts_no_preexisting_collisions_during_edge_"
					"calculations"),
			"set_asserts_no_preexisting_collisions_during_edge_calculations",
			"get_asserts_no_preexisting_collisions_during_edge_calculations");

	ClassDB::bind_method(
			D_METHOD(
					"get_checks_for_alt_intersection_points_for_oblique_"
					"collisions"),
			&MovementProfile::
					get_checks_for_alt_intersection_points_for_oblique_collisions);
	ClassDB::bind_method(
			D_METHOD(
					"set_checks_for_alt_intersection_points_for_oblique_"
					"collisions",
					"p_value"),
			&MovementProfile::
					set_checks_for_alt_intersection_points_for_oblique_collisions);
	ADD_PROPERTY(
			PropertyInfo(
					Variant::BOOL,
					"graph_calc_checks_for_alt_intersection_points_for_oblique_"
					"collisions"),
			"set_checks_for_alt_intersection_points_for_oblique_collisions",
			"get_checks_for_alt_intersection_points_for_oblique_collisions");

	ClassDB::bind_method(
			D_METHOD("get_oblique_collison_normal_aspect_ratio_threshold"),
			&MovementProfile::
					get_oblique_collison_normal_aspect_ratio_threshold);
	ClassDB::bind_method(
			D_METHOD(
					"set_oblique_collison_normal_aspect_ratio_threshold",
					"p_value"),
			&MovementProfile::
					set_oblique_collison_normal_aspect_ratio_threshold);
	ADD_PROPERTY(
			PropertyInfo(
					Variant::FLOAT,
					"graph_calc_oblique_collison_normal_aspect_ratio_"
					"threshold"),
			"set_oblique_collison_normal_aspect_ratio_threshold",
			"get_oblique_collison_normal_aspect_ratio_threshold");

	ClassDB::bind_method(
			D_METHOD(
					"get_min_frame_count_when_colliding_early_with_expected_"
					"surface"),
			&MovementProfile::
					get_min_frame_count_when_colliding_early_with_expected_surface);
	ClassDB::bind_method(
			D_METHOD(
					"set_min_frame_count_when_colliding_early_with_expected_"
					"surface",
					"p_value"),
			&MovementProfile::
					set_min_frame_count_when_colliding_early_with_expected_surface);
	ADD_PROPERTY(
			PropertyInfo(
					Variant::INT,
					"graph_calc_min_frame_count_when_colliding_early_with_"
					"expected_"
					"surface"),
			"set_min_frame_count_when_colliding_early_with_expected_surface",
			"get_min_frame_count_when_colliding_early_with_expected_surface");

	ClassDB::bind_method(
			D_METHOD(
					"get_reached_in_air_destination_distance_squared_"
					"threshold"),
			&MovementProfile::
					get_reached_in_air_destination_distance_squared_threshold);
	ClassDB::bind_method(
			D_METHOD(
					"set_reached_in_air_destination_distance_squared_threshold",
					"p_value"),
			&MovementProfile::
					set_reached_in_air_destination_distance_squared_threshold);
	ADD_PROPERTY(
			PropertyInfo(
					Variant::FLOAT,
					"graph_calc_reached_in_air_destination_distance_squared_"
					"threshold"),
			"set_reached_in_air_destination_distance_squared_threshold",
			"get_reached_in_air_destination_distance_squared_threshold");

	ClassDB::bind_method(
			D_METHOD(
					"get_max_edges_to_remove_from_path_for_opt_to_in_air_dest"),
			&MovementProfile::
					get_max_edges_to_remove_from_path_for_opt_to_in_air_dest);
	ClassDB::bind_method(
			D_METHOD(
					"set_max_edges_to_remove_from_path_for_opt_to_in_air_dest",
					"p_value"),
			&MovementProfile::
					set_max_edges_to_remove_from_path_for_opt_to_in_air_dest);
	ADD_PROPERTY(
			PropertyInfo(
					Variant::INT,
					"graph_calc_max_edges_to_remove_from_path_for_opt_to_in_"
					"air_"
					"dest"),
			"set_max_edges_to_remove_from_path_for_opt_to_in_air_dest",
			"get_max_edges_to_remove_from_path_for_opt_to_in_air_dest");

	ClassDB::bind_method(
			D_METHOD("get_always_tries_to_face_direction_of_motion"),
			&MovementProfile::get_always_tries_to_face_direction_of_motion);
	ClassDB::bind_method(
			D_METHOD("set_always_tries_to_face_direction_of_motion", "p_value"),
			&MovementProfile::set_always_tries_to_face_direction_of_motion);
	ADD_PROPERTY(
			PropertyInfo(
					Variant::BOOL,
					"graph_calc_always_tries_to_face_direction_of_motion"),
			"set_always_tries_to_face_direction_of_motion",
			"get_always_tries_to_face_direction_of_motion");

	ClassDB::bind_method(
			D_METHOD("get_max_distance_for_reachable_surface_tracking"),
			&MovementProfile::get_max_distance_for_reachable_surface_tracking);
	ClassDB::bind_method(
			D_METHOD(
					"set_max_distance_for_reachable_surface_tracking",
					"p_value"),
			&MovementProfile::set_max_distance_for_reachable_surface_tracking);
	ADD_PROPERTY(
			PropertyInfo(
					Variant::FLOAT,
					"graph_calc_max_distance_for_reachable_surface_tracking"),
			"set_max_distance_for_reachable_surface_tracking",
			"get_max_distance_for_reachable_surface_tracking");

	ClassDB::bind_method(
			D_METHOD("get_gravity_fast_fall"),
			&MovementProfile::get_gravity_fast_fall);
	ADD_PROPERTY(
			PropertyInfo(Variant::FLOAT, "graph_calc_gravity_fast_fall"), "",
			"get_gravity_fast_fall");

	ClassDB::bind_method(
			D_METHOD("get_slow_rise_gravity_multiplier"),
			&MovementProfile::get_slow_rise_gravity_multiplier);
	ADD_PROPERTY(
			PropertyInfo(
					Variant::FLOAT, "graph_calc_slow_rise_gravity_multiplier"),
			"", "get_slow_rise_gravity_multiplier");

	ClassDB::bind_method(
			D_METHOD("get_gravity_slow_rise"),
			&MovementProfile::get_gravity_slow_rise);
	ADD_PROPERTY(
			PropertyInfo(Variant::FLOAT, "graph_calc_gravity_slow_rise"), "",
			"get_gravity_slow_rise");

	ClassDB::bind_method(
			D_METHOD("get_rise_double_jump_gravity_multiplier"),
			&MovementProfile::get_rise_double_jump_gravity_multiplier);
	ADD_PROPERTY(
			PropertyInfo(
					Variant::FLOAT,
					"graph_calc_rise_double_jump_gravity_multiplier"),
			"", "get_rise_double_jump_gravity_multiplier");

	ClassDB::bind_method(
			D_METHOD("get_rise_double_jump_gravity"),
			&MovementProfile::get_rise_double_jump_gravity);
	ADD_PROPERTY(
			PropertyInfo(Variant::FLOAT, "graph_calc_rise_double_jump_gravity"),
			"", "get_rise_double_jump_gravity");

	ClassDB::bind_method(
			D_METHOD("get_walk_acceleration"),
			&MovementProfile::get_walk_acceleration);
	ADD_PROPERTY(
			PropertyInfo(Variant::FLOAT, "graph_calc_walk_acceleration"), "",
			"get_walk_acceleration");

	ClassDB::bind_method(
			D_METHOD("get_in_air_horizontal_acceleration"),
			&MovementProfile::get_in_air_horizontal_acceleration);
	ADD_PROPERTY(
			PropertyInfo(
					Variant::FLOAT,
					"graph_calc_in_air_horizontal_acceleration"),
			"", "get_in_air_horizontal_acceleration");

	ClassDB::bind_method(
			D_METHOD("get_climb_up_speed"),
			&MovementProfile::get_climb_up_speed);
	ADD_PROPERTY(
			PropertyInfo(Variant::FLOAT, "graph_calc_climb_up_speed"), "",
			"get_climb_up_speed");

	ClassDB::bind_method(
			D_METHOD("get_climb_down_speed"),
			&MovementProfile::get_climb_down_speed);
	ADD_PROPERTY(
			PropertyInfo(Variant::FLOAT, "graph_calc_climb_down_speed"), "",
			"get_climb_down_speed");

	ClassDB::bind_method(
			D_METHOD("get_ceiling_crawl_speed"),
			&MovementProfile::get_ceiling_crawl_speed);
	ADD_PROPERTY(
			PropertyInfo(Variant::FLOAT, "graph_calc_ceiling_crawl_speed"), "",
			"get_ceiling_crawl_speed");

	ClassDB::bind_method(
			D_METHOD("get_friction_coeff_with_sideways_input"),
			&MovementProfile::get_friction_coeff_with_sideways_input);
	ADD_PROPERTY(
			PropertyInfo(
					Variant::FLOAT,
					"graph_calc_friction_coeff_with_sideways_input"),
			"", "get_friction_coeff_with_sideways_input");

	ClassDB::bind_method(
			D_METHOD("get_friction_coeff_without_sideways_input"),
			&MovementProfile::get_friction_coeff_without_sideways_input);
	ADD_PROPERTY(
			PropertyInfo(
					Variant::FLOAT,
					"graph_calc_friction_coeff_without_sideways_input"),
			"", "get_friction_coeff_without_sideways_input");

	ClassDB::bind_method(
			D_METHOD("get_jump_boost"), &MovementProfile::get_jump_boost);
	ADD_PROPERTY(
			PropertyInfo(Variant::FLOAT, "graph_calc_jump_boost"), "",
			"get_jump_boost");

	ClassDB::bind_method(
			D_METHOD("get_wall_jump_horizontal_boost"),
			&MovementProfile::get_wall_jump_horizontal_boost);
	ADD_PROPERTY(
			PropertyInfo(
					Variant::FLOAT, "graph_calc_wall_jump_horizontal_boost"),
			"", "get_wall_jump_horizontal_boost");

	ClassDB::bind_method(
			D_METHOD("get_wall_fall_horizontal_boost"),
			&MovementProfile::get_wall_fall_horizontal_boost);
	ADD_PROPERTY(
			PropertyInfo(
					Variant::FLOAT, "graph_calc_wall_fall_horizontal_boost"),
			"", "get_wall_fall_horizontal_boost");

	ClassDB::bind_method(
			D_METHOD("get_max_horizontal_speed_default"),
			&MovementProfile::get_max_horizontal_speed_default);
	ADD_PROPERTY(
			PropertyInfo(
					Variant::FLOAT, "graph_calc_max_horizontal_speed_default"),
			"", "get_max_horizontal_speed_default");

	ClassDB::bind_method(
			D_METHOD("get_max_vertical_speed"),
			&MovementProfile::get_max_vertical_speed);
	ADD_PROPERTY(
			PropertyInfo(Variant::FLOAT, "graph_calc_max_vertical_speed"), "",
			"get_max_vertical_speed");

	ClassDB::bind_method(
			D_METHOD("get_max_possible_speed"),
			&MovementProfile::get_max_possible_speed);
	ADD_PROPERTY(
			PropertyInfo(Variant::FLOAT, "graph_calc_max_possible_speed"), "",
			"get_max_possible_speed");

	ClassDB::bind_method(
			D_METHOD("get_dash_speed_multiplier"),
			&MovementProfile::get_dash_speed_multiplier);
	ADD_PROPERTY(
			PropertyInfo(Variant::FLOAT, "graph_calc_dash_speed_multiplier"),
			"", "get_dash_speed_multiplier");

	ClassDB::bind_method(
			D_METHOD("get_dash_vertical_boost"),
			&MovementProfile::get_dash_vertical_boost);
	ADD_PROPERTY(
			PropertyInfo(Variant::FLOAT, "graph_calc_dash_vertical_boost"), "",
			"get_dash_vertical_boost");

	ClassDB::bind_method(
			D_METHOD("get_dash_duration"), &MovementProfile::get_dash_duration);
	ADD_PROPERTY(
			PropertyInfo(Variant::FLOAT, "graph_calc_dash_duration"), "",
			"get_dash_duration");

	ClassDB::bind_method(
			D_METHOD("get_dash_fade_duration"),
			&MovementProfile::get_dash_fade_duration);
	ADD_PROPERTY(
			PropertyInfo(Variant::FLOAT, "graph_calc_dash_fade_duration"), "",
			"get_dash_fade_duration");

	ClassDB::bind_method(
			D_METHOD("get_dash_cooldown"), &MovementProfile::get_dash_cooldown);
	ADD_PROPERTY(
			PropertyInfo(Variant::FLOAT, "graph_calc_dash_cooldown"), "",
			"get_dash_cooldown");

	ClassDB::bind_method(
			D_METHOD("get_additional_edge_weight_offset"),
			&MovementProfile::get_additional_edge_weight_offset);
	ADD_PROPERTY(
			PropertyInfo(
					Variant::FLOAT, "graph_calc_additional_edge_weight_offset"),
			"", "get_additional_edge_weight_offset");

	ClassDB::bind_method(
			D_METHOD("get_walking_edge_weight_multiplier"),
			&MovementProfile::get_walking_edge_weight_multiplier);
	ADD_PROPERTY(
			PropertyInfo(
					Variant::FLOAT,
					"graph_calc_walking_edge_weight_multiplier"),
			"", "get_walking_edge_weight_multiplier");

	ClassDB::bind_method(
			D_METHOD("get_ceiling_crawling_edge_weight_multiplier"),
			&MovementProfile::get_ceiling_crawling_edge_weight_multiplier);
	ADD_PROPERTY(
			PropertyInfo(
					Variant::FLOAT,
					"graph_calc_ceiling_crawling_edge_weight_multiplier"),
			"", "get_ceiling_crawling_edge_weight_multiplier");

	ClassDB::bind_method(
			D_METHOD("get_climbing_edge_weight_multiplier"),
			&MovementProfile::get_climbing_edge_weight_multiplier);
	ADD_PROPERTY(
			PropertyInfo(
					Variant::FLOAT,
					"graph_calc_climbing_edge_weight_multiplier"),
			"", "get_climbing_edge_weight_multiplier");

	ClassDB::bind_method(
			D_METHOD("get_climb_to_adjacent_surface_edge_weight_multiplier"),
			&MovementProfile::
					get_climb_to_adjacent_surface_edge_weight_multiplier);
	ADD_PROPERTY(
			PropertyInfo(
					Variant::FLOAT,
					"graph_calc_climb_to_adjacent_surface_edge_weight_"
					"multiplier"),
			"", "get_climb_to_adjacent_surface_edge_weight_multiplier");

	ClassDB::bind_method(
			D_METHOD("get_move_to_collinear_surface_edge_weight_multiplier"),
			&MovementProfile::
					get_move_to_collinear_surface_edge_weight_multiplier);
	ADD_PROPERTY(
			PropertyInfo(
					Variant::FLOAT,
					"graph_calc_move_to_collinear_surface_edge_weight_"
					"multiplier"),
			"", "get_move_to_collinear_surface_edge_weight_multiplier");

	ClassDB::bind_method(
			D_METHOD("get_air_edge_weight_multiplier"),
			&MovementProfile::get_air_edge_weight_multiplier);
	ADD_PROPERTY(
			PropertyInfo(
					Variant::FLOAT, "graph_calc_air_edge_weight_multiplier"),
			"", "get_air_edge_weight_multiplier");

	ClassDB::bind_method(
			D_METHOD("get_max_surface_speed"),
			&MovementProfile::get_max_surface_speed);
	ADD_PROPERTY(
			PropertyInfo(Variant::FLOAT, "graph_calc_max_surface_speed"), "",
			"get_max_surface_speed");

	ClassDB::bind_method(
			D_METHOD("get_max_air_horizontal_speed"),
			&MovementProfile::get_max_air_horizontal_speed);
	ADD_PROPERTY(
			PropertyInfo(Variant::FLOAT, "graph_calc_max_air_horizontal_speed"),
			"", "get_max_air_horizontal_speed");

	ClassDB::bind_method(
			D_METHOD("get_smaller_of_max_surface_and_air_horizontal_speed"),
			&MovementProfile::
					get_smaller_of_max_surface_and_air_horizontal_speed);
	ADD_PROPERTY(
			PropertyInfo(
					Variant::FLOAT,
					"graph_calc_smaller_of_max_surface_and_air_horizontal_"
					"speed"),
			"", "get_smaller_of_max_surface_and_air_horizontal_speed");
}

void MovementProfile::on_parameter_updated() {
	// TODO: Port from old MovementParameters._update_parameters_debounced().
}

float MovementProfile::get_gravity_fast_fall() const {
	return gravity_multiplier * MovementManifest::get()->get_gravity_default();
}

float MovementProfile::get_slow_rise_gravity_multiplier() const {
	return gravity_slow_rise_multiplier_multiplier *
			MovementManifest::get()->get_gravity_slow_rise_multiplier_default();
}

float MovementProfile::get_gravity_slow_rise() const {
	return get_gravity_fast_fall() * get_slow_rise_gravity_multiplier();
}

float MovementProfile::get_rise_double_jump_gravity_multiplier() const {
	return gravity_double_jump_slow_rise_multiplier_multiplier *
			MovementManifest::get()
					->get_gravity_double_jump_slow_rise_multiplier_default();
}

float MovementProfile::get_rise_double_jump_gravity() const {
	return get_gravity_fast_fall() * get_rise_double_jump_gravity_multiplier();
}

float MovementProfile::get_walk_acceleration() const {
	return walk_acceleration_multiplier *
			MovementManifest::get()->get_walk_acceleration_default() *
			surface_speed_multiplier;
}

float MovementProfile::get_in_air_horizontal_acceleration() const {
	return in_air_horizontal_acceleration_multiplier *
			MovementManifest::get()
					->get_in_air_horizontal_acceleration_default() *
			air_horizontal_speed_multiplier;
}

float MovementProfile::get_climb_up_speed() const {
	return climb_up_speed_multiplier *
			MovementManifest::get()->get_climb_up_speed_default() *
			surface_speed_multiplier;
}

float MovementProfile::get_climb_down_speed() const {
	return climb_down_speed_multiplier *
			MovementManifest::get()->get_climb_down_speed_default() *
			surface_speed_multiplier;
}

float MovementProfile::get_ceiling_crawl_speed() const {
	return ceiling_crawl_speed_multiplier *
			MovementManifest::get()->get_ceiling_crawl_speed_default() *
			surface_speed_multiplier;
}

float MovementProfile::get_friction_coeff_with_sideways_input() const {
	return friction_coefficient_multiplier *
			MovementManifest::get()
					->get_friction_coeff_with_sideways_input_default();
}

float MovementProfile::get_friction_coeff_without_sideways_input() const {
	return friction_coefficient_multiplier *
			MovementManifest::get()
					->get_friction_coeff_without_sideways_input_default();
}

float MovementProfile::get_jump_boost() const {
	return jump_boost_multiplier *
			MovementManifest::get()->get_jump_boost_default();
}

float MovementProfile::get_wall_jump_horizontal_boost() const {
	const float max_air_horizontal_speed = get_max_air_horizontal_speed();
	const float boost = wall_jump_horizontal_boost_multiplier *
			MovementManifest::get()->get_wall_jump_horizontal_boost_default() *
			air_horizontal_speed_multiplier;
	return Math::clamp(
			boost, -max_air_horizontal_speed, max_air_horizontal_speed);
}

float MovementProfile::get_wall_fall_horizontal_boost() const {
	const float max_air_horizontal_speed = get_max_air_horizontal_speed();
	const float boost = wall_fall_horizontal_boost_multiplier *
			MovementManifest::get()->get_wall_fall_horizontal_boost_default() *
			air_horizontal_speed_multiplier;
	return Math::clamp(
			boost, -max_air_horizontal_speed, max_air_horizontal_speed);
}

float MovementProfile::get_max_horizontal_speed_default() const {
	return max_horizontal_speed_default_multiplier *
			MovementManifest::get()->get_max_horizontal_speed_default_default();
}

float MovementProfile::get_max_vertical_speed() const {
	return max_vertical_speed_multiplier *
			MovementManifest::get()->get_max_vertical_speed_default();
}

float MovementProfile::get_max_possible_speed() const {
	return Math::max(
			get_max_horizontal_speed_default(), get_max_vertical_speed());
}

float MovementProfile::get_dash_speed_multiplier() const {
	return dash_speed_multiplier_multiplier *
			MovementManifest::get()->get_dash_speed_multiplier_default();
}

float MovementProfile::get_dash_vertical_boost() const {
	return dash_vertical_boost_multiplier *
			MovementManifest::get()->get_dash_vertical_boost_default();
}

float MovementProfile::get_dash_duration() const {
	return dash_duration_multiplier *
			MovementManifest::get()->get_dash_duration_default();
}

float MovementProfile::get_dash_fade_duration() const {
	return dash_fade_duration_multiplier *
			MovementManifest::get()->get_dash_fade_duration_default();
}

float MovementProfile::get_dash_cooldown() const {
	return dash_cooldown_multiplier *
			MovementManifest::get()->get_dash_cooldown_default();
}

float MovementProfile::get_additional_edge_weight_offset() const {
	return additional_edge_weight_offset_override != -1.0
			? additional_edge_weight_offset_override
			: MovementManifest::get()
					  ->get_additional_edge_weight_offset_default();
}

float MovementProfile::get_walking_edge_weight_multiplier() const {
	return walking_edge_weight_multiplier_override != -1.0
			? walking_edge_weight_multiplier_override
			: MovementManifest::get()
					  ->get_walking_edge_weight_multiplier_default();
}

float MovementProfile::get_ceiling_crawling_edge_weight_multiplier() const {
	return ceiling_crawling_edge_weight_multiplier_override != -1.0
			? ceiling_crawling_edge_weight_multiplier_override
			: MovementManifest::get()
					  ->get_ceiling_crawling_edge_weight_multiplier_default();
}

float MovementProfile::get_climbing_edge_weight_multiplier() const {
	return climbing_edge_weight_multiplier_override != -1.0
			? climbing_edge_weight_multiplier_override
			: MovementManifest::get()
					  ->get_climbing_edge_weight_multiplier_default();
}

float MovementProfile::get_climb_to_adjacent_surface_edge_weight_multiplier()
		const {
	return climb_to_adjacent_surface_edge_weight_multiplier_override != -1.0
			? climb_to_adjacent_surface_edge_weight_multiplier_override
			: MovementManifest::get()
					  ->get_climb_to_adjacent_surface_edge_weight_multiplier_default();
}

float MovementProfile::get_move_to_collinear_surface_edge_weight_multiplier()
		const {
	return move_to_collinear_surface_edge_weight_multiplier_override != -1.0
			? move_to_collinear_surface_edge_weight_multiplier_override
			: MovementManifest::get()
					  ->get_move_to_collinear_surface_edge_weight_multiplier_default();
}

float MovementProfile::get_air_edge_weight_multiplier() const {
	return air_edge_weight_multiplier_override != -1.0
			? air_edge_weight_multiplier_override
			: MovementManifest::get()->get_air_edge_weight_multiplier_default();
}

float MovementProfile::get_max_surface_speed() const {
	return get_max_horizontal_speed_default() * surface_speed_multiplier;
}

float MovementProfile::get_max_air_horizontal_speed() const {
	return get_max_horizontal_speed_default() * air_horizontal_speed_multiplier;
}

float MovementProfile::get_smaller_of_max_surface_and_air_horizontal_speed()
		const {
	return get_max_horizontal_speed_default() *
			Math::min(
					surface_speed_multiplier, air_horizontal_speed_multiplier);
}

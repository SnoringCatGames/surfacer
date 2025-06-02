#include "surfacer/movement_manifest.h"

#include "snore_core/internal_utils.h"
#include "surfacer/surfacer_manifest.h"

#include <godot_cpp/core/class_db.hpp>

using namespace godot;

Ref<MovementManifest> MovementManifest::get() {
	Ref<SurfacerManifest> surfacer_manifest = SurfacerManifest::get();
	return surfacer_manifest.is_valid()
			? surfacer_manifest->get_movement_manifest()
			: Ref<MovementManifest>();
}

void MovementManifest::_bind_methods() {
	// --- Navigation settings ---

	ClassDB::bind_method(
			D_METHOD("get_uses_point_and_click_navigation"),
			&MovementManifest::get_uses_point_and_click_navigation);
	ClassDB::bind_method(
			D_METHOD("set_uses_point_and_click_navigation", "p_value"),
			&MovementManifest::set_uses_point_and_click_navigation);
	ADD_PROPERTY(
			PropertyInfo(Variant::BOOL, "uses_point_and_click_navigation"),
			"set_uses_point_and_click_navigation",
			"get_uses_point_and_click_navigation");

	ClassDB::bind_method(
			D_METHOD("get_do_player_actions_interrupt_navigation"),
			&MovementManifest::get_do_player_actions_interrupt_navigation);
	ClassDB::bind_method(
			D_METHOD("set_do_player_actions_interrupt_navigation", "p_value"),
			&MovementManifest::set_do_player_actions_interrupt_navigation);
	ADD_PROPERTY(
			PropertyInfo(
					Variant::BOOL, "do_player_actions_interrupt_navigation"),
			"set_do_player_actions_interrupt_navigation",
			"get_do_player_actions_interrupt_navigation");

	// --- Gravity settings ---

	ClassDB::bind_method(
			D_METHOD("get_gravity_default"),
			&MovementManifest::get_gravity_default);
	ClassDB::bind_method(
			D_METHOD("set_gravity_default", "p_value"),
			&MovementManifest::set_gravity_default);
	ADD_PROPERTY(
			PropertyInfo(Variant::FLOAT, "gravity_default"),
			"set_gravity_default", "get_gravity_default");

	ClassDB::bind_method(
			D_METHOD("get_gravity_slow_rise_multiplier_default"),
			&MovementManifest::get_gravity_slow_rise_multiplier_default);
	ClassDB::bind_method(
			D_METHOD("set_gravity_slow_rise_multiplier_default", "p_value"),
			&MovementManifest::set_gravity_slow_rise_multiplier_default);
	ADD_PROPERTY(
			PropertyInfo(
					Variant::FLOAT, "gravity_slow_rise_multiplier_default"),
			"set_gravity_slow_rise_multiplier_default",
			"get_gravity_slow_rise_multiplier_default");

	ClassDB::bind_method(
			D_METHOD("get_gravity_double_jump_slow_rise_multiplier_default"),
			&MovementManifest::
					get_gravity_double_jump_slow_rise_multiplier_default);
	ClassDB::bind_method(
			D_METHOD(
					"set_gravity_double_jump_slow_rise_multiplier_default",
					"p_value"),
			&MovementManifest::
					set_gravity_double_jump_slow_rise_multiplier_default);
	ADD_PROPERTY(
			PropertyInfo(
					Variant::FLOAT,
					"gravity_double_jump_slow_rise_multiplier_default"),
			"set_gravity_double_jump_slow_rise_multiplier_default",
			"get_gravity_double_jump_slow_rise_multiplier_default");

	// --- Movement settings ---

	ClassDB::bind_method(
			D_METHOD("get_walk_acceleration_default"),
			&MovementManifest::get_walk_acceleration_default);
	ClassDB::bind_method(
			D_METHOD("set_walk_acceleration_default", "p_value"),
			&MovementManifest::set_walk_acceleration_default);
	ADD_PROPERTY(
			PropertyInfo(Variant::FLOAT, "walk_acceleration_default"),
			"set_walk_acceleration_default", "get_walk_acceleration_default");

	ClassDB::bind_method(
			D_METHOD("get_in_air_horizontal_acceleration_default"),
			&MovementManifest::get_in_air_horizontal_acceleration_default);
	ClassDB::bind_method(
			D_METHOD("set_in_air_horizontal_acceleration_default", "p_value"),
			&MovementManifest::set_in_air_horizontal_acceleration_default);
	ADD_PROPERTY(
			PropertyInfo(
					Variant::FLOAT, "in_air_horizontal_acceleration_default"),
			"set_in_air_horizontal_acceleration_default",
			"get_in_air_horizontal_acceleration_default");

	ClassDB::bind_method(
			D_METHOD("get_climb_up_speed_default"),
			&MovementManifest::get_climb_up_speed_default);
	ClassDB::bind_method(
			D_METHOD("set_climb_up_speed_default", "p_value"),
			&MovementManifest::set_climb_up_speed_default);
	ADD_PROPERTY(
			PropertyInfo(Variant::FLOAT, "climb_up_speed_default"),
			"set_climb_up_speed_default", "get_climb_up_speed_default");

	ClassDB::bind_method(
			D_METHOD("get_climb_down_speed_default"),
			&MovementManifest::get_climb_down_speed_default);
	ClassDB::bind_method(
			D_METHOD("set_climb_down_speed_default", "p_value"),
			&MovementManifest::set_climb_down_speed_default);
	ADD_PROPERTY(
			PropertyInfo(Variant::FLOAT, "climb_down_speed_default"),
			"set_climb_down_speed_default", "get_climb_down_speed_default");

	ClassDB::bind_method(
			D_METHOD("get_ceiling_crawl_speed_default"),
			&MovementManifest::get_ceiling_crawl_speed_default);
	ClassDB::bind_method(
			D_METHOD("set_ceiling_crawl_speed_default", "p_value"),
			&MovementManifest::set_ceiling_crawl_speed_default);
	ADD_PROPERTY(
			PropertyInfo(Variant::FLOAT, "ceiling_crawl_speed_default"),
			"set_ceiling_crawl_speed_default",
			"get_ceiling_crawl_speed_default");

	// --- Friction settings ---

	ClassDB::bind_method(
			D_METHOD("get_friction_coeff_with_sideways_input_default"),
			&MovementManifest::get_friction_coeff_with_sideways_input_default);
	ClassDB::bind_method(
			D_METHOD(
					"set_friction_coeff_with_sideways_input_default",
					"p_value"),
			&MovementManifest::set_friction_coeff_with_sideways_input_default);
	ADD_PROPERTY(
			PropertyInfo(
					Variant::FLOAT,
					"friction_coeff_with_sideways_input_default"),
			"set_friction_coeff_with_sideways_input_default",
			"get_friction_coeff_with_sideways_input_default");

	ClassDB::bind_method(
			D_METHOD("get_friction_coeff_without_sideways_input_default"),
			&MovementManifest::
					get_friction_coeff_without_sideways_input_default);
	ClassDB::bind_method(
			D_METHOD(
					"set_friction_coeff_without_sideways_input_default",
					"p_value"),
			&MovementManifest::
					set_friction_coeff_without_sideways_input_default);
	ADD_PROPERTY(
			PropertyInfo(
					Variant::FLOAT,
					"friction_coeff_without_sideways_input_default"),
			"set_friction_coeff_without_sideways_input_default",
			"get_friction_coeff_without_sideways_input_default");

	// --- Jump settings ---

	ClassDB::bind_method(
			D_METHOD("get_jump_boost_default"),
			&MovementManifest::get_jump_boost_default);
	ClassDB::bind_method(
			D_METHOD("set_jump_boost_default", "p_value"),
			&MovementManifest::set_jump_boost_default);
	ADD_PROPERTY(
			PropertyInfo(Variant::FLOAT, "jump_boost_default"),
			"set_jump_boost_default", "get_jump_boost_default");

	ClassDB::bind_method(
			D_METHOD("get_wall_jump_horizontal_boost_default"),
			&MovementManifest::get_wall_jump_horizontal_boost_default);
	ClassDB::bind_method(
			D_METHOD("set_wall_jump_horizontal_boost_default", "p_value"),
			&MovementManifest::set_wall_jump_horizontal_boost_default);
	ADD_PROPERTY(
			PropertyInfo(Variant::FLOAT, "wall_jump_horizontal_boost_default"),
			"set_wall_jump_horizontal_boost_default",
			"get_wall_jump_horizontal_boost_default");

	ClassDB::bind_method(
			D_METHOD("get_wall_fall_horizontal_boost_default"),
			&MovementManifest::get_wall_fall_horizontal_boost_default);
	ClassDB::bind_method(
			D_METHOD("set_wall_fall_horizontal_boost_default", "p_value"),
			&MovementManifest::set_wall_fall_horizontal_boost_default);
	ADD_PROPERTY(
			PropertyInfo(Variant::FLOAT, "wall_fall_horizontal_boost_default"),
			"set_wall_fall_horizontal_boost_default",
			"get_wall_fall_horizontal_boost_default");

	// --- Speed settings ---

	ClassDB::bind_method(
			D_METHOD("get_max_horizontal_speed_default_default"),
			&MovementManifest::get_max_horizontal_speed_default_default);
	ClassDB::bind_method(
			D_METHOD("set_max_horizontal_speed_default_default", "p_value"),
			&MovementManifest::set_max_horizontal_speed_default_default);
	ADD_PROPERTY(
			PropertyInfo(
					Variant::FLOAT, "max_horizontal_speed_default_default"),
			"set_max_horizontal_speed_default_default",
			"get_max_horizontal_speed_default_default");

	ClassDB::bind_method(
			D_METHOD("get_max_vertical_speed_default"),
			&MovementManifest::get_max_vertical_speed_default);
	ClassDB::bind_method(
			D_METHOD("set_max_vertical_speed_default", "p_value"),
			&MovementManifest::set_max_vertical_speed_default);
	ADD_PROPERTY(
			PropertyInfo(Variant::FLOAT, "max_vertical_speed_default"),
			"set_max_vertical_speed_default", "get_max_vertical_speed_default");

	ClassDB::bind_method(
			D_METHOD("get_min_horizontal_speed"),
			&MovementManifest::get_min_horizontal_speed);
	ClassDB::bind_method(
			D_METHOD("set_min_horizontal_speed", "p_value"),
			&MovementManifest::set_min_horizontal_speed);
	ADD_PROPERTY(
			PropertyInfo(Variant::FLOAT, "min_horizontal_speed"),
			"set_min_horizontal_speed", "get_min_horizontal_speed");

	ClassDB::bind_method(
			D_METHOD("get_min_vertical_speed"),
			&MovementManifest::get_min_vertical_speed);
	ClassDB::bind_method(
			D_METHOD("set_min_vertical_speed", "p_value"),
			&MovementManifest::set_min_vertical_speed);
	ADD_PROPERTY(
			PropertyInfo(Variant::FLOAT, "min_vertical_speed"),
			"set_min_vertical_speed", "get_min_vertical_speed");

	// --- Dash settings ---

	ClassDB::bind_method(
			D_METHOD("get_dash_speed_multiplier_default"),
			&MovementManifest::get_dash_speed_multiplier_default);
	ClassDB::bind_method(
			D_METHOD("set_dash_speed_multiplier_default", "p_value"),
			&MovementManifest::set_dash_speed_multiplier_default);
	ADD_PROPERTY(
			PropertyInfo(Variant::FLOAT, "dash_speed_multiplier_default"),
			"set_dash_speed_multiplier_default",
			"get_dash_speed_multiplier_default");

	ClassDB::bind_method(
			D_METHOD("get_dash_vertical_boost_default"),
			&MovementManifest::get_dash_vertical_boost_default);
	ClassDB::bind_method(
			D_METHOD("set_dash_vertical_boost_default", "p_value"),
			&MovementManifest::set_dash_vertical_boost_default);
	ADD_PROPERTY(
			PropertyInfo(Variant::FLOAT, "dash_vertical_boost_default"),
			"set_dash_vertical_boost_default",
			"get_dash_vertical_boost_default");

	ClassDB::bind_method(
			D_METHOD("get_dash_duration_default"),
			&MovementManifest::get_dash_duration_default);
	ClassDB::bind_method(
			D_METHOD("set_dash_duration_default", "p_value"),
			&MovementManifest::set_dash_duration_default);
	ADD_PROPERTY(
			PropertyInfo(Variant::FLOAT, "dash_duration_default"),
			"set_dash_duration_default", "get_dash_duration_default");

	ClassDB::bind_method(
			D_METHOD("get_dash_fade_duration_default"),
			&MovementManifest::get_dash_fade_duration_default);
	ClassDB::bind_method(
			D_METHOD("set_dash_fade_duration_default", "p_value"),
			&MovementManifest::set_dash_fade_duration_default);
	ADD_PROPERTY(
			PropertyInfo(Variant::FLOAT, "dash_fade_duration_default"),
			"set_dash_fade_duration_default", "get_dash_fade_duration_default");

	ClassDB::bind_method(
			D_METHOD("get_dash_cooldown_default"),
			&MovementManifest::get_dash_cooldown_default);
	ClassDB::bind_method(
			D_METHOD("set_dash_cooldown_default", "p_value"),
			&MovementManifest::set_dash_cooldown_default);
	ADD_PROPERTY(
			PropertyInfo(Variant::FLOAT, "dash_cooldown_default"),
			"set_dash_cooldown_default", "get_dash_cooldown_default");

	// --- Edge weight settings ---

	ClassDB::bind_method(
			D_METHOD("get_additional_edge_weight_offset_default"),
			&MovementManifest::get_additional_edge_weight_offset_default);
	ClassDB::bind_method(
			D_METHOD("set_additional_edge_weight_offset_default", "p_value"),
			&MovementManifest::set_additional_edge_weight_offset_default);
	ADD_PROPERTY(
			PropertyInfo(
					Variant::FLOAT, "additional_edge_weight_offset_default"),
			"set_additional_edge_weight_offset_default",
			"get_additional_edge_weight_offset_default");

	ClassDB::bind_method(
			D_METHOD("get_walking_edge_weight_multiplier_default"),
			&MovementManifest::get_walking_edge_weight_multiplier_default);
	ClassDB::bind_method(
			D_METHOD("set_walking_edge_weight_multiplier_default", "p_value"),
			&MovementManifest::set_walking_edge_weight_multiplier_default);
	ADD_PROPERTY(
			PropertyInfo(
					Variant::FLOAT, "walking_edge_weight_multiplier_default"),
			"set_walking_edge_weight_multiplier_default",
			"get_walking_edge_weight_multiplier_default");

	ClassDB::bind_method(
			D_METHOD("get_ceiling_crawling_edge_weight_multiplier_default"),
			&MovementManifest::
					get_ceiling_crawling_edge_weight_multiplier_default);
	ClassDB::bind_method(
			D_METHOD(
					"set_ceiling_crawling_edge_weight_multiplier_default",
					"p_value"),
			&MovementManifest::
					set_ceiling_crawling_edge_weight_multiplier_default);
	ADD_PROPERTY(
			PropertyInfo(
					Variant::FLOAT,
					"ceiling_crawling_edge_weight_multiplier_default"),
			"set_ceiling_crawling_edge_weight_multiplier_default",
			"get_ceiling_crawling_edge_weight_multiplier_default");

	ClassDB::bind_method(
			D_METHOD("get_climbing_edge_weight_multiplier_default"),
			&MovementManifest::get_climbing_edge_weight_multiplier_default);
	ClassDB::bind_method(
			D_METHOD("set_climbing_edge_weight_multiplier_default", "p_value"),
			&MovementManifest::set_climbing_edge_weight_multiplier_default);
	ADD_PROPERTY(
			PropertyInfo(
					Variant::FLOAT, "climbing_edge_weight_multiplier_default"),
			"set_climbing_edge_weight_multiplier_default",
			"get_climbing_edge_weight_multiplier_default");

	ClassDB::bind_method(
			D_METHOD(
					"get_climb_to_adjacent_surface_edge_weight_multiplier_"
					"default"),
			&MovementManifest::
					get_climb_to_adjacent_surface_edge_weight_multiplier_default);
	ClassDB::bind_method(
			D_METHOD(
					"set_climb_to_adjacent_surface_edge_weight_multiplier_"
					"default",
					"p_value"),
			&MovementManifest::
					set_climb_to_adjacent_surface_edge_weight_multiplier_default);
	ADD_PROPERTY(
			PropertyInfo(
					Variant::FLOAT,
					"climb_to_adjacent_surface_edge_weight_multiplier_default"),
			"set_climb_to_adjacent_surface_edge_weight_multiplier_default",
			"get_climb_to_adjacent_surface_edge_weight_multiplier_default");

	ClassDB::bind_method(
			D_METHOD(
					"get_move_to_collinear_surface_edge_weight_multiplier_"
					"default"),
			&MovementManifest::
					get_move_to_collinear_surface_edge_weight_multiplier_default);
	ClassDB::bind_method(
			D_METHOD(
					"set_move_to_collinear_surface_edge_weight_multiplier_"
					"default",
					"p_value"),
			&MovementManifest::
					set_move_to_collinear_surface_edge_weight_multiplier_default);
	ADD_PROPERTY(
			PropertyInfo(
					Variant::FLOAT,
					"move_to_collinear_surface_edge_weight_multiplier_default"),
			"set_move_to_collinear_surface_edge_weight_multiplier_default",
			"get_move_to_collinear_surface_edge_weight_multiplier_default");

	ClassDB::bind_method(
			D_METHOD("get_air_edge_weight_multiplier_default"),
			&MovementManifest::get_air_edge_weight_multiplier_default);
	ClassDB::bind_method(
			D_METHOD("set_air_edge_weight_multiplier_default", "p_value"),
			&MovementManifest::set_air_edge_weight_multiplier_default);
	ADD_PROPERTY(
			PropertyInfo(Variant::FLOAT, "air_edge_weight_multiplier_default"),
			"set_air_edge_weight_multiplier_default",
			"get_air_edge_weight_multiplier_default");
}

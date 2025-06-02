#ifndef MOVEMENT_MANIFEST_H
#define MOVEMENT_MANIFEST_H

#include "scaffolder/geometry.h"
#include "snore_core/snore_core_manifest.h"

#include <godot_cpp/core/binder_common.hpp>

namespace godot {

// TODO: Port character_movement_params, action_handlers, and edge_calculators
//       logic.
// TODO: Port validation and _calculate_dependent_movement_params.

class MovementManifest : public SnoreCoreManifest {
	GDCLASS(MovementManifest, SnoreCoreManifest)

public:
	static Ref<MovementManifest> get();

	MovementManifest() = default;
	~MovementManifest() = default;

	// --- Navigation settings ---

	bool get_uses_point_and_click_navigation() const {
		return uses_point_and_click_navigation;
	}
	void set_uses_point_and_click_navigation(bool p_value) {
		uses_point_and_click_navigation = p_value;
	}

	bool get_do_player_actions_interrupt_navigation() const {
		return do_player_actions_interrupt_navigation;
	}
	void set_do_player_actions_interrupt_navigation(bool p_value) {
		do_player_actions_interrupt_navigation = p_value;
	}

	// --- Gravity settings ---

	float get_gravity_default() const { return gravity_default; }
	void set_gravity_default(float p_value) { gravity_default = p_value; }

	float get_gravity_slow_rise_multiplier_default() const {
		return gravity_slow_rise_multiplier_default;
	}
	void set_gravity_slow_rise_multiplier_default(float p_value) {
		gravity_slow_rise_multiplier_default = p_value;
	}

	float get_gravity_double_jump_slow_rise_multiplier_default() const {
		return gravity_double_jump_slow_rise_multiplier_default;
	}
	void set_gravity_double_jump_slow_rise_multiplier_default(float p_value) {
		gravity_double_jump_slow_rise_multiplier_default = p_value;
	}

	// --- Movement settings ---

	float get_walk_acceleration_default() const {
		return walk_acceleration_default;
	}
	void set_walk_acceleration_default(float p_value) {
		walk_acceleration_default = p_value;
	}

	float get_in_air_horizontal_acceleration_default() const {
		return in_air_horizontal_acceleration_default;
	}
	void set_in_air_horizontal_acceleration_default(float p_value) {
		in_air_horizontal_acceleration_default = p_value;
	}

	float get_climb_up_speed_default() const { return climb_up_speed_default; }
	void set_climb_up_speed_default(float p_value) {
		climb_up_speed_default = p_value;
	}

	float get_climb_down_speed_default() const {
		return climb_down_speed_default;
	}
	void set_climb_down_speed_default(float p_value) {
		climb_down_speed_default = p_value;
	}

	float get_ceiling_crawl_speed_default() const {
		return ceiling_crawl_speed_default;
	}
	void set_ceiling_crawl_speed_default(float p_value) {
		ceiling_crawl_speed_default = p_value;
	}

	// --- Friction settings ---

	float get_friction_coeff_with_sideways_input_default() const {
		return friction_coeff_with_sideways_input_default;
	}
	void set_friction_coeff_with_sideways_input_default(float p_value) {
		friction_coeff_with_sideways_input_default = p_value;
	}

	float get_friction_coeff_without_sideways_input_default() const {
		return friction_coeff_without_sideways_input_default;
	}
	void set_friction_coeff_without_sideways_input_default(float p_value) {
		friction_coeff_without_sideways_input_default = p_value;
	}

	// --- Jump settings ---

	float get_jump_boost_default() const { return jump_boost_default; }
	void set_jump_boost_default(float p_value) { jump_boost_default = p_value; }

	float get_wall_jump_horizontal_boost_default() const {
		return wall_jump_horizontal_boost_default;
	}
	void set_wall_jump_horizontal_boost_default(float p_value) {
		wall_jump_horizontal_boost_default = p_value;
	}

	float get_wall_fall_horizontal_boost_default() const {
		return wall_fall_horizontal_boost_default;
	}
	void set_wall_fall_horizontal_boost_default(float p_value) {
		wall_fall_horizontal_boost_default = p_value;
	}

	// --- Speed settings ---

	float get_max_horizontal_speed_default_default() const {
		return max_horizontal_speed_default_default;
	}
	void set_max_horizontal_speed_default_default(float p_value) {
		max_horizontal_speed_default_default = p_value;
	}

	float get_max_vertical_speed_default() const {
		return max_vertical_speed_default;
	}
	void set_max_vertical_speed_default(float p_value) {
		max_vertical_speed_default = p_value;
	}

	float get_min_horizontal_speed() const { return min_horizontal_speed; }
	void set_min_horizontal_speed(float p_value) {
		min_horizontal_speed = p_value;
	}

	float get_min_vertical_speed() const { return min_vertical_speed; }
	void set_min_vertical_speed(float p_value) { min_vertical_speed = p_value; }

	// --- Dash settings ---

	float get_dash_speed_multiplier_default() const {
		return dash_speed_multiplier_default;
	}
	void set_dash_speed_multiplier_default(float p_value) {
		dash_speed_multiplier_default = p_value;
	}

	float get_dash_vertical_boost_default() const {
		return dash_vertical_boost_default;
	}
	void set_dash_vertical_boost_default(float p_value) {
		dash_vertical_boost_default = p_value;
	}

	float get_dash_duration_default() const { return dash_duration_default; }
	void set_dash_duration_default(float p_value) {
		dash_duration_default = p_value;
	}

	float get_dash_fade_duration_default() const {
		return dash_fade_duration_default;
	}
	void set_dash_fade_duration_default(float p_value) {
		dash_fade_duration_default = p_value;
	}

	float get_dash_cooldown_default() const { return dash_cooldown_default; }
	void set_dash_cooldown_default(float p_value) {
		dash_cooldown_default = p_value;
	}

	// --- Edge weight settings ---

	float get_additional_edge_weight_offset_default() const {
		return additional_edge_weight_offset_default;
	}
	void set_additional_edge_weight_offset_default(float p_value) {
		additional_edge_weight_offset_default = p_value;
	}

	float get_walking_edge_weight_multiplier_default() const {
		return walking_edge_weight_multiplier_default;
	}
	void set_walking_edge_weight_multiplier_default(float p_value) {
		walking_edge_weight_multiplier_default = p_value;
	}

	float get_ceiling_crawling_edge_weight_multiplier_default() const {
		return ceiling_crawling_edge_weight_multiplier_default;
	}
	void set_ceiling_crawling_edge_weight_multiplier_default(float p_value) {
		ceiling_crawling_edge_weight_multiplier_default = p_value;
	}

	float get_climbing_edge_weight_multiplier_default() const {
		return climbing_edge_weight_multiplier_default;
	}
	void set_climbing_edge_weight_multiplier_default(float p_value) {
		climbing_edge_weight_multiplier_default = p_value;
	}

	float get_climb_to_adjacent_surface_edge_weight_multiplier_default() const {
		return climb_to_adjacent_surface_edge_weight_multiplier_default;
	}
	void set_climb_to_adjacent_surface_edge_weight_multiplier_default(
			float p_value) {
		climb_to_adjacent_surface_edge_weight_multiplier_default = p_value;
	}

	float get_move_to_collinear_surface_edge_weight_multiplier_default() const {
		return move_to_collinear_surface_edge_weight_multiplier_default;
	}
	void set_move_to_collinear_surface_edge_weight_multiplier_default(
			float p_value) {
		move_to_collinear_surface_edge_weight_multiplier_default = p_value;
	}

	float get_air_edge_weight_multiplier_default() const {
		return air_edge_weight_multiplier_default;
	}
	void set_air_edge_weight_multiplier_default(float p_value) {
		air_edge_weight_multiplier_default = p_value;
	}

protected:
	static void _bind_methods();

private:
	// --- Navigation settings ---

	bool uses_point_and_click_navigation = true;
	bool do_player_actions_interrupt_navigation = true;

	// --- Gravity settings ---

	float gravity_default = 5000.0f;
	float gravity_slow_rise_multiplier_default = 0.38f;
	float gravity_double_jump_slow_rise_multiplier_default = 0.68f;

	// --- Movement settings ---

	float walk_acceleration_default = 8000.0f;
	float in_air_horizontal_acceleration_default = 2500.0f;
	float climb_up_speed_default = -230.0f;
	float climb_down_speed_default = 120.0f;
	float ceiling_crawl_speed_default = 230.0f;

	// --- Friction settings ---

	float friction_coeff_with_sideways_input_default = 1.25f;
	float friction_coeff_without_sideways_input_default = 1.0f;

	// --- Jump settings ---

	float jump_boost_default = -900.0f;
	float wall_jump_horizontal_boost_default = 200.0f;
	float wall_fall_horizontal_boost_default = 20.0f;

	// --- Speed settings ---

	float max_horizontal_speed_default_default = 320.0f;
	float max_vertical_speed_default = 2800.0f;
	float min_horizontal_speed = 5.0f;
	float min_vertical_speed = 0.0f;

	// --- Dash settings ---

	float dash_speed_multiplier_default = 3.0f;
	float dash_vertical_boost_default = -300.0f;
	float dash_duration_default = 0.3f;
	float dash_fade_duration_default = 0.1f;
	float dash_cooldown_default = 1.0f;

	// --- Edge weight settings ---

	float additional_edge_weight_offset_default = 0.0f;
	float walking_edge_weight_multiplier_default = 1.2f;
	float ceiling_crawling_edge_weight_multiplier_default = 2.0f;
	float climbing_edge_weight_multiplier_default = 1.8f;
	float climb_to_adjacent_surface_edge_weight_multiplier_default = 1.0f;
	float move_to_collinear_surface_edge_weight_multiplier_default = 0.0f;
	float air_edge_weight_multiplier_default = 1.0f;
};

} // namespace godot

#endif // MOVEMENT_MANIFEST_H

#ifndef MOVEMENT_PROFILE_H
#define MOVEMENT_PROFILE_H

#include "surfacer/navigation_interruption_resolution.h"

#include <godot_cpp/classes/resource.hpp>

namespace godot {

// - This defines how your character will move.
// - There are a _lot_ of parameters you can adjust here.
// - You can adjust these parameters within the editor's inspector panel.
class GDE_EXPORT MovementProfile : public Resource {
	GDCLASS(MovementProfile, Resource)

public:
	MovementProfile() = default;
	~MovementProfile() = default;

	// --- Movement abilities ---

	bool get_can_grab_walls() const { return can_grab_walls; }
	void set_can_grab_walls(bool p_value) {
		can_grab_walls = p_value;
		on_parameter_updated();
	}

	bool get_can_grab_ceilings() const { return can_grab_ceilings; }
	void set_can_grab_ceilings(bool p_value) {
		can_grab_ceilings = p_value;
		on_parameter_updated();
	}

	bool get_can_grab_floors() const { return can_grab_floors; }
	void set_can_grab_floors(bool p_value) {
		can_grab_floors = p_value;
		on_parameter_updated();
	}

	bool get_can_jump() const { return can_jump; }
	void set_can_jump(bool p_value) {
		can_jump = p_value;
		on_parameter_updated();
	}

	bool get_can_dash() const { return can_dash; }
	void set_can_dash(bool p_value) {
		can_dash = p_value;
		on_parameter_updated();
	}

	bool get_can_double_jump() const { return can_double_jump; }
	void set_can_double_jump(bool p_value) {
		can_double_jump = p_value;
		on_parameter_updated();
	}

	bool get_can_target_in_air_destinations() const {
		return can_target_in_air_destinations;
	}
	void set_can_target_in_air_destinations(bool p_value) {
		can_target_in_air_destinations = p_value;
		on_parameter_updated();
	}

	// --- Physics movement ---

	float get_surface_speed_multiplier() const {
		return surface_speed_multiplier;
	}
	void set_surface_speed_multiplier(float p_value) {
		surface_speed_multiplier = p_value;
		on_parameter_updated();
	}

	float get_air_horizontal_speed_multiplier() const {
		return air_horizontal_speed_multiplier;
	}
	void set_air_horizontal_speed_multiplier(float p_value) {
		air_horizontal_speed_multiplier = p_value;
		on_parameter_updated();
	}

	float get_gravity_multiplier() const { return gravity_multiplier; }
	void set_gravity_multiplier(float p_value) {
		gravity_multiplier = p_value;
		on_parameter_updated();
	}

	float get_gravity_slow_rise_multiplier_multiplier() const {
		return gravity_slow_rise_multiplier_multiplier;
	}
	void set_gravity_slow_rise_multiplier_multiplier(float p_value) {
		gravity_slow_rise_multiplier_multiplier = p_value;
		on_parameter_updated();
	}

	float get_gravity_double_jump_slow_rise_multiplier_multiplier() const {
		return gravity_double_jump_slow_rise_multiplier_multiplier;
	}
	void set_gravity_double_jump_slow_rise_multiplier_multiplier(
			float p_value) {
		gravity_double_jump_slow_rise_multiplier_multiplier = p_value;
		on_parameter_updated();
	}

	float get_walk_acceleration_multiplier() const {
		return walk_acceleration_multiplier;
	}
	void set_walk_acceleration_multiplier(float p_value) {
		walk_acceleration_multiplier = p_value;
		on_parameter_updated();
	}

	float get_in_air_horizontal_acceleration_multiplier() const {
		return in_air_horizontal_acceleration_multiplier;
	}
	void set_in_air_horizontal_acceleration_multiplier(float p_value) {
		in_air_horizontal_acceleration_multiplier = p_value;
		on_parameter_updated();
	}

	float get_climb_up_speed_multiplier() const {
		return climb_up_speed_multiplier;
	}
	void set_climb_up_speed_multiplier(float p_value) {
		climb_up_speed_multiplier = p_value;
		on_parameter_updated();
	}

	float get_climb_down_speed_multiplier() const {
		return climb_down_speed_multiplier;
	}
	void set_climb_down_speed_multiplier(float p_value) {
		climb_down_speed_multiplier = p_value;
		on_parameter_updated();
	}

	float get_ceiling_crawl_speed_multiplier() const {
		return ceiling_crawl_speed_multiplier;
	}
	void set_ceiling_crawl_speed_multiplier(float p_value) {
		ceiling_crawl_speed_multiplier = p_value;
		on_parameter_updated();
	}

	float get_friction_coefficient_multiplier() const {
		return friction_coefficient_multiplier;
	}
	void set_friction_coefficient_multiplier(float p_value) {
		friction_coefficient_multiplier = p_value;
		on_parameter_updated();
	}

	float get_jump_boost_multiplier() const { return jump_boost_multiplier; }
	void set_jump_boost_multiplier(float p_value) {
		jump_boost_multiplier = p_value;
		on_parameter_updated();
	}

	float get_wall_jump_horizontal_boost_multiplier() const {
		return wall_jump_horizontal_boost_multiplier;
	}
	void set_wall_jump_horizontal_boost_multiplier(float p_value) {
		wall_jump_horizontal_boost_multiplier = p_value;
		on_parameter_updated();
	}

	float get_wall_fall_horizontal_boost_multiplier() const {
		return wall_fall_horizontal_boost_multiplier;
	}
	void set_wall_fall_horizontal_boost_multiplier(float p_value) {
		wall_fall_horizontal_boost_multiplier = p_value;
		on_parameter_updated();
	}

	float get_ceiling_fall_velocity_boost() const {
		return ceiling_fall_velocity_boost;
	}
	void set_ceiling_fall_velocity_boost(float p_value) {
		ceiling_fall_velocity_boost = p_value;
		on_parameter_updated();
	}

	float get_max_horizontal_speed_default_multiplier() const {
		return max_horizontal_speed_default_multiplier;
	}
	void set_max_horizontal_speed_default_multiplier(float p_value) {
		max_horizontal_speed_default_multiplier = p_value;
		on_parameter_updated();
	}

	float get_max_vertical_speed_multiplier() const {
		return max_vertical_speed_multiplier;
	}
	void set_max_vertical_speed_multiplier(float p_value) {
		max_vertical_speed_multiplier = p_value;
		on_parameter_updated();
	}

	float get_fall_through_floor_velocity_boost() const {
		return fall_through_floor_velocity_boost;
	}
	void set_fall_through_floor_velocity_boost(float p_value) {
		fall_through_floor_velocity_boost = p_value;
		on_parameter_updated();
	}

	bool get_stops_on_slope() const { return stops_on_slope; }
	void set_stops_on_slope(bool p_value) {
		stops_on_slope = p_value;
		on_parameter_updated();
	}

	// --- Dash ---

	float get_dash_speed_multiplier_multiplier() const {
		return dash_speed_multiplier_multiplier;
	}
	void set_dash_speed_multiplier_multiplier(float p_value) {
		dash_speed_multiplier_multiplier = p_value;
		on_parameter_updated();
	}

	float get_dash_vertical_boost_multiplier() const {
		return dash_vertical_boost_multiplier;
	}
	void set_dash_vertical_boost_multiplier(float p_value) {
		dash_vertical_boost_multiplier = p_value;
		on_parameter_updated();
	}

	float get_dash_duration_multiplier() const {
		return dash_duration_multiplier;
	}
	void set_dash_duration_multiplier(float p_value) {
		dash_duration_multiplier = p_value;
		on_parameter_updated();
	}

	float get_dash_fade_duration_multiplier() const {
		return dash_fade_duration_multiplier;
	}
	void set_dash_fade_duration_multiplier(float p_value) {
		dash_fade_duration_multiplier = p_value;
		on_parameter_updated();
	}

	float get_dash_cooldown_multiplier() const {
		return dash_cooldown_multiplier;
	}
	void set_dash_cooldown_multiplier(float p_value) {
		dash_cooldown_multiplier = p_value;
		on_parameter_updated();
	}

	// --- Double jump ---

	int get_max_jump_chain() const { return max_jump_chain; }
	void set_max_jump_chain(int p_value) {
		max_jump_chain = p_value;
		on_parameter_updated();
	}

	// --- Edge weights ---

	bool get_uses_duration_instead_of_distance_for_edge_weight() const {
		return uses_duration_instead_of_distance_for_edge_weight;
	}
	void set_uses_duration_instead_of_distance_for_edge_weight(bool p_value) {
		uses_duration_instead_of_distance_for_edge_weight = p_value;
		on_parameter_updated();
	}

	float get_additional_edge_weight_offset_override() const {
		return additional_edge_weight_offset_override;
	}
	void set_additional_edge_weight_offset_override(float p_value) {
		additional_edge_weight_offset_override = p_value;
		on_parameter_updated();
	}

	float get_walking_edge_weight_multiplier_override() const {
		return walking_edge_weight_multiplier_override;
	}
	void set_walking_edge_weight_multiplier_override(float p_value) {
		walking_edge_weight_multiplier_override = p_value;
		on_parameter_updated();
	}

	float get_ceiling_crawling_edge_weight_multiplier_override() const {
		return ceiling_crawling_edge_weight_multiplier_override;
	}
	void set_ceiling_crawling_edge_weight_multiplier_override(float p_value) {
		ceiling_crawling_edge_weight_multiplier_override = p_value;
		on_parameter_updated();
	}

	float get_climbing_edge_weight_multiplier_override() const {
		return climbing_edge_weight_multiplier_override;
	}
	void set_climbing_edge_weight_multiplier_override(float p_value) {
		climbing_edge_weight_multiplier_override = p_value;
		on_parameter_updated();
	}

	float get_climb_to_adjacent_surface_edge_weight_multiplier_override()
			const {
		return climb_to_adjacent_surface_edge_weight_multiplier_override;
	}
	void set_climb_to_adjacent_surface_edge_weight_multiplier_override(
			float p_value) {
		climb_to_adjacent_surface_edge_weight_multiplier_override = p_value;
		on_parameter_updated();
	}

	float get_move_to_collinear_surface_edge_weight_multiplier_override()
			const {
		return move_to_collinear_surface_edge_weight_multiplier_override;
	}
	void set_move_to_collinear_surface_edge_weight_multiplier_override(
			float p_value) {
		move_to_collinear_surface_edge_weight_multiplier_override = p_value;
		on_parameter_updated();
	}

	float get_air_edge_weight_multiplier_override() const {
		return air_edge_weight_multiplier_override;
	}
	void set_air_edge_weight_multiplier_override(float p_value) {
		air_edge_weight_multiplier_override = p_value;
		on_parameter_updated();
	}

	// --- Surface graph calculations ---

	bool get_minimizes_velocity_change_when_jumping() const {
		return minimizes_velocity_change_when_jumping;
	}
	void set_minimizes_velocity_change_when_jumping(bool p_value) {
		minimizes_velocity_change_when_jumping = p_value;
		on_parameter_updated();
	}

	bool get_optimizes_edge_jump_positions_at_run_time() const {
		return optimizes_edge_jump_positions_at_run_time;
	}
	void set_optimizes_edge_jump_positions_at_run_time(bool p_value) {
		optimizes_edge_jump_positions_at_run_time = p_value;
		on_parameter_updated();
	}

	bool get_optimizes_edge_land_positions_at_run_time() const {
		return optimizes_edge_land_positions_at_run_time;
	}
	void set_optimizes_edge_land_positions_at_run_time(bool p_value) {
		optimizes_edge_land_positions_at_run_time = p_value;
		on_parameter_updated();
	}

	bool get_also_optimizes_preselection_path() const {
		return also_optimizes_preselection_path;
	}
	void set_also_optimizes_preselection_path(bool p_value) {
		also_optimizes_preselection_path = p_value;
		on_parameter_updated();
	}

	bool get_forces_character_position_to_match_edge_at_start() const {
		return forces_character_position_to_match_edge_at_start;
	}
	void set_forces_character_position_to_match_edge_at_start(bool p_value) {
		forces_character_position_to_match_edge_at_start = p_value;
		on_parameter_updated();
	}

	bool get_forces_character_velocity_to_match_edge_at_start() const {
		return forces_character_velocity_to_match_edge_at_start;
	}
	void set_forces_character_velocity_to_match_edge_at_start(bool p_value) {
		forces_character_velocity_to_match_edge_at_start = p_value;
		on_parameter_updated();
	}

	bool get_forces_character_position_to_match_path_at_end() const {
		return forces_character_position_to_match_path_at_end;
	}
	void set_forces_character_position_to_match_path_at_end(bool p_value) {
		forces_character_position_to_match_path_at_end = p_value;
		on_parameter_updated();
	}

	bool get_forces_character_velocity_to_zero_at_path_end() const {
		return forces_character_velocity_to_zero_at_path_end;
	}
	void set_forces_character_velocity_to_zero_at_path_end(bool p_value) {
		forces_character_velocity_to_zero_at_path_end = p_value;
		on_parameter_updated();
	}

	bool get_syncs_character_position_to_edge_trajectory() const {
		return syncs_character_position_to_edge_trajectory;
	}
	void set_syncs_character_position_to_edge_trajectory(bool p_value) {
		syncs_character_position_to_edge_trajectory = p_value;
		on_parameter_updated();
	}

	bool get_syncs_character_velocity_to_edge_trajectory() const {
		return syncs_character_velocity_to_edge_trajectory;
	}
	void set_syncs_character_velocity_to_edge_trajectory(bool p_value) {
		syncs_character_velocity_to_edge_trajectory = p_value;
		on_parameter_updated();
	}

	bool get_includes_continuous_trajectory_positions() const {
		return includes_continuous_trajectory_positions;
	}
	void set_includes_continuous_trajectory_positions(bool p_value) {
		includes_continuous_trajectory_positions = p_value;
		on_parameter_updated();
	}

	bool get_includes_continuous_trajectory_velocities() const {
		return includes_continuous_trajectory_velocities;
	}
	void set_includes_continuous_trajectory_velocities(bool p_value) {
		includes_continuous_trajectory_velocities = p_value;
		on_parameter_updated();
	}

	bool get_includes_discrete_trajectory_state() const {
		return includes_discrete_trajectory_state;
	}
	void set_includes_discrete_trajectory_state(bool p_value) {
		includes_discrete_trajectory_state = p_value;
		on_parameter_updated();
	}

	bool get_is_trajectory_state_stored_at_build_time() const {
		return is_trajectory_state_stored_at_build_time;
	}
	void set_is_trajectory_state_stored_at_build_time(bool p_value) {
		is_trajectory_state_stored_at_build_time = p_value;
		on_parameter_updated();
	}

	bool get_bypasses_runtime_physics() const {
		return bypasses_runtime_physics;
	}
	void set_bypasses_runtime_physics(bool p_value) {
		bypasses_runtime_physics = p_value;
		on_parameter_updated();
	}

	int get_default_nav_interrupt_resolution_mode() const {
		return default_nav_interrupt_resolution_mode;
	}
	void set_default_nav_interrupt_resolution_mode(int p_value) {
		default_nav_interrupt_resolution_mode = p_value;
		on_parameter_updated();
	}

	float get_min_intra_surface_distance_to_optimize_jump_for() const {
		return min_intra_surface_distance_to_optimize_jump_for;
	}
	void set_min_intra_surface_distance_to_optimize_jump_for(float p_value) {
		min_intra_surface_distance_to_optimize_jump_for = p_value;
		on_parameter_updated();
	}

	float get_dist_sq_thres_for_considering_additional_jump_land_points()
			const {
		return dist_sq_thres_for_considering_additional_jump_land_points;
	}
	void set_dist_sq_thres_for_considering_additional_jump_land_points(
			float p_value) {
		dist_sq_thres_for_considering_additional_jump_land_points = p_value;
		on_parameter_updated();
	}

	bool get_stops_after_finding_first_valid_edge_for_a_surface_pair() const {
		return stops_after_finding_first_valid_edge_for_a_surface_pair;
	}
	void set_stops_after_finding_first_valid_edge_for_a_surface_pair(
			bool p_value) {
		stops_after_finding_first_valid_edge_for_a_surface_pair = p_value;
		on_parameter_updated();
	}

	bool get_calculates_all_valid_edges_for_a_surface_pair() const {
		return calculates_all_valid_edges_for_a_surface_pair;
	}
	void set_calculates_all_valid_edges_for_a_surface_pair(bool p_value) {
		calculates_all_valid_edges_for_a_surface_pair = p_value;
		on_parameter_updated();
	}

	bool get_always_includes_jump_land_positions_at_surface_ends() const {
		return always_includes_jump_land_positions_at_surface_ends;
	}
	void set_always_includes_jump_land_positions_at_surface_ends(bool p_value) {
		always_includes_jump_land_positions_at_surface_ends = p_value;
		on_parameter_updated();
	}

	bool get_includes_redundant_j_l_positions_with_zero_start_velocity() const {
		return includes_redundant_j_l_positions_with_zero_start_velocity;
	}
	void set_includes_redundant_j_l_positions_with_zero_start_velocity(
			bool p_value) {
		includes_redundant_j_l_positions_with_zero_start_velocity = p_value;
		on_parameter_updated();
	}

	float get_normal_jump_instruction_duration_increase() const {
		return normal_jump_instruction_duration_increase;
	}
	void set_normal_jump_instruction_duration_increase(float p_value) {
		normal_jump_instruction_duration_increase = p_value;
		on_parameter_updated();
	}

	float get_exceptional_jump_instruction_duration_increase() const {
		return exceptional_jump_instruction_duration_increase;
	}
	void set_exceptional_jump_instruction_duration_increase(float p_value) {
		exceptional_jump_instruction_duration_increase = p_value;
		on_parameter_updated();
	}

	bool get_recurses_when_colliding_during_horizontal_step_calculations()
			const {
		return recurses_when_colliding_during_horizontal_step_calculations;
	}
	void set_recurses_when_colliding_during_horizontal_step_calculations(
			bool p_value) {
		recurses_when_colliding_during_horizontal_step_calculations = p_value;
		on_parameter_updated();
	}

	bool get_backtracks_for_higher_jumps_during_hor_step_calculations() const {
		return backtracks_for_higher_jumps_during_hor_step_calculations;
	}
	void set_backtracks_for_higher_jumps_during_hor_step_calculations(
			bool p_value) {
		backtracks_for_higher_jumps_during_hor_step_calculations = p_value;
		on_parameter_updated();
	}

	float get_collision_margin_for_edge_calculations() const {
		return collision_margin_for_edge_calculations;
	}
	void set_collision_margin_for_edge_calculations(float p_value) {
		collision_margin_for_edge_calculations = p_value;
		on_parameter_updated();
	}

	float get_collision_margin_for_waypoint_positions() const {
		return collision_margin_for_waypoint_positions;
	}
	void set_collision_margin_for_waypoint_positions(float p_value) {
		collision_margin_for_waypoint_positions = p_value;
		on_parameter_updated();
	}

	bool get_skips_less_likely_jump_land_positions() const {
		return skips_less_likely_jump_land_positions;
	}
	void set_skips_less_likely_jump_land_positions(bool p_value) {
		skips_less_likely_jump_land_positions = p_value;
		on_parameter_updated();
	}

	bool get_prevents_path_ends_from_exceeding_surface_ends_with_offsets()
			const {
		return prevents_path_ends_from_exceeding_surface_ends_with_offsets;
	}
	void set_prevents_path_ends_from_exceeding_surface_ends_with_offsets(
			bool p_value) {
		prevents_path_ends_from_exceeding_surface_ends_with_offsets = p_value;
		on_parameter_updated();
	}

	bool get_reuses_previous_waypoints_when_backtracking_on_jump_height()
			const {
		return reuses_previous_waypoints_when_backtracking_on_jump_height;
	}
	void set_reuses_previous_waypoints_when_backtracking_on_jump_height(
			bool p_value) {
		reuses_previous_waypoints_when_backtracking_on_jump_height = p_value;
		on_parameter_updated();
	}

	bool get_asserts_no_preexisting_collisions_during_edge_calculations()
			const {
		return asserts_no_preexisting_collisions_during_edge_calculations;
	}
	void set_asserts_no_preexisting_collisions_during_edge_calculations(
			bool p_value) {
		asserts_no_preexisting_collisions_during_edge_calculations = p_value;
		on_parameter_updated();
	}

	bool get_checks_for_alt_intersection_points_for_oblique_collisions() const {
		return checks_for_alt_intersection_points_for_oblique_collisions;
	}
	void set_checks_for_alt_intersection_points_for_oblique_collisions(
			bool p_value) {
		checks_for_alt_intersection_points_for_oblique_collisions = p_value;
		on_parameter_updated();
	}

	float get_oblique_collison_normal_aspect_ratio_threshold() const {
		return oblique_collison_normal_aspect_ratio_threshold;
	}
	void set_oblique_collison_normal_aspect_ratio_threshold(float p_value) {
		oblique_collison_normal_aspect_ratio_threshold = p_value;
		on_parameter_updated();
	}

	int get_min_frame_count_when_colliding_early_with_expected_surface() const {
		return min_frame_count_when_colliding_early_with_expected_surface;
	}
	void set_min_frame_count_when_colliding_early_with_expected_surface(
			int p_value) {
		min_frame_count_when_colliding_early_with_expected_surface = p_value;
		on_parameter_updated();
	}

	float get_reached_in_air_destination_distance_squared_threshold() const {
		return reached_in_air_destination_distance_squared_threshold;
	}
	void set_reached_in_air_destination_distance_squared_threshold(
			float p_value) {
		reached_in_air_destination_distance_squared_threshold = p_value;
		on_parameter_updated();
	}

	int get_max_edges_to_remove_from_path_for_opt_to_in_air_dest() const {
		return max_edges_to_remove_from_path_for_opt_to_in_air_dest;
	}
	void set_max_edges_to_remove_from_path_for_opt_to_in_air_dest(int p_value) {
		max_edges_to_remove_from_path_for_opt_to_in_air_dest = p_value;
		on_parameter_updated();
	}

	bool get_always_tries_to_face_direction_of_motion() const {
		return always_tries_to_face_direction_of_motion;
	}
	void set_always_tries_to_face_direction_of_motion(bool p_value) {
		always_tries_to_face_direction_of_motion = p_value;
		on_parameter_updated();
	}

	float get_max_distance_for_reachable_surface_tracking() const {
		return max_distance_for_reachable_surface_tracking;
	}
	void set_max_distance_for_reachable_surface_tracking(float p_value) {
		max_distance_for_reachable_surface_tracking = p_value;
		on_parameter_updated();
	}

	// --- Derived values ---

	float get_gravity_fast_fall() const;
	float get_slow_rise_gravity_multiplier() const;
	float get_gravity_slow_rise() const;
	float get_rise_double_jump_gravity_multiplier() const;
	float get_rise_double_jump_gravity() const;
	float get_walk_acceleration() const;
	float get_in_air_horizontal_acceleration() const;
	float get_climb_up_speed() const;
	float get_climb_down_speed() const;
	float get_ceiling_crawl_speed() const;
	float get_friction_coeff_with_sideways_input() const;
	float get_friction_coeff_without_sideways_input() const;
	float get_jump_boost() const;
	float get_wall_jump_horizontal_boost() const;
	float get_wall_fall_horizontal_boost() const;
	float get_max_horizontal_speed_default() const;
	float get_max_vertical_speed() const;
	float get_max_possible_speed() const;
	float get_dash_speed_multiplier() const;
	float get_dash_vertical_boost() const;
	float get_dash_duration() const;
	float get_dash_fade_duration() const;
	float get_dash_cooldown() const;
	float get_additional_edge_weight_offset() const;
	float get_walking_edge_weight_multiplier() const;
	float get_ceiling_crawling_edge_weight_multiplier() const;
	float get_climbing_edge_weight_multiplier() const;
	float get_climb_to_adjacent_surface_edge_weight_multiplier() const;
	float get_move_to_collinear_surface_edge_weight_multiplier() const;
	float get_air_edge_weight_multiplier() const;
	float get_max_surface_speed() const;
	float get_max_air_horizontal_speed() const;
	float get_smaller_of_max_surface_and_air_horizontal_speed() const;

protected:
	static void _bind_methods();

private:
	// --- Movement abilities ---

	bool can_grab_walls = false;
	bool can_grab_ceilings = false;
	bool can_grab_floors = true;
	bool can_jump = true;
	bool can_dash = false;
	bool can_double_jump = false;
	bool can_target_in_air_destinations = true;

	// --- Physics movement ---

	// - This affects the character's speed while moving along a surface.
	// - This does not affect jump start/end velocities or in-air velocities.
	// - This will modify both acceleration and max-speed.
	// - This is similar to SurfaceProperties.speed_multiplier
	float surface_speed_multiplier = 1.0;
	// - This affects the character's horizontal speed while in air.
	// - This does not affect jump start/end velocities or surface speeds.
	// - This will modify both acceleration and max-speed.
	float air_horizontal_speed_multiplier = 1.0;
	// Each character can use a different gravity value.
	float gravity_multiplier = 1.0;
	// Surfacer supports "fast-fall", which means that the ascent of a jump can
	// use a weaker gravity and take longer than the descent.
	float gravity_slow_rise_multiplier_multiplier = 1.0;
	float gravity_double_jump_slow_rise_multiplier_multiplier = 1.0;
	float walk_acceleration_multiplier = 1.0;
	float in_air_horizontal_acceleration_multiplier = 1.0;
	float climb_up_speed_multiplier = 1.0;
	float climb_down_speed_multiplier = 1.0;
	float ceiling_crawl_speed_multiplier = 1.0;
	float friction_coefficient_multiplier = 1.0;
	float jump_boost_multiplier = 1.0;
	float wall_jump_horizontal_boost_multiplier = 1.0;
	float wall_fall_horizontal_boost_multiplier = 1.0;
	float ceiling_fall_velocity_boost = 100.0;
	float max_horizontal_speed_default_multiplier = 1.0;
	float max_vertical_speed_multiplier = 1.0;
	float fall_through_floor_velocity_boost = 100.0;
	// This is passed into `KinematicBody2D.move_and_slide`.
	bool stops_on_slope = true;

	// --- Dash ---

	float dash_speed_multiplier_multiplier = 1.0;
	float dash_vertical_boost_multiplier = 1.0;
	float dash_duration_multiplier = 1.0;
	float dash_fade_duration_multiplier = 1.0;
	float dash_cooldown_multiplier = 1.0;

	// --- Double jump ---

	int max_jump_chain = 1;

	// --- Edge weights ---

	// The A* search could use movement distances or durations to represent edge
	// weights.
	bool uses_duration_instead_of_distance_for_edge_weight = true;
	// If an extra weight is applied for each additional edge, then the
	// character will favor paths that cross fewer surfaces, even if the path
	// may take longer.
	float additional_edge_weight_offset_override = -1.0;
	// If extra weight is applied to walking edges, then the character will
	// favor paths that involve more jumps, even if the path may take longer.
	float walking_edge_weight_multiplier_override = -1.0;
	// If extra weight is applied to ceiling-crawling edges, then the character
	// will favor paths that don't involve ceilings, even if the path may take
	// longer.
	float ceiling_crawling_edge_weight_multiplier_override = -1.0;
	// If extra weight is applied to climbing edges, then the character will
	// favor paths that involve more jumps, even if the path may take longer.
	float climbing_edge_weight_multiplier_override = -1.0;
	// If extra weight is applied to climb-to-adjacent_surface edges, then the
	// character will favor paths that involve jumping between surfaces, even if
	// the path may take longer.
	float climb_to_adjacent_surface_edge_weight_multiplier_override = -1.0;
	// When transitioning to a collinear neighbor surface, it often makes sense
	// to not include any edge weight.
	float move_to_collinear_surface_edge_weight_multiplier_override = -1.0;
	// If extra weight is applied to air edges, then the character will favor
	// paths that involve fewer jumps, even if the path may take longer.
	float air_edge_weight_multiplier_override = -1.0;

	// --- Surface graph calculations ---

	// TODO: For some reason, when this is true, we see fewer valid edges. In
	// theory, this shouldn't be the case?
	// - If this is true, then horizontal movement will be applied earlier in a
	// jump rather than later.
	// - That is, if this is true, jump trajectories will be less
	// up-sideways-then-down, and more parabolic and diagonal.
	bool minimizes_velocity_change_when_jumping = false;
	// - If this is true, then at runtime, after finding a path through
	// build-time-calculated edges, the SurfaceNavigator will try to optimize
	// the jump-off points of the edges to better account for the direction that
	// the character will be approaching the edge from.
	// - This produces more efficient and natural movement.
	// - The build-time-calculated edge state would only use surface end-points
	// or closest points.
	// - We also take this opportunity to update start velocities to exactly
	// match what is allowed from the ramp-up distance along the edge, rather
	// than either the fixed zero or max-speed value used for the
	// build-time-calculated edge state.
	// - However, these edge calculations can be expensive.
	bool optimizes_edge_jump_positions_at_run_time = true;
	bool optimizes_edge_land_positions_at_run_time = true;
	// - Optimizing edges can be expensive.
	// - Preselections can be updated very frequently (nearly every frame).
	// - So setting this to true could have a significant performance impact.
	// - However, setting this to false means that the player will see
	// inaccurate trajectories, which could be especially significant if
	// beat-tracking is enabled or path timings are important.
	bool also_optimizes_preselection_path = true;
	bool forces_character_position_to_match_edge_at_start = true;
	bool forces_character_velocity_to_match_edge_at_start = true;
	bool forces_character_position_to_match_path_at_end = false;
	bool forces_character_velocity_to_zero_at_path_end = false;
	// - If true, then character position will be forced to match the expected
	// calculated edge-movement position during each frame.
	// - Without this, there is typically some deviation at run-time from the
	// expected calculated edge trajectories.
	bool syncs_character_position_to_edge_trajectory = true;
	// - If true, then character velocity will be forced to match the expected
	// calculated edge-movement velocity during each frame.
	// - Without this, there is typically some deviation at run-time from the
	// expected calculated edge trajectories.
	bool syncs_character_velocity_to_edge_trajectory = true;
	// - If true, then trajectory positions will be stored after performing edge
	// calculations.
	// - This state could be used for drawing path trajectories or updating
	// character positions at runtime.
	bool includes_continuous_trajectory_positions = true;
	// - If true, then trajectory velocities will be stored after performing
	// edge calculations.
	// - This state could be used for drawing path trajectories or updating
	// character velocities at runtime.
	bool includes_continuous_trajectory_velocities = true;
	// - If true, then discrete trajectory state will be calculated and saved
	// for each edge.
	// - This "discrete" state should more closely reflect what would be
	// generated by normal character movement at runtime, rather than the
	// "continuous" state, which doesn't take into account the error due to the
	// calculation sampling interval.
	bool includes_discrete_trajectory_state = true;
	// - If false, then any trajectory state that would have otherwise been
	// stored (according to other MovementParameters flags), will not be stored
	// in either the runtime SurfaceGraph or in the build-time surface-graph
	// save files.
	// - Omitting this trajectory state from a save file can significantly
	// reduce its size.
	// - If trajectory state is omitted at build time, and is still needed at
	// runtime, then it will be calculated on-the-fly as needed.
	bool is_trajectory_state_stored_at_build_time = false;
	// - If true, then the character position will be updated according to
	// pre-calculated edge trajectories, and Godot's physics and collision
	// engine will not be used to update character state.
	// - This also means that the player will not be able to control movement
	// with standard move and jump key-press actions.
	bool bypasses_runtime_physics = false;
	int default_nav_interrupt_resolution_mode =
			NavigationInterruptionResolution::FORCE_EXPECTED_STATE;
	float min_intra_surface_distance_to_optimize_jump_for = 16.0;
	// - When calculating possible edges between a given pair of surfaces, we
	// usually need to quit early (for performance) as soon as we've found
	// enough edges, rather than calculate all possible edges.
	// - In order to decide whether to skip edge calculation for a given
	// jump/land point, we look at how far away it is from any other jump/land
	// point that we already found a valid edge for, on the same surface, for
	// the same surface pair.
	// - We use this distance to determine threshold how far away is enough.
	float dist_sq_thres_for_considering_additional_jump_land_points =
			32.0 * 32.0;
	// - If true, then edge calculations for a given surface pair will stop
	// early as soon as the first valid edge for the pair is found.
	// - This overrides
	// dist_sq_thres_for_considering_additional_jump_land_points.
	bool stops_after_finding_first_valid_edge_for_a_surface_pair = false;
	// - If true, then valid edges will be calculated for every good jump/land
	// position between a given surface pair.
	// - This will take more time to compute.
	// - This overrides
	// dist_sq_thres_for_considering_additional_jump_land_points.
	bool calculates_all_valid_edges_for_a_surface_pair = false;
	// - If this is true, then extra jump/land position combinations will be
	// considered for every surface pair for all combinations of surface ends
	// between the two surfaces.
	// - This should always be redundant with the more intelligent and efficient
	// jump/land positions combinations.
	bool always_includes_jump_land_positions_at_surface_ends = false;
	bool includes_redundant_j_l_positions_with_zero_start_velocity = true;
	// - This is a constant increase to all jump durations.
	// - This could make it more likely for edge calculations to succeed
	// earlier, or it could just make the character seem more floaty.
	float normal_jump_instruction_duration_increase = 0.08;
	// - This is a constant increase to all jump durations.
	// - Some edge calculations are identified early on as likely needing some
	// additional jump height in order to navigate around intermediate surfaces.
	// - This duration increase is used for those exceptional edge calculations.
	float exceptional_jump_instruction_duration_increase = 0.2;
	// If false, then edge calculations will not try to move around intermediate
	// surfaces, which will produce many false-negatives.
	bool recurses_when_colliding_during_horizontal_step_calculations = true;
	// If false, then edge calculations will not try to consider higher jump
	// height in order to move around intermediate surfaces, which will produce
	// many false negatives.
	bool backtracks_for_higher_jumps_during_hor_step_calculations = true;
	// The amount of extra margin to include around the character collision
	// boundary when performing collision detection for a given edge
	// calculation.
	float collision_margin_for_edge_calculations = 1.0;
	// The amount of extra margin to include for waypoint offsets, so that the
	// character doesn't collide unexpectedly with the surface.
	float collision_margin_for_waypoint_positions = 4.0;
	// - Some jump/land posititions are less likely to produce valid movement,
	// simply because of how the surfaces are arranged.
	// - Usually there is another more likely pair for the given surfaces.
	// - However, sometimes such pairs can be valid, and sometimes they can even
	// be the only valid pair for the given surfaces.
	bool skips_less_likely_jump_land_positions = false;
	// - If true, then the navigator will include extra offsets so that paths
	// don't end too close to surface ends, and will dynamically insert extra
	// backtracking edges if the character ends up past a surface end at the end
	// of a path.
	// - This should be unnecessary if
	// forces_character_position_to_match_path_at_end is true.
	bool prevents_path_ends_from_exceeding_surface_ends_with_offsets = true;
	// - If true, then edge calculations will re-use previously calculated
	// intermediate waypoints when attempting to backtrack and use a higher max
	// jump height.
	// - Otherwise, intermediate waypoints are recalculated, which can be more
	// expensive, but could produce slightly more accurate results.
	bool reuses_previous_waypoints_when_backtracking_on_jump_height = false;
	bool asserts_no_preexisting_collisions_during_edge_calculations = false;
	// - If true, then edge calculations will attempt to consider alternate
	// intersection points from shape-casting when calculating collision
	// details, rather than the default point returned from move_and_collide,
	// when the default point corresponds to a very oblique collision angle.
	// - For example, move_and_collide could otherwise detect collisons with the
	// adjacent wall when moving vertically and colliding with the edge of a
	// ceiling.
	bool checks_for_alt_intersection_points_for_oblique_collisions = true;
	float oblique_collison_normal_aspect_ratio_threshold = 10.0;
	int min_frame_count_when_colliding_early_with_expected_surface = 4;
	float reached_in_air_destination_distance_squared_threshold = 16.0 * 16.0;
	int max_edges_to_remove_from_path_for_opt_to_in_air_dest = 2;
	// - When accelerating horizontally, i.e., pressing sideways input, the
	// character will face the direction of acceleration.
	// - However, the character's horizontal velocity isn't necessarily in the
	// same direction as their acceleration.
	// - This means that the character can sometimes appear to face the wrong
	// way when jumping/falling.
	// - If this flag is enabled, an extra face-left/face-right input will be
	// triggered after a move-left/move-right input ends and the player is
	// facing the opposite direction from motion.
	bool always_tries_to_face_direction_of_motion = true;
	float max_distance_for_reachable_surface_tracking = 1024.0;

	void on_parameter_updated();
};

} //namespace godot

#endif // MOVEMENT_PARAMETERS_H

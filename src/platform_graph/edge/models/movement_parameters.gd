tool
class_name MovementParameters, \
"res://addons/surfacer/assets/images/editor_icons/movement_params.png"
extends Node2D
## -   This defines how your character will move.[br]
## -   There are a _lot_ of parameters you can adjust here.[br]
## -   You can adjust these parameters within the editor's inspector panel.[br]


const STRONG_SPEED_TO_MAINTAIN_COLLISION := 900.0

# --- Movement abilities ---

const _MOVEMENT_ABILITIES_GROUP := {
    group_name = "Movement abilities",
    first_property_name = "can_grab_walls",
}

var can_grab_walls := false setget _set_can_grab_walls
var can_grab_ceilings := false setget _set_can_grab_ceilings
var can_grab_floors := true
var can_jump := true setget _set_can_jump
var can_dash := false setget _set_can_dash
var can_double_jump := false setget _set_can_double_jump

# --- Physics movement ---

const _PHYSICS_MOVEMENT_GROUP := {
    group_name = "physics_movement",
    first_property_name = "surface_speed_multiplier",
}

## -   This affects the character's speed while moving along a surface.[br]
## -   This does not affect jump start/end velocities or in-air velocities.[br]
## -   This will modify both acceleration and max-speed.[br]
var surface_speed_multiplier := 1.0 \
        setget _set_surface_speed_multiplier

## -   This affects the character's horizontal speed while in air.[br]
## -   This does not affect jump start/end velocities or surface speeds.[br]
## -   This will modify both acceleration and max-speed.[br]
var air_horizontal_speed_multiplier := 1.0 \
        setget _set_air_horizontal_speed_multiplier

## Each character can use a different gravity value.
var gravity_multiplier := 1.0 \
        setget _set_gravity_multiplier
## Surfacer supports "fast-fall", which means that the ascent of a jump can use
## a weaker gravity and take longer than the descent.
var gravity_slow_rise_multiplier_multiplier := 1.0  \
        setget _set_gravity_slow_rise_multiplier_multiplier
var gravity_double_jump_slow_rise_multiplier_multiplier := 1.0 \
        setget _set_gravity_double_jump_slow_rise_multiplier_multiplier

var walk_acceleration_multiplier := 1.0 \
        setget _set_walk_acceleration_multiplier
var in_air_horizontal_acceleration_multiplier := 1.0 \
        setget _set_in_air_horizontal_acceleration_multiplier
var climb_up_speed_multiplier := 1.0 \
        setget _set_climb_up_speed_multiplier
var climb_down_speed_multiplier := 1.0 \
        setget _set_climb_down_speed_multiplier
var ceiling_crawl_speed_multiplier := 1.0 \
        setget _set_ceiling_crawl_speed_multiplier

var friction_coefficient_multiplier := 1.0 \
        setget _set_friction_coefficient_multiplier

var jump_boost_multiplier := 1.0 \
        setget _set_jump_boost_multiplier
var wall_jump_horizontal_boost_multiplier := 1.0 \
        setget _set_wall_jump_horizontal_boost_multiplier
var wall_fall_horizontal_boost_multiplier := 1.0 \
        setget _set_wall_fall_horizontal_boost_multiplier
var ceiling_fall_velocity_boost := 100.0 \
        setget _set_ceiling_fall_velocity_boost

var max_horizontal_speed_default_multiplier := 1.0 \
        setget _set_max_horizontal_speed_default_multiplier
var max_vertical_speed_multiplier := 1.0 \
        setget _set_max_vertical_speed_multiplier

var fall_through_floor_velocity_boost := 100.0 \
        setget _set_fall_through_floor_velocity_boost

## This is passed into `KinematicBody2D.move_and_slide`.
var stops_on_slope := true

# --- Dash ---

const _DASH_GROUP := {
    group_name = "dash",
    first_property_name = "dash_speed_multiplier_multiplier",
}

var dash_speed_multiplier_multiplier := 1.0 \
        setget _set_dash_speed_multiplier_multiplier
var dash_vertical_boost_multiplier := 1.0 \
        setget _set_dash_vertical_boost_multiplier
var dash_duration_multiplier := 1.0 \
        setget _set_dash_duration_multiplier
var dash_fade_duration_multiplier := 1.0 \
        setget _set_dash_fade_duration_multiplier
var dash_cooldown_multiplier := 1.0 \
        setget _set_dash_cooldown_multiplier

# --- Double jump ---

const _DOUBLE_JUMP_GROUP := {
    group_name = "double_jump",
    first_property_name = "max_jump_chain",
}

var max_jump_chain := 1 \
        setget _set_max_jump_chain

# --- Edge weights ---

const _EDGE_WEIGHTS_GROUP := {
    group_name = "edge_weights",
    first_property_name = "uses_duration_instead_of_distance_for_edge_weight",
}

## The A* search could use movement distances or durations to represent edge
## weights.
var uses_duration_instead_of_distance_for_edge_weight := true \
        setget _set_uses_duration_instead_of_distance_for_edge_weight
## If an extra weight is applied for each additional edge, then the character
## will favor paths that cross fewer surfaces, even if the path may take longer.
var additional_edge_weight_offset_override := -1.0 \
        setget _set_additional_edge_weight_offset_override
## If extra weight is applied to walking edges, then the character will favor
## paths that involve more jumps, even if the path may take longer.
var walking_edge_weight_multiplier_override := -1.0 \
        setget _set_walking_edge_weight_multiplier_override
## If extra weight is applied to ceiling-crawling edges, then the character
## will favor paths that don't involve ceilings, even if the path may take
## longer.
var ceiling_crawling_edge_weight_multiplier_override := -1.0 \
        setget _set_ceiling_crawling_edge_weight_multiplier_override
## If extra weight is applied to climbing edges, then the character will favor
## paths that involve more jumps, even if the path may take longer.
var climbing_edge_weight_multiplier_override := -1.0 \
        setget _set_climbing_edge_weight_multiplier_override
## If extra weight is applied to climb-to-adjacent_surface edges, then the
## character will favor paths that involve jumping between surfaces, even if
## the path may take longer.
var climb_to_adjacent_surface_edge_weight_multiplier_override := -1.0 \
        setget _set_climb_to_adjacent_surface_edge_weight_multiplier_override
## When transitioning to a collinear neighbor surface, it often makes sense to
## not include any edge weight.
var move_to_collinear_surface_edge_weight_multiplier_override := -1.0 \
        setget _set_move_to_collinear_surface_edge_weight_multiplier_override
## If extra weight is applied to air edges, then the character will favor
## paths that involve fewer jumps, even if the path may take longer.
var air_edge_weight_multiplier_override := -1.0 \
        setget _set_air_edge_weight_multiplier_override

# --- Platform graph calculations ---

const _PLATFORM_GRAPH_CALCULATIONS_GROUP := {
    group_name = "platform_graph_calculations",
    first_property_name = "minimizes_velocity_change_when_jumping",
}

# TODO: For some reason, when this is true, we see fewer valid edges. In
#       theory, this shouldn't be the case?
## -   If this is true, then horizontal movement will be applied earlier in a
##     jump rather than later.[br]
## -   That is, if this is true, jump trajectories will be less
##     up-sideways-then-down, and more parabolic and diagonal.[br]
var minimizes_velocity_change_when_jumping := false \
        setget _set_minimizes_velocity_change_when_jumping
## -   If this is true, then at runtime, after finding a path through
##     build-time-calculated edges, the SurfaceNavigator will try to optimize
##     the jump-off points of the edges to better account for the direction
##     that the character will be approaching the edge from.[br]
## -   This produces more efficient and natural movement.[br]
## -   The build-time-calculated edge state would only use surface end-points or
##     closest points.[br]
## -   We also take this opportunity to update start velocities to exactly match
##     what is allowed from the ramp-up distance along the edge, rather than
##     either the fixed zero or max-speed value used for the
##     build-time-calculated edge state.[br]
## -   However, these edge calculations can be expensive.[br]
var optimizes_edge_jump_positions_at_run_time := true \
        setget _set_optimizes_edge_jump_positions_at_run_time
var optimizes_edge_land_positions_at_run_time := true \
        setget _set_optimizes_edge_land_positions_at_run_time
## -   Optimizing edges can be expensive.[br]
## -   Preselections can be updated very frequently (nearly every frame).[br]
## -   So setting this to true could have a significant performance impact.[br]
## -   However, setting this to false means that the player will see inaccurate
##     trajectories, which could be especially significant if beat-tracking is
##     enabled or path timings are important.[br]
var also_optimizes_preselection_path := true \
        setget _set_also_optimizes_preselection_path
var forces_character_position_to_match_edge_at_start := true \
        setget _set_forces_character_position_to_match_edge_at_start
var forces_character_velocity_to_match_edge_at_start := true \
        setget _set_forces_character_velocity_to_match_edge_at_start
var forces_character_position_to_match_path_at_end := false \
        setget _set_forces_character_position_to_match_path_at_end
var forces_character_velocity_to_zero_at_path_end := false \
        setget _set_forces_character_velocity_to_zero_at_path_end
## -   If true, then character position will be forced to match the expected
##     calculated edge-movement position during each frame.[br]
## -   Without this, there is typically some deviation at run-time from the
##     expected calculated edge trajectories.[br]
var syncs_character_position_to_edge_trajectory := true \
        setget _set_syncs_character_position_to_edge_trajectory
## -   If true, then character velocity will be forced to match the expected
##     calculated edge-movement velocity during each frame.[br]
## -   Without this, there is typically some deviation at run-time from the
##     expected calculated edge trajectories.[br]
var syncs_character_velocity_to_edge_trajectory := true \
        setget _set_syncs_character_velocity_to_edge_trajectory
## -   If true, then trajectory positions will be stored after performing edge
##     calculations.[br]
## -   This state could be used for drawing path trajectories or updating
##     character positions at runtime.[br]
var includes_continuous_trajectory_positions := true \
        setget _set_includes_continuous_trajectory_positions
## -   If true, then trajectory velocities will be stored after performing edge
##     calculations.[br]
## -   This state could be used for drawing path trajectories or updating
##     character velocities at runtime.[br]
var includes_continuous_trajectory_velocities := true \
        setget _set_includes_continuous_trajectory_velocities
## -   If true, then discrete trajectory state will be calculated and saved for
##     each edge.[br]
## -   This "discrete" state should more closely reflect what would be generated
##     by normal character movement at runtime, rather than the "continuous"
##     state, which doesn't take into account the error due to the calculation
##     sampling interval.[br]
var includes_discrete_trajectory_state := true \
        setget _set_includes_discrete_trajectory_state
## -   If false, then any trajectory state that would have otherwise been stored
##     (according to other MovementParameters flags), will not be stored in
##     either the runtime PlatformGraph or in the build-time platform-graph save
##     files.[br]
## -   Omitting this trajectory state from a save file can significantly reduce
##     its size.[br]
## -   If trajectory state is omitted at build time, and is still needed at
##     runtime, then it will be calculated on-the-fly as needed.[br]
var is_trajectory_state_stored_at_build_time := false \
        setget _set_is_trajectory_state_stored_at_build_time
## -   If true, then the character position will be updated according to
##     pre-calculated edge trajectories, and Godot's physics and collision
##     engine will not be used to update character state.[br]
## -   This also means that the player will not be able to control movement with
##     standard move and jump key-press actions.[br]
var bypasses_runtime_physics := false \
        setget _set_bypasses_runtime_physics

var default_nav_interrupt_resolution_mode := \
        NavigationInterruptionResolution.FORCE_EXPECTED_STATE \
        setget _set_default_nav_interrupt_resolution_mode
var min_intra_surface_distance_to_optimize_jump_for := 16.0 \
        setget _set_min_intra_surface_distance_to_optimize_jump_for
## -   When calculating possible edges between a given pair of surfaces, we
##     usually need to quit early (for performance) as soon as we've found
##     enough edges, rather than calculate all possible edges.[br]
## -   In order to decide whether to skip edge calculation for a given jump/land
##     point, we look at how far away it is from any other jump/land point that
##     we already found a valid edge for, on the same surface, for the same
##     surface pair.[br]
## -   We use this distance to determine threshold how far away is enough.[br]
var dist_sq_thres_for_considering_additional_jump_land_points := \
        32.0 * 32.0 \
        setget _set_dist_sq_thres_for_considering_additional_jump_land_points
## -   If true, then edge calculations for a given surface pair will stop early
##     as soon as the first valid edge for the pair is found.[br]
## -   This overrides
##     dist_sq_thres_for_considering_additional_jump_land_points.[br]
var stops_after_finding_first_valid_edge_for_a_surface_pair := false \
        setget _set_stops_after_finding_first_valid_edge_for_a_surface_pair
## -   If true, then valid edges will be calculated for every good jump/land
##     position between a given surface pair.[br]
## -   This will take more time to compute.[br]
## -   This overrides
##     dist_sq_thres_for_considering_additional_jump_land_points.[br]
var calculates_all_valid_edges_for_a_surface_pair := false \
        setget _set_calculates_all_valid_edges_for_a_surface_pair
## -   If this is true, then extra jump/land position combinations will be
##     considered for every surface pair for all combinations of surface ends
##     between the two surfaces.[br]
## -   This should always be redundant with the more intelligent and efficient
##     jump/land positions combinations.[br]
var always_includes_jump_land_positions_at_surface_ends := false \
        setget _set_always_includes_jump_land_positions_at_surface_ends
var includes_redundant_j_l_positions_with_zero_start_velocity := true \
        setget _set_includes_redundant_j_l_positions_with_zero_start_velocity
## -   This is a constant increase to all jump durations.[br]
## -   This could make it more likely for edge calculations to succeed earlier,
##     or it could just make the character seem more floaty.[br]
var normal_jump_instruction_duration_increase := 0.08 \
        setget _set_normal_jump_instruction_duration_increase
## -   This is a constant increase to all jump durations.[br]
## -   Some edge calculations are identified early on as likely needing some
##     additional jump height in order to navigate around intermediate
##     surfaces.[br]
## -   This duration increase is used for those exceptional edge
##     calculations.[br]
var exceptional_jump_instruction_duration_increase := 0.2 \
        setget _set_exceptional_jump_instruction_duration_increase
## If false, then edge calculations will not try to move around intermediate
## surfaces, which will produce many false-negatives.
var recurses_when_colliding_during_horizontal_step_calculations := true \
        setget _set_recurses_when_colliding_during_horizontal_step_calculations
## If false, then edge calculations will not try to consider higher jump height
## in order to move around intermediate surfaces, which will produce many false
## negatives.
var backtracks_for_higher_jumps_during_hor_step_calculations := true \
        setget _set_backtracks_for_higher_jumps_during_hor_step_calculations
## The amount of extra margin to include around the character collision boundary
## when performing collision detection for a given edge calculation.
var collision_margin_for_edge_calculations := 1.0 \
        setget _set_collision_margin_for_edge_calculations
## The amount of extra margin to include for waypoint offsets, so that the
## character doesn't collide unexpectedly with the surface.
var collision_margin_for_waypoint_positions := 4.0 \
        setget _set_collision_margin_for_waypoint_positions
## -   Some jump/land posititions are less likely to produce valid movement,
##     simply because of how the surfaces are arranged.[br]
## -   Usually there is another more likely pair for the given surfaces.[br]
## -   However, sometimes such pairs can be valid, and sometimes they can even
##     be the only valid pair for the given surfaces.[br]
var skips_less_likely_jump_land_positions := false \
        setget _set_skips_less_likely_jump_land_positions
## -   If true, then the navigator will include extra offsets so that paths
##     don't end too close to surface ends, and will dynamically insert extra
##     backtracking edges if the character ends up past a surface end at the
##     end of a path.[br]
## -   This should be unnecessary if
##     forces_character_position_to_match_path_at_end is true.[br]
var prevents_path_ends_from_exceeding_surface_ends_with_offsets := true \
        setget _set_prevents_path_ends_from_exceeding_surface_ends_with_offsets
## -   If true, then edge calculations will re-use previously calculated
##     intermediate waypoints when attempting to backtrack and use a higher max
##     jump height.[br]
## -   Otherwise, intermediate waypoints are recalculated, which can be more
##     expensive, but could produce slightly more accurate results.[br]
var reuses_previous_waypoints_when_backtracking_on_jump_height := false \
        setget _set_reuses_previous_waypoints_when_backtracking_on_jump_height
var asserts_no_preexisting_collisions_during_edge_calculations := false \
        setget _set_asserts_no_preexisting_collisions_during_edge_calculations
## -   If true, then edge calculations will attempt to consider alternate
##     intersection points from shape-casting when calculating collision
##     details, rather than the default point returned from move_and_collide,
##     when the default point corresponds to a very oblique collision angle.[br]
## -   For example, move_and_collide could otherwise detect collisons with the
##     adjacent wall when moving vertically and colliding with the edge of a
##     ceiling.[br]
var checks_for_alt_intersection_points_for_oblique_collisions := true \
        setget _set_checks_for_alt_intersection_points_for_oblique_collisions
var oblique_collison_normal_aspect_ratio_threshold_threshold := 10.0 \
        setget _set_oblique_collison_normal_aspect_ratio_threshold_threshold
var min_frame_count_when_colliding_early_with_expected_surface := 4 \
        setget _set_min_frame_count_when_colliding_early_with_expected_surface
var reached_in_air_destination_distance_squared_threshold := \
        16.0 * 16.0 \
        setget _set_reached_in_air_destination_distance_squared_threshold
var max_edges_to_remove_from_path_for_opt_to_in_air_dest := 2 \
        setget _set_max_edges_to_remove_from_path_for_opt_to_in_air_dest

## -   When accelerating horizontally, i.e., pressing sideways input, the
##     character will face the direction of acceleration.
## -   However, the character's horizontal velocity isn't necessarily in the
##     same direction as their acceleration.
## -   This means that the character can sometimes appear to face the wrong way
##     when jumping/falling.
## -   If this flag is enabled, an extra face-left/face-right input will be
##     triggered after a move-left/move-right input ends and the player is
##     facing the opposite direction from motion.
var always_tries_to_face_direction_of_motion := true

var max_distance_for_reachable_surface_tracking := 1024.0 \
        setget _set_max_distance_for_reachable_surface_tracking

# --- Logs ---

const _LOGS_GROUP := {
    group_name = "logs",
    first_property_name = "logs_inspector_events",
}

# TODO: It'd be nice to remove this from here, and move it to SurfacerCharacter,
#       but it's used within the PlatformGraphInspector, which deals with a
#       class of character rather than a character instance.
var logs_inspector_events := false \
        setget _set_logs_inspector_events

# --- Movement ability overrides ---

const _MOVEMENT_ABILITY_OVERRIDES_GROUP := {
    group_name = "movement_ability_overrides",
    first_property_name = "edge_calculators_override",
    last_property_name = "action_handlers_override",
    overrides = {
        "edge_calculators_override": {
            # This corresponds to `export(Array, String) var ...`.
            type = TYPE_ARRAY,
            hint = 24,
            hint_string = "4:",
        },
        "action_handlers_override": {
            # This corresponds to `export(Array, String) var ...`.
            type = TYPE_ARRAY,
            hint = 24,
            hint_string = "4:",
        },
    }
}

## -   An EdgeCalculator calculates possible edges between certain types of
##     edge pairs.[br]
## -   For example, JumpFromSurfaceCalculator calculates edges that start from
##     a position along a surfacer, but JumpFromSurfaceCalculator edges may end
##     either along a surface or in the air.[br]
## -   A default set of ActionHandlers is usually assigned based on other
##     movement properties, such as `can_jump`.[br]
var edge_calculators_override := []
## -   An ActionHandler updates a character's state each frame, in response to
##     current events and the character's current state.[br]
## -   For example, FloorJumpAction listens for jump events while the character
##     is on the ground, and triggers character jump state accordingly.[br]
## -   A default set of ActionHandlers is usually assigned based on other
##     movement properties, such as `can_jump`.[br]
var action_handlers_override := []

# --- Derived parameters ---

var gravity_fast_fall: float
var slow_rise_gravity_multiplier: float
var gravity_slow_rise: float
var rise_double_jump_gravity_multiplier: float

var walk_acceleration: float
var in_air_horizontal_acceleration: float
var climb_up_speed: float
var climb_down_speed: float
var ceiling_crawl_speed: float

var friction_coeff_with_sideways_input: float
var friction_coeff_without_sideways_input: float

var jump_boost: float
var wall_jump_horizontal_boost: float
var wall_fall_horizontal_boost: float

var max_horizontal_speed_default: float
var max_vertical_speed: float
var max_possible_speed: float

var dash_speed_multiplier: float
var dash_vertical_boost: float
var dash_duration: float
var dash_fade_duration: float
var dash_cooldown: float

var additional_edge_weight_offset: float
var walking_edge_weight_multiplier: float
var ceiling_crawling_edge_weight_multiplier: float
var climbing_edge_weight_multiplier: float
var climb_to_adjacent_surface_edge_weight_multiplier: float
var move_to_collinear_surface_edge_weight_multiplier: float
var air_edge_weight_multiplier: float

var floor_jump_max_horizontal_jump_distance: float
var wall_jump_max_horizontal_jump_distance: float
var min_upward_jump_distance: float
var max_upward_jump_distance: float
var time_to_max_upward_jump_distance: float

# Array<ActionHandler>
var action_handlers: Array
# Array<EdgeCalculator>
var edge_calculators: Array

var collider := RotatedShape.new()
var collider_shape: Shape2D \
        setget _set_collider_shape
# In radians.
var collider_rotation: float \
        setget _set_collider_rotation

## -   This shape is used for calculating trajectories that approximate what
##     might normally happen at runtime.[br]
## -   These trajectories could be used both for rendering navigation paths, as
##     well as for updating character positions at runtime.[br]
var fall_from_floor_corner_calc_shape := RotatedShape.new()
## -   This shape is used for calculating trajectories that approximate what
##     might normally happen at runtime.[br]
## -   These trajectories could be used both for rendering navigation paths, as
##     well as for updating character positions at runtime.[br]
var rounding_corner_calc_shape := RotatedShape.new()

var character_name := ""

# ---

const _PROPERTY_GROUPS := [
    _MOVEMENT_ABILITIES_GROUP,
    _PHYSICS_MOVEMENT_GROUP,
    _DASH_GROUP,
    _DOUBLE_JUMP_GROUP,
    _EDGE_WEIGHTS_GROUP,
    _PLATFORM_GRAPH_CALCULATIONS_GROUP,
    _LOGS_GROUP,
    _MOVEMENT_ABILITY_OVERRIDES_GROUP,
]

const MOVEMENT_PARAMS_NODE_IDENTIFIER := "__movement_params_identifier__"

# This property is saved to the scene file and is used to identify that the
# node is a MovementParameter instance.
var __movement_params_identifier__ := "_"

var _property_list_addendum := [
    {
        name = "collider_shape",
        type = TYPE_OBJECT,
        usage = PROPERTY_USAGE_STORAGE | PROPERTY_USAGE_SCRIPT_VARIABLE,
    },
    {
        name = "collider_rotation",
        type = TYPE_REAL,
        usage = PROPERTY_USAGE_STORAGE | PROPERTY_USAGE_SCRIPT_VARIABLE,
    },
    {
        name = "character_name",
        type = TYPE_STRING,
        usage = PROPERTY_USAGE_STORAGE | PROPERTY_USAGE_SCRIPT_VARIABLE,
    },
    {
        name = MOVEMENT_PARAMS_NODE_IDENTIFIER,
        type = TYPE_STRING,
        usage = PROPERTY_USAGE_STORAGE | PROPERTY_USAGE_SCRIPT_VARIABLE,
    },
]

var _configuration_warning := ""
var _is_ready := false
var _is_instanced_from_bootstrap := false \
        setget _set_is_instanced_from_bootstrap
var _debounced_update_parameters: FuncRef

# ---


func _init() -> void:
    var property_list_addendum: Array = \
            Sc.utils.get_property_list_for_contiguous_inspector_groups(
                    self, _PROPERTY_GROUPS)
    Sc.utils.concat(_property_list_addendum, property_list_addendum)


func _enter_tree() -> void:
    call_deferred("_parse_shape_from_parent")


func _ready() -> void:
    _set_up()


func _set_up() -> void:
    _is_ready = true
    _debounced_update_parameters = Sc.time.debounce(
            funcref(self, "_update_parameters_debounced"),
            0.02,
            true)


func _parse_shape_from_parent() -> void:
    var parent := get_parent()
    
    if !is_instance_valid(parent):
        return
    
    if !parent.is_in_group(Sc.characters.GROUP_NAME_SURFACER_CHARACTERS):
        _set_configuration_warning("Must define a SurfacerCharacter parent.")
        return
    
    character_name = parent.character_name
    
    var collision_shapes: Array = Sc.utils.get_children_by_type(
            parent,
            CollisionShape2D)
    if !collision_shapes.empty():
        var shape: CollisionShape2D = collision_shapes[0]
        collider_shape = shape.shape
        collider_rotation = shape.rotation
    
    if !is_instance_valid(collider_shape):
        _set_configuration_warning("Must define a CollisionShape2D sibling.")
        return
    
    property_list_changed_notify()
    _set_configuration_warning("")


# NOTE: _get_property_list **appends** to the default list of properties.
#       It does not replace.
func _get_property_list() -> Array:
    return _property_list_addendum


func _update_parameters() -> void:
    if !_is_ready:
        return
    _debounced_update_parameters.call_func()


func _update_parameters_debounced() -> void:
    _parse_shape_from_parent()
    if _configuration_warning != "":
        return
    
    _validate_parameters()
    if _configuration_warning != "":
        return
    
    _derive_parameters()
    
    property_list_changed_notify()
    _set_configuration_warning("")


func _validate_parameters() -> void:
    if surface_speed_multiplier <= 0.0:
        _set_configuration_warning(
                "surface_speed_multiplier must be greater than 0.")
    if air_horizontal_speed_multiplier <= 0.0:
        _set_configuration_warning(
                "air_speed_multiplier must be greater than 0.")
    elif gravity_fast_fall < 0:
        _set_configuration_warning(
                "gravity_fast_fall must be non-negative.")
    elif slow_rise_gravity_multiplier < 0:
        _set_configuration_warning(
                "slow_rise_gravity_multiplier must be non-negative.")
    elif rise_double_jump_gravity_multiplier < 0:
        _set_configuration_warning(
                "rise_double_jump_gravity_multiplier must be non-negative.")
    elif jump_boost > 0:
        _set_configuration_warning("")
    elif in_air_horizontal_acceleration < 0:
        _set_configuration_warning(
                "in_air_horizontal_acceleration must be non-negative.")
    elif max_jump_chain < 0:
        _set_configuration_warning(
                "max_jump_chain must be non-negative.")
    elif wall_jump_horizontal_boost < 0:
        _set_configuration_warning(
                "wall_jump_horizontal_boost must be non-negative.")
    elif wall_jump_horizontal_boost > max_horizontal_speed_default:
        _set_configuration_warning(
                "wall_jump_horizontal_boost must not be greater than " +
                "max_horizontal_speed_default.")
    elif wall_fall_horizontal_boost < 0:
        _set_configuration_warning(
                "wall_fall_horizontal_boost must be non-negative.")
    elif wall_fall_horizontal_boost > max_horizontal_speed_default:
        _set_configuration_warning(
                "wall_fall_horizontal_boost must not be greater than " +
                "max_horizontal_speed_default.")
    elif ceiling_fall_velocity_boost < 0:
        _set_configuration_warning(
                "ceiling_fall_velocity_boost must be non-negative.")
    elif walk_acceleration < 0:
        _set_configuration_warning(
                "walk_acceleration must be non-negative.")
    elif climb_up_speed > 0:
        _set_configuration_warning(
                "climb_up_speed must be non-positive.")
    elif climb_down_speed < 0:
        _set_configuration_warning(
                "climb_down_speed must be non-negative.")
    elif ceiling_crawl_speed < 0:
        _set_configuration_warning(
                "ceiling_crawl_speed must be non-negative.")
    elif max_horizontal_speed_default < 0:
        _set_configuration_warning(
                "max_horizontal_speed_default must be non-negative.")
    elif max_vertical_speed < 0:
        _set_configuration_warning(
                "max_vertical_speed must be non-negative.")
    elif max_vertical_speed < abs(jump_boost):
        _set_configuration_warning(
                "jump_boost must not exceed max_vertical_speed.")
    elif fall_through_floor_velocity_boost < 0:
        _set_configuration_warning(
                "fall_through_floor_velocity_boost must be non-negative.")
    elif dash_speed_multiplier < 0:
        _set_configuration_warning(
                "dash_speed_multiplier must be non-negative.")
    elif dash_duration < \
            dash_fade_duration:
        _set_configuration_warning(
                "dash_duration must not be less than dash_fade_duration.")
    elif dash_fade_duration < 0:
        _set_configuration_warning(
                "dash_fade_duration must be non-negative.")
    elif dash_cooldown < 0:
        _set_configuration_warning(
                "dash_cooldown must be non-negative.")
    elif dash_vertical_boost > 0:
        _set_configuration_warning(
                "dash_vertical_boost must be non-positive.")
    elif Sc.audio_manifest.are_beats_tracked_by_default and \
            !also_optimizes_preselection_path and \
            (optimizes_edge_jump_positions_at_run_time or \
            optimizes_edge_land_positions_at_run_time):
        _set_configuration_warning(
                "If we're tracking beats, then the preselection " +
                "trajectories must match the resulting navigation " +
                "trajectories.")
    elif stops_after_finding_first_valid_edge_for_a_surface_pair and \
            calculates_all_valid_edges_for_a_surface_pair:
        _set_configuration_warning(
                "stops_after_finding_first_valid_edge_for_a_surface_pair " +
                "and calculates_all_valid_edges_for_a_surface_pair " +
                "cannot both be true.")
    elif forces_character_position_to_match_path_at_end and \
            prevents_path_ends_from_exceeding_surface_ends_with_offsets:
        _set_configuration_warning(
                "prevents_path_ends_from_exceeding_surface_ends_with_offsets " +
                "and forces_character_position_to_match_path_at_end " +
                "cannot both be true.")
    elif syncs_character_position_to_edge_trajectory and \
            !includes_continuous_trajectory_positions:
        _set_configuration_warning(
                "If syncs_character_position_to_edge_trajectory is true, " +
                "then includes_continuous_trajectory_positions must be true.")
    elif syncs_character_velocity_to_edge_trajectory and \
            !includes_continuous_trajectory_velocities:
        _set_configuration_warning(
                "If syncs_character_velocity_to_edge_trajectory is true, " +
                "then includes_continuous_trajectory_velocities must be true.")
    elif bypasses_runtime_physics and \
            !syncs_character_position_to_edge_trajectory:
        _set_configuration_warning(
                "If bypasses_runtime_physics is true, " +
                "then syncs_character_position_to_edge_trajectory must be " +
                "true.")


func _derive_parameters() -> void:
    gravity_fast_fall = \
            gravity_multiplier * \
            Su.movement.gravity_default
    slow_rise_gravity_multiplier = \
            gravity_slow_rise_multiplier_multiplier * \
            Su.movement.gravity_slow_rise_multiplier_default
    rise_double_jump_gravity_multiplier = \
            gravity_double_jump_slow_rise_multiplier_multiplier * \
            Su.movement.gravity_double_jump_slow_rise_multiplier_default
    walk_acceleration = \
            walk_acceleration_multiplier * \
            Su.movement.walk_acceleration_default * \
            surface_speed_multiplier
    in_air_horizontal_acceleration = \
            in_air_horizontal_acceleration_multiplier * \
            Su.movement.in_air_horizontal_acceleration_default * \
            air_horizontal_speed_multiplier
    climb_up_speed = \
            climb_up_speed_multiplier * \
            Su.movement.climb_up_speed_default * \
            surface_speed_multiplier
    climb_down_speed = \
            climb_down_speed_multiplier * \
            Su.movement.climb_down_speed_default * \
            surface_speed_multiplier
    ceiling_crawl_speed = \
            ceiling_crawl_speed_multiplier * \
            Su.movement.ceiling_crawl_speed_default * \
            surface_speed_multiplier
    friction_coeff_with_sideways_input = \
            friction_coefficient_multiplier * \
            Su.movement.friction_coeff_with_sideways_input_default
    friction_coeff_without_sideways_input = \
            friction_coefficient_multiplier * \
            Su.movement.friction_coeff_without_sideways_input_default
    jump_boost = \
            jump_boost_multiplier * \
            Su.movement.jump_boost_default
    wall_jump_horizontal_boost = \
            wall_jump_horizontal_boost_multiplier * \
            Su.movement.wall_jump_horizontal_boost_default * \
            air_horizontal_speed_multiplier
    wall_fall_horizontal_boost = \
            wall_fall_horizontal_boost_multiplier * \
            Su.movement.wall_fall_horizontal_boost_default * \
            air_horizontal_speed_multiplier
    
    max_horizontal_speed_default = \
            max_horizontal_speed_default_multiplier * \
            Su.movement.max_horizontal_speed_default_default
    max_vertical_speed = \
            max_vertical_speed_multiplier * \
            Su.movement.max_vertical_speed_default
    max_possible_speed = \
            max(max_horizontal_speed_default, max_vertical_speed)
    
    dash_speed_multiplier = \
            dash_speed_multiplier_multiplier * \
            Su.movement.dash_speed_multiplier_default
    dash_vertical_boost = \
            dash_vertical_boost_multiplier * \
            Su.movement.dash_vertical_boost_default
    dash_duration = \
            dash_duration_multiplier * \
            Su.movement.dash_duration_default
    dash_fade_duration = \
            dash_fade_duration_multiplier * \
            Su.movement.dash_fade_duration_default
    dash_cooldown = \
            dash_cooldown_multiplier * \
            Su.movement.dash_cooldown_default
    
    additional_edge_weight_offset = \
            additional_edge_weight_offset_override if \
            additional_edge_weight_offset_override != -1.0 else \
            Su.movement.additional_edge_weight_offset_default
    walking_edge_weight_multiplier = \
            walking_edge_weight_multiplier_override if \
            walking_edge_weight_multiplier_override != -1.0 else \
            Su.movement.walking_edge_weight_multiplier_default
    ceiling_crawling_edge_weight_multiplier = \
            ceiling_crawling_edge_weight_multiplier_override if \
            ceiling_crawling_edge_weight_multiplier_override != -1.0 else \
            Su.movement.ceiling_crawling_edge_weight_multiplier_default
    climbing_edge_weight_multiplier = \
            climbing_edge_weight_multiplier_override if \
            climbing_edge_weight_multiplier_override != -1.0 else \
            Su.movement.climbing_edge_weight_multiplier_default
    climb_to_adjacent_surface_edge_weight_multiplier = \
            climb_to_adjacent_surface_edge_weight_multiplier_override if \
            climb_to_adjacent_surface_edge_weight_multiplier_override \
                    != -1.0 else \
            Su.movement.climb_to_adjacent_surface_edge_weight_multiplier_default
    move_to_collinear_surface_edge_weight_multiplier = \
            move_to_collinear_surface_edge_weight_multiplier_override if \
            move_to_collinear_surface_edge_weight_multiplier_override \
                    != -1.0 else \
            Su.movement.move_to_collinear_surface_edge_weight_multiplier_default
    air_edge_weight_multiplier = \
            air_edge_weight_multiplier_override if \
            air_edge_weight_multiplier_override != -1.0 else \
            Su.movement.air_edge_weight_multiplier_default
    
    var action_handler_names := \
            action_handlers_override if \
            !action_handlers_override.empty() else \
            Su.movement.get_default_action_handler_names(self)
    action_handlers = Su.movement.get_action_handlers_from_names(
            action_handler_names)
    
    var edge_calculator_names := \
            edge_calculators_override if \
            !edge_calculators_override.empty() else \
            Su.movement.get_default_edge_calculator_names(self)
    edge_calculators = Su.movement.get_edge_calculators_from_names(
            edge_calculator_names)
    
    gravity_slow_rise = gravity_fast_fall * slow_rise_gravity_multiplier
    
    if is_instance_valid(collider_shape):
        collider.update(collider_shape, collider_rotation)
        
        var fall_from_floor_shape := RectangleShape2D.new()
        fall_from_floor_shape.extents = collider.half_width_height
        fall_from_floor_corner_calc_shape.update(fall_from_floor_shape, 0.0)
        
        rounding_corner_calc_shape.update(collider.shape, collider.rotation)
        
        if !collider.is_axially_aligned:
            _set_configuration_warning("Shape2D.rotation must be 0 or 90.")
            return
    
    Su.movement._calculate_dependent_movement_params(self)


func _set_configuration_warning(value: String) -> void:
    if !_is_ready:
        return
    _configuration_warning = value
    update_configuration_warning()
    if value != "" and \
            !Engine.editor_hint:
        Sc.logger.error(value)


func _get_configuration_warning() -> String:
    return _configuration_warning


func set_name(value: String) -> void:
    .set_name(value)
    _update_parameters()


func get_max_horizontal_jump_distance(surface_side: int) -> float:
    return wall_jump_max_horizontal_jump_distance if \
            surface_side == SurfaceSide.LEFT_WALL or \
            surface_side == SurfaceSide.RIGHT_WALL else \
            floor_jump_max_horizontal_jump_distance


func get_max_surface_speed() -> float:
    return max_horizontal_speed_default * surface_speed_multiplier


func get_max_air_horizontal_speed() -> float:
    return max_horizontal_speed_default * air_horizontal_speed_multiplier


func _set_is_instanced_from_bootstrap(value: bool) -> void:
    _is_instanced_from_bootstrap = value
    _set_up()


func _set_can_grab_walls(value: bool) -> void:
    can_grab_walls = value
    _update_parameters()


func _set_can_grab_ceilings(value: bool) -> void:
    can_grab_ceilings = value
    _update_parameters()


func _set_can_jump(value: bool) -> void:
    can_jump = value
    _update_parameters()


func _set_can_dash(value: bool) -> void:
    can_dash = value
    _update_parameters()


func _set_can_double_jump(value: bool) -> void:
    can_double_jump = value
    _update_parameters()


func _set_surface_speed_multiplier(value: float) -> void:
    surface_speed_multiplier = value
    _update_parameters()


func _set_air_horizontal_speed_multiplier(value: float) -> void:
    air_horizontal_speed_multiplier = value
    _update_parameters()


func _set_gravity_multiplier(value: float) -> void:
    gravity_multiplier = value
    _update_parameters()


func _set_gravity_slow_rise_multiplier_multiplier(value: float) -> void:
    gravity_slow_rise_multiplier_multiplier = value
    _update_parameters()


func _set_gravity_double_jump_slow_rise_multiplier_multiplier(
        value: float) -> void:
    gravity_double_jump_slow_rise_multiplier_multiplier = value
    _update_parameters()


func _set_walk_acceleration_multiplier(value: float) -> void:
    walk_acceleration_multiplier = value
    _update_parameters()


func _set_in_air_horizontal_acceleration_multiplier(value: float) -> void:
    in_air_horizontal_acceleration_multiplier = value
    _update_parameters()


func _set_climb_up_speed_multiplier(value: float) -> void:
    climb_up_speed_multiplier = value
    _update_parameters()


func _set_climb_down_speed_multiplier(value: float) -> void:
    climb_down_speed_multiplier = value
    _update_parameters()


func _set_ceiling_crawl_speed_multiplier(value: float) -> void:
    ceiling_crawl_speed_multiplier = value
    _update_parameters()


func _set_friction_coefficient_multiplier(value: float) -> void:
    friction_coefficient_multiplier = value
    _update_parameters()


func _set_jump_boost_multiplier(value: float) -> void:
    jump_boost_multiplier = value
    _update_parameters()


func _set_wall_jump_horizontal_boost_multiplier(value: float) -> void:
    wall_jump_horizontal_boost_multiplier = value
    _update_parameters()


func _set_wall_fall_horizontal_boost_multiplier(value: float) -> void:
    wall_fall_horizontal_boost_multiplier = value
    _update_parameters()


func _set_ceiling_fall_velocity_boost(value: float) -> void:
    ceiling_fall_velocity_boost = value
    _update_parameters()


func _set_max_horizontal_speed_default_multiplier(value: float) -> void:
    max_horizontal_speed_default_multiplier = value
    _update_parameters()


func _set_max_vertical_speed_multiplier(value: float) -> void:
    max_vertical_speed_multiplier = value
    _update_parameters()


func _set_dash_speed_multiplier_multiplier(value: float) -> void:
    dash_speed_multiplier_multiplier = value
    _update_parameters()


func _set_dash_vertical_boost_multiplier(value: float) -> void:
    dash_vertical_boost_multiplier = value
    _update_parameters()


func _set_dash_duration_multiplier(value: float) -> void:
    dash_duration_multiplier = value
    _update_parameters()


func _set_dash_fade_duration_multiplier(value: float) -> void:
    dash_fade_duration_multiplier = value
    _update_parameters()


func _set_dash_cooldown_multiplier(value: float) -> void:
    dash_cooldown_multiplier = value
    _update_parameters()


func _set_uses_duration_instead_of_distance_for_edge_weight(
        value: bool) -> void:
    uses_duration_instead_of_distance_for_edge_weight = value
    _update_parameters()


func _set_additional_edge_weight_offset_override(value: float) -> void:
    additional_edge_weight_offset_override = value
    _update_parameters()


func _set_walking_edge_weight_multiplier_override(value: float) -> void:
    walking_edge_weight_multiplier_override = value
    _update_parameters()


func _set_ceiling_crawling_edge_weight_multiplier_override(
        value: float) -> void:
    ceiling_crawling_edge_weight_multiplier_override = value
    _update_parameters()


func _set_climbing_edge_weight_multiplier_override(value: float) -> void:
    climbing_edge_weight_multiplier_override = value
    _update_parameters()


func _set_climb_to_adjacent_surface_edge_weight_multiplier_override(
        value: float) -> void:
    climb_to_adjacent_surface_edge_weight_multiplier_override = value
    _update_parameters()


func _set_move_to_collinear_surface_edge_weight_multiplier_override(
        value: float) -> void:
    move_to_collinear_surface_edge_weight_multiplier_override = value
    _update_parameters()


func _set_air_edge_weight_multiplier_override(value: float) -> void:
    air_edge_weight_multiplier_override = value
    _update_parameters()


func _set_max_jump_chain(value: int) -> void:
    max_jump_chain = value
    _update_parameters()


func _set_minimizes_velocity_change_when_jumping(value: bool) -> void:
    minimizes_velocity_change_when_jumping = value
    _update_parameters()


func _set_optimizes_edge_jump_positions_at_run_time(value: bool) -> void:
    optimizes_edge_jump_positions_at_run_time = value
    _update_parameters()


func _set_optimizes_edge_land_positions_at_run_time(value: bool) -> void:
    optimizes_edge_land_positions_at_run_time = value
    _update_parameters()


func _set_also_optimizes_preselection_path(value: bool) -> void:
    also_optimizes_preselection_path = value
    _update_parameters()


func _set_forces_character_position_to_match_edge_at_start(value: bool) -> void:
    forces_character_position_to_match_edge_at_start = value
    _update_parameters()


func _set_forces_character_velocity_to_match_edge_at_start(value: bool) -> void:
    forces_character_velocity_to_match_edge_at_start = value
    _update_parameters()


func _set_forces_character_position_to_match_path_at_end(value: bool) -> void:
    forces_character_position_to_match_path_at_end = value
    _update_parameters()


func _set_forces_character_velocity_to_zero_at_path_end(value: bool) -> void:
    forces_character_velocity_to_zero_at_path_end = value
    _update_parameters()


func _set_syncs_character_position_to_edge_trajectory(value: bool) -> void:
    syncs_character_position_to_edge_trajectory = value
    _update_parameters()


func _set_syncs_character_velocity_to_edge_trajectory(value: bool) -> void:
    syncs_character_velocity_to_edge_trajectory = value
    _update_parameters()


func _set_includes_continuous_trajectory_positions(value: bool) -> void:
    includes_continuous_trajectory_positions = value
    _update_parameters()


func _set_includes_continuous_trajectory_velocities(value: bool) -> void:
    includes_continuous_trajectory_velocities = value
    _update_parameters()


func _set_includes_discrete_trajectory_state(value: bool) -> void:
    includes_discrete_trajectory_state = value
    _update_parameters()


func _set_is_trajectory_state_stored_at_build_time(value: bool) -> void:
    is_trajectory_state_stored_at_build_time = value
    _update_parameters()


func _set_bypasses_runtime_physics(value: bool) -> void:
    bypasses_runtime_physics = value
    _update_parameters()


func _set_default_nav_interrupt_resolution_mode(value: int) -> void:
    default_nav_interrupt_resolution_mode = value
    _update_parameters()


func _set_min_intra_surface_distance_to_optimize_jump_for(value: float) -> void:
    min_intra_surface_distance_to_optimize_jump_for = value
    _update_parameters()


func _set_dist_sq_thres_for_considering_additional_jump_land_points(
        value: float) -> void:
    dist_sq_thres_for_considering_additional_jump_land_points = value
    _update_parameters()


func _set_stops_after_finding_first_valid_edge_for_a_surface_pair(
        value: bool) -> void:
    stops_after_finding_first_valid_edge_for_a_surface_pair = value
    _update_parameters()


func _set_calculates_all_valid_edges_for_a_surface_pair(value: bool) -> void:
    calculates_all_valid_edges_for_a_surface_pair = value
    _update_parameters()


func _set_always_includes_jump_land_positions_at_surface_ends(
        value: bool) -> void:
    always_includes_jump_land_positions_at_surface_ends = value
    _update_parameters()


func _set_includes_redundant_j_l_positions_with_zero_start_velocity(
        value: bool) -> void:
    includes_redundant_j_l_positions_with_zero_start_velocity = value
    _update_parameters()


func _set_normal_jump_instruction_duration_increase(value: float) -> void:
    normal_jump_instruction_duration_increase = value
    _update_parameters()


func _set_exceptional_jump_instruction_duration_increase(value: float) -> void:
    exceptional_jump_instruction_duration_increase = value
    _update_parameters()


func _set_recurses_when_colliding_during_horizontal_step_calculations(
        value: bool) -> void:
    recurses_when_colliding_during_horizontal_step_calculations = value
    _update_parameters()


func _set_backtracks_for_higher_jumps_during_hor_step_calculations(
        value: bool) -> void:
    backtracks_for_higher_jumps_during_hor_step_calculations = value
    _update_parameters()


func _set_collision_margin_for_edge_calculations(value: float) -> void:
    collision_margin_for_edge_calculations = value
    _update_parameters()


func _set_collision_margin_for_waypoint_positions(value: float) -> void:
    collision_margin_for_waypoint_positions = value
    _update_parameters()


func _set_skips_less_likely_jump_land_positions(value: bool) -> void:
    skips_less_likely_jump_land_positions = value
    _update_parameters()


func _set_prevents_path_ends_from_exceeding_surface_ends_with_offsets(
        value: bool) -> void:
    prevents_path_ends_from_exceeding_surface_ends_with_offsets = value
    _update_parameters()


func _set_reuses_previous_waypoints_when_backtracking_on_jump_height(
        value: bool) -> void:
    reuses_previous_waypoints_when_backtracking_on_jump_height = value
    _update_parameters()


func _set_asserts_no_preexisting_collisions_during_edge_calculations(
        value: bool) -> void:
    asserts_no_preexisting_collisions_during_edge_calculations = value
    _update_parameters()


func _set_checks_for_alt_intersection_points_for_oblique_collisions(
        value: bool) -> void:
    checks_for_alt_intersection_points_for_oblique_collisions = value
    _update_parameters()


func _set_oblique_collison_normal_aspect_ratio_threshold_threshold(
        value: float) -> void:
    oblique_collison_normal_aspect_ratio_threshold_threshold = value
    _update_parameters()


func _set_min_frame_count_when_colliding_early_with_expected_surface(
        value: int) -> void:
    min_frame_count_when_colliding_early_with_expected_surface = value
    _update_parameters()


func _set_reached_in_air_destination_distance_squared_threshold(
        value: float) -> void:
    reached_in_air_destination_distance_squared_threshold = value
    _update_parameters()


func _set_max_edges_to_remove_from_path_for_opt_to_in_air_dest(
        value: int) -> void:
    max_edges_to_remove_from_path_for_opt_to_in_air_dest = value
    _update_parameters()


func _set_max_distance_for_reachable_surface_tracking(value: float) -> void:
    max_distance_for_reachable_surface_tracking = value
    _update_parameters()


func _set_logs_inspector_events(value: bool) -> void:
    logs_inspector_events = value
    _update_parameters()


func _set_fall_through_floor_velocity_boost(value: float) -> void:
    fall_through_floor_velocity_boost = value
    _update_parameters()


func _set_collider_shape(value: Shape2D) -> void:
    collider_shape = value
    _update_parameters()


func _set_collider_rotation(value: float) -> void:
    collider_rotation = value
    _update_parameters()

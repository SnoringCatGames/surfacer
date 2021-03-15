extends MovementParams
class_name SquirrelParams

func _init() -> void:
    name = "squirrel"
    player_resource_path = "res://src/players/squirrel/squirrel_player.tscn"
    
    can_grab_walls = true
    can_grab_ceilings = false
    can_grab_floors = true
    
    var shape := CapsuleShape2D.new()
    shape.radius = 17.0
    shape.height = 9.0
    collider_shape = shape
    collider_rotation = PI / 2.0
    
    gravity_fast_fall = Geometry.GRAVITY
    slow_rise_gravity_multiplier = 0.38
    rise_double_jump_gravity_multiplier = 0.68
    
    jump_boost = -800.0
    in_air_horizontal_acceleration = 3200.0
    max_jump_chain = 2
    wall_jump_horizontal_boost = 400.0
    wall_fall_horizontal_boost = 20.0
    
    walk_acceleration = 450.0
    climb_up_speed = -450.0
    climb_down_speed = 450.0
    
    minimizes_velocity_change_when_jumping = false
    optimizes_edge_jump_positions_at_run_time = true
    optimizes_edge_land_positions_at_run_time = true
    forces_player_position_to_match_edge_at_start = true
    forces_player_velocity_to_match_edge_at_start = true
    forces_player_position_to_match_path_at_end = false
    forces_player_velocity_to_zero_at_path_end = false
    syncs_player_position_to_edge_trajectory = true
    syncs_player_velocity_to_edge_trajectory = true
    retries_navigation_when_interrupted = true
    distance_squared_threshold_for_considering_additional_jump_land_points = 32.0 * 32.0
    stops_after_finding_first_valid_edge_for_a_surface_pair = false
    calculates_all_valid_edges_for_a_surface_pair = false
    always_includes_jump_land_positions_at_surface_ends = false
    includes_redundant_jump_land_positions_with_zero_start_velocity = true
    normal_jump_instruction_duration_increase = 0.08
    exceptional_jump_instruction_duration_increase = 0.2
    recurses_when_colliding_during_horizontal_step_calculations = true
    backtracks_to_consider_higher_jumps_during_horizontal_step_calculations = true
    collision_margin_for_edge_calculations = 4.0
    collision_margin_for_waypoint_positions = 5.0
    skips_less_likely_jump_land_positions = false
    prevents_path_end_points_from_protruding_past_surface_ends_with_extra_offsets = true
    reuses_previous_waypoints_when_backtracking_on_jump_height = false
    asserts_no_preexisting_collisions_during_edge_calculations = false
    
    max_horizontal_speed_default = 400.0
    min_horizontal_speed = 5.0
    max_vertical_speed = 4000.0
    min_vertical_speed = 0.0
    
    fall_through_floor_velocity_boost = 100.0
    
    dash_speed_multiplier = 4.0
    dash_vertical_boost = -400.0
    dash_duration = 0.3
    dash_fade_duration = 0.1
    dash_cooldown = 1.0
    
    friction_coefficient = 0.01
    
    uses_duration_instead_of_distance_for_edge_weight = true
    additional_edge_weight_offset = 64.0
    walking_edge_weight_multiplier = 1.0
    climbing_edge_weight_multiplier = 1.0
    air_edge_weight_multiplier = 1.2
    
    action_handler_names = [
        AirDashAction.NAME,
        AirDefaultAction.NAME,
        AirJumpAction.NAME,
        AllDefaultAction.NAME,
        CapVelocityAction.NAME,
        FloorDashAction.NAME,
        FloorDefaultAction.NAME,
        FloorFallThroughAction.NAME,
        FloorJumpAction.NAME,
        FloorWalkAction.NAME,
        FloorFrictionAction.NAME,
        WallClimbAction.NAME,
        WallDashAction.NAME,
        WallDefaultAction.NAME,
        WallFallAction.NAME,
        WallJumpAction.NAME,
        WallWalkAction.NAME,
    ]
    
    edge_calculator_names = [
        ClimbOverWallToFloorCalculator.NAME,
        FallFromWallCalculator.NAME,
        FallFromFloorCalculator.NAME,
        JumpInterSurfaceCalculator.NAME,
        ClimbDownWallToFloorCalculator.NAME,
        WalkToAscendWallFromFloorCalculator.NAME,
    ]

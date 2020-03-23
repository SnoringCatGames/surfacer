extends MovementParams
class_name CatParams

func _init() -> void:
    # FIXME: Go back to using the old cat params and remove the floaty test-player params below.
    
    name = "cat"
    
    can_grab_walls = true
    can_grab_ceilings = false
    can_grab_floors = true
    
    var shape := CapsuleShape2D.new()
    shape.radius = 30.0
    shape.height = 54.0
    collider_shape = shape
    collider_rotation = PI / 2.0
    
    gravity_fast_fall = Geometry.GRAVITY
    slow_ascent_gravity_multiplier = 0.18
#    slow_ascent_gravity_multiplier = 0.38
    ascent_double_jump_gravity_multiplier = 0.08
#    ascent_double_jump_gravity_multiplier = 0.68
    
    jump_boost = -1000.0
    in_air_horizontal_acceleration = 1500.0
#    in_air_horizontal_acceleration = 3200.0
    max_jump_chain = 2
    wall_jump_horizontal_boost = 400.0
    
    walk_acceleration = 350.0
    climb_up_speed = -350.0
    climb_down_speed = 150.0
    
    minimizes_velocity_change_when_jumping = false
#    minimizes_velocity_change_when_jumping = true
    calculates_edges_with_velocity_start_x_max_speed = true
    calculates_edges_from_surface_ends_with_velocity_start_x_zero = false
    optimizes_edge_jump_offs_at_run_time = true
    forces_player_position_to_match_edge_at_start = true
#    forces_player_position_to_match_edge_at_start = false
    forces_player_velocity_to_match_edge_at_start = true
#    forces_player_velocity_to_match_edge_at_start = false
#    updates_player_velocity_to_match_edge_trajectory = true
    updates_player_velocity_to_match_edge_trajectory = false
    considers_closest_mid_point_for_jump_land_position = true
    considers_mid_point_matching_edge_movement_for_jump_land_position = true
    
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
    
    friction_multiplier = 0.01
    
    uses_duration_instead_of_distance_for_edge_weight = true
    additional_edge_weight_offset = 32.0
    walking_edge_weight_multiplier = 1.2
    climbing_edge_weight_multiplier = 1.5
    air_edge_weight_multiplier = 1.0
    
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
        WallClimbAction.NAME,
        WallDashAction.NAME,
        WallDefaultAction.NAME,
        WallFallAction.NAME,
        WallJumpAction.NAME,
        WallWalkAction.NAME,
    ]
    
    movement_calculator_names = [
        ClimbOverWallToFloorCalculator.NAME,
        FallFromWallCalculator.NAME,
        FallFromFloorCalculator.NAME,
        JumpFromSurfaceToSurfaceCalculator.NAME,
        ClimbDownWallToFloorCalculator.NAME,
        WalkToAscendWallFromFloorCalculator.NAME,
    ]

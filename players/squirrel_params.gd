extends MovementParams
class_name SquirrelParams

func _init() -> void:
    name = "squirrel"
    
    can_grab_walls = true
    can_grab_ceilings = false
    can_grab_floors = true
    
    var shape := CapsuleShape2D.new()
    shape.radius = 17.0
    shape.height = 9.0
    collider_shape = shape
    collider_rotation = 0.0
    
    gravity_fast_fall = Geometry.GRAVITY
    slow_rise_gravity_multiplier = 0.38
    rise_double_jump_gravity_multiplier = 0.68
    
    jump_boost = -1000.0
    in_air_horizontal_acceleration = 3200.0
    max_jump_chain = 1
    wall_jump_horizontal_boost = 400.0
    
    walk_acceleration = 350.0
    climb_up_speed = -350.0
    climb_down_speed = 150.0
    
    minimizes_velocity_change_when_jumping = true
    
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
    
    uses_duration_instead_of_distance_for_edge_weight = false
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
        FloorFrictionAction.NAME,
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
        JumpInterSurfaceCalculator.NAME,
        ClimbDownWallToFloorCalculator.NAME,
        WalkToAscendWallFromFloorCalculator.NAME,
    ]

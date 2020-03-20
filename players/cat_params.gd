extends PlayerParams
class_name CatParams

const CatPlayer := preload("res://players/cat_player.gd")

const PLAYER_RESOURCE_PATH := "res://players/cat_player.tscn"
const NAME := "cat"
const CAN_GRAB_WALLS := true
const CAN_GRAB_CEILINGS := false
const CAN_GRAB_FLOORS := true
const COLLIDER_ROTATION := PI / 2

func _init(global).(NAME, PLAYER_RESOURCE_PATH, global) -> void:
    pass

func _get_action_handlers() -> Array:
    return [
        global.PLAYER_ACTIONS[AirDashAction.NAME],
        global.PLAYER_ACTIONS[AirDefaultAction.NAME],
        global.PLAYER_ACTIONS[AirJumpAction.NAME],
        global.PLAYER_ACTIONS[AllDefaultAction.NAME],
        global.PLAYER_ACTIONS[CapVelocityAction.NAME],
        global.PLAYER_ACTIONS[FloorDashAction.NAME],
        global.PLAYER_ACTIONS[FloorDefaultAction.NAME],
        global.PLAYER_ACTIONS[FloorFallThroughAction.NAME],
        global.PLAYER_ACTIONS[FloorJumpAction.NAME],
        global.PLAYER_ACTIONS[FloorWalkAction.NAME],
        global.PLAYER_ACTIONS[MatchExpectedEdgeTrajectoryAction.NAME],
        global.PLAYER_ACTIONS[WallClimbAction.NAME],
        global.PLAYER_ACTIONS[WallDashAction.NAME],
        global.PLAYER_ACTIONS[WallDefaultAction.NAME],
        global.PLAYER_ACTIONS[WallFallAction.NAME],
        global.PLAYER_ACTIONS[WallJumpAction.NAME],
        global.PLAYER_ACTIONS[WallWalkAction.NAME],
    ]

func _get_movement_calculators() -> Array:
    return [
        global.EDGE_MOVEMENTS[ClimbOverWallToFloorCalculator.NAME],
        global.EDGE_MOVEMENTS[FallFromWallCalculator.NAME],
        global.EDGE_MOVEMENTS[FallFromFloorCalculator.NAME],
#        global.EDGE_MOVEMENTS[JumpFromSurfaceToSurfaceCalculator.NAME],
        global.EDGE_MOVEMENTS[ClimbDownWallToFloorCalculator.NAME],
        global.EDGE_MOVEMENTS[WalkToAscendWallFromFloorCalculator.NAME],
    ]

func _create_movement_params() -> MovementParams:
    var movement_params := MovementParams.new()
    
#    movement_params.can_grab_walls = CAN_GRAB_WALLS
#    movement_params.can_grab_ceilings = CAN_GRAB_CEILINGS
#    movement_params.can_grab_floors = CAN_GRAB_FLOORS
#
#    var shape = CapsuleShape2D.new()
#    shape.radius = 30.0
#    shape.height = 54.0
#    movement_params.collider_shape = shape
#    movement_params.collider_rotation = COLLIDER_ROTATION
#
#    movement_params.gravity_fast_fall = Geometry.GRAVITY
#    movement_params.slow_ascent_gravity_multiplier = 0.38
#    movement_params.ascent_double_jump_gravity_multiplier = 0.68
#
#    movement_params.jump_boost = -1000.0
#    movement_params.in_air_horizontal_acceleration = 3200.0
#    movement_params.max_jump_chain = 2
#    movement_params.wall_jump_horizontal_boost = 400.0
#
#    movement_params.walk_acceleration = 350.0
#    movement_params.climb_up_speed = -350.0
#    movement_params.climb_down_speed = 150.0
#    
#    movement_params.should_minimize_velocity_change_when_jumping = true
#
#    movement_params.max_horizontal_speed_default = 400.0
#    movement_params.min_horizontal_speed = 5.0
#    movement_params.max_vertical_speed = 4000.0
#    movement_params.min_vertical_speed = 0.0
#
#    movement_params.fall_through_floor_velocity_boost = 100.0
#
#    movement_params.dash_speed_multiplier = 4.0
#    movement_params.dash_vertical_boost = -400.0
#    movement_params.dash_duration = 0.3
#    movement_params.dash_fade_duration = 0.1
#    movement_params.dash_cooldown = 1.0
#
#    movement_params.friction_multiplier = 0.01
    
    # FIXME: Go back to using the cat params above and remove the test-player params below.
    
    movement_params.can_grab_walls = CAN_GRAB_WALLS
    movement_params.can_grab_ceilings = CAN_GRAB_CEILINGS
    movement_params.can_grab_floors = CAN_GRAB_FLOORS
    
    var shape = CapsuleShape2D.new()
    shape.radius = 30.0
    shape.height = 54.0
    movement_params.collider_shape = shape
    movement_params.collider_rotation = COLLIDER_ROTATION
    
    movement_params.gravity_fast_fall = Geometry.GRAVITY
    movement_params.slow_ascent_gravity_multiplier = 0.18
    movement_params.ascent_double_jump_gravity_multiplier = 0.08
    
    movement_params.jump_boost = -1000.0
    movement_params.in_air_horizontal_acceleration = 1500.0
    movement_params.max_jump_chain = 2
    movement_params.wall_jump_horizontal_boost = 400.0
    
    movement_params.walk_acceleration = 350.0
    movement_params.climb_up_speed = -350.0
    movement_params.climb_down_speed = 150.0
    
    movement_params.should_minimize_velocity_change_when_jumping = false
    movement_params.calculates_edges_with_velocity_start_x_max_speed = true
    movement_params.calculates_edges_from_surface_ends_with_velocity_start_x_zero = false
    movement_params.optimizes_edge_jump_offs_at_run_time = true
    movement_params.forces_player_position_to_match_edge_at_start = true
    movement_params.forces_player_velocity_to_match_edge_at_start = true
    movement_params.updates_player_velocity_to_match_edge_trajectory = true
    
    movement_params.max_horizontal_speed_default = 400.0
    movement_params.min_horizontal_speed = 5.0
    movement_params.max_vertical_speed = 4000.0
    movement_params.min_vertical_speed = 0.0
    
    movement_params.fall_through_floor_velocity_boost = 100.0
    
    movement_params.dash_speed_multiplier = 4.0
    movement_params.dash_vertical_boost = -400.0
    movement_params.dash_duration = 0.3
    movement_params.dash_fade_duration = 0.1
    movement_params.dash_cooldown = 1.0
    
    movement_params.friction_multiplier = 0.01
    
    movement_params.uses_duration_instead_of_distance_for_edge_weight = true
    movement_params.additional_edge_weight_offset = 32.0
    movement_params.walking_edge_weight_multiplier = 1.2
    movement_params.climbing_edge_weight_multiplier = 1.5
    movement_params.air_edge_weight_multiplier = 1.0
    
    return movement_params

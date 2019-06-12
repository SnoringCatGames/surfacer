extends PlayerParams
class_name CatParams

const JumpFromPlatformMovement = preload("res://framework/player_movement/jump_from_platform_movement.gd")
const FallFromAirMovement = preload("res://framework/player_movement/fall_from_air_movement.gd")
const CatPlayer = preload("res://players/cat_player.gd")

const NAME := "cat"
const TYPE := PlayerType.HUMAN
const CAN_GRAB_WALLS := true
const CAN_GRAB_CEILINGS := false
const CAN_GRAB_FLOORS := true
const COLLIDER_ROTATION := PI / 2

func _create_player_type_configuration(movement_params: MovementParams, \
        movement_types: Array) -> PlayerTypeConfiguration:
    var type_configuration = PlayerTypeConfiguration.new()
    type_configuration.name = NAME
    type_configuration.type = TYPE
    type_configuration.movement_params = movement_params
    type_configuration.movement_types = movement_types
    return type_configuration

# Array<PlayerMovement>
func _create_movement_types(movement_params: MovementParams) -> Array:
    return [
        JumpFromPlatformMovement.new(movement_params),
        FallFromAirMovement.new(movement_params),
    ]

func _create_movement_params() -> MovementParams:
    var movement_params := MovementParams.new()
    
    movement_params.can_grab_walls = CAN_GRAB_WALLS
    movement_params.can_grab_ceilings = CAN_GRAB_CEILINGS
    movement_params.can_grab_floors = CAN_GRAB_FLOORS
    
    var shape = CapsuleShape2D.new()
    shape.radius = 30.0
    shape.height = 54.0
    movement_params.collider_shape = shape
    movement_params.collider_rotation = COLLIDER_ROTATION
    
    movement_params.gravity = Geometry.GRAVITY
    movement_params.ascent_gravity_multiplier = 0.38
    movement_params.ascent_double_jump_gravity_multiplier = 0.68
    
    movement_params.jump_boost = -1000.0
    movement_params.in_air_horizontal_acceleration = 3200.0
    movement_params.max_jump_chain = 2
    movement_params.wall_jump_horizontal_multiplier = 0.5
    
    movement_params.walk_acceleration = 350.0
    movement_params.climb_up_speed = -350.0
    movement_params.climb_down_speed = 150.0
    
    movement_params.max_horizontal_speed_default = 400.0
    movement_params.current_max_horizontal_speed = movement_params.max_horizontal_speed_default
    movement_params.min_horizontal_speed = 5.0
    movement_params.max_vertical_speed = 4000.0
    movement_params.min_vertical_speed = 0.0
    
    movement_params.fall_through_floor_velocity_boost = 100.0
    
    movement_params.min_speed_to_maintain_vertical_collision = 15.0
    movement_params.min_speed_to_maintain_horizontal_collision = 60.0
    
    movement_params.dash_speed_multiplier = 4.0
    movement_params.dash_vertical_boost = -400.0
    movement_params.dash_duration = 0.3
    movement_params.dash_fade_duration = 0.1
    movement_params.dash_cooldown = 1.0
    
    return movement_params

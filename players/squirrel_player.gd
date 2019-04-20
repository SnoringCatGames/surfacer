extends ComputerPlayer
class_name SquirrelPlayer

const JumpFromPlatformMovement = preload("res://framework/player_movement/jump_from_platform_movement.gd")
const FallFromAirMovement = preload("res://framework/player_movement/fall_from_air_movement.gd")

func _get_initial_movement_params() -> MovementParams:
    var movement_params := MovementParams.new()
    
    movement_params.gravity = Geometry.GRAVITY
    movement_params.ascent_gravity_multiplier = 0.38
    movement_params.ascent_double_jump_gravity_multiplier = 0.68
    
    movement_params.jump_boost = -1000.0
    movement_params.in_air_horizontal_acceleration = 300.0
    movement_params.max_jump_chain = 1
    movement_params.wall_jump_horizontal_multiplier = 0.5
    
    movement_params.walk_acceleration = 350.0
    movement_params.climb_up_speed = -350.0
    movement_params.climb_down_speed = 150.0
    
    movement_params.max_horizontal_speed_default = 400.0
    movement_params.current_max_horizontal_speed = movement_params.max_horizontal_speed_default
    movement_params.min_horizontal_speed = 50.0
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

func _init().("squirrel") -> void:
    pass

func _get_movement_types() -> Array:
    return [
        JumpFromPlatformMovement.new(movement_params),
        FallFromAirMovement.new(movement_params),
    ]

# Updates physics and player states in response to the current actions.
func _process_actions() -> void:
    velocity.x = 0
    velocity.y += actions.delta * movement_params.gravity

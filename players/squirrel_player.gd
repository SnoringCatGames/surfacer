extends ComputerPlayer
class_name SquirrelPlayer

var movement_params := _get_movement_params()

static func _get_movement_params() -> MovementParams:
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

func _get_edge_movement_types() -> Array:
    return [
        JumpFromPlatformMovement.new(movement_params),
    ]

# Updates physics and player states in response to the current actions.
func _process_actions() -> void:
    # The move_and_slide system depends on some vertical gravity always pushing the player into
    # the floor. If we just zero this out, is_on_floor() will give false negatives.
    velocity.y = movement_params.min_speed_to_maintain_vertical_collision
    
    velocity.x = 0

    # We don't need to multiply velocity by delta because MoveAndSlide already takes delta time
    # into account.
    #warning-ignore:return_value_discarded
    move_and_slide(velocity, Geometry.UP, false, 4, Geometry.FLOOR_MAX_ANGLE)

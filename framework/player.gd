extends KinematicBody2D
class_name Player

const PlatformGraphNavigator = preload("res://framework/platform_graph/platform_graph_navigator.gd")
const SurfaceState = preload("res://framework/surface_state.gd")

var surface_state := SurfaceState.new()
var platform_graph_navigator: PlatformGraphNavigator

func _init() -> void:
    platform_graph_navigator = PlatformGraphNavigator.new()

# Gets actions for the current frame.
#
# This can be overridden separately for the human and computer players:
# - The computer player will use instruction sets.
# - The human player will use system IO.
func _get_actions(delta: float) -> Dictionary:
    Utils.error("abstract Player._get_actions is not implemented")
    return {}

# Updates physics and player states in response to the current actions.
func _process_actions(actions: Dictionary) -> void:
    Utils.error("abstract Player._process_actions is not implemented")

func _physics_process(delta: float) -> void:
    var actions := _get_actions(delta)
    _update_surface_state(actions)
    platform_graph_navigator.update(surface_state)
    _process_actions(actions)

# Updates some basic surface-related state for player's actions and environment of the current frame.
func _update_surface_state(actions: Dictionary) -> void:
    # Flip the horizontal direction of the animation according to which way the player is facing.
    if actions.pressed_right:
        surface_state.horizontal_facing_sign = 1
        surface_state.horizontal_movement_sign = 1
    elif actions.pressed_left:
        surface_state.horizontal_facing_sign = -1
        surface_state.horizontal_movement_sign = -1
    else:
        surface_state.horizontal_movement_sign = 0
    
    surface_state.is_touching_floor = is_on_floor()
    surface_state.is_touching_ceiling = is_on_ceiling()
    surface_state.is_touching_wall = is_on_wall()
    surface_state.which_wall = _get_which_wall_collided()
    surface_state.is_touching_left_wall = surface_state.which_wall == "left"
    surface_state.is_touching_right_wall = surface_state.which_wall == "right"
    
    # Calculate the sign of a colliding wall's direction.
    surface_state.toward_wall_sign = (0 if !surface_state.is_touching_wall else \
            (1 if surface_state.which_wall == "right" else -1))
    
    surface_state.is_facing_wall = \
        (surface_state.which_wall == "right" and surface_state.horizontal_facing_sign > 0) or \
        (surface_state.which_wall == "left" and surface_state.horizontal_facing_sign < 0)
    surface_state.is_pressing_into_wall = \
        (surface_state.which_wall == "right" and actions.pressed_right) or \
        (surface_state.which_wall == "left" and actions.pressed_left)
    surface_state.is_pressing_away_from_wall = \
        (surface_state.which_wall == "right" and actions.pressed_left) or \
        (surface_state.which_wall == "left" and actions.pressed_right)
    
    var facing_into_wall_and_pressing_up: bool = actions.pressed_up and \
            (surface_state.is_facing_wall or surface_state.is_pressing_into_wall)
    surface_state.is_triggering_wall_grab = \
            surface_state.is_pressing_into_wall or facing_into_wall_and_pressing_up
    
    surface_state.is_triggering_fall_through = actions.pressed_down and actions.just_pressed_jump
    
    # Whether we are grabbing a wall.
    surface_state.is_grabbing_wall = surface_state.is_touching_wall and \
            (surface_state.is_grabbing_wall or surface_state.is_triggering_wall_grab)
    
    # Whether we should fall through fall-through floors.
    if surface_state.is_grabbing_wall:
        surface_state.is_falling_through_floors = actions.pressed_down
    elif surface_state.is_touching_floor:
        surface_state.is_falling_through_floors = surface_state.is_triggering_fall_through
    else:
        surface_state.is_falling_through_floors = actions.pressed_down
    
    # Whether we should fall through fall-through floors.
    surface_state.is_grabbing_walk_through_walls = \
            surface_state.is_grabbing_wall or actions.pressed_up
    
    _update_surface_attachment()

func _update_surface_attachment() -> void:
    var next_is_grabbing_floor = false
    var next_is_grabbing_ceiling = false
    var next_is_grabbing_left_wall = false
    var next_is_grabbing_right_wall = false
    
    if surface_state.is_grabbing_wall:
        next_is_grabbing_left_wall = surface_state.is_touching_left_wall
        next_is_grabbing_right_wall = surface_state.is_touching_right_wall
    elif surface_state.is_grabbing_ceiling:
        next_is_grabbing_ceiling = true
    elif surface_state.is_touching_floor:
        next_is_grabbing_floor = true
    
    surface_state.just_grabbed_floor = \
            next_is_grabbing_floor and !surface_state.is_grabbing_floor
    surface_state.just_grabbed_ceiling = \
            next_is_grabbing_ceiling and !surface_state.is_grabbing_ceiling
    surface_state.just_grabbed_left_wall = \
            next_is_grabbing_left_wall and !surface_state.is_grabbing_left_wall
    surface_state.just_grabbed_right_wall = \
            next_is_grabbing_right_wall and !surface_state.is_grabbing_right_wall
    
    surface_state.is_grabbing_floor = next_is_grabbing_floor
    surface_state.is_grabbing_ceiling = next_is_grabbing_ceiling
    surface_state.is_grabbing_left_wall = next_is_grabbing_left_wall
    surface_state.is_grabbing_right_wall = next_is_grabbing_right_wall

# FIXME: Move these to Utils

func _get_which_wall_collided() -> String:
    if is_on_wall():
        for i in range(get_slide_count()):
            var collision := get_slide_collision(i)
            if collision.normal.x > 0:
                return "left"
            elif collision.normal.x < 0:
                return "right"
    return "none"

func _get_floor_collision() -> KinematicCollision2D:
    if is_on_floor():
        for i in range(get_slide_count()):
            var collision := get_slide_collision(i)
            if abs(collision.normal.angle_to(Utils.UP)) <= Utils.FLOOR_MAX_ANGLE:
                return collision
    return null

func _get_floor_friction_coefficient() -> float:
    var collision := _get_floor_collision()
    # Collision friction is a property of the TileMap node.
    if collision != null and collision.collider.collision_friction != null:
        return collision.collider.collision_friction
    return 0.0

extends KinematicBody2D
class_name Player

const PlatformGraphNavigator = preload("res://framework/platform_graph/platform_graph_navigator.gd")
const SurfaceState = preload("res://framework/surface_state.gd")

var player_name: String
var surface_state := SurfaceState.new()
var platform_graph_navigator: PlatformGraphNavigator
var velocity := Vector2()
var level

func _init(player_name: String) -> void:
    self.player_name = player_name

func _enter_tree() -> void:
    var global := $"/root/Global"
    level = global.current_level

func initialize_platform_graph_navigator(platform_graph: PlatformGraph) -> void:
    platform_graph_navigator = PlatformGraphNavigator.new(player_name, platform_graph)

# Gets actions for the current frame.
#
# This can be overridden separately for the human and computer players:
# - The computer player will use instruction sets.
# - The human player will use system IO.
#warning-ignore:unused_argument
func _get_actions(delta: float) -> Dictionary:
    Utils.error("abstract Player._get_actions is not implemented")
    return {}

# Updates physics and player states in response to the current actions.
#warning-ignore:unused_argument
func _process_actions(actions: Dictionary) -> void:
    Utils.error("abstract Player._process_actions is not implemented")

func _physics_process(delta: float) -> void:
    var actions := _get_actions(delta)
    _update_surface_state(actions)
    platform_graph_navigator.update(surface_state)
    _process_actions(actions)
    level.descendant_physics_process_completed(self)

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
    surface_state.which_wall = Utils.get_which_wall_collided(self)
    surface_state.is_touching_left_wall = surface_state.which_wall == "left"
    surface_state.is_touching_right_wall = surface_state.which_wall == "right"
    surface_state.is_touching_a_surface = \
            surface_state.is_touching_floor or \
            surface_state.is_touching_ceiling or \
            surface_state.is_touching_wall
    
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
    
    _update_which_side_is_grabbed()
    _update_which_surface_is_grabbed()

func _update_which_side_is_grabbed() -> void:
    var next_is_grabbing_floor := false
    var next_is_grabbing_ceiling := false
    var next_is_grabbing_left_wall := false
    var next_is_grabbing_right_wall := false
    
    if surface_state.is_grabbing_wall:
        next_is_grabbing_left_wall = surface_state.is_touching_left_wall
        next_is_grabbing_right_wall = surface_state.is_touching_right_wall
    elif surface_state.is_grabbing_ceiling:
        next_is_grabbing_ceiling = true
    elif surface_state.is_touching_floor:
        next_is_grabbing_floor = true
    
    var next_is_grabbing_a_surface := \
            next_is_grabbing_floor or next_is_grabbing_ceiling or \
            next_is_grabbing_left_wall or next_is_grabbing_right_wall
    
    surface_state.just_grabbed_floor = \
            next_is_grabbing_floor and !surface_state.is_grabbing_floor
    surface_state.just_grabbed_ceiling = \
            next_is_grabbing_ceiling and !surface_state.is_grabbing_ceiling
    surface_state.just_grabbed_left_wall = \
            next_is_grabbing_left_wall and !surface_state.is_grabbing_left_wall
    surface_state.just_grabbed_right_wall = \
            next_is_grabbing_right_wall and !surface_state.is_grabbing_right_wall
    surface_state.just_grabbed_a_surface = \
            surface_state.just_grabbed_floor or \
            surface_state.just_grabbed_ceiling or \
            surface_state.just_grabbed_left_wall or \
            surface_state.just_grabbed_right_wall
    
    surface_state.just_entered_air = \
            !next_is_grabbing_a_surface and surface_state.is_grabbing_a_surface
    surface_state.just_left_air = \
            next_is_grabbing_a_surface and !surface_state.is_grabbing_a_surface
    
    surface_state.is_grabbing_floor = next_is_grabbing_floor
    surface_state.is_grabbing_ceiling = next_is_grabbing_ceiling
    surface_state.is_grabbing_left_wall = next_is_grabbing_left_wall
    surface_state.is_grabbing_right_wall = next_is_grabbing_right_wall
    surface_state.is_grabbing_a_surface = next_is_grabbing_a_surface
    
    surface_state.grabbed_side = \
            "floor" if surface_state.is_grabbing_floor else \
            ("ceiling" if surface_state.is_grabbing_ceiling else \
            ("left_wall" if surface_state.is_grabbing_left_wall else \
            ("right_wall" if surface_state.is_grabbing_right_wall else \
            "none")))
    match surface_state.grabbed_side:
        "floor":
            surface_state.grabbed_surface_normal = Utils.UP
        "ceiling":
            surface_state.grabbed_surface_normal = Utils.DOWN
        "left_wall":
            surface_state.grabbed_surface_normal = Utils.RIGHT
        "right_wall":
            surface_state.grabbed_surface_normal = Utils.LEFT

func _update_which_surface_is_grabbed() -> void:
    var collision = _get_attached_surface_collision(self, surface_state)
    assert((collision != null) == surface_state.is_grabbing_a_surface)
    
    if surface_state.is_grabbing_a_surface:
        var next_grab_position = collision.position
        surface_state.just_changed_grab_position = \
                surface_state.just_left_air or \
                next_grab_position != surface_state.grab_position
        surface_state.grab_position = next_grab_position
        
        var next_grabbed_tile_map = collision.collider
        surface_state.just_changed_tile_map = \
                surface_state.just_left_air or \
                next_grabbed_tile_map != surface_state.grabbed_tile_map
        surface_state.grabbed_tile_map = next_grabbed_tile_map
        
        var next_grab_position_tile_map_coord = Utils._get_collision_tile_map_coord( \
                surface_state.grab_position, surface_state.grabbed_tile_map, \
                surface_state.is_touching_floor, surface_state.is_touching_ceiling, \
                surface_state.is_touching_left_wall, surface_state.is_touching_right_wall)
        surface_state.just_changed_tile_map_coord = \
                surface_state.just_left_air or \
                next_grab_position_tile_map_coord != surface_state.grab_position_tile_map_coord
        surface_state.grab_position_tile_map_coord = next_grab_position_tile_map_coord
        
        var next_grabbed_surface = \
                platform_graph_navigator.calculate_grabbed_surface(surface_state)
        surface_state.just_changed_surface = \
                surface_state.just_left_air or \
                next_grabbed_surface != surface_state.grabbed_surface
        surface_state.grabbed_surface = next_grabbed_surface
    
    elif surface_state.just_entered_air:
        surface_state.just_changed_grab_position = true
        surface_state.just_changed_tile_map = true
        surface_state.just_changed_tile_map_coord = true
        surface_state.just_changed_surface = true

const WALL_ANGLE_RANGE := PI / 2.0 - Utils.FLOOR_MAX_ANGLE

static func _get_attached_surface_collision( \
        body: KinematicBody2D, surface_state: SurfaceState) -> KinematicCollision2D:
    var closest_normal_diff: float = PI
    var closest_collision: KinematicCollision2D
    var current_normal_diff: float
    var current_collision: KinematicCollision2D
    for i in range(body.get_slide_count()):
        current_collision = body.get_slide_collision(i)
        
        if surface_state.is_grabbing_floor:
            current_normal_diff = abs(current_collision.normal.angle_to(Utils.UP))
        elif surface_state.is_grabbing_ceiling:
            current_normal_diff = abs(current_collision.normal.angle_to(Utils.DOWN))
        elif surface_state.is_grabbing_left_wall:
            current_normal_diff = abs(current_collision.normal.angle_to(Utils.RIGHT))
        elif surface_state.is_grabbing_right_wall:
            current_normal_diff = abs(current_collision.normal.angle_to(Utils.LEFT))
        else:
            continue
        
        if current_normal_diff < closest_normal_diff:
            closest_normal_diff = current_normal_diff
            closest_collision = current_collision
    
    return closest_collision

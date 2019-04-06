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

# TODO: doc
func _update_surface_state(actions: Dictionary) -> void:
    Utils.error("abstract Player._update_surface_state is not implemented")

# Updates physics and player states in response to the current actions.
func _process_actions(actions: Dictionary) -> void:
    Utils.error("abstract Player._process_actions is not implemented")

func _physics_process(delta: float) -> void:
    var actions := _get_actions(delta)
    _update_surface_state(actions)
    platform_graph_navigator.update(surface_state)
    _process_actions(actions)

# TODO: Move these to Utils

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

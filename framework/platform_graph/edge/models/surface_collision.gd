extends Reference
class_name SurfaceCollision

# The surface being collided with.
var surface: Surface

# The position of the point of collision.
var position := Vector2.INF

# The position of the center of the player.
var player_position := Vector2.INF

# This is false if some sort of unexpected/invalid state occured during
# collision calculation.
var is_valid_collision_state: bool

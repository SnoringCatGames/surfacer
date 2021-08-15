class_name SurfaceCollision
extends Reference


## The surface being collided with.
var surface: Surface

## The position of the point of collision.
var position := Vector2.INF

## The position of the center of the character.
var character_position := Vector2.INF

## The time at which the collision occured, relative to the start of the frame.
var time_from_start_of_frame := INF

## This is false if some sort of unexpected/invalid state occured during
## collision calculation.
var is_valid_collision_state: bool

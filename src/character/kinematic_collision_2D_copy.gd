class_name KinematicCollision2DCopy
extends Reference
## -   This is a simple copy of the built-in KinematicCollision2D class.
## -   The built-in KinematicCollision2D class doesn't allow mutation from
##     GDScript.
## -   Godot re-uses and mutates pre-existings instances of
##     KinematicCollision2D when calling move_and_slide.
## -   We need to be able to collect collision references across multiple calls
##     to move_and_slide.
## -   Therefore, we need to create our own copies of collision state.


var collider: Object
var collider_id: int
var collider_metadata
var collider_rid: RID
var collider_shape: Object
var collider_shape_index: int
var collider_velocity: Vector2
var local_shape: Object
var normal: Vector2
var position: Vector2
var remainder: Vector2
var travel: Vector2


func _init(original: KinematicCollision2D = null) -> void:
    if is_instance_valid(original):
        self.collider = original.collider
        self.collider_id = original.collider_id
        self.collider_metadata = original.collider_metadata
        self.collider_rid = original.collider_rid
        self.collider_shape = original.collider_shape
        self.collider_shape_index = original.collider_shape_index
        self.collider_velocity = original.collider_velocity
        self.local_shape = original.local_shape
        self.normal = original.normal
        self.position = original.position
        self.remainder = original.remainder
        self.travel = original.travel

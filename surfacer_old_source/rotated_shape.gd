class_name RotatedShape
extends Reference


var shape: Shape2D
# In radians.
var rotation := INF
var is_rotated_90_degrees := false
var is_axially_aligned: bool setget ,_get_is_axially_aligned
var half_width_height := Vector2.INF


func _init(
        shape: Shape2D = null,
        rotation := INF) -> void:
    update(shape, rotation)


func update(
        shape: Shape2D = null,
        rotation := INF) -> void:
    if shape != null:
        self.shape = shape
    if rotation != INF:
        self.rotation = rotation
    
    if self.shape == null or \
            self.rotation == INF:
        return
    
    self.is_rotated_90_degrees = \
            abs(fmod(self.rotation + TAU, PI) - PI / 2.0) < \
            Sc.geometry.FLOAT_EPSILON
    self.half_width_height = \
            Sc.geometry.calculate_half_width_height(
                    self.shape,
                    self.is_rotated_90_degrees) if \
            _get_is_axially_aligned() else \
            Vector2.INF


func reset() -> void:
    shape = null
    rotation = INF
    is_rotated_90_degrees = false
    is_axially_aligned = false
    half_width_height = Vector2.INF


func _get_is_axially_aligned() -> bool:
    return rotation != INF and \
            (is_rotated_90_degrees or \
            abs(rotation) < Sc.geometry.FLOAT_EPSILON)

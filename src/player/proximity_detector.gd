tool
class_name ProximityDetector, \
"res://addons/surfacer/assets/images/editor_icons/proximity_detector.png"
extends Node2D
## -   This helps your `SurfacerPlayer` detect when other areas or bodies enter
##     or exit the proximity of your player.[br]
## -   You can declare these as children in your SurfacerPlayer scenes.[br]
## -   You can configure the shape used to define the proximity range.[br]

## The shape to detect other bodies within.
export var shape: Shape2D setget _set_shape

## If a radius is given, then a corresponding CircleShape2D will be used for
## the `shape` value.
export var radius := -1.0 setget _set_radius

## The layers to check for collisions ("collision_mask").
export(int, LAYERS_2D_PHYSICS) var layer := 0 setget _set_layer

## Whether to detect when a body enters the proximity region.
export var is_detecting_enter := true setget _set_is_detecting_enter

## Whether to detect when a body exits the proximity region.
export var is_detecting_exit := false setget _set_is_detecting_exit

const DASH_LENGTH := 3.0
const DASH_GAP := 6.0
const STROKE_WIDTH := 1.2
const COLOR := Color("00adad")

var _is_ready := false
var _configuration_warning := ""


func _ready() -> void:
    _is_ready = true
    _update_configuration()


func _draw() -> void:
    if !Engine.editor_hint:
        return
    
    if !is_instance_valid(shape):
        return
    
    var is_axially_aligned: bool = \
            abs(fmod(rotation + PI * 2, PI) - PI / 2) < \
                    Sc.geometry.FLOAT_EPSILON or \
            abs(rotation) < Sc.geometry.FLOAT_EPSILON
    if !is_axially_aligned:
        return
    
    Sc.draw.draw_dashed_shape(
            self,
            position,
            shape,
            rotation,
            COLOR,
            DASH_LENGTH,
            DASH_GAP,
            0.0,
            STROKE_WIDTH)


func _update_configuration() -> void:
    if !_is_ready:
        return
    
    var is_axially_aligned: bool = \
            abs(fmod(rotation + PI * 2, PI) - PI / 2) < \
                    Sc.geometry.FLOAT_EPSILON or \
            abs(rotation) < Sc.geometry.FLOAT_EPSILON
    
    if !is_instance_valid(shape):
        _configuration_warning = "Must define a shape or a radius."
    elif layer == 0:
        _configuration_warning = "Must configure at least one layer."
    elif !is_detecting_enter and !is_detecting_exit:
        _configuration_warning = "Must detect on enter, exit, or both."
    elif !is_axially_aligned:
        _configuration_warning = \
                "Rotation must be axially-aligned (0, 90, 180, etc)."
    else:
        _configuration_warning = ""
    
    update_configuration_warning()
    property_list_changed_notify()


func _get_configuration_warning() -> String:
    return _configuration_warning


func _set_shape(value: Shape2D) -> void:
    shape = value
    if shape is CircleShape2D:
        radius = shape.radius
    else:
        radius = -1.0
    _update_configuration()
    update()


func _set_radius(value: float) -> void:
    radius = value
    if radius > 0:
        shape = CircleShape2D.new()
        shape.radius = radius
    else:
        shape = null
    _update_configuration()
    update()


func _set_layer(value: int) -> void:
    layer = value
    _update_configuration()


func _set_is_detecting_enter(value: bool) -> void:
    is_detecting_enter = value
    _update_configuration()


func _set_is_detecting_exit(value: bool) -> void:
    is_detecting_exit = value
    _update_configuration()


func set_rotation(value: float) -> void:
    .set_rotation(value)
    _update_configuration()


func get_layer_names() -> Array:
    return Sc.utils.get_physics_layer_names_from_bitmask(layer)


func get_config() -> Dictionary:
    return {
        layer_name = self.get_layer_names(),
        shape = self.shape,
        rotation = self.rotation,
    }

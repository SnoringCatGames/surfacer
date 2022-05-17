class_name ReadonlyMovementParametersProxy, \
"res://addons/surfacer/assets/images/editor_icons/movement_params.png"
extends MovementParameters


var _backing_params: MovementParameters

var additional_surface_speed_multiplier := 1.0 \
    setget _set_additional_surface_speed_multiplier


func set_backing_params(backing_params: MovementParameters) -> void:
    _backing_params = backing_params
    
    var movement_params_properties: Dictionary = \
        Sc.utils.get_direct_property_map(
            _backing_params, Node2D)
    for property_name in movement_params_properties:
        set(property_name, movement_params_properties[property_name])
    
    surface_speed_multiplier = \
        _backing_params.surface_speed_multiplier * \
        additional_surface_speed_multiplier


func _set_additional_surface_speed_multiplier(value: float) -> void:
    additional_surface_speed_multiplier = value
    if is_instance_valid(_backing_params):
        surface_speed_multiplier = \
            _backing_params.surface_speed_multiplier * \
            additional_surface_speed_multiplier

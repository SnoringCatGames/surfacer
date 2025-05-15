class_name ReadonlyMovementParametersProxy, \
"res://addons/surfacer/assets/images/editor_icons/movement_params.png"
extends MovementParameters


var _backer: MovementParameters

var additional_surface_speed_multiplier := 1.0 \
    setget _set_additional_surface_speed_multiplier


func set_backer(backer: MovementParameters) -> void:
    _backer = backer
    
    var movement_params_properties: Dictionary = \
        Sc.utils.get_direct_property_map(_backer, Node2D)
    for property_name in movement_params_properties:
        set(property_name, movement_params_properties[property_name])
    
    _set_surface_speed_multiplier(
        _backer.surface_speed_multiplier * \
            additional_surface_speed_multiplier)


func _set_additional_surface_speed_multiplier(value: float) -> void:
    additional_surface_speed_multiplier = value
    if is_instance_valid(_backer):
        _set_surface_speed_multiplier(
            _backer.surface_speed_multiplier * \
                additional_surface_speed_multiplier)

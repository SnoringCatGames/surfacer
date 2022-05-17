class_name ReadonlyPlatformGraphProxy
extends PlatformGraph


var _backer: PlatformGraph

var movement_params_override: MovementParameters \
    setget _set_movement_params_override


func set_backer(backer: PlatformGraph) -> void:
    _backer = backer
    
    var movement_params_properties: Dictionary = \
        Sc.utils.get_direct_property_map(_backer, Reference)
    for property_name in movement_params_properties:
        set(property_name, movement_params_properties[property_name])
    
    movement_params_override = \
        movement_params_override if \
        is_instance_valid(movement_params_override) else \
        _backer.movement_params
    
    movement_params = movement_params_override
    collision_params = CollisionCalcParams.new(
            debug_params,
            movement_params,
            surface_store,
            surfaces_set,
            collision_params.crash_test_dummy)
    
    backer.connect(
        "surface_exclusion_changed",
        self,
        "_on_backer_surface_exclusion_changed")


func update_surface_exclusion(
        surface_or_surfaces,
        is_excluded: bool) -> void:
    _backer.update_surface_exclusion(surface_or_surfaces, is_excluded)


func _set_movement_params_override(value: MovementParameters) -> void:
    movement_params_override = value
    movement_params = movement_params_override
    if is_instance_valid(collision_params):
        collision_params.movement_params = movement_params


func _on_backer_surface_exclusion_changed() -> void:
    emit_signal("surface_exclusion_changed")

class_name CeilingDefaultAction
extends CharacterActionHandler


const NAME := "CeilingDefaultAction"
const TYPE := SurfaceType.CEILING
const USES_RUNTIME_PHYSICS := true
const PRIORITY := 310


func _init().(
        NAME,
        TYPE,
        USES_RUNTIME_PHYSICS,
        PRIORITY) -> void:
    pass


func process(character) -> bool:
    character.jump_count = 0
    character.is_rising_from_jump = false
    character.velocity.x = 0.0
    character.velocity.y = 0.0
    
    # Force the character vertical position to bypass gravity and cling to the
    # ceiling surface.
    character.position.y = Sc.geometry.project_point_onto_surface_with_offset(
            character.position,
            character.surface_state.grabbed_surface,
            character.movement_params.collider_half_width_height).y
    
    return true

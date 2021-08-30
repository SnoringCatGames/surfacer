class_name WallDefaultAction
extends CharacterActionHandler


const NAME := "WallDefaultAction"
const TYPE := SurfaceType.WALL
const USES_RUNTIME_PHYSICS := true
const PRIORITY := 110


func _init().(
        NAME,
        TYPE,
        USES_RUNTIME_PHYSICS,
        PRIORITY) -> void:
    pass


func process(character) -> bool:
    character.jump_count = 0
    character.is_rising_from_jump = false
    character.velocity.y = 0.0
    
    # Force the character horizontal position to bypass gravity and cling to
    # the wall surface.
    character.position.x = Sc.geometry.project_point_onto_surface_with_offset(
            character.position,
            character.surface_state.grabbed_surface,
            character.movement_params.collider_half_width_height).x
    
    return true

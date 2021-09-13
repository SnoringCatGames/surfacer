class_name AllDefaultAction
extends CharacterActionHandler


const NAME := "AllDefaultAction"
const TYPE := SurfaceType.OTHER
const USES_RUNTIME_PHYSICS := true
const PRIORITY := 10


func _init().(
        NAME,
        TYPE,
        USES_RUNTIME_PHYSICS,
        PRIORITY) -> void:
    pass


func process(character) -> bool:
    character.just_triggered_jump = false
    
    # Cancel any horizontal velocity when bumping into a wall.
    if character.surface_state.is_touching_wall and \
            !character.surface_state.is_triggering_wall_release:
        # The move_and_slide system depends on maintained velocity always
        # pushing the character into a collision, otherwise it will eventually
        # stop the collision. If we just zero this out, move_and_slide will
        # produce false-negatives.
        # FIXME: ---------------- REMOVE?
        if Su.uses_surface_normal_to_maintain_collision:
            var wall_cling_velocity: Vector2 = \
                    CharacterActionHandler \
                            .MIN_SPEED_TO_MAINTAIN_HORIZONTAL_COLLISION * \
                    Sc.time.get_combined_scale() * \
                    -character.surface_state.grab_normal
            character.velocity.x = wall_cling_velocity.x
            character.velocity.y += wall_cling_velocity.y
        else:
            character.velocity.x = \
                    CharacterActionHandler \
                            .MIN_SPEED_TO_MAINTAIN_HORIZONTAL_COLLISION * \
                    character.surface_state.toward_wall_sign / \
                    Sc.time.get_combined_scale()
        
        return true
    else:
        return false

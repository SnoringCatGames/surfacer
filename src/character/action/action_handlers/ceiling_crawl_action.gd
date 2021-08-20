class_name CeilingCrawlAction
extends CharacterActionHandler


const NAME := "CeilingCrawlAction"
const TYPE := SurfaceType.CEILING
const USES_RUNTIME_PHYSICS := true
const PRIORITY := 340


func _init().(
        NAME,
        TYPE,
        USES_RUNTIME_PHYSICS,
        PRIORITY) -> void:
    pass


func process(character) -> bool:
    if !character.processed_action(CeilingJumpDownAction.NAME) and \
            !character.processed_action(CeilingFallAction.NAME):
        if character.actions.pressed_left:
            character.velocity.x = \
                    -character.movement_params.ceiling_crawl_speed
            return true
        elif character.actions.pressed_right:
            character.velocity.x = \
                    character.movement_params.ceiling_crawl_speed
            return true
    
    return false

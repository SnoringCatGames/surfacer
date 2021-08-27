class_name CeilingRoundingCornerAction
extends CharacterActionHandler


const NAME := "CeilingRoundingCornerAction"
const TYPE := SurfaceType.CEILING
const USES_RUNTIME_PHYSICS := true
const PRIORITY := 350


func _init().(
        NAME,
        TYPE,
        USES_RUNTIME_PHYSICS,
        PRIORITY) -> void:
    pass


func process(character) -> bool:
    if character.surface_state.is_rounding_corner and \
            !character.processed_action(CeilingJumpDownAction.NAME) and \
            !character.processed_action(CeilingFallAction.NAME):
        var corner_position: Vector2 = character.surface_state.grab_position
        var distance_past_corner: float = \
                corner_position.x - character.position.x if \
                character.surface_state.is_rounding_left_corner else \
                character.position.x - corner_position.x
        assert(distance_past_corner > 0)
        var character_offset_y: float = Sc.geometry \
                .calculate_displacement_y_for_horizontal_distance_past_edge(
                        distance_past_corner,
                        false,
                        character.movement_params \
                                .rounding_corner_calc_shape,
                        character.movement_params \
                                .rounding_corner_calc_shape_rotation)
        
        character.position.y = corner_position.y + character_offset_y
    
    return false

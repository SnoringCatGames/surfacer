class_name FloorRoundingCornerAction
extends CharacterActionHandler


const NAME := "FloorRoundingCornerAction"
const TYPE := SurfaceType.FLOOR
const USES_RUNTIME_PHYSICS := true
const PRIORITY := 270


func _init().(
        NAME,
        TYPE,
        USES_RUNTIME_PHYSICS,
        PRIORITY) -> void:
    pass


func process(character) -> bool:
    if character.surface_state.is_rounding_corner and \
            !character.processed_action(FloorFallThroughAction.NAME) and \
            !character.processed_action(FloorJumpAction.NAME) and \
            !character.processed_action(FloorDashAction.NAME):
        var corner_position: Vector2 = character.surface_state.grab_position
        var distance_past_corner: float = \
                corner_position.x - character.position.x if \
                character.surface_state.is_rounding_left_corner else \
                character.position.x - corner_position.x
        distance_past_corner = max(distance_past_corner, 0.0)
        var character_offset_y: float = Sc.geometry \
                .calculate_displacement_y_for_horizontal_distance_past_edge(
                        distance_past_corner,
                        true,
                        character.movement_params \
                                .rounding_corner_calc_shape,
                        character.movement_params \
                                .rounding_corner_calc_shape_rotation)
        
        character.position.y = corner_position.y + character_offset_y
        
        return true
    
    return false

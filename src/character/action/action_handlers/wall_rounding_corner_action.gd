class_name WallRoundingCornerAction
extends CharacterActionHandler


const NAME := "WallRoundingCornerAction"
const TYPE := SurfaceType.WALL
const USES_RUNTIME_PHYSICS := true
const PRIORITY := 160


func _init().(
        NAME,
        TYPE,
        USES_RUNTIME_PHYSICS,
        PRIORITY) -> void:
    pass


func process(character) -> bool:
    if character.surface_state.is_rounding_corner and \
            !character.processed_action(WallJumpAction.NAME) and \
            !character.processed_action(WallFallAction.NAME) and \
            !character.processed_action(WallDashAction.NAME):
        var corner_position: Vector2 = character.surface_state.grab_position
        var distance_past_corner: float = \
                corner_position.y - character.position.y if \
                character.surface_state \
                        .is_rounding_wall_corner_to_upper_floor else \
                character.position.y - corner_position.y
        var character_offset_x: float = Sc.geometry \
                .calculate_displacement_x_for_vertical_distance_past_edge(
                        distance_past_corner,
                        character.surface_state.grabbed_surface.side == \
                                SurfaceSide.LEFT_WALL,
                        character.movement_params \
                                .rounding_corner_calc_shape,
                        character.movement_params \
                                .rounding_corner_calc_shape_rotation)
        
        character.position.x = corner_position.x + character_offset_x
        
        return true
    
    return false

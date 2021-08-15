class_name SurfacerCharacterPositionAnnotator
extends ScaffolderCharacterPositionAnnotator


var GRAB_POSITION_COLOR := Sc.colors.opacify(
        Sc.colors.character_position, ScaffolderColors.ALPHA_XXFAINT)
const GRAB_POSITION_LINE_WIDTH := 5.0
const GRAB_POSITION_LINE_LENGTH := 10.0

var POSITION_ALONG_SURFACE_COLOR := Sc.colors.opacify(
        Sc.colors.character_position, ScaffolderColors.ALPHA_XXFAINT)
const POSITION_ALONG_SURFACE_TARGET_POINT_RADIUS := 4.0
const POSITION_ALONG_SURFACE_T_LENGTH_IN_SURFACE := 0.0
const POSITION_ALONG_SURFACE_T_LENGTH_OUT_OF_SURFACE := 20.0
const POSITION_ALONG_SURFACE_T_WIDTH := 4.0


func _init(character: SurfacerCharacter).(character) -> void:
    pass


func _draw() -> void:
    if character.surface_state.is_grabbing_a_surface:
        _draw_grab_position()
        _draw_position_along_surface()


func _draw_grab_position() -> void:
    var from: Vector2 = character.surface_state.grab_position
    var to: Vector2 = \
            from + \
            character.surface_state.grabbed_surface.normal * \
                    GRAB_POSITION_LINE_LENGTH
    draw_line(
            from,
            to,
            GRAB_POSITION_COLOR,
            GRAB_POSITION_LINE_WIDTH)


func _draw_position_along_surface() -> void:
    Sc.draw.draw_position_along_surface(
            self,
            character.surface_state.center_position_along_surface,
            POSITION_ALONG_SURFACE_COLOR,
            POSITION_ALONG_SURFACE_COLOR,
            POSITION_ALONG_SURFACE_TARGET_POINT_RADIUS,
            POSITION_ALONG_SURFACE_T_LENGTH_IN_SURFACE,
            POSITION_ALONG_SURFACE_T_LENGTH_OUT_OF_SURFACE,
            POSITION_ALONG_SURFACE_T_WIDTH,
            true,
            false,
            false)

tool
class_name SurfacerSpawnPosition, \
"res://addons/scaffolder/assets/images/editor_icons/spawn_position.png"
extends ScaffolderSpawnPosition


const ATTACHMENT_CONE_RADIUS := 8.0
const ATTACHMENT_CONE_LENGTH := 20.0
const ATTACHMENT_CONE_STROKE_WIDTH := 1.6
const ATTACHMENT_CONE_OPACITY := 0.4
const ATTACHMENT_CONE_FILL_COLOR := Color("ad00ad")
const ATTACHMENT_CONE_STROKE_COLOR := Color("ffffff")

var SURFACE_ATTACHMENT_PROPERTY_CONFIG := {
    name = "surface_attachment",
    type = TYPE_STRING,
    usage = Utils.PROPERTY_USAGE_EXPORTED_ITEM,
    hint = PROPERTY_HINT_ENUM,
    hint_string = "FLOOR,LEFT_WALL,RIGHT_WALL,CEILING,NONE",
}

## The type of surface side that this character should start out attached to.
var surface_attachment := "FLOOR" setget _set_surface_attachment

var surface_side := SurfaceSide.FLOOR

var _surfacer_property_list_addendum = [
    CHARACTER_NAME_PROPERTY_CONFIG,
    SURFACE_ATTACHMENT_PROPERTY_CONFIG,
    INCLUDE_EXCLUSIVELY_PROPERTY_CONFIG,
    EXCLUDE_PROPERTY_CONFIG,
]


func _get_property_list() -> Array:
    return _surfacer_property_list_addendum


func _draw() -> void:
    if !Engine.editor_hint:
        return
    
    if surface_side == SurfaceSide.NONE:
        return
    
    var fill_cone_end_point := \
            -SurfaceSide.get_normal(surface_side) * ATTACHMENT_CONE_LENGTH
    var stroke_cone_end_point := \
            -SurfaceSide.get_normal(surface_side) * \
            (ATTACHMENT_CONE_LENGTH + ATTACHMENT_CONE_STROKE_WIDTH * 2.4)
    
    self.self_modulate.a = ATTACHMENT_CONE_OPACITY
    Sc.draw.draw_ice_cream_cone(
            self,
            stroke_cone_end_point,
            Vector2.ZERO,
            ATTACHMENT_CONE_RADIUS + ATTACHMENT_CONE_STROKE_WIDTH,
            ATTACHMENT_CONE_STROKE_COLOR,
            true)
    Sc.draw.draw_ice_cream_cone(
            self,
            fill_cone_end_point,
            Vector2.ZERO,
            ATTACHMENT_CONE_RADIUS,
            ATTACHMENT_CONE_FILL_COLOR,
            true)
    
    # FIXME: LEFT OFF HERE: -------- Is this auto-called in the parent?
    ._draw()


func _update_editor_configuration() -> void:
    surface_side = SurfaceSide.get_type(surface_attachment)
    
    if !Engine.editor_hint:
        return
    
    var movement_params: MovementParameters = \
            Su.movement.character_movement_params[character_name] if \
            Su.movement.character_movement_params.has(character_name) else \
            null
    
    if surface_side != SurfaceSide.NONE and \
            movement_params == null:
        _set_configuration_warning(
                ("%s has no movement_params, " +
                "and cannot attach to surfaces.") % \
                character_name)
        return
    
    if surface_side == SurfaceSide.FLOOR and \
            !movement_params.can_grab_floors:
        _set_configuration_warning(
                "%s's movement_params.can_grab_floors is false." % \
                character_name)
        return
    
    if (surface_side == SurfaceSide.LEFT_WALL or \
            surface_side == SurfaceSide.RIGHT_WALL) and \
            !movement_params.can_grab_walls:
        _set_configuration_warning(
                "%s's movement_params.can_grab_walls is false." % \
                character_name)
        return
    
    if surface_side == SurfaceSide.CEILING and \
            !movement_params.can_grab_ceilings:
        _set_configuration_warning(
                "%s's movement_params.can_grab_ceilings is false." % \
                character_name)
        return
    
    ._update_editor_configuration()
    
    _set_configuration_warning("")


func _set_configuration_warning(value: String) -> void:
    _configuration_warning = value
    update_configuration_warning()
    property_list_changed_notify()
    update()


func _get_configuration_warning() -> String:
    return _configuration_warning


func _add_character() -> void:
    ._add_character()
    
    match surface_side:
        SurfaceSide.FLOOR:
            _character.animator.play("Rest")
        SurfaceSide.LEFT_WALL, \
        SurfaceSide.RIGHT_WALL:
            _character.animator.play("RestOnWall")
            if surface_side == SurfaceSide.LEFT_WALL:
                _character.animator.face_left()
            else:
                _character.animator.face_right()
        SurfaceSide.CEILING:
            _character.animator.play("RestOnCeiling")
        SurfaceSide.NONE:
            _character.animator.play("JumpFall")
        _:
            Sc.logger.error()


func _set_surface_attachment(value: String) -> void:
    surface_attachment = value
    _update_editor_configuration()

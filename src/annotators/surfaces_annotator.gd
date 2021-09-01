class_name SurfacesAnnotator
extends Node2D


var surface_parser: SurfaceParser
var color_params: ColorParams = Su.ann_defaults.SURFACE_COLOR_PARAMS
var alpha_with_inspector_closed := 0.9
var alpha_with_inspector_open := alpha_with_inspector_closed * 0.2

var was_inspector_open := false

# Dictionary<Surface, Color>
var _surface_to_color := {}

# Dictionary<Surface, ScaffolderCharacter>
var _exclusion_surface_to_character := {}
# Dictionary<ScaffolderCharacter, Surface>
var _exclusion_character_to_surface := {}


func _init(surface_parser: SurfaceParser) -> void:
    self.surface_parser = surface_parser
    
    for surface in surface_parser.all_surfaces:
        _surface_to_color[surface] = color_params.get_color()


func _process(_delta: float) -> void:
    var is_inspector_open: bool = Sc.gui.hud.get_is_inspector_panel_open()
    if is_inspector_open != was_inspector_open:
        was_inspector_open = is_inspector_open
        update()


func _draw() -> void:
    for surface in surface_parser.all_surfaces:
        if _exclusion_surface_to_character.has(surface):
            continue
        _draw_surface(surface)


func _draw_surface(surface: Surface) -> void:
    var color: Color = _surface_to_color[surface]
    color.a = \
            alpha_with_inspector_open if \
            was_inspector_open else \
            alpha_with_inspector_closed
    Sc.draw.draw_surface(
            self,
            surface,
            color)


func exclude(
        surface: Surface,
        character: ScaffolderCharacter) -> void:
    # Remove any stale surface-to-character mapping.
    var previous_surface: Surface = \
            _exclusion_character_to_surface[character] if \
            _exclusion_character_to_surface.has(character) else \
            null
    if previous_surface != surface and \
            _exclusion_surface_to_character.has(previous_surface) and \
            _exclusion_surface_to_character[previous_surface] == character:
        _exclusion_surface_to_character.erase(previous_surface)
    
    if is_instance_valid(surface):
        _exclusion_surface_to_character[surface] = character
    
    _exclusion_character_to_surface[character] = surface
    
    update()

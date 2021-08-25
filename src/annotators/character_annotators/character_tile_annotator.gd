class_name CharacterTileAnnotator
extends Node2D


var TILE_BORDER_COLOR := Sc.colors.opacify(
        Sc.colors.character_position, ScaffolderColors.ALPHA_XXFAINT)
const TILE_BORDER_WIDTH := 6.0

var character: SurfacerCharacter
var polyline: PoolVector2Array


func _init(character: SurfacerCharacter) -> void:
    self.character = character
    polyline = PoolVector2Array()
    polyline.resize(5)


func _draw() -> void:
    if character.surface_state.is_grabbing_surface:
        _draw_tile_border()


func _draw_tile_border() -> void:
    var tile_map := character.surface_state.grabbed_tile_map
    var cell_size := tile_map.cell_size
    var coord := character.surface_state.grab_position_tile_map_coord
    var center := (coord + Vector2(0.5, 0.5)) * cell_size
    
    Sc.draw.draw_rectangle_outline(
            self,
            center,
            cell_size / 2.0,
            false,
            TILE_BORDER_COLOR,
            TILE_BORDER_WIDTH)


func check_for_update() -> void:
    if character.surface_state.just_changed_tile_map_coord:
        update()

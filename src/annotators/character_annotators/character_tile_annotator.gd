class_name CharacterTileAnnotator
extends Node2D


var character: SurfacerCharacter
var polyline: PoolVector2Array
var tile_border_color: Color


func _init(character: SurfacerCharacter) -> void:
    self.character = character
    polyline = PoolVector2Array()
    polyline.resize(5)
    self.tile_border_color = Color.from_hsv(
            character.position_annotation_color.sample().h,
            0.7,
            0.9,
            Sc.annotators.params.character_grab_tile_border_opacity)


func _draw() -> void:
    if character.surface_state.is_grabbing_surface:
        _draw_tile_border()


func _draw_tile_border() -> void:
    var tile_map := character.surface_state.grabbed_tilemap
    var cell_size := tile_map.cell_size
    var coord := character.surface_state.grab_position_tilemap_coord
    var center := (coord + Vector2(0.5, 0.5)) * cell_size
    
    Sc.draw.draw_rectangle_outline(
            self,
            center,
            cell_size / 2.0,
            false,
            tile_border_color,
            Sc.annotators.params.character_grab_tile_border_width)


func check_for_update() -> void:
    if character.surface_state.just_changed_tilemap_coord:
        update()

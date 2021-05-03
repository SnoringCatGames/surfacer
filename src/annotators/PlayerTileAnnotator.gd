class_name PlayerTileAnnotator
extends Node2D

var TILE_BORDER_COLOR := SurfacerColors.opacify(
        SurfacerColors.TEAL, SurfacerColors.ALPHA_XXFAINT)
const TILE_BORDER_WIDTH := 6.0

var player: Player
var polyline: PoolVector2Array

func _init(player: Player) -> void:
    self.player = player
    polyline = PoolVector2Array()
    polyline.resize(5)

func _draw() -> void:
    if player.surface_state.is_grabbing_a_surface:
        _draw_tile_border()

func _draw_tile_border() -> void:
    var tile_map := player.surface_state.grabbed_tile_map
    var cell_size := tile_map.cell_size
    var coord := player.surface_state.grab_position_tile_map_coord
    var center := (coord + Vector2(0.5, 0.5)) * cell_size
    
    Gs.draw_utils.draw_rectangle_outline(
            self,
            center,
            cell_size / 2.0,
            false,
            TILE_BORDER_COLOR,
            TILE_BORDER_WIDTH)

func check_for_update() -> void:
    if player.surface_state.just_changed_tile_map_coord:
        update()

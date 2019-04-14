extends Node2D
class_name TileAnnotator

var TILE_BORDER_COLOR := Color.from_hsv(0.28, 0.9, 0.6, 0.4)
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
    var tile_map = player.surface_state.grabbed_tile_map
    var cell_size = tile_map.cell_size
    var coord = player.surface_state.grab_position_tile_map_coord
    
    polyline[0] = Vector2(coord.x, coord.y) * cell_size
    polyline[1] = Vector2(coord.x + 1, coord.y) * cell_size
    polyline[2] = Vector2(coord.x + 1, coord.y + 1) * cell_size
    polyline[3] = Vector2(coord.x, coord.y + 1) * cell_size
    polyline[4] = polyline[0]
    
    draw_polyline(polyline, TILE_BORDER_COLOR, TILE_BORDER_WIDTH)

func check_for_update() -> void:
    if player.surface_state.just_changed_tile_map_coord:
        update()

extends Node2D
class_name PositionAnnotator

var PLAYER_POSITION_COLOR := Color.from_hsv(0.17, 0.7, 0.9, 0.3)
var GRAB_POSITION_COLOR := Color.from_hsv(0.17, 0.7, 0.9, 0.8)
const PLAYER_POSITION_RADIUS := 3.0
const GRAB_POSITION_LINE_WIDTH := 5.0
const GRAB_POSITION_LINE_LENGTH := 28.0

var player: Player

func _init(player: Player) -> void:
    self.player = player

func _draw() -> void:
    _draw_player_position()
    if player.surface_state.is_grabbing_a_surface:
        _draw_grab_position()

func _draw_player_position() -> void:
    draw_circle(player.position, PLAYER_POSITION_RADIUS, PLAYER_POSITION_COLOR)

func _draw_grab_position() -> void:
    var from := player.surface_state.grab_position
    var to := from - player.surface_state.grabbed_surface_normal * GRAB_POSITION_LINE_LENGTH
    draw_line(from, to, GRAB_POSITION_COLOR, GRAB_POSITION_LINE_WIDTH)

func check_for_update() -> void:
    update()

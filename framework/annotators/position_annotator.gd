extends Node2D
class_name PositionAnnotator

var PLAYER_POSITION_COLOR := Colors.opacify(Colors.TEAL, Colors.ALPHA_XFAINT)
var GRAB_POSITION_COLOR := Colors.opacify(Colors.TEAL_D, Colors.ALPHA_XFAINT)
const PLAYER_POSITION_RADIUS := 3.0
const GRAB_POSITION_LINE_WIDTH := 5.0
const GRAB_POSITION_LINE_LENGTH := 28.0

var POSITION_ALONG_SURFACE_COLOR = Colors.opacify(Colors.TEAL, Colors.ALPHA_XFAINT)
const POSITION_ALONG_SURFACE_TARGET_POINT_RADIUS := 4.0
const POSITION_ALONG_SURFACE_T_LENGTH := 16.0
const POSITION_ALONG_SURFACE_T_WIDTH := 4.0

var COLLIDER_COLOR := Colors.opacify(Colors.TEAL, Colors.ALPHA_XXFAINT)
const COLLIDER_THICKNESS := 4.0

var player: Player
var previous_position: Vector2

func _init(player: Player) -> void:
    self.player = player

func _draw() -> void:
    _draw_player_position()
    _draw_collider_outline()
    if player.surface_state.is_grabbing_a_surface:
        _draw_grab_position()
        _draw_position_along_surface()

func _draw_player_position() -> void:
    draw_circle(player.surface_state.center_position, PLAYER_POSITION_RADIUS, \
            PLAYER_POSITION_COLOR)

func _draw_grab_position() -> void:
    var from := player.surface_state.grab_position
    var to := from - player.surface_state.grabbed_surface_normal * GRAB_POSITION_LINE_LENGTH
    draw_line(from, to, GRAB_POSITION_COLOR, GRAB_POSITION_LINE_WIDTH)

func _draw_position_along_surface() -> void:
    DrawUtils.draw_position_along_surface(self, \
            player.surface_state.center_position_along_surface, \
            POSITION_ALONG_SURFACE_COLOR, POSITION_ALONG_SURFACE_COLOR, \
            POSITION_ALONG_SURFACE_TARGET_POINT_RADIUS, POSITION_ALONG_SURFACE_T_LENGTH, \
            POSITION_ALONG_SURFACE_T_WIDTH, true, false, false)

func _draw_collider_outline() -> void:
    DrawUtils.draw_shape_outline(self, player.position, player.movement_params.collider_shape, \
            player.movement_params.collider_rotation, COLLIDER_COLOR, COLLIDER_THICKNESS)

func check_for_update() -> void:
    if !Geometry.are_points_equal_with_epsilon(player.position, previous_position, 0.001):
        previous_position = player.position
        update()

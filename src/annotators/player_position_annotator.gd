class_name PlayerPositionAnnotator
extends Node2D


var PLAYER_POSITION_COLOR := Gs.colors.opacify(
        Gs.colors.player_position, ScaffolderColors.ALPHA_XXFAINT)
var GRAB_POSITION_COLOR := Gs.colors.opacify(
        Gs.colors.player_position, ScaffolderColors.ALPHA_XXFAINT)
const PLAYER_POSITION_RADIUS := 3.0
const GRAB_POSITION_LINE_WIDTH := 5.0
const GRAB_POSITION_LINE_LENGTH := 10.0

var POSITION_ALONG_SURFACE_COLOR := Gs.colors.opacify(
        Gs.colors.player_position, ScaffolderColors.ALPHA_XXFAINT)
const POSITION_ALONG_SURFACE_TARGET_POINT_RADIUS := 4.0
const POSITION_ALONG_SURFACE_T_LENGTH_IN_SURFACE := 0.0
const POSITION_ALONG_SURFACE_T_LENGTH_OUT_OF_SURFACE := 20.0
const POSITION_ALONG_SURFACE_T_WIDTH := 4.0

var COLLIDER_COLOR := Gs.colors.opacify(
        Gs.colors.player_position, ScaffolderColors.ALPHA_XFAINT)
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
    draw_circle(
            player.surface_state.center_position,
            PLAYER_POSITION_RADIUS,
            PLAYER_POSITION_COLOR)


func _draw_grab_position() -> void:
    var from := player.surface_state.grab_position
    var to := \
            from + \
            player.surface_state.grabbed_surface_normal * \
                    GRAB_POSITION_LINE_LENGTH
    draw_line(
            from,
            to,
            GRAB_POSITION_COLOR,
            GRAB_POSITION_LINE_WIDTH)


func _draw_position_along_surface() -> void:
    Gs.draw.draw_position_along_surface(
            self,
            player.surface_state.center_position_along_surface,
            POSITION_ALONG_SURFACE_COLOR,
            POSITION_ALONG_SURFACE_COLOR,
            POSITION_ALONG_SURFACE_TARGET_POINT_RADIUS,
            POSITION_ALONG_SURFACE_T_LENGTH_IN_SURFACE,
            POSITION_ALONG_SURFACE_T_LENGTH_OUT_OF_SURFACE,
            POSITION_ALONG_SURFACE_T_WIDTH,
            true,
            false,
            false)


func _draw_collider_outline() -> void:
    Gs.draw.draw_shape_outline(
            self,
            player.position,
            player.movement_params.collider_shape,
            player.movement_params.collider_rotation,
            COLLIDER_COLOR,
            COLLIDER_THICKNESS)


func check_for_update() -> void:
    if !Gs.geometry.are_points_equal_with_epsilon(
            player.position,
            previous_position,
            0.001):
        previous_position = player.position
        update()

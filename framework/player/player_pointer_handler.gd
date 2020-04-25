extends Node2D
class_name PlayerPointerHandler

var global # TODO: Add type back
var player

func _init(player) -> void:
    self.player = player

func _ready() -> void:
    self.global = $"/root/Global"

func _unhandled_input(event: InputEvent) -> void:
    if global.current_player_for_clicks != player:
        return
    
    # Mouse-up: Position selection.
    if event is InputEventMouseButton and \
            event.button_index == BUTTON_LEFT and \
            !event.pressed and \
            !event.control:
        player.new_selection_position = global.current_level.get_global_mouse_position()
    
    # Mouse-down: Position pre-selection.
    if event is InputEventMouseButton and \
            event.button_index == BUTTON_LEFT and \
            event.pressed and \
            !event.control:
        player.current_drag_position = global.current_level.get_global_mouse_position()
    
    # Mouse-move: Position pre-selection.
    if event is InputEventMouseMotion and \
            player.current_drag_position != Vector2.INF:
        player.current_drag_position = global.current_level.get_global_mouse_position()
    
    # Touch-up: Position selection.
    if event is InputEventScreenTouch and \
            !event.pressed:
        player.new_selection_position = Utils.get_global_touch_position( \
                event, \
                self)
    
    # Touch-down: Position pre-selection.
    if event is InputEventScreenTouch and \
            event.pressed:
        player.current_drag_position = Utils.get_global_touch_position( \
                event, \
                self)
    
    # Touch-move: Position pre-selection.
    if event is InputEventScreenDrag:
        player.current_drag_position = Utils.get_global_touch_position( \
                event, \
                self)

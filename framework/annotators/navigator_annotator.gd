extends Node2D
class_name NavigatorAnnotator

var CURRENT_PATH_COLOR = Colors.opacify(Colors.PURPLE, Colors.ALPHA_FAINT)
var PREVIOUS_PATH_COLOR = Colors.opacify(Colors.PURPLE, Colors.ALPHA_XFAINT)

var navigator: Navigator
var previous_path: PlatformGraphPath
var current_path: PlatformGraphPath

func _init(navigator: Navigator) -> void:
    self.navigator = navigator

func _draw() -> void:
    if previous_path != null:
        _draw_path(previous_path, PREVIOUS_PATH_COLOR)
    if current_path != null:
        _draw_path(current_path, CURRENT_PATH_COLOR)

func check_for_update() -> void:
    if navigator.current_path != current_path:
        current_path = navigator.current_path
        update()
    if navigator.previous_path != previous_path:
        previous_path = navigator.previous_path
        update()

func _draw_path(path: PlatformGraphPath, color: Color) -> void:
    for edge in path.edges:
        DrawUtils.draw_edge( \
                self, \
                edge, \
                true, \
                false, \
                false, \
                color)

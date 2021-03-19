extends Node2D
class_name CameraController

const ZOOM_STEP_RATIO := Vector2(0.05, 0.05)
const PAN_STEP := 8.0

const ZOOM_ANIMATION_DURATION_SEC := 0.3

var _current_camera: Camera2D

var offset: Vector2 setget _set_offset, _get_offset
var zoom: float setget _set_zoom, _get_zoom

var zoom_tween: Tween
var tween_zoom: float
var zoom_factor := 1.0

func _init() -> void:
    name = "CameraController"

func _enter_tree() -> void:
    zoom_tween = Tween.new()
    add_child(zoom_tween)

func _process(_delta_sec: float) -> void:
    if is_instance_valid(_current_camera):
        # Handle zooming.
        if Input.is_action_pressed("zoom_in"):
            _current_camera.zoom -= _current_camera.zoom * ZOOM_STEP_RATIO
        elif Input.is_action_pressed("zoom_out"):
            _current_camera.zoom += _current_camera.zoom * ZOOM_STEP_RATIO
    
        # Handle Panning.
        if Input.is_action_pressed("pan_up"):
            _current_camera.offset.y -= PAN_STEP
        elif Input.is_action_pressed("pan_down"):
            _current_camera.offset.y += PAN_STEP
        elif Input.is_action_pressed("pan_left"):
            _current_camera.offset.x -= PAN_STEP
        elif Input.is_action_pressed("pan_right"):
            _current_camera.offset.x += PAN_STEP

func _unhandled_input(event: InputEvent) -> void:
    # Mouse wheel events are never considered pressed by Godot--rather they are
    # only ever considered to have just happened.
    if event is InputEventMouseButton and \
            is_instance_valid(_current_camera):
        if event.button_index == BUTTON_WHEEL_UP:
            _current_camera.zoom -= _current_camera.zoom * ZOOM_STEP_RATIO
        if event.button_index == BUTTON_WHEEL_DOWN:
            _current_camera.zoom += _current_camera.zoom * ZOOM_STEP_RATIO

func set_current_camera(camera: Camera2D) -> void:
    camera.make_current()
    _current_camera = camera
    _set_zoom(zoom_factor)

func get_current_camera() -> Camera2D:
    return _current_camera

func _set_offset(offset: Vector2) -> void:
    if !is_instance_valid(_current_camera):
        return
    _current_camera.offset = offset

func _get_offset() -> Vector2:
    if !is_instance_valid(_current_camera):
        return Vector2.ZERO
    return _current_camera.offset

func get_position() -> Vector2:
    if !is_instance_valid(_current_camera):
        return Vector2.ZERO
    return _current_camera.get_camera_screen_center()

func _set_zoom(zoom_factor: float) -> void:
    self.zoom_factor = zoom_factor
    if !is_instance_valid(_current_camera):
        return
    update_zoom()

func _get_zoom() -> float:
    if !is_instance_valid(_current_camera):
        return 1.0
    assert(_current_camera.zoom.x == _current_camera.zoom.y)
    return _current_camera.zoom.x

func animate_to_zoom(zoom: float) -> void:
    if _get_zoom() == zoom:
        return
    
    var start_zoom := \
            tween_zoom if \
            zoom_tween.is_active() else \
            _get_zoom()
    zoom_tween.stop(self)
    zoom_tween.interpolate_property( \
            self, \
            "zoom", \
            start_zoom, \
            zoom, \
            ZOOM_ANIMATION_DURATION_SEC, \
            Tween.TRANS_QUAD, \
            Tween.EASE_IN_OUT)
    zoom_tween.start()

func update_zoom() -> void:
    if !is_instance_valid(_current_camera):
        return
    var zoom: float = \
            zoom_factor * \
            ScaffoldConfig.default_camera_zoom / \
            ScaffoldConfig.gui_scale
    _current_camera.zoom = Vector2(zoom, zoom)

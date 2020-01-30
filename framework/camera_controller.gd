extends Node2D
class_name CameraController

const DEFAULT_CAMERA_ZOOM := 1.5

const ZOOM_STEP_RATIO := Vector2(0.1, 0.1)
const PAN_STEP := 8.0

var global
var _current_camera: Camera2D

var current_camera: Camera2D setget _set_current_camera, _get_current_camera
var offset: Vector2 setget _set_offset, _get_offset
var zoom: float setget _set_zoom, _get_zoom

func _ready() -> void:
    self.global = $"/root/Global"
    global.camera_controller = self

func _process(delta: float) -> void:
    if Input.is_key_pressed(KEY_CONTROL):
        # Handle zooming.
        if Input.is_action_pressed("zoom_in"):
            _current_camera.zoom -= _current_camera.zoom * ZOOM_STEP_RATIO
        elif Input.is_action_pressed("zoom_out"):
            _current_camera.zoom += _current_camera.zoom * ZOOM_STEP_RATIO
    
        # Handle Panning.
        if Input.is_action_pressed("move_up"):
            _current_camera.offset.y -= PAN_STEP
        elif Input.is_action_pressed("move_down"):
            _current_camera.offset.y += PAN_STEP
        elif Input.is_action_pressed("move_left"):
            _current_camera.offset.x -= PAN_STEP
        elif Input.is_action_pressed("move_right"):
            _current_camera.offset.x += PAN_STEP

func _set_current_camera(camera: Camera2D) -> void:
    assert(camera.current)
    _current_camera = camera

func _get_current_camera() -> Camera2D:
    return _current_camera

func _set_offset(offset: Vector2) -> void:
    _current_camera.offset = offset

func _get_offset() -> Vector2:
    return _current_camera.offset

func get_position() -> Vector2:
    return _current_camera.get_camera_screen_center()

func _set_zoom(zoom: float) -> void:
    _current_camera.zoom = Vector2(zoom, zoom)

func _get_zoom() -> float:
    assert(_current_camera.zoom.x == _current_camera.zoom.y)
    return _current_camera.zoom.x

extends Node2D
class_name CameraController

const DEFAULT_CAMERA_ZOOM := 1.5

const ZOOM_STEP_RATIO := Vector2(0.1, 0.1)
const PAN_STEP := 8.0

var global
var _current_camera: Camera2D

var offset: Vector2 setget _set_offset, _get_offset
var zoom: float setget _set_zoom, _get_zoom

func _ready() -> void:
    self.global = $"/root/Global"
    global.camera_controller = self

func _process(delta: float) -> void:
    if _current_camera != null:
        # Handle zooming.
        if Input.is_action_pressed("zoom_in"):
            print("ZOOM_IN")
            _current_camera.zoom -= _current_camera.zoom * ZOOM_STEP_RATIO
        elif Input.is_action_pressed("zoom_out"):
            print("ZOOM_OUT")
            _current_camera.zoom += _current_camera.zoom * ZOOM_STEP_RATIO
    
        # Handle Panning.
        if Input.is_action_pressed("pan_up"):
            print("PAN_UP")
            _current_camera.offset.y -= PAN_STEP
        elif Input.is_action_pressed("pan_down"):
            print("PAN_DOWN")
            _current_camera.offset.y += PAN_STEP
        elif Input.is_action_pressed("pan_left"):
            print("PAN_LEFT")
            _current_camera.offset.x -= PAN_STEP
        elif Input.is_action_pressed("pan_right"):
            print("PAN_RIGHT")
            _current_camera.offset.x += PAN_STEP

func _unhandled_input(event: InputEvent) -> void:
    # Mouse wheel events are never considered pressed by Godot--rather they are only ever
    # considered to have just happened.
    if event is InputEventMouseButton:
        if event.button_index == BUTTON_WHEEL_UP:
            print("ZOOM_IN")
            _current_camera.zoom -= _current_camera.zoom * ZOOM_STEP_RATIO
        if event.button_index == BUTTON_WHEEL_DOWN:
            print("ZOOM_OUT")
            _current_camera.zoom += _current_camera.zoom * ZOOM_STEP_RATIO

func set_current_camera(camera: Camera2D) -> void:
    camera.make_current()
    _current_camera = camera

func get_current_camera() -> Camera2D:
    return _current_camera

func _set_offset(offset: Vector2) -> void:
    assert(_current_camera != null)
    _current_camera.offset = offset

func _get_offset() -> Vector2:
    if _current_camera == null:
        return Vector2.ZERO
    return _current_camera.offset

func get_position() -> Vector2:
    if _current_camera == null:
        return Vector2.ZERO
    return _current_camera.get_camera_screen_center()

func _set_zoom(zoom: float) -> void:
    assert(_current_camera != null)
    _current_camera.zoom = Vector2(zoom, zoom)

func _get_zoom() -> float:
    if _current_camera == null:
        return 1.0
    assert(_current_camera.zoom.x == _current_camera.zoom.y)
    return _current_camera.zoom.x

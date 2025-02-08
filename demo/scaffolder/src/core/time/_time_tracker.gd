class_name _TimeTracker
extends Node
## Keeps track of elapsed time.


var time_scale: float = S.time._DEFAULT_TIME_SCALE

var start_clock_time: float

var elapsed_clock_time: float
var elapsed_physics_time: float
var elapsed_render_time: float

var elapsed_clock_scaled_time: float
var elapsed_physics_scaled_time: float
var elapsed_render_scaled_time: float

var physics_frame_count: int
var render_frame_count: int


func _ready() -> void:
    start_clock_time = Time.get_ticks_usec() / 1000000.0
    elapsed_clock_time = 0.0
    elapsed_physics_time = 0.0
    elapsed_render_time = 0.0
    elapsed_clock_scaled_time = 0.0
    elapsed_physics_scaled_time = 0.0
    elapsed_render_scaled_time = 0.0
    physics_frame_count = 0
    render_frame_count = 0


func _process(delta: float) -> void:
    render_frame_count += 1
    elapsed_render_time += delta
    elapsed_render_scaled_time += delta * time_scale


func _physics_process(delta: float) -> void:
    physics_frame_count += 1
    elapsed_physics_time += delta
    elapsed_physics_scaled_time += delta * time_scale
    _update_clock_time()


func _update_clock_time() -> void:
    var next_elapsed_clock_time := Time.get_ticks_usec() / 1000000.0 - start_clock_time
    var delta_clock_time := next_elapsed_clock_time - elapsed_clock_time
    elapsed_clock_time = next_elapsed_clock_time
    elapsed_clock_scaled_time += delta_clock_time * time_scale

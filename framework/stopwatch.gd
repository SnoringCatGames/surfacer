extends Reference
class_name Stopwatch

var _start_time := -1

func start() -> void:
    _start_time = OS.get_ticks_msec()

# Returns the elapsed time in milliseconds.
func stop() -> int:
    var stop_time = OS.get_ticks_msec()
    assert(_start_time >= 0)
    var elapsed_time = stop_time - _start_time
    _start_time = -1
    return elapsed_time

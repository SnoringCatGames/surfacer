extends Reference
class_name Stopwatch

# Dictionary<ProfilerMetric, int>
var _start_times := {}

func start(metric: int) -> void:
    var start_time := OS.get_ticks_usec()
    assert(!_start_times.has(metric) or _start_times[metric] == -1)
    _start_times[metric] = start_time

# Returns the elapsed time in milliseconds.
func stop(metric: int) -> float:
    var stop_time := OS.get_ticks_usec()
    var start_time: int = _start_times[metric]
    assert(start_time >= 0)
    var elapsed_time := stop_time - start_time
    _start_times[metric] = -1
    return elapsed_time / 1000.0

extends Reference
class_name Stopwatch

# Dictionary<ProfilerMetric|String, int>
var _start_times_msec := {}

func start(metric_key) -> void:
    var start_time := OS.get_ticks_usec()
    assert(!_start_times_msec.has(metric_key) or \
            _start_times_msec[metric_key] == -1)
    _start_times_msec[metric_key] = start_time

# Returns the elapsed time in milliseconds.
func stop(metric_key) -> float:
    var stop_time := OS.get_ticks_usec()
    var start_time: int = _start_times_msec[metric_key]
    assert(start_time >= 0)
    var elapsed_time := stop_time - start_time
    _start_times_msec[metric_key] = -1
    return elapsed_time / 1000.0

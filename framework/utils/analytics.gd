extends Node

var stopwatch := Stopwatch.new()

# Dictionary<AnalyticsMetric, int>
var _timings := {}

func set_timing( \
        metric: int, \
        timing: int) -> void:
    _timings[metric] = timing

func get_timing(metric: int) -> int:
    return _timings[metric]

func stop_and_record(metric: int) -> void:
    set_timing( \
            metric, \
            stopwatch.stop())

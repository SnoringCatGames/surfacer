# Measures and records timings for platform graph calculations.
extends Node

var _stopwatch := Stopwatch.new()

# Dictionary<ProfilerMetric, Array<float>>
var _timings := {}

func start(metric: int) -> void:
    if !Config.DEBUG_PARAMS.is_inspector_enabled:
        return
    _stopwatch.start(metric)

func stop(metric: int) -> float:
    if !Config.DEBUG_PARAMS.is_inspector_enabled:
        return -1.0
    var duration := _stopwatch.stop(metric)
    if !_timings.has(metric):
        _timings[metric] = []
    _timings[metric].push_back(duration)
    return duration

func get_timing(metric: int) -> float:
    assert(Config.DEBUG_PARAMS.is_inspector_enabled)
    var list: Array = _timings[metric]
    assert(list.size() == 1)
    return list[0]

func get_timing_list(metric: int) -> Array:
    assert(Config.DEBUG_PARAMS.is_inspector_enabled)
    return _timings[metric]

func get_mean(metric: int) -> float:
    assert(Config.DEBUG_PARAMS.is_inspector_enabled)
    return get_sum(metric) / get_timing_list(metric).size()

func get_min(metric: int) -> float:
    assert(Config.DEBUG_PARAMS.is_inspector_enabled)
    return get_timing_list(metric).min()

func get_max(metric: int) -> float:
    assert(Config.DEBUG_PARAMS.is_inspector_enabled)
    return get_timing_list(metric).max()

func get_sum(metric: int) -> float:
    assert(Config.DEBUG_PARAMS.is_inspector_enabled)
    var sum := 0.0
    for timing in get_timing_list(metric):
        sum += timing
    return sum

func get_count(metric: int) -> int:
    assert(Config.DEBUG_PARAMS.is_inspector_enabled)
    return get_timing_list(metric).size()

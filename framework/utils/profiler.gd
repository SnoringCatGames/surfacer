# Measures and records timings for platform graph calculations.
extends Node

var _stopwatch := Stopwatch.new()

# Dictionary<ProfilerMetric, Array<float>>
var _timings := {}

func start(metric: int) -> void:
    if !Config.DEBUG_PARAMS.is_inspector_enabled:
        return
    _stopwatch.start(metric)

func stop( \
        metric: int, \
        records := true, \
        additional_timings_storage = null) -> float:
    if !Config.DEBUG_PARAMS.is_inspector_enabled:
        return -1.0
    var duration := _stopwatch.stop(metric)
    if records:
        if !_timings.has(metric):
            _timings[metric] = []
        _timings[metric].push_back(duration)
    if additional_timings_storage != null:
        if !additional_timings_storage.has(metric):
            additional_timings_storage[metric] = []
        additional_timings_storage[metric].push_back(duration)
    return duration

func stop_with_optional_metadata( \
        metric: int, \
        records_profile_or_metadata_container = null) -> float:
    if records_profile_or_metadata_container != null:
        if records_profile_or_metadata_container is EdgeCalcResultMetadata:
            return stop( \
                    metric, \
                    records_profile_or_metadata_container.records_profile, \
                    records_profile_or_metadata_container.timings)
        else:
            return stop( \
                    metric, \
                    records_profile_or_metadata_container)
    else:
        return stop(metric)

func get_timing(metric: int) -> float:
    assert(Config.DEBUG_PARAMS.is_inspector_enabled)
    var list: Array = _timings[metric]
    assert(list.size() == 1)
    return list[0]

func get_timing_list(metric: int) -> Array:
    assert(Config.DEBUG_PARAMS.is_inspector_enabled)
    return _timings[metric] if \
            _timings.has(metric) else \
            []

func get_mean(metric: int) -> float:
    assert(Config.DEBUG_PARAMS.is_inspector_enabled)
    if get_count(metric) == 0:
        return INF
    else:
        return get_sum(metric) / get_timing_list(metric).size()

func get_min(metric: int) -> float:
    assert(Config.DEBUG_PARAMS.is_inspector_enabled)
    if get_count(metric) == 0:
        return INF
    else:
        return get_timing_list(metric).min()

func get_max(metric: int) -> float:
    assert(Config.DEBUG_PARAMS.is_inspector_enabled)
    if get_count(metric) == 0:
        return INF
    else:
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

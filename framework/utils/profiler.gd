# Measures and records timings for platform graph calculations.
extends Node

var _stopwatch := Stopwatch.new()

# Dictionary<ProfilerMetric, Array<float>>
var _timings := {}

# Dictionary<ProfilerMetric, int>
var _counts := {}

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

func increment_count( \
        metric: int, \
        metadata_container = null) -> int:
    if metadata_container != null and \
            metadata_container.records_profile:
        if !metadata_container.counts.has(metric):
            metadata_container.counts[metric] = 0
        metadata_container.counts[metric] += 1
    
    if !_counts.has(metric):
        _counts[metric] = 0
    _counts[metric] += 1
    
    return _counts[metric]

func get_timing( \
        metric: int, \
        metadata_container = null) -> float:
    assert(Config.DEBUG_PARAMS.is_inspector_enabled)
    var timings := _choose_timings(metadata_container)
    var list: Array = timings[metric]
    assert(list.size() == 1)
    return list[0]

func get_timing_list( \
        metric: int, \
        metadata_container = null) -> Array:
    assert(Config.DEBUG_PARAMS.is_inspector_enabled)
    var timings := _choose_timings(metadata_container)
    return timings[metric] if \
            timings.has(metric) else \
            []

func get_mean( \
        metric: int, \
        metadata_container = null) -> float:
    assert(Config.DEBUG_PARAMS.is_inspector_enabled)
    var count := get_count(metric, metadata_container)
    if count == 0:
        return INF
    else:
        return get_sum(metric, metadata_container) / count

func get_min( \
        metric: int, \
        metadata_container = null) -> float:
    assert(Config.DEBUG_PARAMS.is_inspector_enabled)
    if get_count(metric, metadata_container) == 0:
        return INF
    else:
        return get_timing_list(metric, metadata_container).min()

func get_max( \
        metric: int, \
        metadata_container = null) -> float:
    assert(Config.DEBUG_PARAMS.is_inspector_enabled)
    if get_count(metric, metadata_container) == 0:
        return INF
    else:
        return get_timing_list(metric, metadata_container).max()

func get_sum( \
        metric: int, \
        metadata_container = null) -> float:
    assert(Config.DEBUG_PARAMS.is_inspector_enabled)
    var sum := 0.0
    for timing in get_timing_list(metric, metadata_container):
        sum += timing
    return sum

func get_count( \
        metric: int, \
        metadata_container = null) -> int:
    assert(Config.DEBUG_PARAMS.is_inspector_enabled)
    var is_timing := _choose_timings(metadata_container).has(metric)
    var counts := _choose_counts(metadata_container)
    var is_count := counts.has(metric)
    assert(!is_timing or !is_count)
    return counts[metric] if \
            is_count else \
            get_timing_list(metric, metadata_container).size()

func is_timing( \
        metric: int, \
        metadata_container = null) -> bool:
    return _choose_timings(metadata_container).has(metric)

func _choose_timings(metadata_container) -> Dictionary:
    return metadata_container.timings if \
            metadata_container != null else \
            _timings

func _choose_counts(metadata_container) -> Dictionary:
    return metadata_container.counts if \
            metadata_container != null else \
            _counts

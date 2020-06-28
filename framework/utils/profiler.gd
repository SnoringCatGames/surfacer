# Measures and records timings for platform graph calculations.
extends Node

const DEFAULT_THREAD_ID := ""

# Dictionary<String, Stopwatch>
var _stopwatches := {}

# Dictionary<String, Dictionary<ProfilerMetric, Array<float>>>
var _timings := {}

# Dictionary<String, Dictionary<ProfilerMetric, int>>
var _counts := {}

func _init() -> void:
    init_thread(DEFAULT_THREAD_ID)

func init_thread(thread_id: String) -> void:
    _stopwatches[thread_id] = Stopwatch.new()
    _timings[thread_id] = {}
    _counts[thread_id] = {}

func start( \
        metric: int, \
        thread_id := DEFAULT_THREAD_ID) -> void:
    if !Config.DEBUG_PARAMS.is_inspector_enabled:
        return
    _stopwatches[thread_id].start(metric)

func stop( \
        metric: int, \
        thread_id := DEFAULT_THREAD_ID, \
        records := true, \
        additional_timings_storage = null) -> float:
    if !Config.DEBUG_PARAMS.is_inspector_enabled:
        return -1.0
    
    var duration: float = _stopwatches[thread_id].stop(metric)
    
    if records:
        var timings_for_thread: Dictionary = _timings[thread_id]
        if !timings_for_thread.has(metric):
            timings_for_thread[metric] = []
        timings_for_thread[metric].push_back(duration)
    
    if additional_timings_storage != null:
        if !additional_timings_storage.has(metric):
            additional_timings_storage[metric] = []
        additional_timings_storage[metric].push_back(duration)
    
    return duration

func stop_with_optional_metadata( \
        metric: int, \
        thread_id := DEFAULT_THREAD_ID, \
        records_profile_or_metadata_container = null) -> float:
    if records_profile_or_metadata_container != null:
        if records_profile_or_metadata_container is EdgeCalcResultMetadata:
            return stop( \
                    metric, \
                    thread_id, \
                    records_profile_or_metadata_container.records_profile, \
                    records_profile_or_metadata_container.timings)
        else:
            return stop( \
                    metric, \
                    thread_id, \
                    records_profile_or_metadata_container)
    else:
        return stop( \
                metric, \
                thread_id)

func increment_count( \
        metric: int, \
        thread_id := DEFAULT_THREAD_ID, \
        metadata_container = null) -> int:
    var counts_for_thread: Dictionary = _counts[thread_id]
    if !counts_for_thread.has(metric):
        counts_for_thread[metric] = 0
    counts_for_thread[metric] += 1
    
    if metadata_container != null and \
            metadata_container.records_profile:
        if !metadata_container.counts.has(metric):
            metadata_container.counts[metric] = 0
        metadata_container.counts[metric] += 1
    
    return counts_for_thread[metric]

func get_timing( \
        metric: int, \
        metadata_container = null) -> float:
    assert(Config.DEBUG_PARAMS.is_inspector_enabled)
    if metadata_container != null:
        var list: Array = metadata_container.timings[metric]
        assert(list.size() == 1)
        return list[0]
    else:
        for thread_id in _timings:
            var list: Array = _timings[thread_id][metric]
            assert(list.size() == 1)
            return list[0]

func get_timing_list( \
        metric: int, \
        metadata_container = null) -> Array:
    assert(Config.DEBUG_PARAMS.is_inspector_enabled)
    if metadata_container != null:
        var timings: Dictionary = metadata_container.timings
        return timings[metric] if \
                timings.has(metric) else \
                []
    else:
        var timings := []
        for thread_id in _timings:
            if _timings[thread_id].has(metric):
                Utils.concat( \
                        timings, \
                        _timings[thread_id][metric])
        return timings

func get_mean( \
        metric: int, \
        metadata_container = null) -> float:
    assert(Config.DEBUG_PARAMS.is_inspector_enabled)
    var count := get_count( \
            metric, \
            metadata_container)
    if count == 0:
        return INF
    else:
        return get_sum( \
                metric, \
                metadata_container) / count

func get_min( \
        metric: int, \
        metadata_container = null) -> float:
    assert(Config.DEBUG_PARAMS.is_inspector_enabled)
    if get_count( \
            metric, \
            metadata_container) == 0:
        return INF
    else:
        return get_timing_list( \
                metric, \
                metadata_container).min()

func get_max( \
        metric: int, \
        metadata_container = null) -> float:
    assert(Config.DEBUG_PARAMS.is_inspector_enabled)
    if get_count( \
            metric, \
            metadata_container) == 0:
        return INF
    else:
        return get_timing_list( \
                metric, \
                metadata_container).max()

func get_sum( \
        metric: int, \
        metadata_container = null) -> float:
    assert(Config.DEBUG_PARAMS.is_inspector_enabled)
    var sum := 0.0
    for timing in get_timing_list( \
            metric, \
            metadata_container):
        sum += timing
    return sum

func get_count( \
        metric: int, \
        metadata_container = null) -> int:
    assert(Config.DEBUG_PARAMS.is_inspector_enabled)
    
    var is_timing := is_timing( \
            metric, \
            metadata_container)
    var is_count := is_count( \
            metric, \
            metadata_container)
    assert(!is_timing or !is_count)
    
    if metadata_container != null:
        return metadata_container.counts[metric] if \
                is_count else \
                metadata_container.timings[metric].size()
    else:
        if is_count:
            var count := 0
            for thread_id in _counts:
                if _counts[thread_id].has(metric):
                    count += _counts[thread_id][metric]
            return 0
        else:
            return get_timing_list(metric).size()

func is_timing( \
        metric: int, \
        metadata_container = null) -> bool:
    if metadata_container != null:
        return metadata_container.timings.has(metric)
    else:
        for thread_id in _timings:
            if _timings[thread_id].has(metric):
                return true
        return false

func is_count( \
        metric: int, \
        metadata_container = null) -> bool:
    if metadata_container != null:
        return metadata_container.counts.has(metric)
    else:
        for thread_id in _counts:
            if _counts[thread_id].has(metric):
                return true
        return false

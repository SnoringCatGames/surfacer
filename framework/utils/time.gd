extends Node

const PHYSICS_TIME_STEP_SEC := 1 / 60.0

# TODO: Verify that all render-frame _process calls in the scene tree happen
#       without interleaving with any _physics_process calls from other nodes
#       in the scene tree.
var _elapsed_latest_play_time_sec: float
var _elapsed_physics_play_time_sec: float
var _elapsed_render_play_time_sec: float

# Dictionary<int, _Timeout>
var _timeouts := {}
var _last_timeout_id := -1
# Dictionary<FuncRef, _Throttler>
var _throttled_callbacks := {}

# Keeps track of the current total elapsed time of unpaused gameplay.
var elapsed_play_time_sec: float setget ,_get_elapsed_play_time_sec

func _ready() -> void:
    _elapsed_physics_play_time_sec = 0.0
    _elapsed_render_play_time_sec = 0.0
    _elapsed_latest_play_time_sec = 0.0

func _process(delta_sec: float) -> void:
    _elapsed_render_play_time_sec += delta_sec
    _elapsed_latest_play_time_sec = _elapsed_render_play_time_sec
    
    _handle_timeouts()

func _handle_timeouts() -> void:
    var expired_timeout_id := -1
    for id in _timeouts:
        if _elapsed_latest_play_time_sec >= _timeouts[id].time_sec:
            expired_timeout_id = id
            break
    
    if expired_timeout_id >= 0:
        _timeouts[expired_timeout_id].callback.call_func()
        _timeouts.erase(expired_timeout_id)
        
        # Only handle one timeout per event loop, so we don't lock things up.
        call_deferred("_handle_timeouts")

func _physics_process(delta_sec: float) -> void:
    assert(Geometry.are_floats_equal_with_epsilon( \
            delta_sec, \
            PHYSICS_TIME_STEP_SEC))
    _elapsed_physics_play_time_sec += delta_sec
    _elapsed_latest_play_time_sec = _elapsed_physics_play_time_sec

func _get_elapsed_play_time_sec() -> float:
    return _elapsed_latest_play_time_sec

func set_timeout( \
        callback: FuncRef, \
        delay_sec: float) -> int:
    var timeout := _Timeout.new( \
            callback, \
            _elapsed_latest_play_time_sec + delay_sec)
    _timeouts[timeout.id] = timeout
    return timeout.id

func clear_timeout(timeout_id: int) -> bool:
    return _timeouts.erase(timeout_id)

class _Timeout:
    var callback: FuncRef
    var time_sec: float
    var id: int
    
    func _init( \
            callback: FuncRef, \
            time_sec: float) -> void:
        self.callback = callback
        self.time_sec = time_sec
        
        Time._last_timeout_id += 1
        self.id = Time._last_timeout_id

func throttle( \
        callback: FuncRef, \
        interval_sec: float) -> FuncRef:
    var throttler := _Throttler.new( \
            callback, \
            interval_sec)
    var throttled_callback := funcref( \
            throttler, \
            "on_call")
    _throttled_callbacks[throttled_callback] = throttler
    return throttled_callback

func cancel_pending_throttle(throttled_callback: FuncRef) -> void:
    assert(_throttled_callbacks.has(throttled_callback))
    _throttled_callbacks[throttled_callback].cancel()

func erase_throttle(throttled_callback: FuncRef) -> bool:
    return _throttled_callbacks.erase(throttled_callback)

class _Throttler:
    var _callback: FuncRef
    var _interval_sec: float
    
    var _trigger_callback_callback := funcref(self, "_trigger_callback")
    var _last_timeout_id := -1
    
    var _last_call_time_sec := -1.0
    var _is_callback_scheduled := false
    
    func _init( \
            callback: FuncRef, \
            interval_sec: float) -> void:
        self._callback = callback
        self._interval_sec = interval_sec
    
    func on_call() -> void:
        if !_is_callback_scheduled:
            var current_call_time_sec: float = Time.elapsed_play_time_sec
            var next_call_time_sec := _last_call_time_sec + _interval_sec
            if current_call_time_sec > next_call_time_sec:
                _trigger_callback()
            else:
                _last_timeout_id = Time.set_timeout( \
                        _trigger_callback_callback, \
                        next_call_time_sec - current_call_time_sec)
                _is_callback_scheduled = true
    
    func cancel() -> void:
        Time.clear_timeout(_last_timeout_id)
        _is_callback_scheduled = false
    
    func _trigger_callback() -> void:
        _last_call_time_sec = Time.elapsed_play_time_sec
        _is_callback_scheduled = false
        _callback.call_func()

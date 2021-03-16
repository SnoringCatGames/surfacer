extends Node

const _ADDITIONAL_FRAMERATE_MULTIPLIER_FOR_DEBUGGING := 1.0

const PHYSICS_TIME_STEP_SEC := 1 / 60.0

var _play_time: _PlayTime

var physics_framerate_multiplier := 1.0 setget \
        _set_physics_framerate_multiplier,_get_physics_framerate_multiplier

# TODO: Verify that all render-frame _process calls in the scene tree happen
#       without interleaving with any _physics_process calls from other nodes
#       in the scene tree.
var _elapsed_latest_time_sec: float
var _elapsed_physics_time_sec: float
var _elapsed_render_time_sec: float

# Dictionary<int, _Timeout>
var _timeouts := {}
# Dictionary<int, _Interval>
var _intervals := {}
var _last_timeout_id := -1
# Dictionary<FuncRef, _Throttler>
var _throttled_callbacks := {}

# Keeps track of the current total elapsed time that the app has been running.
var elapsed_app_time_actual_sec: float \
        setget ,_get_elapsed_app_time_actual_sec
var elapsed_app_time_modified_sec: float \
        setget ,_get_elapsed_app_time_modified_sec
# Keeps track of the current total elapsed time of unpaused gameplay.
var elapsed_play_time_actual_sec: float \
        setget ,_get_elapsed_play_time_actual_sec
var elapsed_play_time_modified_sec: float \
        setget ,_get_elapsed_play_time_modified_sec

func _init() -> void:
    ScaffoldUtils.print("Time._init")
    
    pause_mode = Node.PAUSE_MODE_PROCESS

func _enter_tree() -> void:
    _play_time = _PlayTime.new()
    add_child(_play_time)

func _ready() -> void:
    _elapsed_physics_time_sec = 0.0
    _elapsed_render_time_sec = 0.0
    _elapsed_latest_time_sec = 0.0

func _process(delta_sec: float) -> void:
    _elapsed_render_time_sec += delta_sec
    _elapsed_latest_time_sec = _elapsed_render_time_sec
    
    _handle_timeouts()
    _handle_intervals()

func _handle_timeouts() -> void:
    var expired_timeout_id := -1
    for id in _timeouts:
        if _elapsed_latest_time_sec >= _timeouts[id].time_sec:
            expired_timeout_id = id
            break
    
    if expired_timeout_id >= 0:
        _timeouts[expired_timeout_id].trigger()
        _timeouts.erase(expired_timeout_id)

func _handle_intervals() -> void:
    var expired_interval_id := -1
    for id in _intervals:
        if _elapsed_latest_time_sec >= _intervals[id].next_trigger_time_sec:
            expired_interval_id = id
            break
    
    if expired_interval_id >= 0:
        _intervals[expired_interval_id].trigger()

func _physics_process(delta_sec: float) -> void:
    _elapsed_physics_time_sec += delta_sec
    _elapsed_latest_time_sec = _elapsed_physics_time_sec

func _set_physics_framerate_multiplier(value: float) -> void:
    physics_framerate_multiplier = value
    _play_time.physics_framerate_multiplier = \
            _get_physics_framerate_multiplier()

func _get_physics_framerate_multiplier() -> float:
    return physics_framerate_multiplier * \
            _ADDITIONAL_FRAMERATE_MULTIPLIER_FOR_DEBUGGING

func _get_elapsed_app_time_actual_sec() -> float:
    return _elapsed_latest_time_sec

func _get_elapsed_app_time_modified_sec() -> float:
    return _elapsed_latest_time_sec * _get_physics_framerate_multiplier()

func _get_elapsed_play_time_actual_sec() -> float:
    return _play_time.elapsed_time_actual_sec

func _get_elapsed_play_time_modified_sec() -> float:
    return _play_time.elapsed_time_modified_sec

func set_timeout( \
        callback: FuncRef, \
        delay_sec: float, \
        arguments := []) -> int:
    var timeout := _Timeout.new( \
            callback, \
            _elapsed_latest_time_sec + delay_sec, \
            arguments)
    _timeouts[timeout.id] = timeout
    return timeout.id

func clear_timeout(timeout_id: int) -> bool:
    return _timeouts.erase(timeout_id)

class _Timeout extends Reference:
    var callback: FuncRef
    var time_sec: float
    var arguments: Array
    var id: int
    
    func _init( \
            callback: FuncRef, \
            time_sec: float, \
            arguments: Array) -> void:
        self.callback = callback
        self.time_sec = time_sec
        self.arguments = arguments
        
        Time._last_timeout_id += 1
        self.id = Time._last_timeout_id
    
    func trigger() -> void:
        if !callback.is_valid():
            return
        
        match arguments.size():
            0:
                callback.call_func()
            1:
                callback.call_func(arguments[0])
            2:
                callback.call_func(arguments[0], arguments[1])
            3:
                callback.call_func(arguments[0], arguments[1], arguments[2])
            4:
                callback.call_func(arguments[0], arguments[1], arguments[2], \
                        arguments[3])
            5:
                callback.call_func(arguments[0], arguments[1], arguments[2], \
                        arguments[3], arguments[4])
            _:
                ScaffoldUtils.error()

func set_interval( \
        callback: FuncRef, \
        interval_sec: float, \
        arguments := []) -> int:
    var interval := _Interval.new( \
            callback, \
            interval_sec, \
            arguments)
    _intervals[interval.id] = interval
    return interval.id

func clear_interval(interval_id: int) -> bool:
    return _intervals.erase(interval_id)

class _Interval extends Reference:
    var callback: FuncRef
    var interval_sec: float
    var arguments: Array
    var id: int
    var next_trigger_time_sec: float
    
    func _init( \
            callback: FuncRef, \
            interval_sec: float, \
            arguments: Array) -> void:
        self.callback = callback
        self.interval_sec = interval_sec
        self.arguments = arguments
        self.next_trigger_time_sec = \
                Time._elapsed_latest_time_sec + interval_sec
        
        Time._last_timeout_id += 1
        self.id = Time._last_timeout_id
    
    func trigger() -> void:
        if !callback.is_valid():
            return
        
        next_trigger_time_sec = \
                Time._elapsed_latest_time_sec + interval_sec
        match arguments.size():
            0:
                callback.call_func()
            1:
                callback.call_func(arguments[0])
            2:
                callback.call_func(arguments[0], arguments[1])
            3:
                callback.call_func(arguments[0], arguments[1], arguments[2])
            4:
                callback.call_func(arguments[0], arguments[1], arguments[2], \
                        arguments[3])
            5:
                callback.call_func(arguments[0], arguments[1], arguments[2], \
                        arguments[3], arguments[4])
            _:
                ScaffoldUtils.error()

func throttle( \
        callback: FuncRef, \
        interval_sec: float, \
        invokes_at_end := true) -> FuncRef:
    var throttler := _Throttler.new( \
            callback, \
            interval_sec, \
            invokes_at_end)
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

class _Throttler extends Reference:
    var _callback: FuncRef
    var _interval_sec: float
    var _invokes_at_end: bool
    
    var _trigger_callback_callback := funcref(self, "_trigger_callback")
    var _last_timeout_id := -1
    
    var _last_call_time_sec := -INF
    var _is_callback_scheduled := false
    
    func _init( \
            callback: FuncRef, \
            interval_sec: float, \
            invokes_at_end: bool) -> void:
        self._callback = callback
        self._interval_sec = interval_sec
        self._invokes_at_end = invokes_at_end
    
    func on_call() -> void:
        if !_is_callback_scheduled:
            var current_call_time_sec: float = \
                    Time.elapsed_app_time_actual_sec
            var next_call_time_sec := _last_call_time_sec + _interval_sec
            if current_call_time_sec > next_call_time_sec:
                _trigger_callback()
            elif _invokes_at_end:
                _last_timeout_id = Time.set_timeout( \
                        _trigger_callback_callback, \
                        next_call_time_sec - current_call_time_sec)
                _is_callback_scheduled = true
    
    func cancel() -> void:
        Time.clear_timeout(_last_timeout_id)
        _is_callback_scheduled = false
    
    func _trigger_callback() -> void:
        _last_call_time_sec = Time.elapsed_app_time_actual_sec
        _is_callback_scheduled = false
        if _callback.is_valid():
            _callback.call_func()

# Keeps track of the current total elapsed time of _unpaused_ gameplay.
class _PlayTime extends Node:
    var physics_framerate_multiplier := 1.0
    
    var _elapsed_latest_time_sec: float
    var _elapsed_physics_time_sec: float
    var _elapsed_render_time_sec: float
    
    var elapsed_time_actual_sec: float \
            setget ,_get_elapsed_time_actual_sec
    var elapsed_time_modified_sec: float \
            setget ,_get_elapsed_time_modified_sec
    
    func _init() -> void:
        pause_mode = Node.PAUSE_MODE_STOP
    
    func _ready() -> void:
        _elapsed_physics_time_sec = 0.0
        _elapsed_render_time_sec = 0.0
        _elapsed_latest_time_sec = 0.0
    
    func _process(delta_sec: float) -> void:
        _elapsed_render_time_sec += delta_sec
        _elapsed_latest_time_sec = _elapsed_render_time_sec
    
    func _physics_process(delta_sec: float) -> void:
        _elapsed_physics_time_sec += delta_sec
        _elapsed_latest_time_sec = _elapsed_physics_time_sec
    
    func _get_elapsed_time_actual_sec() -> float:
        return _elapsed_latest_time_sec
    
    func _get_elapsed_time_modified_sec() -> float:
        return _elapsed_latest_time_sec * physics_framerate_multiplier

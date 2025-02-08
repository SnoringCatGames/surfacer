class_name CircularBuffer
extends RefCounted


# FIXME: Move this to C++.


var _buffer := []
var _capacity: int
var _current_count := 0
var _previous_index := -1
var _frees_overwritten_items: bool


func _init(
        capacity: int,
        frees_overwritten_items := false) -> void:
    assert(capacity > 0)
    _capacity = capacity
    _frees_overwritten_items = frees_overwritten_items
    _buffer.resize(capacity)


func push(item: Variant) -> void:
    _previous_index = (_previous_index + 1) % _capacity
    if _frees_overwritten_items and \
            is_instance_valid(_buffer[_previous_index]):
        _buffer[_previous_index].free()
    _buffer[_previous_index] = item
    _current_count = min(_current_count + 1, _capacity)


func pop() -> Variant:
    var item = _buffer[_previous_index]
    _buffer[_previous_index] = null
    _previous_index = (_previous_index - 1 + _capacity) % _capacity
    _current_count = max(_current_count - 1, 0)
    return item


func peek() -> Variant:
    return _buffer[_previous_index]


func get_items() -> Array:
    var start_index := \
            (_previous_index + 1 - _current_count + _capacity) % _capacity
    var result := []
    result.resize(_current_count)
    for i in _current_count:
        var index: int = (i + start_index) % _capacity
        result[i] = _buffer[index]
    return result


func clear() -> void:
    _current_count = 0
    _previous_index = -1
    if _frees_overwritten_items:
        for i in _capacity:
            if is_instance_valid(_buffer[i]):
                _buffer[i].free()
    for i in _capacity:
        _buffer[i] = null


func size() -> int:
    return _current_count


func is_empty() -> bool:
    return _current_count == 0

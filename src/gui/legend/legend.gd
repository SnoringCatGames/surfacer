class_name Legend
extends VBoxContainer


# Dictionary<int, LegendItem>
var _items := {}

var grid: GridContainer
var label: ScaffolderLabel

var _debounced_on_gui_scale_changed: FuncRef = Sc.time.debounce(
        funcref(self, "_on_gui_scale_changed_debounced"),
        0.05)


func _ready() -> void:
    grid = $GridContainer
    label = $Label
    label.visible = true
    set_meta("gs_rect_size", rect_size)
    _on_gui_scale_changed()


func _destroy() -> void:
    Sc.time.clear_debounce(_debounced_on_gui_scale_changed)


func _on_gui_scale_changed() -> bool:
    _debounced_on_gui_scale_changed.call_deferred("call_func")
    return true


func _on_gui_scale_changed_debounced() -> void:
    var original_rect_size: Vector2 = get_meta("gs_rect_size")
    
    for item in _items.values():
        if is_instance_valid(item):
            item.update()


func add(item: LegendItem) -> void:
    assert(item != null)
    _items[item.type] = item
    grid.add_child(item)
    label.visible = false
    _on_gui_scale_changed()


func erase(item: LegendItem) -> bool:
    var erased := _items.erase(item.type)
    if erased:
        item.queue_free()
    if _items.empty():
        label.visible = true
    return erased


func has(item: LegendItem) -> bool:
    return _items.has(item.type)


func clear() -> void:
    for type in _items:
        if is_instance_valid(_items[type]):
            _items[type].queue_free()
    _items.clear()
    label.visible = true

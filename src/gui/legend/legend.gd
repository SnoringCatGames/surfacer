class_name Legend
extends VBoxContainer


# Dictionary<int, LegendItem>
var _items := {}

var grid: GridContainer
var label: Label

var _debounced_update_gui_scale: FuncRef = Gs.time.debounce(
        funcref(self, "_update_gui_scale_helper"),
        0.05)


func _ready() -> void:
    grid = $GridContainer
    label = $Label
    label.visible = true
    update_gui_scale()


func _exit_tree() -> void:
    Gs.time.clear_debounce(_debounced_update_gui_scale)


func update_gui_scale() -> bool:
    _debounced_update_gui_scale.call_deferred("call_func")
    return true


func _update_gui_scale_helper() -> void:
    if !has_meta("gs_rect_size"):
        set_meta("gs_rect_size", rect_size)
    var original_rect_size: Vector2 = get_meta("gs_rect_size")
    
    for item in _items.values():
        if is_instance_valid(item):
            item.update()


func add(item: LegendItem) -> void:
    assert(item != null)
    _items[item.type] = item
    grid.add_child(item)
    label.visible = false
    update_gui_scale()


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

class_name Legend
extends VBoxContainer

# Dictionary<int, LegendItem>
var _items := {}

var grid: GridContainer
var label: Label


func _ready() -> void:
    grid = $GridContainer
    label = $Label
    label.visible = true


func update_gui_scale(gui_scale: float) -> bool:
    update_gui_scale_helper(gui_scale)
    # TODO: Fix the underlying dependency, instead of this double-call hack.
    #       (To repro the problem: run, start level, maximize window.)
    update_gui_scale_helper(1.0)
    return true


func update_gui_scale_helper(gui_scale: float) -> void:
    var next_rect_size := rect_size * gui_scale
    rect_size = next_rect_size
    for item in _items.values():
        if is_instance_valid(item):
            item.update()
    for child in get_children():
        Gs.utils._scale_gui_recursively(child, gui_scale)
    rect_size = next_rect_size


func add(item: LegendItem) -> void:
    assert(item != null)
    _items[item.type] = item
    grid.add_child(item)
    label.visible = false


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

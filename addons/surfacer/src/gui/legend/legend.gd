extends VBoxContainer
class_name Legend

# Dictionary<int, LegendItem>
var _items := {}

var grid: GridContainer
var label: Label

func _ready() -> void:
    grid = $GridContainer
    label = $Label
    label.visible = true

func add(item: LegendItem) -> void:
    assert(item != null)
    _items[item.type] = item
    grid.add_child(item)
    label.visible = false

func erase(item: LegendItem) -> bool:
    var erased := _items.erase(item.type)
    if erased:
        grid.remove_child(item)
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

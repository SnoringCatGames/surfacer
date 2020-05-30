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
    _items[item.type] = item
    grid.add_child(item)
    label.visible = false

func erase(item: LegendItem) -> bool:
    var erased := _items.erase(item.type)
    if erased:
        grid.remove_child(item)
    if _items.empty():
        label.visible = true
    return erased

func has(item: LegendItem) -> bool:
    return _items.has(item.type)

func clear() -> void:
    for type in _items:
        grid.remove_child(_items[type])
    _items.clear()
    label.visible = true

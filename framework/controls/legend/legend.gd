extends GridContainer
class_name Legend

# Dictionary<int, LegendItem>
var _items := {}

func add(item: LegendItem) -> void:
    _items[item.type] = item
    add_child(item)

func erase(item: LegendItem) -> bool:
    var erased := _items.erase(item.type)
    if erased:
        remove_child(item)
    return erased

func has(item: LegendItem) -> bool:
    return _items.has(item.type)

func clear() -> void:
    for type in _items:
        remove_child(_items[type])
    _items.clear()

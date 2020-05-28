extends GridContainer
class_name Legend

# Dictionary<LegendItem, bool>
var _items := {}

# FIXME: REMOVE -------------
func _ready() -> void:
    add(SurfaceLegendItem.new())
    add(OriginSurfaceLegendItem.new())
    add(DestinationSurfaceLegendItem.new())
    add(HypotheticalEdgeTrajectoryLegendItem.new())
    add(ValidEdgeTrajectoryLegendItem.new())
    add(OriginLegendItem.new())
    add(DestinationLegendItem.new())
    add(InstructionStartLegendItem.new())
    add(InstructionEndLegendItem.new())

func add(item: LegendItem) -> void:
    _items[item] = true
    add_child(item)

func erase(item: LegendItem) -> bool:
    var erased := _items.erase(item)
    if erased:
        remove_child(item)
    return erased

func has(item: LegendItem) -> bool:
    return _items.has(item)

func clear() -> void:
    for item in _items:
        remove_child(item)
    _items.clear()

extends Reference
class_name AnnotationElement

var type := AnnotationElementType.UNKNOWN

# Array<LegendItem>
var _legend_items: Array

func _init(type: int) -> void:
    self.type = type

func get_legend_items() -> Array:
    if _legend_items.empty():
        _legend_items = _create_legend_items()
    return _legend_items

func _create_legend_items() -> Array:
    ScaffoldUtils.error( \
            "Abstract AnnotationElement._create_legend_items is not " + \
            "implemented")
    return []

func draw(canvas: CanvasItem) -> void:
    ScaffoldUtils.error("Abstract AnnotationElement.draw is not implemented")

func clear() -> void:
    # Do nothing unless the sub-class implements this.
    pass

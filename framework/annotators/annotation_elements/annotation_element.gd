extends Reference
class_name AnnotationElement

var type := AnnotationElementType.UNKNOWN

func _init(type: int) -> void:
    self.type = type

func draw(canvas: CanvasItem) -> void:
    Utils.error("Abstract AnnotationElement.draw is not implemented")

func get_legend_items() -> Array:
    Utils.error( \
            "Abstract AnnotationElement.get_legend_items is not implemented")
    return []

func clear() -> void:
    # Do nothing unless the sub-class implements this.
    pass

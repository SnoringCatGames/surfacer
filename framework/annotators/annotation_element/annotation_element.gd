extends Reference
class_name AnnotationElement

var type := AnnotationElementType.UNKNOWN

func _init(type: int) -> void:
    self.type = type

func draw(canvas: CanvasItem) -> void:
    Utils.error("Abstract AnnotationElement.draw is not implemented")

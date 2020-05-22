extends Node2D
class_name ElementAnnotator

# Dictionary<AnnotationElement, AnnotationElement>
var _elements_set := {}
var _old_hash: int = INF

func _process(delta: float) -> void:
    var new_hash := _elements_set.hash()
    if _old_hash != new_hash:
        _old_hash = new_hash
        update()

func add(element: AnnotationElement) -> void:
    _elements_set[element] = element

func clear() -> void:
    for element in _elements_set:
        element.clear()
    _elements_set.clear()

func erase(element: AnnotationElement) -> bool:
    element.clear()
    return _elements_set.erase(element)

func has(element: AnnotationElement) -> bool:
    return _elements_set.has(element)

func _draw() -> void:
    for element in _elements_set:
        element.draw(self)

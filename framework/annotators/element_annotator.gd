extends Node2D
class_name ElementAnnotator

# Dictionary<AnnotationElement, AnnotationElement>
var elements_set := {}
var old_hash: int = INF

func _process(delta: float) -> void:
    var new_hash := elements_set.hash()
    if old_hash != new_hash:
        old_hash = new_hash
        update()

func add(element: AnnotationElement) -> void:
    elements_set[element] = element

func erase(element: AnnotationElement) -> bool:
    return elements_set.erase(element)

func has(element: AnnotationElement) -> bool:
    return elements_set.has(element)

func _draw() -> void:
    for element in elements_set:
        element.draw()

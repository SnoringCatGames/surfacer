class_name TransientAnnotatorRegistry
extends Node2D


# Dictionary<Annotator, bool>
var _annotators := {}


func add(annotator: TransientAnnotator) -> void:
    annotator.connect(
            "completed",
            self,
            "remove",
            [annotator])
    _annotators[annotator] = true
    add_child(annotator)


func clear() -> void:
    for annotator in _annotators.keys():
        remove(annotator)


func remove(annotator: TransientAnnotator) -> void:
    _annotators.erase(annotator)
    annotator.queue_free()

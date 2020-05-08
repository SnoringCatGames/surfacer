extends Node2D
class_name ExtraAnnotator

var extra_annotations: Dictionary
var old_hash: int = INF

func _init(global) -> void:
    if global.DEBUG_PARAMS.extra_annotations == null:
        global.DEBUG_PARAMS.extra_annotations = {}
    self.extra_annotations = global.DEBUG_PARAMS.extra_annotations

func _process(delta: float) -> void:
    var new_hash := extra_annotations.hash()
    if old_hash != new_hash:
        old_hash = new_hash
        update()

func _draw() -> void:
    var annotation
    for key in extra_annotations:
        annotation = extra_annotations[key]
        
        # FIXME: Implement this.
        pass

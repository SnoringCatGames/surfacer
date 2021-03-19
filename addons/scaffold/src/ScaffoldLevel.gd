extends Node2D
class_name ScaffoldLevel

func _ready() -> void:
    ScaffoldUtils.connect( \
            "display_resized", \
            self, \
            "_on_resized")
    _on_resized()

func _on_resized() -> void:
    pass

func start() -> void:
    ScaffoldUtils.error("Abstract ScaffoldLevel.start is not implemented")

func destroy() -> void:
    ScaffoldUtils.error("Abstract ScaffoldLevel.destroy is not implemented")

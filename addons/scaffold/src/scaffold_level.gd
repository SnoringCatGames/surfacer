extends Node2D
class_name ScaffoldLevel

func start() -> void:
    ScaffoldUtils.error("Abstract ScaffoldLevel.start is not implemented")

func destroy() -> void:
    ScaffoldUtils.error("Abstract ScaffoldLevel.destroy is not implemented")

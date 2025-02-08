class_name ScaffolderCanvasLayerConfig
extends Resource


@export var name: String
@export var process_mode: Node.ProcessMode


func _init(name: String, process_mode: Node.ProcessMode) -> void:
    self.name = name
    self.process_mode = process_mode

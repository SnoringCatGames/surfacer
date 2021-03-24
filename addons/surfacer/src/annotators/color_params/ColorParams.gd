class_name ColorParams
extends Reference

var type := ColorParamsType.UNKNOWN

func _init(type: int) -> void:
    self.type = type

func get_color() -> Color:
    Gs.utils.error("Abstract ColorParams.get_color is not implemented")
    return Color.black

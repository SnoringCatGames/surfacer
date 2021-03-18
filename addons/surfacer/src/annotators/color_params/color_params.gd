extends Reference
class_name ColorParams

var type := ColorParamsType.UNKNOWN

func _init(type: int) -> void:
    self.type = type

func get_color() -> Color:
    ScaffoldUtils.error("Abstract ColorParams.get_color is not implemented")
    return Color.black

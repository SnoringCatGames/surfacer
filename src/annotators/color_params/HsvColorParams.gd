class_name HsvColorParams
extends ColorParams

const TYPE := ColorParamsType.HSV

var hue: float
var saturation: float
var value: float
var alpha: float


func _init(
        hue: float,
        saturation: float,
        value: float,
        alpha: float) \
        .(TYPE) -> void:
    self.hue = hue
    self.saturation = saturation
    self.value = value
    self.alpha = alpha


func get_color() -> Color:
    return Color.from_hsv(
            hue,
            saturation,
            value,
            alpha)

class_name HsvRangeColorParams
extends ColorParams

const TYPE := ColorParamsType.HSV_RANGE

var hue_min: float
var hue_max: float
var saturation_min: float
var saturation_max: float
var value_min: float
var value_max: float
var alpha_min: float
var alpha_max: float

func _init( \
        hue_min: float, \
        hue_max: float, \
        saturation_min: float, \
        saturation_max: float, \
        value_min: float, \
        value_max: float, \
        alpha_min: float, \
        alpha_max: float) \
        .(TYPE) -> void:
    self.hue_min = hue_min
    self.hue_max = hue_max
    self.saturation_min = saturation_min
    self.saturation_max = saturation_max
    self.value_min = value_min
    self.value_max = value_max
    self.alpha_min = alpha_min
    self.alpha_max = alpha_max

func get_color() -> Color:
    var hue := randf() * (hue_max - hue_min) + hue_min
    var saturation := randf() * (saturation_max - saturation_min) + saturation_min
    var value := randf() * (value_max - value_min) + value_min
    var alpha := randf() * (alpha_max - alpha_min) + alpha_min
    return Color.from_hsv( \
            hue, \
            saturation, \
            value, \
            alpha)

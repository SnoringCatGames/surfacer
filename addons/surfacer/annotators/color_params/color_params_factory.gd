class_name ColorParamsFactory

static func create_hsv_range_color_params_with_constant_sva( \
        hue_min: float, \
        hue_max: float, \
        saturation: float, \
        value: float, \
        alpha: float) -> HsvRangeColorParams:
    return HsvRangeColorParams.new( \
            hue_min, \
            hue_max, \
            saturation, \
            saturation, \
            value, \
            value, \
            alpha, \
            alpha)

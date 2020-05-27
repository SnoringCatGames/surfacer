extends LegendItem
class_name FailedEdgeLegendItem

const TYPE := LegendItemType.FAILED_EDGE
const TEXT := "Failed edge\ncalculation"

func _init().( \
        TYPE, \
        TEXT) -> void:
    pass

func _draw_shape( \
        center: Vector2, \
        size: Vector2) -> void:
    # FIXME: --------------
    draw_circle( \
            center, \
            min(size.x, size.y) / 2.0, \
            Color.dodgerblue)

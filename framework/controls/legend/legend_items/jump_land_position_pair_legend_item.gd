extends LegendItem
class_name JumpLandPositionPairLegendItem

const TYPE := LegendItemType.JUMP_LAND_POSITION_PAIR
const TEXT := "Possible jump/land\npositions"

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

class_name OriginLegendItem
extends LegendItem

const TYPE := LegendItemType.ORIGIN
const TEXT := "Origin"

const SCALE := 0.8
const SECTOR_ARC_LENGTH := 2.2

func _init().( \
        TYPE, \
        TEXT) -> void:
    pass

func _draw_shape( \
        center: Vector2, \
        size: Vector2) -> void:
    var color: Color = \
            Surfacer.ann_defaults.DEFAULT_WAYPOINT_COLOR_PARAMS.get_color()
    var radius: float = \
            SurfacerDrawUtils.EDGE_START_RADIUS * SCALE * Gs.gui_scale
    Gs.draw_utils.draw_origin_marker( \
            self, \
            center, \
            color, \
            radius, \
            SurfacerDrawUtils.EDGE_WAYPOINT_STROKE_WIDTH, \
            SECTOR_ARC_LENGTH)

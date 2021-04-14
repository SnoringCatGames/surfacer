class_name HypotheticalEdgeTrajectoryLegendItem
extends LegendItem

const TYPE := LegendItemType.HYPOTHETICAL_EDGE_TRAJECTORY
const TEXT := "Hypothetical\nedge"

func _init().( \
        TYPE,
        TEXT) -> void:
    pass

func _draw_shape( \
        center: Vector2,
        size: Vector2) -> void:
    var offset_from_center := size * 0.35
    var start := center - offset_from_center
    var end := center + offset_from_center
    var color: Color = Surfacer.ann_defaults \
            .DEFAULT_JUMP_LAND_POSITIONS_COLOR_PARAMS.get_color()
    Gs.draw_utils.draw_dashed_line( \
            self,
            start,
            end,
            color,
            AnnotationElementDefaults.JUMP_LAND_POSITIONS_DASH_LENGTH,
            AnnotationElementDefaults.JUMP_LAND_POSITIONS_DASH_GAP,
            0.0,
            AnnotationElementDefaults.JUMP_LAND_POSITIONS_DASH_STROKE_WIDTH)
